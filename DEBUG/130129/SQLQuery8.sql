declare @p2 xml
set @p2=convert(xml,N'<row f_cont="5311.2" tip="RE" datajos="2013/01/01" datasus="2013/01/30"/>')
exec wIaPlin @sesiune='32C0AFE6A3EE6',@parXML=@p2