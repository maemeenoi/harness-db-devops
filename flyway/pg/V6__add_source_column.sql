ALTER TABLE redgate.feedbackaudit
ADD COLUMN IF NOT EXISTS source VARCHAR(50);
