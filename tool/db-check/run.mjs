// Isolated PostgreSQL with small Supabase Auth/Storage fixtures. No network or project credentials.
import {PGlite} from '@electric-sql/pglite';
import fs from 'node:fs';
const db=new PGlite();
const root=new URL('../../supabase/',import.meta.url);
await db.exec(`create role anon;create role authenticated;create schema auth;create schema storage;
create table auth.users(id uuid primary key,email text,raw_user_meta_data jsonb);
create function auth.uid()returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
grant usage on schema auth,storage to authenticated,anon;
create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
create table storage.objects(id bigint generated always as identity,bucket_id text,name text);
alter table storage.objects enable row level security; grant select,insert,delete on storage.objects to authenticated;
insert into auth.users values('aaaaaaaa-0000-4000-8000-000000000001','older@example.test','{}');`);
for(const f of ['migrations/001_magistore.sql','migrations/002_catalog.sql','migrations/003_uniform_sizes.sql','migrations/004_pickup_notifications.sql','migrations/005_remove_pickup_email.sql','tests/permissions_checkout.sql','tests/pickup_notifications.sql']){

 try{await db.exec(fs.readFileSync(new URL(f,root),'utf8'));console.log(f,'OK');
      if (f.endsWith('002_catalog.sql')) {
        const {rows:[{products,categories,secured,existing}]}=await db.query(`select
          (select count(*)::int from magistore.products) products,
          (select count(*)::int from magistore.categories) categories,
          (select count(*)::int from pg_tables where schemaname='magistore' and rowsecurity) secured,
          exists(select 1 from magistore.profiles where email='older@example.test') existing`);
        if (products!==15 || categories!==6 || secured!==6 || !existing) throw Error('Unexpected schema, seed or profile backfill');
      }}catch(e){console.error(e.message,e.where,e.detail);process.exit(1)}
}
await db.close();
