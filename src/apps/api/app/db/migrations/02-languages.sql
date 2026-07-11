-- Tabela: languages
-- Contract: docs/dev/contracts/language.md
CREATE TABLE languages (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code       TEXT NOT NULL UNIQUE, -- BCP 47: en, pt-BR, zh-TW
    name       TEXT NOT NULL,
    endonym    TEXT NOT NULL,
    is_active  BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_languages_active ON languages (is_active) WHERE is_active = true;

INSERT INTO languages (code, name, endonym) VALUES
    ('ar', 'Arabic', 'العربية'),
    ('da', 'Danish', 'Dansk'),
    ('de', 'German', 'Deutsch'),
    ('el', 'Greek', 'Ελληνικά'),
    ('en', 'English', 'English'),
    ('es', 'Spanish', 'Español'),
    ('fi', 'Finnish', 'Suomi'),
    ('fr', 'French', 'Français'),
    ('he', 'Hebrew', 'עברית'),
    ('hi', 'Hindi', 'हिन्दी'),
    ('it', 'Italian', 'Italiano'),
    ('ja', 'Japanese', '日本語'),
    ('ko', 'Korean', '한국어'),
    ('nl', 'Dutch', 'Nederlands'),
    ('no', 'Norwegian', 'Norsk'),
    ('pl', 'Polish', 'Polski'),
    ('pt-BR', 'Portuguese (Brazil)', 'Português'),
    ('pt-PT', 'Portuguese (Portugal)', 'Português'),
    ('ru', 'Russian', 'Русский'),
    ('sv', 'Swedish', 'Svenska'),
    ('th', 'Thai', 'ภาษาไทย'),
    ('tr', 'Turkish', 'Türkçe'),
    ('vi', 'Vietnamese', 'Tiếng Việt'),
    ('zh', 'Chinese (Simplified)', '中文'),
    ('zh-TW', 'Chinese (Traditional)', '繁體中文');
