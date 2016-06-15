--***
/* 
*/
CREATE procedure wScriuNomenclRes @sesiune varchar(50), @parXML XML
as
--Declarare variabile
 
Declare @codresursa varchar(20), @tipresursa varchar(1),  @denumire varchar(50), @UM varchar(3), 
        @pret float, @greutate float, @codcoresp varchar(20) ,
        @o_codresursa varchar(20)
		
Set @codresursa = rtrim(isnull(@parXML.value('(/row/@codresursa)[1]', 'varchar(20)'), ''))
Set @tipresursa = rtrim(isnull(@parXML.value('(/row/@tipresursa)[1]', 'varchar(1)'), ''))
Set @denumire = rtrim(isnull(@parXML.value('(/row/@denumire )[1]', 'varchar(50)'), ''))
Set @UM =rtrim(isnull(@parXML.value('(/row/@um)[1]', 'varchar(3)'), ''))
Set @pret =isnull(@parXML.value('(/row/@pret)[1]', 'float'), '9999999')
Set @greutate =isnull(@parXML.value('(/row/@greutate)[1]', 'float'), '9999999')
Set @codcoresp = rtrim(isnull(@parXML.value('(/row/@codcoresp)[1]', 'varchar(20)'), ''))
set @o_codresursa = rtrim(isnull(@parXML.value('(/row/@o_codresursa )[1]', 'varchar(20)'), ''))


--Aici incepe partea de modificare
declare @modificare int
set @modificare=isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)

if @modificare=1
begin
	update nomres
				set tip_resursa=@tipresursa, cod_resursa=@codresursa, denumire=@denumire, UM=@um,
				pret_unitar=@pret, Greutate=@greutate, Cod_corespondent=@codcoresp
				where cod_resursa=@o_codresursa and tip_resursa=@tipresursa
	return
end

--Aici incepe partea de adaugare
if exists(select Cod_resursa from nomres where Cod_resursa=@codresursa and Tip_resursa=@tipresursa)
begin
		declare @err varchar(100)
		set @err = (select 'Cod: '+@codresursa+' exista deja!')
		RAISERROR(@err,16,1)
		return ;

end	
	else
		insert into nomres(Tip_resursa, Cod_resursa, Denumire, UM, Pret_unitar,Greutate,Cod_corespondent)
		values (@tipresursa, @codresursa, @denumire, @um, @pret, @greutate, @codcoresp)

		       
