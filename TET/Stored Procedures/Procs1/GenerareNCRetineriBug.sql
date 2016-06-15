/* operatie pt. generare NC pt. retineri salariati (specific Bugetari) */
Create procedure GenerareNCRetineriBug
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @Continuare int=1 output, @NrPozitie int=0 output, @NumarDoc varchar(8)
As
Begin
	declare @userASiS char(10), @lista_lm int, @Sub char(9), @NCIndBug int, @NCAnActiv int, @NCAnActivCtChelt int, @NCAnActivDebite int, 
	@NCTaxePLM int, @NCRetCaDecont int, @NCNrDecNrDocRet int, @cDataDoc1 char(3), 
	@DebitAvansActiv varchar(20), @CreditAvansActiv varchar(20), @MarcaCreditAvans int, 
	@DebitAvansBoln varchar(20), @CreditAvansBoln varchar(20), 
	@DebitAvansOcazO varchar(20), @CreditAvansOcazO varchar(20), @MarcaCreditAvansOcazO int,
	@DebitAvansOcazP varchar(20), @CreditAvansOcazP varchar(20), @MarcaCreditAvansOcazP int,
	@DebitSumeIncas varchar(20), @CreditSumeIncas varchar(20), @MarcaCreditSumeIncas int,
	@DebitCMCas2 varchar(20), @CreditCMCas2 varchar(20)

	set transaction isolation level read uncommitted

