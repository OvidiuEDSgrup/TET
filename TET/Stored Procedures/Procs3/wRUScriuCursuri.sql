/* Procedura pt. scriere cursuri */
--***
Create procedure wRUScriuCursuri @sesiune varchar(50), @parXML xml
As
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUScriuCursuriSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUScriuCursuriSP @sesiune, @parXML output
	return @returnValue
end

declare	@mesajeroare varchar(500), @utilizator char(10), @userASiS varchar(20), @sub char(9), @id_curs int, @dencurs varchar(100), @durata int, @periodicitate int, @utilitate varchar(max), 
	@id_domeniu int, @email varchar(150), @tipcurs char(1), @tipcompetenta char(1), @tip varchar(2), @update bit, @detalii xml

begin try 
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1	
         
	select 
		@update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
		@id_curs = isnull(@parXML.value('(/row/@id_curs)[1]','int'),0),
		@id_domeniu = @parXML.value('(/row/@id_domeniu)[1]','int'),
		@dencurs = isnull(@parXML.value('(/row/@dencurs)[1]','varchar(200)'),''),
		@durata = isnull(@parXML.value('(/row/@durata)[1]','int'),''),
		@periodicitate = isnull(@parXML.value('(/row/@periodicitate)[1]','int'),''),
		@utilitate = isnull(@parXML.value('(/row/@utilitate)[1]','varchar(MAX)'),''),
		@email = isnull(@parXML.value('(/row/@email)[1]','varchar(150)'),''),
		@tipcurs = isnull(@parXML.value('(/row/@tipcurs)[1]','varchar(1)'),''),
		@tipcompetenta = isnull(@parXML.value('(/row/@tipcompetenta)[1]','varchar(1)'),''),
		@tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),0)
		set @id_domeniu=(case when @id_domeniu=0 then Null else @id_domeniu end)
		
	if @update=1
		update RU_cursuri set Denumire=@dencurs, Durata=@durata, Periodicitate=@periodicitate, Utilitate=@utilitate, ID_domeniu=@id_domeniu, Email=@email, 
		Tip_curs=@tipcurs, Tip_competenta=@tipcompetenta
		where ID_curs=@id_curs
	else 
		insert into RU_cursuri (Denumire, Durata, Periodicitate, Utilitate, ID_domeniu, Email, Tip_curs, Tip_competenta)
		select @dencurs, @durata, @periodicitate, @utilitate, @id_domeniu, @email, @tipcurs, @tipcompetenta
end try

begin catch
	set @mesajeroare = '(wRUScriuCursuri) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
