--***
create procedure [dbo].[wOPSchimbareStareAngBug_p] @sesiune varchar(50), @parXML xml 
as  
begin try
declare @datam datetime,
		@eroare xml, @mesaj varchar(254),@update bit,@dentert varchar(50)

declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
select 
		
	@datam= ISNULL(data,'')
	 
	from OPENXML(@iDoc, '/row') 
	WITH 
	(		
		data datetime '@data'
		
		
	)
exec sp_xml_removedocument @iDoc 	

if @update=1
	return
		
select  convert(char(10),@datam,101) datam
for xml raw

end try	
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
