declare @p2 xml
set @p2=convert(xml,N'<row f_cont="5311.2" tip="RE" datajos="2013/01/01" datasus="2013/01/09"/>')
exec wIaPlin @sesiune='F5E39F38EAD15',@parXML=@p2