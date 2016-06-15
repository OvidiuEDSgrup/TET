/* Procedura pt. scriere indicatori */
--***
Create procedure wRUScriuIndicatori @sesiune varchar(50), @parXML xml
As
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUScriuIndicatoriSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUScriuIndicatoriSP @sesiune, @parXML output
	return @returnValue
end

declare	@mesajeroare varchar(500), @utilizator char(10), @userASiS varchar(20), @sub char(9), 
	@id_indicator int, @id_domeniu int, 
	@denumire varchar(200), @descriere varchar(max), @formula varchar(200), @um varchar(10), @tip varchar(1), 
	@Interval_jos varchar(100), @Interval_sus varchar(100), @valori varchar(200), @descr_valori varchar(max), 
	@procent float, @stare varchar(1), @sursa_doc varchar(100), @responsabil int, @periodicitate int, 
	@update bit, @detalii xml
begin try 
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1	
         
	select 
		@update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
		@id_indicator = isnull(@parXML.value('(/row/@id_indicator)[1]','int'),0),
		@id_domeniu = isnull(@parXML.value('(/row/@id_domeniu)[1]','int'),0),
		@denumire =isnull(@parXML.value('(/row/@denumire)[1]','varchar(200)'),''),
		@descriere =isnull(@parXML.value('(/row/@descriere)[1]','varchar(MAX)'),''),
		@formula =isnull(@parXML.value('(/row/@formula)[1]','varchar(200)'),''),
		@um =isnull(@parXML.value('(/row/@um)[1]','varchar(10)'),''),
		@tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(1)'),0),
		@interval_jos =isnull(@parXML.value('(/row/@interval_jos)[1]','varchar(10)'),''),
		@interval_sus =isnull(@parXML.value('(/row/@interval_sus)[1]','varchar(10)'),''),
		@valori =isnull(@parXML.value('(/row/@valori)[1]','varchar(300)'),''),
		@descr_valori =isnull(@parXML.value('(/row/@descr_valori)[1]','varchar(max)'),''),
		@procent =isnull(@parXML.value('(/row/@procent)[1]','float'),''),
		@stare =isnull(@parXML.value('(/row/@stare)[1]','varchar(1)'),''),
		@sursa_doc =isnull(@parXML.value('(/row/@sursa_doc)[1]','varchar(100)'),''),
		@responsabil =isnull(@parXML.value('(/row/@responsabil)[1]','int'),''),
		@periodicitate =isnull(@parXML.value('(/row/@periodicitate)[1]','int'),'')
		
	if @update=1
		update RU_indicatori set ID_domeniu=@id_domeniu, Denumire=@denumire, Descriere=@descriere, 
			Formula=@formula, UM=@um, Tip=@tip, Interval_jos=@interval_jos, Interval_sus=@interval_sus, 
			Valori=@valori, Descriere_valori=@descr_valori, Procent=@procent, Stare=@stare,
			Sursa_documentare=@sursa_doc, Responsabil_calcul=@responsabil, Periodicitate_calcul=@periodicitate
		where ID_indicator=@id_indicator
	else 
		insert into RU_indicatori (ID_domeniu, Denumire, Descriere, Formula, UM, Tip, 
			Interval_jos, Interval_sus, Valori, Descriere_valori, Procent, Stare, 
			Sursa_documentare, Responsabil_calcul, Periodicitate_calcul)
		select @id_domeniu, @denumire, @descriere, @formula, @um, @tip, @Interval_jos, @Interval_sus, 
			@valori, @descr_valori, @procent, @stare, @sursa_doc, @responsabil, @periodicitate
end try

begin catch
	set @mesajeroare = '(wRUScriuIndicatori) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
