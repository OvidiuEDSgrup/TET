declare @p2 xml

set @p2=convert(xml,N'<row subunitate="1" tip="BK" numar="NT985715" data="05/30/2016" explicatii="AF.COM.985715=TRUNCHIATA /OP.2584.08LEI" termen="05/30/2016" dengestiune="MARFURI SI PIESE DE SCHIMB" gestiune="101" dentert="LD TUR COMPANY SRL" factura="" tert="RO33226846" contractcor="" punctlivrare="" denpunctlivrare="" denlm="NEAMT3" lm="1VZ_NT_03" dengestprim="NT SHOWROOM  NEAMT" gestprim="211.NT" valuta="" curs="0.0000" valoare="2153.43" valtva="430.69" valtotala="2584.12" scadenta="0" contclient="" procpen="0" contr_cadru="" ext_camp4="" ext_camp5="01/01/1901" ext_modificari="" ext_clauze="" valabilitate="01/01/1901" pozitii="27" discount="0.0000000e+000" comspec="0" operat="06/30/2016" stare="0" categpret="1" dencategpret="Lista unica-Pret catalog  RON (1)" denstare="0-Operat" info1="" info2="0.00" info3="0.000000000000000e+000" info4="0.0000000e+000" info5="0.00" info6="" culoare="#000000" _nemodificabil="0" tipMacheta="D" codMeniu="CO_FILIALE" TipDetaliere="BK" subtip="GF"/>')
exec wOPGenerareUnAPdinBK_p @sesiune='3A5C52C2DFFC1',@parXML=@p2
--SELECT * FROM pozcon c where c.Contract like 'NT985715' and c.Cod like '100-200216PN16'
--SELECT * FROM pozdoc c where c.Cod like '100-200216PN16' AND C.NUMAR LIKE '1019%' ORDER BY C.DATA DESC

