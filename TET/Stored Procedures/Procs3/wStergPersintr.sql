--***
create procedure wStergPersintr @sesiune varchar(50), @parXML xml
as

declare @DouaNivele int, @RowPattern varchar(20), @PrefixAtrMarca varchar(3), @AtrMarca varchar(20), 
@iDoc int, @eroare xml, @mesaj varchar(255)
select @DouaNivele = @parXML.exist('/row/row')
set @RowPattern = '/row' + (case when @DouaNivele=1 then '/row' else '' end)
set @PrefixAtrMarca = (case when @DouaNivele=1 then '../' else '' end)
set @AtrMarca = @PrefixAtrMarca + '@marca'

begin try
exec sp_xml_preparedocument @iDoc output, @parXML

delete persintr
from persintr p, 
OPENXML (@iDoc, @RowPattern)
	WITH
	(
		marca char(6) @AtrMarca, 
		cod_personal char(13) '@cnp',
		data datetime '@data'
	) as dx
where p.Marca=dx.Marca and p.Cod_personal=dx.Cod_personal and p.data=dx.data
exec sp_xml_removedocument @iDoc 
exec wIaPersintr @sesiune=@sesiune, @parXML=@parXML
end try

begin catch
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
