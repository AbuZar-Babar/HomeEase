-- ============================================================================
-- Migration: 20261001_initial_schema_and_seed.sql
-- Description: Core PostgreSQL DDL, Automated Triggers, Row Level Security (RLS),
--              and Abbottabad Seed Dataset for HomeEase (60% FYP Milestone)
-- ============================================================================

-- 0. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. CORE RELATIONAL TABLES (DDL)
-- ============================================================================

-- Table 1: profiles (Extends auth.users for platform roles & identity)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    phone TEXT,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('household', 'worker', 'admin')),
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Table 2: worker_profiles (Domain details for service professionals)
CREATE TABLE IF NOT EXISTS public.worker_profiles (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    skills TEXT[] DEFAULT '{}' NOT NULL,
    experience_years INTEGER DEFAULT 0 NOT NULL CHECK (experience_years >= 0),
    hourly_rate NUMERIC(10,2) DEFAULT 0.00 NOT NULL CHECK (hourly_rate >= 0),
    locality TEXT NOT NULL,
    bio TEXT,
    rating NUMERIC(3,2) DEFAULT 0.00 NOT NULL CHECK (rating >= 0.0 AND rating <= 5.0),
    reviews_count INTEGER DEFAULT 0 NOT NULL CHECK (reviews_count >= 0),
    verified BOOLEAN DEFAULT false NOT NULL,
    availability JSONB DEFAULT '{"status": "Available today", "slots": ["Mon", "Tue", "Wed", "Thu", "Fri"]}'::jsonb NOT NULL,
    latitude DOUBLE PRECISION DEFAULT 34.1983 NOT NULL,
    longitude DOUBLE PRECISION DEFAULT 73.2425 NOT NULL,
    profile_visibility BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Table 3: jobs (Marketplace job board listings)
CREATE TABLE IF NOT EXISTS public.jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    locality TEXT NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    budget NUMERIC(10,2) NOT NULL CHECK (budget >= 0),
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Table 4: job_applications (Marketplace worker applications / bids)
CREATE TABLE IF NOT EXISTS public.job_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
    worker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    proposed_rate NUMERIC(10,2),
    notes TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    applied_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    CONSTRAINT unique_worker_job_application UNIQUE (job_id, worker_id)
);

