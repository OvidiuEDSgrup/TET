DROP VIEW yso_vIaGrupe 
GO
CREATE VIEW yso_vIaGrupe AS
select rtrim(g.Tip_de_nomenclator) as tip
	,rtrim(g.Tip_de_nomenclator)+'-' + 
		case g.Tip_de_nomenclator
		when 'A' then 'Marfa'
		when 'F' then 'Mijloace fixe'
		when 'M' then 'Material'
		when 'O' then 'Obiecte de inventar'
		when 'P' then 'Produs'
		when 'R' then 'Servicii furnizate'
		when 'S' then 'Servicii prestate'
		end
	as denTip
	, rtrim(g.grupa) as grupa,rtrim(g.Denumire) as denumire, rtrim (isnull(p.Cod_proprietate,'')) as cont  
	from grupe g 
		left join propgr p on g.grupa=p.Grupa
GO
DROP PROCEDURE yso_xIaGrupe 
GO
CREATE PROCEDURE yso_xIaGrupe AS
select * from yso_vIaGrupe
GO
--***
if exists (select * from sysobjects where name='yso_wScriuGrupe')
drop procedure yso_wScriuGrupe
go
--***
create procedure [dbo].yso_wScriuGrupe  @sesiune varchar(50),@parXML xml 
as  
begin try
	declare @tip_nomencl varchar(1),@tip_nomenclold varchar(1), @grupa varchar(13),@grupaold varchar(13), @denumire varchar(120),@denumireold varchar(120),@update bit, @cont varchar(50)

	select
		@tip_nomencl = upper(ISNULL(@parXML.value('(/row/@tip)[1]','varchar(1)'),'')),
		@tip_nomenclold = ISNULL(@parXML.value('(/row/@o_tip)[1]','varchar(1)'),''),
		@update = ISNULL(@parXML.value('(/row/@update)[1]','bit'),''),
		@grupa = upper(ltrim(rtrim(ISNULL(@parXML.value('(/row/@grupa)[1]','varchar(13)'),'')))),
		@grupaold = ISNULL(@parXML.value('(/row/@o_grupa)[1]','varchar(13)'),''),
		@denumire = upper(ltrim(rtrim(ISNULL(@parXML.value('(/row/@denumire)[1]','varchar(120)'),'')))),
		@denumireold = ISNULL(@parXML.value('(/row/@o_denumire)[1]','varchar(120)'),''),
		@cont = ltrim(rtrim(ISNULL(@parXML.value('(/row/@cont)[1]','varchar(50)'),'')))
	
	if @cont<>'' and not exists (select 1 from conturi where cont=@cont)
		raiserror ('Contul nu este valid!',11,1)
	
	if exists (select * from grupe where Grupa=@grupa and @grupa!=@grupaold) --daca mai exista o grupa cu acelasi cod
	begin
		raiserror ('Grupa deja existenta!',11,1)
		return -1
	end
	if @update=1  --modificare
	begin  
		update grupe set Tip_de_nomenclator = @tip_nomencl, Denumire= @denumire
		where Grupa  = @grupaold
		if exists (select * from nomencl n where  n.Grupa = @grupaold and @grupa!=@grupaold ) --? daca exista o nomenclatura cu grupa initiala
		begin  
			raiserror ('Grupa nu poate fi modificata pentru ca a fost atribuita in nomenclator!',11,1)
			return -1
		end	
		else -- daca NU exista o nomenclatura cu grupa initiala

