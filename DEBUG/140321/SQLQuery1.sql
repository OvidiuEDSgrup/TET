execute as login='tet\magazin.nt'
begin tran
declare @p2 xml
set @p2=convert(xml,N'<row data="03/21/2014" soldinitial="0" totalincasari="0" curs="0" totalplati="0" efect="" totalsold="0" tip="RE"><row numar="" tert="RO16600664" dentert="CON TERM INSTAL SRL (CF/CNP: RO16600664)" factura="NT940167" suma="0" explicatii="" subtip="IB"/></row>')
exec wScriuPozplin @sesiune='',@parXML=@p2
if @@TRANCOUNT>0
	rollback tran

revert