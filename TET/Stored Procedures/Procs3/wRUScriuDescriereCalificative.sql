/* Procedura pentru completare descriere calificative */
--***
Create procedure wRUScriuDescriereCalificative @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUScriuDescriereCalificativeSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUScriuDescriereCalificativeSP @sesiune, @parXML output
	return @returnValue
end

declare	@mesajeroare varchar(500), @utilizator char(10), @userASiS varchar(20), @tip char(2),
	@id_descriere int, @id_calificativ int, @descriere_calificativ varchar(MAX), @update bit
begin try	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1
	      
    select 
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@id_descriere = isnull(@parXML.value('(/row/row/@id_descriere)[1]','int'),0),
		@id_calificativ = isnull(@parXML.value('(/row/@id_calificativ)[1]','int'),0),
		@descriere_calificativ =isnull(@parXML.value('(/row/row/@descriere_calificativ)[1]','varchar(MAX)'),'')
		
	if @update=1
		update RU_descriere_calificative set Descriere_calificativ=@descriere_calificativ
		where ID_calificativ=@id_calificativ and ID_descriere=@id_descriere
	else 
		insert into RU_descriere_calificative (ID_calificativ, Descriere_calificativ)
        select @id_calificativ, @descriere_calificativ
end try

begin catch
	set @mesajeroare = '(wRUScriuDescriereCalificative) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
