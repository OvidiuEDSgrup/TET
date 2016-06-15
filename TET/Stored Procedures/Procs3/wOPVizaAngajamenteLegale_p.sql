--***
create procedure [dbo].[wOPVizaAngajamenteLegale_p] @sesiune varchar(50), @parXML xml 
as  
begin try
declare @data_CFP datetime,
		@eroare xml, @mesaj varchar(254),@update bit,@dentert varchar(50)

declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
select 
		
	@data_CFP= ISNULL(data_ordonantare,'')
	 
	from OPENXML(@iDoc, '/row') 
	WITH 
	(		
		data_ordonantare datetime '@data_ordonantare'
		
		
	)
exec sp_xml_removedocument @iDoc 	

if @update=1
	return
		
select  convert(char(10),@data_CFP,101) data_CFP
for xml raw

end try	
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
