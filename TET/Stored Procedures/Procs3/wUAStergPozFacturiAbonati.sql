--***
/****** Object:  StoredProcedure [dbo].[wUAStergPozFacturiAbonati]    Script Date: 01/05/2011 23:08:45 ******/
create procedure  [dbo].[wUAStergPozFacturiAbonati]  @sesiune varchar(50), @parXML xml
as
begin try
	DECLARE @id int,@nr_pozitie int ,@tip varchar(2),@subtip varchar(2)      
     select
         @id = isnull(@parXML.value('(/row/@id)[1]','int'),''),
         @nr_pozitie= isnull(@parXML.value('(/row/@nr_pozitie)[1]','int'),''),
         @tip=isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),''),
         @subtip=isnull(@parXML.value('(/row/row/@subtip)[1]','varchar(2)'),'')
         
         
declare @mesajeroare varchar(100)
begin
	
	if exists (select id_factura from IncasariFactAbon where id_factura=@id )
		begin
			set @mesajeroare='Nu poate fi stearsa o factura care a fost incasata!!'
			raiserror(@mesajeroare,11,1)
		end
	if @subtip='' and exists (select Id_factura from PozitiiFactAbon where Id_factura=@id)	
			begin
			set @mesajeroare='Antetul unei facturi nu poate fi sters decat dupa stergerea tuturor pozitiilor facturii!!'
			raiserror(@mesajeroare,11,1)
		end	
	
	if @subtip<>''
		delete from PozitiiFactAbon where Id_factura=@id and Nr_pozitie=@nr_pozitie
	else
		delete from AntetFactAbon where Id_factura=@id

declare @docXML xml
	--set @docXML='<row id="'+rtrim(@id)+'"/>'
	set @docXML='<row id="'+rtrim(@id)+'" tip="'+@tip+'"/>'
	exec wUAIaPozFacturiAbonati @sesiune=@sesiune, @parXML=@docXML
end	

end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
--select * from IncasariFactAbon
