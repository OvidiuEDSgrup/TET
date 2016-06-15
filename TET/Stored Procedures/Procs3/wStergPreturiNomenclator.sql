--***
create procedure wStergPreturiNomenclator @sesiune varchar(50), @parXML xml
as
begin try

Declare @cod varchar(20),@data datetime,@pret_cu_amanuntul decimal(12,2),@catpret varchar(10),@tippret varchar(1),@utilizator varchar(50), @um varchar(20)
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
if @utilizator is null
	return

Set @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')
Set @catpret= @parXML.value('(/row/row/@catpret)[1]','varchar(20)')
Set @tippret = @parXML.value('(/row/row/@tippret)[1]','varchar(20)')
Set @data= @parXML.value('(/row/row/@data_inferioara)[1]','datetime')
Set @pret_cu_amanuntul= @parXML.value('(/row/row/@pretamanunt)[1]','decimal(12,2)')
Set @um = @parXML.value('(/row/row/@um)[1]','varchar(20)')

declare @datadinainte datetime,@datadupa datetime
set @datadinainte=(select top 1 data_inferioara from preturi where Cod_produs= @cod and 
	preturi.Data_inferioara<@data and preturi.UM=@catpret and preturi.Tip_pret=@tippret and isnull(preturi.umprodus,'')=isnull(@um,''))
set @datadupa=(select top 1 data_inferioara from preturi where Cod_produs= @cod and 
	preturi.Data_inferioara>@data and preturi.UM=@catpret and preturi.Tip_pret=@tippret and isnull(preturi.umprodus,'')=isnull(@um,''))

delete from preturi where Cod_produs= @cod and preturi.Data_inferioara=@data and preturi.UM=@catpret and preturi.Tip_pret=@tippret  and isnull(preturi.umprodus,'')=isnull(@um,'')

if @datadinainte is not null 
	if @datadupa is not null --a fost un pret la mijloc, se modifica data de sus a liniei anterioare
		update preturi set data_superioara=DATEADD(day,-1,@datadupa)
		where Cod_produs= @cod and preturi.Data_inferioara=@datadinainte and preturi.UM=@catpret and preturi.Tip_pret=@tippret  and isnull(preturi.umprodus,'')=isnull(@um,'')
	else  -- linia de dinainte devine cel curent
		update preturi set data_superioara='01/01/2999'
		where Cod_produs= @cod and preturi.Data_inferioara=@datadinainte and preturi.UM=@catpret and preturi.Tip_pret=@tippret  and isnull(preturi.umprodus,'')=isnull(@um,'')

	--preturile urmatoare nu sunt afectate de stergerea acesetei linii! inteligenta metoda!

end try

begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
