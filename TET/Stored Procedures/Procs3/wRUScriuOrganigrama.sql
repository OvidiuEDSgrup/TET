/** procedura pentru completare organigrama pe functii **/
--***
Create procedure wRUScriuOrganigrama @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUScriuOrganigramaSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUScriuOrganigramaSP @sesiune, @parXML output
	return @returnValue
end

declare	@mesajeroare varchar(500), @utilizator char(10), @userASiS varchar(20), @tip char(2), @id_organigrama int, @update bit, @codfunctie char(60), @id_nivel int, 
	@codfunctieparinte char(6), @data_inceput datetime, @data_sfarsit datetime, @nrposturi int, @ordinestat int

begin try       
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
    
    select 
		@update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
		@codfunctie = isnull(@parXML.value('(/row/@codfunctie)[1]','char(6)'),0),
		@id_nivel = isnull(@parXML.value('(/row/@id_nivel)[1]','int'),0),
		@id_organigrama = isnull(@parXML.value('(/row/@id_organigrama)[1]','int'),0),
		@codfunctieparinte = isnull(@parXML.value('(/row/@codfunctieparinte)[1]','char(6)'),0),
		@data_inceput = isnull(@parXML.value('(/row/@data_inceput)[1]','datetime'),''),
		@data_sfarsit = isnull(@parXML.value('(/row/@data_sfarsit)[1]','datetime'),''),
		@nrposturi = isnull(@parXML.value('(/row/@nrposturi)[1]','int'),0),
		@ordinestat = isnull(@parXML.value('(/row/@ordinestat)[1]','int'),0)

	if @id_nivel=0
	begin
		raiserror('Nivel organigrama necompletat!', 16, 1)
		return -1
	end
	if @codfunctie=@codfunctieparinte
	begin
		raiserror('Un cod functie nu poate sa aiba aceeasi functie ca si parinte!', 16, 1)
		return -1
	end
	if ISNULL(@codfunctieparinte,'')='' and isnull((select Nivel_organigrama from RU_nivele_organigrama where ID_nivel=@id_nivel),0)>1
	begin
		raiserror('Cod functie parinte necompletat!', 16, 1)
		return -1
	end
	if ISNULL(@data_inceput,'')='' 
	begin
		raiserror('Data inceput necompletata!', 16, 1)
		return -1
	end
	if ISNULL(@data_sfarsit,'')=''
	begin
		raiserror('Data sfarsit necompletata!', 16, 1)	
		return -1
	end
	if @data_inceput>=@data_sfarsit
	begin
		raiserror('Data sfarsit trebuie sa fie cronologic dupa data inceput!', 16, 1)	
		return -1
	end

	if @update=1
		update  RU_organigrama set Cod_functie=@codfunctie, Cod_functie_parinte=@codfunctieparinte, 
		ID_nivel=@id_nivel, Data_inceput=@data_inceput, Data_sfarsit=@data_sfarsit, Numar_posturi=@nrposturi, Ordine_stat=@ordinestat
		where ID_organigrama=@id_organigrama
	else 
		insert into RU_organigrama (ID_nivel, Cod_functie, Cod_functie_parinte, Data_inceput, Data_sfarsit, Numar_posturi, Ordine_stat)
		select @id_nivel, @codfunctie, @codfunctieparinte, @data_inceput, @data_sfarsit, @nrposturi, @ordinestat
end try

begin catch
	set @mesajeroare = '(wRUScriuOrganigrama) '+ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
