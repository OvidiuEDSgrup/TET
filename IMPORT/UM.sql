if exists (select * from sysobjects where name ='yso_xIaUM')
drop procedure yso_xIaUM
go
--***
CREATE procedure yso_xIaUM as  
select rtrim(um) as um,rtrim(denumire) as denumire  
from um  
go
--***
if exists (select * from sysobjects where name ='yso_wScriuUM')
drop procedure yso_wScriuUM
go
--***
CREATE procedure yso_wScriuUM  @sesiune varchar(50), @parXML xml--, @um varchar(3), @denumire varchar(30)
as  
declare @um varchar(3), @denumire varchar(30)
Set @um = @parXML.value('(/row/@um)[1]','varchar(3)')
Set @denumire = @parXML.value('(/row/@denumire)[1]','varchar(30)')

begin try
if exists (select * from um where UM = @um)  
begin  
 update um set Denumire= @denumire
 where UM  = @um  
end  
else   
begin  
 insert into um (UM, Denumire)  
 values (upper(@um), @denumire)  
end  
end try

begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
go


if exists (select * from sysobjects where name ='yso_xScriuUm')
drop procedure yso_xScriuUm
go
create procedure yso_xScriuUm  @fisier nvarchar(4000) as
begin try -- scriu umator
	--declare @fisier nvarchar(4000) 
	--set @fisier='\\10.0.0.10\import\testimport.xlsx'
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
	
	if OBJECT_ID('tempdb..##umXlsIniTmp') is not null
	drop table ##umXlsIniTmp

	set @sursa='Excel 12.0;Database=@fisier;Extended Properties="Excel 12.0 Xml;IMEX=1;HDR=YES;";'
	set @sursa=REPLACE(@sursa,'@fisier',@fisier)
	set @txtSelect='Select * from [um$]'
	set @txtSql=
	'select * into ##umXlsIniTmp
	from OPENROWSET(''Microsoft.ACE.OLEDB.12.0''
	,@sursa
	, @txtSelect) x '
	set @txtSql=REPLACE(@txtSql,'@sursa',''''+@sursa+'''')
	set @txtSql=REPLACE(@txtSql,'@txtSelect',''''+@txtSelect+'''')
	exec sp_executesql @txtSql

	if OBJECT_ID('tempdb..#umXlsTmp') is not null
		drop table #umXlsTmp

	--set dateformat mdy
	select isnull(um,'') as um, isnull(denumire,'') as denumire
		,_linieimport
	into #umXlsTmp
	from ##umXlsIniTmp where _linieimport is not null
	--where um like '01263006'

	if OBJECT_ID('tempdb..#umXlsDifTmp') is not null
		drop table #umXlsDifTmp

	select distinct um, denumire
	into #umXlsDifTmp
	from #umXlsTmp 
	except
	select			um, denumire
	from um

/*	
select * from #umXlsTmp 

select  distinct top 1 um, denumire, grupa, um, furnizor, umvamal, pret, pret_stocn, pretvanznom, cont, cotatva from #umXlsDifTmp 



select um, denumire, grupa, um, furnizor, umvamal, pret, pret_stocn, pretvanznom, cont, cotatva from yso_vIaUm 
where um like '0024252'


select  d.pretvanznom-t.pretvanznom ,t.*,d.* from #umXlsDifTmp d
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
	alter table #umXlsDifTmp add nrcrt int identity(1,1) not null
	create unique clustered index id on #umXlsDifTmp (nrcrt)
	--create nonclustered index preturi on #preturiXlsDifTmp (um, catpret, tippret, data_inferioara, pret_vanzare, pret_cu_amanuntul)

	declare @randuri int
	select @randuri=MAX(nrcrt) from #umXlsDifTmp

	if OBJECT_ID('tempdb..#mesajeASiSTmp') is not null
		drop table #mesajeASiSTmp
		
	select top 0 Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj 
	into #mesajeASiSTmp from mesajeASiS
	
	if OBJECT_ID('tempdb..#umXlsErrTmp') is not null
		drop table #umXlsErrTmp
		
	select top 0 _linieimport, convert(varchar(500),'') as _eroareimport into #umXlsErrTmp from #umXlsTmp t  

-- select * from #umXlsErrTmp
	set @contor=1
	while @contor<=@randuri
	begin
		begin try
			set @parxml=(select um
				, denumire
				,isnull((select TOP 1 1 from um v 
					where v.um=t.um),0) as [update] 
				from #umXlsDifTmp t 
				where t.nrcrt=@contor for xml raw)
			--if '0007001A'=@parXML.value('(/row/@um)[1]','varchar(20)')
			--	print 'stop'
			if @parxml is not null
 				exec yso_wScriuUM @sesiune=null,@parxml=@parxml
 		end try
 		begin catch
			set @eroareProc = ERROR_MESSAGE()
			begin try
				insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
				select '','','S',HOST_ID(),'Erori import linie um',@eroareProc
				
				insert #umXlsErrTmp
				select _linieimport, @eroareProc as _eroareimport from #umXlsTmp t inner join #umXlsDifTmp d
					on d.um=t.um and d.denumire=t.denumire
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
		set @txtSelect='Select * from [um$]'
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
		set @txtSql=@txtSql+' inner join #umXlsErrTmp e on e._linieimport=x._linieimport'
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
	
	if OBJECT_ID('tempdb..#umXlsTmp') is not null
		drop table #umXlsTmp
	
	
	if OBJECT_ID('tempdb..#umXlsDifTmp') is not null
		drop table #umXlsDifTmp
		
	if OBJECT_ID('tempdb..#mesajeASiSTmp') is not null
		drop table #mesajeASiSTmp -- select * from #mesajeASiSTmp
		
	if OBJECT_ID('tempdb..#umXlsErrTmp') is not null
		drop table #umXlsErrTmp -- select * into testerrxls from #umXlsErrTmp
	
end try
begin catch
	declare @mesaj varchar(254)
	set @mesaj = 'yso_xScriuUm: '+ERROR_MESSAGE() 
	raiserror(@mesaj, 11, 1)	
end catch
GO