
CREATE PROCEDURE wOPAlocareTransport @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'wOPAlocareTransportSP')
	BEGIN
		exec wOPAlocareTransportSP @sesiune=@sesiune, @parXML=@parXML OUTPUT

		IF @parXML IS NULL
			RETURN
	END
	declare
		@grupare varchar(200), @utilizator varchar(100), @grupare_fact varchar(10),
		@idContract int, @numar_transport int, @rootDoc varchar(50)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	select
		@numar_transport = NULLIF(@parXML.value('(/*/@numar_transport)[1]','int'),0)
				
	IF @numar_transport not between 1 and 9
		raiserror('Transportul virtual selectat trebuie sa fie intre 1 si 9',16,1)
		
	select top 1 @grupare_fact = convert(varchar(10),  stare ) from StariContracte where tipContract='CL' and facturabil=1	
	
	DECLARE @iDoc INT
	
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	if @parXML.exist('(/*/*/@idcontract)')=1 --Daca exista 2 nivele->selectie multipla 
		set @rootDoc='/*/*' 
	else
		set @rootDoc='/*' 

	select 
		idContract,numar,gestiune_comanda
	into #comenziDeAlocat	
	from OPENXML(@iDoc, @rootDoc)
	WITH 
	(
		idContract int '@idcontract',
		numar varchar(20) '@numar',
		gestiune_comanda varchar(20) '@gestiune_comanda'
	)

	exec sp_xml_removedocument @iDoc 	

	update t set t.cantitate=t.cantitate_comanda, 
		t.grupare=RTRIM(@utilizator)+convert(varchar(10), @numar_transport) 
	from tmpArticoleCentralizatorTransport t
		inner join #comenziDeAlocat c on c.idContract=t.idContract
	where t.grupare=@grupare_fact
		
	--apel procedura specifica	
	if exists (select 1 from sysobjects where [type]='P' and [name]='wOPAlocareTransportSP1')
	begin
		exec wOPAlocareTransportSP1 @sesiune=@sesiune, @parXML=@parXML
	end

END TRY
BEGIN CATCH	
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
