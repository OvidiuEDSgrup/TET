/* operatie pt. generare NC pt. retineri salariati */
Create procedure GenNCRetineri
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @Continuare int output, @NrPozitie int output
As
Begin
	declare @userASiS char(10), @lista_lm int, @multiFirma int, @Sub char(9), @NCIndBug int, @NCAnActiv int, @NCAnActivCtChelt int, @NCAnActivDebite int, 
	@NCTaxePLM int, @NCRetCaDecont int, @NCNrDecNrDocRet int, @Dafora int, @Somesana int, @NCSomesanaMures int, @Salubris int, 
	@ContCreditCMUnitate1 varchar(20), @ContCreditCMCas1 varchar(20), 
	@NumarDoc char(10), @NumarDocMarca char(10), @cDataDoc char(4), @cDataDoc1 char(3), @Explicatii char(50), 
	@ContDebitor varchar(20), @ContCreditor varchar(20), @Suma decimal(10,2), 
	@Data datetime, @Marca char(6), @gMarca char(6), @Cod_benef char(13), @gCod_benef char(13), 
	@gCont_debitor varchar(20), @gCont_creditor varchar(20), @gCont_banca char(30), @gActivitate varchar(10), 
	@gObiect_retinere char(30), @gDen_benef char(30), @gLm char(9), @gIndBug char(20), 
	@Numar_doc char(10), @Retinere_progr_avans decimal(10,2), @Retinere_progr_lich decimal(10,2), 
	@Retinut_la_avans decimal(10,2), @Retinut_la_lich decimal(10,2), @Loc_de_munca char(9), @Activitate varchar(10), @Den_benef char(30), @Cod_fiscal char(10), 
	@Cont_debitor varchar(20), @Cont_creditor varchar(20), @gAnalitic_marca int, @Analitic_marca int, @Obiect_retinere char(50), 
	@Sold_credit decimal(12,2), @Grup_marca char(9), @Cod_activitate decimal(8), @Sortare_lm varchar(20), 
	@Sortare_CF decimal(10), @Cont_banca char(30), @IndBug char(20), @vLm char(20),
	@NrCrtMarca int, @Total_benef decimal(10,2), @NetLucrat_marca decimal(10,2), @NetCMunitate_marca decimal(10,2), @NetCMCas_marca decimal(10,2), 
	@RetNeefSalubris decimal(10,2), @gfetch int, @idDiurna int
	set transaction isolation level read uncommitted

