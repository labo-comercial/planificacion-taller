-- Fase: Contenedores de uso interno (Base Neuquén)
-- Correr en el SQL editor de Supabase. No lo ejecuta Claude (sin acceso a la base).
--
-- Contexto: ciertos contenedores están reservados para uso interno de la empresa
-- y NO deben computar en ningún indicador de rental (parque total, utilización,
-- desglose por estado, fuera de servicio, control de gestión). Quedan en el
-- padrón como "reservado", marcados con uso_interno = true; la app los excluye
-- de todos los indicadores y los muestra con un badge "uso interno".

-- 1) Columna nueva. Aditiva, default false: no cambia el comportamiento de
--    ningún trailer existente hasta que se lo marque explícitamente.
alter table planificacion_trailers
  add column if not exists uso_interno boolean not null default false;

-- 2) (VERIFICACIÓN — opcional, correr ANTES del update)
--    Confirmá que el código guardado en la base coincide EXACTO con la lista de
--    abajo (mayúsculas, espacio y guion incluidos). Si esta consulta no devuelve
--    las 5 filas, ajustá los códigos del update al formato real antes de correrlo.
-- select codigo, estado, uso_interno
--   from planificacion_trailers
--  where sede = 'neuquen'
--    and codigo in (
--      'POCU 020418-2', 'TPHU 818736-2', 'WFHU 130895-4', 'DFSU 665127-7', 'CLHU 834894-6'
--    );

-- 3) Marcar los contenedores de uso interno de Neuquén.
--    Deja el estado en "reservado" (siguen en stock como reservados) y solo
--    activa el flag. Ajustá la lista de códigos si la verificación de arriba no
--    devolvió las 5 filas.
update planificacion_trailers
   set uso_interno = true
 where sede = 'neuquen'
   and codigo in (
     'POCU 020418-2',
     'TPHU 818736-2',
     'WFHU 130895-4',
     'DFSU 665127-7',
     'CLHU 834894-6'
   );

-- El SQL editor muestra la cantidad de filas afectadas por el update: deberían
-- ser 5. Si son menos, algún código no coincidió con el formato guardado.
