-- Smart Parking Management System POC
create extension if not exists pgcrypto;

create table if not exists public.parking_spaces (
 id uuid primary key default gen_random_uuid(),
 space_number text unique not null,
 status text not null default 'available' check(status in ('available','occupied','reserved','maintenance')),
 created_at timestamptz not null default now()
);
create table if not exists public.vehicles (
 id uuid primary key default gen_random_uuid(),
 license_plate text unique not null,
 vehicle_type text not null check(vehicle_type in ('Car','Bike','Van','Truck')),
 owner_name text,
 owner_phone text,
 created_at timestamptz not null default now()
);
create table if not exists public.parking_sessions (
 id uuid primary key default gen_random_uuid(),
 vehicle_id uuid not null references public.vehicles(id) on delete restrict,
 parking_space_id uuid not null references public.parking_spaces(id) on delete restrict,
 entry_time timestamptz not null,
 exit_time timestamptz,
 duration_minutes integer,
 fee numeric(10,2) not null default 0 check(fee >= 0),
 status text not null default 'active' check(status in ('active','completed','cancelled')),
 created_at timestamptz not null default now()
);
create table if not exists public.payments (
 id uuid primary key default gen_random_uuid(),
 parking_session_id uuid not null references public.parking_sessions(id) on delete restrict,
 amount numeric(10,2) not null check(amount >= 0),
 payment_method text not null check(payment_method in ('Cash','Card','Mobile Payment')),
 status text not null default 'pending' check(status in ('pending','paid','failed')),
 paid_at timestamptz,
 created_at timestamptz not null default now()
);
create table if not exists public.parking_settings (
 id uuid primary key default gen_random_uuid(),
 first_hour_rate numeric(10,2) not null default 100 check(first_hour_rate >= 0),
 additional_hour_rate numeric(10,2) not null default 50 check(additional_hour_rate >= 0),
 updated_at timestamptz not null default now()
);
create index if not exists idx_sessions_vehicle_status on public.parking_sessions(vehicle_id,status);
create index if not exists idx_sessions_space_status on public.parking_sessions(parking_space_id,status);
create index if not exists idx_sessions_entry on public.parking_sessions(entry_time);
create index if not exists idx_payments_created on public.payments(created_at);

alter table public.parking_spaces enable row level security;
alter table public.vehicles enable row level security;
alter table public.parking_sessions enable row level security;
alter table public.payments enable row level security;
alter table public.parking_settings enable row level security;

create policy "poc public spaces" on public.parking_spaces for all to anon,authenticated using(true) with check(true);
create policy "poc public vehicles" on public.vehicles for all to anon,authenticated using(true) with check(true);
create policy "poc public sessions" on public.parking_sessions for all to anon,authenticated using(true) with check(true);
create policy "poc public payments" on public.payments for all to anon,authenticated using(true) with check(true);
create policy "poc public settings" on public.parking_settings for all to anon,authenticated using(true) with check(true);

-- Recommended transactional entry function.
create or replace function public.create_parking_entry(p_vehicle_id uuid,p_space_id uuid)
returns public.parking_sessions
language plpgsql
security definer
as $$
declare v public.parking_sessions;
begin
 if exists(select 1 from public.parking_sessions where vehicle_id=p_vehicle_id and status='active') then raise exception 'Vehicle is already parked'; end if;
 if not exists(select 1 from public.parking_spaces where id=p_space_id and status='available') then raise exception 'Parking space is not available'; end if;
 insert into public.parking_sessions(vehicle_id,parking_space_id,entry_time,status,fee) values(p_vehicle_id,p_space_id,now(),'active',0) returning * into v;
 update public.parking_spaces set status='occupied' where id=p_space_id;
 return v;
end $$;

-- Seed only when tables are empty.
insert into public.parking_spaces(space_number,status)
select 'P'||lpad(g::text,2,'0'),case when g<=2 then 'occupied' else 'available' end from generate_series(1,50) g
where not exists(select 1 from public.parking_spaces);

insert into public.vehicles(license_plate,vehicle_type,owner_name,owner_phone)
select * from (values
('LEA-1234','Car','Ali Raza','03001234567'),('LEB-5678','Car','Sara Khan','03011234567'),
('ABC-2020','Bike','Usman Ali','03121234567'),('LHR-7865','Van','Hassan Ahmed','03211234567'),
('ISB-4521','Car','Ayesha Malik','03331234567'),('KHI-9912','Car','Bilal Shah','03451234567'),
('LEC-3344','Truck','Hamza Noor','03051234567'),('LEA-7788','Car','Maha Iqbal','03151234567'),
('LEB-9012','Bike','Zain Tariq','03251234567'),('LHE-2468','Car','Daniyal Khan','03351234567')
) v(license_plate,vehicle_type,owner_name,owner_phone)
where not exists(select 1 from public.vehicles);

insert into public.parking_settings(first_hour_rate,additional_hour_rate)
select 100,50 where not exists(select 1 from public.parking_settings);

-- Create two initial active sessions only if none exist.
insert into public.parking_sessions(vehicle_id,parking_space_id,entry_time,status,fee)
select v.id,s.id,now()-interval '45 minutes','active',0
from public.vehicles v join public.parking_spaces s on s.space_number='P01'
where v.license_plate='LEA-1234' and not exists(select 1 from public.parking_sessions);
insert into public.parking_sessions(vehicle_id,parking_space_id,entry_time,status,fee)
select v.id,s.id,now()-interval '90 minutes','active',0
from public.vehicles v join public.parking_spaces s on s.space_number='P02'
where v.license_plate='LEB-5678' and not exists(select 1 from public.parking_sessions where vehicle_id=v.id);
