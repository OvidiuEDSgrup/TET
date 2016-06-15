create procedure [dbo].[wOPPreluareBK] @sesiune varchar(50), @parXML xml output 
as 
begin try
declare @datacomanda datetime, @comanda varchar(20), @gestbk varchar(20), @path varchar(500), @sub varchar(20), @tert varchar(20),
		@utilizator varchar(20), @categpret int, @pret float, @nrpoz int, @data_operarii varchar(20), @ora_operarii varchar(20),
		@scadenta varchar(20), @cantitate float, @cod varchar(30),@ExecuteQuery nvarchar(500),@DriverName nvarchar(500),@DataSource nvarchar(500),
		@ExecuteSA nvarchar(500), @user varchar(50), @DB varchar(30), @DropQuery varchar(100), @selectCursor varchar(50), 
		@sheet varchar(50),@gestdepo varchar(20), @lm varchar(20), @calefis varchar(500), @numefis varchar(20), @exista int
select	@datacomanda=isnull(@parXML.value('(/parametri/@datacomanda)[1]', 'datetime'),'1900-01-01'),
		@comanda=isnull(@parXML.value('(/parametri/@comanda)[1]', 'varchar(20)'),''),
		@gestdepo=isnull(@parXML.value('(/parametri/@gestdepo)[1]', 'varchar(20)'),''),
		@numefis=isnull(@parXML.value('(/parametri/@path)[1]', 'varchar(500)'),''),
		@sheet=isnull(@parXML.value('(/parametri/@sheet)[1]', 'varchar(500)'),'')
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
exec luare_date_par 'AR', 'CALEEXCEL', 0, 0, @calefis output
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
-------------------------citire proprietati utilizator--------------------
set @tert=ISNULL((select max(rtrim(VALOARE)) from proprietati where tip='utilizator' 
				and cod=@utilizator and Cod_proprietate='CLIENT' and Valoare<>''),'')
set @categpret=isnull((select max(rtrim(VALOARE)) from proprietati where tip='utilizator' 
				and cod=@utilizator and Cod_proprietate='CATEGPRET' and Valoare<>''),1)
set @gestbk=isnull((select max(rtrim(VALOARE)) from proprietati where tip='utilizator' 
				and cod=@utilizator and Cod_proprietate='GESTBK' and Valoare<>''),1)
if @lm='' or @lm is null
			set @lm=isnull((select max(loc_de_munca) from gestcor where gestiune=@gestdepo), '')
if @gestdepo=''
	raiserror('wOPPreluareBK:Completati gestiunea de depozit',16,1)
if charindex('.xls',@numefis)=0
	    raiserror('Extensia fisierului nu este .xls, operatia preia doar fisiere cu extensia .xls',16,1)
if @sheet=''
		raiserror('wOPPreluareBK:Introduceti foaia din fisierul excel de pe care se doreste preluarea!',16,1)
if isnull(@comanda, '')=''
		begin
			declare @NrDocFisc int, @fXML xml, @tip varchar(2)
			set @tip='BK'
			set @fXML = '<row/>'
			set @fXML.modify ('insert attribute codMeniu {"CO"} into (/row)[1]')
			set @fXML.modify ('insert attribute tip {sql:variable("@tip")} into (/row)[1]')
			set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
			set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')
			exec wIauNrDocFiscale @fXML, @NrDocFisc output
			if ISNULL(@NrDocFisc, 0)<>0
				set @comanda=LTrim(RTrim(CONVERT(char(8), @NrDocFisc)))
			if isnull(@comanda, '')=''
			begin
				declare @ParUltNr char(9), @UltNr int
				set @ParUltNr='NRCNT' + @tip
				exec luare_date_par 'UC', @ParUltNr, '', @UltNr output, 0
				while @UltNr=0 or exists (select 1 from con where subunitate=@Sub and tip=@tip and contract=rtrim(ltrim(convert(char(9), @UltNr))))
					set @UltNr=@UltNr+1
				set @comanda=rtrim(ltrim(convert(char(9), @UltNr)))
				exec setare_par 'UC', @ParUltNr, null, null, @UltNr, null
			end
        end
        
set @path=rtrim(@calefis)+ltrim(@numefis)
EXEC master..xp_fileexist @path, @exista out
 IF @exista = 0
  raiserror('wOPPreluareBK:Fisierul nu exista!',16,1)
--------- driverul nu va citi din excel doar daca utilizatorul de windows este adaugat ca "db_owner" ---------------
set @user=(select Observatii from utilizatori where ID=@utilizator)
exec sp_addrolemember 'db_owner', @user
declare @BKPrel table ( cod varchar(40), cantitate varchar(20))
set @ExecuteSA='exec as login=''sa'''
--set @DriverName='Microsoft.ACE.OLEDB.12.0'
--set @DataSource='Data Source='+@path+';Extended Properties=Excel 12.0'

set @DriverName='Microsoft.ACE.OLEDB.12.0'
set @DataSource='Excel 12.0 Xml;Database='+@path+';HDR=No;IMEX=1'
---metoda cu openrowset este mai rapida.----- permite subselect
--set @ExecuteQuery='SELECT cod, cantitate from opendatasource('''+@DriverName+''','''+@DataSource+''')...[Sheet1$]'
set @ExecuteQuery='SELECT s.f1 as cod, s.f7 as cantitate from nomencl n,openrowset('''+@DriverName+''','''+@DataSource+''',''select f1, f7 from ['+@sheet+'$] '') s where n.cod=s.f1 and s.f7>''0.01'''
exec sp_executesql @ExecuteSA
insert into @BKPrel(cod,cantitate)
exec sp_executesql @ExecuteQuery
if (select count(*) from @BKPrel)<1
 raiserror('wOPPreluareBK:Preluare esuata, nu a fost preluata nici o comanda!',16,1)

/*cursor pentru toate liniile din fisierul excel de unde se face preluare liniilor unei comenzi*/
		    /*aici am pus aceasta conditie deaorece driverul citeste mai mult de cate linii sunt---cele care sunt cu null sunt la sf.*/
			
		    declare @input xml
			set @input=(select top 1  'BK' as '@tip' ,@comanda as '@numar', convert(varchar(20),@datacomanda,101) as '@data',
									@gestdepo as '@gestiune', @tert as '@tert', @gestbk as '@gestprim',
									(select rtrim(bk.cod) as '@cod' ,convert(varchar(20),bk.cantitate) as '@cantitate',
									convert(varchar(20),bk.cantitate) as '@Tcantitate',@categpret as '@categpret'
									from @bkprel bk
									for XML path,type)
									for XML path,type)
									exec wScriuPozCon @sesiune,@input
  select 'wOPPreluareBK:In urma preluarii a fost generata o comanda de livrare cu numarul '+@comanda+' din data de: '+CONVERT(varchar(20),@datacomanda,101)+' !' as textMesaj for xml raw , root('Mesaje')
end try
begin catch
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
