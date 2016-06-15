create procedure wStergCodBare @sesiune varchar(30), @parXML XML
as
begin try
declare @cod varchar(20),@update int, @codbare varchar(20), @um int, @umprodus varchar(20)
set @cod = isnull(@parXML.value('(/row/@cod)[1]','varchar(20)'),'')
set @codbare = isnull(@parXML.value('(/row/row/@codbare)[1]','varchar(20)'),'')
set @um= isnull(@parXML.value('(/row/row/@um)[1]','int'),'')
set @umprodus= isnull(@parXML.value('(/row/row/@umprodus)[1]','varchar(20)'),'')
 delete from codbare where cod_produs=@cod and isnull(Cod_de_bare,'')=@codbare and isnull(um,'')=@um and isnull(UMprodus,'')=@umprodus
end try
begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
