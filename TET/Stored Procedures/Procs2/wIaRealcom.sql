--***
CREATE procedure wIaRealcom @sesiune varchar(50), @parXML xml
as  
declare @TesaAcordInd int, @TesaAcordGlobal int, @userASiS varchar(10), 
@LunaInch int, @AnulInch int, @DataInch datetime, 
@LunaBloc int, @AnulBloc int, @DataBloc datetime, 
@lista_lm int, @tip varchar(2), @data datetime, @datajos datetime, @datasus datetime, @DataLJ datetime,
@marca varchar(6), @lmantet varchar(9), @f_densalariat varchar(50), @f_denlm varchar(50)

set @TesaAcordGlobal=dbo.iauParL('PS','ACGLOTESA')
set @TesaAcordInd=dbo.iauParL('PS','ACINDTESA')
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

set @LunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
set @AnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
set @DataInch=dbo.Eom(convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4)))

set @LunaBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNABLOC'), 1)
set @AnulBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANULBLOC'), 1901)
set @DataBloc=dbo.Eom(convert(datetime,str(@LunaBloc,2)+'/01/'+str(@AnulBloc,4)))

select @lista_lm=dbo.f_arelmfiltru(@userASiS)

select @tip=xA.row.value('@tip', 'char(2)'), @data=xA.row.value('@data','datetime'), 
@datajos=dbo.Bom(isnull(xA.row.value('@datajos','datetime'),isnull(xA.row.value('@data','datetime'),'01/01/1901'))), 
@datasus=dbo.Eom(isnull(xA.row.value('@datasus','datetime'),isnull(xA.row.value('@data','datetime'),'12/31/2999'))),
@marca=xA.row.value('@marca','varchar(6)'), @lmantet=xA.row.value('@lmantet','varchar(9)'), 
@f_densalariat=xA.row.value('@f_densalariat','varchar(50)'), @f_denlm=xA.row.value('@f_denlm','varchar(50)')
from @parXML.nodes('row') as xA(row)  
set @DataLJ=dbo.Bom(@datasus)

if @datasus>@DataInch and isnull((select count(1) from istpers where Data=@datasus),0)<>
isnull((select count(1) from personal where (loc_ramas_vacant=0 or data_plec>=@DataLJ) and Data_angajarii_in_unitate<=@datasus),0)
	exec scriuistPers @DataLJ, @datasus, '', '', 1, 1

select isnull(convert(char(10),dbo.eom(r.data),101),convert(char(10),@datasus,101)) as data, 
@tip as tip, @tip as subtip, (case when @tip='AG' then 'Acord individual' else 'Acord global' end) as densubtip, 
rtrim(rtrim(max(c.LunaAlfa))+' '+convert(char(4),max(c.An))) as luna, 
rtrim(isnull(r.marca,'')) as marca, rtrim(isnull(max(p.Nume),'')) as densalariat, 
rtrim(isnull(r.Loc_de_munca,'')) as lmantet, rtrim(max(isnull(lm.denumire,''))) as denlmantet, count(distinct r.Comanda) as nrcom, 
sum(isnull(convert(decimal(10,3),r.Cantitate),0)) as cantitate, sum(convert(decimal(12,3),r.Cantitate*r.Tarif_unitar)) as valoare, 
(case when dbo.Eom(r.data)<=@DataInch then '#808080' else '#000000' end) as culoare,
(case when dbo.Eom(r.data)<=@DataInch or dbo.Eom(r.data)<=@DataBloc then 1 else 0 end) as _nemodificabil
from Realcom r
	left outer join personal p on r.Marca=p.Marca
	left outer join lm lm on lm.Cod=r.Loc_de_munca
	inner join fCalendar (@datajos, @datasus) c on c.Data=r.Data 
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and p.Loc_de_munca=lu.cod
where r.data between @datajos and @datasus and (@data is null or dbo.eom(r.data)=@data) 
	and (@tip='AI' and r.marca<>'' or @tip='AG' and r.marca='')
	and (@marca is null or r.Marca=@marca) 
	and (@lmantet is null or r.Loc_de_munca=@lmantet) 
	and (@f_densalariat is null or p.Nume like '%'+@f_densalariat+'%')
	and (@f_denlm is null or lm.denumire like '%'+@f_denlm+'%')
	and (@lista_lm=0 or lu.cod is not null)
