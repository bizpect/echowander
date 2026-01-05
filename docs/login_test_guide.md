# 로그인 테스트 가이드 (초보자용, 단계별)

아래 단계대로만 하면 됩니다. 천천히 가세요.

## 0) 준비물 체크
- 실제 디바이스 (에뮬레이터는 애플 로그인/카카오 로그인에서 제한이 있을 수 있음)
- iOS/Android 키 입력 완료
- Supabase 환경변수 입력 완료


## 1) DB 스키마 적용
Supabase SQL Editor에서 아래 순서대로 실행합니다.
1. `supabase/sql/01_tables.sql`
2. `supabase/sql/02_functions.sql`
3. `supabase/sql/04_rls.sql`


## 2) 앱 실행 (Flutter)
아래 명령을 복사해서 값만 교체하고 실행합니다.
```
flutter run \
  --dart-define=APP_ENV=dev \
  --dart-define=AUTH_BASE_URL=https://YOUR-SUPABASE-FN-URL/ \
  --dart-define=KAKAO_NATIVE_APP_KEY=여기에_카카오_네이티브_앱_키 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=여기에_구글_서버_클라이언트_ID \
  --dart-define=GOOGLE_IOS_CLIENT_ID=여기에_구글_iOS_클라이언트_ID
```


## 3) 테스트 시나리오
각 버튼을 눌러서 아래를 확인합니다.

### 3-1) 구글 로그인
- 로그인 성공: 홈 화면 진입
- 로그인 취소: 아무 메시지도 안 뜸 (조용히 종료)
- 네트워크 끊김: "네트워크 상태를 확인" 메시지
- 토큰 문제: "로그인 검증 실패" 메시지

### 3-2) 카카오 로그인
- 로그인 성공: 홈 화면 진입
- 카카오톡 설치됨: 카카오톡 앱으로 로그인
- 카카오톡 미설치: 카카오 계정 웹 로그인
- 취소/네트워크/실패: 메시지 확인

### 3-3) 애플 로그인
- 로그인 성공: 홈 화면 진입
- 취소/실패: 메시지 확인


## 4) 실패 메시지 매핑 표
앱에서 나오는 메시지와 원인은 대략 아래와 같습니다.
- "로그인에 실패했습니다": 토큰 없음/기타 실패
- "네트워크 상태를 확인": 네트워크 오류
- "로그인 검증에 실패": 토큰 검증 실패
- "지원하지 않는 로그인 방식": 서버에서 provider 거부
- "계정 정보를 저장하지 못했습니다": Supabase RPC 실패
- "로그인 서비스를 사용할 수 없습니다": 서버 환경변수 누락


## 5) 이상할 때 체크리스트
- AUTH_BASE_URL이 Edge Functions URL인지 확인
- GOOGLE_CLIENT_ID가 서버/웹용인지 확인
- APPLE_CLIENT_ID가 Services ID인지 확인
- Supabase Functions 환경변수(APP_SUPABASE_URL/APP_SUPABASE_ANON_KEY) 누락 여부 확인
- iOS/Android 키가 맞는지 확인


## 6) 다음 단계
- 테스트 성공하면 `login_logs` 테이블에서 기록 확인
- `user_profiles` 테이블에 기본 row 생성 여부 확인
