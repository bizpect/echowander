insert into public.common_codes (code_type, code_value, name, sort_order)
values
  ('login_type', 'kakao', 'Kakao', 10),
  ('login_type', 'google', 'Google', 20),
  ('login_type', 'apple', 'Apple', 30),
  ('login_type', 'unknown', 'Unknown', 90),
  ('login_type', 'dev', 'Developer', 99),
  ('journey_status', 'CREATED', 'Created', 10),
  ('journey_status', 'WAITING', 'Waiting', 20),
  ('journey_status', 'COMPLETED', 'Completed', 90),
  ('journey_recipient_status', 'ASSIGNED', 'Assigned', 10),
  ('journey_recipient_status', 'RESPONDED', 'Responded', 20),
  ('journey_recipient_status', 'PASSED', 'Passed', 30),
  ('journey_recipient_status', 'REPORTED', 'Reported', 40),
  ('report_reason', 'SPAM', 'Spam', 10),
  ('report_reason', 'ABUSE', 'Abuse', 20),
  ('report_reason', 'OTHER', 'Other', 90),
  ('journey_filter_status', 'OK', 'Allowed', 10),
  ('journey_filter_status', 'HELD', 'Held', 20),
  ('journey_filter_status', 'REMOVED', 'Removed', 90),
  ('journey_action_type', 'PASS', 'Pass', 10),
  ('journey_action_type', 'REPLY', 'Reply', 20),
  ('journey_action_type', 'REPORT', 'Report', 30),
  ('journey_action_type', 'BLOCK', 'Block', 40),
  ('hide_reason', 'HIDE_REPORTED', 'Hidden due to report', 10),
  ('hide_reason', 'HIDE_BLOCKED', 'Hidden due to block', 20),
  ('ad_placement', 'SENT_DETAIL_GATE', 'Sent detail gate', 10),
  ('app_env', 'DEV', 'Development', 10),
  ('app_env', 'STG', 'Staging', 20),
  ('app_env', 'PROD', 'Production', 90),
  ('ad_network', 'ADMOB', 'AdMob', 10),
  ('reward_unlock_type', 'ADMOB_REWARDED', 'AdMob Rewarded', 10),
  ('ad_reward_event', 'REQUEST', 'Request', 10),
  ('ad_reward_event', 'SHOW', 'Show', 20),
  ('ad_reward_event', 'EARN', 'Earn', 30),
  ('ad_reward_event', 'DISMISS', 'Dismiss', 40),
  ('ad_reward_event', 'FAIL_LOAD', 'Fail load', 80),
  ('ad_reward_event', 'FAIL_SHOW', 'Fail show', 81),
  ('ad_reward_event', 'FAIL_CONFIG', 'Fail config', 90)
on conflict (code_type, code_value) do update
set name = excluded.name,
    sort_order = excluded.sort_order,
    updated_at = now();

insert into public.common_codes (code_type, code_value, name, labels, sort_order)
values
  (
    'board_key',
    'NOTICE',
    'Notice',
    '{"ko":"공지사항","en":"Notice","ja":"お知らせ","zh":"公告","es":"Avisos","fr":"Actualités","pt":"Avisos","pt_BR":"Avisos"}'::jsonb,
    10
  ),
  (
    'notice_type',
    'UPDATE',
    'Update',
    '{"ko":"업데이트","en":"Update","ja":"アップデート","zh":"更新","es":"Actualización","fr":"Mise à jour","pt":"Atualização","pt_BR":"Atualização"}'::jsonb,
    10
  ),
  (
    'notice_type',
    'NEWS',
    'News',
    '{"ko":"소식","en":"News","ja":"ニュース","zh":"新闻","es":"Noticias","fr":"Actualités","pt":"Notícias","pt_BR":"Notícias"}'::jsonb,
    20
  ),
  (
    'notice_type',
    'MAINTENANCE',
    'Maintenance',
    '{"ko":"점검","en":"Maintenance","ja":"メンテナンス","zh":"维护","es":"Mantenimiento","fr":"Maintenance","pt":"Manutenção","pt_BR":"Manutenção"}'::jsonb,
    30
  )
