--***
create procedure wStergExtinfop @sesiune varchar(50), @parXML xml
as

declare @DouaNivele int, @RowPattern varchar(20), @PrefixAtrMarca varchar(3), @AtrMarca varchar(20), 
@iDoc int, @eroare xml, @mesaj varchar(255)
select @DouaNivele = @parXML.exist('/row/row')
set @RowPattern = '/row' + (case when @DouaNivele=1 then '/row' else '' end)
set @PrefixAtrMarca = (case when @DouaNivele=1 then '../' else '' end)
set @AtrMarca = @PrefixAtrMarca + '@marca'

begin try
--BEGIN TRAN
exec sp_xml_preparedocument @iDoc output, @parXML

delete extinfop
from extinfop e, 
OPENXML (@iDoc, @RowPattern)
	WITH
	(
		marca char(6) @AtrMarca, 
		cod char(13) '@cod',
		valoare char(80) '@valoare',
		data datetime '@data'
	) as dx
where e.Marca=dx.Marca and e.Cod_inf=dx.Cod and e.Val_inf=dx.Valoare and e.Data_inf=dx.Data

exec sp_xml_removedocument @iDoc 
exec wIaExtinfop @sesiune=@sesiune, @parXML=@parXML
--COMMIT TRAN
end try

begin catch
	--ROLLBACK TRAN
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
