declare @p2 xml
set @p2=convert(xml,N'<parametri subunitate="1" tip="BK" numar="7694" data="08/31/2012" explicatii="" termen="07/01/2012" dengestiune="MARFURI SI PIESE DE SCHIMB" gestiune="101" dentert="HIGH TECH SRL" factura="" tert="RO4438977" contractcor="RO4438977" punctlivrare="" denlm="BOF  SORIN-DANIEL" lm="1VNZ0607" dengestprim="" gestprim="" valuta="" curs="0.0000" valoare="7460.60" valtva="1790.54" valtotala="9251.14" scadenta="45" contclient="" procpen="" contr_cadru="" ext_camp4="" ext_modificari="" ext_clauze="" valabilitate="01/01/1901" pozitii="1" discount="0.0000000e+000" comspec="0" stare="1" denstare="1-Facturabil" info1="CEC" info2="0.00" info3="0.000000000000000e+000" info4="0.0000000e+000" info5="0.0000000e+000" info6="" culoare="#0000FF" _nemodificabil="1" o_subunitate="1" o_tip="BK" o_numar="7694" o_data="08/31/2012" o_explicatii="" o_termen="07/01/2012" o_dengestiune="MARFURI SI PIESE DE SCHIMB" o_gestiune="101" o_dentert="HIGH TECH SRL" o_factura="" o_tert="RO4438977" o_contractcor="RO4438977" o_punctlivrare="" o_denlm="BOF  SORIN-DANIEL" o_lm="1VNZ0607" o_dengestprim="" o_gestprim="" o_valuta="" o_curs="0.0000" o_valoare="7460.60" o_valtva="1790.54" o_valtotala="9251.14" o_scadenta="45" o_contclient="" o_procpen="" o_contr_cadru="" o_ext_camp4="" o_ext_modificari="" o_ext_clauze="" o_valabilitate="01/01/1901" o_pozitii="1" o_discount="0.0000000e+000" o_comspec="0" o_stare="1" o_denstare="1-Facturabil" o_info1="CEC" o_info2="0.00" o_info3="0.000000000000000e+000" o_info4="0.0000000e+000" o_info5="0.0000000e+000" o_info6="" o_culoare="#0000FF" o__nemodificabil="1" update="1" numedelegat="e" nrmijltransp="e" observatii="e" gesttr="" datadoc="09/12/2012" tipMacheta="D" codMeniu="CO" TipDetaliere="BK" subtip="GT"/>')
exec yso_wOPGenTEsauAPdinBK @sesiune='4BEB2060BF6A2',@parXML=@p2