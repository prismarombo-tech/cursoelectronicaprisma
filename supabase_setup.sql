-- ElectroQuest: base de datos y funciones para progreso + ranking global.
-- Ejecuta todo este archivo en Supabase > SQL Editor > New query.

create table if not exists public.electroquest_players (
  id text primary key,
  name text not null,
  course text not null,
  pin_hash text not null,
  xp integer not null default 0 check (xp >= 0),
  completed jsonb not null default '[]'::jsonb,
  unlocked integer not null default 1 check (unlocked >= 1),
  correct integer not null default 0 check (correct >= 0),
  attempts integer not null default 0 check (attempts >= 0),
  best_streak integer not null default 0 check (best_streak >= 0),
  question_stats jsonb not null default '{}'::jsonb,
  reviews jsonb not null default '[]'::jsonb,
  badges jsonb not null default '[]'::jsonb,
  created_at bigint not null,
  last_seen bigint not null,
  updated_at timestamptz not null default now()
);

alter table public.electroquest_players enable row level security;
revoke all on public.electroquest_players from anon, authenticated;

create or replace function public.eq_login(
  p_id text,
  p_name text,
  p_course text,
  p_pin_hash text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.electroquest_players%rowtype;
  now_ms bigint := floor(extract(epoch from clock_timestamp()) * 1000);
begin
  select * into r from public.electroquest_players where id = p_id;

  if not found then
    insert into public.electroquest_players(id,name,course,pin_hash,created_at,last_seen)
    values(p_id,left(trim(p_name),42),left(trim(p_course),18),p_pin_hash,now_ms,now_ms)
    returning * into r;
  else
    if r.pin_hash <> p_pin_hash then
      raise exception 'PIN_INCORRECTO';
    end if;
    update public.electroquest_players
       set name = left(trim(p_name),42), course = left(trim(p_course),18), last_seen = now_ms, updated_at = now()
     where id = p_id
     returning * into r;
  end if;

  return jsonb_build_object(
    'id',r.id,'name',r.name,'course',r.course,'xp',r.xp,
    'completed',r.completed,'unlocked',r.unlocked,'correct',r.correct,
    'attempts',r.attempts,'bestStreak',r.best_streak,
    'questionStats',r.question_stats,'reviews',r.reviews,'badges',r.badges,
    'createdAt',r.created_at,'lastSeen',r.last_seen
  );
end;
$$;

create or replace function public.eq_save(
  p_id text,
  p_pin_hash text,
  p_data jsonb
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  saved integer;
begin
  update public.electroquest_players
     set name = left(coalesce(p_data->>'name',name),42),
         course = left(coalesce(p_data->>'course',course),18),
         xp = greatest(0,coalesce((p_data->>'xp')::integer,xp)),
         completed = coalesce(p_data->'completed',completed),
         unlocked = greatest(1,coalesce((p_data->>'unlocked')::integer,unlocked)),
         correct = greatest(0,coalesce((p_data->>'correct')::integer,correct)),
         attempts = greatest(0,coalesce((p_data->>'attempts')::integer,attempts)),
         best_streak = greatest(0,coalesce((p_data->>'bestStreak')::integer,best_streak)),
         question_stats = coalesce(p_data->'questionStats',question_stats),
         reviews = coalesce(p_data->'reviews',reviews),
         badges = coalesce(p_data->'badges',badges),
         last_seen = coalesce((p_data->>'lastSeen')::bigint,last_seen),
         updated_at = now()
   where id = p_id and pin_hash = p_pin_hash;
  get diagnostics saved = row_count;
  if saved = 0 then raise exception 'PERFIL_O_PIN_INVALIDO'; end if;
  return true;
end;
$$;

create or replace function public.eq_leaderboard()
returns table(
  id text,
  name text,
  course text,
  xp integer,
  completed_count integer,
  correct integer,
  attempts integer,
  best_streak integer
)
language sql
security definer
set search_path = public
as $$
  select p.id, p.name, p.course, p.xp,
         jsonb_array_length(p.completed) as completed_count,
         p.correct, p.attempts, p.best_streak
    from public.electroquest_players p
   order by jsonb_array_length(p.completed) desc, p.xp desc, p.correct desc, p.updated_at asc
   limit 200;
$$;

create or replace function public.eq_reset(
  p_id text,
  p_pin_hash text
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted integer;
begin
  delete from public.electroquest_players where id = p_id and pin_hash = p_pin_hash;
  get diagnostics deleted = row_count;
  if deleted = 0 then raise exception 'PERFIL_O_PIN_INVALIDO'; end if;
  return true;
end;
$$;

revoke all on function public.eq_login(text,text,text,text) from public;
revoke all on function public.eq_save(text,text,jsonb) from public;
revoke all on function public.eq_leaderboard() from public;
revoke all on function public.eq_reset(text,text) from public;

grant execute on function public.eq_login(text,text,text,text) to anon, authenticated;
grant execute on function public.eq_save(text,text,jsonb) to anon, authenticated;
grant execute on function public.eq_leaderboard() to anon, authenticated;
grant execute on function public.eq_reset(text,text) to anon, authenticated;
