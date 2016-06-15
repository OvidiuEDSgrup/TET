/** procedura pt. scriere nivele organigrama **/
--***
Create procedure wRUScriuNiveleOrganigrama @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUScriuNiveleOrganigramaSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUScriuNiveleOrganigramaSP @sesiune, @parXML output
	return @returnValue
end

declare	@mesajeroare varchar(500), @utilizator char(10), @userASiS varchar(20), @tip char(2),
	@id_nivel int, @nivel int, @descriere varchar(50), @update bit
begin try	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1	

    select 
		@update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
		@id_nivel = isnull(@parXML.value('(/row/@id_nivel)[1]','int'),0),
		@descriere =isnull(@parXML.value('(/row/@descriere)[1]','varchar(MAX)'),''),
		@nivel= isnull(@parXML.value('(/row/@nivel)[1]','varchar(50)'),'')

	if @update=1
		update RU_nivele_organigrama set Nivel_organigrama=@nivel, descriere=@descriere
		where ID_nivel=@id_nivel
	else 
		insert into RU_nivele_organigrama (Nivel_organigrama, descriere)
		select @nivel, @descriere				
end try

begin catch
	set @mesajeroare = '(wRUScriuNiveleOrganigrama) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
