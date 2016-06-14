declare @p2 xml
set @p2=convert(xml,N'<row tip="CA" codmeniu="CA"/>')
exec wIaConfigurareTaburi @sesiune='20B3329472541',@parXML=@p2