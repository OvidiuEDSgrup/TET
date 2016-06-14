declare @p2 xml
set @p2=convert(xml,N'<row f_numar="bh910015" tip="RN" datajos="2015/02/01" datasus="2015/03/31"/>')
exec wIaContracte @sesiune='8B6B7C7D61397',@parXML=@p2