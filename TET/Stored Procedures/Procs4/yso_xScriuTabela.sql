create procedure yso_xScriuTabela @tabela varchar(255), @sursaImport nvarchar(4000) as
begin try -- scriu pozcon
--*/declare @tabela varchar(255)='terti', @sursaImport nvarchar(4000)='\\10.0.0.10\IMPORT\testimport.xlsx '
 	declare @eroareProc varchar(500),@txtSql nvarchar(max),@txtFrom varchar(max), @sursa varchar(max),@txtSelect nvarchar(max)
		,@txtParam nvarchar(max),@eroareXL varchar(500), @contor int, @parxml xml, @hdlxml int
	
--/*sp
	declare @procid int=@@procid, @objname sysname, @hostid int, @param nvarchar(max)
	select @objname=object_name(@procid), @hostid=host_id(), @param=@tabela+@sursaimport
	EXEC wJurnalizareOperatie @sesiune='', @parXML=@param, @obiectSql=@objname
--sp*/
	
	set @tabela=LTRIM(@tabela)
	
	if OBJECT_ID('tempdb..##importXlsIniTmp') is not null
		drop table ##importXlsIniTmp
	
	set @txtFrom='OPENROWSET(''Microsoft.ACE.OLEDB.12.0'', @sursa, @txtSelect) x '
	
	set @sursa='Excel 12.0;Database=@sursaImport;Extended Properties="Excel 12.0 Xml;HDR=YES;IMEX=0;TypeGuessRows=0;ImportMixedTypes=Text";'
	set @sursa=REPLACE(@sursa,'@sursaImport',@sursaImport)
	set @txtFrom=REPLACE(@txtFrom,'@sursa',''''+@sursa+'''')
	
	set @txtSelect='Select * from ['+@tabela+'$]'
	set @txtFrom=REPLACE(@txtFrom,'@txtSelect',''''+@txtSelect+'''')
	
	set @txtSql='select * into ##importXlsIniTmp from '+@txtFrom--+'where cod=''537d6302'''

	print isnull(@txtSql,'nimic')
	
	exec sp_executesql @txtSql
		
	if OBJECT_ID('tempdb..##importXlsTmp') is not null
		drop table ##importXlsTmp

	if OBJECT_ID('tempdb..##importXlsDifTmp') is not null
		drop table ##importXlsDifTmp

	set @txtSelect=(select replace((
			/*select replace(c.name,' ','_')+'='
				+case when c.system_type_id in (59,62) and c.name<>'_linieimport' then 'convert(decimal(17,5),' else '(' end
				+'isnull('+QUOTENAME(c.name)+',''''))' 
				as [data()] */
			select replace(c.name,' ','_')+'='
				+isnull((case when t.collation_name is null and c.name<>'_linieimport' 
					then 'convert('+t.name+isnull('('+rtrim(l.[precision])+','+rtrim(nullif(l.scale,0))+'),',',') 
				else 'convert('+t.name+'('+rtrim(l.max_length)+'),' end),'(')
				+'isnull('+QUOTENAME(c.name)+','''')'+(case when c.system_type_id in (40,42,43,58,61) then ',101' else '' end)+')' 
				as [data()]
			from tempdb.sys.columns c 
				inner join tempdb.sys.objects o on o.object_id=c.object_id
				inner join sys.objects b on b.name like 'yso_vIa'+@tabela
				left join sys.columns l on l.object_id=b.object_id and l.name=c.name
				left join sys.types t on t.system_type_id=l.system_type_id
			where o.name='##importXlsIniTmp'
			order by l.column_id
			for xml path(''), type
		).value('(./text())[1]','nvarchar(max)'),' ',','))
	
	set @txtSelect='select '+@txtSelect
		+CHAR(10)+' into ##importXlsTmp from ##importXlsIniTmp order by _linieimport'
--/*
	print isnull(@txtSelect,'nimic')
--*/
	exec sp_executesql @txtSelect
	
	set @txtSelect=(select replace((
			select rtrim(c.name) as [data()] 
			from tempdb.sys.columns c 
				inner join tempdb.sys.objects o on o.object_id=c.object_id
				inner join sys.objects b on b.name like 'yso_vIa'+@tabela
				inner join sys.columns l on l.object_id=b.object_id and l.name=c.name
			where o.name='##importXlsTmp' order by l.column_id
			for xml path(''), type
		).value('(./text())[1]','nvarchar(max)'),' ',','))
	
	set @txtSelect='select distinct '+@txtSelect
		+char(10)+'into ##importXlsDifTmp'
		+char(10)+'from ##importXlsTmp '
		+char(10)+'except'
		+char(10)+'select distinct '+@txtSelect
		+char(10)+'from yso_vIa'+@tabela
--/*
	print isnull(@txtSelect,'nimic')
--*/
	exec sp_executesql @txtSelect
	
/*
	set @txtSql='yso_xImport'+@tabela
	exec sp_executesql @txtSql
*/
	alter table ##importXlsDifTmp add _nrdif int identity(1,1) not null
	create unique clustered index id on ##importXlsDifTmp (_nrdif)
	--create nonclustered index preturi on #preturiXlsDifTmp (cod, catpret, tippret, data_inferioara, pret_vanzare, pret_cu_amanuntul)

	declare @randuri int
	select @randuri=MAX(_nrdif) from ##importXlsDifTmp

	if OBJECT_ID('tempdb..##mesajeASiSTmp') is not null
		drop table ##mesajeASiSTmp
		
	select top 0 Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj 
	into ##mesajeASiSTmp from mesajeASiS
	
	if OBJECT_ID('tempdb..##importXlsErrTmp') is not null
		drop table ##importXlsErrTmp
		
	select top 0 _linieimport, convert(varchar(500),'') as _eroareimport into ##importXlsErrTmp from ##importXlsTmp t 
	
	--delete t from ##importXlsDifTmp t where t.tert not like 'BE0443598222'
	--update t set cantitate=1 from ##importXlsDifTmp t 
	
	set @contor=1
	while @contor<=@randuri 
	begin
		begin try
			select @txtSql='yso_xScriu'+@tabela+' @_nrdif', @txtParam='@_nrdif int'
			exec sp_executesql @txtSql, @txtParam, @_nrdif=@contor
 		end try
 		begin catch
 			begin try
 				set @eroareProc = ERROR_MESSAGE()
 				insert ##mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
				select '','','S',HOST_ID(),'Erori import linie '+@tabela,@eroareProc
			end try
			begin catch
				set @eroareXL = ERROR_MESSAGE()
				insert ##mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
				select '','','S',HOST_ID(),'Erori raportare erori in tabel',@eroareXL
			end catch
 		end catch 	
 		set @contor=@contor+1
	end
	begin try
		set @txtSql='UPDATE x SET _eroareimport = @eroareimport from '+@txtFrom
		set @txtParam='@eroareimport varchar(500)'
		exec sp_executesql @txtSql, @txtParam, ''
		
		set @txtSql=REPLACE(@txtSql,'@eroareimport','e._eroareimport')
		set @txtSql=@txtSql+' inner join ##importXlsErrTmp e on e._linieimport=x._linieimport'
		exec sp_executesql @txtSql
	end try
	begin catch
		set @eroareXL = ERROR_MESSAGE()
		insert ##mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
		select '','','S',HOST_ID(),'Erori raportare erori in excel',@eroareXL
	end catch
	
	insert mesajeASiS (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj, Data, Ora, Stare)
	select t.*,GETDATE(),'','' from 
		(select Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect
			, convert(varchar,count(*))+':'+Mesaj as Mesaj from ##mesajeASiSTmp
		group by Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj) t
	
	--if OBJECT_ID('tempdb..##importXlsIniTmp') is not null
	--	drop table ##importXlsIniTmp	

	--if OBJECT_ID('tempdb..##importXlsTmp') is not null
		--drop table ##importXlsTmp
	
	--if OBJECT_ID('tempdb..##importXlsDifTmp') is not null
	--	drop table ##importXlsDifTmp
		
	if OBJECT_ID('tempdb..##mesajeASiSTmp') is not null
		drop table ##mesajeASiSTmp -- select * from #mesajeASiSTmp
		
	if OBJECT_ID('tempdb..##importXlsErrTmp') is not null
		drop table ##importXlsErrTmp -- select * into testerrxls from #importXlsErrTmp
	
end try
begin catch
	declare @mesaj varchar(254)
	set @mesaj = 'yso_xScriuTabela: '+ ERROR_MESSAGE() 
	raiserror(@mesaj, 11, 1)	
end catch
