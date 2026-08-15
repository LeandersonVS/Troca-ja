-- ============================================================
-- TROCA JÁ — schema completo (tabelas + triggers + RLS + storage + realtime)
-- Rodar em: Supabase Dashboard → SQL Editor → New query → colar tudo → Run
-- Pode ser rodado mais de uma vez sem quebrar (idempotente).
-- ============================================================

-- ---------- TABELAS ----------

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  city text,
  state text,
  avatar_url text,
  rating numeric default 5.0,
  trades int default 0,
  role text default 'user',
  created_at timestamptz default now()
);

create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  name text not null,
  category text not null,
  condition text,
  brand text,
  model text,
  year text,
  city text,
  state text,
  description text,
  wants text[] default '{}',
  status text not null default 'ativo'
    check (status in ('ativo','pausado','em_negociacao','trocado')),
  created_at timestamptz default now()
);
create index if not exists idx_products_status_created on products (status, created_at desc);
create index if not exists idx_products_owner on products (owner_id);

create table if not exists product_photos (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products(id) on delete cascade,
  path text not null,
  position int default 0
);
create index if not exists idx_photos_product on product_photos (product_id);

create table if not exists proposals (
  id uuid primary key default gen_random_uuid(),
  wanted_product_id uuid not null references products(id) on delete cascade,
  offered_product_id uuid not null references products(id) on delete cascade,
  from_user_id uuid not null references profiles(id) on delete cascade,
  to_user_id uuid not null references profiles(id) on delete cascade,
  status text not null default 'pendente'
    check (status in ('pendente','aceito','recusado')),
  created_at timestamptz default now()
);
create index if not exists idx_proposals_to on proposals (to_user_id, status);
create index if not exists idx_proposals_from on proposals (from_user_id);

create table if not exists matches (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references profiles(id) on delete cascade,
  product_a uuid not null references products(id) on delete cascade,
  user_b uuid not null references profiles(id) on delete cascade,
  product_b uuid not null references products(id) on delete cascade,
  created_at timestamptz default now()
);
create index if not exists idx_matches_users on matches (user_a, user_b);

create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references matches(id) on delete cascade,
  from_user uuid not null references profiles(id) on delete cascade,
  text text not null check (char_length(text) between 1 and 1000),
  created_at timestamptz default now()
);
create index if not exists idx_messages_match on messages (match_id, created_at);

create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  type text,
  text text,
  read boolean default false,
  created_at timestamptz default now()
);
create index if not exists idx_notifications_user on notifications (user_id, read, created_at desc);

-- ---------- TRIGGERS ----------

-- cria profile automaticamente no signup (lê name/city/state do metadata)
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name, city, state)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data->>'name',''), split_part(new.email,'@',1)),
    new.raw_user_meta_data->>'city',
    new.raw_user_meta_data->>'state'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- notifica destinatário quando recebe proposta
create or replace function public.handle_new_proposal()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  offered_name text;
  sender_name text;
begin
  select name into offered_name from products where id = new.offered_product_id;
  select name into sender_name from profiles where id = new.from_user_id;
  insert into notifications (user_id, type, text)
  values (new.to_user_id, 'proposal',
    coalesce(sender_name,'Alguém') || ' propôs trocar "' || coalesce(offered_name,'um produto') || '" com você.');
  return new;
end;
$$;

drop trigger if exists on_proposal_created on proposals;
create trigger on_proposal_created
  after insert on proposals
  for each row execute procedure public.handle_new_proposal();

-- decisão da proposta: aceite cria match, marca produtos e notifica
create or replace function public.handle_proposal_decision()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if new.status = 'aceito' and old.status = 'pendente' then
    insert into matches (user_a, product_a, user_b, product_b)
    values (new.from_user_id, new.offered_product_id, new.to_user_id, new.wanted_product_id);
    update products set status = 'em_negociacao'
      where id in (new.offered_product_id, new.wanted_product_id) and status = 'ativo';
    insert into notifications (user_id, type, text)
    values (new.from_user_id, 'match', 'Sua proposta foi aceita — deu match! Combine a troca pelo chat. 🎉');
  elsif new.status = 'recusado' and old.status = 'pendente' then
    insert into notifications (user_id, type, text)
    values (new.from_user_id, 'proposal', 'Sua proposta de troca foi recusada.');
  end if;
  return new;
end;
$$;

drop trigger if exists on_proposal_decided on proposals;
create trigger on_proposal_decided
  after update on proposals
  for each row execute procedure public.handle_proposal_decision();

-- ---------- RLS ----------

alter table profiles enable row level security;
alter table products enable row level security;
alter table product_photos enable row level security;
alter table proposals enable row level security;
alter table matches enable row level security;
alter table messages enable row level security;
alter table notifications enable row level security;

