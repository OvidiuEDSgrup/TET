declare @p2 xml
set @p2=convert(xml,N'<row tipdocument="RE" serie="CJ" numarinferior="970000" numarsuperior="979999" ultimulnumar="970096" denserieinnumar="Da" serieinnumar="1" idPlaja="13" update="1" o_tipdocument="IB" o_serie="CJ" o_numarinferior="970000" o_numarsuperior="979999" o_ultimulnumar="970096" descriere="" meniupl="PI" subtippl="IB" tipMacheta="C" codMeniu="PJ"/>')
exec wScriuPlajeDocumente @sesiune='EC3A4C96F6714',@parXML=@p2