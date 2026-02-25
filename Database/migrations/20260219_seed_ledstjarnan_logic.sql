-- Seed data for Ledstjärnan logic tables
-- Generated 2026-02-19

begin;

-- Scoring dimensions
insert into scoring_dimensions (code, description, scale_direction) values
    ('SALUTOGENES', 'Strength-based assessment of resources and daily function', 'INVERTED'),
    ('PATOGENES', 'Problem-focused assessment (substance use, MH, trauma)', 'NORMAL')
on conflict (code) do nothing;

-- Treatment levels
delete from treatment_levels;
insert into treatment_levels (code, name, description, requires_baseline, auto_assignment_logic) values
    ('LEVEL_0', 'LEDSTJÄRNAN', 'Assessment & baseline mapping. Mandatory for all clients.', true, jsonb_build_object('role', 'baseline')), 
    ('LEVEL_1', 'LIVBOJEN', 'Salutogenic life-skills program. Building independence, daily structure, health habits.', true, jsonb_build_object('min_level', 1)),
    ('LEVEL_2', 'LIVBOJEN 2', 'Deepened work on attachment, relationships, and social skills.', true, jsonb_build_object('min_salutogenic', 3)),
    ('LEVEL_3', 'LIVLINAN', 'Trauma program with DBT. For clients with deep attachment/regulation needs.', true, jsonb_build_object('requires_trauma_flags', true));

-- Assessment domains (six salutogenic life areas + patogenic areas)
with dimension_ids as (
    select id, code from scoring_dimensions
)
insert into assessment_domains (dimension_id, code, label, description, life_area_order)
values
    ((select id from dimension_ids where code='SALUTOGENES'), 'KROPP_HÄLSA', 'Body & Health', 'Physical health, somatic status, daily routines.', 1),
    ((select id from dimension_ids where code='SALUTOGENES'), 'UTBILDNING_ARBETE', 'Education & Work', 'School/work participation, structure, aspirations.', 2),
    ((select id from dimension_ids where code='SALUTOGENES'), 'SOCIAL_KOMPETENS', 'Social Competence', 'Social skills, interactions, peer relationships.', 3),
    ((select id from dimension_ids where code='SALUTOGENES'), 'SJALVSTANDIGHET_VARDAG', 'Independence & Daily Life', 'Self-care, ADL, daily responsibilities.', 4),
    ((select id from dimension_ids where code='SALUTOGENES'), 'RELATIONER_NATVERK', 'Relationships & Network', 'Family ties, support network, attachment.', 5),
    ((select id from dimension_ids where code='SALUTOGENES'), 'IDENTITET_UTVECKLING', 'Identity & Development', 'Sense of self, future orientation, emotional maturity.', 6),
    ((select id from dimension_ids where code='PATOGENES'), 'ALKOHOL_DROGER', 'Substance Use', 'Alcohol and drug problems.', null),
    ((select id from dimension_ids where code='PATOGENES'), 'ANKNYTNING_RELATIONER', 'Attachment & Relationships', 'Problematic attachment/relationships.', null),
    ((select id from dimension_ids where code='PATOGENES'), 'PSYKISK_OHALSA', 'Mental Health', 'Internalizing/externalizing MH problems.', null),
    ((select id from dimension_ids where code='PATOGENES'), 'ALLVARLIG_PSYKISK_OHALSA', 'Severe Mental Health', 'Self-harm, psychosis, suicidality.', null)
    on conflict (code) do update set label=excluded.label, description=excluded.description;

