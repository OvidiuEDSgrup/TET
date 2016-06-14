FROM avnefac,pozdoc,terti,nomencl,anexafac,doc,infotert
WHERE pozdoc.subunitate=avnefac.subunitate and pozdoc.tip=avnefac.tip and pozdoc.numar=avnefac.numar and avnefac.data=pozdoc.data and pozdoc.cod=nomencl.cod and avnefac.subunitate=terti.subunitate and pozdoc.tert=terti.tert and anexafac.subunitate=avnefac.subunitate and anexafac.numar_factura=pozdoc.factura and pozdoc.subunitate=doc.subunitate and pozdoc.tip=doc.tip and pozdoc.numar=doc.numar and pozdoc.data=doc.data and pozdoc.subunitate=infotert.subunitate and pozdoc.tert=infotert.tert and doc.Gestiune_primitoare=infotert.identificator and pozdoc.tert=doc.cod_tert and pozdoc.factura=doc.factura
GROUP BY  pozdoc.cod, pozdoc.pret_vanzare, pozdoc.pret_valuta, avnefac.cod_gestiune, pozdoc.tert, pozdoc.numar, pozdoc.data

FROM pozdoc 
left join avnefac on pozdoc.subunitate=avnefac.subunitate and pozdoc.tip=avnefac.tip and pozdoc.numar=avnefac.numar and avnefac.data=pozdoc.data 
left join doc on pozdoc.subunitate=doc.subunitate and pozdoc.tip=doc.tip and pozdoc.numar=doc.numar and pozdoc.data=doc.data 
left join terti on pozdoc.subunitate=terti.subunitate and pozdoc.tert=terti.tert 
left join infotert on pozdoc.subunitate=infotert.subunitate and pozdoc.tert=infotert.tert and doc.Gestiune_primitoare=infotert.identificator 
left join nomencl on pozdoc.cod=nomencl.cod 
left join anexafac on anexafac.subunitate=pozdoc.subunitate and anexafac.numar_factura=pozdoc.factura
GROUP BY  pozdoc.cod, pozdoc.pret_vanzare, pozdoc.pret_valuta, avnefac.cod_gestiune, pozdoc.tert, pozdoc.numar, pozdoc.data