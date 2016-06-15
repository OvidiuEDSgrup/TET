﻿--***
Create procedure wIaConcediiAlte @sesiune varchar(50), @parXML xml
as  
declare @userASiS varchar(10), @LunaInch int, @AnulInch int, @DataInch datetime, 
@LunaBloc int, @AnulBloc int, @DataBloc datetime, 
@tip varchar(2), @subtip varchar(2), @data datetime, @datajos datetime, @datasus datetime, @DataLJ datetime

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
set @LunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
set @AnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
set @DataInch=dbo.Eom(convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4)))

set @LunaBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNABLOC'), 1)
set @AnulBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANULBLOC'), 1901)
set @DataBloc=dbo.Eom(convert(datetime,str(@LunaBloc,2)+'/01/'+str(@AnulBloc,4)))

select @data=xA.row.value('@data', 'datetime'), @tip=xA.row.value('@tip', 'varchar(2)'), @subtip=xA.row.value('@subtip', 'varchar(2)'), 
@datajos=dbo.Bom(isnull(xA.row.value('@datajos','datetime'),isnull(xA.row.value('@data','datetime'),'01/01/1901'))), 
@datasus=dbo.Eom(isnull(xA.row.value('@datasus','datetime'),isnull(xA.row.value('@data','datetime'),'12/31/2999'))) 
from @parXML.nodes('row') as xA(row) 
set @DataLJ=dbo.Bom(@datasus)

/*	Nu mai apelam aici procedura de scriere in istpers. Am apelat scrierea in istpers la adaugarea concediilor\alte pe marca. 
	Am tratat astfel pentru a nu modifica datele din istpers daca se deschid luni inchise.
exec wScriuIstPers @sesiune, @parXML
*/

select @tip as tip, '' as subtip, 'Concedii\alte' as densubtip, convert(char(10),ca.data,101) as data, 
rtrim(rtrim(max(c.LunaAlfa))+' '+convert(char(4),max(c.An))) as luna, 'Concedii\alte' as denumire,
count(distinct ca.marca) as nrsal, sum(ca.Zile) as cantitate, 0 as valoare, sum(ca.Zile) as zile, 
sum((case when ca.tip_concediu='1' then ca.Zile else 0 end)) as zilecfs, 
sum((case when ca.tip_concediu='2' then ca.Zile else 0 end)) as zilenemotivate, 
sum((case when ca.tip_concediu='2' then convert(decimal(5),ca.Indemnizatie) else 0 end)) as orenemotivate, 
sum((case when ca.tip_concediu='4' then ca.Zile else 0 end)) as ziledelegatie, 
sum((case when ca.tip_concediu='5' then ca.Zile else 0 end)) as zileproba, 
sum((case when ca.tip_concediu='6' then ca.Zile else 0 end)) as zilepreaviz, 
(case when ca.Data<=@DataInch then '#808080' else '#000000' end) as culoare,
(case when ca.Data<=@DataInch or ca.Data<=@DataBloc then 1 else 0 end) as _nemodificabil
from conalte as ca
	left outer join istpers i on ca.Data=i.Data and ca.Marca=i.Marca
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and i.Loc_de_munca=lu.cod
	inner join fCalendar (@datajos, @datasus) c on c.Data=ca.Data 
where @tip='CA'
	and ca.data between @datajos and @datasus and (@data is null or ca.data=@data)
	and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
group by ca.data
union all
select @tip as tip, '' as subtip, 'Concedii\alte' as densubtip, convert(char(10),@datasus,101) as data, 
rtrim(rtrim(LunaAlfa)+' '+convert(char(4),An)) as luna, 'Concedii\alte' as denumire,
0 as nrsal, 0 as cantitate, 0 as valoare, 0 as zile,
0 as zilecfs, 0 as zilenemotivate, 0 as orenemotivate, 0 as ziledelegatie, 0 as zileproba, 0 as zilepreaviz, 
(case when @datasus<=@DataInch then '#808080' else '#000000' end) as culoare,
(case when @datasus<=@DataInch or @datasus<=@DataBloc then 1 else 0 end) as _nemodificabil
from dbo.fCalendar(@datasus,@datasus)
where isnull((select count(1) from conalte ca 
	left outer join personal p on ca.Marca=p.Marca
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and p.Loc_de_munca=lu.cod
	where ca.data=@datasus and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)),0)=0
for xml raw
