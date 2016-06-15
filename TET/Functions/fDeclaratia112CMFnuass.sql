--***
Create
function [dbo].[fDeclaratia112CMFnuass] (@DataJ datetime, @DataS datetime, @oMarca int, @Marca char(6), @Lm char(9), @Strict int)
returns @CMFnuass table 
	(Data datetime, NrCazuriIT int, NrCazuriPI int, NrCazuriSL int, NrCazuriICB int, NrCazuriRM int, 
	ZileCM int, ZileCMIT int, ZileCMPI int, ZileCMSL int, ZileCMICB int, ZileCMRM int, 
	ZileCMIT_angajator int, ZileCMIT_fnuass int, ZileCMPI_fnuass int, ZileCMSL_fnuass int, ZileCMICB_fnuass int, ZileCMRM_fnuass int, 
	Indemniz_angajator decimal(10), IndemnizIT_angajator decimal(10), 
	IndemnizIT_fnuass decimal(10), IndemnizPI_fnuass decimal(10), IndemnizSL_fnuass decimal(10), IndemnizICB_fnuass decimal(10), IndemnizRM_fnuass decimal(10),
	Total_CCI_angajator decimal(10), Total_CCI_fambp decimal(10), Total_CCI decimal(10), 
	Indemniz_fnuass decimal(10), Total_recuperat decimal(10), Total_de_virat decimal(10), Ramas_de_recuperat decimal(10))
as
Begin
	declare @NrCazuriNrCertif int, @CCI_angajator decimal(10), @CCI_fambp decimal(10)
	select @NrCazuriNrCertif=1

--	creare cursor pt. verificare existenta CM pe acelasi CNP, alta marca si aceeasi perioada
	declare @cmcnp table (Data datetime, Marca char(6), Data_inceput datetime, NrCMCNP int)
	insert into @cmcnp
	select a.Data, a.Marca, a.Data_inceput, 
		(case when exists (select 1 from conmed cm left outer join personal p1 on cm.Marca=p1.Marca 
		where cm.Marca<>a.Marca and cm.Data_inceput=a.Data_inceput and p1.Cod_numeric_personal=p.Cod_numeric_personal) then 1 else 0 end) as NrCMCNP
	from conmed a 
		left outer join istpers b on a.data = b.data and a.marca = b.marca 
		left outer join personal p on a.marca = p.marca 
	where a.marca=b.marca and a.data_inceput between @DataJ and @DataS and (@oMarca=0 or a.marca=@Marca) 
		and a.data=b.data and (@Lm='' or b.loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end)) 
		and not(a.tip_diagnostic in ('2-','3-','4-') or (a.tip_diagnostic='10' or a.tip_diagnostic='11') and a.suma=1)
		and a.tip_diagnostic<>'0-'

