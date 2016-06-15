--***
Create procedure Declaratia112CMFnuass 
	(@dataJos datetime, @dataSus datetime, @Marca char(6)=null, @Lm char(9), @Strict int)
as
Begin
	declare @NrCazuriNrCertif int, @CCI_angajator decimal(10), @CCI_fambp decimal(10)
	select @NrCazuriNrCertif=1

	if object_id('tempdb..#CMFnuass') is not null drop table #CMFnuass
	if object_id('tempdb..#cmcnp') is not null drop table #cmcnp
	if object_id('tempdb..#tmpcciCNP') is not null drop table #tmpcciCNP
	if object_id('tempdb..#tmpcci') is not null drop table #tmpcci
	
	create table #CMFnuass 
		(Data datetime, NrCazuriIT int, NrCazuriPI int, NrCazuriSL int, NrCazuriICB int, NrCazuriRM int, 
		ZileCM int, ZileCMIT int, ZileCMPI int, ZileCMSL int, ZileCMICB int, ZileCMRM int, 
		ZileCMIT_angajator int, ZileCMIT_fnuass int, ZileCMPI_fnuass int, ZileCMSL_fnuass int, ZileCMICB_fnuass int, ZileCMRM_fnuass int, 
		Indemniz_angajator decimal(10), IndemnizIT_angajator decimal(10), 
		IndemnizIT_fnuass decimal(10), IndemnizPI_fnuass decimal(10), IndemnizSL_fnuass decimal(10), IndemnizICB_fnuass decimal(10), IndemnizRM_fnuass decimal(10),
		Total_CCI_angajator decimal(10), Total_CCI_fambp decimal(10), Total_CCI decimal(10), 
		Indemniz_fnuass decimal(10), Total_recuperat decimal(10), Total_de_virat decimal(10), Ramas_de_recuperat decimal(10))

--	creare cursor pt. verificare existenta CM pe acelasi CNP, alta marca si aceeasi perioada
	select a.Data, a.Marca, a.Data_inceput, 
		(case when exists (select 1 from #conmed cm left outer join personal p1 on cm.Marca=p1.Marca 
		where cm.Marca<>a.Marca and cm.Data_inceput=a.Data_inceput and p1.Cod_numeric_personal=p.Cod_numeric_personal) then 1 else 0 end) as NrCMCNP
	into #cmcnp
	from #conmed a 
		left outer join personal p on a.marca = p.marca 
	where a.data_inceput between @dataJos and @dataSus and (@Marca is null or a.marca=@Marca) 
		and not(a.tip_diagnostic in ('2-','3-','4-') or (a.tip_diagnostic='10' or a.tip_diagnostic='11') and a.suma=1)
		and a.tip_diagnostic<>'0-'

--	grupare pe cnp si diagnostic
	select a.Data, p.Cod_numeric_personal, (case when (a.tip_diagnostic='1-' or a.tip_diagnostic='5-' or 
		a.tip_diagnostic='6-' or a.tip_diagnostic='12' or a.tip_diagnostic='13' or a.tip_diagnostic='14') then 'IT' 
		when (tip_diagnostic='7-' or tip_diagnostic='10' and a.suma=0 or tip_diagnostic='11' and a.suma=0) then 'PI'
		when tip_diagnostic='8-' then 'SL' when tip_diagnostic='9-' then 'ICB' when tip_diagnostic='15' then 'RM' end) as diagnostic, 
		count(distinct p.Cod_numeric_personal+(case when @NrCazuriNrCertif=1 then convert(char(10),a.data_inceput,102) else '' end)) as Nr_cazuri, 
		round((case when max(c.NrCMCNP)=1 
			then max(zile_lucratoare*(case when a.Tip_diagnostic='10' then 0.25 else 1 end)) else sum(round(zile_lucratoare*(case when a.Tip_diagnostic='10' then 0.25 else 1 end),0)) end),0) as ZileCM, 
		(case when max(c.NrCMCNP)=1 then max(zile_cu_reducere) else sum(zile_cu_reducere) end) as ZileCM_angajator, 
		round((case when max(c.NrCMCNP)=1 then max((zile_lucratoare-zile_cu_reducere)*(case when tip_diagnostic='10' then 0.25 else 1 end)) 
			else sum(round((zile_lucratoare-zile_cu_reducere)*(case when tip_diagnostic='10' then 0.25 else 1 end),0)) end),0) as ZileCM_fnuass, 
		sum(indemnizatie_unitate) as indemniz_angajator, sum(indemnizatie_cas) as indemniz_fnuass
	into #tmpcciCNP
	from #conmed a 
		left outer join personal p on a.marca = p.marca 
		left outer join #cmcnp c on a.Data=c.Data and a.Marca=c.Marca and a.Data_inceput=c.Data_inceput
	where a.data_inceput between @dataJos and @dataSus and (@Marca is null or a.marca=@Marca) 
		and not(a.tip_diagnostic in ('2-','3-','4-') or (a.tip_diagnostic='10' or a.tip_diagnostic='11') and a.suma=1)
		and a.tip_diagnostic<>'0-'
	group by a.Data, p.Cod_numeric_personal, (case when (a.tip_diagnostic='1-' or a.tip_diagnostic='5-' or 
		a.tip_diagnostic='6-' or a.tip_diagnostic='12' or a.tip_diagnostic='13' or a.tip_diagnostic='14') then 'IT' 
		when (tip_diagnostic='7-' or tip_diagnostic='10' and a.suma=0 or tip_diagnostic='11' and a.suma=0) then 'PI'
		when tip_diagnostic='8-' then 'SL' when tip_diagnostic='9-' then 'ICB' 
		when tip_diagnostic='15' then 'RM' end)

