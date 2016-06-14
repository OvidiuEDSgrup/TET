declare @p2 xml
set @p2=convert(xml,N'<row dentert="sandu vasile"/>')
exec wIaTerti @sesiune='3B53801028673',@parXML=@p2