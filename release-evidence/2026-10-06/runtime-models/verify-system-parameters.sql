select jsonb_build_object(
  'project', 'cswdcbmywzzisovsgwac',
  'parameter_key', p.key,
  'enabled', p.value->'enabled',
  'primary', p.value->>'primary',
  'backup', p.value->>'backup',
  'models', (select jsonb_agg(jsonb_build_object('provider', v->>'id', 'models', v->'models')) from jsonb_array_elements(p.value->'providers') v),
  'updated_at', p.updated_at,
  'history_entries', (select count(*) from public.system_parameter_history where key=p.key),
  'rls_enabled', (select bool_and(relrowsecurity) from pg_class where oid in ('public.system_parameters'::regclass, 'public.system_parameter_history'::regclass)),
  'client_table_access', (select bool_or(has_table_privilege(r, t, perm)) from unnest(array['anon','authenticated']) r cross join unnest(array['public.system_parameters','public.system_parameter_history']) t cross join unnest(array['SELECT','INSERT','UPDATE','DELETE']) perm),
  'service_can_read_and_update', has_table_privilege('service_role','public.system_parameters','SELECT') and has_table_privilege('service_role','public.system_parameters','UPDATE'),
  'quota_table', to_regclass('public.upstream_usage'),
  'reservations_table', to_regclass('public.ai_reservations')
) as verification
from public.system_parameters p where p.key='ai.providers';
