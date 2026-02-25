-- Seed Ledstjärnan interview sections/questions (remaining domains)
-- Generated 2026-02-20

begin;

-- Helper deletes for a given domain code
create or replace function _delete_domain_interviews(domain_code text) returns void as $$
declare
    domain_uuid uuid;
begin
    select id into domain_uuid from assessment_domains where code = domain_code;
    if domain_uuid is NULL then
        return;
    end if;
    delete from domain_interview_questions
    where section_id in (
        select id from domain_interview_sections where domain_id = domain_uuid
    );
    delete from domain_interview_sections where domain_id = domain_uuid;
end;
$$ language plpgsql;

select _delete_domain_interviews('UTBILDNING_ARBETE');
select _delete_domain_interviews('SOCIAL_KOMPETENS');
select _delete_domain_interviews('SJALVSTANDIGHET_VARDAG');
select _delete_domain_interviews('RELATIONER_NATVERK');
select _delete_domain_interviews('IDENTITET_UTVECKLING');
select _delete_domain_interviews('ALKOHOL_DROGER');
select _delete_domain_interviews('ANKNYTNING_RELATIONER');
select _delete_domain_interviews('PSYKISK_OHALSA');
select _delete_domain_interviews('ALLVARLIG_PSYKISK_OHALSA');

-- ==== UTBILDNING & ARBETE ====

with domain as (
    select id from assessment_domains where code = 'UTBILDNING_ARBETE'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'EDUCATION_HISTORY', 'Utbildningsbakgrund', 'Formell skolgång och behörigheter.', 1
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('completed_primary', 'Har du slutfört grundskolan?', 'YES_NO', NULL::jsonb, NULL, NULL, NULL, 1),
    ('completed_secondary', 'Har du fullföljt gymnasium eller motsvarande?', 'YES_NO', NULL, NULL, NULL, NULL, 2),
    ('vocational_certificate', 'Har du en yrkesutbildning/certifiering? (ange vilken)', 'YES_NO_SPECIFY', NULL, NULL, NULL, NULL, 3),
    ('drivers_license', 'Har du giltigt körkort (A/B/C)?', 'YES_NO', NULL, NULL, NULL, NULL, 4)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'UTBILDNING_ARBETE'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'WORK_ECONOMY', 'Arbete & ekonomi', 'Arbetslivserfarenhet och ekonomisk trygghet.', 2
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('work_experience', 'Har du arbetat minst 6 månader i följd?', 'YES_NO', NULL, NULL, NULL, 'Räkna även praktik eller oregistrerat arbete.', 1),
    ('current_income_sources', 'Vilka inkomstkällor hade du senaste 30 dagarna?', 'MULTI_SELECT', jsonb_build_array('Anställning','CSN/Studielån','Ersättning från Försäkringskassan','Försörjningsstöd','Familj/vänner','Annat'), NULL, NULL, 'Markera alla som gäller.', 2),
    ('feels_secure_phase', 'Känner du dig trygg i din nuvarande studie/arbetsfas?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja','Delvis','Nej','Osäker'), NULL, NULL, NULL, 3),
    ('economy_affects_treatment', 'Upplever du att din ekonomi påverkar hur andra bemöter dig?', 'YES_NO_SPECIFY', NULL, NULL, NULL, NULL, 4)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'UTBILDNING_ARBETE'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'FUTURE_PLANS', 'Motivation & framtidsplaner', 'Planer, motivation och stödbehov.', 3
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('meaning_in_work', 'Ger studier/arbete dig mening just nu?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja, mycket','Delvis','Nej','Vet inte'), NULL, NULL, NULL, 1),
    ('has_plan_next6', 'Har du en konkret plan för de kommande 6 månaderna?', 'YES_NO_SPECIFY', NULL, NULL, NULL, 'Beskriv planens steg om svaret är ja.', 2),
    ('support_needed', 'Vad skulle hjälpa dig mest för att komma vidare?', 'TEXT', NULL, NULL, NULL, 'Beskriv resurser, personer eller utbildning.', 3),
    ('importance_support', 'Hur viktigt är stöd inom utbildning/arbete?', 'SCALE', NULL, 1, 5, '1 = inte viktigt, 5 = avgörande.', 4)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'UTBILDNING_ARBETE'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'BARRIERS', 'Hinder & uppföljning', 'Identifiera hinder och nästa steg.', 4
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('satisfied_economy', 'Hur nöjd är du med livssituation och ekonomi senaste 30 dagarna?', 'SCALE', NULL, 1, 5, '1 = inte nöjd alls, 5 = helt nöjd.', 1),
    ('barriers_list', 'Vilka hinder stoppar dig från studier/arbete just nu?', 'MULTI_SELECT', jsonb_build_array('Hälsa','Motivation','Språk','Barnomsorg','Skuld/Ekonomi','Annat'), NULL, NULL, 'Markera alla som passar.', 2),
    ('need_staff_support', 'Önskar du stöd från personal inom detta område?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja, akut','Ja, inom kort','Osäker','Nej'), NULL, NULL, NULL, 3),
    ('education_notes', 'Övriga anteckningar för kartläggningen', 'TEXT', NULL, NULL, NULL, NULL, 4)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);

