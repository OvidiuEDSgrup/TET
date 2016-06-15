--***
CREATE procedure wStergPlin @sesiune varchar(50), @parXML xml OUTPUT
as

declare @iDoc int, @eroare xml ,@mesaj varchar(200), @root varchar(500)
begin try

if exists (select 1 from sysobjects where [type]='P' and [name]='wStergPlinSP')
	exec wStergPlinSP @sesiune, @parXML output

if isnull(@parXML.value('count(/row/@idPozPlin)','int'),0)=0
	set @root = '/row/row'
else
	set @root = '/row'

exec sp_xml_preparedocument @iDoc output, @parXML

delete pozplin
from pozplin p, 
OPENXML (@iDoc, @root)
	WITH
	(idPozPlin int '@idPozPlin') as dx
where p.idPozPlin = dx.idPozPlin

exec sp_xml_removedocument @iDoc 

exec wIaPozplin @sesiune=@sesiune, @parXML=@parXML

end try
begin catch
	 -- ROLLBACK TRAN
	set @mesaj = '(wStergPlin)'+ERROR_MESSAGE()
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
