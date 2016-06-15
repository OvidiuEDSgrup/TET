/** procedura pentru scriere in catalogul de competente **/
--***
Create procedure wRUScriuCompetente @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUScriuCompetenteSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUScriuCompetenteSP @sesiune, @parXML output
	return @returnValue
end
declare	@mesajeroare varchar(500), @utilizator char(10), @userASiS varchar(20), @sub char(9), @tip char(2),	@id_competenta int, @id_competenta_parinte int, @id_domeniu int, @tip_competenta int, 
	@tip_calcul int, @procent float, @dencompetenta varchar(200), @descriere varchar(max), @update bit, @detalii xml
begin try	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1
		   
    select 
		@update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
		@id_competenta = isnull(@parXML.value('(/row/@id_competenta)[1]','int'),0),
		@id_competenta_parinte = isnull(@parXML.value('(/row/@id_competenta_parinte)[1]','int'),0),
		@id_domeniu = isnull(@parXML.value('(/row/@id_domeniu)[1]','int'),0),
		@tip_competenta = isnull(@parXML.value('(/row/@tip_competenta)[1]','int'),0),
		@tip_calcul = isnull(@parXML.value('(/row/@tip_calcul)[1]','int'),0),
		@procent = isnull(@parXML.value('(/row/@procent)[1]','float'),0),
		@dencompetenta =isnull(@parXML.value('(/row/@dencompetenta)[1]','varchar(200)'),''),
		@descriere =isnull(@parXML.value('(/row/@descriere)[1]','varchar(MAX)'),'')
/*
	if @id_competenta_parinte<>0 and @tip_competenta in ('1','2','3')
	begin
		raiserror('Aceasta competenta nu este corespunzatoare tipului de competenta selectat!',11,1)
		return -1
	end
*/		
	if @update=1
		update RU_competente set ID_competenta_parinte=@id_competenta_parinte, ID_domeniu=@ID_domeniu, tip_competenta=@tip_competenta, tip_calcul_calificativ=@tip_calcul, 
			Procent=@procent, descriere=@descriere, denumire=@dencompetenta, detalii=@detalii
		where ID_competenta=@id_competenta
	else 
		insert into RU_competente (denumire, ID_competenta_parinte, ID_domeniu, tip_competenta, tip_calcul_calificativ, procent, descriere, detalii)
		select @dencompetenta, @id_competenta_parinte, @id_domeniu, @tip_competenta, @tip_calcul, @procent, @descriere, @detalii				
end try

begin catch
	set @mesajeroare = '(wRUScriuCompetente) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch