select * from webJurnalOperatii j where j.obiectSql like 'wOPGenerareUnAPdinBKSP'
and convert(nvarchar(max), j.parametruXML) like '%sv980960%'

select * from webJurnalOperatii j where j.obiectSql like 'wScriuPozdoc%'
and convert(nvarchar(max), j.parametruXML) like '%GL940147%'