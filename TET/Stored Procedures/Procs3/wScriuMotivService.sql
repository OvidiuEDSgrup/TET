--***

CREATE procedure  wScriuMotivService  @sesiune varchar(50), @parXML XML
as

declare @cod varchar(20), @descriere varchar(50), @o_cod varchar(20), @update int

set @cod = rtrim(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), ''))
set @o_cod = rtrim(isnull(@parXML.value('(/row/@o_cod)[1]', 'varchar(20)'), ''))
set	@descriere = rtrim(isnull(@parXML.value('(/row/@descriere)[1]', 'varchar(50)'), ''))
set @update=isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)

if @update=1 and isnull(@cod,'')<>@o_cod and exists (select 1 from programator where motiv_intrare=@o_cod)
begin
		raiserror('Nu este permisa schimbarea codului, deoarece codul vechi este folosit in documente sau in alte cataloage!',11,1)
		return
end
	
if (@update=0 or @update=1 and isnull(@cod,'')<>@o_cod) and exists (select 1 from mot_service where cod=@cod)
begin
		raiserror('Acest cod exista deja!',11,1)
		return
end

if isnull(@cod,'')='' 
begin
		raiserror('Cod necompletat!',11,1)
		return
end

if isnull(@descriere,'')='' 
begin
		raiserror('Descriere necompletata!',11,1)
		return
end

--Aici incepe partea de modificare
if @update=1
begin
	update mot_service set Cod=@cod, descriere=@descriere
		where Cod=@o_cod
	return
end

--Aici incepe partea de adaugare
/*if exists(select cod from mot_service where cod=@cod)
begin
		declare @err varchar(100)
		set @err = (select 'Codul '+@cod+' exista deja!')
		RAISERROR(@err,16,1)
		return ;
end	*/
else
	insert into mot_service (cod, descriere) VALUES (@cod,@descriere)
