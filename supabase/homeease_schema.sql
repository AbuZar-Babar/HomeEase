-- ============================================================================
-- HomeEase: Clean Database Schema (No Seed / Dummy Data)
-- Target: New Supabase Project "HomeEase"
-- Description: Core relational schema, indexes, automated triggers, and
--              Row Level Security (RLS) policies for HomeEase.
-- ============================================================================

-- 0. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. CORE RELATIONAL TABLES (DDL)
-- ============================================================================

-- 1.1 PROFILES (Extends auth.users for platform roles & identity)
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

-- 1.2 WORKER_PROFILES (Domain details for service professionals)
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

-- 1.3 JOBS (Marketplace job board listings)
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

-- 1.4 JOB_APPLICATIONS (Marketplace worker applications / bids)
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

-- 1.5 BOOKINGS (Service booking contracts with conflict management)
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    worker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    service_date DATE NOT NULL,
    start_time TIME WITHOUT TIME ZONE NOT NULL,
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

-- 1.6 REVIEWS (Multi-dimensional ratings & feedback)
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
-- 2. PERFORMANCE INDEXES
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
-- 3. FUNCTIONS & TRIGGERS (Hardened with explicit search_path)
-- ============================================================================

-- Function 3.1: updated_at Automatic Timestamp Update
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER 
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS touch_profiles_updated_at ON public.profiles;
CREATE TRIGGER touch_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS touch_worker_profiles_updated_at ON public.worker_profiles;
CREATE TRIGGER touch_worker_profiles_updated_at BEFORE UPDATE ON public.worker_profiles FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS touch_jobs_updated_at ON public.jobs;
CREATE TRIGGER touch_jobs_updated_at BEFORE UPDATE ON public.jobs FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS touch_bookings_updated_at ON public.bookings;
CREATE TRIGGER touch_bookings_updated_at BEFORE UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- Function 3.2: Auto-confirm new user emails (for frictionless onboarding)
CREATE OR REPLACE FUNCTION public.auto_confirm_new_users()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    NEW.email_confirmed_at = COALESCE(NEW.email_confirmed_at, now());
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_auto_confirm_new_users ON auth.users;
CREATE TRIGGER tr_auto_confirm_new_users
    BEFORE INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.auto_confirm_new_users();

