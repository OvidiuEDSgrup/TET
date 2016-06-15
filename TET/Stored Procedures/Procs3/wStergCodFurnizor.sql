--***
Create procedure [dbo].[wStergCodFurnizor]   @sesiune varchar(30), @parXML XML
as
begin try
declare @cod varchar(20), @tert varchar(20), @datapret varchar(20)
select @cod = @parXML.value('(/row/@cod)[1]','varchar(20)'),
	   @tert = @parXML.value('(/row/row/@tert)[1]','varchar(20)'),
	   @datapret = @parXML.value('(/row/row/@datapret)[1]','varchar(20)')

delete from ppreturi where Cod_resursa=@cod and tert=@tert and Data_pretului=convert(datetime,@datapret,101)

end try
begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
