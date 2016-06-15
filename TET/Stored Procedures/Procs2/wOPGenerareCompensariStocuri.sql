--***
Create procedure wOPGenerareCompensariStocuri @sesiune varchar(50), @parXML xml
as

declare @lmstrict int,@datastoc datetime,@datacomp datetime,@tipcomp char(2),@nrcomp varchar(20),
@ctcomp varchar(40),@lmcomp varchar(9),@stergcomp int,@gencomp int,
@gestfiltru varchar(9),@codfiltru varchar(20),@ctstocfiltru varchar(40),@gestcuplus varchar(9),@stocladata int,
@denctcomp varchar(80),@denlmcomp varchar(80),@dengest varchar(30),@dencod varchar(80),
@denctstoc varchar(80),@dengestcuplus varchar(30)--, @userASiS varchar(10)

--exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenerareCompensariStocuri'

Set @lmstrict=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
	parametru='CENTPROF'), 0)
Set @datastoc = ISNULL(@parXML.value('(/parametri/@datastoc)[1]', 'datetime'), '12/31/2999')
Set @datacomp = ISNULL(@parXML.value('(/parametri/@datacomp)[1]', 'datetime'), '01/01/1901')
Set @tipcomp = ISNULL(@parXML.value('(/parametri/@tipcomp)[1]', 'char(20)'), 'AI')
Set @nrcomp = ISNULL(@parXML.value('(/parametri/@nrcomp)[1]', 'varchar(20)'), 'CORA')
Set @ctcomp = ISNULL(@parXML.value('(/parametri/@ctcomp)[1]', 'varchar(40)'), '7718')
select @denctcomp=isnull(Denumire_cont,'') from conturi where cont=@ctcomp
Set @lmcomp = ISNULL(@parXML.value('(/parametri/@lmcomp)[1]', 'varchar(20)'), '')
select @denlmcomp=isnull(Denumire,'') from lm where cod=@lmcomp
Set @stergcomp = ISNULL(@parXML.value('(/parametri/@stergcomp)[1]', 'int'), 0)
Set @gencomp = ISNULL(@parXML.value('(/parametri/@gencomp)[1]', 'int'), 0)
Set @gestfiltru = ISNULL(@parXML.value('(/parametri/@gestfiltru)[1]', 'varchar(20)'), '')
select @dengest=isnull(Denumire_gestiune,'') from gestiuni where Cod_gestiune=@gestfiltru
Set @codfiltru = ISNULL(@parXML.value('(/parametri/@codfiltru)[1]', 'varchar(20)'), '')
select @dencod=isnull(Denumire,'') from nomencl where cod=@codfiltru
Set @ctstocfiltru = ISNULL(@parXML.value('(/parametri/@ctstocfiltru)[1]', 'varchar(40)'), '')
select @denctstoc=isnull(Denumire_cont,'') from conturi where cont=@ctstocfiltru
Set @gestcuplus = ISNULL(@parXML.value('(/parametri/@gestcuplus)[1]', 'varchar(20)'), '')
select @dengestcuplus=isnull(Denumire_gestiune,'') from gestiuni where Cod_gestiune=@gestcuplus
Set @stocladata = ISNULL(@parXML.value('(/parametri/@stocladata)[1]', 'int'), 0)

begin try
	if @stergcomp=0 and @gencomp=0
		raiserror('Bifati macar optiunea "Generare..."!' ,16,1)
	if isnull(@nrcomp,'')=''
		raiserror('Completati nr. / identificator doc.!' ,16,1)
	if not exists (select 1 from conturi where cont=@ctcomp and Are_analitice=0)
		raiserror('Cont compensari inexistent sau cu analitice!' ,16,1)
	if (@lmstrict=1 or @lmcomp<>'') and not exists (select 1 from lm where cod=@lmcomp)
		raiserror('Loc de munca inexistent!' ,16,1)
	if isnull(@ctstocfiltru,'')<>'' and not exists (select 1 from conturi where cont=@ctstocfiltru and Are_analitice=0)
		raiserror('Cont de stoc inexistent sau cu analitice!' ,16,1)
	if isnull(@codfiltru,'')<>'' and not exists (select 1 from nomencl where cod=@codfiltru)
		raiserror('Cod inexistent!' ,16,1)
	if isnull(@gestfiltru,'')<>'' and not exists (select 1 from gestiuni where Cod_gestiune=@gestfiltru)
		raiserror('Gestiune inexistenta!' ,16,1)
	if isnull(@gestcuplus,'')<>'' and not exists (select 1 from gestiuni where Cod_gestiune=@gestcuplus)
		raiserror('Gestiune cu stoc pozitiv inexistenta!' ,16,1)

	if @gestfiltru='' set @gestfiltru=null
	if @codfiltru='' set @codfiltru=null
	if @stergcomp=1 or @gencomp=1 
		exec GenerareCompensariStocuri @datastoc=@datastoc,@datacomp=@datacomp,@tipcomp=@tipcomp,
			@nrcomp=@nrcomp,@ctcomp=@ctcomp,@stergerecomp=@stergcomp,@generarecomp=@gencomp,
			@gestfiltru=@gestfiltru,@codfiltru=@codfiltru,@ctstocfiltru=@ctstocfiltru,
			@gestcuplus=@gestcuplus,@stocladata=@stocladata,@lmcomp=@lmcomp

	select 'Terminat operatie!' as textMesaj, 
		'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch  
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
