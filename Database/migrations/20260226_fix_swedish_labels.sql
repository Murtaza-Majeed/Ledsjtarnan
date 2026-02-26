-- Fix mixed Swedish/English labels in database schema
-- Convert Swedish labels to English for consistency
-- Date: 2026-02-26

begin;

-- Update domain score slots to use English labels consistently
update domain_score_slots
set
    label = case
        when label = 'Ungdomens skattning' then 'Client rating'
        when label = 'Behandlarens bedömning' then 'Staff assessment'
        when label = 'Motivation' and description like '%Receptivitet%' then 'Motivation'
        when label = 'Prioritet' then 'Priority'
        else label
    end,
    description = case
        when description = 'Hur den unge skattar problemnivån' then 'Client-reported problem level'
        when description = 'Personalens samlade bedömning' then 'Staff clinical assessment'
        when description = 'Receptivitet/motivation' then 'Receptivity/motivation for intervention'
        when description = 'Hur viktigt området är i planen' then 'Priority for treatment planning'
        else description
    end
where label in ('Ungdomens skattning', 'Behandlarens bedömning', 'Prioritet')
   or description like '%unge%'
   or description like '%Receptivitet%'
   or description like '%planen%';

commit;
