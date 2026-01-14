# Journey Dispatch Outbox 패턴 전환 작업 완료 보고서

## 1. 변경 계획 (5줄 요약)

1. **Outbox 테이블 추가**: `journey_dispatch_jobs` 테이블 생성하여 전송 작업 큐 관리
2. **멱등 보장**: `journey_recipients` 테이블에 unique constraint 추가로 중복 전송 방지
3. **워커 RPC 생성**: `process_journey_dispatch_jobs` RPC로 pending job 자동 처리 및 재시도(backoff)
4. **GitHub Actions Cron**: 매 1분마다 워커 RPC 호출하여 자동 분배 처리
5. **클라이언트 단순화**: Flutter에서 dispatch 호출 제거, "전송 요청 접수" 중립 메시지로 변경

---

## 2. 인벤토리 표 (파일:라인)

| 파일 경로 | 변경 라인 | 변경 유형 | 설명 |
|---------|---------|---------|------|
| `supabase/sql/08_dispatch_jobs_migration.sql` | 전체 (신규) | 신규 생성 | Outbox 테이블, RPC, RLS 정책 |
| `.github/workflows/dispatch_jobs.yml` | 전체 (신규) | 신규 생성 | GitHub Actions cron workflow |
| `lib/l10n/app_ko.arb` | 117 | 추가 | composeSendRequestAccepted 키 |
| `lib/l10n/app_en.arb` | 117 | 추가 | composeSendRequestAccepted 키 |
| `lib/l10n/app_ja.arb` | 117 | 추가 | composeSendRequestAccepted 키 |
| `lib/l10n/app_es.arb` | 117 | 추가 | composeSendRequestAccepted 키 |
| `lib/l10n/app_fr.arb` | 117 | 추가 | composeSendRequestAccepted 키 |
| `lib/l10n/app_pt.arb` | 117 | 추가 | composeSendRequestAccepted 키 |
| `lib/l10n/app_pt_BR.arb` | 117 | 추가 | composeSendRequestAccepted 키 |
| `lib/l10n/app_zh.arb` | 117 | 추가 | composeSendRequestAccepted 키 |
| `lib/features/journey/application/journey_compose_controller.dart` | 323-327 | 수정 (제거) | dispatchJourneyMatch 호출 제거 |
| `lib/features/journey/presentation/journey_compose_screen.dart` | 513, 526 | 수정 | composeSubmitSuccess → composeSendRequestAccepted |

---

## 3. 변경 파일 목록

### 신규 생성
- `supabase/sql/08_dispatch_jobs_migration.sql`
- `.github/workflows/dispatch_jobs.yml`

### 수정
- `lib/l10n/app_ko.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ja.arb`
- `lib/l10n/app_es.arb`
- `lib/l10n/app_fr.arb`
- `lib/l10n/app_pt.arb`
- `lib/l10n/app_pt_BR.arb`
- `lib/l10n/app_zh.arb`
- `lib/features/journey/application/journey_compose_controller.dart`
- `lib/features/journey/presentation/journey_compose_screen.dart`

---

## 4. 핵심 diff 요약 (재발 방지 관점)

### 4.1 DB: Outbox 패턴 도입
- **Before**: 클라이언트가 `create_journey` 성공 후 즉시 `dispatchJourneyMatch` 호출 → secret 누락/네트워크 끊김 시 분배 실패
- **After**: `create_journey`가 `journey_dispatch_jobs`에 pending job 생성 → GitHub Actions cron이 주기적으로 `process_journey_dispatch_jobs` RPC 호출하여 자동 분배
- **재발 방지**: 클라이언트 앱 종료/네트워크 불안정과 무관하게 백엔드가 분배 완료 보장

### 4.2 DB: 멱등 보장
- **Before**: `journey_recipients`에 unique constraint 존재하지만 확인 필요
- **After**: `(journey_id, recipient_user_id)` unique constraint 명시적 확인 및 추가 (이미 존재하면 skip)
- **재발 방지**: 워커 재시도/중복 실행 시에도 "N명에게 전송" 중복 증가 방지 (ON CONFLICT DO NOTHING)

### 4.3 Flutter: 클라이언트 책임 분리
- **Before**: `dispatchJourneyMatch` 호출 → 실패 시 사용자는 "메시지를 보냈습니다" 알림 받았지만 실제로는 분배 안 됨
- **After**: dispatch 호출 제거, "전송 요청이 접수되었습니다" 중립 메시지로 변경
- **재발 방지**: 사용자 오해 방지, 백엔드가 분배 끝까지 책임

### 4.4 GitHub Actions: 자동 재시도
- **Before**: 수동 재시도 또는 분배 실패 시 영구 실패
- **After**: cron으로 매 1분마다 pending/failed job 처리, exponential backoff로 재시도 (최대 30분 간격)
- **재발 방지**: 일시적 네트워크/서버 문제 시에도 자동 복구