begin try
	set @cDataDoc=left(convert(char(10),@dataSus,101),2)+right(convert(char(10),@dataSus,101),2)
	set @cDataDoc1=left(convert(char(10),@dataSus,101),2)+right(convert(char(10),@dataSus,101),1)
	Set @NumarDoc='SAL'+@cDataDoc

	/*	apelez procedura specifica care sa inlocuiasca procedura standard (Pentru inceput se foloseste la Plexus Oradea, client Angajator) */
	if exists (select * from sysobjects where name ='GenNCRetineriSP' and type='P')
	begin
		exec GenNCRetineriSP @dataJos=@dataJos, @dataSus=@dataSus, @pMarca=@pMarca, @Continuare=@Continuare output, @NrPozitie=@NrPozitie output, @NumarDoc=@NumarDoc
		return
	end

	set @userASiS=dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@userASiS)
	set @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	set @Sub=dbo.iauParA('GE','SUBPRO')
	set @NCIndBug=dbo.iauParL('PS','NC-INDBUG')
	set @NCTaxePLM=dbo.iauParL('PS','N-C-TX-LM')
	set @NCAnActiv=dbo.iauParL('PS','N-C-A-ACT')
	set @NCAnActivDebite=dbo.iauParN('PS','N-C-A-ACT')
	set @NCAnActivCtChelt=dbo.iauParA('PS','N-C-A-ACT')
	set @NCRetCaDecont=dbo.iauParL('PS','NC-RET-M')
	set @NCNrDecNrDocRet=dbo.iauParL('PS','DEC-NDOCR')
	set @ContCreditCMUnitate1=dbo.iauParA('PS','N-C-CMU1C')	
	set @ContCreditCMCas1=dbo.iauParA('PS','N-C-CMC1C')
	set @Dafora=dbo.iauParL('SP','DAFORA')
	set @Somesana=dbo.iauParL('SP','SOMESANA')
	set @Salubris=dbo.iauParL('SP','SALUBRIS')
	set @NCSomesanaMures=dbo.iauParL('PS','NC-SMURES')

	if OBJECT_ID('tempdb..#resal') is not null drop table #resal
	select Data, Marca, Cod_beneficiar, Numar_document, Data_document, Valoare_totala_pe_doc, Valoare_retinuta_pe_doc, 
		Retinere_progr_la_avans, Retinere_progr_la_lichidare, Procent_progr_la_lichidare, Retinut_la_avans, Retinut_la_lichidare, 0 as idDiurna
	into #resal 
	from resal a 
	where a.data=@dataSus and (@pMarca='' or a.Marca=@pMarca) and a.Marca<>''

	if exists (select 1 from syscolumns sc, sysobjects so where so.id = sc.id and so.name='resal' and sc.name= 'detalii')
	BEGIN
		update #resal set idDiurna=isnull(r.detalii.value('(/row/@idDiurna)[1]', 'int'), 0)
		from #resal dr inner join resal r on dr.Data=r.Data and dr.Marca=r.Marca and dr.Cod_beneficiar=r.Cod_beneficiar and dr.Numar_document=r.Numar_document
	end

	declare NCRetineri cursor for
	select a.Data, a.Marca, a.Cod_beneficiar, a.Numar_document, a.Retinere_progr_la_avans, a.Retinere_progr_la_lichidare,  
		a.Retinut_la_avans, a.Retinut_la_lichidare, isnull(n.loc_de_munca,isnull(i.loc_de_munca,p.loc_de_munca)), b.Denumire_beneficiar, 
		b.Cod_fiscal, b.Cont_debitor, b.Cont_creditor, b.Analitic_marca, b.Obiect_retinere, c.Sold_credit, 
		(case when @Dafora=1 or @NCRetCaDecont=1 then a.marca when @Somesana=1 or @NCTaxePLM=1 then isnull(n.loc_de_munca,isnull(i.loc_de_munca,p.loc_de_munca)) else '' end) as Grup_marca, 
		(case when @NCAnActiv=1 and not(@Dafora=1 or @NCRetCaDecont=1) then p.Activitate else '' end) as Activitate, 
		(case when @Somesana=1 or @NCTaxePLM=1 then isnull(n.loc_de_munca,isnull(i.loc_de_munca,p.loc_de_munca)) 
			when @Dafora=1 or @NCRetCaDecont=1 then a.Marca else a.Cod_beneficiar end) as Sortare_lm, 
		(case when @Salubris=1 then convert(float,left(b.Cod_fiscal,9)) else 0 end) as Sortare_CF, b.Cont_banca, a.idDiurna
	from #resal a 
		left outer join istpers i on i.data=a.data and i.marca=a.marca
		left outer join #net n on n.data=a.data and n.marca=a.marca
		left outer join infopers f on f.marca=a.marca
		left outer join personal p on p.marca=a.marca
		left outer join benret b on b.cod_beneficiar=a.cod_beneficiar
		left outer join conturi c on c.Subunitate=@Sub and c.cont=b.cont_creditor
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=i.loc_de_munca
	where a.data=@dataSus and (@pMarca='' or a.Marca=@pMarca) and a.Marca<>''
		and (@NCSomesanaMures=0 or n.loc_de_munca between '40' and '40ZZZ')
		and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null)
	order by Activitate, Sortare_lm, Sortare_CF, (case when @NCRetCaDecont=1 and c.Sold_credit=9 then a.marca else '' end), a.Cod_beneficiar

	open NCRetineri
	fetch next from NCRetineri into @Data, @Marca, @Cod_benef, @Numar_doc, @Retinere_progr_avans, @Retinere_progr_lich, 
		@Retinut_la_avans, @Retinut_la_lich, @Loc_de_munca, @Den_benef, @Cod_fiscal, @Cont_debitor, @Cont_creditor, 
		@Analitic_marca, @Obiect_retinere, @Sold_credit, @Grup_marca, @Activitate, @Sortare_lm, @Sortare_CF, @Cont_banca, @idDiurna
	set @gfetch=@@fetch_status
	set @gMarca=@Marca
	set @gCod_benef=@Cod_benef
	set @gCont_debitor=@Cont_debitor
	set @gCont_creditor=@Cont_creditor
	set @gCont_banca=@Cont_banca
	set @gActivitate=@Activitate
	set @gObiect_retinere=@Obiect_retinere
	set @gDen_benef=@Den_benef
	set @gLm=@Loc_de_munca
	set @gIndBug=(case when @NCIndBug=1 then @Cont_banca else '' end)
	set @gAnalitic_marca=@Analitic_marca

	While @gfetch = 0 
	Begin
		Set @NrCrtMarca=0
		Set @NumarDocMarca=''
		Set @NetLucrat_marca=0
		Set @NetCMunitate_marca=0
		Set @NetCMCas_marca=0
		if @Salubris=1 
			exec NCNetLucratCM @dataJos, @dataSus, @Marca, @NetLucrat_marca output, @NetCMunitate_marca output, @NetCMCas_marca output
		Set @Total_benef=0
		while (@NCRetCaDecont=0 and (not(@Somesana=1 or @NCTaxePLM=1) or @Loc_de_munca=@gLm) and @Cod_benef = @gCod_benef
			or @NCRetCaDecont=1 and @marca = @gMarca) and @gfetch = 0
		Begin
			Set @Total_benef=@Total_benef+@Retinut_la_avans+@Retinut_la_lich
			Set @RetNeefSalubris=0
			if @Salubris=1 and @Cod_benef='1256' and @Retinut_la_avans+@Retinut_la_lich<@Retinere_progr_avans+@Retinere_progr_lich
				Set @RetNeefSalubris=@Retinere_progr_avans+@Retinere_progr_lich-(@Retinut_la_avans+@Retinut_la_lich)
			if @Sold_credit=9 or @RetNeefSalubris>0
			Begin
				Set @NrCrtMarca=@NrCrtMarca+1
				Set @NumarDocMarca=(case when @NCNrDecNrDocRet=1 then @Numar_doc 
				else @cDataDoc1+rtrim(@Marca)+(case when @NrCrtMarca=1 then 'A' when @NrCrtMarca=2 then 'B' 
				when @NrCrtMarca=3 then 'C' when @NrCrtMarca=4 then 'D' when @NrCrtMarca=5 then 'E' 
				when @NrCrtMarca=6 then 'F' when @NrCrtMarca=7 then 'G' when @NrCrtMarca=8 then 'H' else 'I' end) end)
			End	
			Set @NumarDoc=(case when (@Dafora=1 or @NCRetCaDecont=1) and @Sold_credit=9 then @NumarDocMarca else 'SAL'+@cDataDoc end)
