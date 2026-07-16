-- Fase 1: Traslados de presupuesto a Compras + SOLP
-- Correr en el SQL editor de Supabase. No lo ejecuta Claude (sin acceso a la base).
--
-- Contexto: cuando en un bloque de Planificación se saca un directo y se agrega
-- un contratista en el mismo bloque, se traslada presupuesto de mano de obra
-- (Nico) a Compras por el valor de los jornales futuros de ese directo en ese
-- bloque. Esta tabla registra cada traslado; no toca línea base ni costo real.

-- Presupuesto base de Compras (una sola fila vigente). El disponible se calcula
-- en la app como monto - suma de traslados activos (estado <> 'revertido').
create table if not exists presupuesto_compras (
  id uuid primary key default gen_random_uuid(),
  monto numeric not null,
  notas text,
  actualizado_en timestamptz not null default now(),
  actualizado_por text
);

create table if not exists traslados_compras (
  id uuid primary key default gen_random_uuid(),
  proyecto_id uuid not null references proyectos(id),
  bloque_id uuid references planificacion(id) on delete set null,
  persona_directo_id uuid not null references personal(id),
  persona_contratista_id uuid not null references personal(id),
  jornales numeric not null,
  horas_por_jornal numeric not null default 8,
  valor_hora numeric not null,
  monto numeric not null,
  fecha_desde date,
  fecha_hasta date,
  estado text not null default 'pendiente_aviso'
    check (estado in ('pendiente_aviso', 'avisado', 'contratado', 'revertido')),
  creado_en timestamptz not null default now(),
  creado_por text,
  revertido_en timestamptz,
  revertido_por text,
  notas text
);

create index if not exists idx_traslados_compras_estado on traslados_compras(estado);
create index if not exists idx_traslados_compras_proyecto on traslados_compras(proyecto_id);
create index if not exists idx_traslados_compras_bloque on traslados_compras(bloque_id);

-- RLS: se deja abierta a usuarios autenticados, igual que el resto de las tablas
-- de la app hoy. Los permisos por rol (quién puede confirmar/revertir un traslado)
-- quedan pendientes como tema aparte (toca RLS de payroll en general).
alter table presupuesto_compras enable row level security;
alter table traslados_compras enable row level security;

create policy "presupuesto_compras_all_authenticated" on presupuesto_compras
  for all to authenticated using (true) with check (true);

create policy "traslados_compras_all_authenticated" on traslados_compras
  for all to authenticated using (true) with check (true);

-- Carga inicial del presupuesto de Compras. Ajustar el monto antes de correr,
-- o correrlo aparte con el valor real.
-- insert into presupuesto_compras (monto, actualizado_por) values (0, 'pablospinetto@4housing.com.ar');
