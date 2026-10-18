-- ==============================================================================
-- BIBIT PUSAKA - SKEMA MIGRASI SUPABASE DATABASE
-- Fitur: Portal Publik Adopsi & Barter Benih (Seed Exchange Requests)
-- Dikembangkan oleh: I Gusti Ngurah Aristiana Adi Putra
-- ==============================================================================

-- 1. Buat Tabel seed_exchange_requests
CREATE TABLE IF NOT EXISTS public.seed_exchange_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_type TEXT NOT NULL CHECK (request_type IN ('Adopsi Benih', 'Setor Benih')),
    applicant_name TEXT NOT NULL,
    phone_whatsapp TEXT NOT NULL,
    village_region TEXT NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    variety_name TEXT NOT NULL,
    batch_code TEXT,
    grams_amount NUMERIC DEFAULT 25,
    harvest_date DATE,
    photo_url TEXT,
    notes TEXT,
    status TEXT DEFAULT 'Menunggu Verifikasi' CHECK (status IN ('Menunggu Verifikasi', 'Disetujui', 'Ditolak')),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Aktifkan Row Level Security (RLS)
ALTER TABLE public.seed_exchange_requests ENABLE ROW LEVEL SECURITY;

-- 3. Kebijakan RLS: Akses Penuh untuk Anon/Publik & Terautentikasi
DROP POLICY IF EXISTS "Akses publik terbuka untuk permohonan benih" ON public.seed_exchange_requests;
CREATE POLICY "Akses publik terbuka untuk permohonan benih"
ON public.seed_exchange_requests
FOR ALL
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- 4. Indeks Kinerja Kueri
CREATE INDEX IF NOT EXISTS idx_seed_exchange_status ON public.seed_exchange_requests (status);
CREATE INDEX IF NOT EXISTS idx_seed_exchange_created_at ON public.seed_exchange_requests (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_seed_exchange_phone ON public.seed_exchange_requests (phone_whatsapp);

-- 5. Konfigurasi Bucket Supabase Storage 'plant-gallery' (Opsional jika belum publik)
-- Memastikan file foto bukti panen yang diupload dapat diakses publik
INSERT INTO storage.buckets (id, name, public)
VALUES ('plant-gallery', 'plant-gallery', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Kebijakan Akses Storage 'plant-gallery' untuk Publik
DROP POLICY IF EXISTS "Akses upload publik galeri dan bukti setor" ON storage.objects;
CREATE POLICY "Akses upload publik galeri dan bukti setor"
ON storage.objects FOR INSERT
TO anon, authenticated
WITH CHECK (bucket_id = 'plant-gallery');

DROP POLICY IF EXISTS "Akses baca publik galeri dan bukti setor" ON storage.objects;
CREATE POLICY "Akses baca publik galeri dan bukti setor"
ON storage.objects FOR SELECT
TO anon, authenticated
USING (bucket_id = 'plant-gallery');
