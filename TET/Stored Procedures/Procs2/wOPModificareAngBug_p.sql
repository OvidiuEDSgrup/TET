--***
create procedure [dbo].[wOPModificareAngBug_p] @sesiune varchar(50), @parXML xml 
as  
begin try
declare @n_data datetime,@n_suma float,@n_indbug varchar (20), 
		@eroare xml, @mesaj varchar(254),@update bit,@dentert varchar(50)

declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
select 
		
	@n_suma =ISNULL(n_suma,0),
	@n_indbug= ISNULL(n_indbug,''),
	@n_data= ISNULL(n_data,'')
	 
	from OPENXML(@iDoc, '/row') 
	WITH 
	(		
		n_suma float'@suma',
		n_indbug varchar(20)'@indbug',
		n_data datetime '@data'
		
		
	)
exec sp_xml_removedocument @iDoc 	
if @update=1
	return
		
select  rtrim(@n_suma) n_suma,convert(char(10),@n_data,101) n_data,rtrim(@n_indbug) n_indbug
for xml raw

end try	
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