on conflict (code_type, code_value) do update
set name = excluded.name,
    labels = excluded.labels,
    sort_order = excluded.sort_order,
    updated_at = now();

insert into public.boards (board_key, is_active)
values ('NOTICE', true)
on conflict (board_key) do update
set is_active = excluded.is_active;

insert into public.board_posts (
  board_id,
  type_code,
  title,
  content,
  status,
  is_pinned,
  published_at
)
select b.id,
       'UPDATE',
       '서비스 업데이트 안내',
       '더 안정적인 경험을 위해 앱 내부 흐름을 개선했습니다. 최신 버전으로 업데이트해 주세요.',
       'PUBLISHED',
       true,
       now()
from public.boards b
where b.board_key = 'NOTICE'
  and not exists (
    select 1
    from public.board_posts bp
    where bp.board_id = b.id
      and bp.title = '서비스 업데이트 안내'
  );

insert into public.board_posts (
  board_id,
  type_code,
  title,
  content,
  status,
  is_pinned,
  published_at
)
select b.id,
       'NEWS',
       '새로운 기능 소식',
       '프로필과 메시지 흐름이 더 직관적으로 개선됩니다. 곧 자세한 소식을 전해드릴게요.',
       'PUBLISHED',
       false,
       now()
from public.boards b
where b.board_key = 'NOTICE'
  and not exists (
    select 1
    from public.board_posts bp
    where bp.board_id = b.id
      and bp.title = '새로운 기능 소식'
  );

insert into public.board_posts (
  board_id,
  type_code,
  title,
  content,
  status,
  is_pinned,
  published_at
)
select b.id,
       'MAINTENANCE',
       '정기 점검 안내',
       '안정적인 서비스 제공을 위해 점검이 예정되어 있습니다. 점검 시간 동안 일부 기능이 제한될 수 있습니다.',
       'PUBLISHED',
       false,
       now()
from public.boards b
where b.board_key = 'NOTICE'
  and not exists (
    select 1
    from public.board_posts bp
    where bp.board_id = b.id
      and bp.title = '정기 점검 안내'
  );

insert into storage.buckets (id, name, public)
values ('journey-images', 'journey-images', false)
on conflict (id) do update
set name = excluded.name,
    public = excluded.public;

insert into storage.buckets (id, name, public)
values ('profile-avatars', 'profile-avatars', false)
on conflict (id) do nothing;

-- 금칙어 시드 데이터 (닉네임용)
insert into public.forbidden_words (word, is_enabled)
values
  ('admin', true),
  ('administrator', true),
  ('moderator', true),
  ('test', true),
  ('null', true),
  ('undefined', true),
  ('echowander', true),
  ('에코원더', true)
on conflict (word) do update
set is_enabled = excluded.is_enabled,
    updated_at = now();

-- UGC moderation용 금칙어 시드 데이터 (구조만, 실제 운영 단어는 별도 관리)
insert into public.banned_terms (term, severity, category, is_regex, enabled)
values
  -- MASK 예시 (욕설 등)
  ('badword1', 'MASK', 'profanity', false, true),
  ('badword2', 'MASK', 'profanity', false, true),
  -- BLOCK 예시 (명백한 성적/혐오/협박 표현)
  ('explicit1', 'BLOCK', 'sexual', false, true),
  ('hate1', 'BLOCK', 'hate', false, true),
  ('threat1', 'BLOCK', 'threat', false, true)
on conflict do nothing;


-- =========================================================
-- banned_terms seed: 8 languages x 50 terms (TOTAL 400)
-- columns: (term, severity, category, is_regex, enabled)
-- =========================================================

