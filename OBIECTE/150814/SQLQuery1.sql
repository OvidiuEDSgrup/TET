select p.Contract,* from pozdoc p where p.Numar like 'NT941545'
select * from webJurnalOperatii j where j.data between '2015-07-20 00:00:00.000' and '2015-07-21 00:00:00.000'
and convert(nvarchar(max),j.parametruXML) like '%NT984143%'
order by data desc