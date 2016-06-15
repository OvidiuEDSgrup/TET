
CREATE PROCEDURE wOPPopularePlanificareNoua_p @sesiune VARCHAR(50), @parXML XML
AS
begin try
	
	select 
		convert(varchar(10),dbo.bom(GETDATE()),101) datajos, convert(varchar(10), dbo.eom(GETDATE()),101) datasus, '08:00' orastart, '16:00' orastop
	for xml raw, root('Date')	

	
end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
