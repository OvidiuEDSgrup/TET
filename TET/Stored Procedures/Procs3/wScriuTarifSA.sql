--***

CREATE procedure  wScriuTarifSA  @sesiune varchar(50), @parXML XML
as
declare @cod varchar(20), @denumire varchar(50), @o_cod varchar(20), @valuta varchar(50), 
	@tarif float, @update int

set @cod= rtrim(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), ''))
set @o_cod= rtrim(isnull(@parXML.value('(/row/@o_cod)[1]', 'varchar(20)'), ''))
set	@denumire = rtrim(isnull(@parXML.value('(/row/@denumire)[1]', 'varchar(50)'), ''))
set @tarif= isnull(@parXML.value('(/row/@tarif)[1]', 'float'), 0)
set @valuta= rtrim(isnull(@parXML.value('(/row/@valuta)[1]', 'varchar(10)'), ''))
set @update=isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)
/*
if @update=1 and isnull(@cod,'')<>@o_cod and exists (select 1 from pozdevauto where cod=@o_cod)
begin
		raiserror('Nu este permisa schimbarea codului, deoarece codul vechi este folosit in documente sau in alte cataloage!',11,1)
		return
end
*/	
if (@update=0 or @update=1 and isnull(@cod,'')<>@o_cod) and exists (select 1 from tarifemanopera where cod=@cod)
begin
		raiserror('Acest cod exista deja!',11,1)
		return
end

if isnull(@cod,'')='' 
begin
		raiserror('Cod necompletat!',11,1)
		return
end

if isnull(@denumire,'')='' 
begin
		raiserror('Denumire necompletata!',11,1)
		return
end

--Aici incepe partea de modificare
if @update=1
begin
	update tarifemanopera set Cod=@cod, Denumire=@denumire, Tarif=@tarif, Valuta=@valuta
		where Cod =@o_cod
	return
end

--Aici incepe partea de adaugare
/*if exists(select Cod from tarifemanopera where Cod=@cod)
begin
		declare @err varchar(100)
		set @err = (select 'Codul '+@cod+' exista deja!')
		RAISERROR(@err,16,1)
		return ;

end	
*/
else
	insert into tarifemanopera (Cod, Denumire, Tarif, Valuta)
		VALUES (@cod, @denumire, @tarif, @valuta)
