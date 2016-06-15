
CREATE PROCEDURE wOPDealocareTransportCentralizator_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	declare
		@grupare varchar(20), @idContract int, @docJurnal xml, @stare_fact int, @nivel int, @rootDoc varchar(50)

	select
		@grupare = ISNULL(@parXML.value('(/row/@grupare)[1]','varchar(100)'),'')

	select top 1 @stare_fact = convert(varchar(10),  stare )from StariContracte where tipContract='CL' and facturabil=1
	
	DECLARE @iDoc INT
	
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	if @parXML.exist('(/*/*/@idcontract)')=1 --Daca exista 2 nivele->selectie multipla 
		set @rootDoc='/*/*' 
	else
		set @rootDoc='/*' 

	select 
		idContract,numar
	into #comenzi	
	from OPENXML(@iDoc, @rootDoc)
	WITH 
	(
		idContract int '@idcontract',
		numar varchar(20) '@numar'
	)

	exec sp_xml_removedocument @iDoc 

	update t set grupare=@stare_fact
		from tmpArticoleCentralizatorTransport t
			inner join #comenzi c on c.idcontract=t.idcontract

	--apel procedura specifica	
	if exists (select 1 from sysobjects where [type]='P' and [name]='wOPDealocareTransportCentralizator_pSP1')
	begin
		exec wOPDealocareTransportCentralizator_pSP1 @sesiune=@sesiune, @parXML=@parXML
	end

	select '1' as inchideFereastra for xml raw, root('Mesaje')
END TRY
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' (wOPDealocareTransportCentralizator_p)'
	raiserror (@mesaj, 15, 1)
END CATCH
