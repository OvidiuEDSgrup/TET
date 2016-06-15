--***
Create procedure wOPGenerareCompensariFacturi @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPGenerareCompensariFacturiSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPGenerareCompensariFacturiSP @sesiune, @parXML
	return @returnValue
end

declare @tipfact char(2),@datacomp datetime,@idcomp varchar(20),@jurnalcomp varchar(3),
	@stergcomp int,@gencomp int,@exfactavans int,@factavansfiltru varchar(20),@lmfiltru varchar(9),
	@tertfiltru varchar(13),@ctfactfiltru varchar(40),@denlm varchar(80),@dentert varchar(80),
	@denctfact varchar(80)--, @userASiS varchar(10)

--exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenerareCompensariFacturi'

Set @tipfact = ISNULL(@parXML.value('(/parametri/@tipfact)[1]', 'char(20)'), 'F')
Set @datacomp = ISNULL(@parXML.value('(/parametri/@datacomp)[1]', 'datetime'), '01/01/1901')
Set @idcomp = ISNULL(@parXML.value('(/parametri/@idcomp)[1]', 'varchar(20)'), 'CMP'+@tipfact)
Set @jurnalcomp = ISNULL(@parXML.value('(/parametri/@jurnalcomp)[1]', 'varchar(20)'), '')
Set @stergcomp = ISNULL(@parXML.value('(/parametri/@stergcomp)[1]', 'int'), 0)
Set @gencomp = ISNULL(@parXML.value('(/parametri/@gencomp)[1]', 'int'), 0)
Set @exfactavans = ISNULL(@parXML.value('(/parametri/@exfactavans)[1]', 'int'), 0)
Set @factavansfiltru = ISNULL(@parXML.value('(/parametri/@factavansfiltru)[1]', 'varchar(20)'), '')
Set @lmfiltru = ISNULL(@parXML.value('(/parametri/@lmfiltru)[1]', 'varchar(20)'), '')
select @denlm=isnull(Denumire,'') from lm where cod=@lmfiltru
Set @tertfiltru = ISNULL(@parXML.value('(/parametri/@tertfiltru)[1]', 'varchar(20)'), '')
select @dentert=isnull(Denumire,'') from terti where tert=@tertfiltru
Set @ctfactfiltru = ISNULL(@parXML.value('(/parametri/@ctfactfiltru)[1]', 'varchar(40)'), '')
select @denctfact=isnull(Denumire_cont,'') from conturi where cont=@ctfactfiltru

begin try
	if @stergcomp=0 and @gencomp=0
		raiserror('Bifati macar optiunea "Generare..."!' ,16,1)
	if isnull(@idcomp,'')=''
		raiserror('Completati nr. / identificator doc.!' ,16,1)
	if isnull(@ctfactfiltru,'')<>'' and not exists (select 1 from conturi where cont=@ctfactfiltru and Are_analitice=0)
		raiserror('Cont inexistent sau cu analitice!' ,16,1)
	if isnull(@tertfiltru,'')<>'' and not exists (select 1 from terti where tert=@tertfiltru)
		raiserror('Tert inexistent!' ,16,1)
	if isnull(@factavansfiltru,'')<>'' and isnull(@tertfiltru,'')=''
		raiserror('Daca ati completat factura, trebuie completat si tertul!' ,16,1)
	if isnull(@lmfiltru,'')<>'' and not exists (select 1 from lm where cod=@lmfiltru)
		raiserror('Loc de munca inexistent!' ,16,1)

	if @stergcomp=1 or @gencomp=1 
		exec GenerareCompensariFacturi @tipfact=@tipfact, 
			@datacomp=@datacomp, @idcomp=@idcomp, @jurnalcomp=@jurnalcomp, @stergerecomp=@stergcomp, 
			@generarecomp=@gencomp, @exfactavans=@exfactavans, @factavansfiltru=@factavansfiltru,
			@lmfiltru=@lmfiltru,@tertfiltru=@tertfiltru,@ctfactfiltru=@ctfactfiltru

	select 'Terminat operatie!' as textMesaj, 
		'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch  
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
