	select rtrim(c.contract) as cod, 
		(case when c.explicatii='' 
			then 'Com. pt. '+rtrim(case when c.tert='' then g.Denumire_gestiune else t.Denumire end)+' din '+rtrim(convert(char(10),c.Data,103)) 
			else rtrim(c.explicatii) end) as denumire, 
		rtrim(case when c.tert='' then c.cod_dobanda else c.tert end) as info
	from con c 
	left outer join gestiuni g on g.Subunitate=c.Subunitate and g.Cod_gestiune=c.Cod_dobanda 
	left outer join terti t on t.Subunitate=c.Subunitate and  t.Tert=c.Tert 
	where c.tip='BF' 
		and (rtrim(c.contract) like 'e'+'%' or rtrim(c.explicatii) like '%'+'e'+'%' or rtrim(t.Denumire ) like '%'+'e'+'%')
		and (c.Tert='RO14317824' or isnull('RO14317824','')='' )--or @tip<>'PD')
	for xml raw