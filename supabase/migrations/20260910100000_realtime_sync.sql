-- CentroCare Planner - Migration: realtime_sync
-- Sincronizzazione in tempo reale tra utenti (Livello 1+2):
--   * colonna updated_at su shifts / tutors / youths (monitorata con trigger)
--   * tabelle aggiunte alla pubblicazione supabase_realtime per i postgres_changes

-- 1) Colonna updated_at (idempotente)
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE tutors ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE youths ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

-- 2) Trigger che aggiornano updated_at a ogni UPDATE
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_shifts_updated_at ON public.shifts;
CREATE TRIGGER trg_shifts_updated_at
  BEFORE UPDATE ON public.shifts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_tutors_updated_at ON public.tutors;
CREATE TRIGGER trg_tutors_updated_at
  BEFORE UPDATE ON public.tutors
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_youths_updated_at ON public.youths;
CREATE TRIGGER trg_youths_updated_at
  BEFORE UPDATE ON public.youths
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 3) Pubblicazione realtime (idempotente: fallisce silenziosamente se il progetto
--    non ha ancora Realtime abilitato - basta aggiungere le tabelle dal dashboard)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'shifts') THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.shifts;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'tutors') THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.tutors;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'youths') THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.youths;
    END IF;
  END IF;
END;
$$;