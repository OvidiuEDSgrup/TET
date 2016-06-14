/*
La clientul GHEPOP Impex Srl , apare achitata pe 14 sept factura 9430174, insa eu nu regasesc nicaieri aceasta factura ( RIA, CG,DOC, POZDOC)
 desi este pusa la dosar . Initial a fost facuta incasarea la avizul nefacturat 9430173 din 14 sept ,avizul in valoare de 392.26 si incasarea
  de 390.74 , deci sold =1.52 Factura 9430174 este aferenta avizului 9430173 si le gasesti in attach impreuna cu chitanta.
 */
 
 select * from tempdb..factemise f where f.factura like '9430174'
 select * from pozadoc p where p.Factura_stinga='9430174'