-- profiles
drop policy if exists "profiles visíveis a todos" on profiles;
create policy "profiles visíveis a todos" on profiles for select using (true);
drop policy if exists "dono edita próprio perfil" on profiles;
create policy "dono edita próprio perfil" on profiles for update
  using (auth.uid() = id) with check (auth.uid() = id);

-- products
drop policy if exists "produtos visíveis a todos" on products;
create policy "produtos visíveis a todos" on products for select using (true);
drop policy if exists "dono cria produto" on products;
create policy "dono cria produto" on products for insert with check (auth.uid() = owner_id);
drop policy if exists "dono edita produto" on products;
create policy "dono edita produto" on products for update
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
drop policy if exists "dono exclui produto" on products;
create policy "dono exclui produto" on products for delete
  using (auth.uid() = owner_id and status in ('ativo','pausado'));

-- product_photos
drop policy if exists "fotos visíveis a todos" on product_photos;
create policy "fotos visíveis a todos" on product_photos for select using (true);
drop policy if exists "dono do produto gerencia fotos" on product_photos;
create policy "dono do produto gerencia fotos" on product_photos for all
  using (exists(select 1 from products p where p.id = product_id and p.owner_id = auth.uid()))
  with check (exists(select 1 from products p where p.id = product_id and p.owner_id = auth.uid()));

-- proposals
drop policy if exists "vê proposta se envolvido" on proposals;
create policy "vê proposta se envolvido" on proposals for select
  using (auth.uid() = from_user_id or auth.uid() = to_user_id);
drop policy if exists "cria proposta como remetente" on proposals;
create policy "cria proposta como remetente" on proposals for insert
  with check (
    auth.uid() = from_user_id
    and auth.uid() <> to_user_id
    and exists(select 1 from products p where p.id = offered_product_id and p.owner_id = auth.uid() and p.status = 'ativo')
    and exists(select 1 from products p where p.id = wanted_product_id and p.owner_id = to_user_id and p.status = 'ativo')
  );
drop policy if exists "destinatário atualiza status" on proposals;
create policy "destinatário atualiza status" on proposals for update
  using (auth.uid() = to_user_id) with check (auth.uid() = to_user_id);

-- matches (criados pelo trigger security definer; clientes só leem)
drop policy if exists "vê match se participa" on matches;
create policy "vê match se participa" on matches for select
  using (auth.uid() = user_a or auth.uid() = user_b);

-- messages
drop policy if exists "mensagem só de match que participa" on messages;
create policy "mensagem só de match que participa" on messages for select
  using (exists(select 1 from matches m where m.id = match_id and auth.uid() in (m.user_a, m.user_b)));
drop policy if exists "envia mensagem só se participa" on messages;
create policy "envia mensagem só se participa" on messages for insert
  with check (
    auth.uid() = from_user
    and exists(select 1 from matches m where m.id = match_id and auth.uid() in (m.user_a, m.user_b))
  );

-- notifications (inseridas por triggers security definer; clientes leem e marcam como lida)
drop policy if exists "só vê própria notificação" on notifications;
create policy "só vê própria notificação" on notifications for select using (auth.uid() = user_id);
drop policy if exists "só dono marca como lida" on notifications;
create policy "só dono marca como lida" on notifications for update
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------- STORAGE ----------

insert into storage.buckets (id, name, public)
values ('product-photos', 'product-photos', true)
on conflict (id) do nothing;

drop policy if exists "fotos de produto são públicas para leitura" on storage.objects;
create policy "fotos de produto são públicas para leitura"
  on storage.objects for select
  using (bucket_id = 'product-photos');

drop policy if exists "usuário envia foto na própria pasta" on storage.objects;
create policy "usuário envia foto na própria pasta"
  on storage.objects for insert
  with check (
    bucket_id = 'product-photos'
    and auth.role() = 'authenticated'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "dono da pasta remove sua própria foto" on storage.objects;
create policy "dono da pasta remove sua própria foto"
  on storage.objects for delete
  using (bucket_id = 'product-photos' and auth.uid()::text = (storage.foldername(name))[1]);

-- ---------- REALTIME (chat) ----------

do $$
begin
  alter publication supabase_realtime add table messages;
exception when duplicate_object then null;
end $$;

-- ============================================================
-- FIM.
-- Recomendado (opcional) para login imediato após cadastro:
-- Dashboard → Authentication → Sign In / Providers → Email →
-- desativar "Confirm email". Com confirmação ativa, o app mostra
-- a tela "Confirme seu e-mail" após o cadastro.
-- ============================================================
