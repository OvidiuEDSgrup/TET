select * from webJurnalOperatii j where j.data>='2016-01-01'
and convert(nvarchar(max),j.parametruXML) like '%13859%'
--and j.obiectSql like '%descarc%'

--select * from antetBonuri a where a.Factura like 'GL941416'

select * from sysspd p where p.Factura like 'GL941416'
order by p.Data_stergerii desc

select * from pozdoc p where p.Factura like 'GL941416'