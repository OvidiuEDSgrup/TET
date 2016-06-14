begin tran 
exec wScriuPozdoc '',
'<row subunitate="1" tip="AP" tert="RO5526120" numar="SV940260" data="06/02/2014" lm="1VZ_SV_02" contract="SV980960" zilescadenta="60" punctlivrare="" aviznefacturat="0">
  <detalii>
    <row modPlata="" />
  </detalii>
  <row pvaluta="8.3" valuta="" curs="0" discount="10.00" lm="1VZ_SV_02" gestiune="211.SV" cod="5-1604A" cantitate="50" contract="SV980960" />
</row>'
select top 4 p.Data_facturii,p.Data_scadentei,p.Numar_DVI,* from pozdoc p where p.Contract like 'SV980960' order by p.idPozDoc desc
--exec wscriudoc '',null
rollback tran