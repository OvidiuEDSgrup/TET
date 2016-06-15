
CREATE PROCEDURE wOPFacturareComandaTransport @sesiune VARCHAR(50), @parXML XML
as
begin try
	/**

		Procedura creaza un cursor care parcurge comenzile de livrare aferente unei comenzi de transport (CT), iar pentru acestea
		creaza un document xml cu antetul (tert, gestiune, etc) din CL, si pozitiile aferente cu cantitati din CT, generand Legaturi pentru CT cu pozdoc si 
		prin legaturile anteriore (CT,CL) avem si acestea


	**/
	declare 
		@comanda int, @mesaj varchar(max), @doc_fact xml , @id_cl int, @ft int,@data datetime,@doc_jurnal xml,@stare_transport int,

		/** Date factura */
		@numeDelegat VARCHAR(30), @mijlocTransport VARCHAR(30), @nrMijlocTransport VARCHAR(20), @seriaBuletin VARCHAR(10), 
		@numarBuletin VARCHAR(10), @eliberat VARCHAR(30), @observatii VARCHAR(200), @stare_comanda int, @detalii xml


	set @comanda=@parXML.value('(/*/@idContract)[1]','int')
	SET @data = isnull(@parXML.value('(/*/@data)[1]', 'datetime'), GETDATE())

	/** Variabile pt scrierea in AnexFac **/
	SET @numeDelegat = @parXML.value('(/*/detalii/row/@dendelegat)[1]', 'varchar(30)')
	SET @mijlocTransport = @parXML.value('(/*/detalii/row/@mijloctp)[1]', 'varchar(30)')
	SET @nrMijlocTransport = @parXML.value('(/*/detalii/row/@numarmijloctp)[1]', 'varchar(20)')
	SET @seriaBuletin = @parXML.value('(/*/detalii/row/@seriabuletin)[1]', 'varchar(10)')
	SET @numarBuletin = @parXML.value('(/*/detalii/row/@numarbuletin)[1]', 'varchar(10)')
	SET @eliberat = @parXML.value('(/*/detalii/row/@eliberat)[1]', 'varchar(30)')
	SET @observatii = @parXML.value('(/*/@observatii)[1]', 'varchar(200)')

	if @parXML.exist('(/*/detalii)[1]')=1
		SET @detalii = @parXML.query('(/*/detalii/row)[1]')

	IF OBJECT_ID('tempdb..#pt_factura') IS NOT NULL
		drop table #pt_factura

	select
		pLiv.cod, pLiv.idPozContract, pLiv.idContract idContract, pTran.cantitate, comLiv.numar, pLiv.pret, pLiv.discount, comLiv.valuta, comLiv.curs, comLiv.tert 
	into #pt_factura
	from PozContracte pTran
	JOIN LegaturiContracte leg on pTran.idPozContract=leg.idPozContract and pTran.idContract=@comanda
	JOIN PozContracte pLiv on pLiv.idPozContract=leg.idPozContractCorespondent
	JOIN Contracte comLiv on comLiv.idContract=pLiv.idContract

	set @doc_fact= 
	(
		select
			@data data_facturii, '1' fara_mesaje, @detalii detalii,		 		
			/*Delegat*/
			@observatii observatii,@mijlocTransport mijloctransport, @nrMijlocTransport nrmijloctransport, @seriaBuletin seriabuletin, 
			@numarBuletin numarbuletin, @eliberat eliberat, @numeDelegat numedelegat,
			(
				select
					idContract, idPozContract, tert, valuta, curs, numar numar_contract, cod, convert(decimal(15,2),cantitate) cantitate, convert(decimal(15,2),pret) pret ,convert(decimal(15,2),discount) discount
				from #pt_factura
				for XML raw, ROOT('DateGrid'), type
			)				
		for xml raw('parametri')
	)
	
	exec wOPFacturareContracte @sesiune=@sesiune, @parXML=@doc_fact

	/* Jurnalizam facturarea comenzii si o declaram realizata */	
	select top 1 @stare_transport=stare from StariContracte where tipContract='CT' and ISNULL(inchisa,0)=1
	set @doc_jurnal=(select @comanda idContract, GETDATE() data, 'Facturare comanda transport' explicatii, @stare_transport stare for xml raw)
	exec wScriuJurnalContracte @sesiune=@sesiune,@parXML=@doc_jurnal

end try
begin catch
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch
