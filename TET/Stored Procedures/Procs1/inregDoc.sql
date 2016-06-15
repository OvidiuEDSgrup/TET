create procedure inregDoc @sesiune varchar(50), @parXML xml OUTPUT
as 
/*
	Exemplu apel
		create table #DocDeContat (subunitate varchar(9), tip varchar(2), numar varchar(20), data datetime)
		insert #DocDeContat values ('1','AP','76','2014-01-01')
		exec inregDoc '',''
		select * from pozincon where numar_document='76' and data='2014-01-01'
		drop table #DocDeContat

	Observatii
		Conform vechiurilor inreg-uri standardul de conversie este
			round(convert(decimal(17,5), VALOARE),2), exceptie face valuta si tvaneex care este tratata conform anumitor parametri
*/

	declare 
		@gendifreceptii int,@accprod int,@inv_rul44 int,@adtvanxgtipA int,@invadtvanx int,@zecTvaNeex int,@rotunjireValuta bit,@rotPret float,@cheltObinvLaCasare int,@listaTipuri varchar(max),@Sub varchar(9),
		@bugetari int, 
		/* Se folosesc la apelul tipTVAFacturi si se determina din #DocDeContat */
		@datasus datetime, @datajos datetime 

		/*
		Procedura se bazeaza pe existenta tabelei #DocDeContat
			-> ea va exista insa pentru orice eventualitate apelam crearea (nu creaza daca exista)
		*/

	IF OBJECT_ID('tempdb..#DocDeContat') IS NULL
		create table #DocDeContat (subunitate varchar(9), tip varchar(2), numar varchar(40), data datetime)
	/*
		Daca sus este un parametru nefolosit in tipTvaFacturi, iar data jos se contruieste din setul de documente primit
	*/
	select @datasus='01/01/2999', @datajos=MIN(data) from #DocDeContat

	CREATE TABLE [dbo].[#pozincon](
		[TipInregistrare] varchar(20), 
			/*	
				Tipurile de inregistrari sunt comentate la secventa de cod care "le trateaza" mai jos
			*/
		[Subunitate] varchar(9),
		[Tip] varchar(2),
		[Numar] [varchar](20) NOT NULL,
		[Data] [datetime] NOT NULL,
		[Cont_debitor] [varchar](40) NOT NULL,
		[Cont_creditor] [varchar](40) NOT NULL,
		[Suma] [float] NOT NULL,
		[Valuta] [varchar](3) NOT NULL,
		[Curs] [float] NOT NULL,
		[Suma_valuta] [float] NOT NULL,
		[Explicatii] [varchar](1000) NOT NULL,
		[Utilizator] [varchar](10) NOT NULL,
		[Numar_pozitie] [int] identity,
		[Loc_de_munca] [varchar](9) NOT NULL,
		[Comanda] [varchar](40) NOT NULL,
		[Jurnal] [varchar](20),
		[Indbug] [varchar](20),
		[Data_operarii] datetime,
		[Ora_operarii] varchar(10)
	) 

	exec luare_date_par 'GE','SUBPRO',0,0,@Sub output
	exec luare_date_par 'GE','BUGETARI',@bugetari output,0,''
	exec luare_date_par 'GE','GENDIFRM',@gendifreceptii output,0,''
	exec luare_date_par 'GE','ACCIZE',@accprod output,0,''
	exec luare_date_par 'GE','INV44',@inv_rul44 output,0,''
	exec luare_date_par 'GE','ADTAVA',@adtvanxgtipA output,0,''
	exec luare_date_par 'GE','INVADDESC',@invadtvanx output,0,''	
	exec luare_date_par 'GE','ROTUNJTNX',0,@zecTvaNeex output,''
	exec luare_date_par 'GE','ROTPRET',@rotunjireValuta output,@rotPret output,''
	exec luare_date_par 'GE','TROICHCAS',@cheltObinvLaCasare output,0,''
	if @rotunjireValuta=1 and @rotPret=0
		set @rotPret=0.01
	
	/*
		Se genereaza tabelul #pozdoc care contine campuri calculate folosite mai jos la generarea inreg.
	*/
	select 
		p.idPozDoc,p.subunitate,p.tip,p.numar,p.data,p.cod,p.Tip_miscare,p.Loc_de_munca,left(p.comanda,20) as comanda,p.valuta,p.curs,p.utilizator,p.jurnal,p.discount,p.gestiune_primitoare,
		p.tert,p.factura,p.Data_facturii,p.Cota_TVA,p.TVA_neexigibil,p.Procent_vama,p.gestiune,
		convert(decimal(17,5),p.cantitate) cantitate,convert(decimal(17,5),p.Pret_de_stoc) Pret_de_stoc,
		convert(decimal(17,5),p.Pret_valuta) Pret_valuta,convert(decimal(17,6),p.Pret_vanzare) Pret_vanzare,
		convert(decimal(17,5),p.Pret_cu_amanuntul) Pret_cu_amanuntul,convert(decimal(17,5),p.pret_amanunt_predator) pret_amanunt_predator,
		convert(decimal(17,5),p.tva_deductibil) tva_deductibil,
		p.cont_de_stoc,(case when p.tip='DF' and @cheltObinvLaCasare=0 then p.cont_venituri else p.Cont_corespondent end) Cont_corespondent,p.cont_venituri,
		(case when p.tip='DF' and left(p.Cont_de_stoc,3)<>'371' then '' else p.Cont_intermediar end) Cont_intermediar,p.Cont_factura,
		(case when p.tip in ('RM','RS') then p.cont_factura else p.cont_corespondent end) as ContCorespondentIntrare,
		(case when p.tip in ('RM','RS') then convert(decimal(17,5),pret_valuta*(case when p.valuta='' then 1 else p.curs end)
			*(1.00+(case when p.Jurnal='RC' then -convert(decimal(12,6),p.cota_tva*100.00/(p.cota_tva+100)) else p.discount end)/100.00)) else Pret_de_stoc end) as PretFurnizorLei,
		CONVERT(decimal(17,5),(case when p.valuta<>'' and (t.tert_extern=1 or p.tip='AI' and p.jurnal='MFX') then p.pret_valuta*(1.00+p.discount/100.00) else 0 end)) as PretFurnizorValuta,
		(case when p.valuta<>'' and t.tert_extern=1 then convert(decimal(17,5),p.pret_valuta)*(1.00-p.discount/100.00) else 0 end) as PretVanzareValuta,
		round(convert(decimal(17,5),p.Pret_cu_amanuntul*p.TVA_neexigibil/(100.00+p.tva_neexigibil)),@zecTvaNeex) as TvaNeexUnitarIntrare,
		round(convert(decimal(17,5), p.Pret_amanunt_predator*isnull(p.detalii.value('(/row/@tvaneexies)[1]','decimal(7,2)'),p.TVA_neexigibil)/(100.00+isnull(p.detalii.value('(/row/@tvaneexies)[1]','decimal(7,2)'),p.TVA_neexigibil))),@zecTvaNeex) as TvaNeexUnitarIesire,
		convert(decimal(17,5),(case when p.valuta='' then p.pret_valuta else (case when @rotunjireValuta=1 then round(p.curs*p.pret_valuta/@rotPret,0)*@rotPret else p.curs*p.pret_valuta end) end)) as ValLeiDinValuta,
		convert(decimal(17,5),(case when p.valuta='' then p.pret_valuta else (case when @rotunjireValuta=1 then round(p.curs*p.pret_valuta/@rotPret,0)*@rotpret else p.curs*p.pret_valuta end)  end)-p.pret_vanzare) as ValDiscount,
		(case when p.valuta<>'' and p.curs>0 and t.tert_extern=1 then (case when p.tip in ('RM','RS') and isnumeric(p.grupa)=1 and p.grupa not like '442%' then convert(float,p.grupa) else convert(decimal(17,5),p.tva_deductibil/p.curs) end) else 0.0 end) TvaDeductibilValuta,
		p.Data_operarii Data_operarii,
		p.Ora_operarii Ora_operarii,
		isnull(nullif(d.detalii.value('/row[1]/@explicatii','varchar(1000)'),''),nullif(p.detalii.value('/row[1]/@explicatii','varchar(1000)'),'')) explicatiidindetalii, 
		nullif((case when p.tip='RS' and p.Gestiune_primitoare not like '378%' -- daca sunt chiar explicatii 
			then rtrim(p.Numar_DVI)+rtrim(p.Gestiune_primitoare) when p.tip in ('AI','AE') then left(p.factura,8)+contract 
			when p.tip='RM' then rtrim(t.denumire) else '' end),'') as explicatii_old, p.numar_dvi,
		convert(varchar(40),'') as contTva, 
		NULLIF(p.detalii.value('/row[1]/@lmdest','varchar(20)'),'') lm_destinatar,
		isnull(nullif(p.detalii.value('/row[1]/@procsal','decimal(12)'),0),p.Procent_vama) procent_salariat, p.subtip, convert(varchar(20),'') as indbug, 
		--	campuri utilizate in inregDocMF. Pe viitor ar fi bine de salvat in pozdoc.detalii
		nullif(p.detalii.value('/row[1]/@contam','varchar(40)'),'') as ContAm, p.Locatie as ContMFIstoric, p.contract as ContCorespMF, p.Barcod as ContMF8045, p.Accize_cumparare as AmortGradNeutiliz, 
		(case when p.tip='TE' and p.subtip='TR' then isnull(p.detalii.value('/row[1]/@valam','decimal(12,2)'),0) else p.Accize_datorate end) as ValAmortizata, p.Suprataxe_vama as RezerveReevaluare,
		(case when @bugetari=1 and p.tip='AP' then c.detalii.value('(/row/@indicator)[1]','varchar(20)') end) as IndbugContcoresp, 
		isnull(p.detalii.value('(/row/@_contdifav)[1]','varchar(40)'),'') as cont_dif_av, isnull(nullif(p.detalii.value('(/row/@_difcursav)[1]','float'),0),0) as dif_curs_av
	into #pozdoc
	from pozdoc p
	INNER JOIN #DocDeContat dc on p.subunitate=dc.subunitate and p.tip=dc.tip and p.numar=dc.numar and p.data=dc.data
	LEFT JOIN doc d on p.subunitate=d.subunitate and p.tip=d.tip and p.numar=d.numar and p.data=d.data
	LEFT JOIN terti t on p.tert=t.tert and p.Subunitate=t.Subunitate
	LEFT JOIN conturi c on p.Subunitate=c.Subunitate and p.Cont_corespondent=c.cont
	where p.subunitate=@sub

	/*	Se sterg din tabelul #pozdoc pozitiile doc, care inca nu sunt tratate */
	select p1.subunitate,p1.tip,p1.numar,p1.data
	into #prestari_noi
	from #pozdoc p1
	inner join RepartizarePrestari rp on p1.idPozDoc=rp.idPozDoc
	where p1.tip='RM'
	group by p1.subunitate,p1.tip,p1.numar,p1.data

	delete #pozdoc 
		from #pozdoc 
		left outer join #prestari_noi pn on pn.subunitate=#pozdoc.subunitate and pn.tip=#pozdoc.tip and pn.numar=#pozdoc.numar and pn.data=#pozdoc.data
	where #pozdoc.tip not in ('RM','RS','PP','AP','AS','AC','TE','CM','AI','AE','DF','PF','CI','AF') /* Doar aceste tipuri sunt tratate momentan. Adaugat si tipurile pt. ob. de inventar */
		 /*DVI-uri merge pe stil vechi*/
		or (#pozdoc.tip='RM' and #pozdoc.numar_dvi<>'')
		/*Receptii cu prestari pe stil vechi merg pe proc. vechi*/
		or (#pozdoc.tip='RM' and exists (select 1 from pozdoc pp where pp.subunitate=#pozdoc.subunitate and pp.tip in ('RP','RZ') and pp.numar=#pozdoc.numar and pp.data=#pozdoc.data) and pn.tip is null)
		--or (#pozdoc.jurnal='MFX' and #pozdoc.tip!='RM') --nu mai stergem documentele de MF (jurnal MFX) le tratam in inregDoc si inregDocMF.
	/* End stergere */

	/*	Diferentiez AC-urile, respectiv AP-urile cu cantitati negative (stornare bon) din Gestiune tip C, cu Gestiune primitoare completata si validata in catalogul de gestiuni. 
		Completez pret amanunt predator si TvaNeexUnitarIesire pentru descarcare adaos si TVA neexigibil. AT=Aviz si Transfer si AN - AP cu cantitati negative
	*/
	update #pozdoc set tip=(case when tip='AC' then 'AT' else 'AN' end), pret_amanunt_predator=Pret_cu_amanuntul
	where (tip='AC' or tip='AP' and cantitate<0) and exists (select 1 from gestiuni g where g.Cod_gestiune=#pozdoc.Gestiune and g.Tip_Gestiune in ('C','P')) 
		and exists (select 1 from gestiuni g where g.Cod_gestiune=#pozdoc.Gestiune_primitoare and g.Tip_Gestiune='A') 

	/*
		Se insereaza in tabelul #pozdoc date privind intrarea prin transfer (TI), pentru adaos si TVA neex. la intrare 
	*/
	insert into #pozdoc 
		(idPozDoc,Subunitate,tip, numar,data,cod,Tip_miscare,Loc_de_munca,comanda,valuta,curs,utilizator,jurnal,discount,gestiune_primitoare,tert,factura,Data_facturii,Cota_TVA,TVA_neexigibil,Procent_vama,gestiune,
		cantitate,Pret_de_stoc,Pret_valuta,Pret_vanzare,Pret_cu_amanuntul,pret_amanunt_predator,tva_deductibil,cont_de_stoc,Cont_corespondent,cont_venituri,Cont_intermediar,Cont_factura,
		ContCorespondentIntrare,PretFurnizorLei,PretFurnizorValuta, PretVAnzareValuta, TvaNeexUnitarIntrare, TvaNeexUnitarIesire, ValLeiDinValuta, ValDiscount,
		TvaDeductibilValuta, Data_operarii, Ora_operarii, explicatiidindetalii, explicatii_old, numar_dvi, procent_salariat, subtip, indbug, 
		ContAm, ContMFIstoric, ContCorespMF, ContMF8045, AmortGradNeutiliz, ValAmortizata, RezerveReevaluare, IndbugContcoresp, cont_dif_av, dif_curs_av
		)
	select 
		p.idPozDoc,p.subunitate,(case when tip='TE' then 'TI' else p.tip end) as tip,p.numar,p.data,p.cod,'I',p.Loc_de_munca,left(p.comanda,20) as comanda,p.valuta,p.curs,p.utilizator,p.jurnal,p.discount,
		(case when p.tip in ('AT','AN') then p.Gestiune else p.gestiune_primitoare end),	--am modificat gestiunea primitoare pentru a nu da efect pozitia cu I la DADAOS si DTVANEEX
		p.tert,p.factura,p.Data_facturii,p.Cota_TVA,p.TVA_neexigibil,p.Procent_vama,p.Gestiune_primitoare,
		p.cantitate,p.Pret_de_stoc,p.Pret_valuta,p.Pret_vanzare,p.Pret_cu_amanuntul,p.pret_amanunt_predator,
		convert(decimal(17,5),p.tva_deductibil),
		(case when p.tip='DF' and @cheltObinvLaCasare=0 then p.ContCorespondentIntrare else p.Cont_corespondent end) as Cont_corespondent,p.Cont_de_stoc,p.cont_venituri,p.Cont_intermediar,p.Cont_factura,
		p.cont_corespondent  as ContCorespondentIntrare,
		0 as PretFurnizorLei,
		0 as PretFurnizorValuta,
		0 as PretVanzareValuta,
		round(p.Pret_cu_amanuntul*p.TVA_neexigibil/(100.00+p.tva_neexigibil),@zecTvaNeex) as TvaNeexUnitarIntrare,
		0 as TvaNeexUnitarIesire,
		0 as ValLeiDinValuta,
		0 as ValDiscount,
		0 TvaDeductibilValuta,
		p.Data_operarii data_operarii,
		p.Ora_operarii ora_operarii,
		p.explicatiidindetalii, 
		explicatii_old, numar_dvi, procent_salariat, p.subtip, convert(varchar(20),'') as indbug, 
		null as ContAm, '' as ContMFIstoric, '' as ContCorespMF, '' as ContMF8045, 0 as AmortGradNeutiliz, 0 as ValAmortizata, 0 as RezerveReevaluare, null as IndbugContcoresp, 
		'' as cont_dif_av, 0 as dif_curs_av
	from #pozdoc p
	left outer join gestiuni gp on p.Subunitate=gp.Subunitate and p.gestiune_primitoare=gp.cod_gestiune
	where tip in ('TE','AT','AN','DF') and (tip_miscare='E'	or p.tip='TE' and isnull(gp.tip_gestiune,'')='V') -- se iau si TI-uri spre gest. valorice
	-- aici vor mai fi DF, PI. Adaugat DF pt. incarcare gestiune de folosinta(clasa 8).PF-ul nu cred ca trebuie.
	-- Lucian: Am inteles ca aceasta dublare s-a facut la TE-uri pt. adaos si TVA neexigibil. Am pus conditia tip_miscare=E intrucat la AT-uri pot exista pozitii de tip serviciu cu tip_miscare='V'

	/* apelam procedura unica de stabilire a indicatorului bugetar pentru fiecare pozitie de document */
	if @Bugetari=1 and exists (select * from sysobjects where name ='indbugPozitieDocument' and xtype='P')
	begin
		select '' as furn_benef, 'pozdoc' as tabela, idPozDoc as idPozitieDoc, indbug into #indbugPozitieDoc 
		from #pozdoc
		exec indbugPozitieDocument @sesiune=@sesiune, @parXML=@parXML
		update p set p.indbug=ib.indbug
		from #pozdoc p
			left outer join #indbugPozitieDoc ib on ib.idPozitieDoc=p.idPozDoc
	end

	/*
		pentru AT/AN TVA-ul neexigibil se va determina functie de cota_TVA (si nu in functie de TVA_neexigibil)
	*/
	update #pozdoc
		set TvaNeexUnitarIntrare=round(convert(decimal(17,5),Pret_cu_amanuntul*cota_tva/(100.00+cota_tva)),@zecTvaNeex)
	where tip in ('AT','AN')
	update #pozdoc
		set TvaNeexUnitarIesire=(case when tip_miscare='I' then 0 else TvaNeexUnitarIntrare end)
	where tip in ('AT','AN')
	/* 
		Completez pe aceasta pozitie cont de stoc=cont intermediar pentru a nu mai modifica partea de incarcare Adaos si TVA Neexigibil
		Completez TVA_deductibil, Pret_vanzare, Pret_valuta cu 0 pentru a nu mai modifica TVAC, VENFACTURA pt. AN-uri
	*/
	update #pozdoc set Cont_de_stoc=Cont_intermediar, TVA_deductibil=(case when tip='AN' then 0 else TVA_deductibil end), Pret_valuta=0, Pret_vanzare=0
	where tip in ('AT','AN') and Tip_miscare='I'

	/*	calculez TVA colectat la Dari in folosinta aferent procentului suportat de catre salariat.
		calculez PretFurnizorLei aferent intrarii in gestiunea de folosinta, daca se face darea in folosinta pe cont de clasa 8 (cand nu se face trecerea pe chelt. la casare)
	*/
	update #pozdoc set TVA_deductibil=(case when tip_miscare='E' then convert(decimal(12,2),cantitate*pret_de_stoc*isnull(procent_salariat,0)/100*cota_TVA/100) else 0 end),
		PretFurnizorLei=(case when tip_miscare='I' and @cheltObinvLaCasare=0 then Pret_de_stoc*(1-procent_salariat/100) else PretFurnizorLei end)
	where tip='DF'

	-- conturile sa fie spatiu daca null
	update #pozdoc set Cont_corespondent=''	where Cont_corespondent is null
	update #pozdoc set ContCorespondentIntrare=''	where ContCorespondentIntrare is null
	update #pozdoc set Cont_intermediar=''	where Cont_intermediar is null
	update #pozdoc set cont_venituri=''	where cont_venituri is null
	update #pozdoc set Cont_factura=''	where Cont_factura is null

	/*
		ISTOC	- Incarcare stoc in pret de intrare 	  			Cont De Stoc = Cont Corespondent Intrare			in lei si valuta
		Pret intrare= pret furnizor sau pret furnizor cu cota aplicata sau pret de stoc predare/intrare
		La ISTOC am asimilat si DI-urile (intrarea corespunzatoare Darilor in folosinta)
	*/
	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii, Indbug)
	select 'ISTOC',p.subunitate,p.tip,p.numar,p.data,p.valuta,p.curs,sum(round(convert(decimal(17,5),p.cantitate*p.PretFurnizorValuta),2)),max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	p.Cont_de_stoc,p.ContCorespondentIntrare,
	sum(round(convert(decimal(17,5),p.cantitate*p.PretFurnizorLei),2)) as valoare,
	isnull(max(p.explicatiidindetalii),isnull(max(p.explicatii_old),isnull(max(t.denumire),max(n.denumire)))) as explicatii,
	max(p.data_operarii), max(p.ora_operarii), p.indbug
	from #pozdoc p
	inner join nomencl n on p.cod=n.cod
	left join terti t on p.Subunitate=t.Subunitate and p.tert=t.tert
	where (p.Tip_miscare='I' or p.tip in ('RM','RS','AI')) and p.tip<>'TE' -- TE-ul este tratat ca iesire, deci "DSTOC"
		and not(p.tip='AI' and (p.jurnal='MFX' or n.tip='F'))	--incarcarea pentru AI cu mijloace fixe se trateaza in inregDocMF. Sunt anumite particularitati.
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,
	p.Cont_de_stoc,p.ContCorespondentIntrare,p.valuta,p.curs,p.jurnal,p.indbug

	/*
		Inregistrarea Valoare TVA
		
	*/
	declare 
		@CtTvaNeexPlati varchar(40),@CtTvaNeexIncasari varchar(40),@dataTLI datetime, @CtTvaCol varchar(40),@CtTvaDed varchar(40),
		@CtTVANedeductibilChelt varchar(40), @CtTvaNeexDocAvans varchar(40),  @CtDiscountSeparat varchar(40), 
		@ignor4428Avansuri bit,@ignor4428Document bit, @ConturiDocFaraFact varchar(200), @GestiuneInContDiscount bit, @DiscountSeparat bit

	/** Citire conturi din PAR */
	set @CtTvaNeexPlati= isnull(nullif((select top 1 RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CNTLIFURN'),''),'4428')
	set @CtTvaNeexIncasari= isnull(nullif((select top 1 RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CNTLIBEN'),''),'4428')
	set @CtTvaCol= isnull(nullif((select top 1 RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CCTVA'),''),'4427')
	set @CtTvaDed= isnull(nullif((select top 1 RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CDTVA'),''),'4426')
	set @CtTVANedeductibilChelt= isnull(nullif((select top 1 RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CCTVANED'),''),'635')
	set @CtTvaNeexDocAvans= isnull(nullif((select top 1 RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CNEEXREC'),''),'4428')
	select @CtDiscountSeparat=RTRIM(Val_alfanumerica), @GestiuneInContDiscount=val_logica from par where Tip_parametru='GE' and Parametru='CONTDISC'


	/** Citire anumiti parametri din PAR  */
	--Ignorare 4428 la avansuri terti
	select @ignor4428Avansuri=val_logica from par where Tip_parametru='GE' and Parametru='NEEXAV'
	select @ignor4428Document=val_logica, @ConturiDocFaraFact=val_alfanumerica from par where Tip_parametru='GE' and Parametru='NEEXDOCFF'
	select @DiscountSeparat=val_logica from par where Tip_parametru='GE' and Parametru='DISCSEP'

/*
	select '' as tip,(case when p.tip in ('RM','RS','RP') then 'F' else 'B' end) as tipf,p.tert,p.factura,max(data_facturii) as data,max(cont_factura) as cont,'' as tip_tva
	into #facturi_cu_TLI
	from #pozdoc p
	where p.tip in ('RM','RS','RP','AP','AS','AN')
	group by (case when p.tip in ('RM','RS','RP') then 'F' else 'B' end),p.tert,p.Factura
	exec tipTVAFacturi @dataJos=@dataJos, @dataSus=@dataSus
	S-a inlocuit apelul tipTVAFacturi cu apelul procedurii contTVAPozDocument, care va returna contul de TVA al pozitiei de document.
*/
	IF OBJECT_ID('tempdb..#contTVAPozitieDoc') IS NOT NULL
		drop table #contTVAPozitieDoc
	select tip as tip,(case when tip in ('RM','RS','RP','AI') then 'F' else 'B' end) tipf,tert,factura,'pozdoc' as tabela,idPozdoc as idPozitieDoc,'' as tip_tva,contTva
	into #contTVAPozitieDoc
	from #pozdoc
	where tip in ('RM','RS','RP','AI','AP','AS','AN','AE','DF')

	declare @parXMLTva xml
	select @parXMLTva=(select @datajos datajos, @datasus datasus for xml raw)
	exec contTVAPozDocument @sesiune=null, @parXML=@parXMLTva

	update p set p.contTva=ctva.contTVA
	from #pozdoc p 
		inner join #contTVAPozitieDoc ctva on ctva.tabela='pozdoc' and ctva.idPozitieDoc=p.idPozdoc
	
	/*
		TVAD	- Inregistrare TVA Deductibil			Cont TVA Deductibil sau CtTvaNeexDocAvans = Cont Corespondent TVA Deductibl
		 Tratat si cazul RM/RS cu "factura nesosita", cont factura=408.
	*/
	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma,Explicatii, Data_operarii, Ora_operarii, Indbug)
	select 'TVAD',p.subunitate,p.tip,p.numar,p.data,p.valuta,p.curs,sum(round(p.TvaDeductibilValuta,2)),max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	p.contTva,
	(case when p.procent_vama=1 then @CtTvaCol else p.cont_factura end),
	sum(round(convert(decimal(17,5),p.TVA_deductibil),2)) as valoare,
	coalesce(max(p.explicatiidindetalii),max(p.explicatii_old),max(t.denumire),MAX(n.denumire),'') as explicatii,
	max(p.data_operarii), max(p.ora_operarii), p.indbug
	from #pozdoc p
	inner join nomencl n on p.cod=n.cod
	left join terti t on p.Subunitate=t.Subunitate and p.tert=t.tert
	where 
		p.tip in ('RM','RS','AI')
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,
	p.Cont_factura,p.valuta,p.curs,p.jurnal,p.procent_vama,p.cota_tva,p.contTva,p.indbug

	/*
			TVADN	- Inregistrare TVA Deductibil nedeductibil  Cont cheltuiala setat sau cont de stoc (in functie de TIPTVA)= Cont TVA Deductibil		numai daca e pozitie cu TVA nedeductibil
	*/
	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii, Indbug)
	select 'TVADN',p.subunitate,p.tip,p.numar,p.data,p.valuta,p.curs,sum(round(p.TvaDeductibilValuta,2)),max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	(case when p.procent_vama=3 then p.cont_de_Stoc else @CtTVANedeductibilChelt end),
	p.contTva,
	sum(round(convert(decimal(17,5),p.TVA_deductibil),2)) as valoare,
	isnull(max(p.explicatiidindetalii),max(t.denumire)) as explicatii,
	max(p.data_operarii), max(p.ora_operarii), p.indbug
	from #pozdoc p
	inner join terti t on p.Subunitate=t.Subunitate and p.tert=t.tert
	where 
		p.tip in ('RM','RS') and p.procent_vama in (2,3)
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,
	p.cont_de_stoc,p.procent_vama,p.valuta,p.curs,p.jurnal,p.procent_vama,p.cota_tva,p.contTva,p.indbug

	/*
			TVADN	- Inregistrare TVA Deductibil nedeductibil cont de stoc (in functie de TIPTVA=5, pentru inceput documente care vin dinspre imobilizari).
	*/
	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii, Indbug)
	select 'TVADN',p.subunitate,p.tip,p.numar,p.data,p.valuta,p.curs,sum(round(convert(decimal(17,5),p.TvaDeductibilValuta/2),2)),max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	p.cont_de_Stoc,	p.contTva,
	sum(round(convert(decimal(17,5),p.TVA_deductibil/2),2)) as valoare,
	isnull(max(p.explicatiidindetalii),max(t.denumire)) as explicatii,
	max(p.data_operarii), max(p.ora_operarii), p.indbug
	from #pozdoc p
	inner join terti t on p.Subunitate=t.Subunitate and p.tert=t.tert
	where 
		p.tip in ('RM','RS') and p.procent_vama in (5)
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,
	p.cont_de_stoc,p.procent_vama,p.valuta,p.curs,p.jurnal,p.procent_vama,p.cota_tva,p.contTva,p.indbug

	/*
		TVAC: Inregistrarea Valoare TVA Colectata		Cont Factura (tva_colectat) sau CtTvaNeexDocAvans = Cont TVA Colectat (in functie de TLI) 
		Tratat si cazul AP/AS "aviz nefacturat", cont factura=418.
	*/
	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii, Indbug)
	select 'TVAC',p.subunitate,p.tip,p.numar,p.data,p.valuta,p.curs,sum(round(p.TvaDeductibilValuta,2)),max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	(case when p.procent_vama=0 or p.tip in ('AE','DF') then p.Cont_factura else @CtTvaDed end),
	p.contTVA,
	sum(round(convert(decimal(17,5),p.TVA_deductibil),2)) as valoare,
	isnull(max(p.explicatiidindetalii),max(isnull(t.denumire,'TVA colectat'))) as explicatii,
	max(p.data_operarii), max(p.ora_operarii), p.indbug
	from #pozdoc p
	left outer join terti t on p.Subunitate=t.Subunitate and p.tert=t.tert
	where 
		p.tip in ('AP','AS','AE','DF','AN')
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,
	p.Cont_factura,p.contTVA,p.valuta,p.curs,p.jurnal,p.cota_tva,p.Procent_vama,p.indbug


	/**
		ITAV: Inregistrarea "suplimentara"	( vezi parametri: CNEEXREC si NEEXAV) [409,419]
			Cont de stoc	=	@CtTvaNeexDocAvans  (RM, RS)
			@CtTvaNeexDocAvans	=	Cont de stoc	(AP, AS)
		
	**/
	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma,Explicatii, Data_operarii, Ora_operarii, Indbug)
	select 'ITAV',p.subunitate,p.tip,p.numar,p.data,p.valuta,p.curs,sum(round(p.TvaDeductibilValuta,2)),max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	(case when p.tip in ('RM','RS') then p.Cont_de_stoc when p.tip in ('AP','AS') then @CtTvaNeexDocAvans end),
	(case when p.tip in ('RM','RS') then @CtTvaNeexDocAvans when p.tip in ('AP','AS') then p.Cont_de_stoc end),
	sum(round(convert(decimal(17,5),p.TVA_deductibil),2)) as valoare,
	isnull(max(p.explicatiidindetalii),max(t.denumire)) as explicatii,
	max(p.data_operarii), max(p.ora_operarii), p.indbug
	from #pozdoc p
	inner join terti t on p.Subunitate=t.Subunitate and p.tert=t.tert
	inner join conturi c on p.Subunitate=c.Subunitate and c.cont=p.cont_de_stoc 
	where 
		p.Tip_miscare='V' and p.tip in ('RM','RS','AS','AP') and @ignor4428Avansuri=0 and CHARINDEX(LEFT(p.cont_de_stoc,3),@ConturiDocFaraFact)=0 /*in ('409','419','451','232') */
		/* Atribuire cont de stoc pe tert*/ and ((c.Sold_credit=1 and p.tip in ('RM','RS')) OR (p.tip in ('AP','AS') and c.Sold_credit=2))
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,
	p.Cont_de_stoc,p.valuta,p.curs,p.jurnal,p.procent_vama,p.cota_tva,p.indbug

	
	/**
		ITDFF: Inregistrarea "suplimentara"	( vezi parametri: CNEEXREC si NEEXDOCFF) [408,418]
			Cont de stoc	=	@CtTvaNeexDocAvans  (RM, RS)
			@CtTvaNeexDocAvans	=	Cont de stoc	(AP, AS)
		
	**/
	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma,Explicatii, Data_operarii, Ora_operarii, Indbug)
	select 'ITDFF',p.subunitate,p.tip,p.numar,p.data,p.valuta,p.curs,sum(round(p.TvaDeductibilValuta,2)),max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	(case when p.tip in ('RM','RS') then p.Cont_de_stoc when p.tip in ('AP','AS') then @CtTvaNeexDocAvans end),
	(case when p.tip in ('RM','RS') then @CtTvaNeexDocAvans when p.tip in ('AP','AS') then p.Cont_de_stoc end),
	sum(round(convert(decimal(17,5),p.TVA_deductibil),2)) as valoare,
	isnull(max(p.explicatiidindetalii),max(t.denumire)) as explicatii,
	max(p.data_operarii), max(p.ora_operarii), p.indbug
	from #pozdoc p
	inner join terti t on p.Subunitate=t.Subunitate and p.tert=t.tert
	inner join conturi c on p.Subunitate=c.Subunitate and c.cont=p.cont_de_stoc 
	where 
		p.Tip_miscare='V' and p.tip in ('RM','RS','AS','AP') 
		/*	Inversat un pic conditia: de ex. daca se doreste ignorarea doar la 408, cu conditia anterioara (@ignor4428Document=0 and ...) se ignora si la 418).	*/
		and not(@ignor4428Document=1) and CHARINDEX(LEFT(p.cont_de_stoc,3),@ConturiDocFaraFact)<>0 /*not in ('409','419','451','232') in ('408','418','167')*/ 
		/* Atribuire cont de stoc pe tert*/ and ((c.Sold_credit=1 and p.tip in ('RM','RS')) OR (p.tip in ('AP','AS') and c.Sold_credit=2))
		and not (p.tip in ('RM','RS')  and p.Procent_vama=1)
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,
	p.Cont_de_stoc,p.valuta,p.curs,p.jurnal,p.procent_vama,p.cota_tva,p.indbug

	/*
		ISTOCPR - Incarcare Stoc prin Prestare			Cont De Stoc (pozdoc) = Cont Factura Prestare (idPozPrestare)
	
	*/
	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii, Indbug)
	select 'ISTOCPR',p.subunitate,p.tip,p.numar,p.data,pozrp.valuta,pozrp.curs,sum(rp.suma/(case when pozrp.valuta<>'' and pozrp.curs>0 then pozrp.curs else 1 end)),max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	p.Cont_de_stoc,pozrp.Cont_factura,sum(round(convert(decimal(17,5),rp.suma),2)) as valoare,
	'Prest. '+isnull(max(p.explicatiidindetalii),max(isnull(t.denumire,'prestare interna'))) as explicatii,
	max(p.data_operarii), max(p.ora_operarii), p.indbug
	from #pozdoc p
	inner join RepartizarePrestari rp on rp.idpozdoc=p.idpozdoc
	inner join pozdoc pozrp on rp.idPozPrestare=pozrp.idpozdoc
	left join terti t on pozrp.Subunitate=t.Subunitate and pozrp.tert=t.tert
	where p.tip in ('RM','RS')
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,pozrp.valuta,pozrp.curs,
	p.Cont_de_stoc,pozrp.Cont_factura,p.valuta,p.curs,p.jurnal,p.indbug

	/*
		TVADPR	- Tva Deductibil Prestari				Cont TVA Deductibil pe Prestare = Cont Factura Prestare (idPozPrestare)
	*/
/*
	select '' as tip,'F' as tipf,tert,factura,max(data_facturii) as data,max(cont_factura) as cont,'' as tip_tva
	into #facturi_cu_TLI
	from pozdoc 
	where subunitate=@sub and tip='RP' and idPozDoc in (select rp.idPozPrestare from RepartizarePrestari rp inner join #pozdoc rm on rp.idpozdoc=rm.idpozdoc)
	group by tert, Factura
	exec tipTVAFacturi @dataJos=@dataJos, @dataSus=@dataSus
	S-a inlocuit apelul tipTVAFacturi cu apelul procedurii contTVAPozDocument, care va returna contul de TVA al pozitiei de document.
*/
	truncate table #contTVAPozitieDoc
	insert into #contTVAPozitieDoc
	select tip as tip,'F' as tipf,tert,factura,'pozdoc' as tabela,idPozdoc as idPozitieDoc,'' as tip_tva,convert(varchar(40),'') as contTva
	from pozdoc 
	where subunitate=@sub and tip='RP' and idPozDoc in (select rp.idPozPrestare from RepartizarePrestari rp inner join #pozdoc rm on rp.idpozdoc=rm.idpozdoc)
	exec contTVAPozDocument @sesiune=null, @parXML=@parXMLTva

	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii, Indbug)
	select 'TVADPR',p.subunitate,p.tip,p.numar,p.data,pozrp.valuta,pozrp.curs,sum(pozrp.TVA_deductibil/(case when pozrp.valuta<>'' and pozrp.curs>0 then pozrp.curs else 1 end)),max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	--pozrp.Cont_venituri,pozrp.Cont_factura,
	isnull(ctva.contTva,''),
	(case when pozrp.procent_vama=1 then @CtTvaCol else isnull(pozrp.cont_factura,'') end),
	sum(round(convert(decimal(17,5),pozrp.TVA_deductibil),2)) as valoare,
	'Prest. '+isnull(max(p.explicatiidindetalii),max(isnull(t.denumire,'prestare interna'))) as explicatii,
	max(p.data_operarii), max(p.ora_operarii), p.indbug
	from (
		select rp.idPozPrestare,max(p.subunitate) as subunitate,max(p.numar) as numar,max(p.data) as data,max(p.tip) as tip,max(p.Loc_de_munca) as loc_De_munca,max(p.comanda) as comanda,max(p.jurnal) as jurnal,max(p.utilizator) as utilizator,
		max(p.data_operarii) data_operarii, max(p.ora_operarii) ora_operarii, max(p.explicatiidindetalii) as explicatiidindetalii, max(p.indbug) as indbug
		from #pozdoc p
		inner join nomencl n on p.cod=n.cod
		inner join RepartizarePrestari rp on rp.idpozdoc=p.idpozdoc
		group by rp.idPozPrestare
		) p
	inner join pozdoc pozrp on p.idPozPrestare=pozrp.idpozdoc
	left outer join terti t on pozrp.subunitate=t.subunitate and pozrp.tert=t.tert
	left outer join #contTVAPozitieDoc ctva on ctva.tabela='pozdoc' and ctva.idPozitieDoc=p.idPozPrestare
	where 
		p.tip in ('RM','RS')
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,pozrp.valuta,pozrp.curs,
	pozrp.Cont_venituri,pozrp.Cont_factura,ctva.contTva,pozrp.valuta,pozrp.curs,p.jurnal, pozrp.procent_vama, pozrp.cota_tva, p.indbug

	/*
		Incarcare adaos IADAOS 	Cont de Stoc = Cont adaos (citit din parametri)
	*/
	declare @cAdaos varchar(40),@anGestAdaos int,@anGrupaAdaosNumeric decimal(12,2),@anGrupaAdaos int
	select top 1 @cAdaos=rtrim(val_alfanumerica),@anGestAdaos=val_logica,@anGrupaAdaosNumeric=Val_numerica from par where Tip_parametru='GE' and Parametru='CADAOS'
	set @anGrupaAdaos=(case when @anGrupaAdaosNumeric=1 then 1 else 0 end)
	if @cAdaos is null
		set @cAdaos='378'

	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma,Explicatii, Data_operarii, Ora_operarii)
	select 'IADAOS',p.subunitate,(case when p.tip='TI' then 'TE' else p.tip end),p.numar,p.data,'',0,0,max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	p.cont_de_stoc,rtrim(@cAdaos)+(case when @anGestAdaos=1 then '.'+rtrim(p.Gestiune) when @anGrupaAdaos=1 then '.'+rtrim(n.Grupa) else '' end),
	sum(round(convert(decimal(17,5),cantitate*p.Pret_cu_amanuntul),2)-round(convert(decimal(17,5),cantitate*pret_de_stoc),2)
		-round(convert(decimal(17,5),cantitate*p.TvaNeexUnitarIntrare),2)) as valoare,
	isnull(max(p.explicatiidindetalii),max(g.denumire_gestiune)) as explicatii,
	max(p.data_operarii), max(p.ora_operarii)
	from #pozdoc p
	inner join gestiuni g on p.Subunitate=g.Subunitate and p.gestiune=g.cod_gestiune
	inner join nomencl n on p.Cod=n.Cod
	where
		p.tip in ('RM','AI','TI','AT','AN') AND g.tip_gestiune in ('A','V') 
		/* Doar la conturile de stoc de marfa */
		and LEFT(p.Cont_de_stoc,3) IN ('371','357')
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,
	p.Gestiune,p.Cont_de_stoc,(case when @anGestAdaos=1 then '.'+rtrim(p.Gestiune) when @anGrupaAdaos=1 then '.'+rtrim(n.Grupa) else '' end),p.valuta,p.curs,p.jurnal

	/*
		Descarcare adaos DADAOS		Cont adaos (citit din parametri) = Cont de Stoc 
	*/
	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma,Explicatii, Data_operarii, Ora_operarii)
	select 'DADAOS',p.subunitate,p.tip,p.numar,p.data,'',0,0,max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	@cAdaos+(case when @anGestAdaos=1 then '.'+(case when p.tip in ('AT','AN') then p.Gestiune_primitoare else p.Gestiune end) when @anGrupaAdaos=1 then '.'+rtrim(n.Grupa) else '' end),
	(case when p.tip in ('AT','AN') then p.Cont_intermediar else p.cont_de_stoc end),
	sum(round(convert(decimal(17,5),p.cantitate*p.Pret_amanunt_predator),2)-round(convert(decimal(17,5),p.cantitate*pret_de_stoc),2)
		-round(convert(decimal(17,5),p.cantitate*p.TvaNeexUnitarIesire),2)) as valoare,
	isnull(max(p.explicatiidindetalii),max(g.denumire_gestiune)) as explicatii,
	max(p.data_operarii), max(p.ora_operarii)
	from #pozdoc p
	inner join gestiuni g on p.Subunitate=g.Subunitate and (case when p.tip in ('AT','AN') then p.Gestiune_primitoare else p.Gestiune end)=g.cod_gestiune
	inner join nomencl n on p.Cod=n.Cod
	where
		p.tip in ('AP','AC','TE','AE','CM','AT','AN') AND g.tip_gestiune in ('A','V') 
		/* Doar la conturile de stoc de marfa */
		and (LEFT(p.Cont_de_stoc,3) IN ('371','357') or p.tip in ('AT','AN') and left(p.cont_intermediar,3)='371')
		and not (tip_gestiune='V' and p.Tip in ('AP','AC'))
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,
	p.Gestiune,(case when p.tip in ('AT','AN') then p.Cont_intermediar else p.cont_de_stoc end),
	(case when @anGestAdaos=1 then '.'+(case when p.tip in ('AT','AN') then p.Gestiune_primitoare else p.Gestiune end) when @anGrupaAdaos=1 then '.'+rtrim(n.Grupa) else '' end),p.valuta,p.curs,p.jurnal

	/*
		Incarcare tva neexigibil ITVANEX	Cont de Stoc = Cont de TVA Neexigibil (citit din parametri)
	*/
	declare @cTvaNeexigil varchar(40),@anCtTvaNeexigibil int
	select top 1 
		@cTvaNeexigil=rtrim(val_alfanumerica),
		@anCtTvaNeexigibil=val_logica 
	from par where Tip_parametru='GE' and Parametru='CNTVA'
	if @cTvaNeexigil is null
		set @cTvaNeexigil='4428'

	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii)
	select 'ITVANEX',p.subunitate,(case when p.tip='TI' then 'TE' else p.tip end),p.numar,p.data,'',0,0,max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	p.cont_de_stoc,rtrim(@cTvaNeexigil)+(case when @anCtTvaNeexigibil=1 then '.'+rtrim(p.Gestiune) else '' end),
	sum(round(convert(decimal(17,5),p.Cantitate*p.TvaNeexUnitarIntrare),2)) as valoare,
	isnull(max(p.explicatiidindetalii),max(g.denumire_gestiune)) as explicatii,
	max(p.data_operarii), max(p.ora_operarii)
	from #pozdoc p
	inner join gestiuni g on p.Subunitate=g.Subunitate and p.gestiune=g.cod_gestiune
	where 
		p.tip in ('RM','AI','TI','AT','AN') AND g.tip_gestiune in ('A','V') 
		/* Doar la conturile de stoc de marfa */
		and LEFT(p.Cont_de_stoc,3) IN ('371','357')
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,
	p.Gestiune,p.Cont_de_stoc,p.valuta,p.curs,p.jurnal

	/*
		Descarcare tva neexigibil DTVANEX		Cont de TVA Neexigibil (citit din parametri) = Cont de Stoc
	*/
	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii)
	select 'DTVANEX',p.subunitate,p.tip,p.numar,p.data,'',0,0,max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	@cTvaNeexigil+(case when @anCtTvaNeexigibil=1 then '.'+(case when p.tip in ('AT','AN') then p.Gestiune_primitoare else p.Gestiune end) else '' end),
	(case when p.tip in ('AT','AN') then p.Cont_intermediar else p.cont_de_stoc end),
	sum(round(convert(decimal(17,5),p.Cantitate*p.TvaNeexUnitarIesire),2)) as valoare,
	isnull(max(p.explicatiidindetalii),max(g.denumire_gestiune)) as explicatii,
	max(p.data_operarii), max(p.ora_operarii)
	from #pozdoc p
	inner join gestiuni g on p.Subunitate=g.Subunitate and (case when p.tip in ('AT','AN') then p.Gestiune_primitoare else p.Gestiune end)=g.cod_gestiune
	where 
		p.tip in ('AP','AC','TE','AE','CM','AT','AN') AND g.tip_gestiune in ('A','V') 
		/* Doar la conturile de stoc de marfa */
		and (LEFT(p.Cont_de_stoc,3) IN ('371','357') or p.tip in ('AT','AN') and left(p.cont_intermediar,3)='371')
		and not (tip_gestiune='V' and p.Tip in ('AP','AC'))
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,
	(case when p.tip in ('AT','AN') then p.Gestiune_primitoare else p.Gestiune end),(case when p.tip in ('AT','AN') then p.Cont_intermediar else p.cont_de_stoc end),p.valuta,p.curs,p.jurnal

	/*
		Inregistrarea pret vanzare pentru Iesiri mai ales prin Vanzare	Cont Factura (cantitate*pret_furnizor) = Cont venituri
	*/

	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii, Indbug)
	select 'VENFACTURA',p.subunitate,p.tip,p.numar,p.data,p.valuta,p.curs,sum(round(p.cantitate*p.PretVanzareValuta,2)),max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	p.Cont_factura,(case when n.tip='S' and p.Jurnal<>'MFX' then p.cont_de_stoc else p.Cont_venituri end),
	sum(round(convert(decimal(17,5),p.Cantitate*(case when @DiscountSeparat=1 then p.ValLeiDinValuta else p.Pret_vanzare end)),2)) as valoare,
	isnull(max(p.explicatiidindetalii),max(t.denumire)) as explicatii,
	max(p.data_operarii), max(p.ora_operarii), p.indbug
	from #pozdoc p
	inner join terti t on p.Subunitate=t.Subunitate and p.tert=t.tert
	inner join nomencl n on n.cod=p.cod
	where 
		p.tip in ('AP','AS','AN')
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,
	(case when n.tip='S' and p.Jurnal<>'MFX' then p.cont_de_stoc else p.Cont_venituri end),p.Cont_Factura,p.valuta,p.curs,p.jurnal,p.indbug

	/**
		DISC	Inregistrare discount separat- daca e cazul (setarile CONTDISC) @CtDiscountSeparat=CONT factura
	 
		Atentie setarea @GestiuneInContDiscount daca e 1, va face contul de forma @CtDiscountSeparat.GESTIUNE
	**/
	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma,Explicatii, Data_operarii, Ora_operarii, Indbug)
	select 'DISC',p.subunitate,p.tip,p.numar,p.data,p.valuta,p.curs,sum(p.cantitate*(p.pret_valuta-p.pret_vanzare)*p.curs),max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	(case when @GestiuneInContDiscount=1 then @CtDiscountSeparat+'.'+p.gestiune else @CtDiscountSeparat end),	
	p.Cont_factura,
	sum(ROUND(convert(decimal(17,5),p.cantitate*p.ValDiscount),2)) as valoare,
	isnull(max(p.explicatiidindetalii),max(t.denumire)) as explicatii,
	max(p.data_operarii), max(p.ora_operarii), p.indbug
	from #pozdoc p
	inner join terti t on p.Subunitate=t.Subunitate and p.tert=t.tert
	where 
		p.tip in ('AP','AS','AN') and @DiscountSeparat=1
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,
	p.Cont_Factura,p.valuta,p.curs,p.jurnal, p.gestiune, p.indbug

	/*
		Inregistrarea in pret de stoc pentru Dari in folosint suportate de catre salariat Cont Factura (cantitate*pret_de_stoc*procent_salariat/100) = Cont de stoc
	*/
	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii, Indbug)
	select 'DECSALARIAT',p.subunitate,p.tip,p.numar,p.data,'',0,0,max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	p.Cont_factura,p.cont_de_stoc,
	sum(round(convert(decimal(17,5),p.Cantitate*p.Pret_de_stoc*p.Procent_salariat/100),2)) as valoare,
	isnull(max(p.explicatiidindetalii),max(isnull(s.nume,''))) as explicatii,
	max(p.data_operarii), max(p.ora_operarii), p.indbug
	from #pozdoc p
	left outer join personal s on p.Gestiune_primitoare=s.Marca
	where 
		p.tip='DF' and p.Tip_miscare='E'
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,
	p.cont_de_stoc,p.Cont_Factura,p.valuta,p.curs,p.jurnal,p.indbug

	declare @faraInregConturiEgaleTE bit, @faraInregConturiEgalePF bit

	exec luare_date_par 'GE','NUCTEGAL',@faraInregConturiEgaleTE OUTPUT,0,''
	exec luare_date_par 'GE','NUCPFEGAL',@faraInregConturiEgalePF OUTPUT,0,''
	/*
		DSTOC	- Descarcare stoc in pret furnizor	  		 
					DSTOC1											Cont Corespondent Iesire = Cont intermediar (daca e completat) sau Cont de stoc
					DSTOC2		Daca e completat cont intermediar	Cont intermediar= Cont de stoc
		La TE, in functie de setarea "NUCTEGAL" nu se genereaza inregistrarea de descarcare de stoc in conditiile:
			- conturi egale (cont coresp. <-> cont de stoc) si cont intermediat necompletat
	*/

	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii, Indbug)
	select 'DSTOC1',p.subunitate,p.tip,p.numar,p.data,'',0,0,max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	p.Cont_corespondent,
	isnull(nullif(p.cont_intermediar,''),p.Cont_de_stoc),
	sum(round(convert(decimal(17,5),p.cantitate*p.pret_de_Stoc*(1-(case when p.Tip='DF' then p.procent_salariat else 0 end)/100)),2)) as valoare,
	coalesce(max(p.explicatiidindetalii),max(p.explicatii_old),max(n.denumire),'') as explicatii,
	max(p.data_operarii), max(p.ora_operarii), isnull(p.IndbugContcoresp,p.indbug)
	from #pozdoc p
	inner join nomencl n on p.cod=n.cod
	left outer join gestiuni g on p.Subunitate=g.Subunitate and p.gestiune=g.cod_gestiune
	left outer join gestiuni gp on p.Subunitate=gp.Subunitate and p.gestiune_primitoare=gp.cod_gestiune
	left outer join personal ps on p.gestiune=ps.marca
	left outer join conturi c on p.Subunitate=c.Subunitate and p.Cont_corespondent=c.cont
	where 
		(p.Tip_miscare='E' or p.tip='TE' and p.Tip_miscare='V' and (isnull(g.tip_gestiune,'')='V' or isnull(gp.tip_gestiune,'')='V') or (p.Jurnal='MFX' or n.tip='F') and p.tip in ('AE','AP'))
		and (not (@faraInregConturiEgaleTE=1 and p.tip='TE' and p.Cont_corespondent=p.cont_de_stoc and p.cont_intermediar='') -- nu gen. inreg. la TE si setare
			or p.tip='TE' and (isnull(g.tip_gestiune,'')='V' or isnull(gp.tip_gestiune,'')='V')) -- cu exceptia TE spre/de la gestiuni valorice 
		and not (@faraInregConturiEgalePF=1 and p.tip='PF' and p.Cont_corespondent=p.cont_de_stoc and p.cont_intermediar='')
		and not (isnull(g.tip_gestiune,'')='V' and p.tip='AP')	-->	Tratat sa nu se faca inreg. contabile pentru AP-uri din gestiuni valorice. Aceste documente sunt luate in considerare la descarcarea gestiunilor valorice(K).
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,
	p.Cont_de_stoc,p.Cont_corespondent,p.cont_intermediar,p.valuta,p.curs,p.jurnal,isnull(p.IndbugContcoresp,p.indbug)
	
	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii, Indbug)
	select (case when max(g.tip_gestiune)='V' then 'DSTOC3' else 'DSTOC2' end),p.subunitate,p.tip,p.numar,p.data,'',0,0,max(p.utilizator),ISNULL(p.lm_destinatar,p.loc_de_munca),p.comanda,p.jurnal,
	p.Cont_intermediar,p.Cont_de_stoc,
	sum(round(convert(decimal(17,5),p.cantitate*p.pret_de_Stoc),2)) as valoare,
	isnull(max(p.explicatiidindetalii),max(n.denumire)) as explicatii,
	max(p.data_operarii), max(p.ora_operarii), p.indbug
	from #pozdoc p
	inner join nomencl n on p.cod=n.cod
	left outer join gestiuni g on p.Subunitate=g.Subunitate and p.gestiune=g.cod_gestiune
	where 
		(p.Tip_miscare='E' or p.tip='TE' and isnull(g.tip_gestiune,'')='V')
		and nullif(p.cont_intermediar,'') is not null and not (p.cont_de_stoc=p.cont_intermediar)
		and not (g.tip_gestiune='V' and p.tip='AP')	-->	Tratat sa nu se faca inreg. contabile pentru AP-uri din gestiuni valorice. Aceste documente sunt luate in considerare la descarcarea gestiunilor valorice(K).
	group by p.subunitate,p.tip,p.numar,p.data,ISNULL(p.lm_destinatar,p.loc_de_munca),p.comanda,p.valuta,p.curs,
	p.Cont_de_stoc,p.cont_intermediar,p.valuta,p.curs,p.jurnal,p.indbug

	/**
		DIFCURS	- Inregistrare diferente de curs la stornare avans - daca e cazul 
	**/
	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma,Explicatii, Data_operarii, Ora_operarii, Indbug)
	select 'DIFCURS',p.subunitate,p.tip,p.numar,p.data,p.valuta,p.curs,0,max(p.utilizator),p.loc_de_munca,p.comanda,p.jurnal,
	(case when p.tip in ('RM','RS') 
		/* Furnizori */
			then (case when sum(Dif_curs_av)>0 then p.Cont_de_stoc else p.Cont_dif_av end)
		/* Beneficiari */
			else (case when sum(Dif_curs_av)<0 then p.Cont_de_stoc else p.Cont_dif_av end) end), 
	(case when p.tip in ('RM','RS')
		/* Furnizori */
			then (case when sum(Dif_curs_av)>0 then p.Cont_dif_av else p.Cont_de_stoc end)
		/* Beneficiari */
			else (case when sum(Dif_curs_av)<0 then p.Cont_dif_av else p.Cont_de_stoc end) end),
	abs(sum(p.dif_curs_av)) as valoare,
	isnull(max(p.explicatiidindetalii),max(t.denumire)) as explicatii,
	max(p.data_operarii), max(p.ora_operarii), p.indbug
	from #pozdoc p
	inner join terti t on p.Subunitate=t.Subunitate and p.tert=t.tert
	where 
		p.tip in ('RM','RS','AP','AS') and Dif_curs_av<>0
	group by p.subunitate,p.tip,p.numar,p.data,p.loc_de_munca,p.comanda,p.valuta,p.curs,
		p.Cont_de_stoc,p.Cont_dif_av,p.valuta,p.curs,p.jurnal,p.indbug

	declare @parXMLImob xml
	select @parXMLImob=(select @datajos datajos, @datasus datasus for xml raw)
	if exists (select 1 from sysobjects where [type]='P' and [name]='inregDocImob')
		exec inregDocImob @sesiune=@sesiune, @parXML=@parXMLImob
	else
		if exists (select 1 from sysobjects where [type]='P' and [name]='inregDocMF')
			exec inregDocMF @sesiune=@sesiune, @parXML=@parXML

	/*Corectii clasa 8 daca este cazul*/

	-- prelucrare TE prin clasa 8 <=> o inregistrare suplimentara 8...=<spatiu>, pe loc munca al gestiunii primitoare (daca nu exista se ia cel de pe TE):  
	insert #pozincon (TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma,Explicatii, Data_operarii, Ora_operarii, Indbug)
		select TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, 
		isnull(case when Tip='PF' then (select max(pe.Loc_de_munca) from pozdoc p, personal pe where p.subunitate=#pozincon.subunitate and p.tip=#pozincon.tip and p.numar=#pozincon.numar and p.data=#pozincon.data and pe.marca=p.gestiune_primitoare) 
		else (select max(g.Loc_de_munca) from pozdoc p, gestcor g where p.subunitate=#pozincon.subunitate and p.tip=#pozincon.tip and p.numar=#pozincon.numar and p.data=#pozincon.data and g.gestiune=p.gestiune_primitoare) end, loc_de_munca), 
		Comanda, Jurnal,Cont_debitor, '', Suma,Explicatii, Data_operarii, Ora_operarii, Indbug
		from #pozincon 
		where TipInregistrare in ('DSTOC1','DSTOC2') and Cont_debitor like '8%' and (Tip='TE' or Tip='PF') and Cont_creditor like '8%'	--/*la PF se aplica regula cand NU se lucreaza cu setarea @cheltObinvLaCasare(=0)*/
																																		--/*la PF prin 482, cont creditor='' si DSTOC1 contine deja incarcarea de stoc*/
	
	update #pozincon set Cont_debitor=''
	from #pozincon 
	where TipInregistrare in ('DSTOC1','DSTOC2') and Cont_creditor like '8%'
		
	update #pozincon set Cont_creditor=''
	from #pozincon 
	where TipInregistrare in ('ISTOC') and Cont_debitor like '8%'
		
	/*Inversare daca este cazul*/
	
	update #pozincon set Cont_creditor=Cont_debitor,Cont_debitor=Cont_creditor,suma=-1*suma,Suma_valuta=-1*Suma_valuta
	from #pozincon p
	inner join conturi cd on p.Cont_debitor=cd.Cont
	inner join conturi cc on p.Cont_creditor=cc.Cont
	where 
		(p.TipInregistrare in ('VENFACTURA','ISTOC') and 
			(p.Cont_creditor like '6%'
			or
			p.Cont_creditor like '7%' and cc.Tip_cont='A'
			))
		or
		(p.TipInregistrare='ISTOC' and 
			(p.Cont_debitor like '7%'
			or
			p.Cont_debitor like '6%' and cd.Tip_cont='P'
			))
		or
		(@invadtvanx=1
			and p.tipInregistrare in ('DADAOS','DTVANEX','DSTOC3') and p.tip in ('TE','CM')
			)
		or
		(@inv_rul44=1
			and p.Cont_debitor like '44%'
			and p.tipInregistrare like ('ISTOC%')
			)
	/*Gata Inversare*/
	
	/*
		Corectie pentru documentele cu valuta
	*/
	update #pozincon set Suma_valuta=0, curs=0 where valuta='' and (Suma_valuta<>0 or curs<>0)

	/*	
		Modificari pentru AC-uri/AP-uri cu gestiune intermediara. Se repune tipul de document ca AC/AP.
	*/
	update #pozdoc set tip=(case when tip='AT' then 'AC' else 'AP' end) where tip='AT' or tip='AN'
	update #pozincon set tip=(case when tip='AT' then 'AC' else 'AP' end) where tip='AT' or tip='AN'

begin try	

	/*	
		setarea din CG\Configurari\Contare\Marfuri [ ]Inregistrari adaos si TVA neexigibil la avize gestiuni tip A. Doar la conturile de stoc de marfa.
	*/
	if @adtvanxgtipA=1	and exists (select 1 from sysobjects where [type]='P' and [name]='inregDocAvizeGestTipA')
		exec inregDocAvizeGestTipA @sesiune=@sesiune, @parXML=@parXML

	if @gendifreceptii=1 
		exec inregDocReceptiiDiferente @sesiune=@sesiune, @parXML=@parXML
		
	if @accprod=1 and exists (select 1 from sysobjects where [type]='P' and [name]='inregDocAccizeProd')
		exec inregDocAccizeProd @sesiune=@sesiune, @parXML=@parXML
		
	/* Apel de procedura SP ce poate trata tabela temporara #pozincon 
		se pot folosi tipurile de inregistrari (ex. ISTOC, TVAD) pentru a afecta doar unele din acestea
	*/

	if exists (select 1 from sysobjects where [type]='P' and [name]='inregDocSP')
		exec inregDocSP @sesiune, @parXML output

	delete from #pozincon 
		where abs(suma)<0.01

	delete p 
	from pozincon p
		-- stergem aferent documentelor selectate, ca sa fie luate in calcul si cele fara inregistrari + sa nu intretin conditia de selectie din pozdoc in 2 locuri 
		inner join #pozdoc dc on p.subunitate=dc.subunitate and p.tip_document=dc.tip and p.numar_document=dc.numar and p.data=dc.data

	insert into pozincon
	(Subunitate, Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Loc_de_munca, Comanda, Jurnal, Indbug)
	select Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, 
		left(rtrim(Explicatii)+ '('+rtrim(TipInregistrare)+')',50), Utilizator, 			
			Data_operarii, Ora_operarii
		, Numar_pozitie, Loc_de_munca, Comanda, Jurnal, isnull(Indbug,'')
		from #pozincon 
		order by tip,data
	
	delete dc 
		from DocDeContat dc
		-- stergem din docDeContat aferent documentelor selectate, ca sa fie luate in calcul si cele fara inregistrari 
		inner join #pozdoc p on p.subunitate=dc.subunitate and p.tip=dc.tip and p.numar=dc.numar and p.data=dc.data
	
	delete dc 
		from #DocDeContat dc
		-- stergem din #DocDeContat aferent documentelor selectate, ca sa fie luate in calcul si cele fara inregistrari
		inner join #pozdoc p on p.subunitate=dc.subunitate and p.tip=dc.tip and p.numar=dc.numar and p.data=dc.data
end try
begin catch
	declare @mesaj varchar(8000)
	set @mesaj =ERROR_MESSAGE()+' (InregDoc)'
	raiserror(@mesaj, 11, 1)
end catch

-- pana la publicare sa nu existe procedura decat daca se intervine aici:

