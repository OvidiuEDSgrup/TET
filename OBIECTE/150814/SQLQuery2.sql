--drop proc validareStocNegativ
--drop proc ValidareNecorelatiiStocuri
--delete pozdoc where numar='NT941545'
begin tran
exec wOPGenerareUnAPdinBKSP '','
<row subunitate="1" tip="BK" numar="NT984143" data="07/09/2015" explicatii="!?albet DOCHIA/reglare +supl. telef.albet=IONEL" termen="07/09/2015" dengestiune="NT SHOWROOM  NEAMT" gestiune="211.NT" dentert="TERMOGAZ GRUP SRL" factura="" tert="RO12517559" contractcor="RO12517559" punctlivrare="" denpunctlivrare="" denlm="NEAMT3" lm="1VZ_NT_03" dengestprim="" gestprim="" valuta="" curs="0.0000" valoare="233.62" valtva="56.07" valtotala="289.69" scadenta="0" contclient="" procpen="0" contr_cadru="" ext_camp4="" ext_camp5="01/01/1901" ext_modificari="" ext_clauze="" valabilitate="01/01/1901" pozitii="12" discount="0.0000000e+000" comspec="0" operat="07/17/2015" stare="1" categpret="1" dencategpret="Lista unica-Pret catalog  RON (1)" denstare="1-Facturabil" info1="" info2="0.00" info3="0.000000000000000e+000" info4="0.0000000e+000" info5="0.00" info6="" culoare="#0000FF" _nemodificabil="1" beneficiar="RO12517559" denbenef="RO12517559 - TERMOGAZ GRUP SRL" numardoc="" iddelegat="1" numedelegat="ANDRIESCU                                                             GABRIEL                       NT 125441   POL. P. NEAMT                 " prenumedelegat="GABRIEL" nrmijltransp="TAXI" denmijloctp="TAXI                                                                                      " mijloctp="" seriebuletin="NT" numarbuletin="125441" eliberatbuletin="POL. P. NEAMT" data_expedierii="07/20/2015" ora_expedierii="13:07:19" modPlata="NUMERAR" nrformular="RIA_FACT" denformular=" RIA Factura" o_beneficiar="RO12517559" o_numardoc="" o_iddelegat="1" o_prenumedelegat="GABRIEL" o_seriebuletin="NT" o_numarbuletin="125441" o_eliberatbuletin="POL. P. NEAMT" o_nrmijltransp="TAXI" o_modPlata="NUMERAR" o_nrformular="RIA_FACT" update="1" datadoc="07/20/2015" aviznefacturat="0" noudelegat="0" observatii="" tipMacheta="D" codMeniu="CO" TipDetaliere="BK" subtip="GF">
  <o_DateGrid>
    <row cod="100-ISO4-16-BL" cantitate_factura="11.000" cantitate_disponibila="11.000" gestiune="211.NT" denumire="HE-Tub 16x2 Standard cu izolatie bleu 6 mm (colaci 100m)" cant_aprobata="11.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="3" />
    <row cod="10220119" cantitate_factura="1.000" cantitate_disponibila="1.000" gestiune="211.NT" denumire="TRUST-Cot 110X90" cant_aprobata="1.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="14" />
    <row cod="10220128" cantitate_factura="1.000" cantitate_disponibila="1.000" gestiune="211.NT" denumire="TRUST-Ramificatie 110X110X90" cant_aprobata="1.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="13" />
    <row cod="25001102" cantitate_factura="24.000" cantitate_disponibila="24.000" gestiune="211.NT" denumire="TRUST-Teava PPR fibra compozita DN20, bara 4 m" cant_aprobata="24.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="10" />
    <row cod="25003402" cantitate_factura="2.000" cantitate_disponibila="2.000" gestiune="211.NT" denumire="TRUST-Cot echer dublu 20x20, PPR" cant_aprobata="2.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="8" />
    <row cod="25004602" cantitate_factura="8.000" cantitate_disponibila="8.000" gestiune="211.NT" denumire="TRUST-Teu egal 20x20x20" cant_aprobata="8.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="9" />
    <row cod="25006602" cantitate_factura="8.000" cantitate_disponibila="8.000" gestiune="211.NT" denumire="TRUST-Cot echer 20x1/2&quot; M, PPR" cant_aprobata="8.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="6" />
    <row cod="4300902014021" cantitate_factura="6.000" cantitate_disponibila="6.000" gestiune="211.NT" denumire="HK-Dop 20x1/2&quot;&quot; T" cant_aprobata="6.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="7" />
    <row cod="AT 1420" cantitate_factura="2.000" cantitate_disponibila="2.000" gestiune="211.NT" denumire="HE-Teu egal 3/4&quot;&quot; T ptr conexiune eurocon" cant_aprobata="2.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="5" />
    <row cod="EK 16" cantitate_factura="7.000" cantitate_disponibila="7.000" gestiune="211.NT" denumire="HE-Racord eurocon ptr tub 16x2" cant_aprobata="7.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="4" />
    <row cod="VB-060503-R" cantitate_factura="5.000" cantitate_disponibila="5.000" gestiune="211.NT" denumire="HE-Colector 1&quot;&quot; cu robineti sferici ptr conexiune eurocon, rosu-3 cai" cant_aprobata="5.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="15" />
    <row cod="VB-060504-R" cantitate_factura="-4.000" cantitate_disponibila="-4.000" gestiune="211.NT" denumire="HE-Colector 1&quot;&quot; cu robineti sferici ptr conexiune eurocon, rosu-4 cai" cant_aprobata="-4.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="1" />
  </o_DateGrid>
  <DateGrid>
    <row cod="100-ISO4-16-BL" cantitate_factura="11.000" cantitate_disponibila="11.000" gestiune="211.NT" denumire="HE-Tub 16x2 Standard cu izolatie bleu 6 mm (colaci 100m)" cant_aprobata="11.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="3" />
    <row cod="10220119" cantitate_factura="1.000" cantitate_disponibila="1.000" gestiune="211.NT" denumire="TRUST-Cot 110X90" cant_aprobata="1.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="14" />
    <row cod="10220128" cantitate_factura="1.000" cantitate_disponibila="1.000" gestiune="211.NT" denumire="TRUST-Ramificatie 110X110X90" cant_aprobata="1.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="13" />
    <row cod="25001102" cantitate_factura="24.000" cantitate_disponibila="24.000" gestiune="211.NT" denumire="TRUST-Teava PPR fibra compozita DN20, bara 4 m" cant_aprobata="24.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="10" />
    <row cod="25003402" cantitate_factura="2.000" cantitate_disponibila="2.000" gestiune="211.NT" denumire="TRUST-Cot echer dublu 20x20, PPR" cant_aprobata="2.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="8" />
    <row cod="25004602" cantitate_factura="8.000" cantitate_disponibila="8.000" gestiune="211.NT" denumire="TRUST-Teu egal 20x20x20" cant_aprobata="8.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="9" />
    <row cod="25006602" cantitate_factura="8.000" cantitate_disponibila="8.000" gestiune="211.NT" denumire="TRUST-Cot echer 20x1/2&quot; M, PPR" cant_aprobata="8.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="6" />
    <row cod="4300902014021" cantitate_factura="6.000" cantitate_disponibila="6.000" gestiune="211.NT" denumire="HK-Dop 20x1/2&quot;&quot; T" cant_aprobata="6.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="7" />
    <row cod="AT 1420" cantitate_factura="2.000" cantitate_disponibila="2.000" gestiune="211.NT" denumire="HE-Teu egal 3/4&quot;&quot; T ptr conexiune eurocon" cant_aprobata="2.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="5" />
    <row cod="EK 16" cantitate_factura="7.000" cantitate_disponibila="7.000" gestiune="211.NT" denumire="HE-Racord eurocon ptr tub 16x2" cant_aprobata="7.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="4" />
    <row cod="VB-060503-R" cantitate_factura="5.000" cantitate_disponibila="5.000" gestiune="211.NT" denumire="HE-Colector 1&quot;&quot; cu robineti sferici ptr conexiune eurocon, rosu-3 cai" cant_aprobata="5.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="15" />
    <row cod="VB-060504-R" cantitate_factura="-4.000" cantitate_disponibila="-4.000" gestiune="211.NT" denumire="HE-Colector 1&quot;&quot; cu robineti sferici ptr conexiune eurocon, rosu-4 cai" cant_aprobata="-4.000" cant_realizata="0.000" subunitate="1" tip="BK" data="07/09/2015" contract="NT984143" tert="RO12517559" numar_pozitie="1" />
  </DateGrid>
</row>'
rollback tran