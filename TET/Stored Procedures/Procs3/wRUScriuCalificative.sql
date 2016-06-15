/* Procedura pt. scriere date in tabela de calificative */
--***
Create procedure wRUScriuCalificative @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUScriuCalificativeSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUScriuCalificativeSP @sesiune, @parXML output
	return @returnValue
end
declare	@mesajeroare varchar(500), @utilizator char(10), @userASiS varchar(20), @sub char(9), @id_calificativ int, @an int, @data_inceput datetime, @data_sfarsit datetime, @calificativ int, 
	@nivel_realizare varchar(100), @nota_inf decimal(8,2), @nota_sup decimal(8,2), @update bit, @detalii xml
begin try	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1
	          
	select 
		@update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
		@id_calificativ = isnull(@parXML.value('(/row/@id_calificativ)[1]','int'),0),
		@an = @parXML.value('(/row/@an)[1]','int'),
		@data_inceput = isnull(@parXML.value('(/row/@data_inceput)[1]','datetime'),''),
		@data_sfarsit = isnull(@parXML.value('(/row/@data_sfarsit)[1]','datetime'),''),
		@calificativ = isnull(@parXML.value('(/row/@calificativ)[1]','int'),0),
		@nivel_realizare = isnull(@parXML.value('(/row/@nivel_realizare)[1]','varchar(100)'),''),
		@nota_inf = @parXML.value('(/row/@nota_inf)[1]','decimal(8,2)'),
		@nota_sup = @parXML.value('(/row/@nota_sup)[1]','decimal(8,2)')
		
	if @an is not null
		Select @data_inceput=convert(datetime,'01/01/'+convert(char(4),@an),101), 
			@data_sfarsit=convert(datetime,'12/31/'+convert(char(4),@an),101)

	if @update=1
		update RU_calificative set Data_inceput=@data_inceput, Data_sfarsit=@data_sfarsit, Calificativ=@calificativ, Nivel_realizare=@nivel_realizare, 
			Nota_inferioara=@nota_inf, Nota_superioara=@nota_sup
		where ID_calificativ=@id_calificativ
	else 
		insert into RU_calificative (Data_inceput, Data_sfarsit, Calificativ, Nivel_realizare, Nota_inferioara, Nota_superioara)
		select @data_inceput, @data_sfarsit, @calificativ, @nivel_realizare, @nota_inf, @nota_sup
end try

begin catch
	set @mesajeroare = '(wRUScriuCalificative) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
