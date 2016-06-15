CREATE PROCEDURE yso_xScriuPreturiNomencl @fisier nvarchar(4000) as
begin try
	-- declare @fisier nvarchar(4000) set @fisier='\\10.0.0.10\import\testimport1.xlsx'
	declare @eroareProc varchar(500),@txtSql nvarchar(max),@sursa varchar(max),@txtSelect varchar(max)
		,@txtParam nvarchar(max),@eroareXL varchar(500), @contor int, @parxml xml 
	
	--if exists (select 1 from sys.servers s where s.name like 'xNomencl')
	--EXEC sp_dropserver
	--	@server = N'xNomencl',
	--	@droplogins='droplogins'

	--EXEC sp_addlinkedserver  
	--	@server = 'xNomencl',
	--	@srvproduct = 'Excel', 
	--	@provider = 'Microsoft.ACE.OLEDB.12.0',
	--	@datasrc = @fisier,
	--	@provstr = 'Excel 12.0 Xml;IMEX=1;HDR=YES;'
	
	if OBJECT_ID('tempdb..##preturiXlsIniTmp') is not null
	drop table ##preturiXlsIniTmp

	set @sursa='Excel 12.0;Database=@fisier;Extended Properties="Excel 12.0 Xml;IMEX=1;HDR=YES;";'
	set @sursa=REPLACE(@sursa,'@fisier',@fisier)
	set @txtSelect='Select * from [preturi$]'
	set @txtSql=
	'select * into ##preturiXlsIniTmp
	from OPENROWSET(''Microsoft.ACE.OLEDB.12.0''
	,@sursa
	, @txtSelect) x '
	set @txtSql=REPLACE(@txtSql,'@sursa',''''+@sursa+'''')
	set @txtSql=REPLACE(@txtSql,'@txtSelect',''''+@txtSelect+'''')
	exec sp_executesql @txtSql

	if OBJECT_ID('tempdb..#preturiXlsTmp') is not null
		drop table #preturiXlsTmp

	--set dateformat mdy
	select *
	into #preturiXlsTmp
	from ##preturiXlsIniTmp
	--where cod like '01263006'
	--select * from #preturiXlsTmp

	if OBJECT_ID('tempdb..#preturiXlsDifTmp') is not null
		drop table #preturiXlsDifTmp

	select distinct cod, catpret, tippret
		, isnull(data_inferioara,'') as data_inferioara
		, isnull(data_superioara,'') as data_superioara
		, convert(decimal(12,3),pret_vanzare) as pret_vanzare
		, convert(decimal(12,3),pret_cu_amanuntul) as pret_cu_amanuntul
	into #preturiXlsDifTmp
	from #preturiXlsTmp 
	except
	select cod, catpret, tippret, data_inferioara, data_superioara, pret_vanzare, pret_cu_amanuntul
	from yso_vIaPreturiNomenclator
/*

select * from #preturiXlsDifTmp order by cod
select * from yso_vIaPreturiNomenclator where cod like 'SLME3HP20X2CA_12'

*/
	alter table #preturiXlsDifTmp add nrcrt int identity(1,1) not null
	create unique clustered index id on #preturiXlsDifTmp (nrcrt)
	--create nonclustered index preturi on #preturiXlsDifTmp (cod, catpret, tippret, data_inferioara, pret_vanzare, pret_cu_amanuntul)

	declare @randuri int
	select @randuri=MAX(nrcrt) from #preturiXlsDifTmp

	if OBJECT_ID('tempdb..#mesajeASiSTmp') is not null
		drop table #mesajeASiSTmp
		
	select top 0 Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj 
	into #mesajeASiSTmp from mesajeASiS
	
	if OBJECT_ID('tempdb..#preturiXlsErrTmp') is not null
	drop table #preturiXlsErrTmp
		
	select top 0 _linieimport, convert(varchar(500),'') as _eroareimport into #preturiXlsErrTmp from #preturiXlsTmp t 

	set @contor=1
	while @contor<=@randuri
	begin
		begin try
			set @parxml=(select t.cod as o_cod,t.cod
				, rtrim(catpret) as catpret
				, rtrim(tippret) as tippret
				, convert(char(10),data_inferioara,126) as data_inferioara 
				, convert(decimal(12,3),t.pret_vanzare) as pret_vanzare
				, convert(decimal(12,3),t.pret_cu_amanuntul) as pret_cu_amanuntul
				,isnull((select TOP 1 1 from yso_vIaPreturiNomenclator v 
					where v.cod=t.cod and v.catpret=t.catpret and v.tippret=t.tippret /*and v.datai=t.datai*/),0) as [update] 
				from #preturiXlsDifTmp t 
					--inner join nomencl n on n.Cod=t.cod
					--inner join categpret c on c.Categorie=t.catpret
				where t.nrcrt=@contor for xml raw, root('row'))
				if isnull(@parXML.value('(/row/@cod)[1]','varchar(20)'),@parXML.value('(/row/row/@cod)[1]','varchar(20)'))
					='AA9H0KPRM'
					print 'stop'
			if @parxml is not null
 				exec yso_wScriuPreturiNomenclator @sesiune=null,@parxml=@parxml
 		end try
		begin catch
			set @eroareProc = ERROR_MESSAGE()
			begin try
				insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
				select '','','S',HOST_ID(),'Erori import linie preturi',@eroareProc
				
				insert #preturiXlsErrTmp
				select _linieimport, @eroareProc as _eroareimport from #preturiXlsTmp t inner join #preturiXlsDifTmp d
					on d.cod=t.cod and d.catpret=t.catpret and d.tippret=t.tippret 
						and d.data_inferioara=t.data_inferioara and d.data_superioara=t.data_superioara 
						and d.pret_vanzare=t.pret_vanzare and d.pret_cu_amanuntul=t.pret_cu_amanuntul 
				where d.nrcrt=@contor
			end try
			begin catch
				set @eroareXL = ERROR_MESSAGE()
				insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
				select '','','S',HOST_ID(),'Erori raportare erori in tabel',@eroareXL
			end catch
 		end catch
 		--select @parxml
 		set @contor=@contor+1
	end
	begin try
		set @sursa='Excel 12.0;Database=@fisier;Extended Properties="Excel 12.0 Xml;IMEX=0;HDR=YES;";'
		set @sursa=REPLACE(@sursa,'@fisier',@fisier)
		set @txtSelect='Select * from [preturi$]'
		set @txtSql=
		'UPDATE x 
		SET _eroareimport = @eroareimport
		from OPENROWSET(''Microsoft.ACE.OLEDB.12.0''
		,@sursa
		, @txtSelect) x '
		set @txtSql=REPLACE(@txtSql,'@sursa',''''+@sursa+'''')
		set @txtSql=REPLACE(@txtSql,'@txtSelect',''''+@txtSelect+'''')
		set @txtParam='@eroareimport varchar(500)'
		exec sp_executesql @txtSql, @txtParam, ''
		set @txtSql=REPLACE(@txtSql,'@eroareimport','e._eroareimport')
		set @txtSql=@txtSql+' inner join #preturiXlsErrTmp e on e._linieimport=x._linieimport'
		exec sp_executesql @txtSql
	end try
	begin catch
		set @eroareXL = ERROR_MESSAGE()
		insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
		select '','','S',HOST_ID(),'Erori raportare erori in excel',@eroareXL
	end catch
	
	--delete mesajeASiS where Tip_destinatar='S' and Destinatar=HOST_ID()
	insert mesajeASiS (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj, Data, Ora, Stare)
	select t.*,GETDATE(),'','' from 
		(select Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, convert(varchar,count(*))+':'+Mesaj as Mesaj from #mesajeASiSTmp
			group by Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj) t
	
	if OBJECT_ID('tempdb..##preturiXlsIniTmp') is not null
		drop table ##preturiXlsIniTmp	

	if OBJECT_ID('tempdb..#preturiXlsTmp') is not null
		drop table #preturiXlsTmp
	
	
	if OBJECT_ID('tempdb..#preturiXlsDifTmp') is not null
		drop table #preturiXlsDifTmp
		
	if OBJECT_ID('tempdb..#mesajeASiSTmp') is not null
		drop table #mesajeASiSTmp -- select * from #mesajeASiSTmp
		
	if OBJECT_ID('tempdb..#preturiXlsErrTmp') is not null
		drop table #preturiXlsErrTmp -- select * into testerrxls from #preturiXlsErrTmp
	
end try
begin catch
	declare @mesaj varchar(254)
	set @mesaj = 'yso_xScriuPreturiNomencl: '+ ERROR_MESSAGE() 
	raiserror(@mesaj, 11, 1)	
end catch
