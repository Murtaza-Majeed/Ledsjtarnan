-- Migration: add summary columns to assessments table
-- These columns store computed results after assessment completion.
-- Generated 2026-02-26

begin;

alter table assessments
    add column if not exists ptsd_total_score int,
    add column if not exists ptsd_probable boolean,
    add column if not exists safety_flags jsonb,
    add column if not exists intervention_summary jsonb,
    add column if not exists domain_scores jsonb;

comment on column assessments.ptsd_total_score is 'Sum of STRESS symptom items (q22-q46), range 0-75';
comment on column assessments.ptsd_probable is 'True when all four PTSD criteria (B,C,D,E) are met';
comment on column assessments.safety_flags is 'Array of {type, message, requiresAction} objects';
comment on column assessments.intervention_summary is 'Per-domain {needLevel, interventions[], isUrgent, notes}';
comment on column assessments.domain_scores is 'Per-domain {iScore, iScoreStaff, mScore, pScore, notes, scoreType}';

commit;
