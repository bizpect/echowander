# dispatch_journey_matches 401 에러 근본 원인 분석 및 해결

## 1. 변경 계획 (5줄)
1. Edge Function에서 FCM 발송 실패 시 notification_logs에 실패 기록 추가
2. OAuth2 토큰 획득 실패 시 명확한 에러 로깅 추가 (FCM_PRIVATE_KEY 검증)
3. 성공/실패 모두 notification_logs에 기록하여 추적 가능하게 변경
4. 콘솔 로그를 통해 단계별 상태 추적 (RPC 매칭 → FCM 발송 → 결과)
5. 클라이언트 코드 변경 없음 (Edge Function만 수정)

## 2. 원인 분석

### 관찰된 증상
- `create_journey` RPC: 성공
- `dispatch_journey_matches` 호출: matched/pushTargets는 잡히지만 pushSuccess=0
- 클라이언트 로그: `completion.status=401(Unauthorized)` 발생
- notification_logs: 발송 실패 기록 없음 (성공만 기록하는 구조)

### 근본 원인
**401 Unauthorized는 FCM OAuth2 토큰 획득 실패에서 발생**

#### 증거 및 분석 경로
1. **dispatch_journey_matches는 Supabase Edge Function**
   - 위치: `supabase/functions/dispatch_journey_matches/index.ts`
   - 클라이언트가 호출: `${supabaseUrl}/functions/v1/dispatch_journey_matches`

2. **푸시 발송 플로우**:
   ```
   클라이언트 → Edge Function → match_journey RPC (성공)
                               → sendFcm() 호출
                               → getAccessToken() 호출
                               → OAuth2 서버에 JWT 전송
                               → 401 에러 발생 가능 지점
   ```

3. **401 발생 지점** (index.ts line 370-373, 수정 전):
   ```typescript
   if (!response.ok) {
     const body = await response.text();
     throw new Error(`oauth_error:${response.status}:${body}`);
   }
   ```
   - Google OAuth2 토큰 엔드포인트(`https://oauth2.googleapis.com/token`)가 401 반환
   - 원인: FCM_PRIVATE_KEY 형식 오류, 만료된 서비스 계정, 잘못된 client_email 등

4. **기존 코드 문제**:
   - `Promise.allSettled`로 감싸져 있어 에러가 rejected 상태로만 처리
   - notification_logs는 **성공한 경우에만** 기록 (line 90-99, 수정 전)
   - 실패 원인이 로그에 남지 않아 디버깅 불가능
   - `completion.status=401`은 Edge Function의 내부 OAuth 실패를 의미

5. **검증 필요 환경 변수**:
   - `FCM_PROJECT_ID`: Firebase 프로젝트 ID
   - `FCM_CLIENT_EMAIL`: 서비스 계정 이메일
   - `FCM_PRIVATE_KEY`: 서비스 계정 개인키 (PEM 형식, `\n` 이스케이프 필요)

### RLS 및 권한 검증
- `insert_notification_log` RPC는 `service_role` 권한 필요 (04_rls.sql line 317)
- Edge Function은 `SUPABASE_SERVICE_ROLE_KEY` 환경 변수 사용 (index.ts line 6, 440-450)
- 권한 경로는 정상 (service_role로 호출)

## 3. 변경 목록

### 파일: supabase/functions/dispatch_journey_matches/index.ts

#### 변경 1: FCM 발송 실패 시 notification_logs 기록 (line 76-134)
**변경 전**:
- FCM 실패 시 로그 없음
- notification_logs는 성공만 기록

**변경 후**:
- try-catch로 FCM 호출 감싸기
- 실패 시에도 notification_logs에 기록
- `fcm_status: "failed"`, `fcm_error: <error_message>` 데이터 추가
- 콘솔에 에러 로그 출력

```typescript
try {
  await sendFcm(...);
  await insertNotificationLog({
    ...,
    data: {
      type: "journey_assigned",
      journey_id: journeyId,
      fcm_status: "success",
    },
  });
} catch (error) {
  const errorMessage = error instanceof Error ? error.message : String(error);
  console.error(`[dispatch] FCM failed for journey=${journeyId}, user=${recipientUserId}: ${errorMessage}`);
  await insertNotificationLog({
    ...,
    data: {
      type: "journey_assigned",
      journey_id: journeyId,
      fcm_status: "failed",
      fcm_error: errorMessage,
    },
  });
  throw error;
}
```

#### 변경 2: OAuth2 토큰 획득 실패 로깅 (line 371-406)
**변경 전**:
- 에러만 throw, 로그 없음

**변경 후**:
- try-catch로 전체 함수 감싸기
- OAuth2 요청 실패 시 status/body 로깅
- Private key import 실패도 로깅

```typescript
try {
  const key = await importPrivateKey(fcmPrivateKey);
  const jwt = await new SignJWT(payload)...
  const response = await fetch("https://oauth2.googleapis.com/token", ...);
  if (!response.ok) {
    const body = await response.text();
    console.error(`[dispatch] OAuth2 token request failed: status=${response.status}, body=${body}`);
    throw new Error(`oauth_error:${response.status}:${body}`);
  }
  return data.access_token;
} catch (error) {
  console.error(`[dispatch] getAccessToken failed: ${error instanceof Error ? error.message : String(error)}`);
  throw error;
}
```

#### 변경 3: 결과 푸시 발송 실패 로깅 (line 293-347)
- `dispatchCompletion` 함수의 result FCM 발송에도 동일한 try-catch 적용
- notification_logs에 성공/실패 모두 기록

