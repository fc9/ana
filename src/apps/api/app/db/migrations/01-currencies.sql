-- Tabela: currencies
-- Contract: docs/dev/contracts/currency.md
--
-- Custos são sempre calculados e armazenados em USD (ver
-- contracts/token-usage.md). rate_to_usd só é usado na conversão ao
-- servir pela API, conforme a moeda do projeto — nunca para armazenar
-- custo em outra moeda.
CREATE TABLE currencies (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code         CHAR(3) NOT NULL UNIQUE, -- ISO 4217: USD, BRL, EUR
    name         TEXT NOT NULL,
    symbol       TEXT NOT NULL,
    rate_to_usd  NUMERIC(18,8) NULL,      -- 1 para USD; demais moedas
                                          -- ficam NULL até serem
                                          -- configuradas/atualizadas
    is_active    BOOLEAN NOT NULL DEFAULT true,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_currencies_active ON currencies (is_active) WHERE is_active = true;

INSERT INTO currencies (code, name, symbol, rate_to_usd) VALUES
    ('USD', 'US Dollar', '$', 1),
    ('EUR', 'Euro', '€', NULL),
    ('BRL', 'Brazilian Real', 'R$', NULL),
    ('GBP', 'Pound Sterling', '£', NULL),
    ('JPY', 'Japanese Yen', '¥', NULL),
    ('CNY', 'Chinese Yuan', '¥', NULL),
    ('CAD', 'Canadian Dollar', '$', NULL),
    ('AUD', 'Australian Dollar', '$', NULL),
    ('CHF', 'Swiss Franc', 'CHF', NULL),
    ('ARS', 'Argentine Peso', '$', NULL),
    ('MXN', 'Mexican Peso', '$', NULL),
    ('CLP', 'Chilean Peso', '$', NULL),
    ('COP', 'Colombian Peso', '$', NULL),
    ('PEN', 'Peruvian Sol', 'S/', NULL),
    ('UYU', 'Uruguayan Peso', '$U', NULL),
    ('INR', 'Indian Rupee', '₹', NULL),
    ('KRW', 'South Korean Won', '₩', NULL),
    ('SGD', 'Singapore Dollar', '$', NULL),
    ('HKD', 'Hong Kong Dollar', '$', NULL),
    ('NZD', 'New Zealand Dollar', '$', NULL),
    ('ZAR', 'South African Rand', 'R', NULL),
    ('SEK', 'Swedish Krona', 'kr', NULL),
    ('NOK', 'Norwegian Krone', 'kr', NULL),
    ('DKK', 'Danish Krone', 'kr', NULL),
    ('PLN', 'Polish Zloty', 'zł', NULL),
    ('CZK', 'Czech Koruna', 'Kč', NULL),
    ('HUF', 'Hungarian Forint', 'Ft', NULL),
    ('RON', 'Romanian Leu', 'lei', NULL),
    ('TRY', 'Turkish Lira', '₺', NULL),
    ('RUB', 'Russian Ruble', '₽', NULL),
    ('AED', 'UAE Dirham', 'د.إ', NULL),
    ('SAR', 'Saudi Riyal', '﷼', NULL),
    ('ILS', 'Israeli New Shekel', '₪', NULL),
    ('THB', 'Thai Baht', '฿', NULL),
    ('IDR', 'Indonesian Rupiah', 'Rp', NULL),
    ('MYR', 'Malaysian Ringgit', 'RM', NULL),
    ('PHP', 'Philippine Peso', '₱', NULL),
    ('VND', 'Vietnamese Dong', '₫', NULL);
