--***
create procedure [wStergDecaux] @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @eroare xml 

begin try

exec sp_xml_preparedocument @iDoc output, @parXML

delete decaux
from decaux p, 
OPENXML (@iDoc, '/row')
	WITH
	(
		subunitate varchar(9) '@subunitate', 
		numar_document varchar(8) '@numar_document',
		data datetime '@data', 
		l_m_furnizor varchar(9) '@l_m_furnizor',
		comanda_furnizor varchar(13) '@comanda_furnizor',
		loc_de_munca_beneficiar varchar(9) '@loc_de_munca_beneficiar',
		comanda_beneficiar varchar(13) '@comanda_beneficiar'
	) as dx
where p.subunitate = dx.subunitate and p.numar_document = dx.numar_document and p.data = dx.data 
and p.l_m_furnizor = dx.l_m_furnizor and p.comanda_furnizor = dx.comanda_furnizor 
and p.loc_de_munca_beneficiar = dx.loc_de_munca_beneficiar and p.comanda_beneficiar = dx.comanda_beneficiar

exec sp_xml_removedocument @iDoc 

exec wIaPozDecaux @sesiune=@sesiune, @parXML=@parXML

end try
begin catch
	--ROLLBACK TRAN
	declare @mesaj varchar(255)
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj = ERROR_MESSAGE() 
		--set @mesaj='<error coderoare="1" msgeroare="' + ERROR_MESSAGE() + '"/>'
	raiserror(@mesaj, 11, 1)
end catch

