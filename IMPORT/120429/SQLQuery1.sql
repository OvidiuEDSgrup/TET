select * from ##importXlsIniTmp
select replace((
	select replace(c.name,' ','_')+'=isnull('+QUOTENAME(c.name)+','''')' as [data()] 
	from tempdb.sys.columns c inner join tempdb.sys.objects o on o.object_id=c.object_id
	where o.name='##importXlsIniTmp' order by c.column_id
	for xml path(''), type
).value('(./text())[1]','nvarchar(max)'),' ',',')

select replace((
	select rtrim(c.name) as [data()] 
	from tempdb.sys.columns c 
		inner join tempdb.sys.objects o on o.object_id=c.object_id
		inner join sys.objects b on b.name like 'yso_vIa'+ltrim(rtrim('Stoclim'))
		inner join sys.columns l on l.object_id=b.object_id and l.name=c.name
	where o.name='##importXlsTmp' order by l.column_id
	for xml path(''), type
).value('(./text())[1]','nvarchar(max)'),' ',',')

select *
from ##importXlsDifTmp
for xml raw
select * 
select * from sys.types order by name

select --Subunitate=isnull(([Subunitate]),''),Tip_gestiune=isnull(([Tip_gestiune]),''),Cod_gestiune=isnull(([Cod_gestiune]),''),Den_gestiune=isnull(([Den_gestiune]),''),Cod=isnull(([Cod]),''),Den_cod=isnull(([Den_cod]),''),Data=isnull(([Data]),'')
Stoc_min=--
convert(decimal(17,5),isnull([Stoc_min],''))
--,'')
--,Stoc_max=isnull(convert(decimal(17,5),[Stoc_max]),''),_eroareimport=isnull(([_eroareimport]),'')--,_linieimport=isnull(convert(decimal(17,5),[_linieimport]),'')
 --into ##importXlsTmp 
 from ##importXlsIniTmp order by _linieimport
 
 select Subunitate=(isnull([Subunitate],'')),Tip_gestiune=(isnull([Tip_gestiune],'')),Cod_gestiune=(isnull([Cod_gestiune],'')),Den_gestiune=(isnull([Den_gestiune],'')),Cod=(isnull([Cod],'')),Den_cod=(isnull([Den_cod],'')),Data=(isnull([Data],'')),Stoc_min=convert(decimal(17,5),isnull([Stoc_min],'')),Stoc_max=convert(decimal(17,5),isnull([Stoc_max],'')),_eroareimport=(isnull([_eroareimport],'')),_linieimport=convert(decimal(17,5),isnull([_linieimport],''))
 --into ##importXlsTmp 
 from ##importXlsIniTmp order by _linieimport