insert into public.banned_terms (term, severity, category, is_regex, enabled) values
-- ------------------------------
-- ko (Korean) 50
-- ------------------------------
('씨발','MASK','profanity',false,true),
('시발','MASK','profanity',false,true),
('병신','MASK','profanity',false,true),
('좆','MASK','profanity',false,true),
('좆같','MASK','profanity',false,true),
('개새끼','MASK','profanity',false,true),
('새끼','MASK','profanity',false,true),
('미친놈','MASK','profanity',false,true),
('미친년','MASK','profanity',false,true),
('미쳤냐','MASK','profanity',false,true),
('지랄','MASK','profanity',false,true),
('염병','MASK','profanity',false,true),
('썅','MASK','profanity',false,true),
('썅년','MASK','profanity',false,true),
('썅놈','MASK','profanity',false,true),
('닥쳐','MASK','profanity',false,true),
('꺼져','MASK','profanity',false,true),
('꺼져라','MASK','profanity',false,true),
('엿먹어','MASK','profanity',false,true),
('좆까','MASK','profanity',false,true),
('좆까라','MASK','profanity',false,true),
('ㅂㅅ','MASK','profanity',false,true),
('ㅅㅂ','MASK','profanity',false,true),
('ㅈㄹ','MASK','profanity',false,true),
('개지랄','MASK','profanity',false,true),
('존나','MASK','profanity',false,true),
('존나게','MASK','profanity',false,true),
('개같','MASK','profanity',false,true),
('개새','MASK','profanity',false,true),
('개놈','MASK','profanity',false,true),

('야동','BLOCK','sexual',false,true),
('포르노','BLOCK','sexual',false,true),
('섹스','BLOCK','sexual',false,true),
('섹드립','BLOCK','sexual',false,true),
('자위','BLOCK','sexual',false,true),
('음란','BLOCK','sexual',false,true),
('성기','BLOCK','sexual',false,true),

('죽인다','BLOCK','threat',false,true),
('죽여','BLOCK','threat',false,true),
('죽여버릴','BLOCK','threat',false,true),
('죽이겠다','BLOCK','threat',false,true),
('패죽','BLOCK','threat',false,true),
('때려죽','BLOCK','threat',false,true),
('가만 안둔다','BLOCK','threat',false,true),
('찾아간다','BLOCK','threat',false,true),
('뒤져','BLOCK','threat',false,true),
('뒤질래','BLOCK','threat',false,true),

-- ------------------------------
-- en (English) 50
-- ------------------------------
('fuck','MASK','profanity',false,true),
('fucking','MASK','profanity',false,true),
('shit','MASK','profanity',false,true),
('bullshit','MASK','profanity',false,true),
('asshole','MASK','profanity',false,true),
('bastard','MASK','profanity',false,true),
('bitch','MASK','profanity',false,true),
('motherfucker','MASK','profanity',false,true),
('son of a bitch','MASK','profanity',false,true),
('dickhead','MASK','profanity',false,true),
('dick','MASK','profanity',false,true),
('prick','MASK','profanity',false,true),
('jerk','MASK','profanity',false,true),
('moron','MASK','profanity',false,true),
('idiot','MASK','profanity',false,true),
('stupid','MASK','profanity',false,true),
('shut up','MASK','profanity',false,true),
('piss off','MASK','profanity',false,true),
('go to hell','MASK','profanity',false,true),
('damn','MASK','profanity',false,true),
('cunt','MASK','profanity',false,true),
('twat','MASK','profanity',false,true),
('wanker','MASK','profanity',false,true),
('slut','MASK','profanity',false,true),
('whore','MASK','profanity',false,true),

('porn','BLOCK','sexual',false,true),
('porno','BLOCK','sexual',false,true),
('sex','BLOCK','sexual',false,true),
('sexting','BLOCK','sexual',false,true),
('sex video','BLOCK','sexual',false,true),
('nude','BLOCK','sexual',false,true),
('nudes','BLOCK','sexual',false,true),
('blowjob','BLOCK','sexual',false,true),
('handjob','BLOCK','sexual',false,true),
('cum','BLOCK','sexual',false,true),
('pussy','BLOCK','sexual',false,true),
('tits','BLOCK','sexual',false,true),
('boobs','BLOCK','sexual',false,true),
('dildo','BLOCK','sexual',false,true),
('masturbate','BLOCK','sexual',false,true),

