declare @p2 xml
set @p2=convert(xml,N'<row idAntetBon="1039" UID="57951EA9-9B19-96F8-D884-01698D6745E9"/>')
exec wDescarcBon @sesiune='B008C3AD0A533',@parXML=@p2