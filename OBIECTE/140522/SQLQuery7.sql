declare @p2 xml
set @p2=convert(xml,N'<row idAntetBon="5196" UID="E1FF7ADF-FE1B-45C1-2585-23EDD67040B9" vDescarc="1"/>')
exec wDescarcBon @sesiune='',@parXML=@p2