--	validare daca cont debitor/creditor necompletate in Configurari\Contare\Debite
			if (@Cont_debitor='' or @Cont_creditor='') and @Retinut_la_avans+@Retinut_la_lich<>0
			Begin
				Select @Continuare=0
				declare @mesajEroare varchar(254)
				set @mesajEroare='Retinerea '+RTrim(@Cod_benef)+' - '+rtrim(@Den_benef)+' nu are completat '+(case when @Cont_debitor='' then 'contul debitor' else '' end)
					+(case when @Cont_debitor='' AND @Cont_creditor='' then ' si ' else '' end)+(case when @Cont_creditor='' then 'contul creditor' else '' end)+'!'
					+' Verificati "Configurari contare", optiunea "Debite"!'
				RAISERROR (@mesajEroare, 16, 1)
			End	

			Set @ContDebitor=rtrim(@Cont_debitor)+(case when @NCAnActiv=1 and @NCAnActivCtChelt=0 then '.'+rtrim(convert(char(3),@Cod_activitate)) else '' end)
			Set @ContCreditor=rtrim(@Cont_creditor)+(case when @NCAnActivDebite=1 then '.'+rtrim(convert(char(3),@Cod_activitate)) 
				else (case when @Dafora=1 or @NCRetCaDecont=1 then '' else '.'+rtrim(@Marca) end) end)
			Set @Suma=(case when @Salubris=1 and @Cod_benef='1256' then @Retinere_progr_avans+@Retinere_progr_lich 
				else @Retinut_la_avans+@Retinut_la_lich end)
			Set @Explicatii='Retinere marca - '+rtrim(@marca)+' '+rtrim(@Obiect_retinere)+' '+rtrim(@Den_benef)
			Set @vLm=(case when @Dafora=1 or @NCRetCaDecont=1 or @NCTaxePLM=1 then @Loc_de_munca else '' end)
			Set @IndBug=(case when @NCIndBug=1 then @Cont_banca else '' end)
			if (@Analitic_marca=1 or @Dafora=1 or @NCRetCaDecont=1) and @Continuare=1 
			Begin
				if (@Salubris=0 or @NetCMUnitate_marca=0 and @NetCMCas_marca=0)
					exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @Suma, @NumarDoc, 
					@Explicatii, @Continuare output, @NrPozitie output, @vLm, '', @IndBug, 0, @Marca, '', 0, @idDiurna
				Set @Explicatii='Retinere marca - neefectuata '+rtrim(@marca)+' '+rtrim(@Obiect_retinere)+' '+rtrim(@Den_benef)
				if @RetNeefSalubris<>0
				Begin
					exec scriuNCsalarii @Data, '4282.1', @Cont_debitor, @RetNeefSalubris, @NumarDocMarca, 
					@Explicatii, @Continuare output, @NrPozitie output, @vLm, '', @IndBug, 0, @Marca, '', 0, 0
				End	
			End		
			if @Salubris=1 and (@NetCMUnitate_marca>0 and @Cont_debitor<>@ContCreditCMUnitate1 or @NetCMCas_marca>0 and @Cont_debitor<>@ContCreditCMCas1)
				exec GenNCRetLucratCM @dataJos, @dataSus, @Marca, @Continuare output, @NumarDoc, @Explicatii, @NrPozitie output, 
				@Loc_de_munca, @Cont_debitor, @Cont_creditor, @NetLucrat_marca output, @NetCMUnitate_marca output, @NetCMCas_marca output, 
				@Suma, @Cod_benef
		
			fetch next from NCRetineri into @Data, @Marca, @Cod_benef, @Numar_doc, @Retinere_progr_avans, @Retinere_progr_lich, 
			@Retinut_la_avans, @Retinut_la_lich, @Loc_de_munca, @Den_benef, @Cod_fiscal, @Cont_debitor, @Cont_creditor, 
			@Analitic_marca, @Obiect_retinere, @Sold_credit, @Grup_marca, @Activitate, @Sortare_lm, @Sortare_CF, @Cont_banca, @idDiurna
		set @gfetch=@@fetch_status
		End
		if @gAnalitic_marca=0 and @Dafora=0 and @NCRetCaDecont=0 and @Continuare=1
		Begin
			Set @ContDebitor=rtrim(@gCont_debitor)+(case when @NCAnActiv=1 and @NCAnActivCtChelt=0 then '.'+rtrim(@gActivitate) else '' end)
			Set @ContCreditor=rtrim(@gCont_creditor)+(case when @NCAnActivDebite=1 then '.'+rtrim(@gActivitate) else '' end)
			Set @Explicatii='Retinere - '+rtrim(@gObiect_retinere)+' '+rtrim(@gDen_benef)
			Set @vLm=(case when @Dafora=1 or @NCTaxePLM=1 then @gLm else '' end)
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @Total_benef, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @vLm, '', @gIndBug, 0, '', '', 0, 0
		End
		Set @gMarca=@Marca
		Set @gCod_benef=@Cod_benef
		set @gCont_debitor=@Cont_debitor
		set @gCont_creditor=@Cont_creditor
		set @gCont_banca=@Cont_banca
		set @gActivitate=@Activitate
		set @gObiect_retinere=@Obiect_retinere
		set @gDen_benef=@Den_benef
		set @gLm=@Loc_de_munca
		set @gIndBug=(case when @NCIndBug=1 then @Cont_banca else '' end)
		set @gAnalitic_marca=@Analitic_marca
	End
	close NCRetineri
	Deallocate NCRetineri
end try

begin catch 
	declare @eroare varchar(500) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
End

/*
	exec GenNCRetineri '02/01/2011', '02/28/2011', '', 1, 0 
*/
