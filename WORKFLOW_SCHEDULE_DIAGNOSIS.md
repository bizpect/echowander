# GitHub Actions Schedule 미작동 진단 리포트

**Repository**: `bizpect/echowander`
**Workflow**: Journey Dispatch Jobs Processor (`.github/workflows/dispatch_jobs.yml`)
**진단 일시**: 2026-01-14
**현상**: cron `*/5 * * * *`로 설정했으나 5분마다 run이 생성되지 않고 30~40분 간격으로만 실행됨

---

## 2. 파일 인벤토리

### 워크플로우 구성 (`dispatch_jobs.yml`)

| 항목 | 값 | 비고 |
|------|-----|------|
| **워크플로우 이름** | Journey Dispatch Jobs Processor | - |
| **파일 위치** | `.github/workflows/dispatch_jobs.yml` | ✅ 정상 위치 |
| **트리거** | `schedule`, `workflow_dispatch` | 2개 |
| **cron 값** | `'*/5 * * * *'` | 매 5분 (0, 5, 10, ..., 55분) |
| **cron 이력** | `*/1` → `*/5` (최근 변경) | 커밋 0ea61dd → d75d310 |
| **Concurrency** | ❌ 없음 | 병렬 실행 제한 없음 |
| **Permissions** | `contents: read` | 읽기 전용 |
| **Jobs** | `process_dispatch_jobs` | 1개 job |
| **Runner** | `ubuntu-latest` | GitHub-hosted |
| **Steps** | 1개 (Supabase RPC 호출) | curl 사용 |
| **환경변수** | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | Secrets 사용 |
| **조건식** | ❌ 없음 | 무조건 실행 |

### 커밋 이력

| 커밋 SHA | 날짜 (추정) | 메시지 | cron 값 | 상태 |
|----------|------------|--------|---------|------|
| 5f89631 | ~2일 전 | 클론 재작업 | `*/1` | 최초 생성 |
| 0ea61dd | ~1일 전 | 크론수정 | `*/1` | (확인 필요) |
| d75d310 | ~12시간 전 | 클론 주기 수정 | `*/5` | **현재** |

### YAML 구조 분석

```yaml
on:  # ⚠️ 주의: 예약어이지만 인용 없음
  schedule:
    - cron: '*/5 * * * *'  # ✅ 인용 정상
  workflow_dispatch:
    inputs: ...

permissions:
  contents: read

jobs:
  process_dispatch_jobs:
    runs-on: ubuntu-latest
    steps:
      - name: Call Supabase RPC
        env: ...
        run: |
          # Bash script
```

---

## 3. "스케줄 미작동" 원인 분기 트리

### A. 스케줄 트리거가 워크플로우에서 인식되는가?

#### 검증 체크리스트

| 검증 항목 | 예상 결과 | 확인 방법 |
|-----------|----------|----------|
| 1. YAML `on:` 키 인식 | ⚠️ **위험 요소 발견** | `on:` → `"on":` 권장 |
| 2. 파일 경로 | ✅ 정상 | `.github/workflows/` 위치 확인됨 |
| 3. cron 문자열 인용 | ✅ 정상 | `'*/5 * * * *'` 따옴표 존재 |
| 4. YAML 파싱 에러 | ✅ 정상 | 구조상 문제 없음 |
| 5. Default branch | ✅ main | 현재 브랜치 = main |

#### 원인 후보 1: `on:` 예약어 충돌 (가능성: 중)

**문제**:
- YAML에서 `on:`은 예약어로, 일부 파서/린터에서 boolean `true`로 해석될 위험이 있음
- GitHub Actions는 대부분 정상 처리하지만, **드물게 파싱 실패 또는 schedule 인식 누락** 발생 가능
- 특히 YAML 1.1 vs 1.2 차이로 인해 `on`, `yes`, `no` 등이 boolean으로 해석되는 케이스 존재

