/** procedura pentru scriere obiective pe functii **/
--***
Create procedure wRUScriuObiectiveFunctii @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUScriuObiectiveFunctiiSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUScriuObiectiveFunctiiSP @sesiune, @parXML output
	return @returnValue
end

declare	@mesajeroare varchar(500), @utilizator char(10), @userASiS varchar(20), @tip char(2), 
	@update bit, @id_ob_functii int, @codfunctie varchar(6), @id_obiectiv int, @pondere float, 
	@o_id_obiectiv int
begin try	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1
       
    select 
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@codfunctie = isnull(@parXML.value('(/row/@cod)[1]','int'),0),
		@id_obiectiv = isnull(@parXML.value('(/row/row/@id_obiectiv)[1]','int'),0),
		@id_ob_functii = isnull(@parXML.value('(/row/row/@id_ob_functii)[1]','int'),0),
		@o_id_obiectiv= isnull(@parXML.value('(/row/row/@o_id_obiectiv)[1]','int'),0),
		@pondere = isnull(@parXML.value('(/row/row/@pondere)[1]','float'),0)             
		
	if @update=1
		update RU_obiective_functii set ID_obiectiv=@id_obiectiv, Pondere=@pondere
		where ID_ob_functii=@id_ob_functii
	else 
		insert into RU_obiective_functii (ID_obiectiv, Cod_functie, Pondere)
		select @id_obiectiv, @codfunctie, @pondere				
end try

begin catch
	set @mesajeroare = '(wRUScriuObiectiveFunctii) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch