declare @p2 xml
set @p2=convert(xml,N'<row dentert="DOMSA A"/>')
exec wIaTerti @sesiune='A8C01CAE30062',@parXML=@p2