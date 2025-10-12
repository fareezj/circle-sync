-- Step 1: Drop existing circle_members table entirely
drop table if exists public.circle_members cascade;

-- Step 2: Create profiles table first
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  name text,
  email text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Step 3: Set up Row Level Security (RLS) on profiles
alter table public.profiles enable row level security;

-- Step 4: Create policies for profiles
create policy "Public profiles are viewable by everyone." on profiles
  for select using (true);

create policy "Users can insert their own profile." on profiles
  for insert with check (auth.uid() = id);

create policy "Users can update own profile." on profiles
  for update using (auth.uid() = id);

-- Step 5: Now recreate circle_members table with correct foreign key
create table public.circle_members (
  id bigserial not null,
  circle_id text not null,
  user_id uuid not null,
  joined_at timestamp with time zone null default now(),
  role text null default 'member'::text,
  constraint circle_members_pkey primary key (id),
  constraint circle_members_circle_id_user_id_key unique (circle_id, user_id),
  constraint circle_members_circle_id_fkey foreign key (circle_id) references circles (circle_id) on delete cascade,
  constraint circle_members_user_id_fkey foreign key (user_id) references public.profiles (id) on delete cascade
) tablespace pg_default;

-- Step 6: Create indexes for circle_members
create index if not exists idx_circle_members_circle_id on public.circle_members using btree (circle_id) tablespace pg_default;
create index if not exists idx_circle_members_user_id on public.circle_members using btree (user_id) tablespace pg_default;

-- Step 7: Set up RLS for circle_members
alter table public.circle_members enable row level security;

-- Step 8: Create policies for circle_members (simplified to avoid recursion)
create policy "Users can view all circle members" on circle_members
  for select using (true);

create policy "Users can insert themselves into circles" on circle_members
  for insert with check (user_id = auth.uid());

create policy "Users can update their own circle membership" on circle_members
  for update using (user_id = auth.uid());

create policy "Users can delete their own circle membership" on circle_members
  for delete using (user_id = auth.uid());

-- Step 9: Create a function to automatically create a profile when a user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email)
  values (new.id, new.raw_user_meta_data->>'name', new.email);
  return new;
end;
$$ language plpgsql security definer;

-- Step 10: Create a trigger to automatically create profile on user creation
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Step 11: Create indexes for better performance
create index if not exists profiles_id_idx on public.profiles (id);