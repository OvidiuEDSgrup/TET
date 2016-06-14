begin tran
--/*
select * 
--*/delete p
from pozdoc p where p.Subunitate='1' and p.Tip='TE' and p.Data='2016-06-14' and p.Numar='IS930260'
exec yso_wOPStornareDocument null,
'
<row subunitate="1" tip="TE" numar="IS930252" numarf="IS930252" data="05/12/2016" dataf="05/12/2016" dengestiune="IS SHOWROOM IASI" gestiune="211.IS" dentert="" tert="378.0" factura="" contract="" denlm="IASI SHOWROOM" lm="1VZ_IS_00" dencomanda="" comanda="" indbug="" gestprim="110" dengestprim="CUSTODIE TERTI" punctlivrare="" denpunctlivrare="" valuta="" curs="0.0000" tcantitate="3.000" valoare="80.72" tva11="0.00" tva22="0.00" tvatotala="0.00" valtotala="80.72" valoarevaluta="0.00" totalvaloare="80.72" valvalutacutva="80.72" valvaluta="0.00" valoare_valuta_tert="0.00" valinpamanunt="441.62" categpret="0" facturanesosita="0" aviznefacturat="0" cotatva="0.00" discount="0.00" sumadiscount="0.00" tiptva="0" denTiptva="" explicatii="" numardvi="" proforma="0" tipmiscare="E" contfactura="4428.1" dencontfactura="4428.1-TVA neex. comert" contcorespondent="357" dencontcorespondent="Marfuri in custod.sau consig." contvenituri="378.0" dencontvenituri="Diferente de pret la marfuri" datafacturii="05/12/2016" datascadentei="05/12/2016" zilescadenta="0" jurnal="" numarpozitii="3" numedelegat="" seriabuletin="" numarbuletin="" eliberat="" mijloctp="" nrmijloctp="" dataexpedierii="05/12/2016" oraexpedierii="000000" observatii="" punctlivareexped="" contractcor="" stare="3" denStare="Operat" culoare="#000000" _nemodificabil="0" tipdocument="TE" nrdocument="IS930252" dataFactDoc="05/12/2016" idantetbon="0" o_tip="TE" o_numar="IS930252" o_data="05/12/2016" update="1" numardoc="" datadoc="06/14/2016" tipMacheta="D" codMeniu="DO_FILIALE" TipDetaliere="TE" subtip="SS">
  <o_DateGrid>
    <row tip="TE" data="05/12/2016" subunitate="1" numar="IS930252" numar_pozitie="574002" cod="BA-1612" gestiune="211.IS" cantitate="1.00000" cantitate_storno="-1.00000" cantitate_stornoMax="-1.00000" pvaluta="0.00000" valvaluta="0.000" valstoc="40.360" pstoc="40.36000" pvanzare="118.80000" pamanunt="118.80000" cotatva="0.00" sumatva="0.00" dencod="Arc exterior HENCO tub 16x2" cod_intrare="IMPL1" dengestiune="IS SHOWROOM IASI" idPozDoc="584793" />
    <row tip="TE" data="05/12/2016" subunitate="1" numar="IS930252" numar_pozitie="574007" cod="BA-2016" gestiune="211.IS" cantitate="1.00000" cantitate_storno="-1.00000" cantitate_stornoMax="-1.00000" pvaluta="0.00000" valvaluta="0.000" valstoc="40.360" pstoc="40.36000" pvanzare="123.61000" pamanunt="123.61000" cotatva="0.00" sumatva="0.00" dencod="Arc exterior HENCO tub 20x2" cod_intrare="IMPL1" dengestiune="IS SHOWROOM IASI" idPozDoc="584808" />
    <row tip="TE" data="05/12/2016" subunitate="1" numar="IS930252" numar_pozitie="580350" cod="RS32" gestiune="211.IS" cantitate="1.00000" cantitate_storno="-1.00000" cantitate_stornoMax="-1.00000" pvaluta="0.00000" valvaluta="0.000" valstoc="0.000" pstoc="0.00046" pvanzare="199.21000" pamanunt="199.21000" cotatva="0.00" sumatva="0.00" dencod="Dispozitiv HENCO taiat tub 14-32_fitinguri press" cod_intrare="6362058" dengestiune="IS SHOWROOM IASI" idPozDoc="590731" />
  </o_DateGrid>
  <DateGrid>
    <row tip="TE" data="05/12/2016" subunitate="1" numar="IS930252" numar_pozitie="574002" cod="BA-1612" gestiune="211.IS" cantitate="1.00000" cantitate_storno="-1.00000" cantitate_stornoMax="-1.00000" pvaluta="0.00000" valvaluta="0.000" valstoc="40.360" pstoc="40.36000" pvanzare="118.80000" pamanunt="118.80000" cotatva="0.00" sumatva="0.00" dencod="Arc exterior HENCO tub 16x2" cod_intrare="IMPL1" dengestiune="IS SHOWROOM IASI" idPozDoc="584793" />
    <row tip="TE" data="05/12/2016" subunitate="1" numar="IS930252" numar_pozitie="574007" cod="BA-2016" gestiune="211.IS" cantitate="1.00000" cantitate_storno="-1.00000" cantitate_stornoMax="-1.00000" pvaluta="0.00000" valvaluta="0.000" valstoc="40.360" pstoc="40.36000" pvanzare="123.61000" pamanunt="123.61000" cotatva="0.00" sumatva="0.00" dencod="Arc exterior HENCO tub 20x2" cod_intrare="IMPL1" dengestiune="IS SHOWROOM IASI" idPozDoc="584808" />
    <row tip="TE" data="05/12/2016" subunitate="1" numar="IS930252" numar_pozitie="580350" cod="RS32" gestiune="211.IS" cantitate="1.00000" cantitate_storno="-1.00000" cantitate_stornoMax="-1.00000" pvaluta="0.00000" valvaluta="0.000" valstoc="0.000" pstoc="0.00046" pvanzare="199.21000" pamanunt="199.21000" cotatva="0.00" sumatva="0.00" dencod="Dispozitiv HENCO taiat tub 14-32_fitinguri press" cod_intrare="6362058" dengestiune="IS SHOWROOM IASI" idPozDoc="590731" />
  </DateGrid>
  <detalii>
    <row locatie="1820817070012" explicatii="" denLocatie="AVADANI ANDREI/" />
  </detalii>
</row>
'
select top 20 d.detalii,*
from pozdoc p join doc d on d.Subunitate=p.Subunitate and d.Tip=p.Tip and d.Numar=p.Numar and d.Data=p.Data
where p.Tip='TE' and '110' in (p.Gestiune,p.Gestiune_primitoare)
and p.Cantitate<0
order by p.idPozDoc desc
rollback tran