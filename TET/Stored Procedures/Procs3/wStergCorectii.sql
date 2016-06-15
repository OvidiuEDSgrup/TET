--***
Create
procedure wStergCorectii @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @eroare xml, @mesaj varchar(254)

begin try
exec sp_xml_preparedocument @iDoc output, @parXML

delete Corectii
from Corectii c, 
OPENXML (@iDoc, '/row')
	WITH
	(
		Data datetime '@data', 
		Marca varchar(6) '@marca', 
		Loc_de_munca varchar(9) '@lm', 
		Tip_corectie_venit varchar(2) '@tipcor'
	) as dx
where c.Data=dx.Data and c.Marca=dx.Marca and c.Loc_de_munca=dx.Loc_de_munca and c.Tip_corectie_venit=dx.Tip_corectie_venit

exec sp_xml_removedocument @iDoc 
--select 'ok' as msg for xml raw
exec wIaPozSalarii @sesiune=@sesiune, @parXML=@parXML
end try

begin catch
	--ROLLBACK TRAN
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
