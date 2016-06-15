/** procedura pentru scriere cursuri pe Functii **/
--***
Create procedure wRUScriuCursuriFunctii @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUScriuCursuriFunctiiSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUScriuCursuriFunctiiSP @sesiune, @parXML output
	return @returnValue
end

declare	@mesajeroare varchar(500), @utilizator char(10), @userASiS varchar(20), @tip char(2), @id_curs_functie int, @id_curs int, @codfunctie char(6), @update bit

begin try       
    select 
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),''),
		@id_curs_functie = isnull(@parXML.value('(/row/row/@id_curs_functie)[1]','int'),0)

		if @tip='FT'
		Begin
			select @codfunctie = isnull(@parXML.value('(/row/row/@codfunctie)[1]','char(6)'),0),
			@id_curs = isnull(@parXML.value('(/row/@id_curs)[1]','int'),0)
		End	
		else 
		Begin
			select @codfunctie = isnull(@parXML.value('(/row/@cod)[1]','char(6)'),0),
			@id_curs = isnull(@parXML.value('(/row/row/@id_curs)[1]','int'),0)
		End	

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1
	
	if @update=1
		update RU_cursuri_functii set ID_curs=@id_curs, Cod_functie=@codfunctie
		where ID_curs_functie=@id_curs_functie
	else 
		insert into RU_cursuri_functii (Cod_functie, ID_curs)
		select @codfunctie, @id_curs
end try

begin catch
	set @mesajeroare = '(wRUScriuCursuriFunctii) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