begin try
	set @userASiS=dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@userASiS)

	set @Sub=dbo.iauParA('GE','SUBPRO')
	set @NCIndBug=dbo.iauParL('PS','NC-INDBUG')
	set @NCTaxePLM=dbo.iauParL('PS','N-C-TX-LM')
	set @NCAnActiv=dbo.iauParL('PS','N-C-A-ACT')
	set @NCAnActivDebite=dbo.iauParN('PS','N-C-A-ACT')
	set @NCAnActivCtChelt=dbo.iauParA('PS','N-C-A-ACT')
	set @NCRetCaDecont=dbo.iauParL('PS','NC-RET-M')
	set @NCNrDecNrDocRet=dbo.iauParL('PS','DEC-NDOCR')
	set @DebitAvansActiv=dbo.iauParA('PS','N-AV-ACTD')
	set @CreditAvansActiv=dbo.iauParA('PS','N-AV-ACTC')
	set @MarcaCreditAvans=dbo.iauParL('PS','N-AV-ACTC')
	set @DebitAvansBoln=dbo.iauParA('PS','N-AV-BOLD')
	set @CreditAvansBoln=dbo.iauParA('PS','N-AV-BOLC')
	set @DebitAvansOcazO=dbo.iauParA('PS','N-AV-COLD')
	set @CreditAvansOcazO=dbo.iauParA('PS','N-AV-COLC')
	set @MarcaCreditAvansOcazO=dbo.iauParL('PS','N-AV-COLC')
	set @DebitAvansOcazP=dbo.iauParA('PS','N-AV-CLPD')
	set @CreditAvansOcazP=dbo.iauParA('PS','N-AV-CLPC')
	set @MarcaCreditAvansOcazP=dbo.iauParL('PS','N-AV-CLPC')
	set @DebitSumeIncas=dbo.iauParA('PS','N-AV-RIDD')
	set @CreditSumeIncas=dbo.iauParA('PS','N-AV-RIDC')
	set @MarcaCreditSumeIncas=dbo.iauParL('PS','N-AV-RIDC')
	set @DebitCMCas2=dbo.iauParA('PS','N-C-CMC2D')
	set @CreditCMCas2=dbo.iauParA('PS','N-C-CMC2C')

	set @cDataDoc1=left(convert(char(10),@dataSus,101),2)+right(convert(char(10),@dataSus,101),1)

	if object_id('tempdb..#tmpretineri') is not null drop table #tmpretineri
	if object_id('tempdb..#nc_retineri') is not null drop table #nc_retineri
	if object_id('tempdb..#benret_conturi') is not null drop table #benret_conturi

	select Cod_beneficiar, Denumire_beneficiar, Obiect_retinere, Cont_debitor, Cont_creditor 
	into #benret_conturi 
	from benret

	insert into #benret_conturi
	select 'AVANSSALAR', 'Avans salar', '', @DebitAvansActiv, @CreditAvansActiv
	union all
	select 'CORECTIA-M', 'Suma incasata', '', @DebitSumeIncas, @CreditSumeIncas
	union all
	select 'AVANSSALAR_CM', 'Avans salar', '', @DebitAvansBoln, @CreditAvansBoln

	/* preluare date din procedura de calcul */
	CREATE TABLE dbo.#tmpretineri
		(NrOrdine int, Data datetime, Marca varchar(6), Indicator varchar(20), TipSuma varchar(30), Cod_beneficiar varchar(30), Suma float, 
			Explicatii varchar(1000), ExplicatiiRetineri varchar(1000), Numar varchar(10)) 

	insert into #tmpretineri
	exec calculOrdonantariSalarii @dataJos=@dataJos, @dataSus=@dataSus, @marca=@pmarca, @tipCalcul=4

	/* pozitiile de avans aferente concediilor medicale le trecem pe cod beneficiar separat prin care vom citi setarea pusa mai sus */
	update #tmpretineri set Cod_beneficiar='AVANSSALAR_CM', ExplicatiiRetineri=rtrim(ExplicatiiRetineri)+' - bolnavi'
	where Cod_beneficiar='AVANSSALAR' and TipSuma in ('CMUNITATE','CMFNUASS','CMFAAMBP')

	select a.Data, a.TipSuma, (case when @NCTaxePLM=1 then isnull(n.loc_de_munca,isnull(i.loc_de_munca,p.loc_de_munca)) else '' end) as loc_de_munca, 
		a.Indicator, 
		max(case when a.tipSuma='CMFNUASS' and c.Cont_creditor=@DebitCMCas2 then @CreditCMCas2 
			when a.TipSuma=a.Cod_beneficiar then b.Cont_debitor --Daca tip suma=od beneficiar inseamna ca retinerea are atasat cont creditor cu indicator si nu s-a efectuat spargerea pe tipuri de brut
			else c.Cont_creditor end) as Cont_debitor, 
		max(b.Cont_creditor) as Cont_creditor, 
		sum(a.Suma) as suma, a.Explicatii, a.Cod_beneficiar, a.ExplicatiiRetineri, 
		(case when @NCRetCaDecont=1 then a.marca else '' end) as marca, a.Numar, max(b.Obiect_retinere) as Obiect_retinere, 
		0 as idDiurna, row_number() over (partition by (case when @NCRetCaDecont=1 then a.marca else '' end) order by a.Cod_beneficiar) as NrCrtMarca
	into #nc_retineri
	from #tmpretineri a
		left outer join net n on n.data=a.data and n.marca=a.marca
		left outer join #benret_conturi b on b.Cod_beneficiar=a.Cod_beneficiar
		left outer join istPers i on i.data=a.data and i.marca=a.marca
		left outer join personal p on p.marca=a.marca
		outer apply (select * from config_nc c where c.Identificator=a.TipSuma and (n.Loc_de_munca like RTRIM(c.Loc_de_munca)+'%' 
			or c.Loc_de_munca is null and not exists (select 1 from config_nc c1 where n.Loc_de_munca like RTRIM(c1.Loc_de_munca)+'%'))) c
	group by a.Data, a.TipSuma, (case when @NCTaxePLM=1 then isnull(n.loc_de_munca,isnull(i.loc_de_munca,p.loc_de_munca)) else '' end), 
		(case when @NCRetCaDecont=1 then a.marca else '' end), a.Numar, 
		a.Indicator, a.Cod_beneficiar, a.Explicatii, a.ExplicatiiRetineri

	if exists (select 1 from syscolumns sc, sysobjects so where so.id = sc.id and so.name='resal' and sc.name= 'detalii')
	BEGIN
		update nr set nr.idDiurna=isnull(r.detalii.value('(/row/@idDiurna)[1]', 'int'), 0)
		from #nc_retineri nr inner join resal r on nr.Data=r.Data and nr.Marca=r.Marca and nr.Cod_beneficiar=r.Cod_beneficiar and nr.Numar=r.Numar_document
	end

	if exists (select * from sysobjects where name ='GenerareNCRetineriBugSP')
		exec GenerareNCRetineriBugSP @dataJos=@dataJos, @dataSus=@dataSus, @pMarca=@pMarca, @Continuare=@Continuare output, @NrPozitie=@NrPozitie output, @NumarDoc=@NumarDoc

	/* validare retineri cu conturi necompletate */
	if exists (select 1 from #nc_retineri where (Cont_debitor='' or Cont_creditor='') and suma<>0)
	Begin
		Select @Continuare=0
		declare @mesajEroare varchar(254)
		select top 1 @mesajEroare='Retinerea '+RTrim(Cod_beneficiar)+' - '+rtrim(ExplicatiiRetineri)+' nu are completat '+(case when Cont_debitor='' then 'contul debitor' else '' end)
			+(case when Cont_debitor='' AND Cont_creditor='' then ' si ' else '' end)+(case when Cont_creditor='' then 'contul creditor' else '' end)+'!'
			+' Verificati "Configurari contare", optiunea "Debite"!'
		from #nc_retineri where (Cont_debitor='' or Cont_creditor='') and suma<>0
		RAISERROR (@mesajEroare, 16, 1)
	End	

	/* scriere pozitii care vor ajunge in note contabile */
	insert into #docPozncon (Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Explicatii, Nr_pozitie, Loc_munca, Comanda, Jurnal)
	select @Sub, 'PS', @NumarDoc, Data, Cont_debitor, Cont_creditor, sum(Suma) as suma, 
		left((case when cod_beneficiar not in ('AVANSSALAR','AVANSSALAR_CM','CORECTIA-M') then 'Retinere - '+rtrim(max(r.Obiect_retinere))+' ' else '' end)+rtrim(max(r.ExplicatiiRetineri)),50) as explicatii, 
		@NrPozitie+ROW_NUMBER() over(order by r.Loc_de_munca, r.Cod_beneficiar), Loc_de_munca, '', ''
	from #nc_retineri r
		left outer join conturi c on c.cont=r.Cont_creditor
	where @NCRetCaDecont=0 or c.Sold_credit<>9
	group by Data, Cont_debitor, Cont_creditor, Loc_de_munca, Cod_beneficiar

	/* scriere pozitii care vor ajunge in plati incasari (retineri cu cont creditor atribuit de tip deconturi) */
	insert into #docPozplin (Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, Cont_corespondent, Suma,	
			Explicatii, Loc_de_munca, Comanda, Numar_pozitie, Cont_dif, Jurnal, idDiurna)
	select @Sub, r.Cont_creditor, Data, 
		(case when @NCNrDecNrDocRet=1 
			then r.Numar 
			else @cDataDoc1+rtrim(Marca)+(case when NrCrtMarca=1 then 'A' when NrCrtMarca=2 then 'B' 
				when NrCrtMarca=3 then 'C' when NrCrtMarca=4 then 'D' when NrCrtMarca=5 then 'E' 
				when NrCrtMarca=6 then 'F' when NrCrtMarca=7 then 'G' when NrCrtMarca=8 then 'H' else 'I' end) end), 
		'PD', '', '', Cont_debitor, Suma, left('Retinere marca - '+rtrim(r.marca)+' '+rtrim(r.Obiect_retinere)+' '+rtrim(r.ExplicatiiRetineri),50), 
		loc_de_munca, '', ROW_NUMBER() over(order by r.Loc_de_munca, r.marca, r.Cod_beneficiar), r.Marca, '', r.idDiurna
	from #nc_retineri r
		left outer join conturi c on c.cont=r.Cont_creditor
	where @NCRetCaDecont=1 and c.Sold_credit=9

	select @NrPozitie=isnull(max(Nr_pozitie),0)+1 from #docPozncon

	/* apelare procedura ce va completa date in notele contabile (loc de munca pentru costuri, jurnal, comanda generica pe pozitiile fara comanda) */
	exec completareNCsalarii @dataJos=@dataJos, @dataSus=@dataSus, @NumarDoc=@NumarDoc
end try

begin catch 
	declare @eroare varchar(500) 
	set @eroare=ERROR_MESSAGE()+ ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@eroare, 16, 1) 
end catch
End

/*
	exec GenNCRetineri '02/01/2011', '02/28/2011', '', 1, 0 
*/
