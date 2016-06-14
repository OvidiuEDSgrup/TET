select TOP 100 * from webJurnalOperatii j where convert(nvarchar(max),j.parametruXML) like '%980869%' 
OR convert(nvarchar(max),j.parametruXML) like '%940294%' 
ORDER BY J.data DESC