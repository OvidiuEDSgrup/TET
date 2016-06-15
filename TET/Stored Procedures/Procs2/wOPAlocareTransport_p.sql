
CREATE PROCEDURE wOPAlocareTransport_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'wOPAlocareTransport_pSP')
	BEGIN
		exec wOPAlocareTransport_pSP @sesiune=@sesiune, @parXML=@parXML OUTPUT

		IF @parXML IS NULL
			RETURN
	END

	declare
		@grupare varchar(200), @utilizator varchar(100), @grupare_fact varchar(20), @idContract int, @rootDoc varchar(200)

	select
		@grupare = ISNULL(@parXML.value('(/*/@grupare)[1]','varchar(100)'),''),
		@idContract=NULLIF(@parXML.value('(/*/@idcontract)[1]','int'),0)

	select top 1 @grupare_fact = convert(varchar(10), stare) from StariContracte where tipContract='CL' and facturabil=1

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	DECLARE @iDoc INT
	
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	if @parXML.exist('(/*/*/@idcontract)')=1 --Daca exista 2 nivele->selectie multipla 
		set @rootDoc='/*/*' 
	else
		set @rootDoc='/*' 

	select 
		idContract,numar,grupare
	into #comenziDeAlocat	
	from OPENXML(@iDoc, @rootDoc)
	WITH 
	(
		idContract int '@idcontract',
		numar varchar(20) '@numar',
		grupare varchar(100) '@grupare'
	)

	exec sp_xml_removedocument @iDoc 	
	
	if exists (select 1 from #comenziDeAlocat where isnull(grupare,'')<>@grupare_fact)
		raiserror ('Doar comenzile din gruparea "De transportat" pot fi adaugate pe transporturi!',16,1)

	IF exists(select 1 from #comenziDeAlocat where idContract is null)
		raiserror ('Selectati comenzile pentru a fi adaugate pe transport (din gruparea "De transportat")!',16,1)		
	
END TRY
BEGIN CATCH
	SELECT 1 as inchideFereastra for xml raw, root('Mesaje')
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
