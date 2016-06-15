--***
Create 
procedure wStergResal @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @eroare xml

begin try
exec sp_xml_preparedocument @iDoc output, @parXML

delete Resal
from Resal r, 
OPENXML (@iDoc, '/row')
	WITH
	(
		Data datetime '@data', 
		Marca varchar(6) '@marca', 
		Cod_beneficiar varchar(13) '@codbenef', 
		Numar_document varchar(10) '@nrdoc'
	) as dx
where r.Data=dx.Data and r.Marca=dx.Marca and r.Cod_beneficiar=dx.Cod_beneficiar and r.Numar_document=dx.Numar_document

exec sp_xml_removedocument @iDoc 
--select 'ok' as msg for xml raw
exec wIaPozSalarii @sesiune=@sesiune, @parXML=@parXML
end try

begin catch
	--ROLLBACK TRAN
	declare @mesaj varchar(254)
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
	--	set @eroare='<error coderoare="1" msgeroare="' + ERROR_MESSAGE() + '"/>'
	--select @eroare FOR XML RAW
end catch
