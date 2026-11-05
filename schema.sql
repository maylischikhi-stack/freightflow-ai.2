-- FreightFlow AI MVP - exécuter dans Supabase SQL Editor
create extension if not exists pgcrypto;
create table if not exists public.companies(
 id uuid primary key default gen_random_uuid(), name text not null, created_at timestamptz default now()
);
create table if not exists public.company_members(
 id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade, role text not null default 'admin',
 unique(company_id,user_id)
);
create table if not exists public.shipments(
 id uuid primary key default gen_random_uuid(), company_id uuid references public.companies(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade, reference text not null,
 shipper text, consignee text, origin text, destination text, status text not null default 'open',
 created_at timestamptz default now()
);
create table if not exists public.documents(
 id uuid primary key default gen_random_uuid(), company_id uuid references public.companies(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 shipment_id uuid references public.shipments(id) on delete set null,
 file_name text not null, storage_path text not null, mime_type text not null,
 document_type text default 'À classifier',
 status text not null default 'uploaded' check(status in ('uploaded','processing','review','validated','error')),
 extracted_data jsonb, confidence jsonb, mindee_inference_id text, created_at timestamptz default now(), validated_at timestamptz
);
create table if not exists public.anomalies(
 id uuid primary key default gen_random_uuid(), company_id uuid references public.companies(id) on delete cascade,
 document_id uuid references public.documents(id) on delete cascade, user_id uuid references auth.users(id), description text not null,
 field_name text, severity text not null default 'medium', resolved_at timestamptz, created_at timestamptz default now()
);
create table if not exists public.audit_logs(
 id uuid primary key default gen_random_uuid(), company_id uuid references public.companies(id) on delete cascade,
 user_id uuid references auth.users(id), action text not null, details text, created_at timestamptz default now()
);
create table if not exists public.subscriptions(
 id uuid primary key default gen_random_uuid(), company_id uuid references public.companies(id) on delete cascade,
 stripe_customer_id text, stripe_subscription_id text, plan text not null default 'starter',
 monthly_document_limit integer not null default 300, status text not null default 'inactive',
 current_period_end timestamptz, created_at timestamptz default now()
);
alter table public.companies enable row level security;
alter table public.company_members enable row level security;
alter table public.shipments enable row level security;
alter table public.documents add column if not exists mindee_inference_id text;
alter table public.documents enable row level security;
alter table public.anomalies enable row level security;
alter table public.audit_logs enable row level security;
alter table public.subscriptions enable row level security;
-- Drop existing policies first so this schema can be safely re-applied.
drop policy if exists "members read companies" on public.companies;
drop policy if exists "users read own memberships" on public.company_members;
drop policy if exists "members manage shipments" on public.shipments;
drop policy if exists "members manage documents" on public.documents;
drop policy if exists "users manage own anomalies" on public.anomalies;
drop policy if exists "members read audit" on public.audit_logs;
drop policy if exists "members read subscription" on public.subscriptions;
drop policy if exists "users upload own files" on public.storage.objects;
drop policy if exists "users read own files" on public.storage.objects;
drop policy if exists "users delete own files" on public.storage.objects;
drop policy if exists "users insert audit logs" on public.audit_logs;
-- Helper: company access based on membership
create or replace function public.is_company_member(cid uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.company_members m where m.company_id=cid and m.user_id=auth.uid()); $$;
create policy "members read companies" on public.companies for select using(public.is_company_member(id));
create policy "users read own memberships" on public.company_members for select using(user_id=auth.uid());
create policy "members manage shipments" on public.shipments for all using(public.is_company_member(company_id) or user_id=auth.uid()) with check(user_id=auth.uid());
create policy "members manage documents" on public.documents for all using(public.is_company_member(company_id) or user_id=auth.uid()) with check(user_id=auth.uid());
create policy "users manage own anomalies" on public.anomalies for all using(user_id=auth.uid() or public.is_company_member(company_id)) with check(user_id=auth.uid() or public.is_company_member(company_id));
create policy "members read audit" on public.audit_logs for select using(public.is_company_member(company_id));
create policy "members read subscription" on public.subscriptions for select using(public.is_company_member(company_id));
-- Private storage bucket. File path convention: <auth.uid()>/<random>-filename
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('freight-documents','freight-documents',false,26214400,array['application/pdf','image/jpeg','image/png'])
on conflict(id) do nothing;
create policy "users upload own files" on storage.objects for insert to authenticated
with check(bucket_id='freight-documents' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "users read own files" on storage.objects for select to authenticated
using(bucket_id='freight-documents' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "users delete own files" on storage.objects for delete to authenticated
using(bucket_id='freight-documents' and (storage.foldername(name))[1]=auth.uid()::text);
-- NOTE: company onboarding trigger/invitation flow and company-level policies are next implementation tasks.

create index if not exists documents_user_status_created_idx on public.documents(user_id,status,created_at desc);
create index if not exists documents_shipment_idx on public.documents(shipment_id);
create index if not exists anomalies_company_created_idx on public.anomalies(company_id,created_at desc);

create policy "users insert audit logs" on public.audit_logs for insert with check(user_id=auth.uid());
