--***
create procedure wScriuNomenclatorSpecific @sesiune varchar(50), @parXML xml
as

Declare @update bit, @cod varchar(20),@data datetime,@pret decimal(12,3), @codspecific varchar(20),@denumire varchar(30),@utilizator varchar(50),
		@pret_valuta decimal(12,3),@discount decimal(12,2),@tert varchar(14),@cod_v varchar(20)

select @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
	 @cod = upper(isnull(@parXML.value('(/row/row/@cod)[1]','varchar(20)'),'')),
	 @cod_v = upper(isnull(@parXML.value('(/row/row/@o_cod)[1]','varchar(20)'),'')),
	 @codspecific= upper(isnull(@parXML.value('(/row/row/@codspecific)[1]','varchar(20)'),'')),
	 @denumire = upper(isnull(@parXML.value('(/row/row/@denumire)[1]','varchar(30)'),'')),
	 @pret= isnull(@parXML.value('(/row/row/@pret)[1]','decimal(12,3)'),0),
	 @pret_valuta=ISNULL( @parXML.value('(/row/row/@pret_valuta)[1]','decimal(12,3)'),0),
	 @discount= isnull(@parXML.value('(/row/row/@discount)[1]','decimal(12,2)'),0),
	 @tert = upper(isnull(@parXML.value('(/row/@tert)[1]','varchar(14)'),''))


exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
if @utilizator is null
	return

begin try
	if @cod='' or @codspecific=''
		raiserror('Campurile Cod si respectiv Cod special trebuie sa fie completate neaparat!!!',11,1)
	
	if @update=1  --pe ramura update	  
		update nomspec set cod=@cod, Cod_special=@codspecific,Denumire=@denumire,Pret=@pret,Pret_valuta=@pret_valuta,Discount=@discount
		where cod=@cod_v and tert=@tert
	
	else --pe ramura de adaugare cod nou

	insert into nomspec (Tert,Cod,Cod_special,Denumire,Pret,Pret_valuta,Discount)
	values (@tert,@cod,@codspecific,@denumire,@pret,@pret_valuta,@discount)
end try

begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
