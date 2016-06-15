--***
Create procedure wIaConcediiOdihna @sesiune varchar(50), @parXML xml
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

/*	Nu mai apelam aici procedura de scriere in istpers. Am apelat scrierea in istpers la adaugarea concediilor de odihna pe marca. 
	Am tratat astfel pentru a nu modifica datele din istpers daca se deschid luni inchise.
exec wScriuIstPers @sesiune, @parXML
*/

select @tip as tip, '' as subtip, 'Concedii de odihna' as densubtip, convert(char(10),co.data,101) as data, 
rtrim(rtrim(max(c.LunaAlfa))+' '+convert(char(4),max(c.An))) as luna, 
'' as grupdoc, 'Concedii de odihna' as denumire,
count(distinct co.marca) as nrsal, sum(co.Zile_CO) as cantitate, sum(convert(decimal(12,2),Indemnizatie_CO)) as valoare,
(case when co.Data<=@DataInch then '#808080' else '#000000' end) as culoare,
(case when co.Data<=@DataInch or co.Data<=@DataBloc then 1 else 0 end) as _nemodificabil
from concodih as co
	left outer join istpers i on co.Data=i.Data and co.Marca=i.Marca
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and i.Loc_de_munca=lu.cod
	inner join fCalendar (@datajos, @datasus) c on c.Data=co.Data 
where @tip='OD'
	and co.data between @datajos and @datasus and (@data is null or co.data=@data) and co.tip_concediu not in ('9','C','P','V')
	and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
group by co.data
union all
select @tip as tip, '' as subtip, 'Concedii de odihna' as densubtip, convert(char(10),@datasus,101) as data, 
rtrim(rtrim(LunaAlfa)+' '+convert(char(4),An)) as luna, 
'' as grupdoc, 'Concedii de odihna' as denumire,
0 as nrsal, 0 as cantitate, 0 as valoare,
(case when @datasus<=@DataInch then '#808080' else '#000000' end) as culoare,
(case when @datasus<=@DataInch or @datasus<=@DataBloc then 1 else 0 end) as _nemodificabil
from dbo.fCalendar(@datasus,@datasus)
where isnull((select count(1) from concodih co 
	left outer join personal p on co.Marca=p.Marca
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and p.Loc_de_munca=lu.cod
	where co.data=@datasus and co.tip_concediu not in ('9','C','P','V')
	and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)),0)=0
for xml raw
