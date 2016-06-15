--***
Create procedure wOPRefacereStocuri @sesiune varchar(50), @parXML xml
as

declare @tabela char(20), @inlocpreturi int, @panaladata int, @data datetime, @gest char(20), 
@marca char(20), @cod char(20), @dengest varchar(30), @numemarca varchar(80), @dencod varchar(80), 
@pretmediu int, @recalcpretmediu int, @exceptiefolpretmediu int--, @userASiS varchar(10)

--exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPRefacereStocuri'

Set @tabela = ISNULL(@parXML.value('(/parametri/@tabela)[1]', 'char(20)'), 'Stocuri')
Set @inlocpreturi = ISNULL(@parXML.value('(/parametri/@inlocpreturi)[1]', 'int'), 0)
Set @panaladata = ISNULL(@parXML.value('(/parametri/@panaladata)[1]', 'int'), 0)
Set @data = ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '12/31/2999')
if @panaladata=0 Set @data = null
Set @gest = ISNULL(@parXML.value('(/parametri/@gest)[1]', 'char(20)'), ISNULL(@parXML.value('(/parametri/@gestiune)[1]', 'char(20)'), ''))
select @dengest=isnull(Denumire_gestiune,'') from gestiuni where Cod_gestiune=@gest
Set @marca = ISNULL(@parXML.value('(/parametri/@marca)[1]', 'char(20)'), '')
select @numemarca=isnull(Nume,'') from personal where Marca=@marca
Set @cod = ISNULL(@parXML.value('(/parametri/@cod)[1]', 'char(20)'), '')
select @dencod=isnull(Denumire,'') from nomencl where Cod=@cod
exec luare_date_par 'GE','MEDIUP',@pretmediu output,0,''
exec luare_date_par 'GE','MEDIUPREC',@recalcpretmediu output,0,''
exec luare_date_par 'GE','MEDPEXFOL',@exceptiefolpretmediu output,0,''

begin try
	if @inlocpreturi=1 and @pretmediu=0
		raiserror('Nu bifati "Cu inlocuire preturi"!' ,16,1)
	if @inlocpreturi=0 and @pretmediu=1 and @recalcpretmediu=0
		raiserror('Bifati "Cu inlocuire preturi"!' ,16,1)
	if isnull(@gest,'')<>'' and isnull(@marca,'')<>''
		raiserror('Nu este permisa filtrarea atat pe gestiune, cat si pe marca!' ,16,1)
	if isnull(@gest,'')<>'' and @inlocpreturi=1
		raiserror('Nu este permisa filtrarea pe gestiune, daca ati bifat "Cu inlocuire preturi"!' ,16,1)
	if isnull(@marca,'')<>'' and (@tabela='Serii' or @inlocpreturi=1)
		raiserror('Nu este permisa filtrarea pe marca, daca ati bifat "Cu inlocuire preturi" sau daca ati ales tabela "Serii"!' ,16,1)
	if isnull(@marca,'')<>'' and not (@tabela='Stocuri' and @inlocpreturi=0 and isnull(@gest,'')='' 
		and (@pretmediu=0 or @exceptiefolpretmediu=1))
		raiserror('Nu este permisa filtrarea pe marca in aceste conditii!' ,16,1)
	if isnull(@gest,'')<>'' and not exists (select 1 from gestiuni where Cod_gestiune=isnull(@gest,''))
		raiserror('Gestiune inexistenta!' ,16,1)
	if isnull(@marca,'')<>'' and not exists (select 1 from personal where Marca=isnull(@marca,''))
		raiserror('Marca inexistenta!' ,16,1)
	if isnull(@cod,'')<>'' and not exists (select 1 from nomencl where cod=isnull(@cod,''))
		raiserror('Cod inexistent!' ,16,1)

	if @gest='' set @gest=null
	if @marca='' set @marca=null
	if @cod='' set @cod=null
	if @tabela='Stocuri' exec RefacereStocuri @cGestiune=@gest, @cCod=@cod, @cMarca=@marca, 
		@dData=@data, @PretMed=@PretMediu, @InlocPret=@inlocpreturi --and @farainlocpretdoc=0
	if @tabela='Serii' exec RefacereSerii @cGestiune=@gest, @cCod=@cod, @dData=@data

	select 'Terminat operatie!' as textMesaj, 
		'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch  
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
