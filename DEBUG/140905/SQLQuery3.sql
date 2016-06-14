begin tran
select * from stocuri s where s.Cod_gestiune='700.sv' --s.Cod='FM 72268-006        ' and 
exec wScriuDocBeta '',
'<row subunitate="1" tip="TE" numar="test3" data="09/05/2014" gestiune="211.SV" gestprim="700.SV" contract="" categpret="1" lm="1VZ_SV_00" factura="SV981217" comanda="163080333306" numedelegat="BOSTIOG IOAN" mijloctp="" nrmijloctp="SV 10 UTR" seriebuletin="SV" numarbuletin="379538" eliberatbuletin="POL.MUN.RADAUTI" observatii="">
  <row cod="72280MSA" cantitate="1" pvaluta="1094.00000" discount="5.00" pamanunt="1288.73199" lm="1VZ_SV_00" valuta="" curs="0" locatie="163080333306" />
  <row cod="FM 72268-006" cantitate="-1" pvaluta="46.00000" discount="0.00" pamanunt="57.04000" lm="1VZ_SV_00" valuta="" curs="0" locatie="163080333306" />
</row>'
select * from pozdoc p where p.Numar='test3'
rollback tran