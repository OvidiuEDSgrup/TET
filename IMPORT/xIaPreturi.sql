/****** Object:  StoredProcedure [dbo].[wIaPreturi]    Script Date: 04/24/2012 14:40:36 ******/
drop view [yso_vIaPreturi]
go
create view [yso_vIaPreturi] WITH SCHEMABINDING as
select 
	p.cod_produs as codArticol
	, rtrim(n.denumire) as denArticol
	, p.um as cod_categ	
	, RTRIM(c.denumire) as denumire_categ
	, tip_pret as tip
	, CASE Tip_pret WHEN '1' THEN 'Pret standard' WHEN '2' THEN 'Pret promo' WHEN '9' THEN 'Pret impus' ELSE '' END AS denumire_tip
	, convert(char(10),p.data_inferioara,101) as datai
	--, convert(char(10),p.data_superioara,101) as datas
	, convert(decimal(12,3),p.pret_vanzare) as pret_vanzare
	, convert(decimal(12,3),p.pret_cu_amanuntul) as pret_amanunt
	, RTRIM(utilizator) as utilizator
from dbo.preturi p inner join dbo.categpret c on p.um=c.categorie
inner join dbo.nomencl n on n.Cod=p.Cod_produs 
go
create unique clustered index unic on yso_vIaPreturi 
(codArticol, cod_categ, tip, datai)
go

drop view [yso_vIaPreturiNomenclator]
go
create view [yso_vIaPreturiNomenclator] as
select rtrim(cod_produs) as cod,
--rtrim(n.denumire) as dencod,
cp.categorie as catpret,
rtrim(cp.Denumire) as dencategpret,
rtrim(p.tip_pret) as tippret,
CASE Tip_pret WHEN '1' THEN 'Pret standard' WHEN '2' THEN 'Pret promo' WHEN '9' THEN 'Pret impus' ELSE '' END as dentippret,
convert(datetime,convert(date,data_inferioara)) as data_inferioara,
convert(datetime,convert(date,data_superioara)) as data_superioara,
convert(decimal(12,3),p.Pret_vanzare) as pret_vanzare,
convert(decimal(12,3),p.Pret_cu_amanuntul) as pret_cu_amanuntul,
CONVERT(nvarchar(500),'') as _eroareimport
from dbo.preturi p
left join dbo.categpret cp on p.UM=cp.Categorie
left join dbo.nomencl n on n.Cod=p.Cod_produs 
--where p.Cod_produs like '143808CUIAC2X20Ÿ'
go
--create unique clustered index unic on yso_vIaPreturiNomenclator 
--(cod, catpret, tippret, data_inferioara) 
--go
--create unique nonclustered index modificabile on yso_vIaPreturiNomenclator 
--(cod, catpret, tippret, data_inferioara) INCLUDE ([data_superioara], [pret_vanzare], [pret_cu_amanuntul])
--go
drop procedure [dbo].[yso_xIaPreturi]
GO
CREATE procedure [dbo].[yso_xIaPreturi] --@sesiune varchar(50), @parXML XML  
as
	--declare @f_cod_categ varchar(10), @f_tip_pret varchar(10), @f_articol varchar(20), @dataSus datetime, @dataJos datetime,
	--		@f_den_categ varchar(100), @f_den_articol varchar(100)
	
	--set @f_articol= '%'+REPLACE(ISNULL(@parXML.value('(/row/@f_articol)[1]','varchar(20)'),''),' ','%')+'%'
	--set @f_cod_categ= '%'+REPLACE(ISNULL(@parXML.value('(/row/@f_cod_categ)[1]','varchar(10)'),''),' ','%')+'%'
	--set @f_tip_pret= '%'+REPLACE(ISNULL(@parXML.value('(/row/@f_tip_pret)[1]','varchar(10)'),''),' ','%')+'%'
	--set @f_den_articol= '%'+REPLACE(ISNULL(@parXML.value('(/row/@f_den_articol)[1]','varchar(100)'),''),' ','%')+'%'
	--set @f_den_categ= '%'+REPLACE(ISNULL(@parXML.value('(/row/@f_den_categ)[1]','varchar(100)'),''),' ','%')+'%'
	--set @dataJos=@parXML.value('(/row/@datajos)[1]','datetime')
	--set @dataSus=@parXML.value('(/row/@datasus)[1]','datetime')
	
select --top 100
	 *
from yso_vIaPreturi
--where p.tip_pret like @f_tip_pret and p.um like @f_cod_categ and p.cod_produs like @f_articol and 
--	 p.data_inferioara between @dataJos and @dataSus and n.denumire like @f_den_articol and c.Denumire like @f_den_categ
--for xml raw,root('Date')
GO
drop procedure [dbo].[yso_xIaPreturiNomenclator]
GO
CREATE procedure [dbo].[yso_xIaPreturiNomenclator] --@sesiune varchar(50), @parXML XML  
as
	--declare @f_cod_categ varchar(10), @f_tip_pret varchar(10), @f_articol varchar(20), @dataSus datetime, @dataJos datetime,
	--		@f_den_categ varchar(100), @f_den_articol varchar(100)
	
	--set @f_articol= '%'+REPLACE(ISNULL(@parXML.value('(/row/@f_articol)[1]','varchar(20)'),''),' ','%')+'%'
	--set @f_cod_categ= '%'+REPLACE(ISNULL(@parXML.value('(/row/@f_cod_categ)[1]','varchar(10)'),''),' ','%')+'%'
	--set @f_tip_pret= '%'+REPLACE(ISNULL(@parXML.value('(/row/@f_tip_pret)[1]','varchar(10)'),''),' ','%')+'%'
	--set @f_den_articol= '%'+REPLACE(ISNULL(@parXML.value('(/row/@f_den_articol)[1]','varchar(100)'),''),' ','%')+'%'
	--set @f_den_categ= '%'+REPLACE(ISNULL(@parXML.value('(/row/@f_den_categ)[1]','varchar(100)'),''),' ','%')+'%'
	--set @dataJos=@parXML.value('(/row/@datajos)[1]','datetime')
	--set @dataSus=@parXML.value('(/row/@datasus)[1]','datetime')
	
select --top 100
	 *
from yso_vIaPreturiNomenclator
--where p.tip_pret like @f_tip_pret and p.um like @f_cod_categ and p.cod_produs like @f_articol and 
--	 p.data_inferioara between @dataJos and @dataSus and n.denumire like @f_den_articol and c.Denumire like @f_den_categ
--for xml raw,root('Date')
GO