--	grupare pe diagnostic
	select Data, Diagnostic, sum(Nr_cazuri) as Nr_cazuri, sum(ZileCM) as ZileCM, sum(ZileCM_angajator) as ZileCM_angajator, 
		sum(ZileCM_fnuass) as ZileCM_fnuass, sum(Indemniz_angajator) as Indemniz_angajator, sum(Indemniz_fnuass) as Indemniz_fnuass
	into #tmpcci
	from #tmpcciCNP
	group by Data, Diagnostic
	
	select @CCI_angajator=sum(n.ded_suplim), @CCI_fambp=sum(isnull(n1.ded_suplim,0))
	from #net n
		left outer join #net n1 on n.marca = n1.marca and dbo.bom(n.data) = n1.data
	where n.data=@dataSus and (@Marca is null or n.marca=@Marca) 
		and (@Lm='' or n.loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end)) 

	insert into #CMFnuass
	select Data, sum((case when Diagnostic='IT' then Nr_cazuri else 0 end)), sum((case when Diagnostic='PI' then Nr_cazuri else 0 end)),
		sum((case when Diagnostic='SL' then Nr_cazuri else 0 end)), sum((case when Diagnostic='ICB' then Nr_cazuri else 0 end)),
		sum((case when Diagnostic='RM' then Nr_cazuri else 0 end)), sum(ZileCM),
		sum((case when Diagnostic='IT' then ZileCM else 0 end)), sum((case when Diagnostic='PI' then ZileCM else 0 end)), 
		sum((case when Diagnostic='SL' then ZileCM else 0 end)), sum((case when Diagnostic='ICB' then ZileCM else 0 end)), 
		sum((case when Diagnostic='RM' then ZileCM else 0 end)), sum((case when Diagnostic='IT' then ZileCM_angajator else 0 end)), 
		sum((case when Diagnostic='IT' then ZileCM_fnuass else 0 end)), sum((case when Diagnostic='PI' then ZileCM_fnuass else 0 end)), 
		sum((case when Diagnostic='SL' then ZileCM_fnuass else 0 end)), sum((case when Diagnostic='ICB' then ZileCM_fnuass else 0 end)), 
		sum((case when Diagnostic='RM' then ZileCM_fnuass else 0 end)), 
		sum(Indemniz_angajator), sum((case when Diagnostic='IT' then Indemniz_angajator else 0 end)), 
		sum((case when Diagnostic='IT' then Indemniz_fnuass else 0 end)), sum((case when Diagnostic='PI' then Indemniz_fnuass else 0 end)),
		sum((case when Diagnostic='SL' then Indemniz_fnuass else 0 end)), sum((case when Diagnostic='ICB' then Indemniz_fnuass else 0 end)),
		sum((case when Diagnostic='RM' then Indemniz_fnuass else 0 end)),
		0, 0, 0, sum(Indemniz_fnuass), 0, 0, 0
	from #tmpcci
	group by data

	if isnull((select count(1) from #CMFnuass),0)=0
		insert into #CMFnuass
		values (@dataSus, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

	update #CMFnuass
		set Total_CCI_angajator=@CCI_angajator, Total_CCI_fambp=@CCI_fambp, Total_CCI=@CCI_angajator+@CCI_fambp, 
		Total_recuperat=dbo.valoare_minima(@CCI_angajator+@CCI_fambp,Indemniz_fnuass,0), 
		Total_de_virat=(case when @CCI_angajator+@CCI_fambp>Indemniz_fnuass then @CCI_angajator+@CCI_fambp-Indemniz_fnuass else 0 end), 
		Ramas_de_recuperat=(case when @CCI_angajator+@CCI_fambp<=Indemniz_fnuass then Indemniz_fnuass-(@CCI_angajator+@CCI_fambp) else 0 end)
	
	select Data, NrCazuriIT, NrCazuriPI, NrCazuriSL, NrCazuriICB, NrCazuriRM, 
		ZileCM, ZileCMIT, ZileCMPI, ZileCMSL, ZileCMICB, ZileCMRM, ZileCMIT_angajator, ZileCMIT_fnuass, ZileCMPI_fnuass, ZileCMSL_fnuass, ZileCMICB_fnuass, ZileCMRM_fnuass, 
		Indemniz_angajator, IndemnizIT_angajator, IndemnizIT_fnuass, IndemnizPI_fnuass, IndemnizSL_fnuass, IndemnizICB_fnuass, IndemnizRM_fnuass,
		Total_CCI_angajator, Total_CCI_fambp, Total_CCI, Indemniz_fnuass, Total_recuperat, Total_de_virat, Ramas_de_recuperat
	from #CMFnuass	

	return
End

/*
	exec Declaratia112CMFnuass '11/01/2012', '11/30/2012', null, '', 0
*/
