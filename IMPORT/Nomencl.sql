drop view yso_vIaNomencl
go
CREATE VIEW yso_vIaNomencl AS
SELECT --rtrim(n.cod) as _cheieunica
		rtrim(n.cod) as cod
		,rtrim(n.loc_de_munca) as note
		,rtrim(n.denumire) as denumire
		,n.tip
		, dbo.denTipNomenclator(n.tip) as dentip
		,rtrim(n.grupa) as grupa
		, rtrim(isnull(grupe.Denumire,n.grupa)) as dengrupa
		,rtrim(n.um) as um,isnull(RTRIM(um.Denumire),'') as denum,
		RTRIM(n.Furnizor) as furnizor, isnull(rtrim(terti.Denumire),'') as denfurnizor
		, rtrim(n.Tip_echipament) as codvamal, isnull(rtrim(codvama.denumire),'') as dencodvamal,
		convert(decimal(17,5),n.pret_cu_amanuntul) as pret,
		convert(decimal(17,5),n.pret_stoc) as pret_stocn,
		convert(decimal(12,3),isnull(isnull(pretCat.Pret_vanzare, isnull(PretImplicit.Pret_vanzare, n.Pret_vanzare)), 0)) as pretvanzare,
		convert(decimal(17,5),n.Pret_vanzare) as pretvanznom,
		rtrim(n.cont) as cont,rtrim(n.cont)+'-'+RTRIM(ISNULL(conturi.denumire_cont,'')) as dencont
		,n.cota_tva as cotatva,
		pozeria.fisier as poza, --rog lasati fara isnull
		(select top 1 rtrim(Cod_de_bare) from codbare where Cod_produs=n.cod) as codbare
		,CONVERT(decimal(15,3),n.greutate_specifica) greutate
		--,CONVERT(nvarchar(500),'') as _eroareimport		
	from nomencl n 
		left outer join grupe on n.grupa=grupe.grupa
		left outer join conturi on conturi.Subunitate = '1' and conturi.Cont = n.cont
		left outer join terti on terti.Subunitate = '1' and terti.tert = n.furnizor
		left outer join um on n.um=um.UM
		left join preturi pretCat on pretCat.Cod_produs=n.Cod and pretCat.um=4 and pretCat.Tip_pret=1 and pretCat.Data_superioara='2999-01-01' 
		left join preturi PretImplicit on PretImplicit.Cod_produs=n.Cod and PretImplicit.um=1 and PretImplicit.Tip_pret=1 and PretImplicit.Data_superioara='2999-01-01' 
		left outer join PozeRIA on pozeria.tip='N' and pozeria.cod=n.cod
		left outer join codvama on n.Tip_echipament=codvama.Cod
GO
DROP PROCEDURE yso_xIaNomencl 
go
CREATE PROCEDURE yso_xIaNomencl AS
select * from yso_vIaNomencl
go
--***
--if exists (select * from sysobjects where name ='wScriuNomenclatorSP')
--drop procedure wScriuNomenclatorSP
--go
----***

--CREATE procedure wScriuNomenclatorSP @sesiune varchar(50), @parXML xml
--as  

--	Declare @update bit, @cod varchar(20), @grupa varchar(13), @denumire /*startsp*/varchar(150)/*stopsp*/, @um varchar(3),@cont varchar(13), @cotatva float, @pretvanznom float,@codbare varchar(20)
--	declare @o_codbare varchar(20),@pret_stocn float,@observatii varchar(21),@stocmin decimal(12,3),@o_stocmin decimal(12,3)
--	/*startsp*/,@furnizor varchar(13),@pret float, @loc_de_munca varchar(150)/*stopsp*/

