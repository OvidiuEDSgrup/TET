update p set Val_logica=0 from par p where p.Parametru like 'DOCDEF' and p.Tip_parametru='GE'
delete p
from pozdoc p where p.numar like 'GL940147'
exec wScriuPozdoc '','
<row subunitate="1" tip="AP" tert="RO13746003" numar="GL940147" data="05/28/2014" lm="1VZ_GL_01" contract="GL980463" zilescadenta="60" punctlivrare="">
  <row pvaluta="6.4" valuta="" curs="0" discount="10.00" lm="1VZ_GL_01" gestiune="211.GL" cod="100-200216PN16" cantitate="500" contract="GL980463" />
</row>'
update p set Val_logica=1 from par p where p.Parametru like 'DOCDEF' and p.Tip_parametru='GE'