# Supabase 환경변수 체크리스트 (초보자용)

아래 항목을 Supabase 대시보드에서 Edge Functions 환경변수로 등록하세요.

## 필수 항목
- JWT_SECRET: 길고 랜덤한 문자열 (예: 32자 이상)
- JWT_ISSUER: 예) echowander
- JWT_AUDIENCE: 예) echowander
- ACCESS_TTL_SECONDS: 예) 900
- REFRESH_TTL_SECONDS: 예) 2592000
- GOOGLE_CLIENT_ID: 구글 서버/웹용 Client ID
- APPLE_CLIENT_ID: 애플 서비스 ID (Services ID)
- APP_SUPABASE_URL: 프로젝트 URL (예: https://프로젝트.supabase.co)
- APP_SUPABASE_ANON_KEY: 프로젝트 anon key
- USER_NAMESPACE_UUID: UUID 형식 (예: 6f1c219a-7b12-4ce0-9f30-9d9f1b3db6d1)

## 선택 항목
- ALLOW_DEV_SOCIAL: 개발용 dev 토큰 허용 여부 (true/false)

## 확인 방법 (체크리스트)
- JWT_SECRET 설정됨
- JWT_ISSUER / JWT_AUDIENCE 둘 다 동일하게 설정됨
- GOOGLE_CLIENT_ID가 Google Cloud Console의 서버/웹용 Client ID와 일치함
- APPLE_CLIENT_ID가 Apple Developer의 Services ID와 일치함
- APP_SUPABASE_URL / APP_SUPABASE_ANON_KEY가 올바른 프로젝트 값임
- USER_NAMESPACE_UUID가 UUID 형식임

## 자주 생기는 실수
- GOOGLE_CLIENT_ID에 iOS용 Client ID를 넣는 실수
- AUTH_BASE_URL에 프로젝트 URL을 넣는 실수 (Edge Functions URL이어야 함)
- APPLE_CLIENT_ID에 App ID를 넣는 실수 (Services ID 필요)
