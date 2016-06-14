EXEC sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1
GO 
EXEC sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1
GO

if exists (select 1 from sys.servers s where s.name like 'ExcelServer')
EXEC sp_dropserver
    @server = N'ExcelServer',
    @droplogins='droplogins'
    
declare @fisier nvarchar(4000), @dataSource nvarchar(4000)
set @fisier='\\10.0.0.10\import\testimport.xlsx'

EXEC sp_addlinkedserver
    @server = 'ExcelServer',
    @srvproduct = 'Excel', 
    @provider = 'Microsoft.ACE.OLEDB.12.0',
    @datasrc = @fisier,
    @provstr = 'Excel 12.0 Xml;IMEX=1;HDR=YES;'
    
    select codArticol, denArticol, cod_categ, denumire_categ, tip, denumire_tip, datai, pret_vanzare, pret_amanunt, utilizator 
    from excelserver...preturi$
    except
    select * from yso_vIaPreturi
    
    select cod, denumire, tip, dentip, grupa, degrupa, um, denum, furnizor, denfurnizor, observatii, pret, pret_stocn, pretvanzare, pretvanznom, cont, dencont, cotatva, poza, codbare 
    from excelserver...nomencl$
    except
    select * from yso_vIaNomencl
    
    SELECT * FROM OPENQUERY(ExcelServer, 'SELECT * FROM [preturi$]') 
    SELECT * FROM OPENQUERY(ExcelServer, 'SELECT * FROM [nomencl$]') 
    


SELECT *
--codArticol, denArticol, cod_categ, denumire_categ, tip, denumire_tip, datai, pret_vanzare, pret_amanunt, utilizator 
from opendatasource(  'Microsoft.ACE.OLEDB.12.0', 
'Data Source=\\10.0.0.10\import\testimport.xlsx;Extended Properties=Excel 12.0 xml')...[preturi$]
--where f11 is not null or f12 is not null
except 
select* from yso_vIaPreturi
	except 
	select * from yso_vIaNomencl
	
