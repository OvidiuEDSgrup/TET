declare @p2 xml
set @p2=convert(xml,N'<row subunitate="1" tip="TE" numar="9320112" numarf="9320112" data="05/31/2012" dataf="05/31/2012" dengestiune="AVIZE INSTALATORI PCT LUCRU" gestiune="700" dentert="" tert="378.0" factura="" contract="" denlm="ORMENISAN  RAUL" lm="1VNZ0406" dencomanda="KOVACS TIBI" comanda="1600826120663" indbug="" gestprim="212" dengestprim="DEPOZIT CJ" punctlivrare="" denpunctlivrare="" valuta="" curs="0.0000" valoare="1096.51" tva11="0.00" tva22="0.00" tvatotala="0.00" valtotala="1096.51" valoarevaluta="0.00" totalvaloare="1096.51" categpret="4" dencatpret="LISTA MAGAZIN" facturanesosita="0" aviznefacturat="0" cotatva="0.00" discount="0.00" sumadiscount="4.00" tiptva="0" denTiptva="" explicatii="" numardvi="" proforma="0" tipmiscare="E" contfactura="4428" dencontfactura="4428-TVA neexigibila" contcorespondent="371.1" dencontcorespondent="Marfuri en-gros" contvenituri="378.0" dencontvenituri="Diferente de pret la marfuri" datafacturii="05/31/2012" datascadentei="05/31/2012" zilescadenta="0" jurnal="" numarpozitii="9" valamcatprimitor="0" numedelegat="" seriabuletin="" numarbuletin="" eliberat="" mijloctp="" nrmijloctp="" dataexpedierii="05/31/2012" oraexpedierii="000000" observatii="" punctlivareexped="" contractcor="" stare="3" denStare="Operat" culoare="#000000" _nemodificabil="0" tipdocument="TE" nrdocument="9320112">
<row ordonare="1" subunitate="1" tip="TE" subtip="TE" numar="9320112" data="05/31/2012" cod="RB-DF12MF" codcodi="RB-DF12MF" gestiune="700" gestprim="212" tert="378.0" lm="1VNZ0406" comanda="1600826120663" dencomanda="KOVACS TIBI" indbug="                    " codintrare="5511011" tipTVA="0.000" cantitate="10.000" pvaluta="0.00000" valvaluta="0.000" valstoc="44.400" pstoc="4.44000" pvanzare="8.09999" pamanunt="8.09999" cotatva="0.00" sumatva="0.00" tvavaluta="0.00" adaos="0.00" numarpozitie="28035" contstoc="357" valuta="" curs="0.0000" locatie="Locator Pct Lucru CJ" contract="" factura="" lot="" dataexpirarii="05/17/2012" explicatii="" jurnal="" contfactura="4428" discount="0.00" dvi="4428" punctlivrare="" barcod="" contcorespondent="371.1" categpret="4" accizecump="4.000" contvenituri="378.0" contintermediar="" dencodintrare="5511011G" denumire="TRUST-Robinet mini 1/2&quot; FI-FE" dencodcodi="TRUST-Robinet mini 1/2&quot; FI-FE" um="BUC" dengestiune="AVIZE INSTALATORI PCT LUCRU" tipgestiune="A" dengestprim="DEPOZIT CJ" tipgestprim="C" denlm="ORMENISAN  RAUL" dentert="" pamcatprimitor="8.09999" tvaneexigibil="0.00" culoare="#000000" cod_de="RB-DF12MF-TRUST-Robinet mini 1/2&quot; FI-FE" tert_prest="378.0" dentert_prest="" factura_prest="" contfactura_prest="4428" data_fact_prest="05/31/2012" data_scad_prest="05/31/2012" valuta_prest="" curs_prest="0.000" pret_valuta_prest="0.00000" cotatva_prest="0.00" tiptva_prest="0" denTiptva_prest="" cod_prest="RB-DF12MF" _expandat="da" update="1" o_cod="RB-DF12MF" o_codintrare="5511011G" o_cantitate="10.000" o_pamanunt="8.09999" o_discount="0.00"/><linie ordonare="1" subunitate="1" tip="TE" subtip="TE" numar="9320112" data="05/31/2012" cod="RB-DF12MF" codcodi="RB-DF12MF" gestiune="700" gestprim="212" tert="378.0" lm="1VNZ0406" comanda="1600826120663" dencomanda="KOVACS TIBI" indbug="                    " codintrare="5511011G" tipTVA="0.000" cantitate="10.000" pvaluta="0.00000" valvaluta="0.000" valstoc="44.400" pstoc="4.44000" pvanzare="8.09999" pamanunt="8.09999" cotatva="0.00" sumatva="0.00" tvavaluta="0.00" adaos="0.00" numarpozitie="28035" contstoc="357" valuta="" curs="0.0000" locatie="Locator Pct Lucru CJ" contract="" factura="" lot="" dataexpirarii="05/17/2012" explicatii="" jurnal="" contfactura="4428" discount="0.00" dvi="4428" punctlivrare="" barcod="" contcorespondent="371.1" categpret="4" accizecump="4.000" contvenituri="378.0" contintermediar="" dencodintrare="5511011G" denumire="TRUST-Robinet mini 1/2&quot; FI-FE" dencodcodi="TRUST-Robinet mini 1/2&quot; FI-FE" um="BUC" dengestiune="AVIZE INSTALATORI PCT LUCRU" tipgestiune="A" dengestprim="DEPOZIT CJ" tipgestprim="C" denlm="ORMENISAN  RAUL" 
dentert="" pamcatprimitor="8.09999" tvaneexigibil="0.00" culoare="#000000" cod_de="RB-DF12MF-TRUST-Robinet mini 1/2&quot; FI-FE" tert_prest="378.0" dentert_prest="" factura_prest="" contfactura_prest="4428" data_fact_prest="05/31/2012" data_scad_prest="05/31/2012" valuta_prest="" curs_prest="0.000" pret_valuta_prest="0.00000" cotatva_prest="0.00" tiptva_prest="0" denTiptva_prest="" cod_prest="RB-DF12MF" _expandat="da"/></row>')
exec wScriuPozdoc @sesiune='AD31661681721',@parXML=@p2