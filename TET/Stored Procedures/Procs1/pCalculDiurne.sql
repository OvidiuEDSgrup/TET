--***
Create procedure pCalculDiurne
	@dataJos datetime
	,@dataSus datetime
	,@marca char(9)=null	-->	pentru filtrare marca
	,@lm char(9)=null		-->	pentru filtrare loc de munca like
	,@genCorectii int=0		-->	pentru generare corectii pe cele 2 categorii: neimpozabile si impozabile
as  
Begin try
	declare @utilizator varchar(20), @lista_lm int, @subtipcor int, @DiurneNeimpoz int, @CorectieDiurneNeimpoz varchar(2), @DiurneImpoz int, @CorectieDiurneImpoz varchar(2), 
		@CodBenefDiurne varchar(13)

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	select @subtipcor=max(case when Parametru='SUBTIPCOR' then Val_logica else 0 end), 
		@DiurneNeimpoz=max(case when Parametru='DIUNEIMP' then Val_logica else 0 end),
		@CorectieDiurneNeimpoz=max(case when Parametru='DIUNEIMP' then Val_alfanumerica else '' end),
		@DiurneImpoz=max(case when Parametru='DIUIMP' then Val_logica else 0 end),
		@CorectieDiurneImpoz=max(case when Parametru='DIUIMP' then Val_alfanumerica else '' end), 
		@CodBenefDiurne=max(case when Parametru='CODBDIURN' then Val_alfanumerica else '' end)
	from par 
	where tip_parametru='PS' and parametru in ('SUBTIPCOR','DIUNEIMP','DIUIMP','CODBDIURN')

	select @marca=isnull(@marca,''), @lm=isnull(@lm,'')

	if object_id('tempdb..#cdiurne') is not null drop table #cdiurne
	if object_id('tempdb..#diurne_finale') is not null drop table #diurne_finale
	if object_id('tempdb..#diurne_ins') is not null drop table #diurne_ins

	select d.marca, isnull(i.Loc_de_munca,p.Loc_de_munca) as loc_de_munca, isnull(i.Cod_functie,p.Cod_functie) as cod_functie, 
		d.data_inceput, d.data_sfarsit, isnull(d.Zile,DateDiff(day,d.data_inceput,d.data_sfarsit)+1) as zile, d.tara, d.valuta, d.tip_diurna, d.curs, 
		isnull(dm.diurna,isnull(dt.diurna,0)) as diurna_zi, isnull(dt.diurna_neimpozabila,0) as diurna_neimpozabila_zi, idPozitie as idDiurna
	into #cdiurne
	from Diurne d
		left outer join personal p on p.marca=d.marca
		left outer join istPers i on i.Data=dbo.eom(d.data_inceput) and i.marca=d.marca
		left outer join LMfiltrare lu on lu.utilizator=@utilizator and lu.cod=isnull(i.Loc_de_munca,p.Loc_de_munca)
		outer apply (select top 1 diurna, diurna_neimpozabila from CuantumDiurne cd where cd.marca=d.marca and cd.tara=d.tara and cd.valuta=d.valuta and cd.data_inceput<=d.data_inceput 
			order by cd.data_inceput desc) dm	-->diurna stabilita la nivel de marca (+tara si valuta)
		outer apply (select top 1 diurna, diurna_neimpozabila from CuantumDiurne cd where nullif(cd.marca,'') is null and cd.tara=d.tara and cd.valuta=d.valuta and cd.data_inceput<=d.data_inceput 
			order by cd.data_inceput desc) dt	-->diurna stabilita la tara si valuta, inclusiv cea neimpozabila
	where d.data_inceput between @datajos and @datasus
		and (@marca='' or d.marca=@marca)
		and (@lm='' or isnull(i.Loc_de_munca,p.Loc_de_munca) like rtrim(@lm)+'%')
		and (@lista_lm=0 or lu.cod is not null)

	update #cdiurne set diurna_neimpozabila_zi=(case when diurna_zi<diurna_neimpozabila_zi then diurna_zi else diurna_neimpozabila_zi end)

	select marca, loc_de_munca, cod_functie, data_inceput, data_sfarsit, zile, tara, valuta, tip_diurna, curs, 
		diurna_zi, diurna_neimpozabila_zi, zile*diurna_zi as diurna, zile*diurna_neimpozabila_zi as diurna_neimpozabila, 
		(case when diurna_zi-diurna_neimpozabila_zi>0 then zile*(diurna_zi-diurna_neimpozabila_zi) else 0 end) as diurna_impozabila,
		round(zile*diurna_zi*curs,2) as diurna_lei, round(zile*diurna_neimpozabila_zi*curs,2) as diurna_neimpozabila_lei, 
		(case when diurna_zi-diurna_neimpozabila_zi>0 then round(zile*diurna_zi*curs,2)-round(zile*diurna_neimpozabila_zi*curs,2) else 0 end) as diurna_impozabila_lei, idDiurna
	into #diurne_finale
	from #cdiurne

	if @genCorectii=1 and (@DiurneNeimpoz=1 or @DiurneImpoz=1) and exists (select 1 from #diurne_finale)
	Begin
--	stergere corectii generate anterior
		delete c 
		from corectii c
			left outer join LMfiltrare lu on lu.utilizator=@utilizator and lu.cod=c.Loc_de_munca
		where data=@datajos and (@marca='' or marca=@marca)
			and (@lm='' or c.Loc_de_munca like rtrim(@lm)+'%')
			and (@lista_lm=0 or lu.cod is not null) and (c.tip_corectie_venit=@CorectieDiurneNeimpoz or c.tip_corectie_venit=@CorectieDiurneImpoz)

--	generare corectii neimpozabile
		insert into corectii (Data, Marca, Loc_de_munca, Tip_corectie_venit, Suma_corectie, Procent_corectie, Suma_neta)
		select @dataJos, d.Marca, max(p.Loc_de_munca), @CorectieDiurneNeimpoz, sum(d.diurna_neimpozabila_lei), 0, 0
		from #diurne_finale d
			left outer join personal p on p.Marca=d.Marca
		group by d.Marca
		having sum(d.diurna_neimpozabila_lei)<>0

--	generare corectii impozabile
		insert into corectii (Data, Marca, Loc_de_munca, Tip_corectie_venit, Suma_corectie, Procent_corectie, Suma_neta)
		select @dataJos, d.Marca, max(p.Loc_de_munca), @CorectieDiurneImpoz, 
			sum((case when d.tip_diurna in ('B','') then d.diurna_impozabila_lei else 0 end)), 0, sum((case when d.tip_diurna='N' then d.diurna_impozabila_lei else 0 end))
		from #diurne_finale d
			left outer join personal p on p.Marca=d.Marca
		group by d.Marca
		having sum(d.diurna_impozabila_lei)<>0

--	stergere retineri generate anterior
		if @CodBenefDiurne<>''
		Begin	
			delete r 
			from resal r
				left outer join personal p on p.Marca=r.Marca
				left outer join LMfiltrare lu on lu.utilizator=@utilizator and lu.cod=p.Loc_de_munca
			where r.data=@datasus and (@marca='' or r.marca=@marca)
				and (@lm='' or p.Loc_de_munca like rtrim(@lm)+'%')
				and (@lista_lm=0 or lu.cod is not null) and r.Cod_beneficiar=@CodBenefDiurne

			insert into resal (Data, Marca, Cod_beneficiar, Numar_document, Data_document, Valoare_totala_pe_doc, Valoare_retinuta_pe_doc, Retinere_progr_la_avans, Retinere_progr_la_lichidare, 
				Procent_progr_la_lichidare, Retinut_la_avans, Retinut_la_lichidare, detalii)
			select @dataSus, d.Marca, @CodBenefDiurne, 'RDIURNE'+convert(varchar(2),day(d.Data_sfarsit)), @dataSus, 
				d.diurna_neimpozabila_lei+d.diurna_impozabila_lei, 0, 0, d.diurna_neimpozabila_lei+d.diurna_impozabila_lei, 0 ,0, 0, (select idDiurna for xml raw) as detalii
			from #diurne_finale d
			where d.diurna_neimpozabila_lei+d.diurna_impozabila_lei<>0
		End
	End
	else 
	Begin
		select marca, loc_de_munca, cod_functie, data_inceput, data_sfarsit, zile, tara, valuta, tip_diurna, curs, 
			diurna_zi, diurna_neimpozabila_zi, diurna, diurna_neimpozabila, diurna_impozabila,
			diurna_lei, diurna_neimpozabila_lei, diurna_impozabila_lei, idDiurna
		from #diurne_finale
	End

End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura pCalculDiurne (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch


/*
	exec pCalculDiurne '01/01/2014', '01/31/2014', null, null, 1
*/
