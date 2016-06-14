declare @p2 xml
set @p2=convert(xml,N'<row idAntetBon="1039" UID="EF0C3183-81BE-3A96-1409-0FB6736CEAFA"/>')
exec wDescarcBon @sesiune='D8517A72D61A5',@parXML=@p2