ALTER TABLE public.iuran_payments
ADD COLUMN IF NOT EXISTS payment_proof_url TEXT;

INSERT INTO storage.buckets (id, name, public)
VALUES ('payment-proofs', 'payment-proofs', true)
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Public can view payment proofs'
  ) THEN
    CREATE POLICY "Public can view payment proofs"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'payment-proofs');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Authenticated users can upload payment proofs'
  ) THEN
    CREATE POLICY "Authenticated users can upload payment proofs"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'payment-proofs' AND auth.role() = 'authenticated');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Authenticated users can update payment proofs'
  ) THEN
    CREATE POLICY "Authenticated users can update payment proofs"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'payment-proofs' AND auth.role() = 'authenticated');
  END IF;
END $$;
