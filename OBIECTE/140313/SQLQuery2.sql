declare @p2 xml
set @p2=convert(xml,N'
<parametri subunitate="1" tip="BK" numar="NT980194" data="02/11/2014" explicatii="" termen="02/11/2014" dengestiune="NT SHOWROOM  NEAMT" gestiune="211.NT" dentert="RO16600664 - CON TERM INSTAL SRL" factura="" tert="RO16600664" contractcor="RO16600664" punctlivrare="" denpunctlivrare="" denlm="NEAMT SHOW-ROOM" lm="1VZ_NT_00" dengestprim="" gestprim="" valuta="" curs="0.0000" valoare="680.00" valtva="163.20" valtotala="843.20" scadenta="0" contclient="" procpen="0" contr_cadru="" ext_camp4="" ext_camp5="01/01/1901" ext_modificari="" ext_clauze="" valabilitate="01/01/1901" pozitii="1" discount="0.0000000e+000" comspec="0" stare="1" categpret="1" dencategpret="Lista unica-Pret catalog  RON (1)" denstare="1-Facturabil" info1="" info2="0.00" info3="0.000000000000000e+000" info4="0.0000000e+000" info5="0.00" info6="" culoare="#0000FF" _nemodificabil="1" iddelegat="8" numedelegat="ALTUL               IOSICUMINE                    ISX23345    POLISJUD                      " prenumedelegat="IOSICUMINE" nrmijltransp="IS02EEE" denmijloctp="IS02EEE   AUDI                          " mijloctp="AUDI" seriebuletin="ISX" numarbuletin="23345" eliberatbuletin="POLISJUD" data_expedierii="03/13/2014" ora_expedierii="12:23:47" nrformular="RIA_FACT" denformular=" RIA Factura" o_dentert="RO16600664 - CON TERM INSTAL SRL" o_iddelegat="8" o_prenumedelegat="IOSICUMINE" o_seriebuletin="ISX" o_numarbuletin="23345" o_eliberatbuletin="POLISJUD" o_nrmijltransp="IS02EEE" o_mijloctp="AUDI" o_nrformular="RIA_FACT" update="1" numardoc="" datadoc="03/13/2014" noudelegat="0" noumijltp="0" observatii="" tipMacheta="D" codMeniu="CO" TipDetaliere="BK" subtip="GF">
  <o_DateGrid>
    <row cod="100-ISO4-16-RO" cantitate_factura="100" cantitate_disponibila="100" pamanunt="0" denumire="HE-Tub 16x2 Standard cu izolatie rosie 6 mm (colaci 100m)" cant_aprobata="100" cant_realizata="0" subunitate="1" tip="BK" data="02/11/2014" contract="NT980194" tert="RO16600664" numar_pozitie="1" />
  </o_DateGrid>
  <DateGrid>
    <row cod="100-ISO4-16-RO" cantitate_factura="1000" cantitate_disponibila="100" pamanunt="0" denumire="HE-Tub 16x2 Standard cu izolatie rosie 6 mm (colaci 100m)" cant_aprobata="100" cant_realizata="0" subunitate="1" tip="BK" data="02/11/2014" contract="NT980194" tert="RO16600664" numar_pozitie="1" />
  </DateGrid>
</parametri>')
select @p2
exec wOPGenerareUnAPdinBK @sesiune='',@parXML=@p2

--select * from pozcon p where p.Contract='NT980194'