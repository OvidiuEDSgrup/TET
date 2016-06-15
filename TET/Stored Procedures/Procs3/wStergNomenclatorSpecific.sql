--***
create procedure wStergNomenclatorSpecific @sesiune varchar(50), @parXML xml
as

Declare @update bit, @cod varchar(20),@data datetime,@pret decimal(12,3), @codspecific varchar(20),@denumire varchar(30),@utilizator varchar(50),
		@pret_valuta decimal(12,3),@discount decimal(12,2),@tert varchar(14),@cod_v varchar(20)

select @cod = isnull(@parXML.value('(/row/row/@cod)[1]','varchar(20)'),''),
	   @codspecific= isnull(@parXML.value('(/row/row/@codspecific)[1]','varchar(20)'),''),
	   @tert = isnull(@parXML.value('(/row/@tert)[1]','varchar(14)'),'')

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
if @utilizator is null
	return

begin try
	delete nomspec where tert=@tert and cod=@cod and Cod_special=@codspecific
end try

begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
