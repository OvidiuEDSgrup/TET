
CREATE PROCEDURE wOPConfirmareTransfer_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	
	select '' data, '' numar for xml raw, root('Date')


END TRY
begin catch
	declare @mesaj varchar(4000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
