-- SCHEMA DRAFT ONLY: apply to a disposable test project first.
-- Production requires reviewed RLS policies, constraints, transactional RPCs and tests.
create extension if not exists pgcrypto;

create type public.owner_kind as enum ('customer', 'mill');
create type public.receipt_status as enum ('draft', 'issued', 'partially_fulfilled', 'fulfilled', 'cancelled');
create type public.payment_method as enum ('cash', 'bank_transfer', 'check', 'other');

create table public.app_settings (
  id uuid primary key default gen_random_uuid(),
  mill_name text not null default 'وحدة إنتاج زيت الزيتون البدر',
  milling_rate_per_kg numeric(12,3) not null default 0.70 check (milling_rate_per_kg >= 0),
  currency_code char(3) not null default 'MAD',
  season_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.customers (
  id uuid primary key default gen_random_uuid(),
  customer_code text unique,
  full_name text not null,
  phone text,
  address text,
  notes text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id)
);

create table public.olive_receipts (
  id uuid primary key default gen_random_uuid(),
  receipt_no bigint generated always as identity unique,
  customer_id uuid not null references public.customers(id),
  received_at timestamptz not null default now(),
  gross_weight_kg numeric(14,3) not null check (gross_weight_kg >= 0),
  tare_weight_kg numeric(14,3) not null default 0 check (tare_weight_kg >= 0),
  net_weight_kg numeric(14,3) generated always as (gross_weight_kg - tare_weight_kg) stored,
  queue_status text not null default 'waiting' check (queue_status in ('waiting','in_process','processed','cancelled')),
  notes text,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id),
  check (gross_weight_kg >= tare_weight_kg)
);

create table public.processing_batches (
  id uuid primary key default gen_random_uuid(),
  batch_no bigint generated always as identity unique,
  started_at timestamptz,
  completed_at timestamptz,
  status text not null default 'planned' check (status in ('planned','in_process','completed','cancelled')),
  operator_notes text,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id),
  check (completed_at is null or started_at is null or completed_at >= started_at)
);

create table public.batch_receipts (
  batch_id uuid not null references public.processing_batches(id),
  olive_receipt_id uuid not null references public.olive_receipts(id),
  processed_weight_kg numeric(14,3) not null check (processed_weight_kg > 0),
  primary key (batch_id, olive_receipt_id)
);

create table public.inventory_locations (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  location_type text not null default 'tank' check (location_type in ('tank','drum','warehouse','other')),
  capacity_l numeric(14,3) check (capacity_l is null or capacity_l >= 0),
  is_active boolean not null default true
);

create table public.oil_lots (
  id uuid primary key default gen_random_uuid(),
  lot_no bigint generated always as identity unique,
  owner_type public.owner_kind not null,
  customer_id uuid references public.customers(id),
  batch_id uuid references public.processing_batches(id),
  location_id uuid references public.inventory_locations(id),
  produced_at timestamptz not null default now(),
  quantity_l numeric(14,3) not null check (quantity_l >= 0),
  quality_grade text,
  notes text,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id),
  check ((owner_type = 'customer' and customer_id is not null) or (owner_type = 'mill' and customer_id is null))
);

create table public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  oil_lot_id uuid not null references public.oil_lots(id),
  from_location_id uuid references public.inventory_locations(id),
  to_location_id uuid references public.inventory_locations(id),
  movement_type text not null check (movement_type in ('production','transfer','delivery','sale','adjustment','return')),
  quantity_l numeric(14,3) not null check (quantity_l > 0),
  reference_type text,
  reference_id uuid,
  occurred_at timestamptz not null default now(),
  reason text,
  created_by uuid references auth.users(id)
);

create table public.service_charges (
  id uuid primary key default gen_random_uuid(),
  olive_receipt_id uuid not null unique references public.olive_receipts(id),
  weight_kg numeric(14,3) not null check (weight_kg >= 0),
  rate_per_kg numeric(12,3) not null check (rate_per_kg >= 0),
  total_amount numeric(14,2) generated always as (round(weight_kg * rate_per_kg, 2)) stored,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id)
);

create table public.financial_transactions (
  id uuid primary key default gen_random_uuid(),
  transaction_no bigint generated always as identity unique,
  customer_id uuid references public.customers(id),
  direction text not null check (direction in ('inflow','outflow')),
  category text not null,
  amount numeric(14,2) not null check (amount > 0),
  method public.payment_method not null default 'cash',
  transaction_at timestamptz not null default now(),
  reference_type text,
  reference_id uuid,
  notes text,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id)
);

create table public.delivery_vouchers (
  id uuid primary key default gen_random_uuid(),
  voucher_no bigint generated always as identity unique,
  owner_type public.owner_kind not null,
  customer_id uuid references public.customers(id),
  status public.receipt_status not null default 'issued',
  issued_at timestamptz not null default now(),
  fulfilled_at timestamptz,
  notes text,
  created_by uuid references auth.users(id),
  check ((owner_type = 'customer' and customer_id is not null) or (owner_type = 'mill' and customer_id is null))
);

create table public.delivery_voucher_items (
  id uuid primary key default gen_random_uuid(),
  voucher_id uuid not null references public.delivery_vouchers(id),
  oil_lot_id uuid not null references public.oil_lots(id),
  quantity_l numeric(14,3) not null check (quantity_l > 0),
  delivered_quantity_l numeric(14,3) not null default 0 check (delivered_quantity_l >= 0 and delivered_quantity_l <= quantity_l)
);

create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  expense_no bigint generated always as identity unique,
  category text not null,
  expense_kind text not null check (expense_kind in ('fixed','variable')),
  description text not null,
  amount numeric(14,2) not null check (amount > 0),
  expense_date date not null default current_date,
  payment_method public.payment_method not null default 'cash',
  supplier_name text,
  notes text,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id)
);

create table public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id),
  action text not null,
  table_name text not null,
  record_id text,
  old_data jsonb,
  new_data jsonb,
  occurred_at timestamptz not null default now()
);

create index idx_olive_receipts_customer_date on public.olive_receipts(customer_id, received_at desc);
create index idx_olive_receipts_queue on public.olive_receipts(queue_status, received_at);
create index idx_oil_lots_owner_customer on public.oil_lots(owner_type, customer_id);
create index idx_inventory_movements_lot_date on public.inventory_movements(oil_lot_id, occurred_at desc);
create index idx_financial_transactions_customer_date on public.financial_transactions(customer_id, transaction_at desc);
create index idx_expenses_date on public.expenses(expense_date desc);

-- Intentionally no permissive public RLS policies here. Add reviewed policies before exposing tables.


-- Initial settings for وحدة إنتاج زيت الزيتون البدر.
insert into public.app_settings (mill_name, milling_rate_per_kg, currency_code, season_name)
select 'وحدة إنتاج زيت الزيتون البدر', 0.70, 'MAD', 'موسم 2026-2027'
where not exists (select 1 from public.app_settings);

-- Each processed batch can contain one or more received olive deliveries,
-- but customer ownership of the produced oil must remain explicit.
create table public.production_allocations (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references public.processing_batches(id),
  olive_receipt_id uuid not null references public.olive_receipts(id),
  customer_id uuid not null references public.customers(id),
  produced_quantity_l numeric(14,3) not null check (produced_quantity_l >= 0),
  quality_grade text,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id),
  unique (batch_id, olive_receipt_id),
  unique (id, customer_id)
);

create index idx_production_allocations_customer on public.production_allocations(customer_id, created_at desc);

-- Do not expose the tables to anonymous users. Before deployment, configure RLS
-- and execute sensitive operations through authenticated server-side RPCs.