-- mitz: aici trebuie block begin/end pentru aceste update-uri?
			update grupe set Grupa=@grupa where Grupa=@grupaold
			
			update propgr set Cod_proprietate=@cont,Tip=@tip_nomencl, Grupa=@grupa
			where Tip=@tip_nomenclold and Grupa=@grupaold and Numar=0	

	end 	
	else  --adaugare 
	begin  
		if isnull(@tip_nomencl,'')='' 
		begin  
			raiserror ('Introduceti tipul de nomenclator!',11,1)
			return -1
		end	
		if isnull(@grupa,'')='' 
		begin
			if not exists(select convert(float,RTRIM(grupa)) from grupe where ISNUMERIC(rtrim(grupa))=1) 
				set @grupa=1 
			else							
				select @grupa= (select max(convert(float,rtrim(grupa))) from grupe  where ISNUMERIC(rtrim(grupa))=1 and Grupa not like '%,%')+1							
		end	
			
	if isnull(@denumire,'')=''  
	begin  
		raiserror ('Introduceti denumirea!',11,1)
		return -1
	end	
		insert into grupe(Tip_de_nomenclator, Grupa, Denumire, Proprietate_1, Proprietate_2, Proprietate_3, Proprietate_4, Proprietate_5, Proprietate_6, Proprietate_7, Proprietate_8, Proprietate_9, Proprietate_10)
		values (@tip_nomencl, @grupa, @denumire, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	
		
	end
	-- adaugare/modificare cont specific
	if not exists (select * from propgr where tip=@tip_nomencl and Grupa=@grupa and Numar=0)
	begin
		insert into propgr (Tip,Grupa,Numar,Cod_proprietate)
		values(@tip_nomencl,@grupa,0,@cont)
	end
	else
	begin
		update propgr set Cod_proprietate=@cont where tip=@tip_nomencl and Grupa=@grupa and Numar=0
	end
end try

begin catch
	declare @mesajEroare varchar(254)
	set @mesajEroare = ERROR_MESSAGE()
	raiserror(@mesajEroare, 11, 1)	
end catch
go

if exists (select * from sysobjects where name ='yso_xScriuGrupe')
drop procedure yso_xScriuGrupe
go
create procedure yso_xScriuGrupe  @fisier nvarchar(4000) as
begin try -- scriu grupe
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
	
	if OBJECT_ID('tempdb..##grupeXlsIniTmp') is not null
	drop table ##grupeXlsIniTmp

	set @sursa='Excel 12.0;Database=@fisier;Extended Properties="Excel 12.0 Xml;IMEX=1;HDR=YES;";'
	set @sursa=REPLACE(@sursa,'@fisier',@fisier)
	set @txtSelect='Select * from [grupe$]'
	set @txtSql=
	'select * into ##grupeXlsIniTmp
	from OPENROWSET(''Microsoft.ACE.OLEDB.12.0''
	,@sursa
	, @txtSelect) x '
	set @txtSql=REPLACE(@txtSql,'@sursa',''''+@sursa+'''')
	set @txtSql=REPLACE(@txtSql,'@txtSelect',''''+@txtSelect+'''')
	exec sp_executesql @txtSql

	if OBJECT_ID('tempdb..#grupeXlsTmp') is not null
		drop table #grupeXlsTmp

	--set dateformat mdy
	select isnull(tip,'') as tip, isnull(denTip,'') as denTip, isnull(grupa,'') as grupa, isnull(denumire,'') as denumire, isnull(cont,'') as cont
		,_linieimport
	into #grupeXlsTmp
	from ##grupeXlsIniTmp where _linieimport is not null
	--where um like '01263006'

	if OBJECT_ID('tempdb..#grupeXlsDifTmp') is not null
		drop table #grupeXlsDifTmp

	select distinct tip, denTip, grupa, denumire, cont
	into #grupeXlsDifTmp
	from #grupeXlsTmp 
	except
	select			tip, denTip, grupa, denumire, cont
	from yso_vIaGrupe

/*	
select * from #grupeXlsTmp 

select distinct tip, denTip, grupa, denumire, cont
--into #grupeXlsDifTmp
from #grupeXlsDifTmp 
--except
select			tip, denTip, grupa, denumire, cont
from yso_vIaGrupe
where grupa like 'MFA111'


select  d.pretvanznom-t.pretvanznom ,t.*,d.* from #grupeXlsDifTmp d
inner join yso_vIaUm t on t.um=d.um and t.um like '0024252'
where 
d.denumire<>t.denumire 
--or d.grupa<>t.grupa 
--or d.um<>t.um 
--or d.furnizor<>t.furnizor 
--or d.umvamal<>t.umvamal 
--or d.pret<>t.pret 
--or d.pret_stocn<>t.pret_stocn 
--or d.pretvanznom<>t.pretvanznom 
--or d.cont<>t.cont 
--or d.cotatva<>t.cotatva

*/
	alter table #grupeXlsDifTmp add nrcrt int identity(1,1) not null
	create unique clustered index id on #grupeXlsDifTmp (nrcrt)
	--create nonclustered index preturi on #preturiXlsDifTmp (um, catpret, tippret, data_inferioara, pret_vanzare, pret_cu_amanuntul)

	declare @randuri int
	select @randuri=MAX(nrcrt) from #grupeXlsDifTmp

	if OBJECT_ID('tempdb..#mesajeASiSTmp') is not null
		drop table #mesajeASiSTmp
		
	select top 0 Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj 
	into #mesajeASiSTmp from mesajeASiS
	
	if OBJECT_ID('tempdb..#grupeXlsErrTmp') is not null
		drop table #grupeXlsErrTmp
		
	select top 0 _linieimport, convert(varchar(500),'') as _eroareimport into #grupeXlsErrTmp from #grupeXlsTmp t 

-- select * from #grupeXlsErrTmp
	set @contor=1
	while @contor<=@randuri
	begin
		begin try
			set @parxml=(select tip, denTip
				, grupa, RTRIM(grupa) as o_grupa
				, denumire, cont
				,isnull((select TOP 1 1 from yso_vIaGrupe v 
					where v.tip=t.tip and v.grupa=t.grupa),0) as [update] 
				from #grupeXlsDifTmp t 
				where t.nrcrt=@contor for xml raw)
			--if '0007001A'=@parXML.value('(/row/@um)[1]','varchar(20)')
			--	print 'stop'
			if @parxml is not null
 				exec yso_wScriuGrupe @sesiune=null,@parxml=@parxml
 		end try
 		begin catch
			set @eroareProc = ERROR_MESSAGE()
			begin try
				insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
				select '','','S',HOST_ID(),'Erori import linie grupe',@eroareProc
				
				insert #grupeXlsErrTmp
				select _linieimport, @eroareProc as _eroareimport from #grupeXlsTmp t inner join #grupeXlsDifTmp d
					on d.tip=t.tip and d.denTip=t.denTip and d.grupa=t.grupa and d.denumire=t.denumire and d.cont=t.cont
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
		set @txtSelect='Select * from [grupe$]'
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
		set @txtSql=@txtSql+' inner join #grupeXlsErrTmp e on e._linieimport=x._linieimport'
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
	
	if OBJECT_ID('tempdb..#grupeXlsTmp') is not null
		drop table #grupeXlsTmp
	
	
	if OBJECT_ID('tempdb..#grupeXlsDifTmp') is not null
		drop table #grupeXlsDifTmp
		
	if OBJECT_ID('tempdb..#mesajeASiSTmp') is not null
		drop table #mesajeASiSTmp -- select * from #mesajeASiSTmp
		
	if OBJECT_ID('tempdb..#grupeXlsErrTmp') is not null
		drop table #grupeXlsErrTmp -- select * into testerrxls from #grupeXlsErrTmp
	
end try
begin catch
	declare @mesaj varchar(254)
	set @mesaj ='yso_xScriuGrupe: '+ ERROR_MESSAGE() 
	raiserror(@mesaj, 11, 1)	
end catch
GO