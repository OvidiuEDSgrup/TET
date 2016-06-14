begin tran
declare @p2 xml
set @p2=convert(xml,N'<row idAntetBon="8252" UID="C074F39D-BA7A-1004-E626-64F58698B14E" vDescarc="1"/>')
exec wDescarcBon @sesiune='9C4E893B32AC6',@parXML=@p2
rollback tran