-- ==== SOCIAL KOMPETENS & ARENOR ====

with domain as (
    select id from assessment_domains where code = 'SOCIAL_KOMPETENS'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'EMOTIONAL_INTELLIGENCE', 'Emotionell intelligens', 'Förmåga att förstå och reglera känslor.', 1
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('understand_emotions', 'Är du bra på att förstå dina egna känslor?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja','Delvis','Nej'), NULL, NULL, NULL, 1),
    ('express_feelings', 'Kan du uttrycka känslor på ett lugnt sätt?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja ofta','Ibland','Sällan'), NULL, NULL, NULL, 2),
    ('empathy_use', 'Använder du empati i sociala situationer?', 'YES_NO_SPECIFY', NULL, NULL, NULL, NULL, 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'SOCIAL_KOMPETENS'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'DBT_EMOTION', 'DBT – känsloreglering', 'Kartlägg vilka färdigheter som används.', 2
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('labels_feelings', 'Kan du identifiera och beskriva känslor för andra?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja','Delvis','Nej'), NULL, NULL, NULL, 1),
    ('change_negative_states', 'Har du strategier för att förändra negativa känslor?', 'YES_NO_SPECIFY', NULL, NULL, NULL, 'Exempel: motsatt handling, självomhändertagande.', 2),
    ('dbt_skills_used', 'Vilka färdigheter använder du när det är svårt?', 'MULTI_SELECT', jsonb_build_array('STOPP','Självomhändertagande','Fysisk aktivitet','Avledning','Vet inte'), NULL, NULL, 'Markera alla som används.', 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'SOCIAL_KOMPETENS'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'DBT_INTERPERSONAL', 'DBT – relationer', 'Behov, gränssättning och kommunikation.', 3
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('express_needs', 'Kan du uttrycka dina behov till andra utan konflikt?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja','Ibland','Sällan'), NULL, NULL, NULL, 1),
    ('sets_boundaries', 'Sätter du gränser när något känns fel?', 'YES_NO', NULL, NULL, NULL, NULL, 2),
    ('defensive_reaction', 'Blir du lätt defensiv eller aggressiv i samtal?', 'MULTIPLE_CHOICE', jsonb_build_array('Nej','Ibland','Ofta'), NULL, NULL, NULL, 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'SOCIAL_KOMPETENS'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'DBT_STRESS', 'DBT – stresshantering', 'Stressnivå och strategier mot överbelastning.', 4
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('stress_frequency', 'Hur ofta känner du dig överväldigad av stress?', 'MULTIPLE_CHOICE', jsonb_build_array('Nästan aldrig','Några gånger/mån','Varje vecka','Dagligen'), NULL, NULL, NULL, 1),
    ('stress_strategies', 'Vilka strategier använder du när det blir för mycket?', 'MULTI_SELECT', jsonb_build_array('Andningsövningar','Prata med personal','Avledning','Skadligt beteende','Vet inte'), NULL, NULL, 'Markera alla som förekommer.', 2),
    ('needs_new_strategies', 'Behöver du nya sätt att hantera stress?', 'YES_NO_SPECIFY', NULL, NULL, NULL, NULL, 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'SOCIAL_KOMPETENS'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'LEGAL_HISTORY', 'Rättslig historik', 'Eventuell kriminalitet och myndighetskontakter.', 5
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('legal_charges', 'Har du varit misstänkt eller dömd för något brott?', 'MULTI_SELECT', jsonb_build_array('Narkotika','Egendom','Våld','Trafik/DUI','Annat','Nej'), NULL, NULL, 'Markera allt som förekommit.', 1),
    ('lob_events', 'Har du blivit omhändertagen enligt LOB eller ordningsstörning?', 'YES_NO', NULL, NULL, NULL, NULL, 2),
    ('legal_notes', 'Finns pågående rättsprocesser vi behöver känna till?', 'TEXT', NULL, NULL, NULL, NULL, 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);

-- ==== SJÄLVSTÄNDIGHET & VARDAG ====

with domain as (
    select id from assessment_domains where code = 'SJALVSTANDIGHET_VARDAG'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'INCOME_SOURCES', 'Inkomst & försörjning', 'Kartlägg senaste 30 dagarnas ekonomi.', 1
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('income_types', 'Vilka inkomster hade du de senaste 30 dagarna?', 'MULTI_SELECT', jsonb_build_array('Lön','Bidrag/Försäkringskassan','Studielån','Familj/vänner','Illegal inkomst','Sex mot ersättning','Spel/Gambling','Annat'), NULL, NULL, 'Markera alla som stämmer.', 1),
    ('economy_stability', 'Känns ekonomin stabil just nu?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja','Delvis','Nej'), NULL, NULL, NULL, 2),
    ('economy_affects_choices', 'Påverkar ekonomin dina vardagsval?', 'YES_NO_SPECIFY', NULL, NULL, NULL, 'Exempel: tacka nej till aktiviteter, välja billigare mat.', 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'SJALVSTANDIGHET_VARDAG'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'HOUSING_ENV', 'Boende & miljö', 'Trygghet och trivsel i hemmet.', 2
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('living_safe', 'Känner du dig säker i din nuvarande boendemiljö?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja helt','Delvis','Nej'), NULL, NULL, NULL, 1),
    ('change_home', 'Finns det något du vill förändra i boendet för att må bättre?', 'TEXT', NULL, NULL, NULL, NULL, 2),
    ('support_in_home', 'Har du stödpersoner som hjälper i hemmet?', 'YES_NO_SPECIFY', NULL, NULL, NULL, 'Exempel: boendestöd, god man, kontaktperson.', 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'SJALVSTANDIGHET_VARDAG'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'ADL_ROUTINES', 'ADL & vardagsrutiner', 'Hygien, städning, struktur.', 3
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('hygiene_level', 'Hur fungerar din personliga hygien i vardagen?', 'MULTIPLE_CHOICE', jsonb_build_array('Fungerar bra','Behöver påminnelser','Behöver mycket stöd'), NULL, NULL, NULL, 1),
    ('home_care', 'Klarar du städning och tvätt på egen hand?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja','Delvis','Nej'), NULL, NULL, NULL, 2),
    ('daily_structure', 'Har du en daglig struktur med tider för mat, sömn, aktiviteter?', 'YES_NO_SPECIFY', NULL, NULL, NULL, NULL, 3),
    ('identity_style', 'Har du en personlig stil som speglar vem du är?', 'YES_NO_SPECIFY', NULL, NULL, NULL, NULL, 4),
    ('wants_style_change', 'Finns det något med stil/utseende du vill ändra för välmående?', 'TEXT', NULL, NULL, NULL, NULL, 5)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'SJALVSTANDIGHET_VARDAG'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'SUPPORT_NEEDS', 'Stödbehov & prioritering', 'Upplevd nöjdhet och behov av hjälp.', 4
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('satisfaction_housing', 'Hur nöjd är du med boende och vardag senaste 30 dagarna?', 'SCALE', NULL, 1, 5, '1 = inte nöjd alls, 5 = mycket nöjd.', 1),
    ('needs_support_area', 'Vilket stöd behöver du mest?', 'MULTI_SELECT', jsonb_build_array('Boendestöd','Ekonomi/Budget','ADL-träning','Kontaktperson','Annat'), NULL, NULL, NULL, 2),
    ('followup_priority', 'Hur viktigt är detta område för dig just nu?', 'SCALE', NULL, 1, 5, '1 = låg prioritet, 5 = topp-prio.', 3),
    ('adl_notes', 'Övriga anteckningar', 'TEXT', NULL, NULL, NULL, NULL, 4)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);

-- ==== RELATIONER & NÄTVERK ====

with domain as (
    select id from assessment_domains where code = 'RELATIONER_NATVERK'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'RELATION_STATUS', 'Relationsstatus', 'Nuvarande relationer och familjesituation.', 1
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('relationship_status', 'Hur ser din nuvarande relationsstatus ut?', 'MULTIPLE_CHOICE', jsonb_build_array('Singel','I relation','Gift/Sambo','Komplext'), NULL, NULL, 'Beskriv gärna om relationen är stabil eller konfliktfylld.', 1),
    ('has_children', 'Har du egna barn eller lever med någon annans barn?', 'YES_NO_SPECIFY', NULL, NULL, NULL, NULL, 2),
    ('expecting_child', 'Förväntar du barn just nu?', 'YES_NO', NULL, NULL, NULL, NULL, 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'RELATIONER_NATVERK'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'SUPPORT_NETWORK', 'Stöd & nätverk', 'Tillgång till personer som ger emotionellt stöd.', 2
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('has_support_people', 'Finns det flera personer du kan vända dig till när det är svårt?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja, flera','Enstaka','Ingen'), NULL, NULL, NULL, 1),
    ('main_support_person', 'Vem pratar du helst med om viktiga saker?', 'TEXT', NULL, NULL, NULL, 'Ange namn/roll (vän, partner, personal).', 2),
    ('needs_network_map', 'Behöver du hjälp att kartlägga ditt nätverk?', 'YES_NO', NULL, NULL, NULL, NULL, 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'RELATIONER_NATVERK'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'LONELINESS_COPING', 'Ensamhet & strategier', 'Hur klienten hanterar ensamhet utan destruktivitet.', 3
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('feels_lonely', 'Känner du dig ofta ensam även bland andra?', 'MULTIPLE_CHOICE', jsonb_build_array('Sällan','Ibland','Ofta'), NULL, NULL, NULL, 1),
    ('lonely_strategies', 'Vad brukar du göra när du känner dig ensam?', 'TEXT', NULL, NULL, NULL, 'Beskriv både hjälpsamma och svåra strategier.', 2),
    ('needs_loneliness_support', 'Behöver du stöd för att hantera ensamhet?', 'YES_NO_SPECIFY', NULL, NULL, NULL, NULL, 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'RELATIONER_NATVERK'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'RELATION_PRIORITY', 'Prioritering & nöjdhet', 'Bedömning av relationernas kvalitet.', 4
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('satisfaction_network', 'Hur nöjd är du med nätverkets stöd senaste 30 dagarna?', 'SCALE', NULL, 1, 5, '1 = mycket missnöjd, 5 = helt nöjd.', 1),
    ('priority_relationships', 'Vilka relationer vill du utveckla eller reparera?', 'TEXT', NULL, NULL, NULL, NULL, 2),
    ('staff_involvement', 'Behöver personal vara delaktig i nätverksarbete?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja, gärna','Kanske','Nej'), NULL, NULL, NULL, 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);

-- ==== IDENTITET & UTVECKLING ====

with domain as (
    select id from assessment_domains where code = 'IDENTITET_UTVECKLING'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'KASAM', 'KASAM – begriplighet & hanterbarhet', 'Hur klienten förstår livet och klarar utmaningar.', 1
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('understands_events', 'Känner du att du förstår varför saker händer i livet?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja oftast','Ibland','Nej'), NULL, NULL, NULL, 1),
    ('handles_challenges', 'Känner du dig trygg i att hantera svåra situationer?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja','Delvis','Nej'), NULL, NULL, NULL, 2)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'IDENTITET_UTVECKLING'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'VALUES_SELF', 'Värderingar & självuttryck', 'Hur klienten uttrycker åsikter och identitet.', 2
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('express_opinions', 'Kan du uttrycka dina åsikter utan oro för reaktioner?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja','Ibland','Nej'), NULL, NULL, NULL, 1),
    ('safe_to_be_self', 'Känns det tryggt att visa vem du är inför andra?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja','Delvis','Nej'), NULL, NULL, NULL, 2),
    ('identity_concerns', 'Finns det något kring självkänsla eller identitet du oroar dig för?', 'TEXT', NULL, NULL, NULL, NULL, 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'IDENTITET_UTVECKLING'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'CULTURE_SPIRIT', 'Kultur & andlighet', 'Kulturell bakgrund, traditioner och tro.', 3
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('culture_support', 'Ger din kultur eller tradition stöd när det är svårt?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja','Delvis','Nej','Inte aktuellt'), NULL, NULL, NULL, 1),
    ('religion_helpful', 'Är spiritualitet eller religion hjälpsamt för dig?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja ofta','Ibland','Nej'), NULL, NULL, NULL, 2),
    ('needs_identity_support', 'Behöver du hjälp att stärka identitet/kulturkontakt?', 'YES_NO_SPECIFY', NULL, NULL, NULL, NULL, 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'IDENTITET_UTVECKLING'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'MEANING_PRIORITY', 'Mening & prioritering', 'Sätter nivå på oro och behov av stöd.', 4
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('satisfaction_identity', 'Hur nöjd är du med att kunna uttrycka vem du är senaste 30 dagarna?', 'SCALE', NULL, 1, 5, NULL, 1),
    ('hope_future', 'Känner du hopp inför framtiden?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja','Delvis','Nej'), NULL, NULL, NULL, 2),
    ('identity_notes', 'Övriga kommentarer om identitet/utveckling', 'TEXT', NULL, NULL, NULL, NULL, 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);

