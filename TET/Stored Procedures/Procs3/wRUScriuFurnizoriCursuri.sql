/* Procedura pt. scriere furnizori cursuri */
--***
Create procedure wRUScriuFurnizoriCursuri @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUScriuFurnizoriCursuriSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUScriuFurnizoriCursuriSP @sesiune, @parXML output
	return @returnValue
end

declare	@utilizator char(10), @tip char(2), @id_furnizor_curs int, @id_curs int, @tert varchar(13), @explicatii varchar(max), @pret float, @um char(10), @update bit, @mesajeroare varchar(500)
begin try	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1
			     
    select 
         @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
         @id_curs = isnull(@parXML.value('(/row/@id_curs)[1]','int'),0),
         @id_furnizor_curs = isnull(@parXML.value('(/row/row/@id_furnizor_curs)[1]','int'),0),
         @tert = isnull(@parXML.value('(/row/row/@tert)[1]','varchar(13)'),0),
         @explicatii =isnull(@parXML.value('(/row/row/@explicatii)[1]','varchar(max)'),''),
         @pret =isnull(@parXML.value('(/row/row/@pret)[1]','float'),''),
         @um= isnull(@parXML.value('(/row/row/@um)[1]','varchar(3)'),'')

	if @update=1
		update RU_furnizori_cursuri 
			set Tert=@tert, Pret=@pret, UM=@um, Explicatii=@explicatii
		where id_furnizor_curs=@id_furnizor_curs
	else 
		insert into RU_furnizori_cursuri (id_curs, Tert, Pret, UM, Explicatii)
		select @id_curs, @tert, @pret, @um, @explicatii
end try

begin catch
	set @mesajeroare = '(wRUScriuFurnizoriCursuri) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
