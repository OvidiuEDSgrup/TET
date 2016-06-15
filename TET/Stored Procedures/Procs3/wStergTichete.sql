--***
Create 
procedure wStergTichete @sesiune varchar(50), @parXML xml
as
declare @tip varchar(2), @iDoc int, @eroare xml, @mesaj varchar(254)

begin try

exec sp_xml_preparedocument @iDoc output, @parXML
delete Tichete
from Tichete a, 
OPENXML (@iDoc, '/row')
	WITH
	(
		subtip varchar(2) '@subtip',
		Data datetime '@data',
		Marca varchar(6) '@marca',
		Tip_operatie varchar(1) '@tiptichet',
		Serie_inceput varchar(13) '@serieinceput'

	) as dx
where a.Data_lunii=dx.Data and a.Marca=dx.Marca and a.Tip_operatie=dx.Tip_operatie and a.Serie_inceput=dx.Serie_inceput 
and dx.subtip in ('T1','T2')

exec sp_xml_removedocument @iDoc 
--select 'ok' as msg for xml raw
exec wIaPozSalarii @sesiune=@sesiune, @parXML=@parXML

end try

begin catch
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj=ERROR_MESSAGE()
		raiserror(@mesaj, 11, 1)
end catch