where cod='codnou'
go

	select IDENTITY(int,1,1) nrcrt,
		rtrim(n.cod) as cod,n.tip, dbo.denTipNomenclator(n.tip) as dentip,rtrim(n.grupa) as grupa,rtrim(n.denumire) as denumire,rtrim(n.um) as um,
		isnull(rtrim(terti.Denumire),'') as furnizor, rtrim(n.Tip_echipament) as observatii,
		convert(decimal(12,3),isnull(isnull(pretCat.Pret_cu_amanuntul, isnull(PretImplicit.Pret_cu_amanuntul, n.pret_cu_amanuntul)), 0)) as pret,
		convert(decimal(12,3),isnull(isnull(pretCat.Pret_vanzare, isnull(PretImplicit.Pret_vanzare, n.Pret_vanzare)), 0)) as pretvanzare,
		convert(decimal(12,3),n.Pret_vanzare) as pretvanznom,
		isnull(RTRIM(um.Denumire),'') as denum, rtrim(isnull(grupe.Denumire,n.grupa)) as dengrupa,
		rtrim(n.cont) as cont, convert(decimal(12,3),n.cota_tva) as cotatva, 
		rtrim(n.cont)+'-'+RTRIM(ISNULL(conturi.denumire_cont,'')) as dencont,
		convert(decimal(12,3),n.pret_stoc) as pret_stocn,
		pozeria.fisier as poza, --rog lasati fara isnull
		(select top 1 rtrim(Cod_de_bare) from codbare where Cod_produs=n.cod) as codbare		
		into #test1
	from OPENQUERY(ExcelServer, 'SELECT * FROM [Sheet5$]') n 
		left outer join grupe on n.grupa=grupe.grupa
		left outer join conturi on conturi.Subunitate = '1' and conturi.Cont = n.cont
		left outer join terti on terti.Subunitate = '1' and terti.tert = n.furnizor
		left outer join um on n.um=um.UM
		left join preturi pretCat on pretCat.Cod_produs=n.Cod and pretCat.um=4 and pretCat.Tip_pret=1 and pretCat.Data_superioara='2999-01-01' 
		left join preturi PretImplicit on PretImplicit.Cod_produs=n.Cod and PretImplicit.um=1 and PretImplicit.Tip_pret=1 and PretImplicit.Data_superioara='2999-01-01' 
		left outer join PozeRIA on pozeria.tip='N' and pozeria.cod=n.cod
	--for xml raw
	
	    SELECT * --
	    into #test1
    from opendatasource('Microsoft.ACE.OLEDB.12.0',
'Data Source=d:\BAZA_DATE_ASIS\EXCEL\IMPORT\istoricstocuri.xlsx;Extended Properties=Excel 12.0')...[nomencl$Query_from_TET]
	except 
	select * from yso_vIaNomencl
	
	alter table #test1 add nrcrt int identity(1,1) not null

	declare @parxml xml 
	set @parxml=(select *,(select 1 from nomencl where nomencl.Cod=t.cod) as [update] from #test1 t where nrcrt=1 for xml raw)
 	exec  wScriuNomenclator @sesiune=null,@parxml=@parxml
	set @parxml=(select *,(select 1 from nomencl where nomencl.Cod=t.cod) as [update] from #test1 t where nrcrt=2 for xml raw)
 	exec  wScriuNomenclator @sesiune=null,@parxml=@parxml
	set @parxml=(select *,(select 1 from nomencl where nomencl.Cod=t.cod) as [update] from #test1 t where nrcrt=3 for xml raw)
 	exec  wScriuNomenclator @sesiune=null,@parxml=@parxml
	
	DECLARE test CURSOR FOR
	select * from #test1
	OPEN TEST
	FETCH NEXT FROM TEST
	CLOSE TEST
	DEALLOCATE TEST
	drop table #test1
	
	go
	
	
	UPDATE OPENROWSET('Microsoft.ACE.OLEDB.12.0'
	,'Excel 12.0;Database=\\10.0.0.10\import\testimport.xlsx;Extended Properties="Excel 12.0 Xml;IMEX=1;HDR=YES;";'
	, 'Select * from [erori$]')


UPDATE OPENROWSET('Microsoft.ACE.OLEDB.12.0'
	,'Excel 12.0;Database=\\10.0.0.10\import\testimport.xlsx;Extended Properties="Excel 12.0 Xml;IMEX=0;HDR=YES;";'
	, 'Select * from [preturi$]')
   SET [pret_cu_amanuntul] = 0
 WHERE cod='01263006'
GO

select * FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0'
	,'Excel 12.0;Database=\\10.0.0.10\import\testimport1.xlsx;Extended Properties="Excel 12.0 Xml;IMEX=1;HDR=YES;";'
	, 'Select * from [preturi$]')

select * into ##preturiXlsIniTmp
	from OPENROWSET('Microsoft.ACE.OLEDB.12.0'
	,'Excel 12.0;Database=\\10.0.0.10\import\testimport1.xlsx;Extended Properties="Excel 12.0 Xml;IMEX=1;HDR=YES;";'
	, 'Select * from [preturi$]') x 
SELECT ROW_NUMBER() over(order by cod, catpret, dencategpret, tippret, dentippret, data_inferioara, data_superioara, pret_vanzare, pret_cu_amanuntul, eroare_import) as nrcrt
		,[cod]
      ,[catpret]
      ,[dencategpret]
      ,[tippret]
      ,[dentippret]
      ,[pret_vanzare]
      ,[pret_cu_amanuntul]
      ,[data_inferioara]
      ,[data_superioara]
      ,[eroare_import]
  FROM [xPreturi]...[preturi$]
GO


select * from OPENROWSET('Microsoft.ACE.OLEDB.12.0'
	,'Excel 12.0;Database=d:\BAZA_DATE_ASIS\EXCEL\IMPORT\ASIS_preturi_1 mai 2012_DB.xlsx;
	Extended Properties="Excel 12.0 Xml;IMEX=1;HDR=YES;";'
	, 'Select * from [preturi$]')
 WHERE cod='01263006'

UPDATE (select * from OPENROWSET('Microsoft.ACE.OLEDB.12.0'
	,'Excel 12.0;Database=\\10.0.0.10\import\testimport.xlsx;Extended Properties="Excel 12.0 Xml;IMEX=0;HDR=YES;";'
	, 'Select * from [preturi$]')
 WHERE cod='01263006')
    SET [pret_cu_amanuntul] = 0
    
    UPDATE x 
    SET [pret_cu_amanuntul] = 1
    from OPENROWSET('Microsoft.ACE.OLEDB.12.0'
	,'Excel 12.0;Database=\\10.0.0.10\import\testimport.xlsx;Extended Properties="Excel 12.0 Xml;IMEX=0;HDR=YES;";'
	, 'Select * from [preturi$]') x inner join yso_vIaPreturiNomenclator t 
	on x.cod=t.cod and x.catpret=t.catpret and x.dencategpret=t.dencategpret and x.tippret=t.tippret and x.dentippret=t.dentippret 
		and x.data_inferioara=t.data_inferioara and x.pret_vanzare=t.pret_vanzare 
		and x.pret_cu_amanuntul=t.pret_cu_amanuntul
	WHERE x.cod='01263006'
 
 select * from yso_vIaPreturiNomenclator t where t.cod='01263006'
 select * 
 from OPENROWSET('Microsoft.ACE.OLEDB.12.0'
	,'Excel 12.0;Database=\\10.0.0.10\import\testimport.xlsx;Extended Properties="Excel 12.0 Xml;IMEX=0;HDR=YES;";'
	, 'Select * from [preturi$]') x where catpret>5 or tippret>5
	isnull(x.eroare_import,'')<>''
 
UPDATE x 
SET [eroare_import] = ''
from OPENROWSET('Microsoft.ACE.OLEDB.12.0'
,'Excel 12.0;Database=\\10.0.0.10\import\testimport.xlsx;Extended Properties="Excel 12.0 Xml;IMEX=0;HDR=YES;";'
, 'Select * from [preturi$]') x inner join yso_vIaPreturiNomenclator t 
on isnull(x.cod,'')=isnull(t.cod,'') and isnull(x.catpret,'')=isnull(t.catpret,'') 
	and isnull(x.tippret,'')=isnull(t.tippret,'') and isnull(x.data_inferioara,'')=isnull(t.data_inferioara,'') 
	and isnull(x.data_superioara,'')=isnull(t.data_superioara,'') and isnull(x.pret_vanzare,'')=isnull(t.pret_vanzare,'') 
	and isnull(x.pret_cu_amanuntul,'')=isnull(t.pret_cu_amanuntul,'')





