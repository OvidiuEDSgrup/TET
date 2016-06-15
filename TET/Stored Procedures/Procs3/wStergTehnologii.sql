create procedure wStergTehnologii @sesiune varchar(50), @parXML XML
as
	declare @id int, @cod varchar(20)
	set @id=isnull(@parXML.value('(/row/@id)[1]','int'),-1)
	set @cod=isnull(@parXML.value('(/row/@cod_tehn)[1]','varchar(20)'),'')
	
	
	delete from tehnologii where cod=@cod
	delete from pozTehnologii where id=@id or parinteTop=@id
