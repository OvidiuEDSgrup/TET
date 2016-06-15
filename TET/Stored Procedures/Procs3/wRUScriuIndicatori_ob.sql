/* Procedura pt. scriere indicatori pe obiective */
--***
Create procedure wRUScriuIndicatori_ob @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUScriuIndicatori_obSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUScriuIndicatori_obSP @sesiune, @parXML output
	return @returnValue
end

declare	@mesajeroare varchar(500), @utilizator char(10), @tip char(2), @id_ind_ob int, @id_obiectiv int,
	@descriere varchar(max), @valori varchar(max), @procent float, @update bit
begin try	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1
			     
    select 
         @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
         @id_ind_ob = isnull(@parXML.value('(/row/row/@id_ind_ob)[1]','int'),0),
         @id_obiectiv = isnull(@parXML.value('(/row/@id_obiectiv)[1]','int'),0),
         @descriere =isnull(@parXML.value('(/row/row/@descriere)[1]','varchar(max)'),''),
         @valori =isnull(@parXML.value('(/row/row/@valori)[1]','varchar(max)'),''),
         @procent= isnull(@parXML.value('(/row/row/@procent)[1]','float'),'')
         
	if @update=1
		update RU_indicatori_ob 
			set descriere=@descriere, valori=@valori, procent=@procent
		where id_obiectiv=@id_obiectiv 
	else 
		insert into RU_indicatori_ob (id_obiectiv, descriere, Valori,procent)
		select @id_obiectiv, @descriere, @valori, @procent 				
end try

begin catch
	set @mesajeroare = '(wRUScriuIndicatori_ob) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
