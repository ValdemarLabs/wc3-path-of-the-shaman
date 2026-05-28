-- Add copy_base_abilities boolean column to items table
do $$
begin
    if not exists (select 1 from information_schema.columns where table_name='items' and column_name='copy_base_abilities') then
        alter table items add column copy_base_abilities boolean not null default false;
    end if;
end$$;