group by dbo.Eom(r.data), r.Marca, isnull(r.loc_de_munca,'')
union all
select distinct convert(char(10),@datasus,101) as data, 'AI', 'AI' as subtip, 'Acord inidividual' as densubtip, 
rtrim(rtrim(max(c.LunaAlfa))+' '+convert(char(4),max(c.An))) as luna, rtrim(isnull(p.marca,'')) as marca, rtrim(isnull(max(p.Nume),'')) as densalariat, 
isnull(p.loc_de_munca,'') as lmantet, rtrim(max(isnull(lm.denumire,''))) as denlmantet,
0 as nrcom, 0 as cantitate, 0 as valoare, 
(case when @datasus<=@DataInch then '#808080' else '#000000' end) as culoare, 
(case when @datasus<=@DataInch or @datasus<=@DataBloc then 1 else 0 end) as _nemodificabil
from personal as p
	left outer join lm on p.loc_de_munca=lm.cod
	inner join fCalendar (@datasus, @datasus) c on c.Data=@datasus 
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and p.Loc_de_munca=lu.cod
where @tip='AI' and (p.Tip_salarizare in ('4') or @TesaAcordInd=1 and p.Tip_salarizare='2')
	and (loc_ramas_vacant=0 or data_plec>=@DataLJ) and Data_angajarii_in_unitate<=@datasus
	and p.Marca not in (select r.Marca from realcom r where r.Data between @DataLJ and @datasus and r.Marca<>'')
	and (@f_denlm is null or lm.denumire like '%'+@f_denlm+'%')
	and (@f_densalariat is null or p.Nume like '%'+@f_densalariat+'%')
	and (@lmantet is null or p.Loc_de_munca=@lmantet) 
	and (@lista_lm=0 or lu.cod is not null)
group by data, p.marca, isnull(p.loc_de_munca,'')
union all
select distinct convert(char(10),@datasus,101) as data, 'AG', 'AG' as subtip, 'Acord global' as densubtip, 
rtrim(rtrim(max(c.LunaAlfa))+' '+convert(char(4),max(c.An))) as luna, '' as marca, '' as densalariat, 
isnull(p.loc_de_munca,'') as lmantet, rtrim(max(isnull(lm.denumire,''))) as denlmantet,
0 as nrcom, 0 as cantitate, 0 as valoare, 
(case when @datasus<=@DataInch then '#808080' else '#000000' end) as culoare, 
(case when @datasus<=@DataInch or @datasus<=@DataBloc then 1 else 0 end) as _nemodificabil
from personal as p
	left outer join lm on p.loc_de_munca=lm.cod
	inner join fCalendar (@datasus, @datasus) c on c.Data=@datasus 
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and p.Loc_de_munca=lu.cod
where @TIP='AG' and (p.Tip_salarizare in ('5','7') or @TesaAcordGlobal=1 and p.Tip_salarizare='2')
	and (loc_ramas_vacant=0 or data_plec>=@DataLJ) and Data_angajarii_in_unitate<=@datasus
	and p.Loc_de_munca not in (select r.loc_de_munca from realcom r where r.Data between @DataLJ and @datasus and r.Marca='')
	and (@f_denlm is null or lm.denumire like '%'+@f_denlm+'%')
	and (@lmantet is null or p.Loc_de_munca=@lmantet) 
	and (@lista_lm=0 or lu.cod is not null)
group by data, isnull(p.loc_de_munca,'')
order by data, valoare desc, lmantet
for xml raw
