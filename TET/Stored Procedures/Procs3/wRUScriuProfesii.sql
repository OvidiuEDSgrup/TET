/** procedura pentru scriere in catalogul RU_profesii **/
--***
Create procedure wRUScriuProfesii @sesiune varchar(50), @parXML xml
As
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUScriuProfesiiSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUScriuProfesiiSP @sesiune, @parXML output
	return @returnValue
end

declare	@mesajeroare varchar(500), @utilizator char(10), @id_profesie int, @denumire varchar(30), 
	@descriere varchar(max), @studii varchar(max), @update bit
begin try	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1
	       
    select 
		@update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
		@id_profesie = isnull(@parXML.value('(/row/@id_profesie)[1]','int'),0),
		@denumire =isnull(@parXML.value('(/row/@denumire)[1]','varchar(30)'),''),
		@descriere =isnull(@parXML.value('(/row/@descriere)[1]','varchar(max)'),''),
		@studii= isnull(@parXML.value('(/row/@studii)[1]','varchar(max)'),'')
         
	if @update=1
		update RU_profesii set denumire=@denumire,descriere=@descriere,studii=@studii
		where id_profesie=@id_profesie 
	else 
		insert into RU_profesii(denumire,descriere,studii)
		select @denumire,@descriere,@studii 				
end try

begin catch
	set @mesajeroare = '(wRUScriuProfesii) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
