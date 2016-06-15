/*
	Exemplu rulare:
		declare @datalunii datetime='2014-10-31', @pxml xml=convert(xml,'<row tert="11000"/>')
		EXEC inchidereProvizioane @sesiune=NULL, @parXML= @pxml, @data_lunii=@datalunii
		exec fainregistraricontabile @datasus=@datalunii
	
	(Permite si filtru pe un singur TERT)

	Parametri specifici lucrului cu Provizioane (toti parametri pe tip GE)

		1. PROVIZ	->	val_logica: determina daca pe aceasta BD se lucreaza cu provizioane
		2. CONTCIN	->	val_alfanumerica: contul de clienti incerti. Valoarea implicita: 4118
		3. CONTCPR	->	val_alfanumerica: contul de cheltuiala pentru proviz. Valoarea implicita: 681
		4. CONTTPR	->	val_alfanumerica: contul de trecere provizion. Valoarea implicita: 491
		5. CONTVPR	->	val_alfanumerica: contul de venituri pentru provizioane. Valoarea implicita: 718
		6. CONTBENEF->	val_alfanumerica: contul de clienti. Valoarea implicita: 4111

	Reguli constituire provizion factura:
		1. Mai mult de 270 de zile de la scadenta facturii
		2. Beneficiarul este in faliment, lucru specificat in terti.detalii XML coloana data_faliment si provizioane='F' (faliment)

	Alte observatii:
		Se vor observa valorile variabilelor din terti.detalii
			- provizioane (D,N sau F- Da, Nu, Faliment): lipsa acesteia inseamna DA
			- data_faliment: completarea ei in pereche cu provizioane=F => tert in faliment
		
		In cazul "mai special" al falimentului
			- daca s-a operat conform modului de lucru ASiS: operare de FB cu minus din 654 (sau analitic) programul va considera acest tip de documente
				ca fiind "incasari" ale facturilor la care s-au calculat provizioane, pt. a putea inchide si provizioanele (nota de "incasare fact")

		Calcul de dif. de curs la facturi provizionate
			- programul gen. NC cu val= procent*val.nota de diferenta
			- mecanismul: 
				- se cauta diferentele de curs la facturi provizionate, diferente generate in luna curenta
				- conform formulei de mai sus se genereaza nota contabila de dif. (vezi explicatii:"Dif.curs. fact. proviz.") si
					numar_document like 'DFP%'
				- nu se gen. aceste note de diferente in luna in care s-a constituit provizionul

		Numere document
			- numerele de document sunt de forma PDLLAAAA, PCLLAAAA in PoznCon si CPLLAAAA in pozadoc

*/
create procedure inchidereProvizioane @sesiune varchar(50), @parXML xml, @data_lunii datetime
as
begin try
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	declare 
		@cuProvizioane bit,@cCliIncerti varchar(40),@contFactBenef varchar(40), @cCheltProv varchar(40), @cTrecProv varchar(40), @cVenProv varchar(40), @bom_data_lunii datetime, 
		@sub varchar(9), @xmlNCon xml, @utilizator varchar(20), @parXMLFact xml, @numar_doc varchar(6), @tert varchar(20)

	/* Verificam daca se lucreaza cu provizioane */
	select @cuProvizioane=val_logica from par where tip_parametru='GE' and parametru='PROVIZ'
	select @cuProvizioane
	IF ISNULL(@cuProvizioane,0)=0
		return

	select @bom_data_lunii=dbo.bom(@data_lunii)
	select @sub=RTRIM(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'
	select @utilizator=dbo.fIaUtilizator(null)
	if isnull(@utilizator,'')=''
		set @utilizator='INCHPROV'

	/* Citim conturile cu valori implicite*/
	select @cCliIncerti=RTRIM(Val_alfanumerica) from par where tip_parametru='GE' and parametru='CONTCIN'
	IF @cCliIncerti IS NULL
		set @cCliIncerti='4118'

	select @cCheltProv=RTRIM(Val_alfanumerica) from par where tip_parametru='GE' and parametru='CONTCPR'
	IF @cCheltProv IS NULL
		set @cCheltProv='681'

	select @cTrecProv=RTRIM(Val_alfanumerica) from par where tip_parametru='GE' and parametru='CONTTPR'
	IF @cTrecProv IS NULL
		set @cTrecProv='491'

	select @cVenProv=RTRIM(Val_alfanumerica) from par where tip_parametru='GE' and parametru='CONTVPR'
	IF @cVenProv IS NULL
		set @cVenProv='781'

	select @contFactBenef=RTRIM(Val_alfanumerica) from par where tip_parametru='GE' and parametru='CONTBENEF'
	IF @contFactBenef IS NULL
		set @contFactBenef='4111'	

	select
		@tert = NULLIF(@parXML.value('(/*/@tert)[1]','varchar(20)'),'')

	declare @sterg xml
	set @sterg=(select @data_lunii data_lunii, @tert tert for xml raw, type)

	exec stergereProvizioane @sesiune=@sesiune, @parXML=@sterg

	select	
		@numar_doc = convert(varchar(2), MONTH(@data_lunii))+convert(varchar(4), YEAR(@data_lunii))

	/* Generam provizioanele in #provizioane */
	
	IF OBJECT_ID('tempdb..#provizioane') IS NOT NULL
		DROP TABLE #provizioane
	
	IF OBJECT_ID('tempdb..#prov_existente') IS NOT NULL
		DROP TABLE #prov_existente

	IF OBJECT_ID('tempdb..#terti_faliment') IS NOT NULL
		DROP TABLE #terti_faliment
	
	/* Luam tertii care sunt in faliement cu data de faliment*/
	select
		RTRIM(tert) tert, detalii.value('(/*/@data_faliment)[1]','datetime') data_faliment
	into #terti_faliment	
	from Terti where detalii.value('(/*/@data_faliment)[1]','datetime') IS NOT NULL and ISNULL(detalii.value('(/*/@provizioane)[1]','varchar(2)'),'D')='F' and (@tert IS NULL or tert=@tert)

	/* Luam facturile in SOLD carora ar trebui sa le generam provizion (>270 sau faliment) */
	/* Pregatim informatiile despre provizioane, din facturi*/
	/* S-a inlocuit fFacturiCen cu pFacturi */
	if OBJECT_ID('tempdb..#pfacturi') IS NOT NULL
		DROP TABLE #pfacturi
	CREATE TABLE #pfacturi (subunitate varchar(9))
	exec CreazaDiezFacturi @numeTabela='#pfacturi'
	set @parXMLFact=(select 'B' as furnbenef, @data_lunii as datasus, 1 as cen, 1 as grtert, 1 as grfactura, 0.01 as soldmin, 0 as semnsold, @tert tert for xml raw)
	exec pFacturi @sesiune=@sesiune, @parXML=@parXMLFact

	SELECT
		RTRIM(f.tert) tert,RTRIM(f.Factura) factura, f.sold* (case when (tf.tert IS NOT NULL and tf.data_faliment<=@data_lunii) then 100.0 else 30.0 end)/100.0 debit,convert(float,0.0) credit, convert(float,0.0) incasat, 
		(case when (tf.tert IS NOT NULL and tf.data_faliment<=@data_lunii) then 100.0 else 30.0 end) procent,
		RTRIM(f.loc_de_munca) lm, RTRIM(f.comanda) comanda, f.data data_facturii, f.data_scadentei data_scadentei, f.sold sold, f.cont_factura cont, f.valuta valuta, f.curs curs, f.sold_valuta, @cTrecProv cont_prov
	into #provizioane
	FROM #pfacturi f	
	JOIN Terti t on t.tert=f.tert
	LEFT JOIN #terti_faliment tf on tf.tert=f.tert 
	where 
		f.Sold>0.01 and -- facturi cu sold
		(DATEDIFF(DAY,f.data_scadentei,@data_lunii)>=270 OR (tf.tert IS NOT NULL and tf.data_faliment<=@data_lunii)) and-- conditia de nr. de zile sau tert faliment		
		f.cont_factura like @contFactBenef+'%' and --sa nu fie vorba decat de facturi propriu-zise
		ISNULL(detalii.value('(/*/@provizioane)[1]','varchar(2)'),'D')!='N' -- daca s-a exceptat tertul explicit nu ii calculam proviz.(tert in grup si alte cazuri)
	
	/* Daca exista si alte reguli la constituire proviz. se pot adauga in SP prin #provizioane */
	if exists (select * from sysobjects where name ='inchidereProvizioaneSP')
		exec inchidereProvizioaneSP @sesiune=@sesiune, @parXML = @parXML, @data_lunii = @data_lunii

	/* Ne ocupam de Provizioanele existente, care trebuie trecute luna (sold>0) */
	select
		tert, factura, debit, credit, procent, p.cont cont_prov
	into #prov_existente
	from (select tert, factura, debit, credit, procent, cont, rank() over(partition by tert, factura order by datalunii desc) rk	from Provizioane where (@tert IS NULL OR tert=@tert)) p
	where p.rk=1 and (ISNULL(debit,0)-ISNULL(credit,0))>0.0

	/* 
		Aici avem in vedere: 
		Ex. facturile care s-au stins in cursul lunii, tot trebuie sa le facem calculul la proviz.
		Ex.: tert in faliment la data lunii la care s-au stins facturile prin FB cu minus (mod de lucru ASiS)
	*/
	truncate table #pfacturi
	set @parXMLFact=(select 'B' as furnbenef, DATEADD(DAY, -1, @bom_data_lunii) as datasus, 1 as cen, 1 as grtert, 1 as grfactura, 0.01 as soldmin, 0 as semnsold, @tert tert for xml raw)
	exec pFacturi @sesiune=@sesiune, @parXML=@parXMLFact

	insert into #provizioane (tert, factura, debit, credit, incasat, procent, lm, comanda, data_facturii, data_scadentei, sold, cont, valuta, curs, sold_valuta, cont_prov)
	select
		pe.tert, pe.factura,(case when fc.tert IS NOT NULL then fc.sold-pe.debit else pe.debit end), pe.credit, 0,
		(case when (tf.tert IS NOT NULL and tf.data_faliment<=@data_lunii) and pe.procent<>100 then 100 else pe.procent end), 
		ISNULL(fc.loc_de_munca,''),ISNULL(fc.comanda,''),fc.data,fc.data_scadentei, ISNULL(fc.sold,0), @cCliIncerti, '', 0, 0, pe.cont_prov
	from #prov_existente pe
	INNER JOIN #pfacturi fc on fc.tert=pe.tert and fc.factura=pe.factura/* Pt. sold la inceput de luna si lm, comanda*/	
	LEFT JOIN #terti_faliment tf on tf.tert=pe.tert /* Caz ca a falimentat vre-unul luna aceasta*/
	LEFT JOIN #provizioane p on pe.tert=p.tert and pe.factura=p.factura /*PT. a nu dubla*/
	where p.tert IS NULL
		
	/* Luam incasarile*/
	IF OBJECT_ID('tempdb.dbo.#tmp_incasari') IS NOT NULL
		drop table #tmp_incasari
	
	/*
		Vom considera "incasari" (intrumente de stingere a soldului facturii) 
			INCASARILE "CLASICE" +	
			FB (facturi beneficiar) cu MINUS pe cont like 654 -> documente operate la terti declarati faliment pt. chelt. si ded.tva.
	*/
	/* se preiau datele in tabela #docfacturi prin procedura pFacturi (in locul functiei fFacturi) */
	if object_id('tempdb..#docfacturi') is not null drop table #docfacturi
	create table #docfacturi (furn_benef char(1))
	exec CreazaDiezFacturi @numeTabela='#docfacturi'
	set @parXMLFact=(select 'B' as furnbenef, convert(char(10),@bom_data_lunii,101) as datajos, convert(char(10),@data_lunii,101) as datasus, 1 as strictperioada, @tert tert for xml raw)
	exec pFacturi @sesiune=@sesiune, @parXML=@parXMLFact

	select 
		ft.tert,ft.factura,SUM((case when ft.tip='FB' then ABS(ft.valoare+ft.tva) else ft.achitat end)) as sumaincpla
	into #tmp_incasari
	from #docfacturi ft	
	inner join facturi f on f.tip=0x46 and ft.tert=f.tert and ft.factura=f.factura
	inner join #prov_existente p on ft.tert=p.tert and ft.factura=p.factura -- conteaza numai incasarile care se refera la un provizion anterior
	where abs(ft.achitat)>0.001 OR (ft.tip='FB' and ft.cont_coresp like '654%' and ft.valoare<0)
	group by ft.tert,ft.factura

	/* Setam valoarea incasata din factura in luna curenta */
	update p 
		set p.incasat=pin.sumaincpla
	from #provizioane p
	JOIN #tmp_incasari pin on pin.Factura=p.Factura and pin.tert=p.Tert

	/* 
		Avand in vedere tot ce s-a calculat pana in acest moment, pregatim pt. scrierea provizioanelor
		DEBIT/CREDIT (daca s-a schimbat procentul, incasare ponderata, etc)
	*/
	update p set 
		debit=round(convert(decimal(17,5),ISNULL((case when p.procent<>pn.procent then p.debit else pn.debit end),0)),2),
		credit=round(convert(decimal(17,5),ISNULL(p.incasat,0.0)*p.procent/100.0+pn.credit),2) 
	from #provizioane p
	JOIN #prov_existente pn on p.factura=pn.factura and p.tert=pn.tert	

	/* Scriem provizioanele NOI sau cu modificari in Provizioane */
	insert into Provizioane(datalunii, tert, factura, debit, credit, procent, cont)
	select @data_lunii, p.tert, p.factura, p.debit, p.credit, p.procent, p.cont_prov
	from #provizioane p
	
	/* Scriem provizioanele (fara modificari) care trebuie doar trecute luna in Provizioane */
	insert into Provizioane(datalunii, tert, factura, debit, credit, procent, cont)
	select @data_lunii, pe.tert, pe.factura, pe.debit, pe.credit, pe.procent, pe.cont_prov
	from #prov_existente pe
	LEFT JOIN #provizioane p on pe.tert=p.tert and pe.factura=p.factura
	where p.tert IS NULL

	/* Scriem documentele aferente acestor Provizioane */
	IF OBJECT_ID('tempdb..#ncon_prov') IS NOT NULL
		DROP TABLE #ncon_prov

	CREATE TABLE #ncon_prov(
		tip varchar(2),
		numar varchar(13) ,
		data datetime,
		cont_debitor varchar(40) ,
		cont_creditor varchar(40),
		suma decimal(17,2),
		valuta varchar(3) ,
		curs decimal(17,2) ,
		suma_valuta decimal(17,2),
		ex varchar(50),
		lm varchar(9),
		comanda varchar(40) ,
		tert varchar(13) ,
		numar_pozitie int
	)

	IF OBJECT_ID('tempdb..#adoc_prov') IS NOT NULL
		DROP TABLE #adoc_prov

	CREATE TABLE #adoc_prov(
		[Subunitate] [char](9) NOT NULL,
		[Numar_document] [char](8) NOT NULL,
		[Data] [datetime] NOT NULL,
		[Tert] [char](13) NOT NULL,
		[Tip] [char](2) NOT NULL,
		[Factura_stinga] [char](20) NOT NULL,
		[Factura_dreapta] [char](20) NOT NULL,
		[Cont_deb] [varchar](40) NULL,
		[Cont_cred] [varchar](40) NULL,
		[Suma] [float] NOT NULL,
		[TVA11] [float] NOT NULL,
		[TVA22] [float] NOT NULL,
		[Utilizator] [char](10) NOT NULL,
		[Data_operarii] [datetime] NOT NULL,
		[Ora_operarii] [char](6) NOT NULL,
		[Numar_pozitie] [int] NOT NULL,
		[Tert_beneficiar] [char](13) NOT NULL,
		[Explicatii] [char](50) NOT NULL,
		[Valuta] [char](3) NOT NULL,
		[Curs] [float] NOT NULL,
		[Suma_valuta] [float] NOT NULL,
		[Cont_dif] [varchar](40) NULL,
		[suma_dif] [float] NOT NULL,
		[Loc_munca] [char](9) NOT NULL,
		[Comanda] [char](40) NOT NULL,
		[Data_fact] [datetime] NOT NULL,
		[Data_scad] [datetime] NOT NULL,
		[Stare] [smallint] NOT NULL,
		[Achit_fact] [float] NOT NULL,
		[Dif_TVA] [float] NOT NULL,
		[Jurnal] [char](3) NOT NULL
	)

	IF OBJECT_ID('tempdb.dbo.#legaturi_prov') IS NOT NULL
		DROP TABLE #legaturi_prov

	CREATE TABLE #legaturi_prov (idProvizion int, idLegatura int)

	/*Documente tip CB de constituire de provizioane- o singura data pt. o factura*/
	insert into #adoc_prov(Subunitate, Numar_document, Data, Tert, Tip, Factura_stinga, Factura_dreapta, Cont_deb, Cont_cred, Suma, TVA11, TVA22, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Tert_beneficiar, Explicatii, Valuta, Curs, 
		Suma_valuta, Cont_dif, suma_dif, Loc_munca, Comanda, Data_fact, Data_scad, Stare, Achit_fact, Dif_TVA, Jurnal)	
	select
		@sub,'CP'+@numar_doc,@data_lunii,p.tert,'CB', p.factura, p.factura,@cCliIncerti,@contFactBenef,pn.sold, 
		24,0, @utilizator, GETDATE(), replace(convert(varchar(8), GETDATE(),108),':',''), p.idProvizion,'',left('Provizion fact. '+rtrim(p.factura)+' - '+t.denumire,50), pn.valuta, 
		convert(decimal(15,2),(case when pn.valuta<>'' and pn.sold_valuta>0.0 then pn.sold/pn.sold_valuta else 0 end )), pn.sold_valuta,'',0,pn.lm, pn.comanda, pn.data_facturii, pn.data_scadentei,0,
		pn.sold_valuta,0,''		
	from  Provizioane p
	INNER JOIN #provizioane pn on pn.factura=p.factura and pn.tert=p.tert
	LEFT JOIN #prov_existente pe on pe.tert=p.tert and pe.factura =p.factura
	JOIN Terti t on t.tert=p.tert
	where p.datalunii=@data_lunii and pe.tert IS NULL and pn.cont<>@cCliIncerti

	update #adoc_prov set valuta='' where curs=0

	/*
		NC de constituiri de provizioane- poate fi de mai multe ori pt. o factura
		Ex. se constituie cu 30% , iar in lunile urmatoare tertul intra in faliment, programul genereaza si pt. "Restul" din soldul facturii NC de const. prov.
	*/
	insert into #ncon_prov (tip, numar, data ,cont_debitor, cont_creditor, suma, valuta, curs, suma_valuta, ex, lm ,comanda ,tert, numar_pozitie)
	select
		'NC','PD'+@numar_doc,@data_lunii, @cCheltProv , p.cont , CONVERT(DECIMAL(17,2),p.debit),'',convert(decimal(17,2),0),convert(decimal(17,2),0),
		left('Provizion fact. '+rtrim(p.factura)+' - '+t.denumire,50),pn.lm, pn.comanda, p.tert, p.idProvizion
	from  Provizioane p
	JOIN Terti t on t.tert=p.tert
	INNER JOIN #provizioane pn on pn.factura=p.factura and pn.tert=p.tert
	LEFT JOIN #prov_existente pe on pe.tert=p.tert and pe.factura =p.factura	
	where p.datalunii=@data_lunii and ((pe.tert IS NULL and pn.cont<>@cCliIncerti) OR (pe.tert IS NOT NULL and p.procent<>pe.procent))

	/* NC de incasari de facturi cu provizioane- pot fi multiple/factura */
	insert into #ncon_prov (tip, numar, data ,cont_debitor, cont_creditor, suma, valuta, curs, suma_valuta, ex, lm ,comanda ,tert, numar_pozitie)
	select
		'NC','PC'+@numar_doc, @data_lunii, p.cont cont_debitor,@cVenProv cont_creditor, CONVERT(DECIMAL(17,2),p.credit-ISNULL(pe.credit,0)),'',convert(decimal(17,2),0),convert(decimal(17,2),0), 
		left('Inc. prov. fact. '+rtrim(p.factura)+' - '+t.denumire,50), pn.lm, pn.comanda, p.tert, p.idProvizion
	from  Provizioane p
	INNER JOIN #provizioane pn on pn.factura=p.factura and pn.tert=p.tert
	LEFT JOIN #prov_existente pe on pe.tert=p.tert and pe.factura =p.factura
	JOIN Terti t on t.tert=p.tert
	where ABS(ISNULL(pe.credit,0)-ISNULL(p.credit,0))>0.01 and p.datalunii=@data_lunii 

	insert into PozADoc(Subunitate, Numar_document, Data, Tert, Tip, Factura_stinga, Factura_dreapta, Cont_deb, Cont_cred, Suma, TVA11, TVA22, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Tert_beneficiar, Explicatii, Valuta, Curs, 
		Suma_valuta, Cont_dif, suma_dif, Loc_munca, Comanda, Data_fact, Data_scad, Stare, Achit_fact, Dif_TVA, Jurnal)
	OUTPUT Inserted.idPozadoc, Inserted.Numar_pozitie INTO #legaturi_prov (idLegatura, idProvizion)
	select 
		Subunitate, Numar_document, Data, Tert, Tip, Factura_stinga, Factura_dreapta, Cont_deb, Cont_cred, Suma, TVA11, TVA22, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Tert_beneficiar, Explicatii, Valuta, Curs, 
		Suma_valuta, Cont_dif, suma_dif, Loc_munca, Comanda, Data_fact, Data_scad, Stare, Achit_fact, Dif_TVA, Jurnal
	FROM #adoc_prov

	update p
		set idPozADoc=lp.idLegatura
	from Provizioane p
	JOIN #legaturi_prov lp on lp.idProvizion=p.idProvizion

	truncate table #legaturi_prov

	insert into PozNCon (Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, Nr_pozitie, Loc_munca, Comanda, Tert, Jurnal, detalii)
	OUTPUT Inserted.idPozncon, Inserted.nr_pozitie INTO #legaturi_prov (idLegatura, idProvizion)
	select @sub, 'NC',numar, data, cont_debitor, cont_creditor, suma, valuta, curs, suma_valuta, ex, @utilizator, GETDATE(), RTRIM(replace(convert(char(8), getdate(), 108), ':', '')), 
		numar_pozitie, lm, comanda, tert,'', NULL
	from #ncon_prov where abs(suma)>=0.01

	update p
		set idPozNCon=lp.idLegatura
	from Provizioane p
	JOIN #legaturi_prov lp on lp.idProvizion=p.idProvizion

	/* 
		Diferente de curs la facturile provizionate: descris mai sus
	*/

	select
		rtrim(tert) tert, rtrim(factura_stinga) factura, suma
	into #diferente_curs
	from PozADoc where subunitate=@sub and tip='FB'
	and (explicatii like 'DIF. DE CONV.%' or isnull(detalii.value('(/row/@difconv)[1]', 'int'),0)=1) and cont_deb=@cCliIncerti and data=@data_lunii

	delete #ncon_prov

	insert into #ncon_prov (tip, numar, data ,cont_debitor, cont_creditor, suma, valuta, curs, suma_valuta, ex, lm ,comanda ,tert)
	select
		'NC','DFP'+CONVERT(varchar(10), @data_lunii, 103),@data_lunii, @cCheltProv , pe.cont_prov, CONVERT(DECIMAL(17,2),(pe.procent*dc.suma)/100.0),'', 0, 0, 
		left('Dif.curs. fact. proviz. '+rtrim(pe.factura)+' - '+t.denumire,50), pn.lm, pn.comanda, pe.tert
	from  #diferente_curs dc
	JOIN #prov_existente pe on pe.tert=dc.tert and pe.factura =dc.factura
	JOIN #provizioane pn on pn.factura=pe.factura and pn.tert=pe.tert
	JOIN Terti t on t.tert=pe.tert
	
	insert into PozNCon (Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, Nr_pozitie, Loc_munca, Comanda, Tert, Jurnal, detalii)
	select @sub, 'NC',numar, data, cont_debitor, cont_creditor, suma, valuta, curs, suma_valuta, ex, @utilizator, GETDATE(), RTRIM(replace(convert(char(8), getdate(), 108), ':', '')), 
		ROW_NUMBER() OVER (Order by newid()), lm, comanda, tert,'', NULL
	from #ncon_prov where abs(suma)>=0.01

end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
