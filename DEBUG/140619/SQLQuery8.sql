declare @p2 xml
set @p2=convert(xml,N'<row idAntetBon="5609" UID="5B509533-620E-B151-6C25-B44CC6C6D2DA" vDescarc="1"/>')
exec wDescarcBon @sesiune='261F3B762E577',@parXML=@p2