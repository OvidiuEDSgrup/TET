declare @p2 xml
set @p2=convert(xml,N'<row tip="RE" _refresh="1" datajos="2014/05/01" datasus="2014/05/31"/>')
exec wIaPlin @sesiune='3024F61B35BB0',@parXML=@p2