--***
Create 
procedure wStergAvexcep @sesiune varchar(50), @parXML xml
as
declare @tip varchar(2), @iDoc int, @eroare xml, @mesaj varchar(254)

begin try

exec sp_xml_preparedocument @iDoc output, @parXML
delete Avexcep
from Avexcep a, 
OPENXML (@iDoc, '/row')
	WITH
	(
		subtip varchar(2) '@subtip', 
		Data datetime '@data', 
		Marca varchar(6) '@marca'
	) as dx
where a.Data=dx.Data and a.Marca=dx.Marca and dx.subtip in ('A1','A2')

exec sp_xml_removedocument @iDoc 
--select 'ok' as msg for xml raw
exec wIaPozSalarii @sesiune=@sesiune, @parXML=@parXML

end try

begin catch
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj=ERROR_MESSAGE()
		raiserror(@mesaj, 11, 1)
end catch