('kill you','BLOCK','threat',false,true),
('i will kill you','BLOCK','threat',false,true),
('die','BLOCK','threat',false,true),
('i will find you','BLOCK','threat',false,true),
('i will hurt you','BLOCK','threat',false,true),
('i will beat you','BLOCK','threat',false,true),
('i will punch you','BLOCK','threat',false,true),
('i will stab you','BLOCK','threat',false,true),
('i will shoot you','BLOCK','threat',false,true),
('i will burn you','BLOCK','threat',false,true),

-- ------------------------------
-- ja (Japanese) 50
-- ------------------------------
('くそ','MASK','profanity',false,true),
('クソ','MASK','profanity',false,true),
('ばか','MASK','profanity',false,true),
('バカ','MASK','profanity',false,true),
('アホ','MASK','profanity',false,true),
('この野郎','MASK','profanity',false,true),
('てめえ','MASK','profanity',false,true),
('ちくしょう','MASK','profanity',false,true),
('ふざけんな','MASK','profanity',false,true),
('うざい','MASK','profanity',false,true),
('きもい','MASK','profanity',false,true),
('キモい','MASK','profanity',false,true),
('きしょい','MASK','profanity',false,true),
('むかつく','MASK','profanity',false,true),
('消えろ','MASK','profanity',false,true),
('消え失せろ','MASK','profanity',false,true),
('くたばれ','MASK','profanity',false,true),
('糞','MASK','profanity',false,true),
('死ね','BLOCK','threat',false,true),
('しね','BLOCK','threat',false,true),

('殺す','BLOCK','threat',false,true),
('殺してやる','BLOCK','threat',false,true),
('ぶっ殺す','BLOCK','threat',false,true),
('殴るぞ','BLOCK','threat',false,true),
('ぶん殴る','BLOCK','threat',false,true),
('しばくぞ','BLOCK','threat',false,true),
('ぶちのめす','BLOCK','threat',false,true),
('刺す','BLOCK','threat',false,true),
('ぶっ刺す','BLOCK','threat',false,true),
('燃やす','BLOCK','threat',false,true),

('エロ','BLOCK','sexual',false,true),
('エロい','BLOCK','sexual',false,true),
('エロ動画','BLOCK','sexual',false,true),
('ポルノ','BLOCK','sexual',false,true),
('セックス','BLOCK','sexual',false,true),
('オナニー','BLOCK','sexual',false,true),
('変態','BLOCK','sexual',false,true),
('ビッチ','BLOCK','sexual',false,true),
('ちんこ','BLOCK','sexual',false,true),
('ちんぽ','BLOCK','sexual',false,true),
('まんこ','BLOCK','sexual',false,true),
('おっぱい','BLOCK','sexual',false,true),
('乳首','BLOCK','sexual',false,true),
('裸','BLOCK','sexual',false,true),
('ヌード','BLOCK','sexual',false,true),

-- ------------------------------
-- zh (Chinese, Simplified) 50
-- ------------------------------
('他妈的','MASK','profanity',false,true),
('妈的','MASK','profanity',false,true),
('傻逼','MASK','profanity',false,true),
('傻b','MASK','profanity',false,true),
('逼','MASK','profanity',false,true),
('操','MASK','profanity',false,true),
('我操','MASK','profanity',false,true),
('操你','MASK','profanity',false,true),
('操你妈','MASK','profanity',false,true),
('你妈','MASK','profanity',false,true),
('王八蛋','MASK','profanity',false,true),
('滚','MASK','profanity',false,true),
('垃圾','MASK','profanity',false,true),
('废物','MASK','profanity',false,true),
('恶心','MASK','profanity',false,true),
('贱人','MASK','profanity',false,true),
('狗东西','MASK','profanity',false,true),
('混蛋','MASK','profanity',false,true),
('去死','BLOCK','threat',false,true),
('死吧','BLOCK','threat',false,true),

