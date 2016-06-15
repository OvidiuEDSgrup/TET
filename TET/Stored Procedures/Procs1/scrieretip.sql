--***
create procedure scrieretip @cTip char(1000) 
as
insert into par
(Tip_parametru, Parametru, Denumire_parametru, Val_logica, Val_numerica, Val_alfanumerica)
select 'PC','SITCO'+Item,
(case when left(item,2)='FA' then 'Facturat'
when left(item,2)='PP' then 'Predat'
when left(item,2)='CM' then 'Consumat'
when left(item,2)='MA' then 'Marja'
when left(item,2)='PB' then 'Profit Brut'
when left(item,2)='DP' then 'Diferenta Pret'
when left(item,2)='CO' then 'Cost Efectiv'
when left(item,2)='CA' then 'Cost Marfa'
when left(item,2)='NE' then 'Neterminata'
end)
,1,
(case when left(item,2)='FA' then 5
when left(item,2)='PP' then 2
when left(item,2)='CM' then 7
when left(item,2)='MA' then 8
when left(item,2)='PB' then 6
when left(item,2)='DP' then 4
when left(item,2)='CO' then 1
when left(item,2)='CA' then 9
when left(item,2)='NE' then 3
end),'' from dbo.Split(@cTip, ',') s
where not exists(select * from par p where p.tip_parametru='PC' and p.parametru='SITCO'+Item)

update par set val_logica=0 where tip_parametru='PC' and left(parametru,5)='SITCO'

update par set val_logica=1
from dbo.Split(@cTip, ',') s
where par.tip_parametru='PC' and par.parametru='SITCO'+Item
