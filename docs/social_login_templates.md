# 소셜 로그인 키 템플릿 (초보자용)

이 문서는 iOS/Android 키를 어디에 넣는지 그대로 따라하면 됩니다.

## 1) iOS 템플릿
파일: `ios/Flutter/Debug.xcconfig`
```
KAKAO_APP_KEY=여기에_카카오_네이티브_앱_키
GOOGLE_REVERSED_CLIENT_ID=여기에_구글_리버스_클라이언트_ID
```

파일: `ios/Flutter/Release.xcconfig`
```
KAKAO_APP_KEY=여기에_카카오_네이티브_앱_키
GOOGLE_REVERSED_CLIENT_ID=여기에_구글_리버스_클라이언트_ID
```

### iOS 값 찾는 위치
- 카카오 키: Kakao Developers > 내 앱 > 앱 키 > 네이티브 앱 키
- 구글 리버스 ID: Google Cloud Console > OAuth 2.0 클라이언트 > iOS용 Client ID > Reverse Client ID


## 2) Android 템플릿
파일: `android/gradle.properties`
아래 줄을 맨 아래에 추가하세요.
```
KAKAO_APP_KEY=여기에_카카오_네이티브_앱_키
```


## 3) Flutter 실행용 환경값 템플릿
아래 명령을 복사해서 값만 바꾼 뒤 실행합니다.
```
flutter run \
  --dart-define=APP_ENV=dev \
  --dart-define=AUTH_BASE_URL=https://YOUR-SUPABASE-FN-URL/ \
  --dart-define=KAKAO_NATIVE_APP_KEY=여기에_카카오_네이티브_앱_키 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=여기에_구글_서버_클라이언트_ID \
  --dart-define=GOOGLE_IOS_CLIENT_ID=여기에_구글_iOS_클라이언트_ID
```

### Flutter 값 찾는 위치
- `AUTH_BASE_URL`: Supabase Edge Functions URL (예: https://프로젝트.supabase.co/functions/v1/)
- `KAKAO_NATIVE_APP_KEY`: 카카오 네이티브 앱 키
- `GOOGLE_SERVER_CLIENT_ID`: Google Cloud Console > OAuth 2.0 클라이언트 > 웹/서버용 Client ID
- `GOOGLE_IOS_CLIENT_ID`: Google Cloud Console > OAuth 2.0 클라이언트 > iOS용 Client ID
