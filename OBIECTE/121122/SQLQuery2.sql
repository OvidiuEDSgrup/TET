declare @p2 xml
set @p2=convert(xml,N'<row tipMacheta="O" codMeniu="GT"/>')
exec yso_wOPGolireGestPrinTEStorno_p @sesiune='1994B3D55E7A3',@parXML=@p2