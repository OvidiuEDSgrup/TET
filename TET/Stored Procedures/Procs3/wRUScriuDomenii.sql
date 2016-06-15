/** procedura pentru scriere in catalogul RU_domenii **/
--***
Create procedure wRUScriuDomenii @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUScriuDomeniiSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUScriuDomeniiSP @sesiune, @parXML output
	return @returnValue
end

declare	@mesajeroare varchar(500), @utilizator char(10), @userASiS varchar(20),
	@id_domeniu int, @denumire varchar(50), @descriere varchar(100), @update bit
begin try	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1
		        
    select 
		@update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
		@id_domeniu = isnull(@parXML.value('(/row/@id_domeniu)[1]','int'),0),
		@denumire =isnull(@parXML.value('(/row/@denumire)[1]','varchar(50)'),''),
		@descriere= isnull(@parXML.value('(/row/@descriere)[1]','varchar(100)'),'')
		
	if @update=1
		update RU_domenii set denumire=@denumire,descriere=@descriere
		where ID_domeniu=@id_domeniu
	else 
		insert into RU_domenii (denumire, descriere)
		select @denumire, @descriere
end try

begin catch
	set @mesajeroare = '(wRUScriuDomenii) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