('我杀了你','BLOCK','threat',false,true),
('杀了你','BLOCK','threat',false,true),
('弄死你','BLOCK','threat',false,true),
('我弄死你','BLOCK','threat',false,true),
('打死你','BLOCK','threat',false,true),
('我打死你','BLOCK','threat',false,true),
('我找你','BLOCK','threat',false,true),
('我会找到你','BLOCK','threat',false,true),
('我会伤害你','BLOCK','threat',false,true),
('我会打你','BLOCK','threat',false,true),

('色情','BLOCK','sexual',false,true),
('黄色','BLOCK','sexual',false,true),
('黄网','BLOCK','sexual',false,true),
('成人视频','BLOCK','sexual',false,true),
('成人视频','BLOCK','sexual',false,true),
('色情视频','BLOCK','sexual',false,true),
('裸照','BLOCK','sexual',false,true),
('裸体','BLOCK','sexual',false,true),
('性','BLOCK','sexual',false,true),
('做爱','BLOCK','sexual',false,true),
('打炮','BLOCK','sexual',false,true),
('性交','BLOCK','sexual',false,true),
('鸡巴','BLOCK','sexual',false,true),
('阴茎','BLOCK','sexual',false,true),
('阴道','BLOCK','sexual',false,true),
('乳房','BLOCK','sexual',false,true),
('奶子','BLOCK','sexual',false,true),
('色狼','BLOCK','sexual',false,true),
('变态','BLOCK','sexual',false,true),
('porn','BLOCK','sexual',false,true),

-- ------------------------------
-- es (Spanish) 50
-- ------------------------------
('mierda','MASK','profanity',false,true),
('joder','MASK','profanity',false,true),
('carajo','MASK','profanity',false,true),
('cabrón','MASK','profanity',false,true),
('puta','MASK','profanity',false,true),
('puto','MASK','profanity',false,true),
('hijo de puta','MASK','profanity',false,true),
('gilipollas','MASK','profanity',false,true),
('pendejo','MASK','profanity',false,true),
('imbécil','MASK','profanity',false,true),
('idiota','MASK','profanity',false,true),
('estúpido','MASK','profanity',false,true),
('coño','MASK','profanity',false,true),
('culero','MASK','profanity',false,true),
('mamón','MASK','profanity',false,true),
('vete a la mierda','MASK','profanity',false,true),
('cállate','MASK','profanity',false,true),
('lárgate','MASK','profanity',false,true),
('asqueroso','MASK','profanity',false,true),
('basura','MASK','profanity',false,true),

('porno','BLOCK','sexual',false,true),
('pornografía','BLOCK','sexual',false,true),
('sexo','BLOCK','sexual',false,true),
('follar','BLOCK','sexual',false,true),
('coger','BLOCK','sexual',false,true),
('desnudo','BLOCK','sexual',false,true),
('desnuda','BLOCK','sexual',false,true),
('nude','BLOCK','sexual',false,true),
('nudes','BLOCK','sexual',false,true),
('pene','BLOCK','sexual',false,true),
('vagina','BLOCK','sexual',false,true),
('tetas','BLOCK','sexual',false,true),
('masturbar','BLOCK','sexual',false,true),
('paja','BLOCK','sexual',false,true),
('boquete','BLOCK','sexual',false,true),

('te mato','BLOCK','threat',false,true),
('voy a matarte','BLOCK','threat',false,true),
('te voy a matar','BLOCK','threat',false,true),
('muérete','BLOCK','threat',false,true),
('te reviento','BLOCK','threat',false,true),
('te parto la cara','BLOCK','threat',false,true),
('te apuñalo','BLOCK','threat',false,true),
('te disparo','BLOCK','threat',false,true),
('te quemo','BLOCK','threat',false,true),
('te voy a encontrar','BLOCK','threat',false,true),
('te busco','BLOCK','threat',false,true),
('te hago daño','BLOCK','threat',false,true),
('te pego','BLOCK','threat',false,true),
('te rompo','BLOCK','threat',false,true),
('te destruyo','BLOCK','threat',false,true),