--	grupare pe cnp si diagnostic
	declare @tmpcciCNP table 
	(Data datetime, CNP varchar(13), Diagnostic char(3), Nr_cazuri int, ZileCM int, ZileCM_angajator int, ZileCM_fnuass int, Indemniz_angajator decimal(10), Indemniz_fnuass decimal(10))
	insert into @tmpcciCNP
	select a.Data, p.Cod_numeric_personal, (case when (a.tip_diagnostic='1-' or a.tip_diagnostic='5-' or 
		a.tip_diagnostic='6-' or a.tip_diagnostic='12' or a.tip_diagnostic='13' or a.tip_diagnostic='14') then 'IT' 
		when (tip_diagnostic='7-' or tip_diagnostic='10' and a.suma=0 or tip_diagnostic='11' and a.suma=0) then 'PI'
		when tip_diagnostic='8-' then 'SL' when tip_diagnostic='9-' then 'ICB' 
		when tip_diagnostic='15' then 'RM' end), 
		count(distinct p.Cod_numeric_personal+(case when @NrCazuriNrCertif=1 then convert(char(10),a.data_inceput,102) else '' end)), 
		(case when max(c.NrCMCNP)=1 then max(zile_lucratoare*(case when a.Tip_diagnostic='10' then 0.25 else 1 end)) else sum(zile_lucratoare*(case when a.Tip_diagnostic='10' then 0.25 else 1 end)) end), 
		(case when max(c.NrCMCNP)=1 then max(zile_cu_reducere) else sum(zile_cu_reducere) end), 
		(case when max(c.NrCMCNP)=1 then max((zile_lucratoare-zile_cu_reducere)*(case when tip_diagnostic='10' then 0.25 else 1 end)) 
		else sum((zile_lucratoare-zile_cu_reducere)*(case when tip_diagnostic='10' then 0.25 else 1 end)) end), 
		sum(indemnizatie_unitate), sum(indemnizatie_cas)
	from conmed a 
		left outer join istpers b on a.data = b.data and a.marca = b.marca 
		left outer join personal p on a.marca = p.marca 
		left outer join @cmcnp c on a.Data=c.Data and a.Marca=c.Marca and a.Data_inceput=c.Data_inceput
	where a.marca=b.marca and a.data_inceput between @DataJ and @DataS and (@oMarca=0 or a.marca=@Marca) 
		and a.data=b.data and (@Lm='' or b.loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end)) 
		and not(a.tip_diagnostic in ('2-','3-','4-') or (a.tip_diagnostic='10' or a.tip_diagnostic='11') and a.suma=1)
		and a.tip_diagnostic<>'0-'
	group by a.Data, p.Cod_numeric_personal, (case when (a.tip_diagnostic='1-' or a.tip_diagnostic='5-' or 
		a.tip_diagnostic='6-' or a.tip_diagnostic='12' or a.tip_diagnostic='13' or a.tip_diagnostic='14') then 'IT' 
		when (tip_diagnostic='7-' or tip_diagnostic='10' and a.suma=0 or tip_diagnostic='11' and a.suma=0) then 'PI'
		when tip_diagnostic='8-' then 'SL' when tip_diagnostic='9-' then 'ICB' 
		when tip_diagnostic='15' then 'RM' end)

--	grupare pe diagnostic
	declare @tmpcci table 
	(Data datetime, Diagnostic char(3), Nr_cazuri int, ZileCM int, ZileCM_angajator int, ZileCM_fnuass int, Indemniz_angajator decimal(10), Indemniz_fnuass decimal(10))
	insert @tmpcci
	select Data, Diagnostic, sum(Nr_cazuri), sum(ZileCM), sum(ZileCM_angajator), sum(ZileCM_fnuass), 
	sum(Indemniz_angajator), sum(Indemniz_fnuass)
	from @tmpcciCNP
	group by Data, Diagnostic
	
	select @CCI_angajator=sum(a.ded_suplim), @CCI_fambp=sum(isnull(c.ded_suplim,0))
	from net a
		left outer join net c on a.marca = c.marca and dbo.bom(a.data) = c.data
	where a.data=@DataS and (@oMarca=0 or a.marca=@Marca) 
		and (@Lm='' or a.loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end)) 

	insert into @CMFnuass
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
	from @tmpcci
	group by data

	if isnull((select count(1) from @CMFnuass),0)=0
		insert into @CMFnuass
		values (@DataS, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

	update @CMFnuass
		set Total_CCI_angajator=@CCI_angajator, Total_CCI_fambp=@CCI_fambp, Total_CCI=@CCI_angajator+@CCI_fambp, 
		Total_recuperat=dbo.valoare_minima(@CCI_angajator+@CCI_fambp,Indemniz_fnuass,0), 
		Total_de_virat=(case when @CCI_angajator+@CCI_fambp>Indemniz_fnuass then @CCI_angajator+@CCI_fambp-Indemniz_fnuass else 0 end), 
		Ramas_de_recuperat=(case when @CCI_angajator+@CCI_fambp<=Indemniz_fnuass then Indemniz_fnuass-(@CCI_angajator+@CCI_fambp) else 0 end)

	return
End

/*
select * from fDeclaratia112CMFnuass ('05/01/2011', '05/31/2011', 0, '', '', 0)
*/
