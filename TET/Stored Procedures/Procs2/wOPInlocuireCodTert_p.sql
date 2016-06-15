
Create PROCEDURE wOPInlocuireCodTert_p @sesiune VARCHAR(50), @parXML XML
AS
begin try
	select @parXML for xml path('Date')
end try
begin catch

	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
