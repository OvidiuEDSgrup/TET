
declare @tabela varchar(200)='terti'
declare @txtSelect nvarchar(max)=(select replace((
			select replace(c.name,' ','_')+'='
				+case when t.collation_name is null and c.name<>'_linieimport' then 'convert('+t.name+isnull('('+rtrim(l.[precision])+','+rtrim(nullif(l.scale,0))+'),',',') 
				else 'convert('+t.name+'('+rtrim(l.max_length)+'),' end
				+'isnull('+QUOTENAME(c.name)+',''''))' 
				as [data()] 
			from tempdb.sys.columns c 
				inner join tempdb.sys.objects o on o.object_id=c.object_id
				inner join sys.objects b on b.name like 'yso_vIa'+@tabela
				inner join sys.columns l on l.object_id=b.object_id and l.name=c.name
				inner join sys.types t on t.system_type_id=l.system_type_id
			where o.name='##importXlsTmp' order by l.column_id
			for xml path(''), type
		).value('(./text())[1]','nvarchar(max)'),' ',','))
select @txtSelect

select 
t.name
,c.*
--,o.* 
from sys.columns c inner join sys.objects o on o.object_id=c.object_id
inner join sys.types t on t.system_type_id=c.system_type_id
where o.name like 'yso_vIaterti'

select * from sys.types

--select * from ##importXlsiniTmp

select /*
replace(c.name,' ','_')+'='
				+case when t.collation_name is null and c.name<>'_linieimport' then 'convert(,'+t.name+'('+rtrim(l.[precision])+','+rtrim(l.scale)+')' 
				else 'convert(,'+t.name+'('+rtrim(l.max_length)+')' end
				+'isnull('+QUOTENAME(c.name)+',''''))' 
				as [data()] 
*/
t.collation_name,t.name,l.precision,l.scale,l.max_length
			from tempdb.sys.columns c 
				inner join tempdb.sys.objects o on o.object_id=c.object_id
				inner join sys.objects b on b.name like 'yso_vIa'+@tabela
				inner join sys.columns l on l.object_id=b.object_id and l.name=c.name
				inner join sys.types t on t.system_type_id=l.system_type_id
			where o.name='##importXlsTmp' order by l.column_id
/*
select p.termenscadenta,* -- update it set discount=isnull(p.termenscadenta,it.discount)
from infotert it inner join terti t on t.Subunitate=it.Subunitate and t.Tert=it.Tert and it.Identificator=''
inner join ##importXlsiniTmp p on p.tert=it.Tert

select p.termenscadenta,* -- update t set sold_maxim_ca_beneficiar=isnull(p.soldmaxben,t.sold_maxim_ca_beneficiar)
from terti t
inner join ##importXlsiniTmp p on p.tert=t.Tert
*/
declare @test decimal(4)=34
select @test

select * from ##importXlsDifTmp