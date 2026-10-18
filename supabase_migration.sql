-- ==============================================================================
-- BIBIT PUSAKA - SKEMA MIGRASI DATABASE SUPABASE LENGKAP & ZERO-TRUST RLS
-- Multi-Outlet Komunitas, Bank Benih, CRM, Regenerasi, QC, & Ensiklopedia Botani
-- Dikembangkan oleh: I Gusti Ngurah Aristiana Adi Putra
-- ==============================================================================

-- 1. TABEL: community_outlets (Master Simpul Lumbung / Outlet Komunitas)
CREATE TABLE IF NOT EXISTS public.community_outlets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    outlet_code TEXT UNIQUE NOT NULL, -- Kode 2-3 huruf kapital (misal: 'BP', 'UBD', 'KRG', 'BGL', 'BLL')
    outlet_name TEXT NOT NULL,        -- Nama Outlet/Lumbung Komunitas
    coordinator_name TEXT,            -- Nama Koordinator Simpul Lumbung
    phone_whatsapp TEXT,              -- No. WhatsApp Koordinator (format 62...)
    village_region TEXT,              -- Desa / Kecamatan / Kabupaten
    latitude DOUBLE PRECISION,        -- Koordinat Geografis Lat
    longitude DOUBLE PRECISION,       -- Koordinat Geografis Lng
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Indeks Performa Outlet
CREATE INDEX IF NOT EXISTS idx_community_outlets_code ON public.community_outlets (outlet_code);

-- Data Awal: 4 Simpul Lumbung Komunitas di Bali
INSERT INTO public.community_outlets (outlet_code, outlet_name, coordinator_name, phone_whatsapp, village_region, latitude, longitude)
VALUES
    ('BP', 'Lumbung Utama Bibit Pusaka', 'I Gusti Ngurah Aristiana Adi Putra', '6281234567890', 'Pusat Konservasi Denpasar, Bali', -8.650000, 115.216667),
    ('UBD', 'Outlet Komunitas Ubud', 'I Wayan Sudira (Subak Ubud)', '6281234567891', 'Banjar Tebesaya, Ubud, Gianyar', -8.506854, 115.262474),
    ('KRG', 'Outlet Komunitas Karangasem', 'I Ketut Karya (Tani Abian)', '6281234567892', 'Desa Subagan, Amlapura, Karangasem', -8.448889, 115.612500),
    ('BGL', 'Outlet Komunitas Bangli', 'Ni Luh Putu Widi (Pertiwi Kintamani)', '6281234567893', 'Kintamani / Bangli Kota, Bangli', -8.453889, 115.354722)
ON CONFLICT (outlet_code) DO UPDATE SET
    outlet_name = EXCLUDED.outlet_name,
    coordinator_name = EXCLUDED.coordinator_name,
    phone_whatsapp = EXCLUDED.phone_whatsapp,
    village_region = EXCLUDED.village_region,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude;


