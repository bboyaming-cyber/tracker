-- ============================================================
--  PT Tracker — Supabase 資料庫結構
--  喺 Supabase → SQL Editor 貼上呢段，撳 RUN 一次即可
-- ============================================================

-- 1) 設定表：每個用戶一行，存場地固定成本等設定
create table if not exists settings (
  user_id       uuid primary key references auth.users(id) on delete cascade,
  alive_monthly numeric not null default 4000,   -- ALIVE 每月固定租金 ($12000/3 個月)
  rate_111      numeric not null default 80,      -- 111 每堂成本 (1 鐘 x $80)
  updated_at    timestamptz not null default now()
);

-- 2) 客戶表
create table if not exists clients (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  name          text not null,
  total_sessions int  not null,                   -- 套票總堂數
  remaining     int  not null,                    -- 剩餘堂數
  package_price numeric not null default 0,        -- 套票售價
  created_at    timestamptz not null default now()
);

-- 3) 上堂流水表 (每上一堂一行)
create table if not exists sessions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  client_id    uuid not null references clients(id) on delete cascade,
  client_name  text not null,                      -- 快照, 方便月結直接睇
  session_date date not null,
  location     text not null,                      -- ALIVE / 111 / Clubhouse / 其他
  cost         numeric not null default 0,          -- 該堂變動成本 (111=80, 其餘=0)
  revenue      numeric not null default 0,          -- 該堂攤分收入 (套票售價 / 總堂數)
  created_at   timestamptz not null default now()
);

create index if not exists idx_sessions_user_date on sessions(user_id, session_date);
create index if not exists idx_clients_user on clients(user_id);

-- ============================================================
--  Row Level Security: 確保每個用戶只睇到自己嘅資料
-- ============================================================
alter table settings enable row level security;
alter table clients  enable row level security;
alter table sessions enable row level security;

create policy "own settings" on settings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own clients" on clients
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own sessions" on sessions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