--	Set @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0)
--	Set @grupa = upper(isnull(@parXML.value('(/row/@grupa)[1]','varchar(13)'),''))
--	Set @denumire = @parXML.value('(/row/@denumire)[1]',/*startsp*/'varchar(150)'/*stopsp*/)
--	Set @um = upper(isnull(@parXML.value('(/row/@um)[1]','varchar(3)'),'BUC'))
--	Set @cont = isnull(@parXML.value('(/row/@cont)[1]','varchar(13)'),'371')
--	Set @cotatva = isnull(@parXML.value('(/row/@cotatva)[1]','float'),24)
--	Set @pretvanznom = isnull(@parXML.value('(/row/@pretvanznom)[1]','float'),0)
--	Set @pret_stocn = isnull(@parXML.value('(/row/@pret_stocn)[1]','float'),0)
--	Set @cod = /*startsp upper(*/@parXML.value('(/row/@cod)[1]','varchar(20)')
--	Set @observatii = isnull(@parXML.value('(/row/@observatii)[1]','varchar(30)'),'')
--	Set @codbare = upper(@parXML.value('(/row/@codbare)[1]','varchar(20)'))
--	Set @o_codbare = @parXML.value('(/row/@o_codbare)[1]','varchar(20)')
--	Set @stocmin= isnull(@parXML.value('(/row/@stocmin)[1]','decimal(12,3)'),0)
--	Set @o_stocmin= isnull(@parXML.value('(/row/@o_stocmin)[1]','decimal(12,3)'),0)
--	-- startsp
--	Set @furnizor = isnull(@parXML.value('(/row/@furnizor)[1]','varchar(13)'),'')
--	Set @pret = isnull(@parXML.value('(/row/@pret)[1]','float'),0)
--	Set @loc_de_munca = isnull(@parXML.value('(/row/@loc_de_munca)[1]','varchar(150)'),'')
--	-- stopsp

--begin try
--	if exists (select 1 from sys.objects where name='yso_wScriuNomenclator' and type='P')  
--	begin
--	 exec yso_wScriuNomenclator @sesiune, @parXML
--	 return
--	end

--	if exists (select 1 from sys.objects where name='wCodificareSP' and type='P') and ISNULL(@cod,'')='' 
--	begin
--	 exec wCodificareSP @sesiune, @parXML output
--	 Set @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')
--	end

--	declare @tip varchar(1)
--	set @tip=isnull(/*startsp*/isnull(CASE @parXML.value('(/row/@tip)[1]','varchar(1)') WHEN 'U' THEN 'U' ELSE NULL END/*stopsp*/
--		,(select tip_de_nomenclator from grupe where grupa=@grupa)),'A')

--	if @um not in ('', 'BUC') and not exists (select 1 from um where um.UM=@um)
--		raiserror('Unitate de masura invalida!',11,1)
	
--	if @update=1  
--	begin  
--		update nomencl set Tip = @tip, Grupa=@grupa, Denumire= @denumire, UM=@um, Cont=@cont, Cota_TVA=@cotatva, Pret_vanzare=@pretvanznom ,Pret_stoc=convert(decimal(17,5),@pret_stocn) ,tip_echipament=@observatii 
--			/*startsp*/ ,Furnizor=@furnizor, Pret_cu_amanuntul=@pret, Loc_de_munca=@loc_de_munca/*stopsp*/
--		where Cod= @cod  
--		if @codbare is not null
--		begin
--			delete from codbare where Cod_de_bare=@o_codbare
--		end
--	end  
--	else   
--	begin    
--		declare @cod_par varchar(20)    
--		if (isnull(@cod,'')='')  	
--			exec wMaxCod 'cod','nomencl',@cod_par output
--		else 
--			set @cod_par=@cod    
--		insert into nomencl (Cod, Tip, Grupa, Denumire, UM,  
--		UM_1, Coeficient_conversie_1, UM_2, Coeficient_conversie_2, Cont, Valuta, Pret_in_valuta, Pret_stoc, Pret_vanzare, Pret_cu_amanuntul, Cota_TVA, Stoc_limita, Stoc, Greutate_specifica, Furnizor, Loc_de_munca, Gestiune, Categorie, Tip_echipament)  
--		values (@cod_par, @tip, @grupa, @denumire, @um,'',0,'',0,@cont,'',0,convert(decimal(17,5),@pret_stocn),@pretvanznom,0,@cotatva,0,0,0,/*startsp*/@furnizor/*stopsp*/,@loc_de_munca,0,0,@observatii)  
--	end
	
--	if @stocmin>0
--	begin
--		if @stocmin<>@o_stocmin
--		begin
--			delete from stoclim where cod=@cod and cod_gestiune=''
			
--			insert into stoclim(subunitate,tip_gestiune,cod_gestiune,cod,data,Stoc_min,stoc_max,pret,locatie)
--			values('1','','',@cod,getdate(),@stocmin,0,0,'')
--		end
--	end

--	if isnull(@codbare,'')<>'' 
--	begin
--		if @codbare='GENERARE'
--			exec generareEan @codbare=@codbare output, @sesiune=@sesiune, @parXML=@parXML
--		insert into codbare(Cod_de_bare,Cod_produs,UM)
--		values(@codbare,@cod,1)
--	end

--end try

--begin catch
--	declare @mesaj varchar(254)
--	set @mesaj = ERROR_MESSAGE()
--	raiserror(@mesaj, 11, 1)	
--end catch 

