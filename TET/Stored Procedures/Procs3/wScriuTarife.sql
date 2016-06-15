--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori )- adauga o categorie de indicatori 
verificand unicitatea codului*/

CREATE procedure  [dbo].[wScriuTarife]  @sesiune varchar(50), @parXML XML
as
declare @cod varchar(10), @denumire varchar(50), @o_cod varchar(20), @valuta varchar(50), @tarif varchar(50)
		

set @cod= rtrim(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(10)'), ''))
set @o_cod= rtrim(isnull(@parXML.value('(/row/@o_cod)[1]', 'varchar(10)'), ''))
set	@denumire = rtrim(isnull(@parXML.value('(/row/@denumire)[1]', 'varchar(50)'), ''))
set @tarif= rtrim(isnull(@parXML.value('(/row/@tarif)[1]', 'varchar(10)'), ''))
set @valuta= rtrim(isnull(@parXML.value('(/row/@valuta)[1]', 'varchar(10)'), ''))

--Aici incepe partea de modificare
declare @modificare int
set @modificare=isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)
if @modificare=1
begin
	update tarifemanopera set Denumire=@denumire, Tarif=@tarif, Valuta=@valuta
		where Cod =@o_cod
	return
end

--Aici incepe partea de adaugare
if exists(select Cod from tarifemanopera where Cod=@cod)
begin
		declare @err varchar(100)
		set @err = (select 'Cod: '+@cod+' exista deja!')
		RAISERROR(@err,16,1)
		return ;

end	

else
	insert into tarifemanopera (Cod, Denumire, Tarif, Valuta)
	       VALUES (@cod, @denumire, @tarif, @valuta)
