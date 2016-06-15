create procedure yso_xScriuNomencl  @fisier nvarchar(4000) as
begin try -- scriu nomenclator
	--declare @fisier nvarchar(4000) set @fisier='\\10.0.0.10\import\80_Import Preturi_2013\2015\80_ASIS_preturi pt import 23 ian 2015_DC.xls'
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
	
	if OBJECT_ID('tempdb..##nomenclXlsIniTmp') is not null
		drop table tempdb..##nomenclXlsIniTmp

	set @sursa='Excel 12.0;Database=@fisier;Extended Properties="Excel 12.0 Xml;IMEX=1;HDR=YES;";'
	set @sursa=REPLACE(@sursa,'@fisier',@fisier)
	set @txtSelect='Select * from [nomencl$]'
	set @txtSql=
	'select * into ##nomenclXlsIniTmp
	from OPENROWSET(''Microsoft.ACE.OLEDB.12.0''
	,@sursa
	, @txtSelect) x '
	set @txtSql=REPLACE(@txtSql,'@sursa',''''+@sursa+'''')
	set @txtSql=REPLACE(@txtSql,'@txtSelect',''''+@txtSelect+'''')
	exec sp_executesql @txtSql
		
	if OBJECT_ID('tempdb..#nomenclXlsTmp') is not null
		drop table #nomenclXlsTmp

	--set dateformat mdy
	select isnull(cod,'') as cod, isnull(note,'') as note, isnull(denumire,'') as denumire, isnull(tip,'') as tip, isnull(dentip,'') as dentip
	, isnull(grupa,'') as grupa, isnull(dengrupa,'') as dengrupa, isnull(um,'') as um, isnull(denum,'') as denum, isnull(furnizor,'') as furnizor
	, isnull(denfurnizor,'') as denfurnizor, isnull(codvamal,'') as codvamal, isnull(dencodvamal,'') as dencodvamal
	, isnull(pret,'') as pret, isnull(pret_stocn,'') as pret_stocn, isnull(pretvanzare,'') as pretvanzare, isnull(pretvanznom,'') as pretvanznom
	, isnull(cont,'') as cont, isnull(dencont,'') as dencont, isnull(cotatva,'') as cotatva, isnull(poza,'') as poza, isnull(codbare,'') as codbare
	, ISNULL(greutate,'') as greutate
	,_linieimport
	into #nomenclXlsTmp
	from ##nomenclXlsIniTmp where _linieimport is not null
	--where cod like '01263006'

	if OBJECT_ID('tempdb..#nomenclXlsDifTmp') is not null
		drop table #nomenclXlsDifTmp

	select distinct cod, note, denumire, tip, grupa, um, furnizor, codvamal, pret, pret_stocn, pretvanznom, cont, cotatva, greutate
	into #nomenclXlsDifTmp
	from #nomenclXlsTmp 
	except
	select			cod, note, denumire, tip, grupa, um, furnizor, codvamal, pret, pret_stocn, pretvanznom, cont, cotatva, greutate
	from yso_vIaNomencl

/*	
select * from #nomenclXlsTmp 

select  distinct top 1 cod, denumire, grupa, um, furnizor, codvamal, pret, pret_stocn, pretvanznom, cont, cotatva from #nomenclXlsDifTmp 



select cod, denumire, grupa, um, furnizor, codvamal, pret, pret_stocn, pretvanznom, cont, cotatva from yso_vIaNomencl 
where cod like '0024252'


select  d.pretvanznom-t.pretvanznom ,t.*,d.* from #nomenclXlsDifTmp d
inner join yso_vIaNomencl t on t.cod=d.cod and t.cod like '0024252'
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
	alter table #nomenclXlsDifTmp add nrcrt int identity(1,1) not null
	create unique clustered index id on #nomenclXlsDifTmp (nrcrt)
	--create nonclustered index preturi on #preturiXlsDifTmp (cod, catpret, tippret, data_inferioara, pret_vanzare, pret_cu_amanuntul)

	declare @randuri int
	select @randuri=MAX(nrcrt) from #nomenclXlsDifTmp

	if OBJECT_ID('tempdb..#mesajeASiSTmp') is not null
		drop table #mesajeASiSTmp
		
	select top 0 Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj 
	into #mesajeASiSTmp from mesajeASiS
	
	if OBJECT_ID('tempdb..#nomenclXlsErrTmp') is not null
		drop table #nomenclXlsErrTmp
		
	select top 0 _linieimport, convert(varchar(500),'') as _eroareimport into #nomenclXlsErrTmp from #nomenclXlsTmp t 

-- select * from #nomenclXlsErrTmp
	set @contor=1
	while @contor<=@randuri
	begin
		begin try
			set @parxml=(select cod
				,RTRIM(note) as loc_de_munca
				, denumire, tip, grupa, um, furnizor
				, codvamal as observatii
				, convert(decimal(17,5),pret) pret
				, convert(decimal(17,5),pret_stocn) pret_stocn
				, convert(decimal(17,5),pretvanznom) pretvanznom
				, cont
				, convert(decimal(5,0),cotatva) as cotatva
				, CONVERT(decimal(15,3),greutate) as greutate 
				,isnull((select TOP 1 1 from nomencl v 
					where v.cod=t.cod),0) as [update] 
				from #nomenclXlsDifTmp t 
				where t.nrcrt=@contor for xml raw)
			--if '0007001A'=@parXML.value('(/row/@cod)[1]','varchar(20)')
			--	print 'stop'
			if @parxml is not null
 				exec wScriuNomenclator @sesiune=null,@parxml=@parxml
 		end try
 		begin catch
			set @eroareProc = ERROR_MESSAGE()
			begin try
				insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
				select '','','S',HOST_ID(),'Erori import linie nomencl',@eroareProc
				
				insert #nomenclXlsErrTmp
				select _linieimport, @eroareProc as _eroareimport from #nomenclXlsTmp t inner join #nomenclXlsDifTmp d
					on d.cod=t.cod and d.note=t.note and d.denumire=t.denumire and d.grupa=t.grupa and d.um=t.um and d.furnizor=t.furnizor 
						and d.codvamal=t.codvamal and d.pret=t.pret and d.pret_stocn=t.pret_stocn and d.pretvanznom=t.pretvanznom 
						and d.cont=t.cont and d.cotatva=t.cotatva
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
		set @txtSelect='Select * from [nomencl$]'
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
		set @txtSql=@txtSql+' inner join #nomenclXlsErrTmp e on e._linieimport=x._linieimport'
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
	
	if OBJECT_ID('tempdb..##nomenclXlsIniTmp') is not null
		drop table ##nomenclXlsIniTmp	

	if OBJECT_ID('tempdb..#nomenclXlsTmp') is not null
		drop table #nomenclXlsTmp
	
	
	if OBJECT_ID('tempdb..#nomenclXlsDifTmp') is not null
		drop table #nomenclXlsDifTmp
		
	if OBJECT_ID('tempdb..#mesajeASiSTmp') is not null
		drop table #mesajeASiSTmp -- select * from #mesajeASiSTmp
		
	if OBJECT_ID('tempdb..#nomenclXlsErrTmp') is not null
		drop table #nomenclXlsErrTmp -- select * into testerrxls from #nomenclXlsErrTmp
	
end try
begin catch
	declare @mesaj varchar(254)
	set @mesaj = 'yso_xScriuNomencl: '+ ERROR_MESSAGE() 
	raiserror(@mesaj, 11, 1)	
end catch
