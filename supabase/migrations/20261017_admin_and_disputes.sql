-- ============================================================================
-- Migration: 20261017_admin_and_disputes.sql
-- Description: Dedicated Disputes Table, Audit Trail, and RLS Policies for HomeEase
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.disputes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    complainant_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    respondent_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    evidence_path TEXT,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'under_review', 'resolved', 'dismissed')),
    resolution_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    resolved_at TIMESTAMPTZ
);

-- Indexes for dispute lookups and audit queries
CREATE INDEX IF NOT EXISTS idx_disputes_booking_id ON public.disputes(booking_id);
CREATE INDEX IF NOT EXISTS idx_disputes_complainant_id ON public.disputes(complainant_id);
CREATE INDEX IF NOT EXISTS idx_disputes_respondent_id ON public.disputes(respondent_id);
CREATE INDEX IF NOT EXISTS idx_disputes_status ON public.disputes(status);

-- Automatic updated_at trigger
DROP TRIGGER IF EXISTS touch_disputes_updated_at ON public.disputes;
CREATE TRIGGER touch_disputes_updated_at
    BEFORE UPDATE ON public.disputes
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- Enable Row Level Security (RLS)
ALTER TABLE public.disputes ENABLE ROW LEVEL SECURITY;

-- 1. SELECT Policy: Complainant, Respondent, or Platform Admin can view dispute
DROP POLICY IF EXISTS "Disputes viewable by involved parties" ON public.disputes;
CREATE POLICY "Disputes viewable by involved parties"
    ON public.disputes FOR SELECT
    TO authenticated
    USING (
        (SELECT auth.uid()) = complainant_id
        OR (SELECT auth.uid()) = respondent_id
        OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (SELECT auth.uid())
            AND profiles.role = 'admin'
        )
    );

-- 2. INSERT Policy: Authenticated users can file dispute as complainant
DROP POLICY IF EXISTS "Users can create disputes as complainant" ON public.disputes;
CREATE POLICY "Users can create disputes as complainant"
    ON public.disputes FOR INSERT
    TO authenticated
    WITH CHECK ((SELECT auth.uid()) = complainant_id);

-- 3. UPDATE Policy: Complainant can update notes; Admin can adjudicate
DROP POLICY IF EXISTS "Admin or complainant can update disputes" ON public.disputes;
CREATE POLICY "Admin or complainant can update disputes"
    ON public.disputes FOR UPDATE
    TO authenticated
    USING (
        (SELECT auth.uid()) = complainant_id
        OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (SELECT auth.uid())
            AND profiles.role = 'admin'
        )
    )
    WITH CHECK (
        (SELECT auth.uid()) = complainant_id
        OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (SELECT auth.uid())
            AND profiles.role = 'admin'
        )
    );
