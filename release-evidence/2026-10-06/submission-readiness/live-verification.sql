select exists(select 1 from supabase_migrations.schema_migrations where version='20261006021055') as migration_recorded,
  (select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname in ('content_reports','content_blocks') and c.relrowsecurity) as private_tables_with_rls,
  has_table_privilege('anon','public.content_reports','SELECT') as anon_can_read_reports,
  has_table_privilege('authenticated','public.content_blocks','SELECT') as users_can_read_blocks,
  has_function_privilege('anon','public.group_safety_action(text,uuid,text,text,uuid,text,text)','EXECUTE') as anon_can_impersonate_actor,
  has_function_privilege('authenticated','public.review_content_report(uuid,boolean)','EXECUTE') as users_can_moderate,
  has_function_privilege('service_role','public.group_safety_context(uuid,uuid,text,boolean)','EXECUTE') as service_can_check_safety,
  (select count(*) from pg_policies where schemaname='public' and policyname in ('groups_safety','rsvps_safety') and permissive='RESTRICTIVE') as restrictive_safety_policies;
