select *
FROM pozdoc 
left join avnefac on pozdoc.subunitate=avnefac.subunitate and pozdoc.tip=avnefac.tip and pozdoc.numar=avnefac.numar and avnefac.data=pozdoc.data 
left join doc on pozdoc.subunitate=doc.subunitate and pozdoc.tip=doc.tip and pozdoc.numar=doc.numar and pozdoc.data=doc.data 
left join anexafac on anexafac.subunitate=pozdoc.subunitate and anexafac.numar_factura=pozdoc.factura 
left join nomencl on pozdoc.cod=nomencl.cod 
left join terti on pozdoc.subunitate=terti.subunitate and pozdoc.tert=terti.tert 
left join infotert on pozdoc.subunitate=infotert.subunitate and pozdoc.tert=infotert.tert and doc.Gestiune_primitoare=infotert.identificator 
left join Localitati on Localitati.cod_oras=ISNULL(nullif(infotert.Pers_contact,''),terti.Localitate) 
left join Judete on Judete.cod_judet=ISNULL(nullif(infotert.Telefon_fax2,''),terti.Judet)
--select * from infotert