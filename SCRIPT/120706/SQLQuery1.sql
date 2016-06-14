declare @p2 xml
set @p2=convert(xml,N'<row idAntetBon="858" UID="A3E42B45-D317-C095-4A85-5AA47B088A42"/>')
exec wDescarcBon @sesiune='3CFD652D51B31',@parXML=@p2