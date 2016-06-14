declare @p2 xml
set @p2=convert(xml,N'<row idAntetBon="1107" UID="A4BB7960-FB95-F4F7-1A86-4EB6E76C65FC"/>')
exec wDescarcBon @sesiune='57E9D7FF1B513',@parXML=@p2