-- ------------------------------
-- fr (French) 50
-- ------------------------------
('merde','MASK','profanity',false,true),
('putain','MASK','profanity',false,true),
('connard','MASK','profanity',false,true),
('conne','MASK','profanity',false,true),
('salaud','MASK','profanity',false,true),
('salope','MASK','profanity',false,true),
('bordel','MASK','profanity',false,true),
('enfoiré','MASK','profanity',false,true),
('bâtard','MASK','profanity',false,true),
('fils de pute','MASK','profanity',false,true),
('ta gueule','MASK','profanity',false,true),
('dégage','MASK','profanity',false,true),
('idiot','MASK','profanity',false,true),
('imbécile','MASK','profanity',false,true),
('stupide','MASK','profanity',false,true),
('crétin','MASK','profanity',false,true),
('trou du cul','MASK','profanity',false,true),
('connasse','MASK','profanity',false,true),
('va te faire foutre','MASK','profanity',false,true),
('nique','MASK','profanity',false,true),

('porno','BLOCK','sexual',false,true),
('pornographie','BLOCK','sexual',false,true),
('sexe','BLOCK','sexual',false,true),
('baiser','BLOCK','sexual',false,true),
('nudité','BLOCK','sexual',false,true),
('nude','BLOCK','sexual',false,true),
('nudes','BLOCK','sexual',false,true),
('fellatio','BLOCK','sexual',false,true),
('fellation','BLOCK','sexual',false,true),
('suce','BLOCK','sexual',false,true),
('branler','BLOCK','sexual',false,true),
('branlette','BLOCK','sexual',false,true),
('bite','BLOCK','sexual',false,true),
('chatte','BLOCK','sexual',false,true),
('nichons','BLOCK','sexual',false,true),

('je vais te tuer','BLOCK','threat',false,true),
('je te tue','BLOCK','threat',false,true),
('tuer','BLOCK','threat',false,true),
('crève','BLOCK','threat',false,true),
('je vais te buter','BLOCK','threat',false,true),
('je te bute','BLOCK','threat',false,true),
('je te casse la gueule','BLOCK','threat',false,true),
('je vais te frapper','BLOCK','threat',false,true),
('je te frappe','BLOCK','threat',false,true),
('je vais te retrouver','BLOCK','threat',false,true),
('je te retrouve','BLOCK','threat',false,true),
('je te détruis','BLOCK','threat',false,true),
('je vais te détruire','BLOCK','threat',false,true),
('je te fais du mal','BLOCK','threat',false,true),
('je vais te faire du mal','BLOCK','threat',false,true),

-- ------------------------------
-- pt (Portuguese - PT) 50
-- ------------------------------
('merda','MASK','profanity',false,true),
('caralho','MASK','profanity',false,true),
('porra','MASK','profanity',false,true),
('foda','MASK','profanity',false,true),
('foder','MASK','profanity',false,true),
('puta','MASK','profanity',false,true),
('filho da puta','MASK','profanity',false,true),
('cabrão','MASK','profanity',false,true),
('idiota','MASK','profanity',false,true),
('estúpido','MASK','profanity',false,true),
('imbecil','MASK','profanity',false,true),
('burro','MASK','profanity',false,true),
('palhaço','MASK','profanity',false,true),
('vai-te lixar','MASK','profanity',false,true),
('vai-te foder','MASK','profanity',false,true),
('vai para o caralho','MASK','profanity',false,true),
('cala-te','MASK','profanity',false,true),
('desgraçado','MASK','profanity',false,true),
('nojento','MASK','profanity',false,true),
('lixo','MASK','profanity',false,true),

