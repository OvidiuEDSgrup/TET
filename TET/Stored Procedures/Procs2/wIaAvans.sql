--***
CREATE procedure wIaAvans @sesiune varchar(50), @parXML xml
as  
declare @userASiS varchar(10), @LunaInch int, @AnulInch int, @DataInch datetime, @LunaBloc int, @AnulBloc int, @DataBloc datetime, 
@tip varchar(2), @data datetime, @datajos datetime, @datasus datetime, @DataLJ datetime, @lmantet varchar(9), @f_denlm varchar(50), @f_salariat varchar(50)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
set @LunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
set @AnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
set @DataInch=dbo.Eom(convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4)))

set @LunaBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNABLOC'), 1)
set @AnulBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANULBLOC'), 1901)
set @DataBloc=dbo.Eom(convert(datetime,str(@LunaBloc,2)+'/01/'+str(@AnulBloc,4)))

select @tip=xA.row.value('@tip', 'char(2)'), @data=xA.row.value('@data','datetime'), 
@datajos=dbo.Bom(isnull(xA.row.value('@datajos','datetime'),isnull(xA.row.value('@data','datetime'),'01/01/1901'))), 
@datasus=dbo.Eom(isnull(xA.row.value('@datasus','datetime'),isnull(xA.row.value('@data','datetime'),'12/31/2999'))),
@lmantet=xA.row.value('@lmantet','varchar(9)'), @f_denlm=xA.row.value('@f_denlm','varchar(50)'),
@f_salariat=xA.row.value('@f_salariat','varchar(50)')
from @parXML.nodes('row') as xA(row)  
set @DataLJ=dbo.Bom(@datasus)

exec wScriuIstPers @sesiune, @parXML

select isnull(convert(char(10),a.data,101),convert(char(10),@datasus,101)) as data, 
'AV' as tip, 'A2' as subtip, 'Avans' as densubtip, rtrim(rtrim(max(c.LunaAlfa))+' '+convert(char(4),max(c.An))) as luna, 
rtrim(isnull(i.Loc_de_munca,'')) as lmantet, rtrim(max(isnull(lm.denumire,''))) as denlmantet, count(a.Marca) as nrsal, 
sum(isnull(a.Ore_lucrate_la_avans,0)) as oreavans, sum(convert(decimal(12,2),a.Suma_avans)) as sumaavans, 
sum(convert(decimal(12,2),a.Premiu_la_avans)) as premiuavans, 
(case when a.Data<=@DataInch then '#808080' else '#000000' end) as culoare,
(case when a.Data<=@DataInch or a.Data<=@DataBloc then 1 else 0 end) as _nemodificabil
from Avexcep a
	left outer join istpers i on a.Marca=i.Marca and a.Data=i.Data
	left outer join lm lm on lm.Cod=i.Loc_de_munca
	inner join fCalendar (@datajos, @datasus) c on c.Data=a.Data 
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and i.Loc_de_munca=lu.cod
where a.data between @datajos and @datasus and (@data is null or a.data=@data)
	and (@f_denlm is null or lm.denumire like '%'+@f_denlm+'%')
	and (@lmantet is null or i.Loc_de_munca=@lmantet) 
	and (@f_salariat is null or i.Nume like '%'+@f_salariat+'%' or a.Marca like @f_salariat+'%')
	and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
group by a.data, isnull(i.loc_de_munca,'')
union all
select distinct convert(char(10),i.data,101) as data, 'AV' as tip, 'A2' as subtip, 'Avans' as densubtip,
rtrim(rtrim(max(c.LunaAlfa))+' '+convert(char(4),max(c.An))) as luna, 
isnull(i.loc_de_munca,'') as lmantet, rtrim(max(isnull(lm.denumire,''))) as denlmantet,
0 as nrsal, 0 as oreavans, 0 as sumaavans, 0 as premiuavans, 
(case when i.Data<=@DataInch then '#808080' else '#000000' end) as culoare, 
(case when i.Data<=@DataInch or i.Data<=@DataBloc then 1 else 0 end) as _nemodificabil
from istpers as i
	left outer join lm on i.loc_de_munca=lm.cod
	inner join fCalendar (@datasus, @datasus) c on c.Data=i.Data 
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and i.Loc_de_munca=lu.cod
where i.data=@datasus and (@data is null or i.data=@data) and 
	not exists (select loc_de_munca from istpers i1 where i1.Data=@datasus 
		and exists (select a.marca from avexcep a where a.data=@datasus and a.Marca=i1.Marca
			and (@f_salariat is null or i1.Nume like '%'+@f_salariat+'%' or a.Marca like @f_salariat+'%')) and i1.Loc_de_munca=i.Loc_de_munca)
	and (@f_denlm is null or lm.denumire like '%'+@f_denlm+'%')
	and (@lmantet is null or i.Loc_de_munca=@lmantet) 
	and (@f_salariat is null or i.Nume like '%'+@f_salariat+'%' or i.Marca like @f_salariat+'%')
	and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
group by i.data, isnull(i.loc_de_munca,'')
order by data, sumaavans desc, lmantet
for xml raw