-- Function 3.3: Automatic User Profile Creation on auth.users Sign-Up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
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
            COALESCE(NEW.raw_user_meta_data->>'locality', 'Abbottabad'),
            COALESCE(NEW.raw_user_meta_data->>'bio', 'Domestic service professional')
        )
        ON CONFLICT (id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function 3.4: Dynamic Worker Rating Re-calculation
CREATE OR REPLACE FUNCTION public.sync_worker_rating()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    target_worker_id UUID;
BEGIN
    target_worker_id := COALESCE(NEW.worker_id, OLD.worker_id);

    UPDATE public.worker_profiles
    SET 
        rating = COALESCE((
            SELECT ROUND(AVG(rating)::numeric, 2)
            FROM public.reviews
            WHERE worker_id = target_worker_id
        ), 0.0),
        reviews_count = (
            SELECT COUNT(*)
            FROM public.reviews
            WHERE worker_id = target_worker_id
        ),
        updated_at = now()
    WHERE id = target_worker_id;

    RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS on_review_created_or_updated ON public.reviews;
CREATE TRIGGER on_review_created_or_updated
    AFTER INSERT OR UPDATE OR DELETE ON public.reviews
    FOR EACH ROW EXECUTE FUNCTION public.sync_worker_rating();

-- Revoke direct RPC execution on internal triggers for extra security
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.sync_worker_rating() FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.auto_confirm_new_users() FROM anon, authenticated;

-- ============================================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

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
    WITH CHECK ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING ((SELECT auth.uid()) = id)
    WITH CHECK ((SELECT auth.uid()) = id);

-- 4.2 WORKER_PROFILES POLICIES
DROP POLICY IF EXISTS "Worker profiles viewable by all authenticated users" ON public.worker_profiles;
CREATE POLICY "Worker profiles viewable by all authenticated users"
    ON public.worker_profiles FOR SELECT
    TO authenticated, anon
    USING (profile_visibility = true OR (SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Workers can insert own profile" ON public.worker_profiles;
CREATE POLICY "Workers can insert own profile"
    ON public.worker_profiles FOR INSERT
    TO authenticated
    WITH CHECK ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Workers can update own profile" ON public.worker_profiles;
CREATE POLICY "Workers can update own profile"
    ON public.worker_profiles FOR UPDATE
    TO authenticated
    USING ((SELECT auth.uid()) = id)
    WITH CHECK ((SELECT auth.uid()) = id);

-- 4.3 JOBS POLICIES
DROP POLICY IF EXISTS "Jobs viewable by authenticated users" ON public.jobs;
CREATE POLICY "Jobs viewable by authenticated users"
    ON public.jobs FOR SELECT
    TO authenticated, anon
    USING (status = 'open' OR (SELECT auth.uid()) = employer_id);

DROP POLICY IF EXISTS "Employers can insert jobs" ON public.jobs;
CREATE POLICY "Employers can insert jobs"
    ON public.jobs FOR INSERT
    TO authenticated
    WITH CHECK ((SELECT auth.uid()) = employer_id);

DROP POLICY IF EXISTS "Employers can update own jobs" ON public.jobs;
CREATE POLICY "Employers can update own jobs"
    ON public.jobs FOR UPDATE
    TO authenticated
    USING ((SELECT auth.uid()) = employer_id)
    WITH CHECK ((SELECT auth.uid()) = employer_id);

DROP POLICY IF EXISTS "Employers can delete own jobs" ON public.jobs;
CREATE POLICY "Employers can delete own jobs"
    ON public.jobs FOR DELETE
    TO authenticated
    USING ((SELECT auth.uid()) = employer_id);

-- 4.4 JOB_APPLICATIONS POLICIES
DROP POLICY IF EXISTS "Applications viewable by applicant or job owner" ON public.job_applications;
CREATE POLICY "Applications viewable by applicant or job owner"
    ON public.job_applications FOR SELECT
    TO authenticated
    USING (
        (SELECT auth.uid()) = worker_id 
        OR EXISTS (
            SELECT 1 FROM public.jobs 
            WHERE jobs.id = job_applications.job_id 
            AND jobs.employer_id = (SELECT auth.uid())
        )
    );

DROP POLICY IF EXISTS "Workers can submit applications" ON public.job_applications;
CREATE POLICY "Workers can submit applications"
    ON public.job_applications FOR INSERT
    TO authenticated
    WITH CHECK ((SELECT auth.uid()) = worker_id);

DROP POLICY IF EXISTS "Applications status updateable by applicant or job owner" ON public.job_applications;
CREATE POLICY "Applications status updateable by applicant or job owner"
    ON public.job_applications FOR UPDATE
    TO authenticated
    USING (
        (SELECT auth.uid()) = worker_id 
        OR EXISTS (
            SELECT 1 FROM public.jobs 
            WHERE jobs.id = job_applications.job_id 
            AND jobs.employer_id = (SELECT auth.uid())
        )
    )
    WITH CHECK (
        (SELECT auth.uid()) = worker_id 
        OR EXISTS (
            SELECT 1 FROM public.jobs 
            WHERE jobs.id = job_applications.job_id 
            AND jobs.employer_id = (SELECT auth.uid())
        )
    );

-- 4.5 BOOKINGS POLICIES
DROP POLICY IF EXISTS "Bookings viewable by involved parties" ON public.bookings;
CREATE POLICY "Bookings viewable by involved parties"
    ON public.bookings FOR SELECT
    TO authenticated
    USING ((SELECT auth.uid()) = employer_id OR (SELECT auth.uid()) = worker_id);

DROP POLICY IF EXISTS "Employers can create bookings" ON public.bookings;
CREATE POLICY "Employers can create bookings"
    ON public.bookings FOR INSERT
    TO authenticated
    WITH CHECK ((SELECT auth.uid()) = employer_id);

DROP POLICY IF EXISTS "Bookings updatable by involved parties" ON public.bookings;
CREATE POLICY "Bookings updatable by involved parties"
    ON public.bookings FOR UPDATE
    TO authenticated
    USING ((SELECT auth.uid()) = employer_id OR (SELECT auth.uid()) = worker_id)
    WITH CHECK ((SELECT auth.uid()) = employer_id OR (SELECT auth.uid()) = worker_id);

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
        (SELECT auth.uid()) = employer_id
        AND EXISTS (
            SELECT 1 FROM public.bookings
            WHERE bookings.id = reviews.booking_id
            AND bookings.employer_id = (SELECT auth.uid())
            AND bookings.status = 'completed'
        )
    );

DROP POLICY IF EXISTS "Employers can update own review" ON public.reviews;
CREATE POLICY "Employers can update own review"
    ON public.reviews FOR UPDATE
    TO authenticated
    USING ((SELECT auth.uid()) = employer_id)
    WITH CHECK ((SELECT auth.uid()) = employer_id);
