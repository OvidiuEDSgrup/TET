--***
/* 
*/
CREATE procedure wScriuArtDeviz @sesiune varchar(50), @parXML XML
as
--Declarare variabile 
Declare @codarticol varchar(20), @denumire varchar(100),  @UM varchar(3),  @subcapitol varchar(20), 
        @o_codarticol varchar(20)
		

Set @codarticol = rtrim(isnull(@parXML.value('(/row/@codarticol )[1]', 'varchar(20)'), ''))
Set @denumire = rtrim(isnull(@parXML.value('(/row/@denumire )[1]', 'varchar(100)'), ''))
Set @UM =rtrim(isnull(@parXML.value('(/row/@um)[1]', 'varchar(3)'), ''))
Set @subcapitol = rtrim(isnull(@parXML.value('(/row/@subcapitol)[1]', 'varchar(20)'), ''))
set @o_codarticol = rtrim(isnull(@parXML.value('(/row/@o_codarticol )[1]', 'varchar(20)'), ''))

--Aici incepe partea de modificare
declare @modificare int
set @modificare=isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)

if @modificare=1
begin
	update art
				set cod_articol=@codarticol, denumire=@denumire, UM=@um, Subcapitol=@subcapitol
				where cod_articol=@o_codarticol
	return
end

--Aici incepe partea de adaugare
if exists(select Cod_articol from art where Cod_articol=@codarticol )
begin
		declare @err varchar(100)
		set @err = (select 'Cod: '+@codarticol+' exista deja!')
		RAISERROR(@err,16,1)
		return ;

end	
	else
		insert into art (Cod_articol, Denumire, UM, Subcapitol)
		values (@codarticol, @denumire, @um, @subcapitol)


