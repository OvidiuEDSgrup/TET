--***
CREATE procedure wAmRefTerti @sesiune varchar(50),@tert varchar(20)
as      
select      
(case when exists (select 1 from pozdoc p where p.tert=@tert) then 'Tertul are documente!'
 when exists (select 1 from pozadoc p where p.tert=@tert) then 'Tertul are (alte) documente!'
 when exists (select 1 from pozncon p where p.tert=@tert) then 'Tertul are note contabile!'
 when exists (select 1 from pozplin p where p.tert=@tert) then 'Tertul are plati!'
 else '' end) as mesaj    
FOR XML RAW
