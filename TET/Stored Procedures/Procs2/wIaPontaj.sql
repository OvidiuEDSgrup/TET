--***
CREATE procedure wIaPontaj @sesiune varchar(50), @parXML xml
as  
set transaction isolation level READ UNCOMMITTED
declare @userASiS varchar(10), @LunaInch int, @AnulInch int, @DataInch datetime, @LunaBloc int, @AnulBloc int, @DataBloc datetime, 
@tip varchar(2), @data datetime, @datajos datetime, @datasus datetime, @lmantet varchar(9), @f_lm varchar(9), @f_denlm varchar(50), 
@f_salariat varchar(50), @DataLJ datetime

select @tip=xA.row.value('@tip', 'char(2)'), @data=xA.row.value('@data','datetime'), 
@datajos=dbo.Bom(isnull(xA.row.value('@datajos','datetime'),isnull(xA.row.value('@data','datetime'),'01/01/1901'))), 
@datasus=dbo.Eom(isnull(xA.row.value('@datasus','datetime'),isnull(xA.row.value('@data','datetime'),'12/31/2999'))),
@lmantet=xA.row.value('@lmantet','varchar(9)'), @f_lm=xA.row.value('@f_lm','varchar(9)'), 
@f_denlm=xA.row.value('@f_denlm','varchar(50)'), @f_salariat=xA.row.value('@f_salariat','varchar(50)')
from @parXML.nodes('row') as xA(row)  

if @tip!='MN' -- asa era macheta inainte de DRDP
begin
	set @LunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @AnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	set @LunaBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNABLOC'), 1)
	set @AnulBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANULBLOC'), 1901)
end
else -- daca vin dinspre meniul "Realizari manopera" sa ma refer la date de PC
begin
	set @LunaInch=isnull((select max(val_numerica) from par where tip_parametru='PC' and parametru='LUNAINC'), 1)
	set @AnulInch=isnull((select max(val_numerica) from par where tip_parametru='PC' and parametru='ANULINC'), 1901)
	set @LunaBloc=@LunaInch
	set @AnulBloc=@AnulInch
	set @tip='PO'
end

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
set @DataInch=dbo.Eom(convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4)))
set @DataBloc=dbo.Eom(convert(datetime,str(@LunaBloc,2)+'/01/'+str(@AnulBloc,4)))

set @DataLJ=dbo.Bom(@datasus)
/*	Nu mai apelam aici procedura de scriere in istpers. Am apelat scrierea in istpers la adaugarea pontajului pe marca. 
	Am tratat astfel pentru a nu modifica datele din istpers daca se deschid luni inchise.
exec wScriuIstPers @sesiune, @parXML
*/

if object_id('tempdb..#wiapontaj') is not null drop table #wiapontaj

select @tip as tip, convert(varchar(2),'') as subtip, convert(varchar(100),'') as densubtip, convert(char(10),dbo.eom(p.data),101) as data, 
rtrim(rtrim(max(c.LunaAlfa))+' '+convert(char(4),max(c.An))) as luna, 
isnull(i.loc_de_munca,'') as lmantet, rtrim(max(isnull(lm.denumire,''))) as denlmantet,
count(distinct p.marca) as nrsal, isnull((select count(distinct i1.marca) from istpers i1 where i1.data=dbo.eom(p.data) 
	and i1.loc_de_munca=isnull(i.loc_de_munca,'') and i1.tip_salarizare in ('1','3','6')),0) as nrsalregie, 
isnull((select count(distinct i2.marca) from istpers i2 where i2.data=dbo.eom(p.data) 
	and i2.loc_de_munca=isnull(i.loc_de_munca,'') and i2.tip_salarizare in ('2','4','5','7')),0) as nrsalacord, 