-- Table 5: bookings (Service booking contracts with conflict management)
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    worker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    service_date DATE NOT NULL,
    start_time TIME NOT NULL,
    duration_hours NUMERIC(4,2) DEFAULT 2.0 NOT NULL CHECK (duration_hours > 0),
    total_amount NUMERIC(10,2) NOT NULL CHECK (total_amount >= 0),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'in_progress', 'completed', 'cancelled', 'disputed')),
    payment_method TEXT NOT NULL DEFAULT 'cash' CHECK (payment_method IN ('cash', 'easypaisa', 'jazzcash', 'bank_transfer')),
    payment_status TEXT NOT NULL DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'submitted', 'confirmed', 'disputed', 'refunded')),
    address TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Table 6: reviews (Multi-dimensional ratings & feedback)
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL UNIQUE REFERENCES public.bookings(id) ON DELETE CASCADE,
    employer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    worker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    punctuality_rating INTEGER CHECK (punctuality_rating >= 1 AND punctuality_rating <= 5),
    behavior_rating INTEGER CHECK (behavior_rating >= 1 AND behavior_rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ============================================================================
-- 2. INDEXES
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_jobs_employer_id ON public.jobs(employer_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON public.jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_category ON public.jobs(category);
CREATE INDEX IF NOT EXISTS idx_job_applications_job_id ON public.job_applications(job_id);
CREATE INDEX IF NOT EXISTS idx_job_applications_worker_id ON public.job_applications(worker_id);
CREATE INDEX IF NOT EXISTS idx_bookings_employer_id ON public.bookings(employer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_worker_id ON public.bookings(worker_id);
CREATE INDEX IF NOT EXISTS idx_bookings_service_date ON public.bookings(service_date);
CREATE INDEX IF NOT EXISTS idx_reviews_booking_id ON public.reviews(booking_id);
CREATE INDEX IF NOT EXISTS idx_reviews_worker_id ON public.reviews(worker_id);
CREATE INDEX IF NOT EXISTS idx_worker_profiles_locality ON public.worker_profiles(locality);

-- ============================================================================
-- 3. AUTOMATED DATABASE TRIGGERS & FUNCTIONS
-- ============================================================================

-- Trigger Function 1: Automatic User Profile Creation on auth.users Sign-Up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, phone, full_name, role)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'phone',
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'HomeEase User'),
        COALESCE(NEW.raw_user_meta_data->>'role', 'household')
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        phone = COALESCE(EXCLUDED.phone, public.profiles.phone),
        full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name),
        role = COALESCE(EXCLUDED.role, public.profiles.role),
        updated_at = now();

    -- If registered role is worker, initialize empty worker_profile
    IF (NEW.raw_user_meta_data->>'role' = 'worker') THEN
        INSERT INTO public.worker_profiles (id, locality, bio)
        VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'locality', 'Mandian'),
            COALESCE(NEW.raw_user_meta_data->>'bio', 'Domestic service professional')
        )
        ON CONFLICT (id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger Function 2: Dynamic Worker Rating Re-calculation
CREATE OR REPLACE FUNCTION public.sync_worker_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.worker_profiles
    SET 
        rating = COALESCE((
            SELECT ROUND(AVG(rating)::numeric, 2)
            FROM public.reviews
            WHERE worker_id = NEW.worker_id
        ), 0.0),
        reviews_count = (
            SELECT COUNT(*)
            FROM public.reviews
            WHERE worker_id = NEW.worker_id
        ),
        updated_at = now()
    WHERE id = NEW.worker_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_review_created_or_updated ON public.reviews;
CREATE TRIGGER on_review_created_or_updated
    AFTER INSERT OR UPDATE ON public.reviews
    FOR EACH ROW EXECUTE FUNCTION public.sync_worker_rating();

-- Trigger Function 3: updated_at Automatic Timestamp Update
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS touch_profiles_updated_at ON public.profiles;
CREATE TRIGGER touch_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS touch_worker_profiles_updated_at ON public.worker_profiles;
CREATE TRIGGER touch_worker_profiles_updated_at BEFORE UPDATE ON public.worker_profiles FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS touch_jobs_updated_at ON public.jobs;
CREATE TRIGGER touch_jobs_updated_at BEFORE UPDATE ON public.jobs FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS touch_bookings_updated_at ON public.bookings;
CREATE TRIGGER touch_bookings_updated_at BEFORE UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- ============================================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS across all 6 tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- 4.1 PROFILES POLICIES
DROP POLICY IF EXISTS "Profiles are viewable by authenticated users" ON public.profiles;
CREATE POLICY "Profiles are viewable by authenticated users"
    ON public.profiles FOR SELECT
    TO authenticated, anon
    USING (true);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile"
    ON public.profiles FOR INSERT
    TO authenticated
    WITH CHECK ((select auth.uid()) = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING ((select auth.uid()) = id)
    WITH CHECK ((select auth.uid()) = id);

-- 4.2 WORKER_PROFILES POLICIES
DROP POLICY IF EXISTS "Worker profiles viewable by all authenticated users" ON public.worker_profiles;
CREATE POLICY "Worker profiles viewable by all authenticated users"
    ON public.worker_profiles FOR SELECT
    TO authenticated, anon
    USING (profile_visibility = true OR (select auth.uid()) = id);

DROP POLICY IF EXISTS "Workers can insert own profile" ON public.worker_profiles;
CREATE POLICY "Workers can insert own profile"
    ON public.worker_profiles FOR INSERT
    TO authenticated
    WITH CHECK ((select auth.uid()) = id);

DROP POLICY IF EXISTS "Workers can update own profile" ON public.worker_profiles;
CREATE POLICY "Workers can update own profile"
    ON public.worker_profiles FOR UPDATE
    TO authenticated
    USING ((select auth.uid()) = id)
    WITH CHECK ((select auth.uid()) = id);

-- 4.3 JOBS POLICIES
DROP POLICY IF EXISTS "Jobs viewable by authenticated users" ON public.jobs;
CREATE POLICY "Jobs viewable by authenticated users"
    ON public.jobs FOR SELECT
    TO authenticated, anon
    USING (status = 'open' OR (select auth.uid()) = employer_id);

DROP POLICY IF EXISTS "Employers can insert jobs" ON public.jobs;
CREATE POLICY "Employers can insert jobs"
    ON public.jobs FOR INSERT
    TO authenticated
    WITH CHECK ((select auth.uid()) = employer_id);

DROP POLICY IF EXISTS "Employers can update own jobs" ON public.jobs;
CREATE POLICY "Employers can update own jobs"
    ON public.jobs FOR UPDATE
    TO authenticated
    USING ((select auth.uid()) = employer_id)
    WITH CHECK ((select auth.uid()) = employer_id);

DROP POLICY IF EXISTS "Employers can delete own jobs" ON public.jobs;
CREATE POLICY "Employers can delete own jobs"
    ON public.jobs FOR DELETE
    TO authenticated
    USING ((select auth.uid()) = employer_id);

-- 4.4 JOB_APPLICATIONS POLICIES
DROP POLICY IF EXISTS "Applications viewable by applicant or job owner" ON public.job_applications;
CREATE POLICY "Applications viewable by applicant or job owner"
    ON public.job_applications FOR SELECT
    TO authenticated
    USING (
        (select auth.uid()) = worker_id 
        OR EXISTS (
            SELECT 1 FROM public.jobs 
            WHERE jobs.id = job_applications.job_id 
            AND jobs.employer_id = (select auth.uid())
        )
    );

DROP POLICY IF EXISTS "Workers can submit applications" ON public.job_applications;
CREATE POLICY "Workers can submit applications"
    ON public.job_applications FOR INSERT
    TO authenticated
    WITH CHECK ((select auth.uid()) = worker_id);

DROP POLICY IF EXISTS "Applications status updateable by applicant or job owner" ON public.job_applications;
CREATE POLICY "Applications status updateable by applicant or job owner"
    ON public.job_applications FOR UPDATE
    TO authenticated
    USING (
        (select auth.uid()) = worker_id 
        OR EXISTS (
            SELECT 1 FROM public.jobs 
            WHERE jobs.id = job_applications.job_id 
            AND jobs.employer_id = (select auth.uid())
        )
    )
    WITH CHECK (
        (select auth.uid()) = worker_id 
        OR EXISTS (
            SELECT 1 FROM public.jobs 
            WHERE jobs.id = job_applications.job_id 
            AND jobs.employer_id = (select auth.uid())
        )
    );

-- 4.5 BOOKINGS POLICIES
DROP POLICY IF EXISTS "Bookings viewable by involved parties" ON public.bookings;
CREATE POLICY "Bookings viewable by involved parties"
    ON public.bookings FOR SELECT
    TO authenticated
    USING ((select auth.uid()) = employer_id OR (select auth.uid()) = worker_id);

DROP POLICY IF EXISTS "Employers can create bookings" ON public.bookings;
CREATE POLICY "Employers can create bookings"
    ON public.bookings FOR INSERT
    TO authenticated
    WITH CHECK ((select auth.uid()) = employer_id);

DROP POLICY IF EXISTS "Bookings updatable by involved parties" ON public.bookings;
CREATE POLICY "Bookings updatable by involved parties"
    ON public.bookings FOR UPDATE
    TO authenticated
    USING ((select auth.uid()) = employer_id OR (select auth.uid()) = worker_id)
    WITH CHECK ((select auth.uid()) = employer_id OR (select auth.uid()) = worker_id);

-- 4.6 REVIEWS POLICIES
DROP POLICY IF EXISTS "Reviews viewable by authenticated users" ON public.reviews;
CREATE POLICY "Reviews viewable by authenticated users"
    ON public.reviews FOR SELECT
    TO authenticated, anon
    USING (true);

DROP POLICY IF EXISTS "Employers can review completed bookings" ON public.reviews;
CREATE POLICY "Employers can review completed bookings"
    ON public.reviews FOR INSERT
    TO authenticated
    WITH CHECK (
        (select auth.uid()) = employer_id
        AND EXISTS (
            SELECT 1 FROM public.bookings
            WHERE bookings.id = reviews.booking_id
            AND bookings.employer_id = (select auth.uid())
            AND bookings.status = 'completed'
        )
    );

DROP POLICY IF EXISTS "Employers can update own review" ON public.reviews;
CREATE POLICY "Employers can update own review"
    ON public.reviews FOR UPDATE
    TO authenticated
    USING ((select auth.uid()) = employer_id)
    WITH CHECK ((select auth.uid()) = employer_id);

-- ============================================================================
-- 5. ABBOTTABAD SEED DATASET (DML)
-- ============================================================================

-- 5.0 Seed Auth Users & Identities (Password: 'password123')
INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token
) VALUES
-- Household Employers
('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'household@homeease.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Babar Khan","role":"household","phone":"+923001234567"}'::jsonb, now(), now(), '', ''),
('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'malik.farhan@gmail.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Malik Farhan","role":"household","phone":"+923019876543"}'::jsonb, now(), now(), '', ''),
('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'tariq.doc@gmail.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Dr. Tariq Mehmood","role":"household","phone":"+923335551234"}'::jsonb, now(), now(), '', ''),
('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000004', 'authenticated', 'authenticated', 'saima.khan@yahoo.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Saima Khan","role":"household","phone":"+923124445566"}'::jsonb, now(), now(), '', ''),
('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000005', 'authenticated', 'authenticated', 'javed.pma@gmail.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Brigadier (R) Javed","role":"household","phone":"+923007778899"}'::jsonb, now(), now(), '', ''),
('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000006', 'authenticated', 'authenticated', 'bilqees.h@gmail.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Mrs. Bilqees","role":"household","phone":"+923456667788"}'::jsonb, now(), now(), '', ''),
-- Workers
('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000010', 'authenticated', 'authenticated', 'worker@homeease.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Rabia Bibi","role":"worker","phone":"+923111234567"}'::jsonb, now(), now(), '', ''),
('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000011', 'authenticated', 'authenticated', 'amina.noor@homeease.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Amina Noor","role":"worker","phone":"+923214567890"}'::jsonb, now(), now(), '', ''),
('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000012', 'authenticated', 'authenticated', 'sana.gul@homeease.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Sana Gul","role":"worker","phone":"+923339876543"}'::jsonb, now(), now(), '', ''),
('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000013', 'authenticated', 'authenticated', 'hira.khan@homeease.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Hira Khan","role":"worker","phone":"+923451122334"}'::jsonb, now(), now(), '', ''),
('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000014', 'authenticated', 'authenticated', 'farzana.parveen@homeease.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Farzana Parveen","role":"worker","phone":"+923023344556"}'::jsonb, now(), now(), '', ''),
('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000015', 'authenticated', 'authenticated', 'nasreen.akhtar@homeease.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Nasreen Akhtar","role":"worker","phone":"+923135566778"}'::jsonb, now(), now(), '', ''),
('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000016', 'authenticated', 'authenticated', 'tariq.electrician@homeease.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Tariq Mehmood","role":"worker","phone":"+923004455667"}'::jsonb, now(), now(), '', ''),
('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000017', 'authenticated', 'authenticated', 'arshad.electrician@homeease.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Muhammad Arshad","role":"worker","phone":"+923225566778"}'::jsonb, now(), now(), '', ''),
('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000018', 'authenticated', 'authenticated', 'gul.plumber@homeease.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Gul Zaman","role":"worker","phone":"+923336677889"}'::jsonb, now(), now(), '', ''),
('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000019', 'authenticated', 'authenticated', 'sajid.plumber@homeease.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Sajid Abbasi","role":"worker","phone":"+923447788990"}'::jsonb, now(), now(), '', ''),
('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000020', 'authenticated', 'authenticated', 'rashid.painter@homeease.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Rashid Minhas","role":"worker","phone":"+923018899001"}'::jsonb, now(), now(), '', ''),
('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000021', 'authenticated', 'authenticated', 'asif.carpenter@homeease.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Asif Ali","role":"worker","phone":"+923129900112"}'::jsonb, now(), now(), '', '')
ON CONFLICT (id) DO NOTHING;

-- Seed Identities
INSERT INTO auth.identities (
    id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) VALUES
('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '{"sub":"00000000-0000-0000-0000-000000000001","email":"household@homeease.com"}'::jsonb, 'email', '00000000-0000-0000-0000-000000000001', now(), now(), now()),
('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', '{"sub":"00000000-0000-0000-0000-000000000002","email":"malik.farhan@gmail.com"}'::jsonb, 'email', '00000000-0000-0000-0000-000000000002', now(), now(), now()),
('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', '{"sub":"00000000-0000-0000-0000-000000000003","email":"tariq.doc@gmail.com"}'::jsonb, 'email', '00000000-0000-0000-0000-000000000003', now(), now(), now()),
('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000004', '{"sub":"00000000-0000-0000-0000-000000000004","email":"saima.khan@yahoo.com"}'::jsonb, 'email', '00000000-0000-0000-0000-000000000004', now(), now(), now()),
('00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000005', '{"sub":"00000000-0000-0000-0000-000000000005","email":"javed.pma@gmail.com"}'::jsonb, 'email', '00000000-0000-0000-0000-000000000005', now(), now(), now()),
('00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000006', '{"sub":"00000000-0000-0000-0000-000000000006","email":"bilqees.h@gmail.com"}'::jsonb, 'email', '00000000-0000-0000-0000-000000000006', now(), now(), now()),
('00000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000010', '{"sub":"00000000-0000-0000-0000-000000000010","email":"worker@homeease.com"}'::jsonb, 'email', '00000000-0000-0000-0000-000000000010', now(), now(), now()),
('00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000011', '{"sub":"00000000-0000-0000-0000-000000000011","email":"amina.noor@homeease.com"}'::jsonb, 'email', '00000000-0000-0000-0000-000000000011', now(), now(), now()),
('00000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000012', '{"sub":"00000000-0000-0000-0000-000000000012","email":"sana.gul@homeease.com"}'::jsonb, 'email', '00000000-0000-0000-0000-000000000012', now(), now(), now()),
('00000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000013', '{"sub":"00000000-0000-0000-0000-000000000013","email":"hira.khan@homeease.com"}'::jsonb, 'email', '00000000-0000-0000-0000-000000000013', now(), now(), now()),
('00000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000014', '{"sub":"00000000-0000-0000-0000-000000000014","email":"farzana.parveen@homeease.com"}'::jsonb, 'email', '00000000-0000-0000-0000-000000000014', now(), now(), now()),
('00000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000015', '{"sub":"00000000-0000-0000-0000-000000000015","email":"nasreen.akhtar@homeease.com"}'::jsonb, 'email', '00000000-0000-0000-0000-000000000015', now(), now(), now()),
('00000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000016', '{"sub":"00000000-0000-0000-0000-000000000016","email":"tariq.electrician@homeease.com"}'::jsonb, 'email', '00000000-0000-0000-0000-000000000016', now(), now(), now()),
('00000000-0000-0000-0000-000000000017', '00000000-0000-0000-0000-000000000017', '{"sub":"00000000-0000-0000-0000-000000000017","email":"arshad.electrician@homeease.com"}'::jsonb, 'email', '00000000-0000-0000-0000-000000000017', now(), now(), now()),
('00000000-0000-0000-0000-000000000018', '00000000-0000-0000-0000-000000000018', '{"sub":"00000000-0000-0000-0000-000000000018","email":"gul.plumber@homeease.com"}'::jsonb, 'email', '00000000-0000-0000-0000-000000000018', now(), now(), now()),
('00000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000019', '{"sub":"00000000-0000-0000-0000-000000000019","email":"sajid.plumber@homeease.com"}'::jsonb, 'email', '00000000-0000-0000-0000-000000000019', now(), now(), now()),
('00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000020', '{"sub":"00000000-0000-0000-0000-000000000020","email":"rashid.painter@homeease.com"}'::jsonb, 'email', '00000000-0000-0000-0000-000000000020', now(), now(), now()),
('00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000021', '{"sub":"00000000-0000-0000-0000-000000000021","email":"asif.carpenter@homeease.com"}'::jsonb, 'email', '00000000-0000-0000-0000-000000000021', now(), now(), now())
ON CONFLICT (id) DO NOTHING;

-- 5.1 PROFILES (Household Employers & Workers)
INSERT INTO public.profiles (id, email, phone, full_name, role) VALUES
('00000000-0000-0000-0000-000000000001', 'household@homeease.com', '+923001234567', 'Babar Khan', 'household'),
('00000000-0000-0000-0000-000000000002', 'malik.farhan@gmail.com', '+923019876543', 'Malik Farhan', 'household'),
('00000000-0000-0000-0000-000000000003', 'tariq.doc@gmail.com', '+923335551234', 'Dr. Tariq Mehmood', 'household'),
('00000000-0000-0000-0000-000000000004', 'saima.khan@yahoo.com', '+923124445566', 'Saima Khan', 'household'),
('00000000-0000-0000-0000-000000000005', 'javed.pma@gmail.com', '+923007778899', 'Brigadier (R) Javed', 'household'),
('00000000-0000-0000-0000-000000000006', 'bilqees.h@gmail.com', '+923456667788', 'Mrs. Bilqees', 'household'),
('00000000-0000-0000-0000-000000000010', 'worker@homeease.com', '+923111234567', 'Rabia Bibi', 'worker'),
('00000000-0000-0000-0000-000000000011', 'amina.noor@homeease.com', '+923214567890', 'Amina Noor', 'worker'),
('00000000-0000-0000-0000-000000000012', 'sana.gul@homeease.com', '+923339876543', 'Sana Gul', 'worker'),
('00000000-0000-0000-0000-000000000013', 'hira.khan@homeease.com', '+923451122334', 'Hira Khan', 'worker'),
('00000000-0000-0000-0000-000000000014', 'farzana.parveen@homeease.com', '+923023344556', 'Farzana Parveen', 'worker'),
('00000000-0000-0000-0000-000000000015', 'nasreen.akhtar@homeease.com', '+923135566778', 'Nasreen Akhtar', 'worker'),
('00000000-0000-0000-0000-000000000016', 'tariq.electrician@homeease.com', '+923004455667', 'Tariq Mehmood', 'worker'),
('00000000-0000-0000-0000-000000000017', 'arshad.electrician@homeease.com', '+923225566778', 'Muhammad Arshad', 'worker'),
('00000000-0000-0000-0000-000000000018', 'gul.plumber@homeease.com', '+923336677889', 'Gul Zaman', 'worker'),
('00000000-0000-0000-0000-000000000019', 'sajid.plumber@homeease.com', '+923447788990', 'Sajid Abbasi', 'worker'),
('00000000-0000-0000-0000-000000000020', 'rashid.painter@homeease.com', '+923018899001', 'Rashid Minhas', 'worker'),
('00000000-0000-0000-0000-000000000021', 'asif.carpenter@homeease.com', '+923129900112', 'Asif Ali', 'worker')
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    full_name = EXCLUDED.full_name,
    role = EXCLUDED.role;

-- 5.2 WORKER_PROFILES
INSERT INTO public.worker_profiles (id, skills, experience_years, hourly_rate, locality, bio, rating, reviews_count, verified, availability, latitude, longitude) VALUES
-- Cook: Rabia Bibi
('00000000-0000-0000-0000-000000000010', ARRAY['Desi Cooking', 'Meal Prep', 'Baking', 'Traditional Biryani', 'Family Meals', 'Cook'], 4, 3000.00, 'Jhangi Syedan', 'Professional home cook with 4 years of experience preparing traditional Pakistani dishes.', 4.80, 24, true, '{"status": "Available today", "slots": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]}'::jsonb, 34.1750, 73.2280),

-- Nanny: Amina Noor
('00000000-0000-0000-0000-000000000011', ARRAY['Toddler Care', 'Infant Feeding', 'First Aid', 'Homework Help', 'Nanny'], 3, 2500.00, 'Mandian', 'Certified childcare assistant specialized in early child development and infant care.', 4.70, 18, true, '{"status": "Available today", "slots": ["Mon", "Tue", "Wed", "Thu", "Fri"]}'::jsonb, 34.1983, 73.2425),

-- Cleaner: Sana Gul
('00000000-0000-0000-0000-000000000012', ARRAY['Deep Cleaning', 'Sanitation', 'Floor Polishing', 'Window Washing', 'Kitchen Disinfection', 'Cleaner'], 5, 2200.00, 'Supply Bazaar', 'Detail-oriented cleaner specializing in deep sanitization and guest-ready home preparation.', 4.90, 36, true, '{"status": "Available today", "slots": ["Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]}'::jsonb, 34.1580, 73.2190),

-- Maid: Hira Khan
('00000000-0000-0000-0000-000000000013', ARRAY['Dusting', 'Laundry & Ironing', 'Dishwashing', 'General Housekeeping', 'Maid'], 2, 2000.00, 'Nawan Shehr', 'Reliable general maid offering dusting, washing, ironing, and flexible chore support.', 4.60, 14, true, '{"status": "Available today", "slots": ["Mon", "Tue", "Wed", "Thu", "Fri"]}'::jsonb, 34.1620, 73.2650),

-- Caregiver: Farzana Parveen
('00000000-0000-0000-0000-000000000014', ARRAY['Elderly Care', 'Medication Management', 'Mobility Support', 'Vital Signs Check', 'Caregiver'], 6, 3500.00, 'Mandian', 'Trained elderly companion with basic nursing background, BP monitoring, and mobility care.', 4.90, 29, true, '{"status": "Available today", "slots": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]}'::jsonb, 34.1960, 73.2410),

-- Cook: Nasreen Akhtar
('00000000-0000-0000-0000-000000000015', ARRAY['Desi Cooking', 'Chapati & Naan', 'Dietary Restrictions', 'Continental Snacks', 'Cook'], 3, 2800.00, 'PMA Kakul Road', 'Passionate cook specializing in northern Pakistani cuisines and hygiene-certified meal prep.', 4.50, 11, true, '{"status": "Available today", "slots": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]}'::jsonb, 34.1890, 73.2590),

-- Electrician: Tariq Mehmood
('00000000-0000-0000-0000-000000000016', ARRAY['Wiring', 'Circuit Breakers', 'UPS Installation', 'Fan Repair', 'Lighting', 'Electrician'], 6, 1800.00, 'Mandian', 'Licensed domestic electrician for distribution boards, short-circuits, and home wiring.', 4.80, 28, true, '{"status": "Available today", "slots": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]}'::jsonb, 34.1983, 73.2425),

-- Electrician: Muhammad Arshad
('00000000-0000-0000-0000-000000000017', ARRAY['Solar Inverters', 'Appliance Repair', 'Emergency Fixes', '3-Phase Wiring', 'Electrician'], 8, 2000.00, 'Supply Bazaar', 'Master electrician specialized in solar inverter installations, heavy load rewiring, and breakers.', 4.90, 42, true, '{"status": "Available today", "slots": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]}'::jsonb, 34.1580, 73.2190),

-- Plumber: Gul Zaman
('00000000-0000-0000-0000-000000000018', ARRAY['Pipe Leakage', 'Water Pump Repair', 'Sanitary Fittings', 'Geyser Maintenance', 'Plumber'], 5, 1500.00, 'Jhangi Syedan', 'Experienced plumber for urgent pipe leakages, motor pump repairs, and sanitary ware installation.', 4.70, 19, true, '{"status": "Available today", "slots": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]}'::jsonb, 34.1750, 73.2280),

-- Plumber: Sajid Abbasi
('00000000-0000-0000-0000-000000000019', ARRAY['PPRC Piping', 'Drainage Unclogging', 'Bathroom Renovation', 'Overhead Tanks', 'Plumber'], 7, 1700.00, 'Nawan Shehr', 'Expert plumber specializing in underground water line tracing, drainage cleaning, and tank fittings.', 4.80, 31, true, '{"status": "Available today", "slots": ["Mon", "Tue", "Wed", "Thu", "Fri"]}'::jsonb, 34.1620, 73.2650),

-- Painter: Rashid Minhas
('00000000-0000-0000-0000-000000000020', ARRAY['Wall Emulsion', 'Exterior Weather-Sheet', 'Wood Polishing', 'Ceiling Distemper', 'Painter'], 4, 2200.00, 'Supply Bazaar', 'Professional house painter providing smooth finish walls, exterior weather-protection, and wood varnish.', 4.60, 16, true, '{"status": "Available today", "slots": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]}'::jsonb, 34.1580, 73.2190),

-- Carpenter: Asif Ali
('00000000-0000-0000-0000-000000000021', ARRAY['Door Lock Fitting', 'Cabinet Making', 'Furniture Repair', 'Wood Polishing', 'Carpenter'], 9, 2200.00, 'Nawan Shehr', 'Skilled carpenter with 9 years of craftsmanship in door alignments, custom kitchen racks, and bed repair.', 4.80, 35, true, '{"status": "Available today", "slots": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]}'::jsonb, 34.1620, 73.2650)
ON CONFLICT (id) DO UPDATE SET 
    skills = EXCLUDED.skills,
    experience_years = EXCLUDED.experience_years,
    hourly_rate = EXCLUDED.hourly_rate,
    locality = EXCLUDED.locality,
    bio = EXCLUDED.bio,
    rating = EXCLUDED.rating,
    reviews_count = EXCLUDED.reviews_count,
    verified = EXCLUDED.verified,
    availability = EXCLUDED.availability,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude;

-- 5.3 JOBS (Marketplace Job Posts)
INSERT INTO public.jobs (id, employer_id, title, category, description, locality, latitude, longitude, date, budget, status) VALUES
('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000002', 'Family Dinner Cook Needed', 'Cook', 'Need an experienced Desi cook for a family dinner of 8 guests. Specializing in Biryani and Karahi.', 'Mandian', 34.1983, 73.2425, CURRENT_DATE + 1, 3500.00, 'open'),
('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000003', 'Deep House Cleaning Post-Renovation', 'Cleaner', 'Require thorough deep cleaning of a 2-storey house after paintwork. Windows, floor polishing, and kitchen.', 'Supply Bazaar', 34.1580, 73.2190, CURRENT_DATE + 2, 4500.00, 'open'),
('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000001', 'Main DB & UPS Inverter Short Circuit Fix', 'Electrician', 'Urgent electrician needed to isolate tripping main circuit breaker and replace 2 burnt switches.', 'Mandian', 34.1983, 73.2425, CURRENT_DATE, 3000.00, 'open'),
('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000004', 'Water Motor Pump Repair & PPRC Joint', 'Plumber', 'Submersible pump motor making grinding noise and leaking from main supply intake line.', 'Jhangi Syedan', 34.1750, 73.2280, CURRENT_DATE + 1, 2500.00, 'open'),
('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0000-000000000005', 'Elderly Mobility & Caregiver Support', 'Caregiver', 'Assistance for senior citizen with walking mobility and daily afternoon medication routine.', 'PMA Kakul Road', 34.1890, 73.2590, CURRENT_DATE + 3, 4000.00, 'open'),
('00000000-0000-0000-0000-000000000106', '00000000-0000-0000-0000-000000000006', 'Kitchen Cabinet Drawer & Hinges Overhaul', 'Carpenter', 'Three kitchen cabinet doors came off hinges. Requires realignment and new heavy-duty screw anchors.', 'Nawan Shehr', 34.1620, 73.2650, CURRENT_DATE + 2, 2800.00, 'open')
ON CONFLICT (id) DO NOTHING;

-- 5.4 JOB_APPLICATIONS
INSERT INTO public.job_applications (id, job_id, worker_id, proposed_rate, notes, status) VALUES
('00000000-0000-0000-0000-000000000151', '00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000010', 3500.00, 'I can bring my own specialized Desi spices and prepare fresh dinner on time.', 'pending'),
('00000000-0000-0000-0000-000000000152', '00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000016', 2800.00, 'I am located 1 km away in Mandian, available with complete multimeter tools in 30 mins.', 'pending')
ON CONFLICT (id) DO NOTHING;

-- 5.5 BOOKINGS
INSERT INTO public.bookings (id, employer_id, worker_id, service_date, start_time, duration_hours, total_amount, status, payment_method, payment_status, address, notes) VALUES
('00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000012', CURRENT_DATE - 3, '09:00:00', 3.0, 2200.00, 'completed', 'cash', 'confirmed', 'House 14, Lane 2, Mandian, Abbottabad', 'Deep kitchen and floor cleaning.'),
('00000000-0000-0000-0000-000000000202', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000010', CURRENT_DATE + 2, '10:00:00', 4.0, 3000.00, 'accepted', 'easypaisa', 'unpaid', 'House 14, Lane 2, Mandian, Abbottabad', 'Traditional family dinner menu.'),
('00000000-0000-0000-0000-000000000203', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000016', CURRENT_DATE - 1, '14:00:00', 2.0, 1800.00, 'completed', 'jazzcash', 'confirmed', 'Apartment 4B, Pine Heights, Supply Bazaar', 'UPS backup wiring restoration.'),
('00000000-0000-0000-0000-000000000204', '00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000018', CURRENT_DATE + 1, '11:00:00', 2.0, 1500.00, 'pending', 'cash', 'unpaid', 'House 88, Sector 1, Jhangi Syedan', 'Geyser pilot flame inspection.')
ON CONFLICT (id) DO NOTHING;

-- 5.6 REVIEWS
INSERT INTO public.reviews (id, booking_id, employer_id, worker_id, rating, punctuality_rating, behavior_rating, comment) VALUES
('00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000012', 5, 5, 5, 'Sana did an exceptional job cleaning our kitchen and windows. Highly recommended!'),
('00000000-0000-0000-0000-000000000302', '00000000-0000-0000-0000-000000000203', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000016', 5, 4, 5, 'Tariq bhai diagnosed the UPS wiring fault immediately and fixed the tripping issue.')
ON CONFLICT (id) DO NOTHING;
