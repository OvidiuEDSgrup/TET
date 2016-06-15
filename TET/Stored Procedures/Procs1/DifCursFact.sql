
create procedure DifCursFact @TipCor char(1),@partert char(13),@parvaluta char(3), @paridentdoc char(4),@parconttert varchar(40),@contprov varchar(40),@generare bit,@sterg bit,@data datetime
as

	/*
	
	-- exemplu de rulare:
	exec DifCursFact @TipCor='B',@partert='11000',@parvaluta='GBP', @paridentdoc='DIFC',@parconttert=null,@contprov=null,@generare=1,@sterg=1,@data='2014-11-30'

	*/
	declare 
		@mesaj varchar(200), @datajos datetime,@datasus datetime,@subunitate char(13),@contcheltfurn varchar(40),
		@contvenfurn varchar(40),@contcheltben varchar(40),@contvenben varchar(40),@aninchis int,@lunainchisa int,@user char(10),
		@validcomstrict int,@comandaGenerica varchar(20),@maxpoz int,@cmaxnumar varchar(10),@maxnumar int, @parXMLFact xml

	if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
	begin
			raiserror('Accesul este restrictionat pe anumite locuri de munca! Nu este permisa operatia in aceste conditii!',16,1)
			return
	end

	if isnull(@paridentdoc,'')='' 
		select @paridentdoc='DIFC'
	
	if exists(select * from sys.objects where type='P' and name='DifCursFact_SP')
	begin
		exec DifCursFact_SP @TipCor,@partert,@parvaluta,@paridentdoc,@parconttert,@contprov, @generare,@sterg,@data
		return
	end

	select
		@subunitate=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), ''),
		@contcheltfurn=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='DIFCH'), ''),
		@contvenfurn=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='DIFVE'), ''),
		@contcheltben=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='DIFCHB'), ''),
		@contvenben=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='DIFVEB'), ''),
		@validcomstrict=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='COMANDA'), 0),
		@comandaGenerica=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='COMANDAG'), '')

	set @datajos=dbo.EOM(dateadd(mm,(@aninchis-1900)* 12 + @lunainchisa - 1,0)) 
	set @datasus=dbo.EOM(@data)
	set @user = isnull(dbo.fIaUtilizator(null),'')
	select @paridentdoc= RTRIM(LTRIM(@paridentdoc))
	/* Verificam daca se lucreaza cu provizioane: in caz afirmativ prov. aferente lunii pt. care se da calc. de dif. curs trebuie sterse
		(ele vor fi recreate la inchidere). Se sterg pt. a nu afecta contul, soldul,etc al facturii: ordinea este 1. Calc. de dif.; 2. Calcul de proviz. */

	if @sterg=1
	begin
		if OBJECT_ID('tempdb..#doc_sterse') is not null 
			drop TABLE #doc_sterse
		create table #doc_sterse(subunitate varchar(9), tip varchar(2), numar_document varchar(40), data datetime)

		delete from pozadoc 
		OUTPUT deleted.Subunitate, deleted.Tip, deleted.Numar_document, deleted.Data
		into #doc_sterse(subunitate, tip, numar_document, data) 
			where subunitate=@subunitate and tip=(case when @tipcor='B' then 'FB' else 'FF' end) 
			and data=@datasus and stare=5 
			and (explicatii like 'PROVIZIONE%' or explicatii like 'DIF. DE CONV.%' or isnull(detalii.value('(/row/@difconv)[1]', 'int'),0)=1)
			and (ISNULL(@partert,'')='' or tert=@partert) and (ISNULL(@parvaluta,'')='' or valuta=@parvaluta) 
			and (isnull(@parconttert,'')='' or @tipcor='F' and Cont_deb like rtrim (@parconttert)+'%' or @tipcor='B' and Cont_cred like rtrim (@parconttert)+'%') 

		delete adoc from adoc 
		inner join #doc_sterse ds on adoc.subunitate=ds.subunitate and adoc.tip=ds.tip and adoc.numar_document=ds.numar_document and adoc.data=ds.data 
			where adoc.subunitate=@subunitate and adoc.tip=(case when @tipcor='B' then 'FB' else 'FF' end) 
			and adoc.data=@datasus /*and stare=5 and adoc.numar_document like rtrim(@paridentdoc)+'%' */
			and (ISNULL(@partert,'')='' or adoc.tert=@partert) and adoc.Numar_pozitii=0
	end

	if @generare=1
	begin
		--	iau numarul maxim deja generat (pt. cazurile in care se ruleaza operatia cu filtre) pentru a putea numerota la rand numerele de document
		select @cmaxnumar=isnull(max(numar_document),''), @maxpoz=isnull(max(numar_pozitie),0) 
			from pozadoc where Data=@data and tip=(case when @TipCor='B' then 'FB' else 'FF' end) and Numar_document like rtrim(@paridentdoc)+'%'  
		set @maxnumar=isnull(convert(int,substring(@cmaxnumar,len(rtrim(@paridentdoc))+1,10)),0)

		if @partert='' set @partert=null

		/** 
			Daca operatia este apelata din CGplus nu avem tabela temporara si atunci o cream default cu acest valori
			Daca operatia este apelata din RIA tabela va exista, creata pe baza gridului editabil
			Aceasta tabela este folosita in JOIN-ul de mai jos pentru a determina cursul la data din tabela #DifFactura (care este folosit pe urma in mai multe locuri)
		*/
		IF OBJECT_ID('tempdb..#tmpcursuri') IS NULL
		begin
			create table #tmpcursuri (valuta varchar(20), curs float)
			insert into #tmpcursuri(valuta, curs)
			SELECT valuta, curs
			from 
				(
					SELECT 
						valuta, Curs, RANK() over (partition by valuta order by data desc) rn
					from curs
					where Data<=@datasus and valuta<>''
				) crs
			WHERE crs.rn=1

		end

		if OBJECT_ID('tempdb..#DifFactura') is not null drop table #DifFactura
		if OBJECT_ID('tempdb..#doc_inserate') is not null drop TABLE #doc_inserate
		create table #doc_inserate(numar varchar(40))

		/* se preiau datele in tabela #pfacturi prin procedura pFacturi (in locul functiei fFacturiCen) */
		if object_id('tempdb..#pfacturi') is not null 
			drop table #pfacturi
		create table #pfacturi (subunitate varchar(9))
		exec CreazaDiezFacturi @numeTabela='#pfacturi'
		set @parXMLFact=(select @tipcor as furnbenef, null as datajos, convert(char(10),@datasus,101) as datasus, 1 as cen, rtrim(@partert) as tert, rtrim(@parconttert) as contfactura for xml raw)
		exec pFacturi @sesiune=null, @parXML=@parXMLFact

		--sold in valuta,sold in lei
		select 
			a.factura,a.data,a.data_scadentei,a.tert,a.cont_factura,a.valuta,a.curs as curs_factura,
			a.sold_valuta,a.sold,a.loc_de_munca,a.comanda,b.curs as curs_la_data,
			rtrim(@paridentdoc)+replace(str(@maxnumar+dense_rank() over (order by a.tert),4),' ','0') as numar, 
			@maxpoz+row_number() over (partition by a.tert order by a.factura) as numar_pozitie
		into #DifFactura
		from #pfacturi a
		--from dbo.fFacturiCen(@Tipcor, null, @datasus, @partert, null, 1, 1, @parconttert, 0, 0, null) a
		left outer join #tmpcursuri b on b.Valuta=a.Valuta
		where 
			a.valuta<>'' 
			and (ISNULL(@parvaluta,'')='' or a.valuta=@parvaluta) 
			and (abs(a.sold_valuta)>=0.01 or abs(a.sold_valuta)<0.01 and abs(a.sold)>=0.01)
			and abs(b.curs*a.sold_valuta-a.sold)>=0.01
		order by a.tert,a.data,a.factura

		--inserez in pozadoc datele cu nrdoc din tabela temporara. Pun numerele de document se insereaza in tabela temporara pt. a nu dubla conditia de WHERE
		insert into pozadoc(Subunitate,Numar_document,Data,Tert,Tip,Factura_stinga,Factura_dreapta,
			Cont_deb,Cont_cred,Suma,TVA11,TVA22,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,
			Tert_beneficiar,Explicatii,Valuta,Curs,Suma_valuta,Cont_dif,suma_dif,Loc_munca,Comanda,
			Data_fact,Data_scad,Stare,Achit_fact,Dif_TVA,Jurnal,detalii)
		OUTPUT inserted.Numar_document
		into #doc_inserate(numar) 
		select @subunitate,a.numar,@datasus,a.tert,(case when @TipCor='B' then 'FB' else 'FF' end),
			(case when @TipCor='B' then a.factura else '' end),(case when @TipCor='B' then '' else a.factura end),
			(case when @TipCor='B' then a.cont_factura 
				else (case when ISNULL(@contprov,'')<>'' then @contprov 
					else (case when (a.curs_la_data*a.sold_valuta-a.sold)>0 then @contcheltfurn else @contvenfurn end) end) end),
			(case when @TipCor='B' then (case when ISNULL(@contprov,'')<>'' then @contprov 
					else (case when (a.curs_la_data*a.sold_valuta-a.sold)>0 then @contvenben else @contcheltben end) end) 
				else a.cont_factura end),
			convert(decimal(12,2),a.curs_la_data*a.sold_valuta-a.sold),0,0,@user,
			convert(datetime, convert(char(10), getdate(), 104), 104),
			RTrim(replace(convert(char(8), getdate(), 108), ':', '')),
			a.numar_pozitie,'',
			left((case when ISNULL(@contprov,'')<>'' then 'PROVIZIOANE ' else 'DIF. DE CONV.' end)
			+'=cnXsv-sl='+ltrim(convert(decimal(12,4),a.curs_la_data))/*+',cv:'+ltrim(convert(decimal(12,4),a.curs_factura))*/+'X'+ltrim(convert(decimal(14,2),a.sold_valuta))+'-'+ltrim(convert(decimal(14,2),a.sold))
			,50),
			a.valuta,a.curs_la_data,0,'',0,
			a.loc_de_munca,(case when @validcomstrict=1 and a.comanda='' then @comandaGenerica else a.comanda end),a.data,a.data_scadentei,5,0,0,'',
			(select 1 as difconv for xml raw)
		from #DifFactura a
		where /*(@parprovizioane=1 or sold_valuta*(curs_la_data-curs_factura)>0)*/ --abs(sold_valuta)>0.01 and 
			abs(curs_la_data*sold_valuta-sold)>=0.01

		if object_id('tempdb..#DocDeContat') is not null
			drop table #DocDeContat
		else
			create table #DocDeContat (subunitate varchar(9), tip varchar(2), numar varchar(40), data datetime)

		insert into #DocDeContat (subunitate, tip, numar, data)
		select distinct @subunitate, (case when @TipCor='B' then 'FB' else 'FF' end), numar, @datasus
		from #doc_inserate

		
		IF ISNULL((select val_logica from par where tip_parametru='GE' and parametru='PROVIZ'),0)=1
		begin
			declare
				@data_prov datetime, @cCliIncerti varchar(20), @cClienti varchar(20), @xmlp xml

			select @cCliIncerti=RTRIM(Val_alfanumerica) from par where tip_parametru='GE' and parametru='CONTCIN'
			IF @cCliIncerti IS NULL
				set @cCliIncerti='4118'
			select @cClienti=RTRIM(Val_alfanumerica) from par where tip_parametru='GE' and parametru='CONTBENEF'
			IF @cClienti IS NULL
				set @cClienti='4111'	

			/* In situatia in care in aceasi luna unei facturi i se calculeaza Dif. de curs, acestea trebuie sa reflecte contul corect al facturii, inainte de a fi afectat de proviz.*/
			update pa
				set pa.Cont_deb=@cClienti
			from PozAdoc pa 
			JOIN #doc_inserate di on pa.Subunitate=@subunitate and pa.Tip='FB' and pa.Numar_document=di.numar and pa.data=@datasus
			JOIN Provizioane pr on pr.tert=pa.Tert and pr.factura=pa.Factura_stinga and pr.datalunii=dbo.eom(@datasus)
			where @TipCor='B' and pa.Cont_deb=@cCliIncerti
		end

		exec fainregistraricontabile @dinTabela=2

		if OBJECT_ID('tempdb..#DifFactura') is not null drop table #DifFactura
		if OBJECT_ID('tempdb..#DocDeContat') is not null drop table #DocDeContat
		if OBJECT_ID('tempdb..#doc_inserate') is not null drop table #doc_inserate
		if OBJECT_ID('tempdb..#pfacturi') is not null drop table #pfacturi
end
