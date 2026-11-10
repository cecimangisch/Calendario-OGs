-- Calendario compartido — esquema para Supabase
-- Pegá TODO esto en Supabase → SQL Editor → Run. Una sola vez.

-- 1. Una fila por calendario. El documento entero va en `doc`, y `version`
--    evita que dos personas que guardan a la vez se pisen sin enterarse.
create table if not exists public.cal_docs (
  cal        text primary key,
  doc        jsonb       not null default '{}'::jsonb,
  version    bigint      not null default 1,
  updated_at timestamptz not null default now()
);

-- 2. Nadie toca la tabla directamente: ni siquiera con la anon key.
alter table public.cal_docs enable row level security;
revoke all on public.cal_docs from anon, authenticated;

-- 3. Se entra sólo por estas dos funciones, y ambas piden el id del calendario.
--    O sea: tener la anon key (que es pública) no alcanza; hay que tener el link.
create or replace function public.cal_get(p_cal text)
returns json
language sql
security definer
set search_path = public
as $$
  select json_build_object('doc', doc, 'version', version)
  from public.cal_docs where cal = p_cal;
$$;

create or replace function public.cal_put(p_cal text, p_doc jsonb, p_version bigint)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  cur public.cal_docs%rowtype;
begin
  select * into cur from public.cal_docs where cal = p_cal for update;

  if not found then
    insert into public.cal_docs (cal, doc, version) values (p_cal, p_doc, 1);
    return json_build_object('version', 1);
  end if;

  -- quien guarda tiene que haber leído la última versión
  if cur.version <> p_version then
    return json_build_object(
      'conflict', true,
      'current', json_build_object('doc', cur.doc, 'version', cur.version));
  end if;

  update public.cal_docs
     set doc = p_doc, version = cur.version + 1, updated_at = now()
   where cal = p_cal;

  return json_build_object('version', cur.version + 1);
end;
$$;

revoke all on function public.cal_get(text)                from public, anon, authenticated;
revoke all on function public.cal_put(text, jsonb, bigint) from public, anon, authenticated;
grant execute on function public.cal_get(text)                to anon;
grant execute on function public.cal_put(text, jsonb, bigint) to anon;

-- 4. Tus datos de hoy, para no cargar nada a mano.
insert into public.cal_docs (cal, doc, version)
values ('db2918a8d4', '{"cities": [{"id": "mad", "name": "Madrid", "code": "MAD", "slot": 1}, {"id": "bue", "name": "Buenos Aires", "code": "BUE", "slot": 2}], "base": "mad", "people": [{"id": "p-ceci", "name": "Ceci", "stays": [{"city": "mad", "from": "2026-11-01", "to": "2027-02-28"}]}, {"id": "p-agus", "name": "Agus M", "stays": [{"city": "mad", "from": "2026-11-01", "to": "2026-11-20"}, {"city": "bue", "from": "2026-11-21", "to": "2026-12-12"}, {"city": "mad", "from": "2026-12-13", "to": "2027-02-28"}]}, {"id": "p-caro", "name": "Caro", "stays": [{"city": "mad", "from": "2026-11-01", "to": "2026-12-14"}, {"city": "bue", "from": "2026-12-15", "to": "2027-01-09"}, {"city": "mad", "from": "2027-01-10", "to": "2027-02-28"}]}, {"id": "p-palo", "name": "Palo", "stays": [{"city": "mad", "from": "2026-11-01", "to": "2026-12-15"}, {"city": "bue", "from": "2026-12-16", "to": "2027-01-14"}, {"city": "mad", "from": "2027-01-15", "to": "2027-02-28"}]}, {"id": "p-michi", "name": "Michi", "stays": [{"city": "mad", "from": "2026-11-01", "to": "2026-12-10"}, {"city": "bue", "from": "2026-12-11", "to": "2027-01-05"}, {"city": "mad", "from": "2027-01-06", "to": "2027-02-28"}]}, {"id": "p-bri", "name": "Bri", "stays": [{"city": "mad", "from": "2026-11-01", "to": "2026-12-10"}, {"city": "bue", "from": "2026-12-11", "to": "2027-01-05"}, {"city": "mad", "from": "2027-01-06", "to": "2027-02-28"}]}, {"id": "p-vir", "name": "Vir", "stays": [{"city": "mad", "from": "2026-11-01", "to": "2026-12-02"}, {"city": "bue", "from": "2026-12-03", "to": "2026-12-13"}, {"city": "mad", "from": "2026-12-14", "to": "2027-02-28"}]}, {"id": "pw173z8", "name": "Sofi", "stays": []}], "v": 1}'::jsonb, 1)
on conflict (cal) do nothing;
