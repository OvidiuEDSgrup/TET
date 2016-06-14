	if OBJECT_ID('tempdb..#preturiXlsTmp') is not null
		drop table #preturiXlsTmp

	--set dateformat mdy
	select *
	into #preturiXlsTmp
	from xPreturi...preturi$
	--where cod like '01263006'
	--select * from #preturiXlsTmp

	if OBJECT_ID('tempdb..#preturiXlsDifTmp') is not null
		drop table #preturiXlsDifTmp

	select distinct cod, catpret, tippret, data_inferioara, data_superioara, pret_vanzare, pret_cu_amanuntul
	into #preturiXlsDifTmp
	from #preturiXlsTmp 
	except
	select cod, catpret, tippret, data_inferioara, data_superioara, pret_vanzare, pret_cu_amanuntul
	from yso_vIaPreturiNomenclator

--select * from #preturiXlsDifTmp 
--select * from yso_vIaPreturiNomenclator where cod like '1-2004Z'

	alter table #preturiXlsDifTmp add nrcrt int identity(1,1) not null
	create unique clustered index id on #preturiXlsDifTmp (nrcrt)
	
UPDATE x 
				SET [eroare_import] = ''
				from OPENROWSET('Microsoft.ACE.OLEDB.12.0'
				,'Excel 12.0;Database=\\10.0.0.10\import\testimport.xlsx;Extended Properties="Excel 12.0 Xml;IMEX=0;HDR=YES;";'
				, 'Select * from [preturi$]') x 
				--inner join #preturiXlsDifTmp t 
				--on isnull(x.cod,'')=isnull(t.cod,'') and isnull(x.catpret,'')=isnull(t.catpret,'') 
				--	and isnull(x.tippret,'')=isnull(t.tippret,'') and isnull(x.data_inferioara,'1900-01-01')=isnull(t.data_inferioara,'1900-01-01') 
				--	and isnull(x.data_superioara,'1900-01-01')=isnull(t.data_superioara,'1900-01-01') and isnull(x.pret_vanzare,'')=isnull(t.pret_vanzare,'') 
				--	and isnull(x.pret_cu_amanuntul,'')=isnull(t.pret_cu_amanuntul,'')
				WHERE x.catpret='1234567'