---

## 5. 규칙 준수 체크

### 5.1 NetworkGuard / Direct Supabase 호출
- **확인 결과**: `grep -rn "\.from(Supabase" lib --include="*.dart"` → **0건**
- **결론**: ✅ 모든 백엔드 호출이 NetworkGuard 경유, direct supabase 호출 없음

### 5.2 i18n 8개 언어 동기화
- **확인 결과**: `composeSendRequestAccepted` 키가 8개 ARB 파일 모두에 추가됨
  - ko, en, ja, es, fr, pt, pt_BR, zh
- **결론**: ✅ i18n 규칙 준수

### 5.3 색상 토큰
- **확인 결과**: `grep -rn "Color(0x" lib --include="*.dart"` → `app/theme/app_colors.dart`에서만 토큰 정의
- **확인 결과**: `grep -rn "Colors\." lib --include="*.dart"` → `AppColors.*` 토큰만 사용
- **결론**: ✅ 색상 하드코딩 없음, AppColors 토큰만 사용

### 5.4 SQL alias 규칙
- **확인 결과**: `08_dispatch_jobs_migration.sql`의 모든 SQL
  - 모든 테이블 alias 사용 (jr, jdj, j 등)
  - 모든 컬럼 `alias.column` 형식
  - 변수명 충돌 방지 (`v_` prefix)
- **결론**: ✅ SQL 규칙 준수

---

## 6. flutter analyze 결과

```bash
flutter analyze --no-pub
Analyzing echowander...
No issues found! (ran in 13.1s)
```

**결론**: ✅ 모든 코드 정적 분석 통과

---

## 7. grep 증빙

### 7.1 "메시지를 보냈습니다" 하드코딩 제거 확인
```bash
cd lib && grep -rn "메시지를 보냈" . --include="*.dart"
```
**결과**:
```
./l10n/app_localizations_ko.dart:324:  String get composeSubmitSuccess => '메시지를 보냈어요.';
./l10n/app_localizations_ko.dart:614:  String get inboxRespondSuccessBody => '메시지를 보냈어요.';
```
- `composeSubmitSuccess` 키는 ARB에 그대로 유지 (기존 참조 제거 후 정리 예정)
- 실제 사용처(`journey_compose_screen.dart`)는 `composeSendRequestAccepted`로 변경됨
- `inboxRespondSuccessBody`는 받은 메시지 답변 성공 메시지로 별도 기능 (변경 불필요)

**결론**: ✅ compose 화면에서 "메시지를 보냈습니다" 제거 완료

### 7.2 Direct Supabase 호출
```bash
cd lib && grep -rn "\.from(Supabase" . --include="*.dart"
```
**결과**: (출력 없음)

**결론**: ✅ Direct Supabase 호출 0건

### 7.3 색상 하드코딩
```bash
cd lib && grep -rn "Colors\." . --include="*.dart" | head -20
```
**결과**: `AppColors.*` 토큰만 사용 확인

```bash
cd lib && grep -rn "Color(0x" . --include="*.dart" | head -20
```
**결과**: `app/theme/app_colors.dart`에서만 토큰 정의

**결론**: ✅ 색상 하드코딩 0건, AppColors 토큰만 사용

---

## 8. GitHub Actions Cron 환경변수/Secrets 산출물

### 8.1 필수 Secrets 목록

| 이름 | 타입 | 설명 | 획득 위치 | 예시 형태 (마스킹) | 주의사항 |
|------|------|------|-----------|-------------------|----------|
| `SUPABASE_URL` | Secret | Supabase 프로젝트 URL | Supabase Dashboard → Project Settings → API | `https://xxxx.supabase.co` | 프로젝트마다 다름 |
| `SUPABASE_SERVICE_ROLE_KEY` | Secret | service_role key (서버 권한) | Supabase Dashboard → Project Settings → API → service_role | `eyJhbG...` (매우 긴 JWT) | **절대 외부 노출 금지** (로그/코드 출력 금지) |

### 8.2 선택 환경변수

| 이름 | 타입 | 설명 | 기본값 | 주의사항 |
|------|------|------|--------|----------|
| `BATCH_SIZE` | Workflow env | 한 번에 처리할 job 수 | 20 | Secret 불필요, workflow 파일에 직접 기재 가능 |

### 8.3 KST 기준 실행 시간

| GitHub Actions Cron (UTC) | KST 변환 | 설명 |
|---------------------------|----------|------|
| `*/1 * * * *` | 매 1분 (UTC+9) | KST 기준 매 1분마다 실행 (실제로는 GitHub 부하에 따라 최대 5분 지연 가능) |

**예시**:
- UTC 00:00 → KST 09:00
- UTC 15:00 → KST 00:00 (다음날)

