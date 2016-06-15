/** procedura pentru scriere competente pe Functii **/
--***
Create procedure wRUScriuCompetenteFunctii @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUScriuCompetenteFunctiiSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUScriuCompetenteFunctiiSP @sesiune, @parXML output
	return @returnValue
end

declare	@mesajeroare varchar(500), @utilizator char(10), @userASiS varchar(20), @sub char(9), @tip char(2),
	@id_comp_functii int, @id_competenta int, @codfunctie char(6), @pondere float, @update bit

begin try       
    select 
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@id_comp_functii = isnull(@parXML.value('(/row/row/@id_comp_functii)[1]','int'),0),
		@codfunctie = isnull(@parXML.value('(/row/@cod)[1]','char(6)'),0),
		@id_competenta = isnull(@parXML.value('(/row/row/@id_competenta)[1]','int'),0),
		@pondere =isnull(@parXML.value('(/row/row/@pondere)[1]','float'),'')
	if @pondere=0
		select @pondere=Procent from RU_competente where ID_competenta=@id_competenta

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1
	
	if @update=1
		update RU_competente_functii set ID_competenta=@id_competenta, Pondere=@pondere
		where Cod_functie=@codfunctie and ID_comp_functii=@id_comp_functii
	else 
		insert into RU_competente_functii (ID_competenta, Cod_functie, pondere)
		select @id_competenta, @codfunctie, @pondere 				
end try

begin catch
	set @mesajeroare = '(wRUScriuCompetenteFunctii) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
