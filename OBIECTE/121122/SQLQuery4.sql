declare @p2 xml
set @p2=convert(xml,N'<row tipMacheta="O" codMeniu="GT"/>')
exec yso_wOPGolireGestPrinTEStorno_p @sesiune='2BE710BA032B7',@parXML=@p2