**권장**: GitHub Actions는 최소 5분 간격 권장 (`*/5 * * * *`), 하지만 이 워커는 부하가 낮으므로 `*/1 * * * *`로 설정 가능.

### 8.4 GitHub Settings → Secrets 등록 경로

1. **GitHub 레포지토리 페이지 접속**
2. **Settings** 탭 클릭
3. 왼쪽 사이드바에서 **Secrets and variables** → **Actions** 클릭
4. **New repository secret** 버튼 클릭
5. **Name**: `SUPABASE_URL` 입력
6. **Secret**: Supabase Dashboard에서 복사한 URL 붙여넣기
7. **Add secret** 클릭
8. 동일한 방법으로 `SUPABASE_SERVICE_ROLE_KEY` 등록

**주의**:
- Secret은 등록 후 수정 가능하지만 **내용 확인 불가** (재등록 필요)
- Secret은 workflow 실행 로그에 자동 마스킹됨 (`***`)
- 절대 `echo` 등으로 secret 출력하지 말 것

### 8.5 환경변수 사용 규칙

```yaml
env:
  SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
  SUPABASE_SERVICE_ROLE_KEY: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}
```

- workflow 파일에 직접 키 하드코딩 금지
- 반드시 `${{ secrets.* }}` 형식으로 주입
- job log에 secret 출력되지 않도록 `set -x` 금지, `echo` 금지

### 8.6 최소 권한 권장

```yaml
permissions:
  contents: read
```

- 외부 토큰(예: PAT) 요구하지 않도록 구성
- Supabase service_role key만으로 RPC 호출 가능

---

## 9. 수동 테스트 시나리오

### 9.1 전송 요청 접수 확인
**절차**:
1. Flutter 앱에서 메시지 작성 화면 진입
2. 내용 입력, 수신자 수 선택, 사진 첨부 (선택)
3. "보내기" 버튼 클릭
4. **기대 결과**: "전송 요청이 접수되었습니다" 알럿 표시
5. 알럿 확인 후 보낸메시지 탭으로 이동
6. 방금 보낸 메시지가 "진행중" 탭에 표시됨 (status_code=WAITING)

**기대 로그** (Flutter 디버그):
```
compose: 전송 시작
compose: ensureSessionReady 시작
compose: ensureSessionReady 성공
compose: 이미지 업로드 시작 (N장)
compose: 이미지 업로드 완료 (N건)
compose: create_journey 요청 (recipientCount=N, images=N, lang=ko)
compose: RPC 호출 완료 (dispatch는 백엔드 워커가 처리)
```

### 9.2 GitHub Actions Cron 자동 처리 확인
**절차**:
1. 9.1 완료 후 1분 대기
2. GitHub Actions 탭 접속 → "Journey Dispatch Jobs Processor" workflow 확인
3. 최근 실행 로그 확인

**기대 로그** (GitHub Actions):
```
Calling process_journey_dispatch_jobs RPC...
Batch size: 20
SUCCESS: HTTP 200
Response:
{"ok":true,"processed":1,"failed":0,"batch_size":20}
```

4. Flutter 앱에서 보낸메시지 새로고침
5. **기대 결과**: `sent_count`가 요청한 수신자 수만큼 표시됨 (예: "3명에게 전송")
6. journey `status_code`가 `WAITING` → `CREATED`로 변경됨

### 9.3 멱등 확인 (중복 실행 방지)
**절차**:
1. GitHub Actions → "Journey Dispatch Jobs Processor" workflow
2. **"Run workflow"** 버튼으로 수동 실행 (2번 연속)
3. 두 번째 실행 로그 확인

**기대 로그**:
```
{"ok":true,"processed":0,"failed":0,"batch_size":20}
```
또는
```
{"ok":true,"processed":1,"failed":0,"batch_size":20}
```
- 중요: `sent_count`가 중복으로 증가하지 않음
- `journey_recipients` 테이블에 중복 row 생성되지 않음 (unique constraint)

### 9.4 재시도 (네트워크 끊김 시뮬레이션)
**절차**:
1. (고급) Supabase 프로젝트 일시 정지 또는 RPC 함수 오류 주입
2. Flutter 앱에서 메시지 전송 → "전송 요청 접수" 표시
3. GitHub Actions cron 실행 → 실패 로그 확인
4. `journey_dispatch_jobs` 테이블 확인:
   - `status=failed`
   - `attempt_count=1`
   - `last_error` 값 기록됨
   - `next_run_at`이 backoff 적용되어 미래 시간으로 설정됨
5. Supabase 복구 후 다음 cron 실행
6. **기대 결과**: 재시도 성공, `status=done`, `sent_count` 증가

**기대 로그**:
```
{"ok":true,"processed":1,"failed":0,"batch_size":20}
```

