declare @p2 xml
set @p2=convert(xml,N'<row subunitate="1" tip="BK" numar="NT980211" data="03/19/2014" explicatii="comanda CLIENT SERVBUJOR ionut" termen="03/19/2014" dengestiune="MARFURI SI PIESE DE SCHIMB" gestiune="101" dentert="SERV BUJOR SRL" factura="10000017" tert="RO9252098" contractcor="" punctlivrare="" denpunctlivrare="" denlm="NEAMT3" lm="1VZ_NT_03" dengestprim="NT SHOWROOM  NEAMT" gestprim="211.NT" valuta="" curs="0.0000" valoare="5211.00" valtva="1250.64" valtotala="6461.64" scadenta="0" contclient="" procpen="0" contr_cadru="" ext_camp4="" ext_camp5="01/01/1901" ext_modificari="" ext_clauze="" valabilitate="01/01/1901" pozitii="10" discount="0.0000000e+000" comspec="0" stare="6" categpret="1" dencategpret="Lista unica-Pret catalog  RON (1)" denstare="6-Realizat" info1="" info2="0.00" info3="0.000000000000000e+000" info4="0.0000000e+000" info5="0.00" info6="" culoare="#808080" _nemodificabil="1" tipMacheta="D" codMeniu="CO" TipDetaliere="BK" subtip="GF"><row subunitate="1" tip="BK" subtip="BK" numar="NT980211" data="2014-03-19T00:00:00" cod="400018" dencod="400018 - CIM-Vas de expansiune SOLAR 18" gestiune="101" 
cantitate="1.00000" valuta="" termene="03/19/2014" termen="03/19/2014" Tpret="137.0000" tert="RO9252098" Tcantitate="1.00000" Tcant_realizata="1.00000" um1="BUC" cantitateum1="1.00000" um2="" coefconvum2="0.00000" cantitateum2="0.00000" um3="" coefconvum3="0.00000" cantitateum3="0.00000" pret="137.00000" cant_transferata="1.0000" discount="2.00000" cotatva="24.00" punctlivrare="211.NT" modplata="" denumire="CIM-Vas de expansiune SOLAR 18" dengestiune="MARFURI SI PIESE DE SCHIMB" tipgestiune="C" dentert="SERV BUJOR SRL" cant_realizata="1.00000" cant_aprobata="1.00000" termen_poz="03/19/2014" explicatii="0" denspecif="" numarpozitie="5" lot="" dataexpirarii="01/01/1901" obiect="" denobiect="" info1="0.000000000000000e+000" info2="" info3="0.000000000000000e+000" info4="" info5="" info6="Jan  1 190" info7="Jan  1 190" info8="0.00000" info9="0.00000" info10="0.00000" info11="0.00000" info12="" info13="" info14="" info15="" info16="" info17="" Tachitat="0.00" Tfacturat="137.00" codsisursa="400018 - CIM-Vas de expansiune SOLAR 18&#x0A;"/></row>')
exec wOPGenerareUnAPdinBK_p @sesiune='EC3A4C96F6714',@parXML=@p2