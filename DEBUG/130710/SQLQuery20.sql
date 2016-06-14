--exec RefacereStocuri null,null,null,null,null,null
execute as login='tet\MAGAZIN.NT'
begin tran
set transaction isolation level read uncommitted
insert ASiSRIA..sesiuniRIA (BD,token,utilizator)
select 'TESTOV','E531CED2708C2','MAGAZIN_NT'
select * from pozdoc p where p.Numar='9411348'
select * from docfiscalerezervate
select * from docfiscale
exec yso_wOPGenTEsauAPdinBK 
'E531CED2708C2'	
,'<row subunitate="1" tip="BK" numar="9812143" data="06/03/2013" explicatii="!? TRAISTA PT BESU ALEXANDRU" termen="06/03/2013" dengestiune="NT FILIALA NEAMT" gestiune="211.NT" dentert="RO5712298 - NEMIRA CONF SRL" factura="" tert="RO5712298" contractcor="" punctlivrare="" denpunctlivrare="" denlm="NEAMT FILIALA" lm="1VZ_NT_00" dengestprim="" gestprim="" valuta="" curs="0.0000" valoare="5342.65" valtva="1034.07" valtotala="6376.72" scadenta="0" contclient="" procpen="0" contr_cadru="" ext_camp4="" ext_camp5="01/01/1901" ext_modificari="" ext_clauze="" valabilitate="01/01/1901" pozitii="16" discount="0.0000000e+000" comspec="0" stare="1" categpret="1" dencategpret="Lista unica-Pret catalog  RON (1)" denstare="1-Facturabil" info1="" info2="0.00" info3="0.000000000000000e+000" info4="0.0000000e+000" info5="0.00" info6="" culoare="#0000FF" _nemodificabil="1" o_subunitate="1" o_tip="BK" o_numar="9812143" o_data="06/03/2013" o_explicatii="!? TRAISTA PT BESU ALEXANDRU" o_termen="06/03/2013" o_dengestiune="NT FILIALA NEAMT" o_gestiune="211.NT" o_dentert="RO5712298 - NEMIRA CONF SRL" o_factura="" o_tert="RO5712298" o_contractcor="" o_punctlivrare="" o_denpunctlivrare="" o_denlm="NEAMT FILIALA" o_lm="1VZ_NT_00" o_dengestprim="" o_gestprim="" o_valuta="" o_curs="0.0000" o_valoare="5342.65" o_valtva="1034.07" o_valtotala="6376.72" o_scadenta="0" o_contclient="" o_procpen="0" o_contr_cadru="" o_ext_camp4="" o_ext_camp5="01/01/1901" o_ext_modificari="" o_ext_clauze="" o_valabilitate="01/01/1901" o_pozitii="16" o_discount="0.0000000e+000" o_comspec="0" o_stare="1" o_categpret="1" o_dencategpret="Lista unica-Pret catalog  RON (1)" o_denstare="1-Facturabil" o_info1="" o_info2="0.00" o_info3="0.000000000000000e+000" o_info4="0.0000000e+000" o_info5="0.00" o_info6="" o_culoare="#0000FF" o__nemodificabil="1" update="1" numedelegat="traista " nrmijltransp="auto" observatii="" gesttr="" datadoc="07/05/2013" numardoc="9411348" aviznefacturat="0" tipMacheta="D" codMeniu="CO" TipDetaliere="BK" subtip="GT" />'
--select * from pozdoc p where p.Contract='9812485'
select * from pozdoc p where p.Numar='9411348'
select * from docfiscalerezervate
select * from docfiscale
rollback tran