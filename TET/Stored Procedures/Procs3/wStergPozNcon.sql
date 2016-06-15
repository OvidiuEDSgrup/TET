--***
create procedure wStergPozNcon @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @eroare xml 

begin try

exec sp_xml_preparedocument @iDoc output, @parXML

delete pozncon
from pozncon p, 
OPENXML (@iDoc, '/row')
	WITH
	(
		subunitate char(9) '@subunitate', 
		tip char(2) '@tip', 
		numar char(13) '@numar', 
		data datetime '@data', 
		nr_pozitie int '@nr_pozitie'
	) as dx
where p.subunitate = dx.subunitate and p.tip = dx.tip and p.numar = dx.numar and p.data = dx.data 
and (dx.nr_pozitie is null or p.nr_pozitie = dx.nr_pozitie)

exec sp_xml_removedocument @iDoc 

--select 'ok' as msg for xml raw
exec wIaPozNcon @sesiune=@sesiune, @parXML=@parXML

end try
begin catch
	--ROLLBACK TRAN
	
	declare @mesaj varchar(255)
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
	--select @eroare FOR XML RAW
end catch
