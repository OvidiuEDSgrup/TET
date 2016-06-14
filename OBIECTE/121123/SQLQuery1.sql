declare @p2 xml
set @p2=convert(xml,N'<row tipMacheta="D" codMeniu="DO" tip="TE" TipDetaliere="TE" subtip="GI"/>')
exec wIaConfigurareMacheta @sesiune='AA29AB73CC322',@parXML=@p2