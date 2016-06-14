drop view yso_vIaTehnpoz 
go
create view yso_vIaTehnpoz as 
select tp.Cod_tehn, rtrim(t.Denumire) as Den_tehn
	, tp.Tip, CASE tp.Tip WHEN 'M' THEN 'Material' WHEN 'R' THEN 'Rezultat' ELSE 'Altele' END as Den_tip
	, tp.Cod, RTRIM(n.Denumire) as Den_cod
	, tp.Nr
	, rtrim(tp.Subtip) as Tip_resursa, CASE tp.Tip WHEN 'M' THEN 'Material' WHEN 'P' THEN 'Produs' ELSE 'Altele' END as Den_tip_resursa
	, tp.Specific as Consum_specific
from tehnpoz tp 
	inner join tehn t on t.Cod_tehn=tp.Cod_tehn
	inner join nomencl n on n.Cod=tp.Cod
go
drop proc yso_xIaTehnpoz 
go
create proc yso_xIaTehnpoz as
select * from yso_vIaTehnpoz
go

--begin try
	declare @fisier nvarchar(4000) 
	set @fisier='\\10.0.0.10\import\80_ASIS_componenta_pachete_11 mai 2012_DC.xls'
	if exists (select 1 from sys.servers s where s.name like 'xTehnpoz')
	EXEC sp_dropserver
		@server = N'xTehnpoz',
		@droplogins='droplogins'

	EXEC sp_addlinkedserver  
		@server = 'xTehnpoz',
		@srvproduct = 'Excel', 
		@provider = 'Microsoft.ACE.OLEDB.12.0',
		@datasrc = @fisier,
		@provstr = 'Excel 12.0 Xml;IMEX=1;HDR=YES;'

	if OBJECT_ID('tempdb..#tehnpozXlsTmp') is not null
		drop table #tehnpozXlsTmp

	--set dateformat mdy
	select isnull(Cod_tehn,'') as Cod_tehn, isnull(Den_tehn,'') as Den_tehn, isnull(Tip,'') as Tip, isnull(Den_tip,'') as Den_tip, isnull(Cod,'') as Cod, isnull(Den_cod,'') as Den_cod, isnull(Nr,'') as Nr, isnull(Tip_resursa,'') as Tip_resursa, isnull(Den_tip_resursa,'') as Den_tip_resursa, isnull(Consum_specific,'') as Consum_specific
	,_linieimport
	into #tehnpozXlsTmp
	from xTehnpoz...tehnpoz$
	--where cod like '01263006'

	if OBJECT_ID('tempdb..#tehnpozXlsDifTmp') is not null
		drop table #tehnpozXlsDifTmp

	select distinct Cod_tehn, Tip, Cod, Nr, Tip_resursa, Consum_specific
	into #tehnpozXlsDifTmp
	from #tehnpozXlsTmp 
	except
	select			Cod_tehn, Tip, Cod, Nr, Tip_resursa, Consum_specific
	from yso_vIaTehnpoz

/*	
select * from #tehnXlsTmp 

select  distinct top 1 Cod_tehn, Tip, Cod, Nr, Tip_resursa, Consum_specific 
from #tehnpozXlsDifTmp 



select Cod_tehn, Tip, Cod, Nr, Tip_resursa, Consum_specific 
from yso_vIatehnpoz
where cod_tehn like 'MALK50_12S241' and cod like '00202634'


select  d.pretvanznom-t.pretvanznom ,t.*,d.* from #tehnXlsDifTmp d
inner join yso_vIatehn t on t.cod=d.cod and t.cod like '0024252'
where 
d.denumire<>t.denumire 
--or d.grupa<>t.grupa 
--or d.um<>t.um 
--or d.furnizor<>t.furnizor 
--or d.codvamal<>t.codvamal 
--or d.pret<>t.pret 
--or d.pret_stocn<>t.pret_stocn 
--or d.pretvanznom<>t.pretvanznom 
--or d.cont<>t.cont 
--or d.cotatva<>t.cotatva

*/
	alter table #tehnpozXlsDifTmp add nrcrt int identity(1,1) not null
	create unique clustered index id on #tehnpozXlsDifTmp (nrcrt)
	--create nonclustered index preturi on #preturiXlsDifTmp (cod, catpret, tippret, data_inferioara, pret_vanzare, pret_cu_amanuntul)

	declare @randuri int
	select @randuri=MAX(nrcrt) from #tehnpozXlsDifTmp

	if OBJECT_ID('tempdb..#mesajeASiSTmp') is not null
		drop table #mesajeASiSTmp
		
	select top 0 Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj 
	into #mesajeASiSTmp from mesajeASiS
	
	if OBJECT_ID('tempdb..#tehnpozXlsErrTmp') is not null
		drop table #tehnpozXlsErrTmp
		
	select top 0 _linieimport, convert(varchar(500),'') as _eroareimport into #tehnpozXlsErrTmp from #tehnpozXlsTmp t 
	
 	declare @eroareProc varchar(500),@txtSql nvarchar(max),@sursa varchar(max),@txtSelect varchar(max)
 		,@txtParam nvarchar(max),@eroareXL varchar(500), @contor int, @parxml xml 

