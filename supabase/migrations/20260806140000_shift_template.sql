-- CentroCare Planner - Migration: shift_template
-- La "Pianificazione Turni" è una settimana tipo (template) ripetuta ogni settimana.
-- Le settimane reali (Validazione Turni) copiano il template in turni datati.

ALTER TABLE shifts
  ADD COLUMN is_template BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN template_weekday SMALLINT,
  ADD COLUMN template_shift_id TEXT;

-- Presente solo su installazioni gia' esistenti (aggiunta manualmente su prod).
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS duration_weeks INTEGER;

CREATE INDEX idx_shifts_is_template ON shifts(is_template);
CREATE INDEX idx_shifts_template_shift_id ON shifts(template_shift_id);
