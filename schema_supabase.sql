-- ============================================================
-- STAGE 2 SERVER SCHEMA (Supabase / PostgreSQL)
-- Run once in Supabase: SQL Editor -> New query -> paste -> Run.
-- Same tables as the on-phone database; the app syncs row-by-row.
-- NOTE: written for PostgreSQL but not executed against a live server
--       during development - run it and tell me if any line errors.
-- ============================================================

-- helper: server stamps every write so phones can pull "what changed since X"
create or replace function set_server_ts() returns trigger as $$
begin new.server_ts := clock_timestamp(); return new; end; $$ language plpgsql;

-- ---------- master data ----------
create table if not exists projects (
  id text primary key, code text, name text, client text,
  contract_sum numeric default 0, retention_pct numeric default 5, currency text default 'RM',
  spacer_edge numeric default 1, spacer_spacing numeric default 2, spacer_extra numeric default 2,
  plugs_per_way numeric default 2, subduct_lines numeric default 3,
  start_date text, end_date text,
  updated_at text not null, deleted boolean default false, server_ts timestamptz default clock_timestamp()
);
create table if not exists rate_items (               -- contract rates (CONTROL sheet)
  id text primary key, project_id text not null references projects(id),
  code text, subtrade text, description text, unit text default 'm', pipe_size numeric, rate numeric default 0,
  updated_at text not null, deleted boolean default false, server_ts timestamptz default clock_timestamp()
);
create table if not exists labour_types (
  id text primary key, project_id text not null references projects(id),
  trade text, hourly_rate numeric default 0, planned_hrs_per_m numeric default 0,
  updated_at text not null, deleted boolean default false, server_ts timestamptz default clock_timestamp()
);
create table if not exists materials (
  id text primary key, project_id text not null references projects(id),
  code text, name text, unit text, unit_cost numeric default 0, wastage_allow numeric default 0, roll_length numeric,
  updated_at text not null, deleted boolean default false, server_ts timestamptz default clock_timestamp()
);
create table if not exists delay_reasons (
  id text primary key, project_id text not null references projects(id),
  code text, category text, name text,
  updated_at text not null, deleted boolean default false, server_ts timestamptz default clock_timestamp()
);
-- a work item = one pipe run (manhole to manhole) = the unit of progress and cost
create table if not exists work_items (
  id text primary key, project_id text not null references projects(id),
  seq numeric, manhole_ref text, ref_code text, zone text, subtrade text,
  pipe_size numeric, no_layer numeric default 1, no_way numeric, length_per_way numeric,
  subduct_pipes numeric default 0, rate_override numeric, drawing_ref text, remarks text,
  updated_at text not null, deleted boolean default false, server_ts timestamptz default clock_timestamp()
);
create table if not exists work_item_norms (          -- standard material qty per metre, derived from take-off
  id text primary key, project_id text not null references projects(id),
  work_item_id text not null, material_id text not null, qty_per_unit numeric not null,
  updated_at text not null, deleted boolean default false, server_ts timestamptz default clock_timestamp()
);

-- ---------- the daily site entry ----------
create table if not exists daily_reports (
  id text primary key, project_id text not null references projects(id),
  report_date text not null, weather text, rain_hours numeric default 0, notes text, entered_by text,
  updated_at text not null, deleted boolean default false, server_ts timestamptz default clock_timestamp()
);
create table if not exists daily_progress (
  id text primary key, project_id text not null references projects(id),
  report_id text not null, work_item_id text not null, qty_done numeric not null, remarks text,
  updated_at text not null, deleted boolean default false, server_ts timestamptz default clock_timestamp()
);
create table if not exists daily_labour (
  id text primary key, project_id text not null references projects(id),
  report_id text not null, work_item_id text not null, labour_type_id text not null,
  workers numeric not null, hours_each numeric default 8, hourly_rate numeric,
  updated_at text not null, deleted boolean default false, server_ts timestamptz default clock_timestamp()
);
create table if not exists daily_material_usage (
  id text primary key, project_id text not null references projects(id),
  report_id text not null, work_item_id text not null, material_id text not null,
  qty_used numeric not null, unit_cost numeric,
  updated_at text not null, deleted boolean default false, server_ts timestamptz default clock_timestamp()
);
create table if not exists daily_delays (
  id text primary key, project_id text not null references projects(id),
  report_id text not null, work_item_id text, reason_id text not null, hours_lost numeric default 0, description text,
  updated_at text not null, deleted boolean default false, server_ts timestamptz default clock_timestamp()
);
create table if not exists material_receipts (
  id text primary key, project_id text not null references projects(id),
  material_id text not null, receipt_date text not null, qty numeric not null, unit_cost numeric,
  supplier text, do_number text,
  updated_at text not null, deleted boolean default false, server_ts timestamptz default clock_timestamp()
);

-- ---------- triggers + indexes + security ----------
do $$
declare t text;
begin
  foreach t in array array['projects','rate_items','labour_types','materials','delay_reasons','work_items','work_item_norms',
    'daily_reports','daily_progress','daily_labour','daily_material_usage','daily_delays','material_receipts']
  loop
    execute format('drop trigger if exists trg_ts on %I', t);
    execute format('create trigger trg_ts before insert or update on %I for each row execute function set_server_ts()', t);
    execute format('create index if not exists ix_%s_ts on %I (server_ts)', t, t);
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists staff_all on %I', t);
    -- only signed-in users (create them in Supabase > Authentication > Users) can read/write
    execute format('create policy staff_all on %I for all to authenticated using (true) with check (true)', t);
  end loop;
end $$;
