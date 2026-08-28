-- Quest Designer migration runner
-- Usage: psql -U postgres -d wc3_pots -f run_all_quest_migrations.sql

\set ON_ERROR_STOP on
\echo 'Applying WC3 Manager Quest Designer schema...'
\ir 007_create_quest_designer.sql
\ir 008_add_quest_source_sync.sql
\echo 'Quest Designer schema is ready.'

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
      'quest_givers',
      'quests',
      'quest_objectives',
      'quest_rewards',
      'quest_prerequisites',
      'quest_voicelines',
      'quest_sequences',
      'quest_sequence_steps',
      'quest_we_dependencies'
  )
ORDER BY table_name;
