set transaction isolation level read uncommitted
begin tran
EXECUTE AS LOGIN='TET\Magazin.SV'
select dbo.fIaUtilizator(''),dbo.fIaUtilizator(null)

execute wscriudatepv '',
--'<row idAntetBon="2503" UID="5CF09D82-135D-9D5C-208B-AD34E463EB6B" />' 
--/*
'<date>
  <document aplicatie="PV" tip="PV" casamarcat="4" data="07/05/2013" inXML="0" UID="5CF09D82-135D-9D5C-208B-AD34E463EB6B" categoriePret="1" tert="1750203334997" tipdoc="AC" numarDoc="1" pentruValidare="1" ora="0802" totaldocument="589.5" totalincasari="589.5" descarcarePrioritara="0">
    <pozitii>
      <row contract="9840522" data="07/01/2013" punctLivrare="" tert="1750203334997" explicatii="9840522-TURCULET ADRIAN" cod="9-3650-004-91-22-13" denumire="TRUST-Colector 1&quot;&quot; din alama cu robineti reglaj si debitmetre, Premium-4 cai" cantitate="1" um="BUC" pretcatalog="812.2" cotatva="24" discount="20" lm="1VZ_SV_00" gestiune="211.SV" pret="649.76" valoare="649.76" tipLinie="Produs" tip="21" o_pretcatalog="812.2000000000" valoarefaradiscount="812.2" tva="125.76" pretftva="524" valftva="524" observatii="1 BUC x 812.2(-20%)" nrlinie="1" />
      <row contract="9840522" data="07/01/2013" punctLivrare="" tert="1750203334997" explicatii="9840522-TURCULET ADRIAN" cod="9-3680-120-00-22-13" denumire="TRUST-Modul hidraulic ptr incalzire prin pardoseala" cantitate="1" um="BUC" pretcatalog="1850.08" cotatva="24" discount="20" lm="1VZ_SV_00" gestiune="211.SV" pret="1480.06" valoare="1480.06" tipLinie="Produs" tip="21" o_pretcatalog="1850.0800000000" valoarefaradiscount="1850.08" tva="286.46" pretftva="1193.6" valftva="1193.6" observatii="1 BUC x 1850.08(-20%)" nrlinie="2" />
      <row contract="9840522" data="07/01/2013" punctLivrare="" tert="1750203334997" explicatii="9840522-TURCULET ADRIAN" cod="9-3690-530-00-24-01" denumire="TRUST-Cutie de distributie ptr incastrare Divibox L 530 mm" cantitate="-1" um="BUC" pretcatalog="204.6" cotatva="24" discount="20" lm="1VZ_SV_00" gestiune="211.SV" pret="163.68" valoare="-163.68" tipLinie="Produs" tip="21" o_pretcatalog="204.6000000000" valoarefaradiscount="-204.6" tva="-31.68" pretftva="132" valftva="-132" observatii="-1 BUC x 204.6(-20%)" nrlinie="3" />
      <row contract="9840522" data="07/01/2013" punctLivrare="" tert="1750203334997" explicatii="9840522-TURCULET ADRIAN" cod="9-3690-680-00-24-01" denumire="TRUST-Cutie de distributie ptr incastrare Divibox L 680 mm" cantitate="1" um="BUC" pretcatalog="238.08" cotatva="24" discount="20" lm="1VZ_SV_00" gestiune="211.SV" pret="190.46" valoare="190.46" tipLinie="Produs" tip="21" o_pretcatalog="238.0800000000" valoarefaradiscount="238.08" tva="36.86" pretftva="153.6" valftva="153.6" observatii="1 BUC x 238.08(-20%)" nrlinie="4" />
      <row contract="9840522" data="07/01/2013" punctLivrare="" tert="1750203334997" explicatii="9840522-TURCULET ADRIAN" cod="UFH-0405-SC1" denumire="HE-Modul hidraulic Comfort cu pompa si vana reglaj incluse-1 cale" cantitate="-1" um="BUC" pretcatalog="1958.88" cotatva="24" discount="20" lm="1VZ_SV_00" gestiune="211.SV" pret="1567.1" valoare="-1567.1" tipLinie="Produs" tip="21" o_pretcatalog="1958.8800000000" valoarefaradiscount="-1958.88" tva="-303.31" pretftva="1263.79" valftva="-1263.79" observatii="-1 BUC x 1958.88(-20%)" nrlinie="5" />
      <row denumire="Numerar" tipLinie="Incasare" tip="31" pret="589.5" cantitate="1" valoare="589.5" nrlinie="6" />
    </pozitii>
  </document>
</date>'
--*/
commit tran
--select * from antetbonuri a where a.IdAntetBon=2503
--select dbo.wfValidarePozdoc(null)
--UPDATE pozdoc set Subunitate='1' where 1=0