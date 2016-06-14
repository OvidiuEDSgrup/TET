select * from webJurnalOperatii j where j.obiectSql='wOPGenerareUnAPdinBKSP' and convert(nvarchar(max),j.parametruXML) like '%GL980463%'
order by j.data desc