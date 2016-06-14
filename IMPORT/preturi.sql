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

DROP procedure [dbo].[yso_wScriuPreturiNomenclator] 
GO
CREATE procedure [dbo].[yso_wScriuPreturiNomenclator] @sesiune varchar(50), @parXML xml
as

Declare @update bit, @cod varchar(20),@data datetime,@pret_cu_amanuntul decimal(12,3),@pvanzare decimal(12,3),@catpret varchar(20)
	,@tippret varchar(1),@utilizator varchar(50),@cota_tva decimal(12,2)

Set @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0)
Set @cod = isnull(@parXML.value('(/row/@cod)[1]','varchar(20)'),@parXML.value('(/row/row/@cod)[1]','varchar(20)'))
Set @catpret= @parXML.value('(/row/row/@catpret)[1]','varchar(20)')
Set @tippret = @parXML.value('(/row/row/@tippret)[1]','varchar(1)')
Set @data= @parXML.value('(/row/row/@data_inferioara)[1]','datetime')
Set @pret_cu_amanuntul= isnull(@parXML.value('(/row/row/@pret_cu_amanuntul)[1]','decimal(12,3)'),0)
set @cota_tva=isnull((select top 1 Cota_TVA from nomencl where cod=@cod),24)
set @pvanzare=isnull(@parXML.value('(/row/row/@pret_vanzare)[1]','decimal(12,3)'),round(@pret_cu_amanuntul/(100+@cota_tva)*100,3))

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
if @utilizator is null
	return

--se calculeaza pretul de vanzare prin extragerea tva-ului din pretul cu amanuntul
--declare @pvanzare decimal(12,3)
--set @pvanzare=round(@pret_cu_amanuntul/(100+@cota_tva)*100,3)


begin try
declare @tip varchar(1)

	--if @update=1  --se va sterge linia cu pretul respectiv deoarece se poate schimba data, adica cheia
	--begin  
		declare @o_cod varchar(20),@o_data datetime,@o_categpret varchar(10),@o_tippret varchar(10)
		Set @o_cod= @parXML.value('(/row/row/@o_cod)[1]','varchar(20)')
		Set @o_data= @parXML.value('(/row/row/@o_data_inferioara)[1]','datetime')
		Set @o_categpret= @parXML.value('(/row/row/@o_categorie)[1]','varchar(10)')
		Set @o_tippret= @parXML.value('(/row/row/@o_tippret)[1]','varchar(10)')
		
		delete from preturi where Cod_produs= @o_cod and preturi.UM=@catpret and preturi.Tip_pret=@tippret
	--end  

	--se cauta ultimul pret pana la mine si se pune update cu o zi inainte
	declare @lastdate datetime
	set @lastdate=(select top 1 data_superioara from preturi where
	Cod_produs= @cod and preturi.UM=@catpret and preturi.Tip_pret=@tippret and Data_inferioara<@data
	order by Data_superioara desc)
	print @lastdate
	/*if @lastdate is not null
	begin
		update preturi set Data_superioara=DATEADD(DAY,-1,@data)
		where Cod_produs= @cod and preturi.Data_superioara=@lastdate and preturi.UM=@catpret and preturi.Tip_pret=@tippret
	end*/
	--se cauta daca exista pret dupa data ceruta si se pune data superioara data inferioara a pretului de dupa -1 zi
	set @lastdate=(select top 1 data_inferioara from preturi where
	Cod_produs= @cod and preturi.UM=@catpret and preturi.Tip_pret=@tippret and Data_inferioara>@data
	order by Data_superioara desc)
	declare @datasup datetime
	if @lastdate is not null
		set @datasup=DATEADD(DAY,-1,@lastdate)
	else
		set @datasup='01/01/2999'

	insert into preturi (Cod_produs,UM,Tip_pret,Data_inferioara,Ora_inferioara,Data_superioara,Ora_superioara,Pret_vanzare,Pret_cu_amanuntul,Utilizator,Data_operarii,Ora_operarii)
	values (@cod,@catpret,@tippret,@data,'',@datasup,'',@pvanzare,@pret_cu_amanuntul,@utilizator,GETDATE(),'')
end try

begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE() 
	--set @mesaj = RTRIM(@mesaj)+': '+isnull(@cod,'')+','+isnull(@catpret,'')+','+isnull(@tippret,'')
	--	+','+convert(varchar,isnull(@data,''))+','+CONVERT(varchar,isnull(@update,''))
	raiserror(@mesaj, 11, 1)	
end catch
go
drop PROCEDURE yso_xScriuPreturiNomencl
go
CREATE PROCEDURE yso_xScriuPreturiNomencl @fisier nvarchar(4000) as
begin try
	-- declare @fisier nvarchar(4000) set @fisier='\\10.0.0.10\import\ASIS_preturi_import 2 iulie 2012_DB.xlsx'
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
GO