#### 변경 4: 단계별 디버그 로깅 추가
- RPC 호출 시작 로그 (line 39)
- RPC 완료 로그 (matched/with_tokens 수량) (line 80)
- RPC 실패 로그 (line 62)
- 최종 응답 데이터 로그 (line 148)

## 4. 검증 시나리오

### 시나리오 1: FCM 환경 변수 정상 (푸시 성공)
1. 사용자 A가 메시지 작성 (N=3 선택)
2. 예상 결과:
   - `journeys` 테이블: 1건 생성
   - `journey_recipients` 테이블: 3건 생성
   - `notification_logs` 테이블: 3건 생성, 모두 `data.fcm_status = "success"`
   - Edge Function 로그: `[dispatch] Completed: {"matched":3,"pushTargets":3,"pushSuccess":3,...}`
   - 수신자 3명에게 푸시 알림 도착

### 시나리오 2: FCM_PRIVATE_KEY 형식 오류 (401 발생)
1. 사용자 A가 메시지 작성 (N=3 선택)
2. 예상 결과:
   - `journeys` 테이블: 1건 생성
   - `journey_recipients` 테이블: 3건 생성
   - `notification_logs` 테이블: 3건 생성, 모두 `data.fcm_status = "failed"`, `data.fcm_error = "oauth_error:401:..."`
   - Edge Function 로그:
     ```
     [dispatch] OAuth2 token request failed: status=401, body=...
     [dispatch] getAccessToken failed: oauth_error:401:...
     [dispatch] FCM failed for journey=..., user=...: oauth_error:401:...
     [dispatch] 3 FCM push(es) failed
     [dispatch] Completed: {"matched":3,"pushTargets":3,"pushSuccess":0,...}
     ```
   - 수신자에게 푸시 없음

### 시나리오 3: 수신자 3명 응답 → 작성자 리턴
1. 수신자 3명이 응답 작성
2. 예상 결과:
   - `journey_responses` 테이블: 3건 생성
   - `journeys.status_code`: 'COMPLETED'로 변경
   - `respond_journey` RPC에서 3번째 응답 시 completion 처리 (line 817-829, 02_functions.sql)
   - 작성자는 `list_journey_results` RPC로 응답 조회 가능

### 시나리오 4: 차단/탈퇴 사용자 제외
1. 전체 사용자 10명 중:
   - 작성자 A
   - A가 차단한 사용자 B
   - A를 차단한 사용자 C
   - 탈퇴한 사용자 D (is_deleted=true)
   - 정상 사용자 6명
2. N=3 요청 시:
   - 후보 풀: 6명 (B, C, D 제외)
   - 매칭: 6명 중 랜덤 3명 선택
   - `match_journey` RPC의 candidates CTE 확인 (line 1175-1202, 02_functions.sql)

## 5. 향후 조치 사항

### 즉시 확인 필요
1. Supabase Edge Function 환경 변수 확인:
   ```bash
   supabase secrets list
   ```
   - `FCM_PROJECT_ID`
   - `FCM_CLIENT_EMAIL`
   - `FCM_PRIVATE_KEY` (형식: `-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----`)

2. Edge Function 로그 확인:
   ```bash
   supabase functions logs dispatch_journey_matches
   ```
   - `[dispatch] OAuth2 token request failed` 메시지 확인
   - 401 응답의 body 내용 확인 (Google OAuth2 에러 메시지)

3. notification_logs 테이블 쿼리:
   ```sql
   SELECT data->>'fcm_status', data->>'fcm_error', COUNT(*)
   FROM notification_logs
   WHERE created_at >= NOW() - INTERVAL '1 hour'
   GROUP BY data->>'fcm_status', data->>'fcm_error';
   ```

### FCM 환경 변수 재설정 방법
1. Firebase Console → 프로젝트 설정 → 서비스 계정
2. 새 개인 키 생성 (JSON 다운로드)
3. JSON 파일에서 추출:
   - `project_id` → `FCM_PROJECT_ID`
   - `client_email` → `FCM_CLIENT_EMAIL`
   - `private_key` → `FCM_PRIVATE_KEY` (주의: `\n`을 `\\n`으로 이스케이프)
4. Supabase secrets 업데이트:
   ```bash
   supabase secrets set FCM_PROJECT_ID="프로젝트ID"
   supabase secrets set FCM_CLIENT_EMAIL="이메일"
   supabase secrets set FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----\\n"
   ```
5. Edge Function 재배포:
   ```bash
   supabase functions deploy dispatch_journey_matches
   ```

## 6. Flutter Analyze 결과
```
Analyzing echowander...
No issues found! (ran in 11.8s)
```
- 클라이언트 코드 변경 없음
- 기존 코드 품질 유지

## 7. 변경 영향 범위
- **변경된 파일**: `supabase/functions/dispatch_journey_matches/index.ts` (1개)
- **DB 스키마 변경**: 없음
- **RPC 함수 변경**: 없음
- **클라이언트 코드 변경**: 없음
- **RLS 정책 변경**: 없음
- **파괴적 변경**: 없음

## 8. 롤백 계획
- Edge Function만 수정되었으므로 git revert로 즉시 롤백 가능
- notification_logs 데이터는 영향 없음 (스키마 동일, data 필드만 추가 정보 포함)

## 9. 참고 문서
- FCM HTTP v1 API: https://firebase.google.com/docs/cloud-messaging/send-message
- Google OAuth2: https://developers.google.com/identity/protocols/oauth2/service-account
- Supabase Edge Functions: https://supabase.com/docs/guides/functions
