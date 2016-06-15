--***
create procedure [dbo].[selectind] as
select cod_categ,denumire_categ,'2' as nr from categorii
union all 
select '<TOTI>' as cod_categ,'Toti indicatorii','0' as nr
/*union all 
select '','Indicatorii neincadrati','1' as nr*/
order by nr,cod_categ
