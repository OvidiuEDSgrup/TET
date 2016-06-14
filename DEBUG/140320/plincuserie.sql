execute as login='tet\magazin.dj' -- cod utilizator MAGAZIN_DJ

begin tran
declare @p2 xml
set @p2=convert(xml,N'
<row data="03/20/2014" soldinitial="0" cont="5311.DJ" totalincasari="0" curs="0" totalplati="0" efect="" totalsold="0" tip="RE">
  <row numar="" tert="RO9175570" dentert="MLTR CONSULTING SRL (CF/CNP: RO9175570)" factura="DJ940086" suma="0" explicatii="" subtip="IB" />
</row>')
select @p2
exec wScriuPozplin @sesiune='',@parXML=@p2

--select * from docfiscale d where d.UltimulNr=10000001
select * -- update d set tipdoc='RE'
from docfiscale d where d.TipDoc='RE' and d.Id IN (select a.Id from asocieredocfiscale a where a.Cod='MAGAZIN_DJ')

if @@TRANCOUNT>0
	rollback tran
revert