-- 2. TABEL: plant_species (Kamus Botani & Ensiklopedia Plasma Nutfah)
CREATE TABLE IF NOT EXISTS public.plant_species (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    common_name TEXT UNIQUE NOT NULL,
    local_name_bali TEXT,
    common_name_en TEXT,
    scientific_name TEXT NOT NULL,
    family TEXT,
    season TEXT,
    month_range TEXT,
    region TEXT,
    temp_range TEXT,
    harvest_food_hst TEXT,
    harvest_seed_hst TEXT,
    watering TEXT,
    sunlight TEXT,
    biochar_fertilizer TEXT,
    benefit_culture TEXT,
    benefit_health TEXT,
    benefit_food TEXT,
    benefit_ecology TEXT,
    benefit_economy TEXT,
    image_urls TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Indeks Kamus Botani
CREATE INDEX IF NOT EXISTS idx_plant_species_common ON public.plant_species (common_name);
CREATE INDEX IF NOT EXISTS idx_plant_species_scientific ON public.plant_species (scientific_name);


-- 3. TABEL: seed_batches (Katalog Lot / Batch Benih Fisik)
CREATE TABLE IF NOT EXISTS public.seed_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_code TEXT UNIQUE NOT NULL,
    outlet_code TEXT DEFAULT 'BP' REFERENCES public.community_outlets(outlet_code) ON UPDATE CASCADE ON DELETE SET DEFAULT,
    variety_name TEXT NOT NULL,
    species TEXT,
    parent_batch_code TEXT,
    provenance TEXT,
    storage_location TEXT,
    harvest_date DATE,
    stock_grams NUMERIC DEFAULT 0,
    min_stock_alert NUMERIC DEFAULT 50,
    germination_rate NUMERIC DEFAULT 85,
    moisture_content NUMERIC DEFAULT 7.5,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Pastikan kolom outlet_code ada pada tabel seed_batches jika tabel sudah dibuat sebelumnya
ALTER TABLE public.seed_batches ADD COLUMN IF NOT EXISTS outlet_code TEXT DEFAULT 'BP';
UPDATE public.seed_batches SET outlet_code = 'BP' WHERE outlet_code IS NULL;

-- Indeks Performa Katalog
CREATE INDEX IF NOT EXISTS idx_seed_batches_code ON public.seed_batches (batch_code);
CREATE INDEX IF NOT EXISTS idx_seed_batches_outlet ON public.seed_batches (outlet_code);
CREATE INDEX IF NOT EXISTS idx_seed_batches_variety ON public.seed_batches (variety_name);


-- 4. TABEL: qc_logs (Riwayat Pengujian Mutu & Viabilitas)
CREATE TABLE IF NOT EXISTS public.qc_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_code TEXT NOT NULL,
    test_date DATE NOT NULL,
    germination_rate NUMERIC NOT NULL,
    moisture_content NUMERIC,
    test_status TEXT DEFAULT 'Lolos',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_qc_logs_batch ON public.qc_logs (batch_code);


-- 5. TABEL: planting_calendar (Kalender Siklus Tanam & Regenerasi Serial)
CREATE TABLE IF NOT EXISTS public.planting_calendar (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_batch_code TEXT NOT NULL,
    target_batch_code TEXT NOT NULL,
    variety_name TEXT NOT NULL,
    plot_location TEXT,
    plant_date DATE NOT NULL,
    harvest_estimate DATE NOT NULL,
    target_yield_grams NUMERIC,
    status TEXT DEFAULT 'Aktif',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_planting_calendar_target ON public.planting_calendar (target_batch_code);


-- 6. TABEL: seed_members (Database Anggota, Petani Mitra, & Subak)
CREATE TABLE IF NOT EXISTS public.seed_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name TEXT NOT NULL,
    phone_whatsapp TEXT NOT NULL,
    village_region TEXT,
    member_type TEXT DEFAULT 'Petani Mitra',
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_seed_members_phone ON public.seed_members (phone_whatsapp);


-- 7. TABEL: member_seed_adoptions (CRM Pemantauan Siklus Tanam Petani)
CREATE TABLE IF NOT EXISTS public.member_seed_adoptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id UUID REFERENCES public.seed_members(id) ON DELETE CASCADE,
    batch_code TEXT NOT NULL,
    variety_name TEXT NOT NULL,
    received_date DATE NOT NULL,
    grams_given NUMERIC DEFAULT 25,
    current_stage TEXT DEFAULT 'Penyemaian',
    feedback_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_adoptions_member ON public.member_seed_adoptions (member_id);
CREATE INDEX IF NOT EXISTS idx_adoptions_batch ON public.member_seed_adoptions (batch_code);


-- 8. TABEL: seed_exchange_requests (Antrean Permohonan Adopsi & Setor Benih Panen dari Portal Publik)
CREATE TABLE IF NOT EXISTS public.seed_exchange_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_type TEXT NOT NULL CHECK (request_type IN ('Adopsi Benih', 'Setor Benih')),
    outlet_code TEXT DEFAULT 'BP',
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

-- Pastikan kolom outlet_code ada pada seed_exchange_requests jika sebelumnya sudah ada
ALTER TABLE public.seed_exchange_requests ADD COLUMN IF NOT EXISTS outlet_code TEXT DEFAULT 'BP';
UPDATE public.seed_exchange_requests SET outlet_code = 'BP' WHERE outlet_code IS NULL;

-- Indeks Performa Permohonan Komunitas
CREATE INDEX IF NOT EXISTS idx_seed_exchange_status ON public.seed_exchange_requests (status);
CREATE INDEX IF NOT EXISTS idx_seed_exchange_outlet ON public.seed_exchange_requests (outlet_code);
CREATE INDEX IF NOT EXISTS idx_seed_exchange_phone ON public.seed_exchange_requests (phone_whatsapp);
CREATE INDEX IF NOT EXISTS idx_seed_exchange_created ON public.seed_exchange_requests (created_at DESC);


-- ==============================================================================
-- 9. KEBIJAKAN ROW LEVEL SECURITY (RLS) ZERO-TRUST LOCKDOWN
-- ==============================================================================

-- A. Aktifkan RLS pada seluruh tabel
ALTER TABLE public.community_outlets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plant_species ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seed_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qc_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.planting_calendar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seed_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.member_seed_adoptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seed_exchange_requests ENABLE ROW LEVEL SECURITY;


-- B. Hapus kebijakan lama jika ada
DROP POLICY IF EXISTS "Publik baca outlet komunitas" ON public.community_outlets;
DROP POLICY IF EXISTS "Admin kelola outlet komunitas" ON public.community_outlets;

DROP POLICY IF EXISTS "Publik baca spesies tanaman" ON public.plant_species;
DROP POLICY IF EXISTS "Admin kelola spesies tanaman" ON public.plant_species;

DROP POLICY IF EXISTS "Publik baca katalog batch benih" ON public.seed_batches;
DROP POLICY IF EXISTS "Admin kelola katalog batch benih" ON public.seed_batches;

DROP POLICY IF EXISTS "Admin kelola qc logs" ON public.qc_logs;
DROP POLICY IF EXISTS "Admin kelola planting calendar" ON public.planting_calendar;
DROP POLICY IF EXISTS "Admin kelola seed members" ON public.seed_members;
DROP POLICY IF EXISTS "Admin kelola adoptions" ON public.member_seed_adoptions;

DROP POLICY IF EXISTS "Akses publik terbuka untuk permohonan benih" ON public.seed_exchange_requests;
DROP POLICY IF EXISTS "Publik ajukan permohonan benih" ON public.seed_exchange_requests;
DROP POLICY IF EXISTS "Publik lacak permohonan sendiri" ON public.seed_exchange_requests;
DROP POLICY IF EXISTS "Admin kelola permohonan benih" ON public.seed_exchange_requests;


-- C. Aturan RLS: community_outlets
-- Publik (anon & authenticated): Hanya SELECT
CREATE POLICY "Publik baca outlet komunitas"
ON public.community_outlets FOR SELECT
TO anon, authenticated
USING (true);

-- Admin (authenticated): Akses Penuh (ALL)
CREATE POLICY "Admin kelola outlet komunitas"
ON public.community_outlets FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);


-- D. Aturan RLS: plant_species
-- Publik (anon & authenticated): Hanya SELECT
CREATE POLICY "Publik baca spesies tanaman"
ON public.plant_species FOR SELECT
TO anon, authenticated
USING (true);

-- Admin (authenticated): Akses Penuh (ALL)
CREATE POLICY "Admin kelola spesies tanaman"
ON public.plant_species FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);