-- Domain score slots (I client, I staff, M receptivity, P priority for salutogenic domains)
insert into domain_score_slots (domain_id, slot_code, label, description, actor, scale_min, scale_max)
select d.id, slot_info.slot_code, slot_info.label, slot_info.description, slot_info.actor, 1, 5
from assessment_domains d
join (
    values
        ('KROPP_HÄLSA','I','Client rating', 'Client-reported score', 'CLIENT'),
        ('KROPP_HÄLSA','I_STAFF','Staff rating','Staff clinical score','STAFF'),
        ('KROPP_HÄLSA','M','Motivation/receptivity','How open the youth is to change','STAFF'),
        ('KROPP_HÄLSA','P','Priority','Staff-set priority','STAFF'),
        ('UTBILDNING_ARBETE','I','Client rating','Client-reported score','CLIENT'),
        ('UTBILDNING_ARBETE','I_STAFF','Staff rating','Staff clinical score','STAFF'),
        ('UTBILDNING_ARBETE','M','Motivation','Receptivity for interventions','STAFF'),
        ('UTBILDNING_ARBETE','P','Priority','Priority for planning','STAFF'),
        ('SOCIAL_KOMPETENS','I','Client rating','Client-reported score','CLIENT'),
        ('SOCIAL_KOMPETENS','I_STAFF','Staff rating','Staff clinical score','STAFF'),
        ('SOCIAL_KOMPETENS','M','Motivation','Receptivity for change','STAFF'),
        ('SOCIAL_KOMPETENS','P','Priority','Priority','STAFF'),
        ('SJALVSTANDIGHET_VARDAG','I','Client rating','Client-reported score','CLIENT'),
        ('SJALVSTANDIGHET_VARDAG','I_STAFF','Staff rating','Staff clinical score','STAFF'),
        ('SJALVSTANDIGHET_VARDAG','M','Motivation','Receptivity for change','STAFF'),
        ('SJALVSTANDIGHET_VARDAG','P','Priority','Priority','STAFF'),
        ('RELATIONER_NATVERK','I','Client rating','Client-reported score','CLIENT'),
        ('RELATIONER_NATVERK','I_STAFF','Staff rating','Staff clinical score','STAFF'),
        ('RELATIONER_NATVERK','M','Motivation','Receptivity','STAFF'),
        ('RELATIONER_NATVERK','P','Priority','Priority','STAFF'),
        ('IDENTITET_UTVECKLING','I','Client rating','Client-reported score','CLIENT'),
        ('IDENTITET_UTVECKLING','I_STAFF','Staff rating','Staff clinical score','STAFF'),
        ('IDENTITET_UTVECKLING','M','Motivation','Receptivity','STAFF'),
        ('IDENTITET_UTVECKLING','P','Priority','Priority','STAFF'),
        ('ALKOHOL_DROGER','CLIENT','Ungdomens skattning','Hur den unge skattar problemnivån','CLIENT'),
        ('ALKOHOL_DROGER','STAFF','Behandlarens bedömning','Personalens samlade bedömning','STAFF'),
        ('ALKOHOL_DROGER','M','Motivation','Receptivitet/motivation','STAFF'),
        ('ALKOHOL_DROGER','P','Prioritet','Hur viktigt området är i planen','STAFF'),
        ('ANKNYTNING_RELATIONER','CLIENT','Ungdomens skattning','Hur den unge skattar problemnivån','CLIENT'),
        ('ANKNYTNING_RELATIONER','STAFF','Behandlarens bedömning','Personalens samlade bedömning','STAFF'),
        ('ANKNYTNING_RELATIONER','M','Motivation','Receptivitet/motivation','STAFF'),
        ('ANKNYTNING_RELATIONER','P','Prioritet','Hur viktigt området är i planen','STAFF'),
        ('PSYKISK_OHALSA','CLIENT','Ungdomens skattning','Hur den unge skattar problemnivån','CLIENT'),
        ('PSYKISK_OHALSA','STAFF','Behandlarens bedömning','Personalens samlade bedömning','STAFF'),
        ('PSYKISK_OHALSA','M','Motivation','Receptivitet/motivation','STAFF'),
        ('PSYKISK_OHALSA','P','Prioritet','Hur viktigt området är i planen','STAFF'),
        ('ALLVARLIG_PSYKISK_OHALSA','CLIENT','Ungdomens skattning','Hur den unge skattar problemnivån','CLIENT'),
        ('ALLVARLIG_PSYKISK_OHALSA','STAFF','Behandlarens bedömning','Personalens samlade bedömning','STAFF'),
        ('ALLVARLIG_PSYKISK_OHALSA','M','Motivation','Receptivitet/motivation','STAFF'),
        ('ALLVARLIG_PSYKISK_OHALSA','P','Prioritet','Hur viktigt området är i planen','STAFF')
) as slot_info(domain_code, slot_code, label, description, actor)
    on d.code = slot_info.domain_code
on conflict (domain_id, slot_code) do update set label=excluded.label, description=excluded.description;

-- Assessment steps
insert into assessment_steps (step_number, title, description) values
    (1, 'Prepare & Build Rapport', 'Introduce assessment purpose, explain levels, obtain consent.'),
    (2, 'Interview 6 Life Areas', 'Guided interviews for salutogenic domains with youth and staff.'),
    (3, 'Problem & Trauma Mapping', 'Capture patogenic scores, trauma checklists, PTSD criteria.'),
    (4, 'Synthesis & Planning', 'Summarize findings, set plan priorities, auto-generate suggestions.')
on conflict (step_number) do update set title=excluded.title, description=excluded.description;

-- Trauma/PTSD rules
insert into trauma_rules (rule_code, description, logic) values
    ('TRAUMA_ADULT_EVENTS', 'Adult trauma flag triggered when ≥2 YES answers on Q1–21 (adult subset).', jsonb_build_object('question_range', json_build_array(1,21), 'threshold', 2, 'type', 'adult')), 
    ('TRAUMA_CHILD_EVENTS', 'Childhood trauma flag triggered when ≥2 YES answers on Q1–21 (child subset).', jsonb_build_object('question_range', json_build_array(1,21), 'threshold', 2, 'type', 'child')), 
    ('PTSD_CRITERIA_B', 'Criterion B met when intrusion items >= threshold.', jsonb_build_object('questions', json_build_array(22,23,24,25,26,27), 'threshold', 1)), 
    ('PTSD_CRITERIA_C', 'Criterion C met when avoidance items >= threshold.', jsonb_build_object('questions', json_build_array(28,29,30,31,32), 'threshold', 1)), 
    ('PTSD_CRITERIA_D', 'Criterion D met when cognition/mood items >= threshold.', jsonb_build_object('questions', json_build_array(33,34,35,36,37,38,39), 'threshold', 2)), 
    ('PTSD_CRITERIA_E', 'Criterion E met when arousal/reactivity >= threshold.', jsonb_build_object('questions', json_build_array(40,41,42,43,44,45), 'threshold', 2)), 
    ('PTSD_FUNCTIONAL_IMPAIR', 'Functional impairment flag when ≥1 YES on Q47–52.', jsonb_build_object('questions', json_build_array(47,48,49,50,51,52), 'threshold', 1)), 
    ('PTSD_DISSOCIATION', 'Dissociation specifier when DS1 or DS2 ≥2 points.', jsonb_build_object('questions', json_build_array('DS1','DS2'), 'threshold', 2))
on conflict (rule_code) do update set description=excluded.description, logic=excluded.logic;

-- Guidebook entries (system overview + scoring note)
insert into guidebook_entries (slug, category, content_md) values
    ('system_overview', 'overview', '# What Ledstjärnan Is\nLedstjärnan is the entry point of all treatment at Västerbo Social Omsorg...'),
    ('two_scoring_dimensions', 'scoring', 'Everything revolves around two types of assessment: **Salutogenes** (strengths, inverted scale) and **Patogenes** (problems, normal scale).')
on conflict (slug) do update set content_md = excluded.content_md;

commit;