-- select * from #tehnXlsErrTmp
	set @contor=1
	while @contor<=@randuri
	begin
		begin try
			update v
			set subtip=t.Tip_resursa, Specific=t.Consum_specific
			from tehnpoz v inner join #tehnpozXlsDifTmp t on v.Cod_tehn=t.Cod_tehn and v.Tip=t.Tip and v.Cod=t.Cod and v.Nr=t.Nr and v.Loc_munca=''
			where t.nrcrt=@contor
			if (@@ROWCOUNT=0)
				insert tehnpoz
				(Cod_tehn, Tip, Cod, Cod_operatie, Nr, Subtip, Supr, Coef_consum, Randament, Specific, Cod_inlocuit, Loc_munca, Obs, Utilaj, Timp_preg, Timp_util, Categ_salar, Norma_timp, Tarif_unitar, Lungime, Latime, Inaltime, Comanda, Alfa1, Alfa2, Alfa3, Alfa4, Alfa5, Val1, Val2, Val3, Val4, Val5)
				select
				Cod_tehn, Tip, Cod, '', Nr, Tip_resursa, '', '', '', Consum_specific, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''
				from #tehnpozXlsDifTmp t
				where t.nrcrt=@contor
 		end try
 		begin catch
			set @eroareProc = ERROR_MESSAGE()
			insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
			select '','','S',HOST_ID(),'Eroare import linie tehn',@eroareProc
			begin try
				insert #tehnpozXlsErrTmp
				select _linieimport, @eroareProc as _eroareimport from #tehnpozXlsTmp t inner join #tehnpozXlsDifTmp d
					on d.Cod_tehn=t.Cod_tehn and d.Tip=t.Tip and d.Cod=t.Cod  
						and d.Nr=t.Nr and d.Tip_resursa=t.Tip_resursa and d.Consum_specific=t.Consum_specific
				where d.nrcrt=@contor
			end try
			begin catch
				set @eroareXL = ERROR_MESSAGE()
				insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
				select '','','S',HOST_ID(),'Eroare raportare erori in tabel',@eroareXL
			end catch
 		end catch
 		--select @parxml
 		set @contor=@contor+1
	end
	begin try
		set @sursa='Excel 12.0;Database=@fisier;Extended Properties="Excel 12.0 Xml;IMEX=0;HDR=YES;";'
		set @sursa=REPLACE(@sursa,'@fisier',@fisier)
		set @txtSelect='Select * from [tehnpoz$]'
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
		set @txtSql=@txtSql+' inner join #tehnpozXlsErrTmp e on e._linieimport=x._linieimport'
		exec sp_executesql @txtSql
	end try
	begin catch
		set @eroareXL = ERROR_MESSAGE()
		insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
		select '','','S',HOST_ID(),'Eroare raportare erori in excel',@eroareXL
	end catch
	
	delete mesajeASiS where Tip_destinatar='S' and Destinatar=HOST_ID()
	insert mesajeASiS (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj, Data, Ora, Stare)
	select t.*,GETDATE(),'','' from (select distinct * from #mesajeASiSTmp) t
	
--end try
--begin catch
--	declare @mesaj varchar(254)
--	set @mesaj = ERROR_MESSAGE() 
--	--set @mesaj = RTRIM(@mesaj)+': '+isnull(@cod,'')+','+isnull(@catpret,'')+','+isnull(@tippret,'')
--	--	+','+convert(varchar,isnull(@data,''))+','+CONVERT(varchar,isnull(@update,''))
--	raiserror(@mesaj, 11, 1)	
--	--select @mesaj as mesaj into testmesajasis
--end catch
GO

