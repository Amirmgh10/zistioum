-- اجرا در Supabase SQL Editor بعد از اجرای اسکریپت اولیه
-- این trigger پروفایل دانش‌آموز را پس از ساخت حساب Auth ایجاد می‌کند.
-- نقش پیش‌فرض همیشه student است؛ ثبت‌نام عمومی نمی‌تواند معلم بسازد.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, username, role)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'username', ''), split_part(new.email, '@', 1)),
    'student'
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- برای اینکه نام کاربری تکراری نباشد، unique constraint جدول profiles حفظ می‌شود.