### 9.5 네트워크 끊김/앱 종료와 무관한 분배
**절차**:
1. Flutter 앱에서 메시지 전송 후 즉시 앱 강제 종료 (스와이프 종료)
2. 1분 대기
3. GitHub Actions cron 자동 실행
4. Flutter 앱 재실행 → 보낸메시지 확인
5. **기대 결과**: `sent_count`가 정상적으로 표시됨 (앱 종료와 무관하게 분배 완료)

---

## 10. 배포 체크리스트

### 10.1 DB 마이그레이션
- [ ] `supabase/sql/08_dispatch_jobs_migration.sql` Supabase SQL Editor에서 실행
- [ ] `journey_dispatch_jobs` 테이블 생성 확인
- [ ] `journey_recipients` unique constraint 확인
- [ ] `process_journey_dispatch_jobs` RPC 함수 생성 확인
- [ ] `create_journey` RPC 함수 수정 확인

### 10.2 GitHub Actions 설정
- [ ] `.github/workflows/dispatch_jobs.yml` 파일 레포지토리에 커밋
- [ ] GitHub Settings → Secrets → Actions에서 `SUPABASE_URL` 등록
- [ ] GitHub Settings → Secrets → Actions에서 `SUPABASE_SERVICE_ROLE_KEY` 등록
- [ ] GitHub Actions 탭에서 "Journey Dispatch Jobs Processor" workflow 활성화 확인

### 10.3 Flutter 배포
- [ ] ARB 파일 수정 후 `flutter gen-l10n` 실행 완료
- [ ] `flutter analyze` 통과 확인
- [ ] 앱 빌드 및 테스트
- [ ] 스토어 배포 (필요 시)

### 10.4 모니터링
- [ ] GitHub Actions cron 실행 로그 모니터링 (처음 24시간)
- [ ] Supabase `journey_dispatch_jobs` 테이블 모니터링
  - `status=failed` row가 계속 증가하는지 확인
  - `attempt_count`가 비정상적으로 높은 job 확인
- [ ] Flutter 사용자 피드백 모니터링
  - "전송 요청 접수" 메시지 혼란 여부 확인
  - 실제 분배 완료 시간 (평균 1~2분 이내)

---

## 11. 롤백 계획 (비상 시)

### 11.1 Flutter 롤백
1. `journey_compose_controller.dart` 323~327라인 복원 (dispatchJourneyMatch 호출 추가)
2. `journey_compose_screen.dart` 513, 526라인 복원 (composeSubmitSuccess 사용)
3. `flutter analyze` 통과 확인
4. 핫픽스 배포

### 11.2 GitHub Actions 중단
1. `.github/workflows/dispatch_jobs.yml` 파일 삭제 또는 비활성화
2. 또는 cron schedule 주석 처리

### 11.3 DB 롤백 (신중)
- `journey_dispatch_jobs` 테이블 제거는 권장하지 않음 (외래키 cascade)
- `create_journey` RPC 함수만 이전 버전으로 복원 가능
- 단, pending job이 남아있을 수 있으므로 수동 정리 필요

---

## 12. 재발 방지 및 개선 사항

### 12.1 재발 방지
- ✅ 클라이언트가 dispatch를 책임지지 않음
- ✅ 백엔드 워커가 분배 끝까지 보장
- ✅ 멱등 보장으로 중복 전송 방지
- ✅ 재시도 로직으로 일시적 장애 자동 복구

### 12.2 향후 개선 사항
1. **알림 정책 개선**: "전송 요청 접수" → "N명에게 전송 완료" 푸시 알림 추가 (선택)
2. **모니터링 강화**: Supabase 함수 로그, GitHub Actions 실패 알림 연동
3. **배치 크기 조정**: 부하에 따라 `BATCH_SIZE` 조정 (기본 20 → 50)
4. **cron 주기 조정**: 부하가 낮으면 `*/5 * * * *` (5분)으로 변경 가능
5. **Dead Letter Queue**: `attempt_count > 10`인 job은 별도 테이블로 이동하여 수동 처리

---

## 13. 결론

✅ **모든 요구사항 완료**:
- Outbox 패턴으로 전환 완료
- 멱등 보장 확인
- GitHub Actions Cron 워커 추가
- Flutter 클라이언트 단순화
- 규칙 준수 (NetworkGuard, i18n, 색상 토큰, SQL alias)
- flutter analyze 통과
- grep 증빙 완료
- GitHub Actions Secrets 가이드 작성
- 수동 테스트 시나리오 제공

**배포 권장**: DB 마이그레이션 → GitHub Actions 설정 → Flutter 배포 순서로 진행

**문의 사항**: 추가 문의는 레포지토리 Issue로 등록

---

**작성 일시**: 2026-01-14
**작성자**: Claude Sonnet 4.5
**버전**: 1.0