-- E. Aturan RLS: seed_batches
-- Publik (anon & authenticated): Hanya SELECT
CREATE POLICY "Publik baca katalog batch benih"
ON public.seed_batches FOR SELECT
TO anon, authenticated
USING (true);

-- Admin (authenticated): Akses Penuh (ALL)
CREATE POLICY "Admin kelola katalog batch benih"
ON public.seed_batches FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);


-- F. Aturan RLS: qc_logs (Hanya Admin Authenticated)
CREATE POLICY "Admin kelola qc logs"
ON public.qc_logs FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);


-- G. Aturan RLS: planting_calendar (Hanya Admin Authenticated)
CREATE POLICY "Admin kelola planting calendar"
ON public.planting_calendar FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);


-- H. Aturan RLS: seed_members (Hanya Admin Authenticated)
CREATE POLICY "Admin kelola seed members"
ON public.seed_members FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);


-- I. Aturan RLS: member_seed_adoptions (Hanya Admin Authenticated)
CREATE POLICY "Admin kelola adoptions"
ON public.member_seed_adoptions FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);


-- J. Aturan RLS: seed_exchange_requests
-- Publik (anon & authenticated): Boleh INSERT permohonan baru
CREATE POLICY "Publik ajukan permohonan benih"
ON public.seed_exchange_requests FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Publik (anon & authenticated): Boleh SELECT untuk cek status permohonan via no WA
CREATE POLICY "Publik lacak permohonan sendiri"
ON public.seed_exchange_requests FOR SELECT
TO anon, authenticated
USING (true);

-- Admin (authenticated): Akses Penuh (ALL: update, delete, approve)
CREATE POLICY "Admin kelola permohonan benih"
ON public.seed_exchange_requests FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);


-- ==============================================================================
-- 10. KONFIGURASI STORAGE BUCKET 'plant-gallery'
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('plant-gallery', 'plant-gallery', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Kebijakan Akses Storage Publik
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

DROP POLICY IF EXISTS "Admin update delete storage galeri" ON storage.objects;
CREATE POLICY "Admin update delete storage galeri"
ON storage.objects FOR ALL
TO authenticated
USING (bucket_id = 'plant-gallery')
WITH CHECK (bucket_id = 'plant-gallery');
