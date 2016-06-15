/** procedura pt. scriere date in RU_obiective **/
--***
Create procedure wRUScriuObiective @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUScriuObiectiveSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUScriuObiectiveSP @sesiune, @parXML output
	return @returnValue
end

declare	@mesajeroare varchar(500), @utilizator char(10), @id_obiectiv int, @denumire varchar(max), 
	@categorie varchar(1), @tip_obiectiv varchar(1), @id_obiectiv_parinte int, @lm char(9), 
	@an int, @data_inceput datetime, @data_sfarsit datetime, @actiuni_realizare varchar(max), 
	@actiuni_dezvoltare varchar(max), @rezultate varchar(max), @update bit
begin try	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1
	     
	select 
		@update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
		@id_obiectiv = isnull(@parXML.value('(/row/@id_obiectiv)[1]','int'),0),
		@denumire =isnull(@parXML.value('(/row/@denumire)[1]','varchar(max)'),''),
		@categorie =isnull(@parXML.value('(/row/@categorie)[1]','varchar(1)'),''),
		@tip_obiectiv =isnull(@parXML.value('(/row/@tip_obiectiv)[1]','varchar(1)'),''),
		@id_obiectiv_parinte = isnull(@parXML.value('(/row/@id_obiectiv_parinte)[1]','int'),0),
		@lm = isnull(@parXML.value('(/row/@lm)[1]','char(9)'),0),
		@an = @parXML.value('(/row/@an)[1]','int'),
		@data_inceput = isnull(@parXML.value('(/row/@data_inceput)[1]','datetime'),''),
		@data_sfarsit = isnull(@parXML.value('(/row/@data_sfarsit)[1]','datetime'),''),
		@actiuni_realizare= isnull(@parXML.value('(/row/@actiuni_realizare)[1]','varchar(MAX)'),''),
		@actiuni_dezvoltare= isnull(@parXML.value('(/row/@actiuni_dezvoltare)[1]','varchar(MAX)'),''),
		@rezultate= isnull(@parXML.value('(/row/@rezultate)[1]','varchar(MAX)'),'')

	if @an is not null
		Select @data_inceput=convert(datetime,'01/01/'+convert(char(4),@an),101), 
			@data_sfarsit=convert(datetime,'12/31/'+convert(char(4),@an),101)

	if @id_obiectiv_parinte=0 and @categorie>'1'
	begin
		raiserror('Obiectiv parinte necompletat!', 16, 1)
		return -1
	end

	if @update=1
		update RU_obiective set Denumire=@denumire, Categorie=@categorie, Tip_obiectiv=@tip_obiectiv,
			ID_obiectiv_parinte=@id_obiectiv_parinte, Loc_de_munca=@lm, Data_inceput=@data_inceput, Data_sfarsit=@data_sfarsit, 
			Actiuni_realizare=@actiuni_realizare, Actiuni_dezvoltare=@actiuni_dezvoltare, Rezultate=@rezultate
		where ID_obiectiv=@id_obiectiv 
	else 
		insert into RU_obiective(Denumire, Categorie, Tip_obiectiv, ID_obiectiv_parinte, Loc_de_munca, Data_inceput, Data_sfarsit, Actiuni_realizare, Actiuni_dezvoltare, Rezultate)
		select @denumire, @categorie, @tip_obiectiv, @id_obiectiv_parinte, @lm, @data_inceput, @data_sfarsit, @actiuni_realizare, @actiuni_dezvoltare, @rezultate
end try

begin catch
	set @mesajeroare = '(wRUScriuObiective) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
