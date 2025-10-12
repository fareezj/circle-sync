-- Create an RPC function to get user details safely
-- This function can access auth.users and return the data we need
create or replace function get_users_by_ids(user_ids uuid[])
returns table(id uuid, email text, name text) 
language plpgsql security definer
as $$
begin
  return query
  select 
    u.id,
    u.email,
    coalesce(u.raw_user_meta_data->>'name', u.email) as name
  from auth.users u
  where u.id = any(user_ids);
end;
$$;

-- Grant execute permission to authenticated users
grant execute on function get_users_by_ids(uuid[]) to authenticated;