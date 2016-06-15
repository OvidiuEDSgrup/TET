
CREATE PROCEDURE wOPSchimbGestiuneComandaCen @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	declare
		@gestiune_noua varchar(20), @idContract int

	select
		@gestiune_noua = ISNULL(@parXML.value('(/*/@gestiune_noua)[1]','varchar(100)'),''),
		@idContract = NULLIF(@parXML.value('(/*/@idcontract)[1]','int'),0)
	
	update Contracte set gestiune=@gestiune_noua where idContract=@idContract
	
END TRY
BEGIN CATCH
	select 1 as inchideFereastra for xml raw, root('Mesaje')
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
