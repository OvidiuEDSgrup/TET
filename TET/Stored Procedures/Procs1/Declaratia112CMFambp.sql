--***
Create procedure Declaratia112CMFambp 
	(@dataJos datetime, @dataSus datetime, @Marca char(6)=null, @Lm char(9), @Strict int)
as
Begin
	declare @utilizator varchar(20), @lista_lm int, @Subtipcor int, @NrCazuriAjDeces int, @SumaAjDeces decimal(10), @AjDecesUnitate int

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	set @Subtipcor=dbo.iauParL('PS','SUBTIPCOR')
	set @AjDecesUnitate=dbo.iauParL('PS','AJDUNIT-R')

	if object_id('tempdb..#CMFambp') is not null drop table #CMFambp
	if object_id('tempdb..#tmpCMfambp') is not null drop table #tmpCMfambp
	
	Create table #CMFambp
	(Data datetime, NrCazuriIT int, NrCazuriTT int, NrCazuriRT int, NrCazuriCC int, ZileCM int, ZileCMIT int, ZileCMTT int, ZileCMRT int, ZileCMCC int, 
		Indemnizatie decimal(10), IndemnizatieIT decimal(10), IndemnizatieTT decimal(10), IndemnizatieRT decimal(10), IndemnizatieCC decimal(10), 
		IndemnizatieFambp decimal(10), IndemnizITFambp decimal(10), IndemnizTTFambp decimal(10), IndemnizRTFambp decimal(10), IndemnizCCFambp decimal(10), 
		NrCazuriAjDeces int, SumaAjDeces decimal(10))

	create table #tmpCMfambp 
		(Data datetime, Diagnostic char(3), Nr_cazuri int, ZileCM int, Indemnizatie decimal(10), Indemniz_fambp decimal(10))

	insert #tmpCMfambp
	select a.Data, (case when (a.tip_diagnostic='2-' or tip_diagnostic='3-' or tip_diagnostic='4-') then 'IT' 
		when tip_diagnostic='10' and a.suma=1 then 'RT' when tip_diagnostic='11' and a.suma=1 then 'TT' else 'CC' end) as Diagnostic, 
		count(distinct a.marca+convert(char(10),a.data_inceput,102)) as Nr_cazuri, sum(zile_lucratoare) as ZileCM, 
		sum(indemnizatie_unitate+indemnizatie_cas) as Indemnizatie, sum(indemnizatie_cas) as Indemniz_fambp
	from #conmed a
	where a.data between @dataJos and @dataSus and a.data_inceput between @dataJos and @dataSus 
		and (@Marca is null or a.marca=@Marca) 
		and ((tip_diagnostic='2-' or tip_diagnostic='3-' or tip_diagnostic='4-') or (tip_diagnostic='10' or tip_diagnostic='11') and a.suma=1)
	group by a.Data, (case when (a.tip_diagnostic='2-' or tip_diagnostic='3-' or tip_diagnostic='4-') then 'IT'
		when tip_diagnostic='10' and a.suma=1 then 'RT' when tip_diagnostic='11' and a.suma=1 then 'TT' else 'CC' end)

	select @NrCazuriAjDeces=count(distinct a.marca), @SumaAjDeces=sum(suma_corectie) 
	from corectii a
		left outer join istpers i on i.Data=dbo.EOM(a.Data) and i.Marca=a.Marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
	where a.data between @dataJos and @dataSus and (@Marca is null or a.marca=@Marca) 
		and (@Lm='' or i.loc_de_munca like rtrim(@Lm)+( case when @Strict=0 then '%' else '' end)) 
		and (@Subtipcor=0 and tip_corectie_venit='R-' or @Subtipcor=1 and Tip_corectie_venit in (select s.Subtip from Subtipcor s where s.tip_corectie_venit='R-'))
		and (@lista_lm=0 or lu.cod is not null) 
		and @AjDecesUnitate=0

	insert into #CMFambp
	select Data, sum((case when Diagnostic='IT' then Nr_cazuri else 0 end)), sum((case when Diagnostic='TT' then Nr_cazuri else 0 end)),
		sum((case when Diagnostic='RT' then Nr_cazuri else 0 end)), sum((case when Diagnostic='CC' then Nr_cazuri else 0 end)),
		sum((case when Diagnostic='RM' then Nr_cazuri else 0 end)), 
		sum((case when Diagnostic='IT' then ZileCM else 0 end)), sum((case when Diagnostic='TT' then ZileCM else 0 end)), 
		sum((case when Diagnostic='RT' then ZileCM else 0 end)), sum((case when Diagnostic='CC' then ZileCM else 0 end)), 
		sum(Indemnizatie), sum((case when Diagnostic='IT' then Indemnizatie else 0 end)), 
		sum((case when Diagnostic='TT' then Indemnizatie else 0 end)), sum((case when Diagnostic='RT' then Indemnizatie else 0 end)), 
		sum((case when Diagnostic='CC' then Indemnizatie else 0 end)), 
		sum(Indemniz_fambp),
		sum((case when Diagnostic='IT' then Indemniz_fambp else 0 end)), sum((case when Diagnostic='TT' then Indemniz_fambp else 0 end)),
		sum((case when Diagnostic='RT' then Indemniz_fambp else 0 end)), sum((case when Diagnostic='CC' then Indemniz_fambp else 0 end)),
		@NrCazuriAjDeces, @SumaAjDeces
	from #tmpCMfambp
	group by data

	if isnull((select count(1) from #CMFambp),0)=0 and @NrCazuriAjDeces<>0
		insert into #CMFambp
		values (@dataSus, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @NrCazuriAjDeces, @SumaAjDeces)

	select Data, NrCazuriIT, NrCazuriTT, NrCazuriRT, NrCazuriCC, ZileCM, ZileCMIT, ZileCMTT, ZileCMRT, ZileCMCC, 
		Indemnizatie, IndemnizatieIT, IndemnizatieTT, IndemnizatieRT, IndemnizatieCC, 
		IndemnizatieFambp, IndemnizITFambp, IndemnizTTFambp, IndemnizRTFambp, IndemnizCCFambp, 
		NrCazuriAjDeces, SumaAjDeces
	from #CMFambp
	
	return
End

/*
	exec Declaratia112CMFambp '11/01/2012', '11/30/2012', null, '', 0
*/
