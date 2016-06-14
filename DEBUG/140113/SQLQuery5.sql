select * from webJurnalOperatii j where j.obiectSql like '%storn%'
and convert(nvarchar(max),j.parametruXML) like '%9490032%'

select * from pozdoc p where p.Numar like '9490032'