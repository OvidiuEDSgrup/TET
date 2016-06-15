CREATE PROCEDURE  wOPIncasareProforme @sesiune VARCHAR(50), @parXML XML OUTPUT
AS
BEGIN TRY
	declare
		@codAvans varchar(20), @idContract int, @suma float, @xml_jurnal xml, @xml_doc xml, @idJurnal int, @idPozDoc int,
		@tert varchar(20), @gestiune varchar(20), @data varchar(10), @lm varchar(20), @tipDoc varchar(2), @numarDoc varchar(20),
		@valuta varchar(10), @curs decimal(15,4), @idContractCorespondent int, @tert_extern int, @factura varchar(20),
		@valoare_proforma float, @incasat_proforma float, @suma_valuta float, @tipIncasare varchar(2), @valuta_proforma varchar(3),
		@curs_proforma float, @valoare_facturi_avans float, @stare_proforma_inchisa int, @tip_tva_tert varchar(1),@Cota_TVA float

	exec luare_date_par 'PV','CODAVBEN',0,0,@codAvans OUTPUT

	select
		@idContract = @parXML.value('(/*/*/@proforma)[1]','int'),
		@suma = isnull(@parXML.value('(/*/*/@suma)[1]','float'),0),
		@suma_valuta = isnull(@parXML.value('(/*/*/@suma_valuta)[1]','float'),0),
		@curs = isnull(@parXML.value('(/*/*/@curs)[1]','float'),@parXML.value('(/*/@curs)[1]','float')),
		@valuta=isnull(@parXML.value('(/*/*/@valuta)[1]','varchar(3)'),'')

	if @valuta=''
		set @valuta= isnull(@parXML.value('(/*/@valuta)[1]','varchar(3)'),'')
			
	select	
		@tert=tert, @gestiune=gestiune, @data=convert(varchar(10), GETDATE(), 101), @lm = loc_de_munca, @valuta_proforma=NULLIF(valuta,''), @curs_proforma=NULLIF(curs,0.0),
		@idContractCorespondent =idContractCorespondent
	from Contracte 
	where idContract=@idContract
	
	if @valuta<>@valuta_proforma
		raiserror ('Valuta introdusa diferita de valuta proformei!',11,1)

	if @valuta<>'' and isnull(@curs,0)=0
		raiserror('Introduceti cursul valutar!',11,1)

	select @tert_extern= tert_extern, @tip_tva_tert=isnull(ttva.tip_tva,'P') 
	from terti t 
		outer apply(select top 1 tip_tva from TvaPeTerti tv where tv.tert=t.tert and @data>tv.dela order by dela desc) ttva
	where t.tert=@tert and t.Subunitate='1'

	select @valoare_proforma=sum(pc.cantitate*pc.pret
					--daca proforma in RON sau proforma in valuta si tert extern si neplatitor de TVA, adaug si suma tva
					+(case when isnull(c.valuta,'')='' or (isnull(c.valuta,'')<>'' and @tert_extern=1 and @tip_tva_tert='N') then pc.cantitate*pc.pret*((n.Cota_TVA)/ 100) 
					else 0 end)),
			@Cota_TVA=max(n.cota_tva)
			from pozcontracte pc 
				inner join contracte c on c.idcontract=pc.idcontract
				inner join nomencl n on n.cod=pc.cod
			where pc.idContract=@idContract

	--daca nu s-a introdus suma pe macheta, calculez soldul proformei
	if isnull(@suma,0)=0 and isnull(@suma_valuta,0)=0
	begin 
		select @incasat_proforma=SUM(case when isnull(f.valuta,'')<>'' then f.achitat_valuta else f.Achitat end)
		from facturi f
			inner join (select distinct pd.factura, pd.tert, pd.Data_facturii
						from JurnalContracte jc
							JOIN LegaturiContracte lc on jc.idJurnal=lc.idJurnal and lc.idPozContract is null and lc.idPozContractCorespondent is null and jc.idContract=@idContract
							join pozdoc pd on pd.subunitate='1' and pd.idpozdoc=lc.idPozDoc) ft
				on ft.factura=f.Factura and ft.tert=f.Tert and ft.Data_facturii=f.Data and f.Tip=0x46

		set @suma=convert(decimal(17,2),isnull(@valoare_proforma,0)-isnull(@incasat_proforma,0))

		if isnull(@valuta,'')<>''
			set @suma_valuta=@suma
	end

	select @tipDoc='AS'

	set @xml_doc=
	(
		select
			@tipDoc tip, @tert tert, @gestiune gestiune, @data data, @lm lm,
			'1' fara_luare_date, '1' fara_mesaje, '1' returneaza_inserate,
			(
				select
					@codAvans cod, 1 cantitate, 
					convert(decimal(17,5),isnull(@suma,0)
						--daca proforma in RON sau proforma este in valuta si tert extern si neplatitor de TVA, factura de avans va avea suma TVA, de aceea scot suma tva din pvaluta
						/case when isnull(@valuta,'')='' or (isnull(@valuta,'')<>'' and @tert_extern=1 and @tip_tva_tert='N') then (1.00+@cota_TVA/100.00) else 1 end) pvaluta, 
					1 idlinie, @valuta valuta, @curs curs,
					case when isnull(@valuta,'')='' or (isnull(@valuta,'')<>'' and @tert_extern=1 and @tip_tva_tert='N') then null else 0 end as cotatva
				for xml raw, type
			)
		for xml raw, type
	)
	exec wScriuPozDoc @sesiune=@sesiune, @parXML=@xml_doc OUTPUT

	--jurnalizare generare factura de avans pe proforma
	SELECT @xml_jurnal = (SELECT @idContract idContract, GETDATE() data, 'Generare factura avans' explicatii FOR XML raw)
	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @xml_jurnal OUTPUT

	select 
		@idJurnal=@xml_jurnal.value('(/*/@idJurnal)[1]','int'),
		@idPozDoc=@xml_doc.value('(/row/docInserate/row/@idPozDoc)[1]','int')

	--legatura factura de avans cu proforma
	insert into LegaturiContracte(idJurnal, idPozDoc)
	SELECT @idJurnal, @idPozDoc

	--jurnalizare generare factura de avans in baza proformei pe comanda de livrare
	SELECT @xml_jurnal = (SELECT @idContractCorespondent idContract, GETDATE() data, 'Gen. factura avans in baza proforma' explicatii FOR XML raw)
	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @xml_jurnal OUTPUT

	select 
		@idJurnal=@xml_jurnal.value('(/*/@idJurnal)[1]','int')
	
	--leg factura de avans si de comanda de livrare initiala, astfel incat sa se poata face stornare avans automat la facturarea finala
	insert into LegaturiContracte(idJurnal, idPozDoc)
	SELECT @idJurnal, @idPozDoc

	--incasare factura de avans generata
	select top 1 @numarDoc=numar, @factura=factura
	from pozdoc p
	where idPozDoc=@idPozDoc
		and subunitate='1'
	-->generare inregistrari contabile
	exec faInregistrariContabile @dinTabela=0, @Subunitate='1', @Tip=@tipDoc, @Numar=@numarDoc, @Data=@data
	
	select @tipIncasare='IB'
	
	if isnull(@valuta,'')<>''--incasare in valuta
	begin
		--setez parametru sumavaluta
		if @parXML.value('(/row/row/@sumavaluta)[1]', 'float') is not null                          
			set @parXML.modify('replace value of (/row/row/@sumavaluta)[1] with sql:variable("@suma")') 
		else
			set @parXML.modify ('insert attribute sumavaluta{sql:variable("@suma")} into (/row/row)[1]') 

		--sterg parametru suma
		SET @parXML.modify('delete /row/row/@suma')

		select @tipIncasare='IV'
	end

	--pregatesc @parXML pentru apel procedura wScriuPlin
	if @parXML.value('(/row/row/@factura)[1]', 'varchar(20)') is not null                          
		set @parXML.modify('replace value of (/row/row/@factura)[1] with sql:variable("@factura")') 
	else
		set @parXML.modify ('insert attribute factura{sql:variable("@factura")} into (/row/row)[1]') 

	if @parXML.value('(/row/row/@subtip)[1]', 'varchar(2)') is not null                          
		set @parXML.modify('replace value of (/row/row/@subtip)[1] with sql:variable("@tipIncasare")') 
	else
		set @parXML.modify ('insert attribute subtip{sql:variable("@tipIncasare")} into (/row/row)[1]') 

	exec wScriuPlin @sesiune=@sesiune, @parXML=@parXML

	--daca proforma a fost realizata, jurnalizez realizarea
	select @valoare_facturi_avans=SUM(case when isnull(f.valuta,'')<>'' then f.Valoare_valuta else f.Valoare+f.TVA_22 end)
		from facturi f
			inner join (select distinct pd.factura, pd.tert, pd.Data_facturii
						from JurnalContracte jc
							JOIN LegaturiContracte lc on jc.idJurnal=lc.idJurnal and lc.idPozContract is null and lc.idPozContractCorespondent is null and jc.idContract=@idContract
							join pozdoc pd on pd.subunitate='1' and pd.idpozdoc=lc.idPozDoc) ft
				on ft.factura=f.Factura and ft.tert=f.Tert and ft.Data_facturii=f.Data and f.Tip=0x46
	
	if convert(decimal(17,2),@valoare_facturi_avans)>=convert(decimal(17,2),@valoare_proforma)--daca s-au generat facturi pentru intreaga valoare a proformei, finalizez proforma
	begin
		set @stare_proforma_inchisa=(select top 1 stare from StariContracte where tipcontract='PR' and inchisa=1 order by stare)

		SELECT @xml_jurnal = (SELECT @idContract idContract, @stare_proforma_inchisa stare ,GETDATE() data, 'Realizare Proforma' explicatii FOR XML raw)
		EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @xml_jurnal OUTPUT
	end

	/* Permitem un SP1 pt. anumite verificari, trimiteri email, schimbari de stari, samd specifice*/
	IF EXISTS (SELECT *	FROM sysobjects WHERE NAME = 'wOPIncasareProformeSP1')
		exec wOPIncasareProformeSP1 @sesiune=@sesiune, @parXML=@parXML

END TRY
BEGIN CATCH	
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
