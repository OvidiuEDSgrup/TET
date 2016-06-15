--***
create procedure DepanareNecorelatiiTLI @datajos datetime, @datasus datetime
as
begin
set transaction isolation level read uncommitted

select * from #jurnalTLI
/*select distinct tert,factura,sum(TVA_deductibil) as tva
into #tlidin4428
from pozdoc p1 
where p1.subunitate=1 and p1.tip in ('RM','RS') and p1.data between '02/01/2013' and '02/28/2013' and Cont_venituri='4428.fi'
group by tert,factura*/

/*
declare @ct418 varchar(20),@dataJos datetime,@dataSus datetime,@ct4428TLI varchar(20),@ct4428AV varchar(20)
select @dataJos='02/01/2013',@dataSus='02/28/2013'

select top 1 @ct418=val_alfanumerica from par where tip_parametru='GE' and parametru='CTCLAVRT'
select top 1 @ct4428TLI=val_alfanumerica from par where tip_parametru='GE' and parametru='CNTLIFURN'
select top 1 @ct418=val_alfanumerica from par where tip_parametru='GE' and parametru='CTCLAVRT'
select top 1 @ct4428AV=val_alfanumerica from par where tip_parametru='GE' and parametru='CNEEXREC'

-- cont TLI la avize 418 -> se pune cont avans
update pozdoc set Grupa=@ct4428AV
	where subunitate='1' and tip='ap' and cont_factura=@ct418 and grupa=@ct4428TLI and 
	data between @dataJos and @dataSus
	and grupa!=@ct4428AV

-- cont TLI la receptii facturi fara TLI
--drop table #tlidin4428
select * from ##j2
select distinct tert,factura,sum(TVA_deductibil) as tva
into #tlidin4428
from pozdoc p1 
where p1.subunitate=1 and p1.tip in ('RM','RS') and p1.data between '02/01/2013' and '02/28/2013' and Cont_venituri='4428.fi'
group by tert,factura

select t1.tva,##j2.rulajdebitTLI,*
from #tlidin4428 t1
left outer join ##j2 on t1.tert=##j2.tert and t1.Factura=##j2.factura
where ##j2.factura is null or
	abs(##j2.rulajdebitTLI-t1.tva)>0.01

*/


end
