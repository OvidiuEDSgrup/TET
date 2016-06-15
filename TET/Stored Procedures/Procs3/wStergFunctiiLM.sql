--***
Create procedure [dbo].[wStergFunctiiLM] @sesiune varchar(30), @parXML XML
as
begin try
	declare @data datetime, @lm varchar(9), @functie varchar(6)
	select @lm = @parXML.value('(/row/@lm)[1]','varchar(9)'),
		@data = @parXML.value('(/row/row/@data)[1]','datetime'),
		@functie = @parXML.value('(/row/row/@functie)[1]','varchar(6)')

	delete from functii_lm where Data=@data and Loc_de_munca=@lm and Cod_functie=@functie

end try

begin catch
	declare @mesaj varchar(254)
	set @mesaj = '(wStergFunctiiLM) '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
