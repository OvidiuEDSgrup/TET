
CREATE PROCEDURE wOPSchimbGestiuneComandaCen_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	declare
		@grupare varchar(20), @idContract int

	select
		@grupare = ISNULL(@parXML.value('(/row/@grupare)[1]','varchar(100)'),''),
		@idContract = NULLIF(@parXML.value('(/row/@idcontract)[1]','int'),0)

	IF @idContract is null
		raiserror('Selectati o comanda din sectiunea "Comenzi nealocate" pentru a-i schimba gestiunea!',16,1)

	IF @grupare <> 'N'
		raiserror('Doar gestiunea comenzilor "nealocate" poate fi schimbata!',16,1)
	
END TRY
BEGIN CATCH
	select 1 as inchideFereastra for xml raw, root('Mesaje')
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
