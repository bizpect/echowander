# Dispatch Outbox Fix Report

## 변경 계획 (5줄)
1. create_journey RPC를 Outbox 기반으로 교체해 job을 반드시 생성한다.
2. 누락된 WAITING journey를 찾아 pending job으로 일괄 복구한다.
3. AFTER INSERT 트리거로 WAITING insert 시 job을 멱등 enqueue한다.
4. 보안/권한/alias 규칙을 재확인하고 함수 권한을 정리한다.
5. 검증 쿼리와 수동 테스트 시나리오로 정상 흐름을 확인한다.

## 적용 가이드
- `supabase/sql/08_dispatch_jobs_outbox_fix.sql`를 실행한다.
- 적용 직후 repair SQL이 포함되어 있으므로 바로 누락 복구가 수행된다.

## 인벤토리 표 (파일:라인)
| 구분 | 파일 | 라인 |
| --- | --- | --- |
| create_journey 교체 | `supabase/sql/08_dispatch_jobs_outbox_fix.sql` | 8 |
| outbox upsert | `supabase/sql/08_dispatch_jobs_outbox_fix.sql` | 114 |
| repair SQL | `supabase/sql/08_dispatch_jobs_outbox_fix.sql` | 142 |
| 재발 방지 트리거 | `supabase/sql/08_dispatch_jobs_outbox_fix.sql` | 172 |
| 권한 설정 | `supabase/sql/08_dispatch_jobs_outbox_fix.sql` | 208 |

## 변경 파일 목록
- `supabase/sql/08_dispatch_jobs_outbox_fix.sql`
- `DISPATCH_OUTBOX_FIX_REPORT.md`

## 핵심 diff 요약 (재발 방지 관점)
- create_journey가 WAITING insert 직후 outbox job을 멱등 생성한다.
- 누락 복구 SQL로 기존 WAITING 대상의 미생성 job을 일괄 회복한다.
- AFTER INSERT 트리거로 직접 insert 경로에서도 job이 항상 생성된다.
- 반환 컬럼을 journey_created_at로 통일해 클라이언트 호환을 확보한다.

## 규칙 준수 체크
- 권한: create_journey는 authenticated만 execute, process_journey_dispatch_jobs는 service_role만 유지.
- alias 규칙: SELECT/EXISTS 등 모든 테이블에 alias 사용 및 alias.column 표기 적용.
- 보안: security definer + search_path=public 설정.
- 멱등: outbox insert는 ON CONFLICT로 상태/카운트 초기화.
- direct 호출 탐지/차단 체크: `rg -n "supabase\.(from|rpc|storage)" lib` 실행.

## 검증 SQL / 수동 테스트 시나리오
1) 앱에서 메시지 전송 1회.
2) pending 생성 확인:
```sql
select journey_id, status, attempt_count, last_error
from public.journey_dispatch_jobs
order by created_at desc
limit 5;
```
3) GitHub Actions 워커 수동 실행 1회 후 상태 확인:
```sql
select journey_id, status, last_error, updated_at
from public.journey_dispatch_jobs
order by updated_at desc
limit 10;
```
4) journey_recipients ASSIGNED 확인:
```sql
select *
from public.journey_recipients
where journey_id = '<최근 journey_id>'
order by created_at desc;
```

## 롤백 플랜
- `supabase/sql/08_dispatch_jobs_outbox_fix.sql` 적용 전 상태로 돌아가려면 이전 create_journey 정의를 재적용한다.
- 트리거 롤백: `drop trigger if exists trg_enqueue_journey_dispatch_job on public.journeys;`와 `drop function if exists public.enqueue_journey_dispatch_job();` 실행.
- repair SQL은 단순 insert이므로 롤백이 필요할 경우 job 테이블에서 해당 범위를 수동 삭제한다.