('pornografia','BLOCK','sexual',false,true),
('porno','BLOCK','sexual',false,true),
('sexo','BLOCK','sexual',false,true),
('nude','BLOCK','sexual',false,true),
('nudes','BLOCK','sexual',false,true),
('pénis','BLOCK','sexual',false,true),
('vagina','BLOCK','sexual',false,true),
('mamas','BLOCK','sexual',false,true),
('tetas','BLOCK','sexual',false,true),
('masturbar','BLOCK','sexual',false,true),
('punheta','BLOCK','sexual',false,true),
('boquete','BLOCK','sexual',false,true),
('gozar','BLOCK','sexual',false,true),
('ejaculação','BLOCK','sexual',false,true),
('transar','BLOCK','sexual',false,true),

('vou-te matar','BLOCK','threat',false,true),
('vou te matar','BLOCK','threat',false,true),
('eu te mato','BLOCK','threat',false,true),
('morre','BLOCK','threat',false,true),
('morre logo','BLOCK','threat',false,true),
('vou-te bater','BLOCK','threat',false,true),
('vou te bater','BLOCK','threat',false,true),
('vou-te achar','BLOCK','threat',false,true),
('vou te achar','BLOCK','threat',false,true),
('vou te encontrar','BLOCK','threat',false,true),
('vou-te encontrar','BLOCK','threat',false,true),
('vou-te partir','BLOCK','threat',false,true),
('vou te partir','BLOCK','threat',false,true),
('vou-te quebrar','BLOCK','threat',false,true),
('vou te quebrar','BLOCK','threat',false,true),

-- ------------------------------
-- pt_BR (Portuguese - Brazil) 50
-- ------------------------------
('merda','MASK','profanity',false,true),
('caralho','MASK','profanity',false,true),
('porra','MASK','profanity',false,true),
('puta','MASK','profanity',false,true),
('filho da puta','MASK','profanity',false,true),
('fdp','MASK','profanity',false,true),
('vai se foder','MASK','profanity',false,true),
('vai tomar no cu','MASK','profanity',false,true),
('babaca','MASK','profanity',false,true),
('otário','MASK','profanity',false,true),
('idiota','MASK','profanity',false,true),
('imbecil','MASK','profanity',false,true),
('arrombado','MASK','profanity',false,true),
('desgraça','MASK','profanity',false,true),
('lixo','MASK','profanity',false,true),
('nojento','MASK','profanity',false,true),
('cala a boca','MASK','profanity',false,true),
('some daqui','MASK','profanity',false,true),
('inferno','MASK','profanity',false,true),
('maldito','MASK','profanity',false,true),

('pornografia','BLOCK','sexual',false,true),
('porno','BLOCK','sexual',false,true),
('sexo','BLOCK','sexual',false,true),
('nude','BLOCK','sexual',false,true),
('nudes','BLOCK','sexual',false,true),
('transar','BLOCK','sexual',false,true),
('trepar','BLOCK','sexual',false,true),
('punheta','BLOCK','sexual',false,true),
('boquete','BLOCK','sexual',false,true),
('gozar','BLOCK','sexual',false,true),
('buceta','BLOCK','sexual',false,true),
('pau','BLOCK','sexual',false,true),
('pênis','BLOCK','sexual',false,true),
('vagina','BLOCK','sexual',false,true),
('peitos','BLOCK','sexual',false,true),

('vou te matar','BLOCK','threat',false,true),
('eu vou te matar','BLOCK','threat',false,true),
('eu te mato','BLOCK','threat',false,true),
('morre','BLOCK','threat',false,true),
('morre logo','BLOCK','threat',false,true),
('vou te bater','BLOCK','threat',false,true),
('vou te arrebentar','BLOCK','threat',false,true),
('vou te quebrar','BLOCK','threat',false,true),
('vou te achar','BLOCK','threat',false,true),
('vou te encontrar','BLOCK','threat',false,true),
('vou te pegar','BLOCK','threat',false,true),
('eu vou te achar','BLOCK','threat',false,true),
('eu vou te encontrar','BLOCK','threat',false,true),
('vou acabar contigo','BLOCK','threat',false,true),
('vou te fazer mal','BLOCK','threat',false,true)
;
