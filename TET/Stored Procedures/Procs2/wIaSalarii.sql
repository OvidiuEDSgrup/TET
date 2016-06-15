--***
Create procedure wIaSalarii @sesiune varchar(50), @parXML xml
as  
set transaction isolation level READ UNCOMMITTED
declare @userASiS varchar(10), @LunaInch int, @AnulInch int, @DataInch datetime, 
@LunaBloc int, @AnulBloc int, @DataBloc datetime, 
@iDoc int, @tip varchar(2), @data datetime, @datajos datetime, @datasus datetime, @marca varchar(6), @salariat varchar(50), 
@filtruMarca varchar(6), @filtruNume varchar(50), @filtruLM varchar(9), @filtrudenLM varchar(30), @filtruFunctie varchar(6), @filtrudenFunctie varchar(30)

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
	@marca=xA.row.value('@marca', 'varchar(6)'), 
	@filtruMarca=isnull(xA.row.value('@f_marca', 'varchar(6)'),''), @filtruNume=isnull(xA.row.value('@f_densalariat', 'varchar(50)'),''), 
	@filtruFunctie=isnull(xA.row.value('@f_functie', 'varchar(6)'),''), @filtrudenFunctie=isnull(xA.row.value('@f_denfunctie', 'varchar(30)'),''),
	@filtruLM=isnull(xA.row.value('@f_lm', 'varchar(9)'),''), @filtrudenLM=isnull(xA.row.value('@f_denlm', 'varchar(30)'),'')
from @parXML.nodes('row') as xA(row)  

select top 100 
'SL' as tip,
rtrim(i.marca) as marca,
convert(char(10),i.data,101) as data,
rtrim(rtrim(c.LunaAlfa)+' '+convert(char(4),c.An)) as luna, 
rtrim(i.nume) as densalariat, 
rtrim(i.Loc_de_munca) as lmantet, 
rtrim(lm.denumire) as denlmantet, 
rtrim(f.denumire) as denfunctie, 
convert(decimal(10,2),i.salar_de_incadrare) as salarincadrare,
(case when i.Data<=@DataInch then '#808080' else '#000000' end) as culoare,
(case when i.Data<=@DataInch or i.Data<=@DataBloc then 1 else 0 end) as _nemodificabil
from istpers as i
	left outer join lm on lm.cod=i.loc_de_munca
	left outer join functii f on f.cod_functie=i.cod_functie
	inner join fCalendar (@datajos, @datasus) c on c.Data=i.Data 
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and i.Loc_de_munca=lu.cod
	,@parXML.nodes('row') as xA(row)
where 
i.data between @datajos and @datasus and (@data is null or i.data=@data) and (@marca is Null or i.Marca=@marca)
	and (@filtruMarca='' or i.Marca like @filtruMarca + '%')
	and (@filtruNume='' or i.Nume like '%' + replace(@filtruNume,' ','%') + '%' or i.Marca like @filtruNume + '%')
	and (@filtruLM='' or i.Loc_de_munca like @filtruLM + '%')
	and (@filtrudenLM='' or lm.Denumire like '%' + replace(@filtrudenLM,' ','%') + '%')
	and (@filtruFunctie='' or i.Cod_functie like @filtruFunctie + '%')
	and (@filtrudenFunctie='' or f.Denumire like '%' + replace(@filtrudenFunctie,' ','%') + '%')
	and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
union all 
select 'SL' as tip,
rtrim(p.marca) as marca,
convert(char(10),@datasus,101) as data,
rtrim(rtrim(c.LunaAlfa)+' '+convert(char(4),c.An)) as luna, 
rtrim(p.nume) as densalariat, 
rtrim(p.Loc_de_munca) as lmantet, 
rtrim(lm.denumire) as denlmantet, 
rtrim(f.denumire) as denfunctie, 
convert(decimal(10,2),p.salar_de_incadrare) as salarincadrare,
(case when @datasus<=@DataInch then '#808080' else '#000000' end) as culoare,
(case when @datasus<=@DataInch or @datasus<=@DataBloc then 1 else 0 end) as _nemodificabil
from personal as p
	left outer join lm on lm.cod=p.loc_de_munca
	left outer join functii f on f.cod_functie=p.cod_functie
	inner join fCalendar (@datasus, @datasus) c on c.Data=@datasus 
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and p.Loc_de_munca=lu.cod
	,@parXML.nodes('row') as xA(row)
where (@marca is Null or p.Marca=@marca) and p.loc_ramas_vacant=0 and not exists (select marca from istpers i where i.data=@datasus and i.Marca=p.Marca and (@data is null or i.data=@data)) 
	and (@filtruMarca='' or p.Marca like @filtruMarca + '%')
	and (@filtruNume='' or p.Nume like '%' + replace(@filtruNume,' ','%') + '%' or p.Marca like @filtruNume + '%')
	and (@filtruLM='' or p.Loc_de_munca like @filtruLM + '%')
	and (@filtrudenLM='' or lm.Denumire like '%' + replace(@filtrudenLM,' ','%') + '%')
	and (@filtruFunctie='' or p.Cod_functie like @filtruFunctie + '%')
	and (@filtrudenFunctie='' or f.Denumire like '%' + replace(@filtrudenFunctie,' ','%') + '%')
	and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
order by densalariat, data
for xml raw
