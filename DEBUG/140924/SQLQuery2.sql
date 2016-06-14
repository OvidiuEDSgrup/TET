select top 100 *
from webJurnalOperatii j 
where convert(nvarchar(max),j.parametruXML) like '%AG980370%'
--select * from antetBonuri a where a.Factura like '940327'