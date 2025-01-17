-- Create the employees table
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    salary DECIMAL(10, 2) NOT NULL,
    department VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create a unique index to constrain uniqueness by first_name, department, email, and salary
CREATE UNIQUE INDEX employees_unique_idx ON employees (first_name, department, email, salary);

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TABLE IF NOT EXISTS public.event_stream
(
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    profile_id text COLLATE pg_catalog."default",
    email text COLLATE pg_catalog."default",
    phone_number text COLLATE pg_catalog."default",
    account_id uuid NOT NULL,
    brand_id uuid,
    outlet_id uuid,
    source_id uuid NOT NULL,
    source_type text COLLATE pg_catalog."default" NOT NULL,
    source_created_at timestamp with time zone NOT NULL,
    source_updated_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data jsonb NOT NULL
);

CREATE INDEX IF NOT EXISTS event_stream_account_id_idx
    ON public.event_stream USING btree
    (account_id ASC NULLS LAST)
    INCLUDE(source_id, source_type)
    TABLESPACE pg_default;
-- Index: event_stream_created_at_idx

-- DROP INDEX IF EXISTS public.event_stream_created_at_idx;

CREATE INDEX IF NOT EXISTS event_stream_created_at_idx
    ON public.event_stream USING btree
    (created_at ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: event_stream_profile_id_idx

-- DROP INDEX IF EXISTS public.event_stream_profile_id_idx;

CREATE INDEX IF NOT EXISTS event_stream_profile_id_idx
    ON public.event_stream USING btree
    (profile_id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default
    WHERE profile_id IS NOT NULL;
-- Index: event_stream_source_type_source_id_uindex

-- DROP INDEX IF EXISTS public.event_stream_source_type_source_id_uindex;

CREATE UNIQUE INDEX IF NOT EXISTS event_stream_source_type_source_id_uindex
    ON public.event_stream USING btree
    (source_type COLLATE pg_catalog."default" ASC NULLS LAST, source_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_event_stream_custom

-- DROP INDEX IF EXISTS public.idx_event_stream_custom;

CREATE INDEX IF NOT EXISTS idx_event_stream_custom
    ON public.event_stream USING btree
    (created_at ASC NULLS LAST, account_id ASC NULLS LAST, source_type COLLATE pg_catalog."default" ASC NULLS LAST, source_id ASC NULLS LAST)
    TABLESPACE pg_default
    WHERE source_type = 'CUSTOM_EVENT'::text;
-- Index: idx_event_stream_non_custom

-- DROP INDEX IF EXISTS public.idx_event_stream_non_custom;

CREATE INDEX IF NOT EXISTS idx_event_stream_non_custom
    ON public.event_stream USING btree
    (created_at ASC NULLS LAST, account_id ASC NULLS LAST, source_type COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default
    WHERE source_type <> 'CUSTOM_EVENT'::text;
-- Index: idx_source_id

-- DROP INDEX IF EXISTS public.idx_source_id;

CREATE INDEX IF NOT EXISTS idx_source_id
    ON public.event_stream USING btree
    (source_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_unique_data_hash

-- DROP INDEX IF EXISTS public.idx_unique_data_hash;

CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_data_hash
    ON public.event_stream USING btree
    ((md5(data::text)::uuid) ASC NULLS LAST)
    TABLESPACE pg_default;