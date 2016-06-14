declare @p2 xml
set @p2=convert(xml,N'<row tipMacheta="D" codMeniu="AD" tip="IF" subtip="IF" update="0" numar="" data="02/08/2012" tert="1125411" facturastinga="" facturadreapta=" " contdeb="" contcred="" suma="0" cotatva="0" diftva="0" searchText="  "/>')
exec wACFacturiBenef @sesiune='6DFBEE909B606',@parXML=@p2