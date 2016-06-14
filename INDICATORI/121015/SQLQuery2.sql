declare @p2 xml
set @p2=convert(xml,N'<row cod="VMB" denumire="MARJA BRUTA DIN VANZARI" expresie="exec calculIndVMB" detalieredata="Da" cudata="1" gaugeinvers="1" descriere="" dataJos="08/01/2012" dataSus="08/31/2012" tip="CT" tipMacheta="C" codMeniu="CT" TipDetaliere="CT" subtip="RC"/>')
exec wCalculezIndicatori @sesiune='3DC5003CBC533',@parXML=@p2