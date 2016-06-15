--***
create procedure wStergStagiuCM @sesiune varchar(50), @parXML xml
as

declare @DouaNivele int, @RowPattern varchar(20), @PrefixAtrMarca varchar(3), @AtrMarca varchar(20), 
@iDoc int, @eroare xml, @mesaj varchar(255)
select @DouaNivele = @parXML.exist('/row/row')
set @RowPattern = '/row' + (case when @DouaNivele=1 then '/row' else '' end)
set @PrefixAtrMarca = (case when @DouaNivele=1 then '../' else '' end)
set @AtrMarca = @PrefixAtrMarca + '@marca'

begin try
	exec sp_xml_preparedocument @iDoc output, @parXML

	delete net
	from net n, 
	OPENXML (@iDoc, @RowPattern)
		WITH
		(
			marca char(6) @AtrMarca, 
			data datetime '@data'
		) as dx
	where n.Marca=dx.Marca and n.data=dx.data and day(n.Data)=15
	exec sp_xml_removedocument @iDoc 
	exec wIaStagiuCM @sesiune=@sesiune, @parXML=@parXML
end try

begin catch
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
