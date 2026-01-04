### 터미널에서 안드로이드 시뮬레이터 실행 (WINDOW)

1. 터미널 관리자 모드로 실행
2. 에뮬레이터 설치경로로 이동   
```
	cd C:\Users\jbh\AppData\Local\Android\Sdk\emulator
```
1. 명령어로 실행할 수 있는 에뮬레이터 리스트 확인
```
	emulator -list-avds
```
4.  에뮬레이터 실행 예) emulator -avd <리스트에서 나온 에뮬레이터명> 
```
	emulator -avd Pixel_9_Pro
```

### git hub classic token

```
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
```

### 애플 계정 정보

-  팀 ID
```
LG6DSTYY5C
```

### 환경변수 정보

-  JWT_SECRET
```
H3cO5lWa3OfjEtRu/KaMLUvPxqhXZy32oQxU9HSEHqGCyekQgT8XxmLpbxQDrlRPNXa+wRJPGxgB0mjByVmHoQ==
```
- JWT_ISSUER
```
supabase
```
-  JWT_AUDIENCE
```
authenticated
```
- ACCESS_TTL_SECONDS
```
900
```
- REFRESH_TTL_SECONDS
```
2592000
```
- GOOGLE_CLIENT_ID
```
242212293972-8vm6ee1525blnu5af4v8f3ngg9i3aku0.apps.googleusercontent.com
```
-  APPLE_CLIENT_ID
```
com.bizpect.echowander
```
-  APP_SUPABASE_URL
```
https://foprazptesbozwcktqky.supabase.co
```
- APP_SUPABASE_ANON_KEY
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZvcHJhenB0ZXNib3p3Y2t0cWt5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc1MDcyNzgsImV4cCI6MjA4MzA4MzI3OH0.PElDj8bQgQWDz-1Mj4v2EMisCuyCdZvJYoTyyk-3NYE
```

### 키스토어 지문 , 키 해시 값 뽑기

> openssl 설치 후 powershell에서 진행

-  SHA1 지문 값 보기
```
keytool -list -v -keystore C:\project\echowander\debug.keystore -alias androiddebugkey -storepass android -keypass android
```
-  위 명령어 실행 후 SHA1 값을 가져와서 아래에 붙혀서 실행해서 나온 값이 키 해시
```
$sha1 = "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD".Replace(":","")
$bytes = for ($i=0; $i -lt $sha1.Length; $i+=2) { [Convert]::ToByte($sha1.Substring($i,2),16) }
[Convert]::ToBase64String($bytes)
```

### 디버그용 키스토어

- 디버그용 키스토어 경로
```
C:\project\echowander
```
- 디버그용 SHA1
```
80:54:0C:91:D1:F4:3A:EF:79:D7:5A:54:29:49:06:1A:E5:2D:86:D6
```
- 디버그용 SHA256
```
96:FE:F3:27:C0:F9:A6:47:12:5B:EB:67:D8:14:8F:C2:3B:2C:AF:E6:77:61:EA:4B:00:FE:7D:D4:A3:A0:B8:29
```
- 디버그용 KEY HASH
```
gFQMkdH0Ou9511pUKUkGGuUthtY=
```
### 카카오 로그인

- 네이티브 앱 키
```
c17fad746615b58f888cf526344305eb
```
- 자바스크립트 키
```
ab162ce0e6d4ec9b3936b49ceb29a2c3
```
- rest api 키
```
df8ef9b1493c7f085c7197d391aa78d1
```
- 스킴정보
```
kakaoc17fad746615b58f888cf526344305eb
```

### 구글 로그인

> echowander_web

-  클라이언트 ID
```
242212293972-8vm6ee1525blnu5af4v8f3ngg9i3aku0.apps.googleusercontent.com
```
-  클라이언트 보안 비밀번호
```
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
```
- JSON 파일명
```
client_secret_242212293972-8vm6ee1525blnu5af4v8f3ngg9i3aku0.apps.googleusercontent.com
```

> echowander_aos

-  클라이언트 ID
```
242212293972-qi1759456v1g6url5ji2pnbmjakcss3u.apps.googleusercontent.com
```

- JSON 파일명
```
client_secret_242212293972-qi1759456v1g6url5ji2pnbmjakcss3u.apps.googleusercontent.com
```

> echowander_ios

-  클라이언트 ID
```
242212293972-m5qsl1vt6rj9d06de53b4siuvkhpohk3.apps.googleusercontent.com
```

- plist 파일명
```
client_242212293972-m5qsl1vt6rj9d06de53b4siuvkhpohk3.apps.googleusercontent.com
```








맥에서 해야할 것
  2. Xcode에서 Capability 추가

  - ios/Runner.xcworkspace 열기
  - Runner 타겟 → Signing & Capabilities
  - + Capability → Sign In with Apple 추가

  3. APPLE_CLIENT_ID 값 (중요)

  - 네이티브 로그인인 지금 코드 기준
    → APPLE_CLIENT_ID = com.bizpect.echowander
    (서비스 ID가 아니라 앱 번들 ID)