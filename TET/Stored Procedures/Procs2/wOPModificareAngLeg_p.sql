--***
create procedure [dbo].[wOPModificareAngLeg_p] @sesiune varchar(50), @parXML xml 
as  
begin try
declare @n_data_ordonantare datetime,@n_suma float,@n_numar_ang_bug varchar (20), 
		@eroare xml, @mesaj varchar(254),@update bit,@dentert varchar(50)

declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
select 
		
	@n_suma =ISNULL(n_suma,0),
	@n_numar_ang_bug= ISNULL(n_numar_ang_bug,''),
	@n_data_ordonantare= ISNULL(n_data_ordonantare,'')
	 
	from OPENXML(@iDoc, '/row') 
	WITH 
	(		
		n_suma float'@suma',
		n_numar_ang_bug varchar(20)'@numar_ang_bug',
		n_data_ordonantare datetime '@data_ordonantare'
		
	)
exec sp_xml_removedocument @iDoc 	
if @update=1
	return
		
select  rtrim(@n_suma) n_suma,convert(char(10),@n_data_ordonantare,101) n_data_ordonantare,rtrim(@n_numar_ang_bug) n_numar_ang_bug
for xml raw

end try	
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
