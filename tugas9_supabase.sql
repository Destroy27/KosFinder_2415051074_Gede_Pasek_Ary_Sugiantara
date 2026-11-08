-- ============================================================================
-- KOSFINDER - SQL SETUP WORKSHEET 9
-- Authentication, Authorization, dan Push Notification
-- Mahasiswa : Gede Pasek Ary Sugiantara (2415051074)
-- Kelas     : PTI 5C
-- ============================================================================
-- Cara pakai:
-- 1. Buka Supabase Dashboard -> project KosFinder -> SQL Editor -> New query.
-- 2. Copy seluruh isi file ini, tempel, lalu klik Run.
-- 3. Supabase -> Authentication -> Providers -> Email:
--    nonaktifkan "Confirm email" agar akun baru langsung mendapat session
--    (opsional, memudahkan pengujian).
-- 4. Isi Project URL dan publishable/anon key pada
--    lib/config/supabase_config.dart.
-- ============================================================================

-- ============================================================================
-- BAGIAN 1 - TABEL PROFILES DAN ROLE (Praktik 3)
-- ============================================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  name text,
  role text not null default 'seeker'
    check (role in ('seeker', 'owner', 'admin')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Pengguna hanya boleh membaca profilnya sendiri. Tidak ada policy INSERT
-- karena baris dibuat oleh trigger, dan tidak ada policy DELETE.
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles
  for select
  to authenticated
  using (auth.uid() = id);

-- Pengguna boleh memperbarui profilnya sendiri. Kolom `role` dilindungi
-- dengan mencabut hak UPDATE pada kolom tersebut (lihat GRANT di bawah),
-- sehingga role tidak bisa dinaikkan sendiri dari aplikasi.
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

revoke all on public.profiles from anon;
revoke update on public.profiles from authenticated;
grant select on public.profiles to authenticated;
grant update (name) on public.profiles to authenticated;

-- ----------------------------------------------------------------------------
-- Trigger: setiap user baru otomatis mendapat baris profile.
-- Role hanya boleh 'seeker' atau 'owner'; 'admin' hanya diberikan manual.
-- ----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'name', ''),
    case
      when new.raw_user_meta_data ->> 'role' in ('seeker', 'owner')
        then new.raw_user_meta_data ->> 'role'
      else 'seeker'
    end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill profile untuk akun yang sudah ada sebelum trigger dibuat.
insert into public.profiles (id, email, name, role)
select
  id,
  email,
  coalesce(raw_user_meta_data ->> 'name', ''),
  'seeker'
from auth.users
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- Fungsi bantu untuk mengecek admin. SECURITY DEFINER dipakai agar fungsi
-- dapat membaca tabel profiles tanpa terhalang policy profiles_select_own.
-- ----------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- ============================================================================
-- BAGIAN 2 - TABEL KOS DAN ROW LEVEL SECURITY (Praktik 5)
-- ============================================================================

create table if not exists public.kos (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  name text not null,
  address text not null default '',
  price integer not null default 0 check (price >= 0),
  description text not null default '',
  is_verified boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists kos_owner_id_idx on public.kos (owner_id);
create index if not exists kos_created_at_idx on public.kos (created_at desc);

alter table public.kos enable row level security;

revoke all on public.kos from anon;
grant select, insert, update, delete on public.kos to authenticated;

-- 1. SELECT: semua pengguna yang sudah login boleh membaca daftar kos.
drop policy if exists "kos_select_authenticated" on public.kos;
create policy "kos_select_authenticated"
  on public.kos
  for select
  to authenticated
  using (true);

-- 2. INSERT: owner_id harus sama dengan user yang login, dan role harus
--    owner atau admin. Seeker tidak boleh menambah kos.
drop policy if exists "kos_insert_owner" on public.kos;
create policy "kos_insert_owner"
  on public.kos
  for insert
  to authenticated
  with check (
    auth.uid() = owner_id
    and exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role in ('owner', 'admin')
    )
  );

-- 3. UPDATE: hanya pemilik data.
drop policy if exists "kos_update_own" on public.kos;
create policy "kos_update_own"
  on public.kos
  for update
  to authenticated
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

-- 4. DELETE: hanya pemilik data.
drop policy if exists "kos_delete_own" on public.kos;
create policy "kos_delete_own"
  on public.kos
  for delete
  to authenticated
  using (auth.uid() = owner_id);

-- 5. ADMIN: boleh mengelola seluruh data sesuai kebijakan aplikasi.
drop policy if exists "kos_admin_all" on public.kos;
create policy "kos_admin_all"
  on public.kos
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ----------------------------------------------------------------------------
-- Pengaman tambahan: pemilik kos tidak boleh memverifikasi kosnya sendiri.
-- Hanya admin yang boleh mengubah kolom is_verified.
-- ----------------------------------------------------------------------------
create or replace function public.protect_verification_flag()
returns trigger
language plpgsql
as $$
begin
  if new.is_verified is distinct from old.is_verified
     and not public.is_admin() then
    new.is_verified := old.is_verified;
  end if;
  return new;
end;
$$;

drop trigger if exists protect_verification_flag on public.kos;
create trigger protect_verification_flag
  before update on public.kos
  for each row execute function public.protect_verification_flag();

-- ============================================================================
-- BAGIAN 3 - DEVICE TOKENS UNTUK PUSH NOTIFICATION (Praktik 9, opsional)
-- ============================================================================

create table if not exists public.device_tokens (
  token text primary key,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  platform text,
  updated_at timestamptz not null default now()
);

alter table public.device_tokens enable row level security;

revoke all on public.device_tokens from anon;
grant select, insert, update, delete on public.device_tokens to authenticated;

drop policy if exists "tokens_select_own" on public.device_tokens;
create policy "tokens_select_own"
  on public.device_tokens
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "tokens_insert_own" on public.device_tokens;
create policy "tokens_insert_own"
  on public.device_tokens
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "tokens_update_own" on public.device_tokens;
create policy "tokens_update_own"
  on public.device_tokens
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "tokens_delete_own" on public.device_tokens;
create policy "tokens_delete_own"
  on public.device_tokens
  for delete
  to authenticated
  using (auth.uid() = user_id);

-- ============================================================================
-- BAGIAN 4 - PROMOSI ADMIN (jalankan manual setelah akun terdaftar)
-- ============================================================================
-- Ganti email di bawah dengan email admin yang kamu daftarkan dari aplikasi.
--
-- update public.profiles
-- set role = 'admin'
-- where email = 'admin@contoh.com';
--
-- update public.profiles
-- set role = 'owner'
-- where email = 'owner@contoh.com';

-- ============================================================================
-- BAGIAN 5 - VERIFIKASI HASIL
-- ============================================================================
-- Cek RLS aktif pada kedua tabel (relrowsecurity harus true):
--
-- select relname, relrowsecurity
-- from pg_class
-- where relname in ('profiles', 'kos', 'device_tokens');
--
-- Cek daftar policy:
--
-- select tablename, policyname, cmd
-- from pg_policies
-- where schemaname = 'public'
-- order by tablename, policyname;

-- ============================================================================
-- BAGIAN 6 - DATA CONTOH (opsional)
-- ============================================================================
-- Daftarkan satu akun owner dari aplikasi, salin UUID-nya dari
-- Authentication > Users, lalu jalankan:
--
-- insert into public.kos (owner_id, name, address, price, description)
-- values (
--   'UUID_AKUN_OWNER',
--   'Kos Melati Putri',
--   'Jl. Udayana No. 12, Singaraja',
--   750000,
--   'Kamar mandi dalam, Wi-Fi, 5 menit ke Undiksha.'
-- );
