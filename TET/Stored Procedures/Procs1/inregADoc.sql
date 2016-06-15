create procedure inregADoc @sesiune varchar(50), @parXML xml OUTPUT
as 

	declare 
		 @sub varchar(9), @bugetari int, 
		/* Se folosesc la apelul tipTVAFacturi si se determina din #DocDeContat */
		@datasus datetime, @datajos datetime 

		/*
		Procedura se bazeaza pe existenta tabelei #DocDeContat
			-> ea va exista insa pentru orice eventualitate apelam crearea (nu creaza daca exista)
		*/

	IF OBJECT_ID('tempdb..#DocDeContat') IS NULL
		create table #DocDeContat (subunitate varchar(9), tip varchar(2), numar varchar(40), data datetime)
	
	select @datasus='01/01/2999', @datajos=MIN(data) from #DocDeContat
	exec luare_date_par 'GE','SUBPRO',0,0,@Sub output
	exec luare_date_par 'GE','BUGETARI',@bugetari output,0,''

	CREATE TABLE [dbo].[#pozincon](
		[TipInregistrare] varchar(20), 
			/*	
				Tipurile de inregistrari sunt comentate la secventa de cod care "le trateaza" mai jos
			*/
		[Subunitate] varchar(9),
		[Tip] varchar(2),
		[Numar] [varchar](13) NOT NULL,
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

	select 
		RTRIM(p.subunitate) subunitate, rtrim(p.tip) tip, rtrim(p.numar_document) numar, p.data data, rtrim(p.cont_deb) cont_debitor, rtrim(p.Cont_cred) cont_creditor, rtrim(p.cont_dif) cont_diferenta,
		convert(decimal(17,5),p.suma_dif) suma_dif, convert(decimal(17,5),p.suma) suma, p.valuta, p.curs, convert(decimal(17,5),p.suma_valuta) suma_valuta, 
		rtrim(p.explicatii) explicatii, rtrim(p.factura_stinga) factura_stanga, rtrim(p.factura_dreapta) factura_dreapta, 
		p.Data_fact, (case when p.tip in ('SF','FF') then p.Cont_cred else p.Cont_deb end) as cont_factura,
		p.utilizator, p.data_operarii, p.ora_operarii, p.loc_munca, left(p.comanda,20) as comanda, p.tert, p.jurnal, p.stare tip_tva, p.tva11 cota_tva, convert(decimal(17,5), p.tva22) suma_tva, convert(decimal(17,5), dif_tva) dif_tva,
		p.idPozadoc as idpozadoc, space(20) as indbug, 0 as dedublareCOmpBug
	into #pozadoc 	
	from pozadoc p
	INNER JOIN #DocDeContat dc on p.subunitate=dc.subunitate and dc.tip=p.Tip and p.numar_document=dc.numar and p.data=dc.data
	where p.Subunitate=@Sub 

	/* apelam procedura unica de stabilire a indicatorului bugetar pentru fiecare pozitie de document */
	if @Bugetari=1 and exists (select * from sysobjects where name ='indbugPozitieDocument' and xtype='P')
	begin
		/*	pentru compensari la bugetari (CO si C3) trebuie dedublata inregistrarea pentru a putea genera 2 inregistrari cu indicatori diferiti 
			Trebuie care fiecare inregistrare sa aiba propriul indicator. 401 are un indicator, 411 are alt indicator */
		/*	pentru aceasta determinam primul cont 473 fara analitic */
		declare @contTrecere varchar(40)
		exec luare_date_par 'GE','CTTRCOMPB',0,0,@contTrecere output
		if @contTrecere=''
			select top 1 @contTrecere=cont from conturi where subunitate=@sub and cont like '473%' and are_analitice=0

		insert into #pozadoc (subunitate, tip, numar, data, cont_debitor, cont_creditor, cont_diferenta, suma_dif, suma, valuta, curs, suma_valuta, explicatii, factura_stanga, factura_dreapta, 
			Data_fact, cont_factura, utilizator, data_operarii, ora_operarii, loc_munca, comanda, tert, jurnal, tip_tva, cota_tva, suma_tva, dif_tva, idpozadoc, indbug, dedublareCOmpBug)
		select subunitate, tip, numar, data, @contTrecere, cont_creditor, cont_diferenta, suma_dif, suma, valuta, curs, suma_valuta, explicatii, factura_stanga, factura_dreapta, 
			Data_fact, cont_factura, utilizator, data_operarii, ora_operarii, loc_munca, comanda, tert, jurnal, tip_tva, cota_tva, suma_tva, dif_tva, idpozadoc, indbug, 1 as dedublareCOmpBug
		from #pozadoc where tip in ('CO','C3')

		update #pozadoc set Cont_creditor=@contTrecere where tip in ('CO','C3') and dedublareCOmpBug=0

		select (case when tip in ('CO','C3') then (case when dedublareCOmpBug=1 then 'B' else 'F' end) else '' end) as furn_benef, 'pozadoc' as tabela, idPozadoc as idPozitieDoc, indbug, 
		(case when dedublareCOmpBug=1 then factura_dreapta else factura_stanga end) as factura
		into #indbugPozitieDoc 
		from #pozadoc
		exec indbugPozitieDocument @sesiune=@sesiune, @parXML=@parXML
		update p set p.indbug=ib.indbug
		from #pozadoc p
			left outer join #indbugPozitieDoc ib on ib.idPozitieDoc=p.idPozadoc and (p.tip not in ('CO','C3') or ib.furn_benef=(case when dedublareCOmpBug=1 then 'B' else 'F' end))
	end

	/*
			BAZA- inregistrarea de baza POZADOC
	*/
	insert into #pozincon(TipInregistrare, Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii, Indbug)
	select
		'BAZA',subunitate, tip, numar, data, valuta, curs, round(Suma_valuta+(case when tip='IF' and curs>0 then suma_tva/curs else 0 end),2), utilizator, loc_munca, comanda, jurnal, 
		(case when tip='FF' and cont_diferenta<>'' then cont_diferenta else cont_debitor end),cont_creditor, 
		round(suma--+(case when tip='SF' and tip_tva<>1 then suma_tva else 0 end)-(case when tip='SF' then dif_tva else 0 end)	Inreg. BAZA pentru SF va contine doar campul pozadoc.suma. Similar cu IF.
			-(case when tip in('CF','SF','CO') and LEFT(cont_diferenta,1)='6' OR tip in ('CB','IF') and LEFT(cont_diferenta,1)='7' then suma_dif else 0 end),2),
		explicatii, Data_operarii, Ora_operarii, indbug
	from #pozadoc
	where cont_debitor<>cont_creditor
	
	/*
			POZI: Pozitie intermediara FF
	*/
	insert into #pozincon(TipInregistrare, Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma,Explicatii, Data_operarii, Ora_operarii, Indbug)
	select
		'POZI',subunitate, tip, numar, data, valuta, curs, round(Suma_valuta,2), utilizator, loc_munca, comanda, jurnal, cont_debitor, cont_diferenta, round(suma,2), explicatii, Data_operarii, Ora_operarii, indbug
	from #pozadoc
	where tip='FF' and ISNULL(cont_diferenta,'')<>''
	
	/*
			DIFCURS: Diferenta de curs valutar
	*/
	insert into #pozincon(TipInregistrare, Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma,Explicatii, Data_operarii, Ora_operarii, Indbug)
	select
		'DIFCURS',subunitate, tip, numar, data, valuta, curs, 0.0, utilizator, loc_munca, comanda, jurnal,  
		(case when LEFT(cont_diferenta,1)='6' then cont_diferenta else cont_debitor end),(case when left(cont_diferenta,1)='7' then cont_diferenta else cont_creditor end), 
		round(suma_dif,2), explicatii, Data_operarii, Ora_operarii, Indbug
	from #pozadoc
	where ABS(ISNULL(suma_dif,0))>0.01


	declare 
		@CtTvaNeexTLIPlati varchar(40),@CtTvaNeexTLIIncasari varchar(40), @CtTvaCol varchar(40),@CtTvaDed varchar(40),
		@CtTVANedeductibilChelt varchar(40), @CtTvaNeexDocAvans varchar(40), @ignor4428Avansuri bit
		

	/** Citire conturi din PAR */
	select @CtTvaNeexTLIPlati=RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CNTLIFURN'
	select @CtTvaNeexTLIIncasari=RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CNTLIBEN'
	select @CtTvaCol=RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CCTVA'
	select @CtTvaDed=RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CDTVA'
	select @CtTVANedeductibilChelt=RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CCTVANED'
	select @CtTvaNeexDocAvans=RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CNEEXREC'
	select @ignor4428Avansuri=val_logica from par where Tip_parametru='GE' and Parametru='NEEXAV'
	
	select '' as tip,(case when p.tip in ('SF','FF','CF') then 'F' else 'B' end) as tipf,p.tert,(case when p.tip in ('SF','FF') then p.factura_dreapta else p.factura_stanga end) factura,
		max(p.data_fact) as data,max(p.cont_factura) as cont,'' as tip_tva
	into #facturi_cu_TLI
	from #pozadoc p
	group by p.tert,(case when p.tip in ('SF','FF','CF') then 'F' else 'B' end),(case when p.tip in ('SF','FF') then p.factura_dreapta else p.factura_stanga end)
	
	exec tipTVAFacturi @dataJos=@dataJos, @dataSus=@dataSus

	/*
		TVA: TVA ded./colectat/neex.
	*/	
	insert into #pozincon(TipInregistrare, Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma,Explicatii, Data_operarii, Ora_operarii, Indbug)
	select
		'TVA',p.subunitate, p.tip, p.numar, p.data, p.valuta, p.curs, (case when p.tip in ('FF','FB') then p.dif_tva else 0.0 end), p.utilizator, p.loc_munca, p.comanda, p.jurnal, 
		(case when p.tip in ('SF','FF') or (p.tip in ('IF','FB') and p.tip_tva=1) 
				then (case when p.tip='FF' and left(p.cont_creditor,3)='408' then @CtTvaNeexDocAvans when p.tip in ('SF','FF') and ft.tip_tva='I' and p.tip_tva=0 then @CtTvaNeexTLIPlati else @CtTvaDed end)
			when left(p.cont_debitor,3)='419' and p.tip<>'FB' then @CtTvaCol else p.cont_debitor end) cont_debitor,
		(case when p.tip in ('SF','FF') and p.tip_tva=1 then @CtTvaCol when p.tip in ('SF','FF') then p.cont_creditor when left(p.cont_debitor, 3)='419' or left(p.cont_debitor,3)='418' and p.tip='FB' 
			then @CtTvaNeexDocAvans when ft.tip_tva='I' and p.tip_tva=0 and p.tip in ('IF','FB') then @CtTvaNeexTLIIncasari else @CtTvaCol end) cont_creditor, 
		round((case when p.tip='SF' and 1=0 /*Si la SF pe inregistrarea TVA se va completa suma_tva.*/ then p.dif_tva else p.suma_tva end),2), p.explicatii, p.Data_operarii, p.Ora_operarii, p.indbug
	from #pozadoc p
	INNER JOIN #facturi_cu_TLI ft on ft.tert=p.tert and ft.factura=(case when p.tip in ('SF','FF') then p.factura_dreapta else p.factura_stanga end)
		and ft.tipf=(case when p.tip in ('SF','FF','CF') then 'F' else 'B' end)
	where p.tip not in ('CF','CB') and not (p.tip in ('FB','IF') and p.tip_tva=2)

	/*
		CTVA: compensare TVA 
	*/	
	insert into #pozincon(TipInregistrare, Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma,Explicatii, Data_operarii, Ora_operarii, Indbug)
	select
		'CTVA',p.subunitate, p.tip, p.numar, p.data, p.valuta, p.curs, 0.0, p.utilizator, p.loc_munca, p.comanda, p.jurnal, 
		(case when p.tip='SF' or p.tip='CB' and @ignor4428Avansuri=1 then p.cont_debitor --when p.tip='SF' and ft.tip_tva='I' and p.tip_tva=0 then @CtTvaNeexTLIPlati 
			when p.tip in (/*'SF',*/'CF') then @CtTvaDed else @CtTvaNeexDocAvans end) cont_debitor,
		(case when p.tip='CB' /*or p.tip='SF' and p.tip_tva=1*/ then @CtTvaCol when p.tip='IF' or p.tip='CF' and @ignor4428Avansuri=1 then p.cont_creditor 
			when p.tip='IF' and ft.tip_tva='I' and p.tip_tva=0 then @CtTvaNeexTLIIncasari else @CtTvaNeexDocAvans end), 
		round((case when p.tip in ('CF','CB')  then -1 else 1 end)*suma_tva-(case when p.tip in ('SF','IF') then p.dif_tva else 0 end),2), p.explicatii, p.Data_operarii, p.Ora_operarii, p.indbug
	from #pozadoc p
	INNER JOIN #facturi_cu_TLI ft on ft.tert=p.tert and ft.factura=(case when p.tip='SF' then p.factura_dreapta else p.factura_stanga end)
	where p.tip not in ('FB','FF')

	/*
			TVAN- trecere pe nedeductibil
	*/	
	insert into #pozincon(TipInregistrare, Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma,Explicatii, Data_operarii, Ora_operarii, Indbug)
	select
		'TVAN',p.subunitate, p.tip, p.numar, p.data, p.valuta, p.curs, (case when p.tip='FF' then p.dif_tva else 0.0 end), p.utilizator, p.loc_munca, p.comanda, p.jurnal, 
		(case when p.tip='FF' and p.tip_tva=3 then p.cont_debitor else @CtTVANedeductibilChelt end),
		(case when p.tip='FF' and left(p.cont_creditor,3)='408' then @CtTvaNeexDocAvans else @CtTvaDed end), 
		round(p.suma_tva,2), p.explicatii, p.Data_operarii, p.Ora_operarii, p.indbug
	from #pozadoc p
	where (p.tip in ('FF','SF') and p.tip_tva=2 OR p.tip='FF' and p.tip_tva=3) and ABS(p.suma_tva)>0.01


	update #pozincon set Suma_valuta=0, curs=0 where valuta='' and (Suma_valuta<>0 or curs<>0)
	update #pozincon set valuta='', curs=0 where Suma_valuta=0

	
	/*Inversare daca este cazul, la inreg. de BAZA*/
	update #pozincon 
		set Cont_creditor=Cont_debitor,Cont_debitor=Cont_creditor,suma=-1*suma,Suma_valuta=-1*Suma_valuta
	from #pozincon p
	inner join conturi cd on p.Cont_debitor=cd.Cont
	inner join conturi cc on p.Cont_creditor=cc.Cont
	where 
		p.TipInregistrare='BAZA' and 
		(p.tip='FF' and (p.Cont_debitor like '7%' or p.Cont_debitor like '6%' and cd.Tip_cont='P') OR
		p.tip='FB' and (p.Cont_creditor like '6%' or p.Cont_creditor like '7%' and cc.Tip_cont='A'))


	/* Inversare la inreg. de Pozitie interm. -> doar la FF */
	update p 
		set Cont_creditor=Cont_debitor,Cont_debitor=Cont_creditor,suma=-1*suma,Suma_valuta=-1*Suma_valuta
	from #pozincon p
	inner join conturi cd on p.Cont_debitor=cd.Cont
	inner join conturi cc on p.Cont_creditor=cc.Cont
	where tip='FF' and p.TipInregistrare='POZI' and 
			(p.Cont_debitor like '7%'
			or
			p.Cont_debitor like '6%' and cd.Tip_cont='P'
			)

	begin try	
		
		/* Apel de procedura SP ce poate trata tabela temporara #pozincon */

		if exists (select 1 from sysobjects where [type]='P' and [name]='inregADocSP')
			exec inregADocSP @sesiune, @parXML output
		
		delete from #pozincon 
			where abs(suma)<0.01 and abs(Suma_valuta)<0.01
	
		delete p 
		from pozincon p
		inner join #pozadoc dc on p.subunitate=dc.subunitate and p.tip_document=dc.tip and p.numar_document=dc.numar and p.data=dc.data

		insert into pozincon
		(Subunitate, Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Loc_de_munca, Comanda, Jurnal, Indbug)
		select 
			Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, sum(Suma), Valuta, max(Curs), sum(Suma_valuta), 
			max(left(Explicatii,50)), max(Utilizator), max(Data_operarii), max(Ora_operarii), 
			ROW_NUMBER() over (PARTITION BY Subunitate, Tip, Numar, Data ORDER BY max(numar_pozitie)), Loc_de_munca, Comanda, max(Jurnal), Indbug
		from #pozincon 
		group by Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Loc_de_munca, Comanda, Valuta, Indbug
		order by tip,data
	
		-- stergem din docDeContat documentele prevazute - aici lucram doar cu #DocDeContat
		delete dc 
			from DocDeContat dc
			inner join #DocDeContat p on dc.tip=p.tip and p.numar=dc.numar and p.data=dc.data 
			where dc.tip in ('CO','C3','FF','FB','CF','CB','IF','SF')

		delete #DocDeContat where tip in ('CO','C3','FF','FB','CF','CB','IF','SF')

	end try
	begin catch
		declare @mesaj varchar(2000)
		set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
		raiserror (@mesaj, 15, 1)
	end catch

