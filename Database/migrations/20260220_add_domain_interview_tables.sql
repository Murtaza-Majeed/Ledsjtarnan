-- Migration: domain interview sections & questions
-- Generated 2026-02-20

begin;

create table if not exists domain_interview_sections (
    id uuid primary key default gen_random_uuid(),
    domain_id uuid not null references assessment_domains(id) on delete cascade,
    section_code text,
    title text not null,
    description text,
    display_order int not null default 0,
    unique (domain_id, section_code)
);

create table if not exists domain_interview_questions (
    id uuid primary key default gen_random_uuid(),
    section_id uuid not null references domain_interview_sections(id) on delete cascade,
    question_key text not null,
    label text not null,
    question_type text not null check (question_type in ('YES_NO','YES_NO_SPECIFY','TEXT','MULTIPLE_CHOICE','MULTI_SELECT','SCALE')),
    options jsonb,
    scale_min int,
    scale_max int,
    help_text text,
    display_order int not null default 0,
    unique (section_id, question_key)
);

commit;