-- ==== ALKOHOL & DROGER ====

with domain as (
    select id from assessment_domains where code = 'ALKOHOL_DROGER'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'DRINKING_PATTERN', 'Alkoholkonsumtion', 'Mönster och konsekvenser senaste året.', 1
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('drinks_at_all', 'Dricker du alkohol överhuvudtaget?', 'YES_NO', NULL, NULL, NULL, NULL, 1),
    ('intoxication_freq', 'Hur ofta dricker du dig berusad?', 'MULTIPLE_CHOICE', jsonb_build_array('Aldrig','<1 gång/mån','1-3 ggr/mån','1+ ggr/vecka'), NULL, NULL, NULL, 2),
    ('money_on_alcohol', 'Har du lagt pengar på alkohol senaste 30 dagarna?', 'YES_NO', NULL, NULL, NULL, NULL, 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'ALKOHOL_DROGER'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'SUBSTANCE_HISTORY', 'Droghistorik', 'Substanser klienten provat mer än en gång.', 2
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('substances_used', 'Vilka substanser har du använt mer än en gång?', 'MULTI_SELECT', jsonb_build_array('Cannabis','Amfetamin','Kokain','Opioider','Bensodiazepiner','Lösningsmedel','Blandmissbruk','Ingen'), NULL, NULL, 'Markera allt som förekommit historiskt.', 1),
    ('used_last_30d', 'Har du använt någon substans senaste 30 dagarna?', 'YES_NO_SPECIFY', NULL, NULL, NULL, NULL, 2),
    ('spend_on_drugs', 'Har du spenderat pengar på droger senaste 30 dagarna?', 'YES_NO', NULL, NULL, NULL, NULL, 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'ALKOHOL_DROGER'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'TREATMENT_HISTORY', 'Behandling & nykterhet', 'Tidigare försök att bli fri från alkohol/droger.', 3
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('ever_treatment', 'Har du fått behandling för alkohol/droger tidigare?', 'YES_NO_SPECIFY', NULL, NULL, NULL, 'Beskriv typ av behandling och resultat.', 1),
    ('longest_sober', 'Hur länge har du varit nykter/drogfri som längst?', 'TEXT', NULL, NULL, NULL, NULL, 2),
    ('current_program', 'Delar du i någon behandling just nu?', 'YES_NO_SPECIFY', NULL, NULL, NULL, 'Exempel: öppenvård, medicinering, självhjälpsgrupp.', 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'ALKOHOL_DROGER'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'RECOVERY_PLAN', 'Risk & stödplan', 'Motivation, risk för återfall, behov av specialist.', 4
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('motivation_change', 'Hur motiverad är du att vara alkohol- och drogfri?', 'SCALE', NULL, 1, 5, '1 = ingen motivation, 5 = mycket hög.', 1),
    ('relapse_risk', 'Vad triggar eventuell återfallrisk?', 'TEXT', NULL, NULL, NULL, 'Beskriv personer, platser eller känslor.', 2),
    ('need_specialist', 'Behövs specialistinsats (A-CRA/MET/Avgiftning)?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja, akut','Ja, önskvärt','Osäker','Nej'), NULL, NULL, NULL, 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);

-- ==== ANKNYTNING & RELATIONER ====

with domain as (
    select id from assessment_domains where code = 'ANKNYTNING_RELATIONER'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'SOCIAL_ENV', 'Social miljö', 'Vilka personer klienten umgås mest med.', 1
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('spends_time_with', 'Vem spenderar du mest tid med just nu?', 'MULTIPLE_CHOICE', jsonb_build_array('Familj utan missbruk','Familj med missbruk','Vänner utan missbruk','Vänner med missbruk','Mest ensam'), NULL, NULL, NULL, 1),
    ('lives_with_use', 'Bor du med någon som använder alkohol/droger?', 'YES_NO', NULL, NULL, NULL, NULL, 2)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'ANKNYTNING_RELATIONER'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'RELATION_QUALITY', 'Relationernas kvalitet', 'Relationer med familj, partner, vänner.', 2
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('good_relationships', 'Har du goda relationer med (markera alla som stämmer)?', 'MULTI_SELECT', jsonb_build_array('Mamma','Pappa','Syskon','Partner','Eget barn','Vänner','Ingen'), NULL, NULL, 'Senaste 30 dagarna.', 1),
    ('conflict_relationships', 'Med vilka har du haft långvariga konflikter?', 'MULTI_SELECT', jsonb_build_array('Mamma','Pappa','Syskon','Partner','Eget barn','Vänner','Annat'), NULL, NULL, NULL, 2)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'ANKNYTNING_RELATIONER'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'ABUSE_HISTORY', 'Våld och utsatthet', 'Eventuella erfarenheter av våld eller övergrepp.', 3
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('abuse_types', 'Har någon nära utsatt dig för våld eller övergrepp?', 'MULTI_SELECT', jsonb_build_array('Psykiskt','Fysiskt','Sexuellt','Ekonomiskt','Nej'), NULL, NULL, 'Beskriv historik/aktuellt i anteckning.', 1),
    ('current_risk', 'Finns det aktuell risk i någon relation?', 'YES_NO_SPECIFY', NULL, NULL, NULL, NULL, 2)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'ANKNYTNING_RELATIONER'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'ATTACHMENT_PLAN', 'Stöd och prioritering', 'Behov av familjesamtal eller skydd.', 4
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('needs_family_meeting', 'Behöver du stöd med familjesamtal eller nätverksmöte?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja, omgående','Ja, kanske','Nej'), NULL, NULL, NULL, 1),
    ('loneliness_score', 'Hur ensam har du känt dig senaste månaden?', 'SCALE', NULL, 1, 5, '1 = inte alls, 5 = mycket ofta.', 2),
    ('attachment_notes', 'Övriga noteringar för behandlingsplan', 'TEXT', NULL, NULL, NULL, NULL, 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);

-- ==== PSYKISK OHÄLSA ====

with domain as (
    select id from assessment_domains where code = 'PSYKISK_OHALSA'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'MH_TREATMENTS', 'Tidigare behandling', 'Historik av psykiatrisk vård och medicinering.', 1
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('inpatient_history', 'Har du haft slutenvård för psykisk ohälsa?', 'YES_NO_SPECIFY', NULL, NULL, NULL, NULL, 1),
    ('outpatient_history', 'Har du gått i öppenvård eller terapi senaste året?', 'YES_NO_SPECIFY', NULL, NULL, NULL, NULL, 2),
    ('psy_medication', 'Tar du ordinerad psykofarmaka?', 'YES_NO_SPECIFY', NULL, NULL, NULL, 'Ange läkemedel och följsamhet.', 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'PSYKISK_OHALSA'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'MH_SYMPTOMS', 'Symtom senaste 30 dagar', 'Depression, ångest, kognitiva svårigheter, hallucinationer.', 2
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('depression_last30', 'Har du haft allvarlig nedstämdhet senaste 30 dagarna?', 'YES_NO', NULL, NULL, NULL, NULL, 1),
    ('anxiety_last30', 'Har du haft svår ångest eller panik?', 'YES_NO', NULL, NULL, NULL, NULL, 2),
    ('cognitive_difficulties', 'Har du svårt att minnas, koncentrera eller förstå?', 'YES_NO', NULL, NULL, NULL, NULL, 3),
    ('hallucinations', 'Har du upplevt hallucinationer?', 'YES_NO', NULL, NULL, NULL, NULL, 4)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'PSYKISK_OHALSA'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'FUNCTION_IMPACT', 'Funktion & stödbehov', 'Hur symtom påverkar vardagen.', 3
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('functioning_score', 'Hur mycket påverkar psykisk ohälsa din vardag just nu?', 'SCALE', NULL, 1, 5, '1 = påverkar inte, 5 = mycket stor påverkan.', 1),
    ('needs_psych_support', 'Behöver du mer stöd från psykolog/psykiatri?', 'MULTIPLE_CHOICE', jsonb_build_array('Ja, akut','Ja, önskar','Inte nu'), NULL, NULL, NULL, 2),
    ('mh_notes', 'Övriga noteringar kring psykisk hälsa', 'TEXT', NULL, NULL, NULL, NULL, 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);

-- ==== ALLVARLIG PSYKISK OHÄLSA ====

with domain as (
    select id from assessment_domains where code = 'ALLVARLIG_PSYKISK_OHALSA'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'ACUTE_FLAGS', 'Akuta varningsflaggor', 'Suicidtankar, självmordsförsök, självskada.', 1
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('suicidal_thoughts', 'Har du haft suicidtankar senaste 30 dagarna?', 'YES_NO', NULL, NULL, NULL, 'JA kräver omedelbart psykologkontakt enligt regel.', 1),
    ('suicide_attempt', 'Har du gjort självmordsförsök tidigare?', 'YES_NO_SPECIFY', NULL, NULL, NULL, 'Ange datum och metod om möjligt.', 2),
    ('self_harm', 'Har du självskadat dig senaste 30 dagarna?', 'YES_NO', NULL, NULL, NULL, NULL, 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'ALLVARLIG_PSYKISK_OHALSA'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'RISK_MANAGEMENT', 'Riskhantering & stödplan', 'Skyddsplaner och psykologkontakt.', 2
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('has_safety_plan', 'Finns det en aktuell säkerhetsplan?', 'YES_NO_SPECIFY', NULL, NULL, NULL, NULL, 1),
    ('professional_contact', 'Har du regelbunden kontakt med psykiatri/psykolog?', 'YES_NO_SPECIFY', NULL, NULL, NULL, NULL, 2),
    ('emergency_contacts', 'Vem kontaktar du först om kris uppstår?', 'TEXT', NULL, NULL, NULL, NULL, 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);


with domain as (
    select id from assessment_domains where code = 'ALLVARLIG_PSYKISK_OHALSA'
), section_insert as (
    insert into domain_interview_sections (domain_id, section_code, title, description, display_order)
    select id, 'FOLLOWUP_NEEDS', 'Uppföljning & prioritet', 'Bedömning av behov av intensitet.', 3
    from domain returning id
)
insert into domain_interview_questions (section_id, question_key, label, question_type, options, scale_min, scale_max, help_text, display_order)
select section_insert.id, q.question_key, q.label, q.question_type, q.options::jsonb, q.scale_min::integer, q.scale_max::integer, q.help_text::text, q.display_order::integer
from section_insert
cross join (
    values
        ('intensity_need', 'Vilken nivå av psykiatriskt stöd behövs?', 'MULTIPLE_CHOICE', jsonb_build_array('Heldygn','Öppenvård intensiv','Öppenvård normal','Okänt'), NULL, NULL, NULL, 1),
    ('priority_rating', 'Hur akut är behovet på en skala 1–5?', 'SCALE', NULL, 1, 5, NULL, 2),
    ('severe_notes', 'Övriga noteringar (diagnoser, observationer)', 'TEXT', NULL, NULL, NULL, NULL, 3)
) as q(question_key, label, question_type, options, scale_min, scale_max, help_text, display_order);

drop function _delete_domain_interviews(domain_code text);

commit;
