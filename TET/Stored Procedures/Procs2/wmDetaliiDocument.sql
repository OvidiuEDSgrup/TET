
create procedure wmDetaliiDocument @sesiune varchar(50), @parXML xml as

if exists(select * from sysobjects where name='wmDetaliiDocumentSP' and type='P')
begin
	exec wmDetaliiDocumentSP @sesiune=@sesiune, @parXML=@parXML
	return 0
end
begin try
	declare
		@numar varchar(20), @data datetime,@pozitii xml, @antet xml, @adauga_pozitie xml,@utilizator varchar(100), @formular xml,
		@tip varchar(2), @form_antet varchar(20), @form_pozitie varchar(20), @proc_scriere_antet varchar(20), @codFormular varchar(100),
		@gestiune varchar(20), @dengestiune varchar(100), @tert varchar(20), @dentert varchar(100),
		@gestiune_primitoare varchar(20), @dengestiune_primitoare varchar(100), @lm varchar(20), @denlm varchar(100), @cont_coresp varchar(20), @dencont_coresp varchar(100), @meniu varchar(20),
		@factura varchar(20), @data_factura datetime, @searchText varchar(200), @dinComanda xml, @amComanda bit = 0, @idComanda int,
		@focusSearch char(1), @incurs bit, @initializare bit, @schimbare_stare xml, @areMeniu int


	SELECT
		@numar=@parXML.value('(/*/@numar)[1]','varchar(20)'),
		@data=convert(datetime,@parXML.value('(/*/@data)[1]','varchar(10)')),
		@tip=@parXML.value('(/*/@tip)[1]','varchar(2)'),
		@meniu=@parXML.value('(/*/@meniuParinte)[1]','varchar(20)'),
		@form_antet=@parXML.value('(/*/@form_antet)[1]','varchar(20)'),
		@form_pozitie=@parXML.value('(/*/@form_pozitie)[1]','varchar(20)'),
		@proc_scriere_antet=@parXML.value('(/*/@proc_scriere_antet)[1]','varchar(20)'),
		@searchText = @parXML.value('(/*/@searchText)[1]','varchar(100)')

	select @incurs=0, @initializare=0
	if exists(select 1 from StariDocumente where inCurs=1)
		select @incurs=1

	if exists(select 1 from jurnaldocumente jd inner join StariDocumente sd on jd.stare=sd.stare where tip=@tip and numar=@numar and data=@data and initializare=1)
		select @initializare=1

	select	@focusSearch = (case when parametru='FOCUSNOM' then convert(char,Val_logica) else @focusSearch end)
	from par
	where Tip_parametru='AM' and Parametru in ('FOCUSNOM')

	if @focusSearch!='1'
		set @focusSearch=null

	IF OBJECT_ID('tempdb..#temp_doc') IS NOT NULL
		drop table #temp_doc

	select *
	into #temp_doc
	from doc d
	where d.Numar=@numar and d.tip=@tip and d.data=@data and d.Subunitate='1'

	if @numar is not null
		select top 1
			@gestiune=RTRIM(d.cod_gestiune),
			@tert=RTRIM(d.cod_tert), @dentert=rtrim(t.denumire),
			@lm=rtrim(loc_munca),
			@gestiune_primitoare=d.Gestiune_primitoare,
			@cont_coresp=d.detalii.value('(/*/@contcoresp)[1]','varchar(20)'),
			@data=data,
			@data_factura=Data_facturii,
			@factura=factura,
			@idComanda=d.Contractul,
			@amComanda =(case when NULLIF(contractul,'') IS NOT NULL then 1 else 0 end)
		from #temp_doc d
		LEFT JOIN terti t on t.tert=d.Cod_tert
		where d.Numar=@numar and d.tip=@tip and d.data=@data and d.Subunitate='1'
	/** Daca se adauga un document sugeram de la utilizator */
	else
	begin
		exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
		select
			@gestiune = rtrim(dbo.wfProprietateUtilizator('GESTIUNE', @utilizator)),
			@lm=rtrim(dbo.wfProprietateUtilizator('LOCMUNCA', @utilizator))
	end

	select top 1 @denlm= rtrim(Denumire) from lm where Cod=@lm
	select top 1 @dengestiune=RTRIM(denumire_gestiune) from gestiuni where cod_gestiune=@gestiune and Subunitate='1'
	select top 1 @dengestiune_primitoare=RTRIM(denumire_gestiune) from gestiuni where cod_gestiune=@gestiune_primitoare and Subunitate='1'
	select top 1 @dencont_coresp= rtrim(Denumire_cont) from conturi where cont=@cont_coresp

	exec wAreMeniuMobile 'antet',@utilizator,@areMeniu output
	if @areMeniu=1
		set @antet=
		(
			SELECT
				'adaugare' cod, 'Detalii antet' denumire, '0x0000ff' as culoare,'D' as tipdetalii,
				@proc_scriere_antet procdetalii,'assets/Imagini/Meniu/Contracte.png' as poza,
				ISNULL('Nr. '+rtrim(@numar)+ ' - Data '+ convert(varchar(10), @data, 103),'Completeaza date antet') info,
				dbo.f_wmIaForm(@form_antet) as form, '1' as toateAtr,
				@numar numar, @tip tip,
				@tert tert, @dentert dentert,
				@gestiune gestiune, @dengestiune dengestiune,
				@gestiune_primitoare gestiune_primitoare, @dengestiune_primitoare dengestiune_primitoare,
				@lm lm, @denlm denlm,
				@cont_coresp contcoresp, @dencont_coresp dencontcoresp,
				convert(varchar(10), @data, 101) data,
				convert(varchar(10), @data_factura, 101) data_factura,
				@factura factura
			for xml raw,type
		)

	/* Daca am definita asociere intre tip de document si tip de comanda
	   pot adauga un antet din detalii existente in comanda
	*/
	exec wAreMeniuMobile 'dinComanda',@utilizator,@areMeniu output
	IF (@numar IS NULL) and (dbo.wfIaTipComandaDocument(@tip) IS NOT NULL) and (@areMeniu=1)
		set @dinComanda =
		(
			select
				'adaugare' cod, 'Din comanda' denumire, '0x0000ff' as culoare,'C' as tipdetalii,
				'wmAdaugDocumentDinComanda' procdetalii,'assets/Imagini/Meniu/Contracte.png' as poza,
				'Selecteaza comanda' info, '1' as toateAtr
			for xml raw,type
		)

	/** La adaugare document se autoselecteaza informatiile de antet, daca am deja antetul, atunci nu */
	if @numar IS NULL and @dinComanda IS NULL
		select 'autoSelect' as actiune for xml raw, ROOT('Mesaje')

	exec wAreMeniuMobile 'adaugaPozitie',@utilizator,@areMeniu output
	if @areMeniu=1
		set @adauga_pozitie=
		(
			select top 1
				'adaugarePoz' cod, 'Adauga pozitie' denumire, '0x0000ff' as culoare,'C' as tipdetalii, 'wmAlegCodDocumente' procdetalii,
				'assets/Imagini/Meniu/AdaugProdus32.png' as poza,
				'wmScriuPozitieDocument' proc_detalii_next,
				@form_pozitie as meniu_detalii_next,
				'1' as toateAtr,
				CONVERT(varchar(10),Numar_pozitii) + ' pozitii' info,
				rtrim(Cod_tert) tert,
				rtrim(Cod_gestiune) gestiune,
				rtrim(Loc_munca) lm,
				rtrim(Gestiune_primitoare) gestiune_primitoare,
				detalii.value('(/*/@contcoresp)[1]','varchar(20)') contcoresp,
				convert(varchar(10), data, 101) data,
				convert(varchar(10), data_facturii, 101) data_factura,
				RTRIM(factura) factura,
				@searchText searchText,
				'back(1)' [wmScriuPozitieDocument.actiune]
			from #temp_doc where tip=@tip and numar=@numar and data=@data
			for xml raw, type
		)

	exec wAreMeniuMobile 'schimbareStare',@utilizator,@areMeniu output
	if @areMeniu=1
		select @schimbare_stare = 
		(
			select top 1
				'sc_stare' cod, 'Inchidere document' denumire, '0x0000ff' as culoare,'C' as tipdetalii, 'wmConfirmareInchidereDocument' procdetalii,
				'assets/Imagini/Meniu/realizari.png' as poza,
				'1' as toateAtr,
				@tip as tip,
				@numar as numar,
				@data as data
			for xml raw, type
		)

	/* Daca primim searchText si avem antet, poate fi un cod scanat, atunci mergem automat la adaugare pozitie*/
	IF NULLIF(@searchText,'') IS NOT NULL
	BEGIN
		SELECT * INTO #gs1 from dbo.wfDecodareGS1(@searchText)

		set @parXML.modify('delete (/row/@searchText)[1]')		

		/* daca am scanat cod GS1 */
		IF EXISTS (select 1 from #gs1) 
		BEGIN
			declare @xml_gs1 xml
			set @xml_gs1 = (select @tip tip, @numar numar, @data data, @searchText codgs1 for xml raw, type)
			exec wmScriuPozitieDocument @sesiune=@sesiune, @parXML=@xml_gs1

			exec wmDetaliiDocument @sesiune=@sesiune, @parXML=@parXML

		END
		else
		/* Cod de bare simplu	*/
		begin
			exec adaugaAtributeXml @parXML, @adauga_pozitie output
			
			declare @cod varchar(20), @um varchar(3), @err_flag bit = 0
			select top 1 @cod=cod_produs, @um=umprodus from codbare where cod_de_bare=@searchText

			set @adauga_pozitie.modify('delete (/row/@cod)[1]')
			set @adauga_pozitie.modify('delete (/row/@um)[1]')
			set @adauga_pozitie.modify('insert attribute cod {sql:variable("@cod")} into (/row)[1]')
			set @adauga_pozitie.modify('insert attribute um {sql:variable("@um")} into (/row)[1]')
			set @adauga_pozitie.modify('delete (/row/@wmScriuPozitieDocument.actiune)[1]')
			set @adauga_pozitie.modify('insert attribute wmScriuPozitieDocument.actiune {"refresh"} into (/row)[1]')
			
			if (@initializare = 1) and not exists (select 1 from pozdoc where subunitate='1' and tip=@tip and numar=@numar and data=@data and cod=ISNULL(@cod,''))
			begin
				set @err_flag = 1
				select 'Eroare' titluMesaj, 'Nu s-a gasit codul scanat pe acest document.' textMesaj for xml raw, root('Mesaje')
			end

			if (@initializare=0) and not exists(select 1 from nomencl where cod=@cod)
			begin
				set @err_flag = 1
				select 'Eroare' titluMesaj, 'Nu s-a gasit codul scanat in nomenclator.' textMesaj for xml raw, root('Mesaje')
			end

			if (@cod is not null) and (@err_flag=0)
				exec wmScriuPozitieDocument @sesiune=@sesiune, @parXML=@adauga_pozitie

			exec wmDetaliiDocument @sesiune=@sesiune, @parXML=@parXML

		end
		select '1' clearSearch for xml raw, root('Mesaje')
		RETURN
	END

	/*
		"Pozitiile" pe care le aratam sunt dinamice: daca am comanda arat colorat in fucntie de cat s-a scanat
		Daca nu se "lucreaza" cu comanda, nu afecteaza nimic
	*/


	IF OBJECT_ID('tempdb.dbo.#pozitii') IS NOT NULL
		drop table #pozitii
	create table #pozitii (cod varchar(20), cantitate_com float,cantitate_doc float, pstoc float, pvaluta float, idpozdoc int, culoare varchar(10), info varchar(500), detalii xml)

	IF @amComanda = 1
	begin
		INSERT INTO #pozitii (cod, cantitate_com,pstoc,pvaluta)
		select
			pc.cod, pc.cantitate,pret,pret
		from Contracte c
		JOIN PozContracte pc on pc.idContract=c.idContract
		JOIN #temp_doc td on c.idContract=td.Contractul

		INSERT INTO #pozitii (cod, cantitate_com,cantitate_doc,pstoc,pvaluta)
		select pd.cod, 0, sum(pd.cantitate ), max(pret_de_stoc), max(pret_valuta)
		from pozdoc pd
		LEFT JOIN PozContracte pc on pc.idContract=@idComanda and pc.cod=pd.cod
		where pd.tip=@tip and pd.numar=@numar and pd.data=@data and pd.Subunitate='1' and pc.cod is null
		group by pd.cod

		update p
			set cantitate_doc=pd.cantitate, pstoc=pd.pstoc, idpozdoc=pd.idpozdoc, pvaluta=pd.pvaluta
		from #pozitii p
		JOIN (select cod, sum(cantitate) cantitate, max(Pret_de_stoc) pstoc, max(pret_valuta) pvaluta, max(idpozdoc) idpozdoc from pozdoc where tip=@tip and numar=@numar and data=@data and Subunitate='1' group by cod) pd
			ON p.cod=pd.cod

		update #pozitii
			set culoare = (case when ISNULL(cantitate_doc,0)=0 then '0xFF0000' when ISNULL(cantitate_doc,0)<cantitate_com then '0xFFA500' else '0x008000' end),
				info = 'Cant.com. '+ convert(varchar(10), convert(decimal(15,2),ISNULL(cantitate_com,0))) + ' - Cant.doc. '+convert(varchar(10), convert(decimal(15,2),ISNULL(cantitate_doc,0)))
	end

	else		
		begin
			INSERT INTO #pozitii (cod, cantitate_com, cantitate_doc, pstoc, pvaluta, idpozdoc , detalii)
			select
				cod, isnull(detalii.value('(/*/@cant_scriptica)[1]','decimal(12,3)'),0), cantitate, Pret_de_stoc, Pret_valuta, idpozdoc, detalii
			From Pozdoc
			where tip=@tip and numar=@numar and data=@data and subunitate='1'

		update #pozitii
				set info ='Cantitate scanata '+ convert(varchar(10), convert(decimal(15,2),cantitate_doc)) + ' - scriptica ' + CONVERT(varchar(10), convert(decimal(15,3),cantitate_com)) where @tip='RM'
		
		end

	if @inCurs=1 and @initializare=1
	begin
		update #pozitii
			set culoare = (case when cantitate_com is null then '0x0000FF'									-- Albastru
								when cantitate_com = cantitate_doc then '0x808080'							-- Gri
								when cantitate_doc <> 0 and cantitate_doc <> cantitate_com then '0xAA0000'	-- Rosu
								when cantitate_doc = 0 then '0xFFFFFF'										-- Alb
							end)
	end

	exec wAreMeniuMobile 'pozitii',@utilizator,@areMeniu output
	if @areMeniu=1
		set @pozitii=
		(
			SELECT
				rtrim(pd.cod) + ' - ' + rtrim(n.denumire) as denumire,
				'wmScriuPozitieDocument' procdetalii,
				'D' as tipdetalii,
				dbo.f_wmIaForm(@form_pozitie) as form,
				(case when @amComanda = 0 or @amComanda = 1 and cantitate_doc IS NOT NULL then 1 else 0 end ) as [update],
				1 as toateAtr,
				pd.idpozdoc idpozdoc,
				pd.info as info,
				RTRIM(pd.cod) as cod, convert(decimal(15,2),ISNULL(pd.cantitate_doc, pd.cantitate_com)) cantitate,
				RTRIM(@numar) numar, convert(varchar(10), @data,101) data,
				convert(decimal(15,5), pd.pvaluta) pvaluta,
				convert(decimal(15,5), pd.pstoc) pstoc,
				pd.culoare as culoare
			from #pozitii pd
			JOIN nomencl n on pd.cod=n.cod
			order by isnull(pd.detalii.value('(/row/@scanat)[1]','int'),0) desc, pd.idpozdoc desc
			for xml raw, TYPE
		)

	/* Formularul asociat acestui meniu de mobile (cu TOP 1 in caz ca s-au asociat mai multe...)*/
	select top 1 @codFormular=rtrim(cod_formular) from WebConfigFormulare where meniu=@meniu

	exec wAreMeniuMobile 'formular',@utilizator,@areMeniu output
	if @areMeniu=1
		set @formular=
		(
			select
				'Tipareste formular' as denumire, '0x0000ff' as culoare, 'assets/Imagini/Meniu/Bonuri.png' as poza,'1' as _toateAtr,
				@codFormular nrform, @tip tip, rtrim(numar) numar, convert(varchar,isnull(data,getdate()),101) data, rtrim(cod_tert) tert, rtrim(cod_gestiune) gestiune, '0' debug,
				'wmTiparesteFormularDocument' procdetalii
			from #temp_doc
			where ISNULL(@codFormular,'')<>''
			for xml raw, type
		)

	select
		(CASE @tip when 'PP' THEN 'Predarea ' when 'TE' then 'Transferul ' when 'AP' then 'Avizul ' when 'AI' then 'Alta intr.' when 'AE' then 'Alte iesire ' when 'RM' then 'Receptia ' end)+ rtrim(@numar) as titlu,
		'1' as areSearch, @focusSearch as focusSearch
	for xml RAW,ROOT('Mesaje')

	if isnull(@incurs,0)=0 or (@pozitii is null)
		set @schimbare_stare=null

	select @antet,@dinComanda, @formular, @adauga_pozitie, @schimbare_stare, @pozitii
	for xml PATH('Date')

end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch
