drop view yso_vIaCodvama 
go
create view yso_vIaCodvama with schemabinding as 
select rtrim(Cod) as Cod, Denumire
	, Val1 as Tip_cod, case Val1 when 0 then 'Cod vamal' when 1 then 'Cod nom. combinat' else '' end as Den_tip
	, UM, UM2, Coef_conv, Taxa_UE, Taxa_AELS, Taxa_GB, Taxa_alte_tari, Comision_vamal, Randament
	, rtrim(Alfa1) as Cod_NC8
	, rtrim(Alfa2) as UM_suplimentara
	--,CONVERT(nvarchar(500),'') as _eroareimport
from dbo.codvama c
	--inner join dbo.nomencl n on n.cod=c.cod
go
create unique clustered index unic on dbo.yso_vIaCodvama (cod)
go
create unique nonclustered index modificabile on dbo.yso_vIaCodvama (cod) 
include (Denumire, Tip_cod, UM, UM2, Coef_conv, Taxa_UE, Taxa_AELS, Taxa_GB, Taxa_alte_tari, Comision_vamal, Randament, Cod_NC8, UM_suplimentara)
go
drop proc yso_xIaCodvama 
go
create proc yso_xIaCodvama as
select *
from yso_vIaCodvama 
go
if exists (select * from sysobjects where name ='yso_xScriuCodvama')
drop procedure yso_xScriuCodvama
go
create procedure yso_xScriuCodvama  @fisier nvarchar(4000) as
begin try
	--declare @fisier nvarchar(4000) set @fisier='\\10.0.0.10\import\ASIS_nomenclator_articole_de actualizat in asis_cu coloana note_17mai2012_DB.xlsx'
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
	
	if OBJECT_ID('tempdb..##codvamaXlsIniTmp') is not null
	drop table ##codvamaXlsIniTmp

	set @sursa='Excel 12.0;Database=@fisier;Extended Properties="Excel 12.0 Xml;IMEX=1;HDR=YES;";'
	set @sursa=REPLACE(@sursa,'@fisier',@fisier)
	set @txtSelect='Select * from [codvama$]'
	set @txtSql=
	'select * into ##codvamaXlsIniTmp
	from OPENROWSET(''Microsoft.ACE.OLEDB.12.0''
	,@sursa
	, @txtSelect) x '
	set @txtSql=REPLACE(@txtSql,'@sursa',''''+@sursa+'''')
	set @txtSql=REPLACE(@txtSql,'@txtSelect',''''+@txtSelect+'''')
	exec sp_executesql @txtSql

	if OBJECT_ID('tempdb..#codvamaXlsTmp') is not null
		drop table #codvamaXlsTmp

	--set dateformat mdy
	select isnull(Cod,'') as Cod, isnull(Denumire,'') as Denumire, isnull(Tip_cod,'') as Tip_cod, isnull(Den_tip,'') as Den_tip, isnull(UM,'') as UM, isnull(UM2,'') as UM2, isnull(Coef_conv,'') as Coef_conv, isnull(Taxa_UE,'') as Taxa_UE, isnull(Taxa_AELS,'') as Taxa_AELS, isnull(Taxa_GB,'') as Taxa_GB, isnull(Taxa_alte_tari,'') as Taxa_alte_tari, isnull(Comision_vamal,'') as Comision_vamal, isnull(Randament,'') as Randament, isnull(Cod_NC8,'') as Cod_NC8, isnull(UM_suplimentara,'') as UM_suplimentara, isnull(_eroareimport,'') as _eroareimport
	,_linieimport
	into #codvamaXlsTmp
	from ##codvamaXlsIniTmp
	--where cod like '01263006'

	if OBJECT_ID('tempdb..#codvamaXlsDifTmp') is not null
		drop table #codvamaXlsDifTmp

	select distinct Cod, Denumire, Tip_cod, UM, UM2, Coef_conv, Taxa_UE, Taxa_AELS, Taxa_GB, Taxa_alte_tari, Comision_vamal, Randament
		, Cod_NC8, UM_suplimentara
	into #codvamaXlsDifTmp
	from #codvamaXlsTmp 
	except
	select Cod, Denumire, Tip_cod, UM, UM2, Coef_conv, Taxa_UE, Taxa_AELS, Taxa_GB, Taxa_alte_tari, Comision_vamal, Randament
		, Cod_NC8, UM_suplimentara
	from yso_vIaCodvama
	
--select * from #codvamaXlsTmp select * from #codvamaXlsDifTmp 
--select * from yso_vIaPreturiNomenclator where cod like '1-2004Z'

	alter table #codvamaXlsDifTmp add nrcrt int identity(1,1) not null
	create unique clustered index id on #codvamaXlsDifTmp (nrcrt)
	--create nonclustered index preturi on #preturiXlsDifTmp (cod, catpret, tippret, data_inferioara, pret_vanzare, pret_cu_amanuntul)

	declare @randuri int
	select @randuri=MAX(nrcrt) from #codvamaXlsDifTmp

	if OBJECT_ID('tempdb..#mesajeASiSTmp') is not null
		drop table #mesajeASiSTmp
		
	select top 0 Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj 
	into #mesajeASiSTmp from mesajeASiS
	
	if OBJECT_ID('tempdb..#codvamaXlsErrTmp') is not null
	drop table #codvamaXlsErrTmp	
	
	select top 0 _linieimport, convert(varchar(500),'') as _eroareimport into #codvamaXlsErrTmp from #codvamaXlsTmp t 

	set @contor=1
	while @contor<=@randuri
	begin
		begin try
			update codvama
			set Denumire=t.Denumire, UM=t.UM, UM2=t.UM2, Coef_conv=t.Coef_conv, Taxa_UE=t.Taxa_UE, Taxa_AELS=t.Taxa_AELS, Taxa_GB=t.Taxa_GB
				, Taxa_alte_tari=t.Taxa_alte_tari, Comision_vamal=t.Comision_vamal, Randament=t.Randament, Alfa1=t.Cod_NC8, Alfa2=t.UM_suplimentara
				, Val1=t.tip_cod
			from codvama v inner join #codvamaXlsDifTmp t on v.Cod=t.cod
			where t.nrcrt=@contor
			if (@@ROWCOUNT=0)
				insert codvama
				(Cod, Denumire, UM, UM2, Coef_conv, Taxa_UE, Taxa_AELS, Taxa_GB, Taxa_alte_tari, Comision_vamal, Randament, Alfa1, Alfa2, Val1, Val2)
				select
				Cod, Denumire, UM, UM2, Coef_conv, Taxa_UE, Taxa_AELS, Taxa_GB, Taxa_alte_tari, Comision_vamal, Randament, Cod_NC8, UM_suplimentara, tip_cod,0
				from #codvamaXlsDifTmp t
				where t.nrcrt=@contor
 		end try
 		begin catch
			set @eroareProc = ERROR_MESSAGE()
			begin try
				insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
				select '','','S',HOST_ID(),'Erori import codvama',@eroareProc
				
				insert #codvamaXlsErrTmp
				select _linieimport, @eroareProc as _eroareimport from #codvamaXlsTmp t inner join #codvamaXlsDifTmp d
					on d.Cod=t.Cod and d.Denumire=t.Denumire and d.Tip_cod=t.Tip_cod and d.UM=t.UM 
						and d.UM2=t.UM2 and d.Coef_conv=t.Coef_conv and d.Taxa_UE=t.Taxa_UE and d.Taxa_AELS=t.Taxa_AELS 
						and d.Taxa_GB=t.Taxa_GB and d.Taxa_alte_tari=t.Taxa_alte_tari and d.Comision_vamal=t.Comision_vamal 
						and d.Randament=t.Randament and d.Cod_NC8=t.Cod_NC8 and d.UM_suplimentara=t.UM_suplimentara
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
		set @txtSelect='Select * from [codvama$]'
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
		set @txtSql=@txtSql+' inner join #codvamaXlsErrTmp e on e._linieimport=x._linieimport'
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
	
	if OBJECT_ID('tempdb..#codvamaXlsTmp') is not null
		drop table #codvamaXlsTmp
	
	
	if OBJECT_ID('tempdb..#codvamaXlsDifTmp') is not null
		drop table #codvamaXlsDifTmp
		
	if OBJECT_ID('tempdb..#mesajeASiSTmp') is not null
		drop table #mesajeASiSTmp -- select * from #mesajeASiSTmp
		
	if OBJECT_ID('tempdb..#codvamaXlsErrTmp') is not null
		drop table #codvamaXlsErrTmp -- select * into testerrxls from #codvamaXlsErrTmp
end try
begin catch
	declare @mesaj varchar(254)
	set @mesaj = 'yso_xScriuCodvama: '+ ERROR_MESSAGE() 
	raiserror(@mesaj, 11, 1)	
end catch
GO

