-- Migration: problem domains (extended assessments)
-- Generated 2026-02-20

begin;

create table if not exists problem_domains (
    id uuid primary key default gen_random_uuid(),
    code text not null unique,
    app_key text not null unique,
    title text not null,
    subtitle text,
    icon text,
    score_type text not null check (score_type in ('SALUTOGENIC','PATHOGENIC')),
    scoring_question text not null,
    created_at timestamptz not null default now()
);

create table if not exists problem_domain_sections (
    id uuid primary key default gen_random_uuid(),
    domain_id uuid not null references problem_domains(id) on delete cascade,
    section_code text,
    title text not null,
    description text,
    display_order int not null default 0,
    is_scoring_section boolean not null default false,
    unique (domain_id, section_code)
);

create table if not exists problem_domain_questions (
    id uuid primary key default gen_random_uuid(),
    section_id uuid not null references problem_domain_sections(id) on delete cascade,
    question_key text not null,
    label text not null,
    question_type text not null check (question_type in (
        'YES_NO',
        'YES_NO_SPECIFY',
        'TEXT',
        'MULTIPLE_CHOICE',
        'MULTI_SELECT',
        'SCALE',
        'M_SCORE',
        'P_SCORE'
    )),
    options jsonb,
    scale_min int,
    scale_max int,
    help_text text,
    is_safety_question boolean not null default false,
    safety_trigger_value jsonb,
    display_order int not null default 0,
    unique (section_id, question_key)
);

commit;
