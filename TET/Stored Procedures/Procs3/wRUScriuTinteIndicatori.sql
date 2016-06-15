/** procedura pentru completare date in tabela RU_tinte_indicatori*/
--***
Create procedure wRUScriuTinteIndicatori @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUScriuTinteIndicatoriSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUScriuTinteIndicatoriSP @sesiune, @parXML output
	return @returnValue
end

declare	@mesajeroare varchar(500), @utilizator char(10), @userASiS varchar(20), @sub char(9), 
	@id_tinta int, @id_indicator int, @descriere varchar(max), @an int, @data_inceput datetime, @data_sfarsit datetime, 
	@Interval_jos varchar(100), @Interval_sus varchar(100), @valori varchar(200), @descr_valori varchar(max), 
	@id_calificativ int, @update bit
begin try	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1

	select 
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@id_tinta = isnull(@parXML.value('(/row/row/@id_tinta)[1]','int'),0),
		@id_indicator = isnull(@parXML.value('(row/@id_indicator)[1]','int'),0),
		@descriere = isnull(@parXML.value('(/row/row/@descriere)[1]','varchar(max)'),''),
		@an = @parXML.value('(/row/row/@an)[1]','int'),
		@data_inceput = isnull(@parXML.value('(/row/row/@data_inceput)[1]','datetime'),''),
		@data_sfarsit = isnull(@parXML.value('(/row/row/@data_sfarsit)[1]','datetime'),''),
		@interval_jos = isnull(@parXML.value('(/row/row/@interval_jos)[1]','varchar(10)'),''),
		@interval_sus = isnull(@parXML.value('(/row/row/@interval_sus)[1]','varchar(10)'),''),
		@valori = isnull(@parXML.value('(/row/row/@valori)[1]','varchar(300)'),''),
		@descr_valori = isnull(@parXML.value('(/row/row/@descr_valori)[1]','varchar(max)'),''),
		@id_calificativ = isnull(@parXML.value('(/row/row/@id_calificativ)[1]','int'),0)

	if @an is not null
		Select @data_inceput=convert(datetime,'01/01/'+convert(char(4),@an),101), 
			@data_sfarsit=convert(datetime,'12/31/'+convert(char(4),@an),101)
	
	if @update=1
		update RU_tinte_indicatori set ID_indicator=@id_indicator, Descriere=@descriere, 
			Data_inceput=@data_inceput, Data_sfarsit=@data_sfarsit, 
			Interval_jos=@interval_jos, Interval_sus=@interval_sus, Valori=@valori, Descriere_valori=@descr_valori,
			ID_calificativ=@id_calificativ
		where ID_tinta=@id_tinta
	else 
		insert into RU_tinte_indicatori (ID_indicator, Descriere, Data_inceput, Data_sfarsit, Interval_jos, Interval_sus, Valori, Descriere_valori, ID_calificativ)
		select @id_indicator, @descriere, @data_inceput, @data_sfarsit, @Interval_jos, @Interval_sus, @valori, @descr_valori, @id_calificativ
end try

begin catch
	set @mesajeroare = '(wRUScriuTinteIndicatori) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
