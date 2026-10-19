begin;
update public.system_parameters
set value = jsonb_set(jsonb_set(jsonb_set(value, '{primary}', '"openai"'), '{backup}', '"google"'), '{enabled}', 'true')
where key = 'ai.providers'
  and value->>'primary' = 'google'
  and value->>'backup' = 'openai'
  and value->>'enabled' = 'false'
  and value->'providers'->1->'models'->>'free' = 'gpt-6-luna'
  and value->'providers'->1->'models'->>'pro' = 'gpt-6-luna';
do $$ begin
  if not exists(select 1 from public.system_parameters where key='ai.providers' and value->>'primary'='openai' and value->>'enabled'='true') then
    raise exception 'AI activation preconditions changed; inspect settings before retrying';
  end if;
end $$;
commit;
select key, value->>'enabled' as enabled, value->>'primary' as primary, value->>'backup' as backup, updated_at
from public.system_parameters where key='ai.providers';
