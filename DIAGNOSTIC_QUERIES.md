# block_sender_and_pass 디버깅 쿼리

## 1. 현재 로그인 유저 uid 확인
```sql
SELECT auth.uid() AS current_user_id;
```

## 2. recipientId=4 row 확인 (가장 중요)
```sql
SELECT
  id,
  journey_id,
  recipient_user_id,
  sender_user_id,
  status_code,
  is_hidden,
  created_at
FROM journey_recipients
WHERE id = 4;
```

**판정:**
- 여기 나온 `recipient_user_id`가 "지금 앱 로그인 유저"와 다르면, `not_recipient`는 정상 동작입니다.
- 문제는 `list_inbox_journeys`가 잘못된 `recipient_id`를 반환하거나, 클라가 다른 row의 `recipientId`를 들고 있는 것입니다.

## 3. "내가 가진 recipientId=4가 내 것인지" 확인 쿼리
```sql
SELECT id
FROM journey_recipients
WHERE id = 4
  AND recipient_user_id = auth.uid();
```

**결과 0 rows면:** 내 row가 아님 → 반환/매핑/필터 문제 확정

## 4. list_inbox_journeys가 반환하는 recipient_id 확인
```sql
SELECT recipient_id, journey_id, sender_user_id
FROM list_inbox_journeys(20, 0)
ORDER BY created_at DESC
LIMIT 10;
```

이 쿼리 결과의 `recipient_id`가 모두 내 row인지 확인:
```sql
SELECT jr.id
FROM journey_recipients jr
WHERE jr.id IN (
  SELECT recipient_id
  FROM list_inbox_journeys(20, 0)
  LIMIT 10
)
  AND jr.recipient_user_id = auth.uid();
```

**결과 개수가 일치하면:** `list_inbox_journeys`는 정상입니다.
**결과 개수가 불일치하면:** `list_inbox_journeys`가 잘못된 `recipient_id`를 반환하고 있습니다.
