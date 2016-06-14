BEGIN TRAN
declare @p2 xml
set @p2=convert(xml,N'<row idAntetBon="5686" vDescarc="1"/>')
exec wDescarcBon @sesiune='18683BC3D60B3',@parXML=@p2
ROLLBACK TRAN