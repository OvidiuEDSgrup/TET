--***
CREATE procedure wIaTichete @sesiune varchar(50), @parXML xml
as  
declare @tip varchar(2), @data datetime, @LunaInch int, @AnulInch int, @DataInch datetime, 
@LunaBloc int, @AnulBloc int, @DataBloc datetime, 
@lista_lm int, @datajos datetime, @datasus datetime, @DataLJ datetime,
@lmantet varchar(9), @f_denlm varchar(50), @f_salariat varchar(50), @userASiS varchar(10)

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
@lmantet=xA.row.value('@lmantet','varchar(9)'), @f_denlm=xA.row.value('@f_denlm','varchar(50)'),
@f_salariat=xA.row.value('@f_salariat','varchar(50)')
from @parXML.nodes('row') as xA(row)  
set @DataLJ=dbo.Bom(@datasus)

/*	Nu mai apelam aici procedura de scriere in istpers. Am apelat scrierea in istpers la adaugarea tichetelor pe marca. 
	Am tratat astfel pentru a nu modifica datele din istpers daca se deschid luni inchise.
exec wScriuIstPers @sesiune, @parXML
*/

select isnull(convert(char(10),t.Data_lunii,101),convert(char(10),@datasus,101)) as data, 
'TM' as tip, 'T2' as subtip, 'Tichete' as densubtip, rtrim(rtrim(max(c.LunaAlfa))+' '+convert(char(4),max(c.An))) as luna, 
rtrim(isnull(i.Loc_de_munca,'')) as lmantet, rtrim(max(isnull(lm.denumire,''))) as denlmantet, count(distinct t.Marca) as nrsal, 
sum(convert(decimal(12,2),t.Nr_tichete*(case when t.Tip_operatie='R' then -1 else 1 end))) as nrtichete, 
sum(convert(decimal(12,2),t.Nr_tichete*t.Valoare_tichet*(case when t.Tip_operatie='R' then -1 else 1 end))) as valtichete, 
(case when t.Data_lunii<=@DataInch then '#808080' else '#000000' end) as culoare,
(case when t.Data_lunii<=@DataInch or t.Data_lunii<=@DataBloc then 1 else 0 end) as _nemodificabil
from Tichete t
	left outer join istpers i on t.Marca=i.Marca and t.Data_lunii=i.Data
	left outer join lm lm on lm.Cod=i.Loc_de_munca
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and i.Loc_de_munca=lu.cod
	inner join fCalendar (@datajos, @datasus) c on c.Data=t.Data_lunii 
	and t.Data_lunii between @datajos and @datasus and (@data is null or t.Data_lunii=@data)
	and (@f_denlm is null or lm.denumire like '%'+@f_denlm+'%')
	and (@lmantet is null or i.Loc_de_munca=@lmantet) 
	and (@f_salariat is null or i.Nume like '%'+@f_salariat+'%' or t.Marca like @f_salariat+'%')
	and (@lista_lm=0 or lu.cod is not null)
group by t.Data_lunii, isnull(i.loc_de_munca,'')
union all
select distinct convert(char(10),@datasus,101) as data, 'TM' as tip, 'T2' as subtip, 'Tichete' as densubtip,
rtrim(rtrim(max(c.LunaAlfa))+' '+convert(char(4),max(c.An))) as luna, 
isnull(p.loc_de_munca,'') as lmantet, rtrim(max(isnull(lm.denumire,''))) as denlmantet,
0 as nrsal, 0 as nrtichete, 0 as valtichete, 
(case when @datasus<=@DataInch then '#808080' else '#000000' end) as culoare, 
(case when @datasus<=@DataInch or @datasus<=@DataBloc then 1 else 0 end) as _nemodificabil
from personal as p
	left outer join lm on p.loc_de_munca=lm.cod
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and p.Loc_de_munca=lu.cod
	inner join fCalendar (@datasus, @datasus) c on c.Data=@datasus
where (@data is null or @datasus=@data)
	and (p.loc_ramas_vacant=0 or p.data_plec>=@DataLJ) 
	and p.Data_angajarii_in_unitate<=@datasus
	and not exists (select loc_de_munca from istpers i1 where i1.Data=@datasus 
			and exists (select t.marca from tichete t where t.data_lunii=@datasus and t.Marca=i1.Marca
				and (@f_salariat is null or i1.Nume like '%'+@f_salariat+'%' or t.Marca like @f_salariat+'%')) and i1.Loc_de_munca=p.Loc_de_munca)
	and (@f_denlm is null or lm.denumire like '%'+@f_denlm+'%')
	and (@lmantet is null or p.Loc_de_munca=@lmantet) 
	and (@f_salariat is null or p.Nume like '%'+@f_salariat+'%' or p.Marca like @f_salariat+'%')
	and (@lista_lm=0 or lu.cod is not null)
group by data, isnull(p.loc_de_munca,'')
order by data, valtichete desc, lmantet
for xml raw
