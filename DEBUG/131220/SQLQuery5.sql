begin tran
declare @p2 xml
set @p2=convert(xml,N'<parametri subunitate="1" tip="BK" numar="9822599" data="12/17/2013" explicatii="" termen="12/17/2013" dengestiune="CJ SHOWROOM  CLUJ" gestiune="211.CJ" dentert="RO16359044 - RAMIVLAD INSTAL SRL" factura="" tert="RO16359044" contractcor="" punctlivrare="" denpunctlivrare="" denlm="CLUJ SHOW-ROOM" lm="1VZ_CJ_00" dengestprim="" gestprim="" valuta="" curs="0.0000" valoare="17992.00" valtva="4318.08" valtotala="22310.08" scadenta="0" contclient="" procpen="0" contr_cadru="" ext_camp4="" ext_camp5="01/01/1901" ext_modificari="" ext_clauze="" valabilitate="01/01/1901" pozitii="1" discount="0.0000000e+000" comspec="0" stare="1" categpret="1" dencategpret="Lista unica-Pret catalog  RON (1)" denstare="1-Facturabil" info1="" info2="0.00" info3="0.000000000000000e+000" info4="0.0000000e+000" info5="0.00" info6="" culoare="#0000FF" _nemodificabil="1" update="1" numedelegat="c" nrmijltransp="c" observatii="c" gesttr="" datadoc="12/18/2013" numardoc="" aviznefacturat="0" tipMacheta="D" codMeniu="CO" TipDetaliere="BK" subtip="GT"/>')
exec yso_wOPGenTEsauAPdinBK @sesiune='90607DBEAC255',@parXML=@p2

select * from pozdoc p where p.Contract='9831858'
rollback tran

select * from sysspcon p where p.Contract='9822599'
order by p.Data_stergerii desc