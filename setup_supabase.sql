-- ==========================================
-- SETUP DATABASE KASHTIFY (FROM SCRATCH)
-- PERINGATAN: SCRIPT INI AKAN MENGHAPUS SEMUA DATA LAMA
-- Copy & Paste script ini ke SQL Editor di Supabase
-- ==========================================

-- 1. HAPUS SEMUA TABEL, VIEWS, DAN TIPE LAMA (CASCADE)
DROP VIEW IF EXISTS public.siswa_payment_summary CASCADE;
DROP VIEW IF EXISTS public.iuran_summary CASCADE;
DROP VIEW IF EXISTS public.kas_summary CASCADE;

DROP TABLE IF EXISTS public.iuran_payments CASCADE;
DROP TABLE IF EXISTS public.iuran CASCADE;
DROP TABLE IF EXISTS public.transactions CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

DROP TYPE IF EXISTS public.user_role CASCADE;
DROP TYPE IF EXISTS public.transaction_type CASCADE;
DROP TYPE IF EXISTS public.payment_status CASCADE;

DROP FUNCTION IF EXISTS public.handle_new_user CASCADE;
DROP FUNCTION IF EXISTS public.generate_iuran_payments CASCADE;
DROP FUNCTION IF EXISTS public.generate_student_iuran_payments CASCADE;

-- 2. BUAT TIPE ENUM BARU
CREATE TYPE public.user_role AS ENUM ('siswa', 'bendahara', 'admin');
CREATE TYPE public.transaction_type AS ENUM ('pemasukan', 'pengeluaran');
CREATE TYPE public.payment_status AS ENUM ('lunas', 'belum_lunas', 'terlambat');

-- 3. BUAT TABEL DARI AWAL

-- Tabel Profiles
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    nis TEXT,
    avatar_url TEXT,
    role public.user_role DEFAULT 'siswa'::public.user_role NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabel Transactions
CREATE TABLE public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    type public.transaction_type NOT NULL,
    amount BIGINT NOT NULL,
    description TEXT,
    date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabel Iuran
CREATE TABLE public.iuran (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    amount BIGINT NOT NULL,
    due_date DATE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabel Iuran Payments
CREATE TABLE public.iuran_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    iuran_id UUID REFERENCES public.iuran(id) ON DELETE CASCADE NOT NULL,
    siswa_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    status public.payment_status DEFAULT 'belum_lunas'::public.payment_status NOT NULL,
    paid_at TIMESTAMPTZ,
    confirmed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    notes TEXT,
    payment_proof_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(iuran_id, siswa_id)
);

-- 4. KONFIGURASI KEAMANAN (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.iuran ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.iuran_payments ENABLE ROW LEVEL SECURITY;

-- Policies untuk development
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "All users can view transactions" ON public.transactions FOR SELECT USING (true);
CREATE POLICY "Users can insert transactions" ON public.transactions FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "All users can view iuran" ON public.iuran FOR SELECT USING (true);
CREATE POLICY "Users can insert iuran" ON public.iuran FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "All users can view iuran payments" ON public.iuran_payments FOR SELECT USING (true);
CREATE POLICY "Users can insert iuran payments" ON public.iuran_payments FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update iuran payments" ON public.iuran_payments FOR UPDATE USING (true);

INSERT INTO storage.buckets (id, name, public)
VALUES ('payment-proofs', 'payment-proofs', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public can view payment proofs"
ON storage.objects FOR SELECT
USING (bucket_id = 'payment-proofs');

CREATE POLICY "Authenticated users can upload payment proofs"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'payment-proofs' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update payment proofs"
ON storage.objects FOR UPDATE
USING (bucket_id = 'payment-proofs' AND auth.role() = 'authenticated');

-- 5. FUNGSI & TRIGGER UNTUK PROFIL OTOMATIS SAAT DAFTAR
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, nis, role)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', 'Siswa Baru'),
    new.raw_user_meta_data->>'nis',
    COALESCE((new.raw_user_meta_data->>'role')::public.user_role, 'siswa'::public.user_role)
  );
  RETURN new;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 6. FUNGSI & TRIGGER UNTUK OTOMATIS BUAT TAGIHAN SISWA
CREATE OR REPLACE FUNCTION public.generate_iuran_payments()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.iuran_payments (iuran_id, siswa_id, status)
  SELECT new.id, p.id, 'belum_lunas'::public.payment_status
  FROM public.profiles p
  WHERE p.role = 'siswa'::public.user_role;
  RETURN new;
END;
$$;

CREATE TRIGGER on_iuran_created
  AFTER INSERT ON public.iuran
  FOR EACH ROW EXECUTE PROCEDURE public.generate_iuran_payments();

CREATE OR REPLACE FUNCTION public.generate_student_iuran_payments()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF new.role = 'siswa'::public.user_role THEN
    INSERT INTO public.iuran_payments (iuran_id, siswa_id, status)
    SELECT i.id, new.id, 'belum_lunas'::public.payment_status
    FROM public.iuran i
    ON CONFLICT (iuran_id, siswa_id) DO NOTHING;
  END IF;
  RETURN new;
END;
$$;

CREATE TRIGGER on_student_profile_created
  AFTER INSERT ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.generate_student_iuran_payments();

-- 7. BUAT VIEWS
CREATE OR REPLACE VIEW public.kas_summary AS
SELECT
  COALESCE(SUM(CASE WHEN type = 'pemasukan' THEN amount ELSE 0 END), 0) AS total_pemasukan,
  COALESCE(SUM(CASE WHEN type = 'pengeluaran' THEN amount ELSE 0 END), 0) AS total_pengeluaran,
  COALESCE(SUM(CASE WHEN type = 'pemasukan' THEN amount ELSE -amount END), 0) AS saldo
FROM public.transactions;

CREATE OR REPLACE VIEW public.iuran_summary AS
SELECT
  i.id,
  i.title,
  i.amount,
  i.due_date,
  (SELECT COUNT(*) FROM public.iuran_payments WHERE iuran_id = i.id) AS total_siswa,
  (SELECT COUNT(*) FROM public.iuran_payments WHERE iuran_id = i.id AND status = 'lunas') AS sudah_bayar,
  (SELECT COUNT(*) FROM public.iuran_payments WHERE iuran_id = i.id AND status != 'lunas') AS belum_bayar,
  (SELECT COUNT(*) * i.amount FROM public.iuran_payments WHERE iuran_id = i.id AND status = 'lunas') AS total_terkumpul
FROM public.iuran i;

CREATE OR REPLACE VIEW public.siswa_payment_summary AS
SELECT
  p.id AS siswa_id,
  p.full_name,
  p.nis,
  (SELECT COUNT(*) FROM public.iuran_payments WHERE siswa_id = p.id) AS total_tagihan,
  (SELECT COUNT(*) FROM public.iuran_payments WHERE siswa_id = p.id AND status = 'lunas') AS sudah_lunas,
  (SELECT COUNT(*) FROM public.iuran_payments WHERE siswa_id = p.id AND status != 'lunas') AS belum_lunas,
  COALESCE((
    SELECT SUM(i.amount) 
    FROM public.iuran_payments ip
    JOIN public.iuran i ON i.id = ip.iuran_id
    WHERE ip.siswa_id = p.id AND ip.status != 'lunas'
  ), 0) AS total_tunggakan
FROM public.profiles p
WHERE p.role = 'siswa'::public.user_role;
