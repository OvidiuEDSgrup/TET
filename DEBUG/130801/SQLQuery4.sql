declare @p2 xml
set @p2=convert(xml,N'<row tip="BN" _refresh="0" datajos="2013/08/01" datasus="2013/08/31"/>')
exec wIaBonuriNedescarcate @sesiune='F1CABA0601945',@parXML=@p2