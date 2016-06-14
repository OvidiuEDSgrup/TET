declare @p2 xml
set @p2=convert(xml,N'<row f_factura="" tip="BY" datajos="2013/05/23" datasus="2014/05/23"/>')
exec wIaBonuri @sesiune='',@parXML=@p2