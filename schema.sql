-- مخطط تأسيسي للمراجعة فقط. نفّذه في مشروع Supabase جديد بعد مراجعة السياسات.
-- لا تضف مفاتيح سرية أو service_role داخل ملفات المتصفح.
create extension if not exists pgcrypto;

create table if not exists public.app_settings (
  id boolean primary key default true check (id),
  mill_name text not null default 'وحدة إنتاج زيت الزيتون البدر',
  default_milling_rate numeric(10,2) not null default 0.70 check (default_milling_rate >= 0),
  updated_at timestamptz not null default now()
);
insert into public.app_settings (id) values (true) on conflict (id) do nothing;

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  full_name text not null check (length(trim(full_name)) > 0),
  phone text,
  address text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.olive_receipts (
  id uuid primary key default gen_random_uuid(),
  receipt_no bigint generated always as identity unique,
  customer_id uuid not null references public.customers(id),
  gross_kg numeric(12,2) not null check (gross_kg > 0),
  tare_kg numeric(12,2) not null default 0 check (tare_kg >= 0),
  net_kg numeric(12,2) generated always as (gross_kg - tare_kg) stored,
  milling_rate numeric(10,2) not null check (milling_rate >= 0),
  milling_fee numeric(14,2) generated always as (round((gross_kg - tare_kg) * milling_rate, 2)) stored,
  status text not null default 'received' check (status in ('received','queued','processing','completed','cancelled')),
  notes text,
  created_at timestamptz not null default now(),
  check (tare_kg <= gross_kg)
);

create table if not exists public.processing_batches (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null unique references public.olive_receipts(id),
  started_at timestamptz,
  finished_at timestamptz,
  oil_output_l numeric(12,2) not null default 0 check (oil_output_l >= 0),
  pomace_kg numeric(12,2) not null default 0 check (pomace_kg >= 0),
  notes text,
  created_at timestamptz not null default now(),
  check (finished_at is null or started_at is null or finished_at >= started_at)
);

create table if not exists public.oil_lots (
  id uuid primary key default gen_random_uuid(),
  lot_no bigint generated always as identity unique,
  owner_type text not null check (owner_type in ('customer','mill')),
  customer_id uuid references public.customers(id),
  processing_batch_id uuid references public.processing_batches(id),
  produced_l numeric(12,2) not null check (produced_l >= 0),
  created_at timestamptz not null default now(),
  check ((owner_type='customer' and customer_id is not null) or (owner_type='mill' and customer_id is null))
);

create table if not exists public.customer_account_entries (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id),
  receipt_id uuid references public.olive_receipts(id),
  entry_type text not null check (entry_type in ('milling_fee','payment','advance','adjustment')),
  debit numeric(14,2) not null default 0 check (debit >= 0),
  credit numeric(14,2) not null default 0 check (credit >= 0),
  payment_method text,
  reference text,
  notes text,
  created_at timestamptz not null default now(),
  check (debit = 0 or credit = 0)
);

create table if not exists public.oil_deliveries (
  id uuid primary key default gen_random_uuid(),
  delivery_no bigint generated always as identity unique,
  customer_id uuid not null references public.customers(id),
  redeemed_at timestamptz,
  status text not null default 'issued' check (status in ('issued','redeemed','cancelled')),
  notes text,
  created_at timestamptz not null default now()
);
create table if not exists public.oil_delivery_items (
  id uuid primary key default gen_random_uuid(),
  delivery_id uuid not null references public.oil_deliveries(id),
  oil_lot_id uuid not null references public.oil_lots(id),
  quantity_l numeric(12,2) not null check (quantity_l > 0)
);

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  description text not null,
  amount numeric(14,2) not null check (amount > 0),
  expense_date date not null default current_date,
  supplier text,
  reference text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid,
  action text not null,
  entity_table text not null,
  entity_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- مهم: لا تُفعّل الوصول العام ولا تضع سياسة USING(true) على الجداول التشغيلية.
-- قبل إدخال بيانات حقيقية: أضف تسجيل دخول، وسياسات RLS مقصورة على المالك/المستخدم المصرح،
-- ودوال SQL ذرية للتحقق من الرصيد وصرف وصل التسليم مرة واحدة فقط.