--go

if exists (select * from sysobjects where name ='yso_xScriuNomencl')
drop procedure yso_xScriuNomencl
go
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
GO

if exists (select * from sysobjects where name ='yso_wStergNomenclator')
drop procedure yso_wStergNomenclator
go
--***
create procedure yso_wStergNomenclator @sesiune varchar(50), @parXML xml
as
begin try

declare @cod varchar(20)
Set @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')

declare @mesajeroare varchar(100)
set @mesajeroare=''

select @mesajeroare=
  (case	when exists (select 1 from stocuri s where s.cod=@cod and stoc > 0) then 'Articolul are stoc!'
		when exists (select 1 from pozdoc p where p.cod=@cod) then 'Articolul este operat in documente!'
		when exists (select 1 from stocuri s where s.cod=@cod) then 'Articolul are istoric in stocuri!'
		when exists (select 1 from istoricstocuri s where s.cod=@cod) then 'Articolul are istoric in stocuri!'
		when exists (select 1 from pozcon p where p.cod=@cod) then 'Articolul este operat in contracte/comenzi!'
		when @cod is null then 'Nu a fost trimis codul'
		else '' end)

if @mesajeroare=''
	delete from nomencl where cod=@cod
else 
	raiserror(@mesajeroare, 11, 1)
end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
GO
if exists (select * from sysobjects where name ='yso_xStergNomencl')
drop procedure yso_xStergNomencl
go
create procedure yso_xStergNomencl  @fisier nvarchar(4000) as
begin try -- sterg nomenclator
	--declare @fisier nvarchar(4000) 
	--set @fisier='\\10.0.0.10\import\80_ASIS_componenta_pachete_11 mai 2012_DC.xls'
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
	drop table ##nomenclXlsIniTmp

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
	select isnull(cod,'') as cod, isnull(denumire,'') as denumire, isnull(tip,'') as tip, isnull(dentip,'') as dentip, isnull(grupa,'') as grupa, isnull(dengrupa,'') as dengrupa, isnull(um,'') as um, isnull(denum,'') as denum, isnull(furnizor,'') as furnizor, isnull(denfurnizor,'') as denfurnizor, isnull(codvamal,'') as codvamal, isnull(dencodvamal,'') as dencodvamal
	, isnull(pret,'') as pret, isnull(pret_stocn,'') as pret_stocn, isnull(pretvanzare,'') as pretvanzare, isnull(pretvanznom,'') as pretvanznom, isnull(cont,'') as cont, isnull(dencont,'') as dencont, isnull(cotatva,'') as cotatva, isnull(poza,'') as poza, isnull(codbare,'') as codbare
	,_linieimport
	into #nomenclXlsTmp
	from ##nomenclXlsIniTmp
	--where cod like '01263006'

	if OBJECT_ID('tempdb..#nomenclXlsDifTmp') is not null
		drop table #nomenclXlsDifTmp

	select distinct cod
	into #nomenclXlsDifTmp
	from #nomenclXlsTmp 
	intersect
	select			cod
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
				--, denumire, grupa, um, furnizor
				--, codvamal as observatii
				--, convert(decimal(17,5),pret) pret
				--, convert(decimal(17,5),pret_stocn) pret_stocn
				--, convert(decimal(17,5),pretvanznom) pretvanznom
				--, cont
				--, convert(decimal(5,0),cotatva) as cotatva
				--,isnull((select TOP 1 1 from nomencl v 
				--	where v.cod=t.cod),0) as [update] 
				from #nomenclXlsDifTmp t 
				where t.nrcrt=@contor for xml raw)
			if @parxml is not null
 				exec yso_wStergNomenclator @sesiune=null,@parxml=@parxml
 		end try
 		begin catch
			set @eroareProc = ERROR_MESSAGE()
			insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
			select '','','S',HOST_ID(),'Erori import linie nomencl',@eroareProc
			begin try
				insert #nomenclXlsErrTmp
				select _linieimport, @eroareProc as _eroareimport from #nomenclXlsTmp t inner join #nomenclXlsDifTmp d
					on d.cod=t.cod 
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
		drop table #mesajeASiSTmp
		
	if OBJECT_ID('tempdb..#nomenclXlsErrTmp') is not null
		drop table #nomenclXlsErrTmp
	
end try
begin catch
	declare @mesaj varchar(254)
	set @mesaj ='yso_xStergNomencl:'+ERROR_MESSAGE() 
	raiserror(@mesaj, 11, 1)	
end catch
go