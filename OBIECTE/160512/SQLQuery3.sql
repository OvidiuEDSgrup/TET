select * from pozdoc p where p.Numar='NT942142'
select * from con c join pozcon p on p.Contract=c.Contract and p.Tip=c.Tip and p.Tert=c.Tert
where c.Factura like 'NT942150'

select * from webJurnalOperatii j where j.data>='2016-05-10'
and convert(nvarchar(max),j.parametruXML) like '%NT985629%'