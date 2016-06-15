CREATE PROCEDURE yso_xScriuPreturiNomenclator @fisier nvarchar(4000) as 
--set @fisier='\\10.0.0.10\import\ASIS_preturi_1 mai 2012_DB.xlsx'

if exists (select 1 from sys.servers s where s.name like 'xPreturi')
EXEC sp_dropserver
	@server = N'xPreturi',
	@droplogins='droplogins'

EXEC sp_addlinkedserver
	@server = 'xPreturi',
	@srvproduct = 'Excel', 
	@provider = 'Microsoft.ACE.OLEDB.12.0',
	@datasrc = @fisier,
	@provstr = 'Excel 12.0 xml;IMEX=1;HDR=YES;'

if OBJECT_ID('tempdb..#preturiXlsTmp') is not null
	drop table #preturiXlsTmp

--set dateformat mdy
select CONVERT(varchar(20),cod) as cod
, convert(varchar(6),catpret) as catpret
, convert(varchar(20),tippret) as tippret
, convert(char(10),CONVERT(DATE,data_inferioara),101) as data_inferioara
, convert(decimal(12,3),pret_vanzare) as pret_vanzare
, convert(decimal(12,3),pret_cu_amanuntul) as pret_cu_amanuntul
into #preturiXlsTmp
from xPreturi...preturi$
--where cod like '01263006'
--select * from #preturiXlsTmp

if OBJECT_ID('tempdb..#preturiXlsDifTmp') is not null
	drop table #preturiXlsDifTmp

select cod, catpret, tippret, data_inferioara, pret_vanzare, pret_cu_amanuntul
into #preturiXlsDifTmp
from #preturiXlsTmp 
except
select cod, catpret, tippret, data_inferioara, pret_vanzare, pret_cu_amanuntul
from yso_vIaPreturiNomenclator

alter table #preturiXlsDifTmp add nrcrt int identity(1,1) not null
create unique clustered index id on #preturiXlsDifTmp (nrcrt)
create nonclustered index pret on #preturiXlsDifTmp (cod,catpret,tippret,data_inferioara)

declare @randuri int, @contor int, @parxml xml 
select @randuri=MAX(nrcrt) from #preturiXlsDifTmp

set @contor=1
while @contor<=@randuri
begin
	set @parxml=(select t.cod as o_cod,t.cod, rtrim(catpret) as catpret
		, rtrim(tippret) as tippret, data_inferioara
		, convert(decimal(12,3),t.pret_vanzare) as pret_vanzare, convert(decimal(12,3),t.pret_cu_amanuntul) as pret_cu_amanuntul
		,isnull((select TOP 1 1 from yso_vIaPreturiNomenclator v 
			where v.cod=t.cod and v.catpret=t.catpret and v.tippret=t.tippret /*and v.datai=t.datai*/),0) as [update] 
		from #preturiXlsDifTmp t inner join nomencl n on n.Cod=t.cod
			inner join categpret c on c.Categorie=t.catpret
		where t.nrcrt=@contor for xml raw, root('row'))
	if @parxml is not null
 		exec yso_wScriuPreturiNomenclator @sesiune=null,@parxml=@parxml
 	--select @parxml
 	set @contor=@contor+1
end