--***
if exists (select * from sysobjects where name ='yso_wStergPreturiNomenclator')
drop procedure yso_wStergPreturiNomenclator
go
--***
create procedure yso_wStergPreturiNomenclator @sesiune varchar(50), @parXML xml
as
begin try

Declare @cod varchar(20),@data datetime,@pret_cu_amanuntul decimal(12,2),@catpret varchar(10),@tippret varchar(1),@utilizator varchar(50)
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
if @utilizator is null
	return

Set @cod = isnull(@parXML.value('(/row/@cod)[1]','varchar(20)'),@parXML.value('(/row/row/@cod)[1]','varchar(20)'))
Set @catpret= @parXML.value('(/row/row/@catpret)[1]','varchar(20)')
Set @tippret = @parXML.value('(/row/row/@tippret)[1]','varchar(20)')
Set @data= @parXML.value('(/row/row/@data_inferioara)[1]','datetime')
Set @pret_cu_amanuntul= @parXML.value('(/row/row/@pretamanunt)[1]','decimal(12,2)')
print @catpret

--declare @datadinainte datetime,@datadupa datetime
--set @datadinainte=(select top 1 data_inferioara from preturi where Cod_produs= @cod and 
--	preturi.Data_inferioara<@data and preturi.UM=@catpret and preturi.Tip_pret=@tippret)
--set @datadupa=(select top 1 data_inferioara from preturi where Cod_produs= @cod and 
--	preturi.Data_inferioara>@data and preturi.UM=@catpret and preturi.Tip_pret=@tippret)

delete from preturi where Cod_produs= @cod and preturi.UM=@catpret and preturi.Tip_pret=@tippret 
	--and preturi.Data_inferioara=@data

--if @datadinainte is not null 
--	if @datadupa is not null --a fost un pret la mijloc, se modifica data de sus a liniei anterioare
--		update preturi set data_superioara=DATEADD(day,-1,@datadupa)
--		where Cod_produs= @cod and preturi.Data_inferioara=@datadinainte and preturi.UM=@catpret and preturi.Tip_pret=@tippret
--	else  -- linia de dinainte devine cel curent
--		update preturi set data_superioara='01/01/2999'
--		where Cod_produs= @cod and preturi.Data_inferioara=@datadinainte and preturi.UM=@catpret and preturi.Tip_pret=@tippret

	--preturile urmatoare nu sunt afectate de stergerea acesetei linii! inteligenta metoda!

end try

begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
go
drop PROCEDURE yso_xStergPreturiNomencl
go
CREATE PROCEDURE yso_xStergPreturiNomencl @fisier nvarchar(4000) as
begin try
	--declare @fisier nvarchar(4000) set @fisier='\\10.0.0.10\import\ASIS_preturi_import 21 mai 2012_preturi de actualizat_DB.xlsx'
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
		--, data_inferioara, data_superioara
		--, convert(decimal(12,3),pret_vanzare) as pret_vanzare
		--, convert(decimal(12,3),pret_cu_amanuntul) as pret_cu_amanuntul
	into #preturiXlsDifTmp
	from #preturiXlsTmp 
	intersect
	select cod, catpret, tippret
		--, data_inferioara, data_superioara, pret_vanzare, pret_cu_amanuntul
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
				--, convert(char(10),data_inferioara,126) as data_inferioara 
				--, convert(decimal(12,3),t.pret_vanzare) as pret_vanzare
				--, convert(decimal(12,3),t.pret_cu_amanuntul) as pret_cu_amanuntul
				,isnull((select TOP 1 1 from yso_vIaPreturiNomenclator v 
					where v.cod=t.cod and v.catpret=t.catpret and v.tippret=t.tippret /*and v.datai=t.datai*/),0) as [update] 
				from #preturiXlsDifTmp t 
					--inner join nomencl n on n.Cod=t.cod
					--inner join categpret c on c.Categorie=t.catpret
				where t.nrcrt=@contor for xml raw, root('row'))
			if @parxml is not null
 				exec yso_wStergPreturiNomenclator @sesiune=null,@parxml=@parxml
 		end try
		begin catch
			set @eroareProc = ERROR_MESSAGE()
			begin try
				insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
				select '','','S',HOST_ID(),'Erori import linie preturi',@eroareProc
				
				insert #preturiXlsErrTmp
				select _linieimport, @eroareProc as _eroareimport from #preturiXlsTmp t inner join #preturiXlsDifTmp d
					on d.cod=t.cod and d.catpret=t.catpret and d.tippret=t.tippret 
						--and d.data_inferioara=t.data_inferioara and d.data_superioara=t.data_superioara 
						--and d.pret_vanzare=t.pret_vanzare and d.pret_cu_amanuntul=t.pret_cu_amanuntul 
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
	set @mesaj = 'yso_xStergPreturiNomencl: '+ ERROR_MESSAGE() 
	raiserror(@mesaj, 11, 1)	
end catch
GO