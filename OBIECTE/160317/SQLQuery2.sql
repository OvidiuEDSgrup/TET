declare @p2 xml
set @p2=convert(xml,N'<row codMeniu="DO_STORNO" subunitate="1" tip="AP" numar="IF940780" numarf="IF940780" data="03/11/2016" dataf="03/11/2016" dengestiune="IF SHOWROOM BUCURESTI" gestiune="211.IF" dentert="MURSTAI IMPORT-EXPORT SRL" tert="RO3153980" factura="IF940780" contract="IF981582" denlm="ILFOV2-BUCURESTI" lm="1VZ_IF_02" dencomanda="" comanda="" indbug="" gestprim="" dengestprim="" punctlivrare="" denpunctlivrare="" valuta="" curs="0.0000" tcantitate="107.000" valoare="4095.92" tva11="0.00" tva22="819.18" tvatotala="819.18" valtotala="4915.10" valoarevaluta="0.00" totalvaloare="4915.10" valvalutacutva="4915.10" valvaluta="0.00" valinpamanunt="0.00" categpret="0" facturanesosita="0" aviznefacturat="0" cotatva="0.00" discount="0.00" sumadiscount="0.00" tiptva="0" denTiptva="0-TVA Colectat" explicatii="" numardvi="" proforma="0" tipmiscare="E" contfactura="411.1" dencontfactura="411.1-Clienti interni" contcorespondent="607.1" dencontcorespondent="Cheltuieli privind marfuri en-gros" contvenituri="707.1" dencontvenituri="Venituri din vinz.de marfuri engros" datafacturii="03/11/2016" datascadentei="04/10/2016" zilescadenta="30" jurnal="" numarpozitii="18" numedelegat="MURARU SILVIU FLORIN" seriabuletin="RR" numarbuletin="919033" eliberat="" mijloctp="" nrmijloctp="AUTO" dataexpedierii="03/11/2016" oraexpedierii="153853" observatii="" punctlivareexped="" contractcor="" stare="3" denStare="Operat" culoare="#000000" _nemodificabil="0" tipdocument="AP" nrdocument="IF940780" _refresh="1"><detalii><row modPlata="OP" explicatii=""/></detalii></row>')
exec yso_wIaDocumenteStorno @sesiune='FB03355E11701',@parXML=@p2