--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori )- adauga o categorie de indicatori 
verificand unicitatea codului*/

CREATE procedure  [dbo].[wScriuMotiveService]  @sesiune varchar(50), @parXML XML
as
declare @cod varchar(10), @descriere varchar(50), @o_cod varchar(20)
		

set @cod = rtrim(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(10)'), ''))
set @o_cod = rtrim(isnull(@parXML.value('(/row/@o_cod)[1]', 'varchar(10)'), ''))
set	@descriere = rtrim(isnull(@parXML.value('(/row/@descriere)[1]', 'varchar(50)'), ''))

--Aici incepe partea de modificare
declare @modificare int
set @modificare=isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)
if @modificare=1
begin
	update mot_service set descriere=@descriere
		where Cod=@o_cod
	return
end

--Aici incepe partea de adaugare
if exists(select cod from mot_service where cod=@cod)
begin
		declare @err varchar(100)
		set @err = (select 'Codul: '+@cod+' exista deja!')
		RAISERROR(@err,16,1)
		return ;

end	
else
	insert into mot_service VALUES (@cod,@descriere)
