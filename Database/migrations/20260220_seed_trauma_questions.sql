-- Seed trauma question catalog for STRESS (Q1–52)
-- Generated 2026-02-20

begin;

truncate table trauma_questions;

insert into trauma_questions (code, question_number, label, question_type, group_code, scale_min, scale_max, help_text) values
    -- Q1–21: 21 yes/no trauma events (with timing options)
    ('q1', 1, 'Naturlig katastrof (tsunami, jordbävning, etc.)', 'BOOLEAN', 'EVENTS', null, null, 'NEJ / JA senaste år / JA >1 år / JA som barn (ange ålder).'),
    ('q2', 2, 'Befunnit dig i krig eller krigszon', 'BOOLEAN', 'EVENTS', null, null, 'NEJ / JA senaste år / JA >1 år / JA som barn (ålder).'),
    ('q3', 3, 'Familjemedlem/partner i krig eller krigszon', 'BOOLEAN', 'EVENTS', null, null, 'NEJ / JA senaste år / JA >1 år / JA som barn (ålder).'),
    ('q4', 4, 'Allvarlig brand eller förlorat hem i brand', 'BOOLEAN', 'EVENTS', null, null, 'NEJ / JA senaste år / JA >1 år / JA som barn (ålder).'),
    ('q5', 5, 'Allvarlig olycka', 'BOOLEAN', 'EVENTS', null, null, 'NEJ / JA senaste år / JA >1 år / JA som barn (ålder).'),
    ('q6', 6, 'Sjukhusvård för allvarlig sjukdom eller skada', 'BOOLEAN', 'EVENTS', null, null, 'NEJ / JA senaste år / JA >1 år / JA som barn (ålder).'),
    ('q7', 7, 'Förlorat nära anhörig, barn eller partner genom dödsfall', 'BOOLEAN', 'EVENTS', null, null, 'NEJ / JA senaste år / JA >1 år / JA som barn (ålder).'),
    ('q8', 8, 'Bevittnat när andra skadats svårt eller dödats', 'BOOLEAN', 'EVENTS', null, null, 'NEJ / JA senaste år / JA >1 år / JA som barn (ålder).'),
    ('q9', 9, 'Fysisk misshandel av icke-familjemedlem', 'BOOLEAN', 'EVENTS', null, null, 'NEJ / JA senaste år / JA >1 år / JA som barn (ålder).'),
    ('q10', 10, 'Icke-familj hotat att skada/döda någon du bryr dig om', 'BOOLEAN', 'EVENTS', null, null, 'NEJ / JA senaste år / JA >1 år / JA som barn (ålder).'),
    ('q11', 11, 'Icke-familj tvingade dig till sexuella handlingar/tjänster', 'BOOLEAN', 'EVENTS', null, null, 'NEJ / JA senaste år / JA >1 år / JA som barn (ålder).'),
    ('q12', 12, 'Familj/partner utsatt dig för fysisk misshandel', 'BOOLEAN', 'EVENTS', null, null, 'NEJ / JA senaste år / JA >1 år / JA som barn (ålder).'),
    ('q13', 13, 'Familj/partner hotat att skada/döda dig', 'BOOLEAN', 'EVENTS', null, null, 'NEJ / JA senaste år / JA >1 år / JA som barn (ålder).'),
    ('q14', 14, 'Familj/partner hotat att skada någon du bryr dig om', 'BOOLEAN', 'EVENTS', null, null, 'NEJ / JA senaste år / JA >1 år / JA som barn (ålder).'),
    ('q15', 15, 'Familj/partner tvingade dig till sexuella handlingar/tjänster', 'BOOLEAN', 'EVENTS', null, null, 'NEJ / JA senaste år / JA >1 år / JA som barn (ålder).'),
    ('q16', 16, 'Känner detaljer om hur en nära person dog (kan visualisera)', 'BOOLEAN', 'EVENTS', null, null, 'NEJ / JA senaste år / JA >1 år / JA som barn (ålder).'),
    ('q17', 17, 'Annat trauma (fängelse, separation, hemlöshet m.m.)', 'BOOLEAN', 'EVENTS', null, null, 'NEJ / JA senaste år / JA >1 år / JA som barn (ålder).'),
    ('q18', 18, '*Barn sjukhusvårdats för allvarlig sjukdom/skada', 'BOOLEAN', 'EVENTS_PARENT', null, null, 'Endast om klienten är förälder. NEJ / JA senaste år / JA >1 år / JA som barn.'),
    ('q19', 19, '*Barn diagnostiserats med livshotande sjukdom', 'BOOLEAN', 'EVENTS_PARENT', null, null, 'Endast om klienten är förälder. NEJ / JA senaste år / JA >1 år / JA som barn.'),
    ('q20', 20, '*Förlorat ett barn genom dödsfall', 'BOOLEAN', 'EVENTS_PARENT', null, null, 'Endast om klienten är förälder. NEJ / JA senaste år / JA >1 år / JA som barn.'),
    ('q21', 21, '*Barn utsatts för våld eller sexuella övergrepp', 'BOOLEAN', 'EVENTS_PARENT', null, null, 'Endast om klienten är förälder. NEJ / JA senaste år / JA >1 år / JA som barn.'),

    -- Aggregated event flags
    ('adultEventsMultiple', null, 'Flera traumatiska händelser som vuxen?', 'BOOLEAN', 'EVENTS_ADULT', null, null, 'Markeras när klienten anger två eller fler händelser i vuxenlivet.'),
    ('childEventsMultiple', null, 'Flera traumatiska händelser som barn/ungdom?', 'BOOLEAN', 'EVENTS_CHILD', null, null, 'Markeras när klienten anger två eller fler händelser före 18 års ålder.'),

    -- STRESS symptom items (0 = aldrig, 3 = de flesta dagarna)
    ('q22', 22, 'Q22: Ofrivilliga minnesbilder', 'SCALE', 'SYMPTOMS_B', 0, 3, 'Återkommande, påträngande minnesbilder eller flashbacks.'),
    ('q23', 23, 'Q23: Mardrömmar', 'SCALE', 'SYMPTOMS_B', 0, 3, 'Återkommande drömmar kopplade till traumat.'),
    ('q24', 24, 'Q24: Flashbacks', 'SCALE', 'SYMPTOMS_B', 0, 3, 'Korta stunder då det känns som att händelsen sker igen.'),
    ('q25', 25, 'Q25: Psykisk stress vid påminnelser', 'SCALE', 'SYMPTOMS_B', 0, 3, 'Stark psykisk reaktion vid externa/interna triggers.'),
    ('q26', 26, 'Q26: Fysiologisk reaktion vid påminnelser', 'SCALE', 'SYMPTOMS_B', 0, 3, 'Hjärtslag, svettning, darrning när du påminns.'),
    ('q27', 27, 'Q27: Undvikande av tankar/minnen', 'SCALE', 'SYMPTOMS_C', 0, 3, 'Försöker aktivt att inte tänka på händelsen.'),
    ('q28', 28, 'Q28: Undvikande av platser/personer', 'SCALE', 'SYMPTOMS_C', 0, 3, 'Undviker situationer som påminner om traumat.'),
    ('q29', 29, 'Q29: Luckor i minnet kring händelsen', 'SCALE', 'SYMPTOMS_D', 0, 3, 'Svårt att minnas viktiga delar av traumat.'),
    ('q30', 30, 'Q30: Negativa övertygelser om dig själv', 'SCALE', 'SYMPTOMS_D', 0, 3, '”Jag är förstörd”, ”jag kan inte lita på någon”.'),
    ('q31', 31, 'Q31: Förvrängd skuldkänsla/skuld', 'SCALE', 'SYMPTOMS_D', 0, 3, 'Lägger skulden på dig själv eller andra.'),
    ('q32', 32, 'Q32: Ihållande negativa känslor', 'SCALE', 'SYMPTOMS_D', 0, 3, 'Rädsla, skräck, vrede, skuld eller skam.'),
    ('q33', 33, 'Q33: Minskad förmåga att känna glädje', 'SCALE', 'SYMPTOMS_D', 0, 3, 'Svårt att känna positiva känslor.'),
    ('q34', 34, 'Q34: Känsla av främlingskap', 'SCALE', 'SYMPTOMS_D', 0, 3, 'Känner dig bortkopplad från andra eller världen.'),
    ('q35', 35, 'Q35: Intresseförlust', 'SCALE', 'SYMPTOMS_D', 0, 3, 'Tappar intresse för aktiviteter du tidigare uppskattade.'),
    ('q36', 36, 'Q36: Självförakt', 'SCALE', 'SYMPTOMS_D', 0, 3, 'Negativ självbild, självhat.'),
    ('q37', 37, 'Q37: Irritation och vredesutbrott', 'SCALE', 'SYMPTOMS_E', 0, 3, 'Oförutsedda vredesutbrott eller irritabilitet.'),
    ('q38', 38, 'Q38: Riskfyllt eller destruktivt beteende', 'SCALE', 'SYMPTOMS_E', 0, 3, 'Självdestruktiva handlingar, riskbeteenden.'),
    ('q39', 39, 'Q39: Hypervigilans', 'SCALE', 'SYMPTOMS_E', 0, 3, 'Ständig vaksamhet, svårt att slappna av.'),
    ('q40', 40, 'Q40: Överdriven startle-reaktion', 'SCALE', 'SYMPTOMS_E', 0, 3, 'Rycker lätt till av ljud och rörelser.'),
    ('q41', 41, 'Q41: Koncentrationssvårigheter', 'SCALE', 'SYMPTOMS_E', 0, 3, 'Svårt att hålla fokus på uppgifter.'),
    ('q42', 42, 'Q42: Sömnsvårigheter', 'SCALE', 'SYMPTOMS_E', 0, 3, 'Problem att somna eller sova hela natten.'),
    ('q43', 43, 'Q43: Återkommande kroppsliga stressreaktioner', 'SCALE', 'SYMPTOMS_E', 0, 3, 'Hög puls, muskelspänning, illamående.'),
    ('q44', 44, 'Q44: Känsla av att framtiden är begränsad', 'SCALE', 'SYMPTOMS_D', 0, 3, 'Svårt att känna hopp eller planera framtiden.'),
    ('q45', 45, 'Q45: Overklighetskänslor (DS1)', 'SCALE', 'SYMPTOMS_D', 0, 3, 'Upplevelse av att världen inte känns verklig.'),
    ('q46', 46, 'Q46: Avskildhet från kroppen (DS2)', 'SCALE', 'SYMPTOMS_D', 0, 3, 'Känsla av att lämna kroppen / se sig själv utifrån.'),

    -- Funktionsnedsättning Q47–52 (Ja/Nej)
    ('q47', 47, 'Funktionspåverkan: Skola/arbete', 'BOOLEAN', 'FUNCTION', null, null, 'Påverkar symtomen din förmåga att klara skola eller arbete?'),
    ('q48', 48, 'Funktionspåverkan: Relationer/familj', 'BOOLEAN', 'FUNCTION', null, null, 'Påverkar symtomen relationer med familj eller närstående?'),
    ('q49', 49, 'Funktionspåverkan: Vänner/socialt', 'BOOLEAN', 'FUNCTION', null, null, 'Påverkar symtomen ditt sociala liv eller vänskapsrelationer?'),
    ('q50', 50, 'Funktionspåverkan: Fritid/hobby', 'BOOLEAN', 'FUNCTION', null, null, 'Gör symtomen att du undviker fritidsaktiviteter/hobby?'),
    ('q51', 51, 'Funktionspåverkan: Självomsorg', 'BOOLEAN', 'FUNCTION', null, null, 'Försvårar symtomen vardaglig omvårdnad (mat, sömn, hygien)?'),
    ('q52', 52, 'Funktionspåverkan: Annat viktigt område', 'BOOLEAN', 'FUNCTION', null, null, 'Finns andra områden som påverkas påtagligt av symtomen?');

commit;
