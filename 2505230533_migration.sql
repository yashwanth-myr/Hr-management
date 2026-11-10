-- This migration creates the necessary tables and functions for admin authentication
-- Schema: public
-- Tables: users, user_roles
-- Functions: handle_new_user

-- Create users table with role column
create table if not exists public.users (
  id uuid references auth.users on delete cascade not null primary key,
  email text not null unique,
  role text not null check (role in ('admin', 'user')),
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

-- Create a secure function to handle new user signups
create or replace function public.handle_new_user() 
returns trigger as $$
begin
  -- By default assign the 'user' role to new users
  -- Admins will need to be manually upgraded by another admin
  insert into public.users (id, email, role)
  values (new.id, new.email, 'user');
  return new;
end;
$$ language plpgsql security definer;

-- Trigger the function every time a user is created
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Create RLS policies for users table
alter table public.users enable row level security;

-- Allow users to see their own data
create policy "Users can view their own data"
  on public.users for select
  using (auth.uid() = id);

-- Allow admins to see all user data
create policy "Admins can view all user data"
  on public.users for select
  using (
    exists (
      select 1 from public.users 
      where id = auth.uid() and role = 'admin'
    )
  );

-- Allow admins to update user roles
create policy "Admins can update user roles"
  on public.users for update
  using (
    exists (
      select 1 from public.users 
      where id = auth.uid() and role = 'admin'
    )
  );

-- Insert an initial admin user (change the email and UUID as needed)
-- This is for demonstration purposes; in production, use a secure method to add admin users
insert into auth.users (id, email)
values ('00000000-0000-0000-0000-000000000000', 'admin@example.com')
on conflict do nothing;

-- Assign admin role to the initial user
insert into public.users (id, email, role)
values ('00000000-0000-0000-0000-000000000000', 'admin@example.com', 'admin')
on conflict (id) do update set role = 'admin';

-- Enable Supabase authentication for email/password
update auth.config
set enable_sign_up = true;

-- Add comments to tables and columns for better documentation
comment on table public.users is 'Stores user profile data with role-based access control';
comment on column public.users.id is 'References the auth.users table';
comment on column public.users.role is 'User role: admin or user';