Null as cantitate, Null as valoare, sum(p.Ore_regie+p.Ore_acord) as orelucrate, 
sum(p.Ore_suplimentare_1+p.Ore_suplimentare_2+Ore_suplimentare_3+Ore_suplimentare_4) as oresupl, 
sum(Ore_de_noapte) as orenoapte, sum(Ore_concediu_de_odihna) as oreco, sum(Ore_concediu_medical) as orecm, 
sum(Ore_invoiri) as oreinvoiri, sum(Ore_nemotivate) as orenemotivate, sum(Ore_concediu_fara_salar) as orecfs, 
sum(Ore_intrerupere_tehnologica) as oreit1, sum(Ore) as oreit2, sum(Ore_obligatii_cetatenesti) as oreobligatii, 
sum(Ore_concediu_de_odihna+Ore_concediu_medical+Ore_invoiri+Ore_nemotivate+Ore_concediu_fara_salar+Ore_intrerupere_tehnologica+Ore+Ore_obligatii_cetatenesti) as orenelucrate, 
sum(p.Ore__cond_6) as nrtichete, 
(case when dbo.eom(p.data)<=@DataInch then '#808080' else '#000000' end) as culoare,
(case when dbo.eom(p.data)<=@DataInch or dbo.eom(p.data)<=@DataBloc then 1 else 0 end) as _nemodificabil
into #wiapontaj
from pontaj as p
	left outer join istpers i on i.data=dbo.eom(p.data) and p.marca=i.marca
	left outer join lm on i.loc_de_munca=lm.cod
	inner join fCalendar (@datajos, @datasus) c on c.Data=dbo.eom(p.data)
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and i.loc_de_munca=lu.cod
where @tip='PO' and (@lmantet is null or i.loc_de_munca=@lmantet)
	and p.data between @datajos and @datasus and (@data is null or p.data=@data)
	and (@f_denlm is null or lm.denumire like '%'+@f_denlm+'%')
	and (@f_lm is null or i.Loc_de_munca like @f_lm+'%')
	and (@f_salariat is null or i.Nume like '%'+@f_salariat+'%' or p.Marca like @f_salariat+'%')
	and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
group by dbo.eom(p.data), isnull(i.loc_de_munca,'')
union all
select distinct 'PO' as tip, '' as subtip, '' as densubtip, convert(char(10),@datasus,101) as data, 
rtrim(rtrim(max(c.LunaAlfa))+' '+convert(char(4),max(c.An))) as luna, 
isnull(p.loc_de_munca,'') as lmantet, rtrim(max(isnull(lm.denumire,''))) as denlmantet,
0 as nrsal, 0 as nrsalregie, 0 as nrsalacord, Null as cantitate, Null as valoare, 0 as orelucrate, 0 as oresupl, 
0 as orenoapte, 0 as oreco, 0 as orecm, 0 as oreinvoiri, 0 as orenemotivate, 0 as orecfs, 
0 as oreit1, 0 as oreit2, 0 as oreobligatii, 0 as orenelucrate, 0 as nrtichete, 
(case when @datasus<=@DataInch then '#808080' else '#000000' end) as culoare, 
(case when @datasus<=@DataInch or @datasus<=@DataBloc then 1 else 0 end) as _nemodificabil
from personal as p
	left outer join lm on p.loc_de_munca=lm.cod
	inner join fCalendar (@datasus, @datasus) c on c.Data=@datasus
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and p.Loc_de_munca=lu.cod
where (p.loc_ramas_vacant=0 or p.data_plec>=@DataLJ) and p.Data_angajarii_in_unitate<=@datasus
	and (@lmantet is null or p.loc_de_munca=@lmantet)
	and not exists (select loc_de_munca from istpers i where i.Data=@datasus and exists (select j.marca from pontaj j where j.Data between dbo.bom(@datasus) and @datasus and j.Marca=i.Marca) 
		and i.Loc_de_munca=p.Loc_de_munca)
	and (@f_denlm is null or lm.denumire like '%'+@f_denlm+'%')
	and (@f_lm is null or p.Loc_de_munca like @f_lm+'%')
	and (@f_salariat is null or p.Nume like '%'+@f_salariat+'%' or p.Marca like @f_salariat+'%')
	and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
group by isnull(p.loc_de_munca,'')

if exists (select 1 from sysobjects where [type]='P' and [name]='wIaPontajSP')
	exec wIaPontajSP @sesiune, @parXML

select tip, subtip, densubtip, convert(char(10),dbo.eom(data),101) as data, luna, lmantet, denlmantet, 
nrsal, nrsalregie, nrsalacord, cantitate, valoare, orelucrate, 
oresupl, orenoapte, oreco, orecm, oreinvoiri, orenemotivate, orecfs, oreit1, oreit2, oreobligatii, orenelucrate, nrtichete, 
culoare, _nemodificabil
from #wiapontaj
order by data, lmantet
for xml raw

if object_id('tempdb..#wiapontaj') is not null drop table #wiapontaj
