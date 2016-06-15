create procedure wScriuCodBare   @sesiune varchar(30), @parXML XML
as
begin try
SELECT @PARXML
declare @cod varchar(20),@update int, @codbare varchar(20), @um int, @umprodus varchar(20)
set @cod = upper(@parXML.value('(/row/@cod)[1]','varchar(20)'))
set @codbare = upper(@parXML.value('(/row/row/@codbare)[1]','varchar(20)'))
set @um= upper(@parXML.value('(/row/row/@um)[1]','int'))
set @umprodus= upper(@parXML.value('(/row/row/@umprodus)[1]','varchar(20)'))
set @update = isnull(@parXML.value('(/row/@update)[1]','int'),0)
if @update=1
 begin
 declare @o_cod varchar(20),@o_codbare varchar(20), @o_um int, @o_umprodus varchar(20)
	 select @o_cod  = upper(@parXML.value('(/row/@cod)[1]','varchar(20)')),
			@o_codbare  = upper(@parXML.value('(/row/row/@o_codbare)[1]','varchar(20)')),
			@o_um= upper(@parXML.value('(/row/row/@o_um)[1]','int')),
			@o_umprodus= upper(@parXML.value('(/row/row/@o_umprodus)[1]','varchar(20)'))
			
   update codbare set cod_de_bare=@codbare, UM=@um, UMprodus=@umprodus where Cod_produs=@o_cod and Cod_de_bare=@o_codbare and (@o_um is null or um=@o_um) and (@o_umprodus is null or UMprodus=@o_umprodus)
 end
 else 
  insert into codbare (Cod_de_bare,Cod_produs,UM,UMprodus)
  values(@codbare,@cod,@um,@umprodus)
end try
begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
