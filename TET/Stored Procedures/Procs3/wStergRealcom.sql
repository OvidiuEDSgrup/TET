--***
Create 
procedure wStergRealcom @sesiune varchar(50), @parXML xml
as
declare @DouaNivele int, @RowPattern varchar(20), @PrefixAtrMarca varchar(3), @AtrMarca varchar(20), 
@iDoc int, @eroare xml, @mesaj varchar(254)

begin try
exec sp_xml_preparedocument @iDoc output, @parXML
delete realcom
from Realcom r, 
OPENXML (@iDoc, '/row/row')
	WITH
	(
		Subtip varchar(2) '@subtip',
		Data datetime '@data',
		Marca varchar(6) '@marca',
		Loc_de_munca varchar(9) '@lm',
		Comanda varchar(20) '@comanda',
		Numar_document varchar(20) '@nrdoc'
	) as dx
where r.Data=dx.Data and (dx.Subtip in ('AG') and r.Marca='' or dx.Subtip in ('AI','MN') and r.Marca=dx.Marca)  
and r.Loc_de_munca=dx.Loc_de_munca and r.Comanda=dx.Comanda and r.Numar_document=dx.Numar_document

exec sp_xml_removedocument @iDoc 
--select 'ok' as msg for xml raw
exec wIaPozRealcom @sesiune=@sesiune, @parXML=@parXML

end try

begin catch
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj=ERROR_MESSAGE()
		raiserror(@mesaj, 11, 1)
end catch