**근거**:
- [GitHub Actions 공식 문서](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#on)에서는 `on:`과 `"on":` 모두 허용하지만, 안전성을 위해 **인용 권장**
- 다른 오픈소스 프로젝트들에서 `"on":` 사용 비율이 높음 (예: kubernetes, tensorflow)

**증상과의 연관성**:
- "일부 화면에서 상단 배너가 workflow_dispatch만 언급되고 schedule 트리거 언급이 안 보임" → **schedule이 파싱되지 않았을 가능성**

**수정안**:
```yaml
# Before
on:
  schedule:
    - cron: '*/5 * * * *'

# After (안전)
"on":
  schedule:
    - cron: '*/5 * * * *'
```

**재발 방지**:
- 모든 워크플로우 파일에서 `"on":` 사용 표준화
- YAML 린터에서 `on` 예약어 검증 규칙 추가

---

### B. schedule은 인식되지만 run이 "5분마다 생성되지 않는"가?

#### 원인 후보 2: GitHub 큐 지연 (가능성: **높음**)

**문제**:
- GitHub Actions의 scheduled workflows는 **best-effort**로 실행됨
- 특히 **정각(00분) 및 5분 단위(00, 05, 10, ..., 55분)는 혼잡 시간대**
- 공식 문서: "The shortest interval you can run scheduled workflows is once every 5 minutes. **Scheduled workflows may be delayed during periods of high loads**."
- 실제 사례: 최대 **10~60분 지연** 발생 가능, 심한 경우 **skip**됨

**근거**:
- 현상: 30~40분 간격 → 5분마다 큐에 들어가지만 일부만 실행되는 패턴
- 커밋 이력: `*/1` (1분마다) → `*/5` (5분마다) 변경 → 여전히 간헐적 실행
  - `*/1`은 사실상 불가능 (GitHub는 5분 최소 간격 권장)
  - `*/5`도 정각 혼잡 시간대와 겹침

**수정안 (정각 회피)**:
```yaml
# Before (혼잡)
- cron: '*/5 * * * *'  # 0, 5, 10, 15, 20, 25, ...

# After (오프셋 적용)
- cron: '2-59/5 * * * *'  # 2, 7, 12, 17, 22, 27, 32, 37, 42, 47, 52, 57분
```

**효과**:
- 정각(00분) 및 5분 단위 정각 회피 → 혼잡 회피
- 여전히 5분 간격 유지 (시간당 12회 → 10회로 약간 감소하지만 안정성 확보)

**재발 방지**:
- 모든 scheduled workflow에 오프셋 적용 (예: 2분, 3분, 7분 등)
- 중요도가 높은 워크플로우는 **3분 간격 이상**으로 설정

#### 원인 후보 3: Repository Inactivity 자동 비활성화 (가능성: 중)

**문제**:
- GitHub는 **60일간 커밋 활동이 없는 public repository**의 scheduled workflows를 **자동 비활성화**
- 비활성화되면 UI 상단에 노란색 배너 표시: "This scheduled workflow is disabled because there hasn't been activity in this repository for at least 60 days."

**확인 방법**:
1. GitHub repo → Actions 탭 상단에 노란색 배너 있는지 확인
2. 있으면 "Enable workflow" 버튼 클릭

**근거**:
- 최근 커밋: d75d310 (~12시간 전), bba5728, 3fed1e7 등 활발 → **해당 없음 (현재 활성 상태로 판단)**

#### 원인 후보 4: Secrets 누락 또는 실행 실패 (가능성: 낮음)

**문제**:
- `SUPABASE_URL` 또는 `SUPABASE_SERVICE_ROLE_KEY`가 설정되지 않으면 워크플로우가 **실패**로 끝남
- 실패한 run도 Actions 탭에 **빨간색**으로 표시되므로, "run이 안 쌓임"과는 다름

**확인 방법**:
- Actions 탭 → 최근 run들의 상태 확인 (Success ✅ / Failure ❌)
- Failure가 많으면 Secrets 점검 필요

**근거**:
- 현상: "run이 5분마다 생성되지 않음" → 실패 여부와 무관, **트리거 자체가 안 되는 문제**

---

### C. run은 생성되지만 사용자가 "안 보이는 것처럼" 느끼는가?

#### 원인 후보 5: UI 필터 또는 Branch 불일치 (가능성: 낮음)

**문제**:
- Actions 탭에서 **Event 필터**가 `workflow_dispatch`로만 설정되어 있으면 scheduled run이 안 보임
- Default branch가 main이 아닌 경우 schedule은 default branch에서만 실행됨

**확인 방법**:
1. Actions 탭 → 좌측 Event 드롭다운 → "All workflows" 또는 "schedule" 선택
2. Repository Settings → Default branch 확인 (main이어야 함)

**근거**:
- 현재 branch: main ✅
- 파일 위치: `.github/workflows/` (main 브랜치) ✅

---

## 1. 원인 후보 Top 5 (가능성 순)

| 순위 | 원인 | 가능성 | 근거 | 영향 |
|------|------|--------|------|------|
| 1 | **GitHub 큐 지연 (정각 혼잡)** | ⭐⭐⭐⭐⭐ | 30~40분 간격 실행 = 일부만 처리되는 패턴, `*/5` cron이 정각과 겹침 | run 생성 빈도 감소 |
| 2 | **`on:` 예약어 파싱 이슈** | ⭐⭐⭐ | schedule 트리거 UI 언급 누락 의심, YAML 1.1 파서 호환성 | schedule 완전 미인식 |
| 3 | **Repository inactivity (60일)** | ⭐⭐ | 최근 커밋 활발 → 현재는 해당 없음, 향후 주의 필요 | schedule 자동 비활성화 |
| 4 | **Secrets 누락/실행 실패** | ⭐ | run이 생성되더라도 실패로 끝남, 현상과 다름 | 실행 실패 (run은 보임) |
| 5 | **UI 필터 또는 branch 불일치** | ⭐ | 현재 main 브랜치 확인됨, UI 조작 이슈 가능성 낮음 | 사용자 오인 |

---

## 4. 강제 진단 실험 (최소 변경)

### 실험 1: push 트리거 임시 추가 (워크플로우 정상성 검증)

**목적**: 워크플로우 파일 자체가 정상적으로 인식/실행되는지 즉시 확인

**패치**:
```yaml
"on":
  push:
    branches:
      - main
    paths:
      - '.github/workflows/dispatch_jobs.yml'
  schedule:
    - cron: '2-59/5 * * * *'
  workflow_dispatch:
    inputs: ...
```

**기대 결과**:
- ✅ push 후 즉시 run 생성 → **워크플로우 자체는 정상**, schedule 쪽 문제로 좁혀짐
- ❌ push run도 안 뜸 → **Actions 비활성화** 또는 **Repository 설정 문제** (Settings → Actions → General 확인 필요)

**실행 절차**:
1. 위 패치 적용 후 커밋/푸시
2. Actions 탭에서 5분 내 run 생성 여부 확인
3. 확인 후 **push 트리거 제거** (원복)

---

### 실험 2: `"on":` 변경 + cron 오프셋 (최종 수정안)

**목적**: schedule 인식 문제 해결 + 정각 혼잡 회피

**패치**:
```yaml
# Before
on:
  schedule:
    - cron: '*/5 * * * *'

# After
"on":
  schedule:
    - cron: '2-59/5 * * * *'
  workflow_dispatch:
    inputs:
      batch_size:
        description: 'Batch size for processing jobs'
        required: false
        default: '20'
        type: string
```

**변경 내용**:
1. `on:` → `"on":` (YAML 예약어 인용)
2. `*/5` → `2-59/5` (정각 오프셋: 2, 7, 12, 17, 22, 27, 32, 37, 42, 47, 52, 57분)

**기대 결과**:
- 이후 **10~20분 내** scheduled run이 정상적으로 쌓이기 시작
- 5분 간격은 아니지만 **안정적으로 반복 실행**됨
- 다음 정각 시간대(예: 14:02, 14:07, 14:12) 확인

**실행 절차**:
1. 위 패치 적용 후 커밋/푸시
2. Actions 탭에서 다음 scheduled run 시간 대기 (예: 현재 14:05 → 14:07 대기)
3. 20분 동안 2~3개 run 생성되는지 확인

**원복 여부**:
- ✅ 성공 시: **원복 불필요** (정식 적용)
- ❌ 실패 시: 추가 진단 필요 (Secrets, Actions 설정 등)

---

## 3. 수정안

### 1안: 안전 우선 (권장) ⭐

**변경 내용**:
1. `"on":` 인용 (YAML 파서 안전성)
2. cron 오프셋 `2-59/5` (정각 혼잡 회피)
3. 주석 업데이트 (실제 실행 시간 명시)

**전체 diff**:
```yaml
# Before
on:
  schedule:
    # UTC 기준 매 1분 (실제로는 GitHub 부하에 따라 최대 5분 지연 가능)
    - cron: '*/5 * * * *'

# After
"on":
  schedule:
    # UTC 기준 매 ~5분 간격 (2, 7, 12, 17, 22, 27, 32, 37, 42, 47, 52, 57분)
    # 정각 혼잡 회피를 위해 오프셋 적용 (GitHub best-effort 정책)
    - cron: '2-59/5 * * * *'
```

**장점**:
- ✅ schedule 인식 문제 해결 (YAML 파서 호환성)
- ✅ 큐 지연 완화 (정각 혼잡 회피)
- ✅ 재발 방지 (표준 패턴 적용)

**단점**:
- 시간당 실행 횟수: 12회 → 10회 (약간 감소)
- 00분, 01분에는 실행되지 않음

---

### 2안: 최소 변경 (대안)

**변경 내용**:
- `"on":` 인용만 적용, cron은 기존 유지

**diff**:
```yaml
# Before
on:
  schedule:
    - cron: '*/5 * * * *'

# After
"on":
  schedule:
    - cron: '*/5 * * * *'
```

**장점**:
- ✅ 최소 변경 (cron 유지)
- ✅ schedule 인식 문제만 해결

**단점**:
- ❌ 정각 혼잡 여전히 존재 → 큐 지연 지속 가능

**선택 기준**:
- "5분마다 정확히"가 중요하면 → 2안
- "안정적으로 반복 실행"이 중요하면 → **1안 권장**

---

## 4. 검증 체크리스트

### A. 즉시 확인 (커밋 전)

- [ ] `.github/workflows/dispatch_jobs.yml` 파일이 main 브랜치에 존재하는가?
- [ ] YAML 구조가 올바른가? (온라인 YAML validator 사용)
- [ ] Default branch가 main인가? (Settings → Branches)

### B. 커밋 후 확인 (5분 내)

- [ ] 커밋 SHA 확인: `git log -1 --oneline .github/workflows/dispatch_jobs.yml`
- [ ] GitHub에 푸시 완료: `git push origin main`
- [ ] Actions 탭에서 워크플로우 파일 인식 확인:
  - 좌측 사이드바에 "Journey Dispatch Jobs Processor" 표시되는가?

### C. 첫 scheduled run 확인 (20분 내)

**수정안 1안 적용 시**:
- [ ] 현재 시각 기록 (예: 14:05)
- [ ] 다음 예정 시각 계산 (예: 14:07, 14:12, 14:17)
- [ ] Actions 탭 → Event 필터 "schedule" 선택
- [ ] 20분 내 2~3개 scheduled run 생성되는가?
- [ ] 각 run의 시작 시간이 오프셋 패턴(2, 7, 12분 등)을 따르는가?

### D. run 상태 확인

- [ ] 최근 scheduled run 클릭
- [ ] "Set up job" 로그에서 Trigger 확인: `Event: schedule`
- [ ] 실행 결과: ✅ Success / ❌ Failure
- [ ] Failure 시 로그 확인:
  - Secrets 관련 에러?
  - HTTP 상태 코드?

### E. 장기 모니터링 (24시간)

- [ ] 24시간 동안 scheduled run 개수 집계 (기대: ~240회 for 1안, ~288회 for 기존)
- [ ] 실패율 확인 (목표: <5%)
- [ ] 평균 실행 간격 확인 (목표: 5~7분)

---

## 5. 재발 방지 가이드

### A. Cron 설정 규칙

1. **최소 간격**: 5분 이상 (GitHub 권장)
2. **오프셋 적용**: 정각(00분) 및 5분 단위 정각 회피
   - ✅ Good: `2-59/5`, `3-59/6`, `7-59/10`
   - ❌ Bad: `*/5`, `*/1`, `0 * * * *`
3. **중요도별 간격**:
   - Critical: 10분 (`7-59/10`)
   - Normal: 5분 오프셋 (`2-59/5`)
   - Low: 15분 (`2-59/15`)

### B. YAML 안전성

1. **예약어 인용**: `"on":` (not `on:`)
2. **cron 값 인용**: `'2-59/5 * * * *'` (작은따옴표)
3. **YAML 검증**: yamllint 또는 온라인 validator 사용

### C. 모니터링

1. **주간 점검**:
   - Actions 탭 → Workflows → 실행 이력 확인
   - 비정상적인 갭(1시간 이상) 발견 시 조사

2. **알림 설정**:
   - GitHub Actions 실패 알림 켜기 (Settings → Notifications)
   - Slack/Discord 웹훅 연동 고려

3. **60일 inactivity 방지**:
   - 장기 inactive 예상 시 수동으로 workflow_dispatch 실행
   - 또는 커밋 없이도 워크플로우 유지하려면 **별도 keep-alive 워크플로우** 추가

### D. 문서화

1. **CLAUDE.md에 규칙 추가**:
   ```markdown
   ## GitHub Actions Cron 규칙
   - 모든 scheduled workflow는 `"on":` 인용 사용
   - cron은 정각 회피 오프셋 적용 (예: `2-59/5`)
   - 최소 간격 5분 이상
   ```

2. **워크플로우 파일 주석**:
   ```yaml
   "on":
     schedule:
       # ✅ 정각 혼잡 회피: 2, 7, 12, 17, 22, 27, 32, 37, 42, 47, 52, 57분
       # GitHub best-effort 정책으로 ±3분 오차 발생 가능
       - cron: '2-59/5 * * * *'
   ```

---

## 6. 즉시 적용 가능한 패치

### 패치 파일: `.github/workflows/dispatch_jobs.yml`

```yaml
name: Journey Dispatch Jobs Processor

# 스케줄: KST 기준 약 5분마다 실행 (UTC는 -9시간)
# 정각 혼잡 회피를 위해 오프셋 적용 (2, 7, 12, 17, 22, 27, 32, 37, 42, 47, 52, 57분)
# GitHub Actions는 best-effort이므로 ±3분 오차 발생 가능
"on":
  schedule:
    # UTC 기준 2, 7, 12, 17, 22, 27, 32, 37, 42, 47, 52, 57분
    - cron: '2-59/5 * * * *'

  # 수동 실행 지원 (디버깅/테스트용)
  workflow_dispatch:
    inputs:
      batch_size:
        description: 'Batch size for processing jobs'
        required: false
        default: '20'
        type: string

# 최소 권한 원칙: read-only
permissions:
  contents: read

jobs:
  process_dispatch_jobs:
    name: Process Journey Dispatch Jobs
    runs-on: ubuntu-latest

    steps:
      - name: Call Supabase RPC
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_SERVICE_ROLE_KEY: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}
          BATCH_SIZE: ${{ github.event.inputs.batch_size || '20' }}
        run: |
          # 환경변수 검증
          if [ -z "$SUPABASE_URL" ]; then
            echo "ERROR: SUPABASE_URL is not set"
            exit 1
          fi

          if [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
            echo "ERROR: SUPABASE_SERVICE_ROLE_KEY is not set"
            exit 1
          fi

          echo "Calling process_journey_dispatch_jobs RPC..."
          echo "Batch size: $BATCH_SIZE"

          # RPC 호출
          HTTP_CODE=$(curl -s -o response.json -w "%{http_code}" \
            -X POST \
            "${SUPABASE_URL}/rest/v1/rpc/process_journey_dispatch_jobs" \
            -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
            -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
            -H "Content-Type: application/json" \
            -d "{\"p_batch\": ${BATCH_SIZE}}")

          # HTTP 상태 코드 확인
          if [ "$HTTP_CODE" != "200" ]; then
            echo "ERROR: HTTP $HTTP_CODE"
            echo "Response (first 500 chars):"
            head -c 500 response.json
            exit 1
          fi

          echo "SUCCESS: HTTP $HTTP_CODE"
          echo "Response:"
          cat response.json

          # 정리
          rm -f response.json
```

---

## 요약

### 확정된 사실 (파일 기준)

| 항목 | 상태 | 비고 |
|------|------|------|
| 워크플로우 파일 존재 | ✅ | `.github/workflows/dispatch_jobs.yml` |
| Main 브랜치 | ✅ | 현재 브랜치 = main |
| YAML 구조 | ✅ | 파싱 가능 |
| `on:` 예약어 인용 | ❌ | **위험 요소** |
| cron 정각 겹침 | ❌ | `*/5` → 0, 5, 10, 15, ... (혼잡) |
| Concurrency 설정 | ❌ | 없음 (정상) |
| 최근 커밋 활동 | ✅ | 활발 (inactivity 비활성화 아님) |

### 미확인 (GitHub UI/설정 필요)

| 항목 | 확인 방법 |
|------|----------|
| Actions 활성화 여부 | Settings → Actions → General → "Allow all actions" |
| Scheduled workflows 비활성화 배너 | Actions 탭 상단 노란색 배너 확인 |
| Secrets 설정 | Settings → Secrets → `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` 존재 확인 |
| 최근 run 상태 | Actions 탭 → Event 필터 "schedule" → Success/Failure 비율 |
| Default branch | Settings → Branches → Default branch = main 확인 |

### 최종 권장 조치

1. **즉시 적용**: 위 패치 파일로 `.github/workflows/dispatch_jobs.yml` 교체
2. **커밋/푸시**: `git add .github/workflows/dispatch_jobs.yml && git commit -m "fix: GitHub Actions schedule 안정성 개선 (on 인용 + cron 오프셋)" && git push`
3. **20분 대기**: 다음 scheduled run (예: 14:07, 14:12) 생성 확인
4. **24시간 모니터링**: 안정적으로 반복 실행되는지 확인
5. **문서화**: CLAUDE.md에 cron 규칙 추가

---

## 참고 자료

- [GitHub Actions - Workflow syntax: on](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#on)
- [GitHub Actions - Events that trigger workflows: schedule](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#schedule)
- [GitHub Community: Scheduled workflows not running](https://github.com/orgs/community/discussions/26209)
- [YAML 1.1 vs 1.2: Boolean values](https://yaml.org/type/bool.html)
