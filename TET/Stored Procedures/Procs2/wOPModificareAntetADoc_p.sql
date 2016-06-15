--***
create procedure [dbo].[wOPModificareAntetADoc_p] @sesiune varchar(50), @parXML xml 
as  
begin try
declare  @tip char(2), @numar char(8), @data datetime, @n_numar varchar(20),@n_tert varchar(13),@n_data datetime,@n_tip varchar(2),
		@eroare xml, @mesaj varchar(254),@update bit,@dentert varchar(50)

declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
select 
		
	@n_numar =ISNULL(n_numar,''),
	@n_tert= ISNULL(n_tert,''),
	@n_data= ISNULL(n_data,''),
	@n_tip= ISNULL(n_tip,'')
	 
	from OPENXML(@iDoc, '/row') 
	WITH 
	(		
		n_numar varchar(20)'@numar',
		n_tert varchar(13)'@tert',
		n_data datetime '@data',
		n_tip varchar(2) '@tip'
		
	)
exec sp_xml_removedocument @iDoc 	
if @update=1
	return
		
select  rtrim(@n_tert) n_tert,convert(char(10),@n_data,101) n_data,@n_tip n_tip,rtrim(@n_numar) n_numar
for xml raw

end try	
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
