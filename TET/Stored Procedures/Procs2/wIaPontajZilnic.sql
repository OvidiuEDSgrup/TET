--***
CREATE procedure wIaPontajZilnic @sesiune varchar(50), @parXML xml
as  
begin
	set transaction isolation level READ UNCOMMITTED
	declare @userASiS varchar(10), @LunaInch int, @AnulInch int, @DataInch datetime, @LunaBloc int, @AnulBloc int, @DataBloc datetime, 
	@tip varchar(2), @data datetime, @datajos datetime, @datasus datetime, @lm varchar(9), @f_lm varchar(9), @f_denlm varchar(50), 
	@f_salariat varchar(50), @DataLJ datetime

	select @tip=xA.row.value('@tip', 'char(2)'), @data=xA.row.value('@data','datetime'), 
		@datajos=dbo.Bom(isnull(xA.row.value('@datajos','datetime'),isnull(xA.row.value('@data','datetime'),'01/01/1901'))), 
		@datasus=dbo.Eom(isnull(xA.row.value('@datasus','datetime'),isnull(xA.row.value('@data','datetime'),'12/31/2999'))),
		@lm=xA.row.value('@lm','varchar(9)'), @f_lm=xA.row.value('@f_lm','varchar(9)'), 
		@f_denlm=xA.row.value('@f_denlm','varchar(50)'), @f_salariat=xA.row.value('@f_salariat','varchar(50)')
	from @parXML.nodes('row') as xA(row)  

	set @LunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @AnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	set @LunaBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNABLOC'), 1)
	set @AnulBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANULBLOC'), 1901)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	set @DataInch=dbo.Eom(convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4)))
	set @DataBloc=dbo.Eom(convert(datetime,str(@LunaBloc,2)+'/01/'+str(@AnulBloc,4)))

	set @DataLJ=dbo.Bom(@datasus)

	if object_id('tempdb..#wiapontaj') is not null drop table #wiapontaj

	select @tip as tip, convert(varchar(2),'') as subtip, convert(varchar(100),'') as densubtip, convert(char(10),dbo.eom(pz.data),101) as data, 
		rtrim(rtrim(max(c.LunaAlfa))+' '+convert(char(4),max(c.An))) as luna, 
		isnull(isnull(i.loc_de_munca,p.loc_de_munca),'') as lm, rtrim(max(isnull(lm.denumire,''))) as denlm,
		count(distinct pz.marca) as nrsal,
		(case when dbo.eom(pz.data)<=@DataInch then '#808080' else '#000000' end) as culoare,
		(case when dbo.eom(pz.data)<=@DataInch or dbo.eom(pz.data)<=@DataBloc then 1 else 0 end) as _nemodificabil
	into #wiapontaj
	from pontaj_zilnic as pz
		inner join personal p on p.marca=pz.marca
		left outer join istpers i on i.data=dbo.eom(pz.data) and p.marca=i.marca
		left outer join lm on lm.cod=isnull(i.loc_de_munca,p.loc_de_munca)
		inner join fCalendar (@datajos, @datasus) c on c.Data=dbo.eom(pz.data)
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=isnull(i.loc_de_munca,p.loc_de_munca)
	where @tip='PO' and (@lm is null or i.loc_de_munca=@lm)
		and pz.data between @datajos and @datasus and (@data is null or pz.data=@data)
		and (@f_denlm is null or lm.denumire like '%'+@f_denlm+'%')
		and (@f_lm is null or i.Loc_de_munca like @f_lm+'%')
		and (@f_salariat is null or i.Nume like '%'+@f_salariat+'%' or p.Marca like @f_salariat+'%')
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	group by dbo.eom(pz.data), isnull(i.loc_de_munca,p.loc_de_munca)
	union all
	select distinct 'PO' as tip, '' as subtip, '' as densubtip, convert(char(10),@datasus,101) as data, 
		rtrim(rtrim(max(c.LunaAlfa))+' '+convert(char(4),max(c.An))) as luna, 
		isnull(p.loc_de_munca,'') as lm, rtrim(max(isnull(lm.denumire,''))) as denlm,
		0 as nrsal,
		(case when @datasus<=@DataInch then '#808080' else '#000000' end) as culoare, 
		(case when @datasus<=@DataInch or @datasus<=@DataBloc then 1 else 0 end) as _nemodificabil
	from personal as p
		left outer join lm on p.loc_de_munca=lm.cod
		inner join fCalendar (@datasus, @datasus) c on c.Data=@datasus
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and p.Loc_de_munca=lu.cod
	where (p.loc_ramas_vacant=0 or p.data_plec>=@DataLJ) and p.Data_angajarii_in_unitate<=@datasus
		and (@lm is null or p.loc_de_munca=@lm)
		and not exists (select 1 from pontaj_zilnic pz where pz.Data between dbo.bom(@datasus) and @datasus /*and pz.Marca=p.Marca*/ and pz.Loc_de_munca=p.Loc_de_munca)
		/*and not exists (select 1 from istpers i where i.Data=@datasus 
			and exists (select 1 from pontaj_zilnic pz1 where pz1.Data between dbo.bom(@datasus) and @datasus and pz1.Marca=i.Marca) and i.Loc_de_munca=p.Loc_de_munca)*/
		and (@f_denlm is null or lm.denumire like '%'+@f_denlm+'%')
		and (@f_lm is null or p.Loc_de_munca like @f_lm+'%')
		and (@f_salariat is null or p.Nume like '%'+@f_salariat+'%' or p.Marca like @f_salariat+'%')
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	group by isnull(p.loc_de_munca,'')

	if exists (select 1 from sysobjects where [type]='P' and [name]='wIaPontajPeZileSP')
		exec wIaPontajPeZileSP @sesiune, @parXML

	select tip, subtip, densubtip, convert(char(10),dbo.eom(data),101) as data, luna, lm, denlm, nrsal, 
		culoare, _nemodificabil
	from #wiapontaj
	order by data, lm
	for xml raw

	if object_id('tempdb..#wiapontaj') is not null drop table #wiapontaj
end
