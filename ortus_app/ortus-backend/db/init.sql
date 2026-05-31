CREATE EXTENSION IF NOT EXISTS "pgcrypto";

DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('director', 'manager', 'trainer', 'client');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE user_status AS ENUM ('active', 'inactive');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE order_status AS ENUM ('new', 'contacted', 'paid', 'delivering', 'completed', 'canceled');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS users (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number VARCHAR(50)  UNIQUE NOT NULL,
  full_name   VARCHAR(255) NOT NULL,
  role        user_role    NOT NULL DEFAULT 'client',
  status      user_status  NOT NULL DEFAULT 'active',
  password    TEXT         NOT NULL,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS products (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        VARCHAR(255) NOT NULL,
  description TEXT         NOT NULL DEFAULT '',
  category    VARCHAR(100) NOT NULL DEFAULT 'other',
  price       NUMERIC(12,2) NOT NULL,
  sizes       JSONB        NOT NULL DEFAULT '[]',
  images      JSONB        NOT NULL DEFAULT '[]',
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS carts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID         UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  items       JSONB        NOT NULL DEFAULT '[]',
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orders (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID          NOT NULL REFERENCES users(id),
  client_name    VARCHAR(255)  NOT NULL,
  client_phone   VARCHAR(50)   NOT NULL,
  items          JSONB         NOT NULL DEFAULT '[]',
  total_amount   NUMERIC(12,2) NOT NULL DEFAULT 0,
  status         order_status  NOT NULL DEFAULT 'new',
  client_comment TEXT          NOT NULL DEFAULT '',
  manager_note   TEXT          NOT NULL DEFAULT '',
  created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reports (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id    UUID        NOT NULL REFERENCES users(id),
  training_date TIMESTAMPTZ NOT NULL,
  slot          VARCHAR(50) NOT NULL,
  comment       TEXT        NOT NULL DEFAULT '',
  attachments   JSONB       NOT NULL DEFAULT '[]',
  is_late       BOOLEAN     NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
