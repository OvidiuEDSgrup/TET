/** procedura pentru scriere descriere competente **/
--***
Create procedure wRUScriuDescriereCompetente @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUScriuDescriereCompetenteSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUScriuDescriereCompetenteSP @sesiune, @parXML output
	return @returnValue
end

declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20), @sub char(9), 
	@tip char(2), @procent float
begin try	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1
	
	DECLARE @id_desc_comp int, @id_competenta int, @tip_componenta int, @componenta varchar(200), 
		@descriere varchar(MAX), @update bit
				     
    select 
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@id_desc_comp = isnull(@parXML.value('(/row/row/@id_desc_comp)[1]','int'),0),
		@id_competenta = isnull(@parXML.value('(/row/@id_competenta)[1]','int'),0),
		@tip_componenta = isnull(@parXML.value('(/row/row/@tip_componenta)[1]','int'),0),
		@procent = isnull(@parXML.value('(/row/row/@procent)[1]','decimal(5,2)'),0),
		@componenta =isnull(@parXML.value('(/row/row/@componenta)[1]','varchar(200)'),''),
		@descriere =isnull(@parXML.value('(/row/row/@descriere)[1]','varchar(MAX)'),'')
        
	if @update=1
		update RU_descriere_competente set tip_componenta=@tip_componenta,componenta=@componenta,
			Procent=@procent, descriere=@descriere
		where ID_competenta=@id_competenta and ID_desc_comp=@id_desc_comp
	else 
		insert into RU_descriere_competente(ID_competenta, tip_componenta, componenta, procent, descriere)
		select @id_competenta, @tip_componenta, @componenta, @procent, @descriere
end try

begin catch
	set @mesajeroare = '(wRUScriuDescriereCompetente) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
