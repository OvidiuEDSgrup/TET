--***
Create procedure wScriuCodProprietati   @sesiune varchar(30), @parXML XML
as
declare @cod varchar(20), @update bit, @valoare varchar(20), @descriere varchar(200), @codprop varchar(50)
Select  @cod = upper(@parXML.value('(/row/@cod)[1]','varchar(20)')),
		@update = upper(isnull(@parXML.value('(/row/row/@update)[1]','bit'),0)),
		@valoare = upper(isnull(@parXML.value('(/row/row/@valoare)[1]','varchar(50)'),'')),
		@codprop = upper(isnull(@parXML.value('(/row/row/@codprop)[1]','varchar(50)'),''))
begin try
	if @update=1
	begin
		declare @o_cod varchar(20),@o_valoare varchar(20)
		Select @o_cod= upper(@parXML.value('(/row/@cod)[1]','varchar(20)')),
		       @o_valoare= upper(isnull(@parXML.value('(/row/row/@o_datapret)[1]','varchar(20)'),''))
		update proprietati set Valoare=@valoare where cod=@o_cod and Cod_proprietate=@codprop
	end
	else
		if exists (select 1 from proprietati where cod=@cod and Cod_proprietate=@codprop)
			update proprietati set Valoare=@valoare where cod=@cod and Cod_proprietate=@codprop
		else
			insert into proprietati (Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla)
			values('NOMENCL',@cod,@codprop,@valoare,'')
end try
begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch

