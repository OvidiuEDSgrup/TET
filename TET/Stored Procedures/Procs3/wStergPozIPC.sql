--***
create procedure [dbo].[wStergPozIPC] @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @eroare xml, @datal datetime, @tip char(2), @mesaj varchar(255)

begin try

exec sp_xml_preparedocument @iDoc output, @parXML
set @datal=isnull(@parXML.value('(/row/@datal)[1]','datetime'),'01/01/1901')
set @tip=isnull(@parXML.value('(/row/@tip)[1]','char(2)'),'')

delete MF_ipc
from MF_ipc p, 
OPENXML (@iDoc, '/row')
	WITH
	(
		tip char(2) '@tip', 
		subtip char(2) '@subtip', 
		an int '@an', 
		luna int '@luna'
	) as dx
where p.Data = @datal and p.An = dx.an and p.Luna = dx.luna

exec sp_xml_removedocument @iDoc 

exec wIaPozIPC @sesiune=@sesiune, @parXML=@parXML

end try

begin catch
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj='<error coderoare="1" msgeroare="' + ERROR_MESSAGE() + '"/>'
	raiserror(@mesaj, 11, 1)
end catch
