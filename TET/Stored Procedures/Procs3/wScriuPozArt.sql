--***
/* 
*/
CREATE procedure wScriuPozArt @sesiune varchar(50), @parXML XML
as
--Declarare variabile 
declare	@codarticol varchar(20), @tipresursa varchar(20), @denumire varchar(100),@codresursa varchar(20), @cantitate float, @pret float 
			
Set @codarticol = rtrim(isnull(@parXML.value('(/row/@codarticol )[1]', 'varchar(20)'), ''))
Set @tipresursa = rtrim(isnull(@parXML.value('(/row/row/@tipresursa )[1]', 'varchar(1)'), ''))
Set @codresursa =rtrim(isnull(@parXML.value('(/row/row/@codresursa)[1]', 'varchar(20)'), ''))
Set @denumire =rtrim(isnull(@parXML.value('(/row/row/@denumire)[1]', 'varchar(3)'), ''))
Set @cantitate = isnull(@parXML.value('(/row/row/@cantitate)[1]', 'float'), '9999999')
Set @pret =isnull(@parXML.value('(/row/row/@pret)[1]', 'float'), '9999999')

--Aici incepe partea de modificare
declare @modificare int
set @modificare=isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)

if @modificare=1
begin
	update pozart
				set tip_resursa=@tipresursa, cod_resursa=@codresursa,  cantitate=@cantitate 
				where cod_articol=@codarticol and cod_resursa=@codresursa
				     
	return
end

--Aici incepe partea de adaugare
if not exists(select 1 from pozart where Cod_articol=@codarticol and cod_resursa=@codresursa)
begin
		insert into pozart (Cod_articol, Tip_resursa, Cod_resursa, Cantitate)
		values (@codarticol, @tipresursa, @codresursa, @cantitate)
end	
	else
begin
	raiserror('Eroare adaugare linie - pozitia este adaugata deja!',11,1)
end

	
