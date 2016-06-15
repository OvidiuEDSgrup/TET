
create procedure wOPGenerareDocumenteComenzi @sesiune varchar(50),@parXML xml
as
BEGIN TRY
	-- apelare procedura specIFica daca aceASta exista.
	IF EXISTS (SELECT 1 FROM sysobjects where [type]='P' AND [name]='wOPGenerareDocumenteComenziSP')
	BEGIN 
		DECLARE @returnValue INT -- variabila salveaza return value de la procedura specIFica
		EXEC @returnValue = wOPGenerareDocumenteComenziSP @sesiune, @parXML OUTPUT
		RETURN @returnValue
	END


	declare
		@imprimezDocument bit, @idContract int, @utilizator varchar(100), @docFactura xml, @data_factura datetime

	set @imprimezDocument=ISNULL(@parXML.value('(/*/@imprimezFacturi)[1]','BIT'),0)
	set @data_factura=@parXML.value('(/*/@data_facturii)[1]','datetime')

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	select top 1 @idContract= idContract from tmpComenziDePrelucrat where utilizator=@utilizator
	
	IF OBJECT_ID('tempdb..#facturi_scrise') IS NOT NULL
		drop table #facturi_scrise
	create table #facturi_scrise (factura varchar(20), data datetime)

	while EXISTS (select 1 from tmpComenziDePrelucrat where utilizator=@utilizator)
	BEGIN
		set @docFactura=
		(
			select top 1 
				gestiune gestiune, tert tert, loc_de_munca lm, @data_factura data, '1' fara_mesaj, '' observatii,
				'' mijloctransport, '' nrmijloctransport, '' seriabuletin, 
				'' numarbuletin, '' eliberat, '' numedelegat, @idContract idContract,
				(
					select
						p.idPozContract idPozContract, p.cod cod, p.pret pret, p.cantitate defacturat							
					from PozContracte p					
					where p.idContract=c.idContract
					for XML raw, ROOT('DateGrid'), type
				)				
			from Contracte  c where idContract=@idContract
			for xml raw
		)

		exec wOPGenerareFactura @sesiune=@sesiune, @parXML=@docFactura OUTPUT

		insert into #facturi_scrise(factura, data)
		select 
			xFact.row.value('@numar', 'varchar(20)'),
			@data_factura
		from @docFactura.nodes('/row') as xFact(row)

		delete from tmpComenziDePrelucrat where idContract=@idContract and utilizator=@utilizator
		select top 1 @idContract= idContract from tmpComenziDePrelucrat where utilizator=@utilizator
	END

	if @imprimezDocument=1
	BEGIN
		declare 
			@XML_print xml, @formular varchar(100), @numefisier varchar(100)


			/** Formularul folosit este cel ales in macheta **/
		select top 1 @formular=rtrim(numar_formular) from antForm where clFROM='procedura' and clwhere='formFactura'
		set @numefisier='Facturi '+@sesiune

		set @XML_print=
		(
			select
				@numefisier numefisier, @formular nrform,@formular formular,
				(
					select
						factura factura, data data_facturii
					from #facturi_scrise
					for xml raw,root('facturi'), type
				)
			for xml raw
		)
	
	select @XML_print
		EXEC wTipFormular @sesiune = @sesiune, @parXML = @XML_print
	END
END TRY
BEGIN CATCH
	declare @mesaj  varchar(max)
	set @mesaj=ERROR_MESSAGE()+ ' (wOPGenerareDocumenteComenzi)'
	raiserror(@mesaj, 16,1)
END CATCH
