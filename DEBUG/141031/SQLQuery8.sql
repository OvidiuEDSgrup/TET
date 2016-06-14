declare @p2 xml
set @p2=convert(xml,N'<row idInventar="1" data="10/31/2014" gestiune="" stare="2" denstare="Rezolvat" pozitii="0" grupa="" culoare="#C0C0C0" locatie="" o_data="10/31/2014" o_gestiune="900" o_grupa="" o_locatie="" update="0" tipMacheta="D" codMeniu="D_IN" tip="ID" subtip="DI" searchText="300"/>')
exec wACGestLMMarcaInventar @sesiune='D67002965A9A4',@parXML=@p2