--***
Create procedure wOPGenerareCompensariEfecte @sesiune varchar(50), @parXML xml
as

declare @tipefecte char(2),@datacomp datetime,@idcomp varchar(20),@ctcomp varchar(40),
@stergcomp int,@gencomp int,@tert varchar(13),@dentert varchar(80), @denctcomp varchar(80)--, @userASiS varchar(10)

--exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenerareCompensariEfecte'

Set @tipefecte = ISNULL(@parXML.value('(/parametri/@tipefecte)[1]', 'char(20)'), 'P')
Set @datacomp = ISNULL(@parXML.value('(/parametri/@datacomp)[1]', 'datetime'), '01/01/1901')
Set @idcomp = ISNULL(@parXML.value('(/parametri/@idcomp)[1]', 'varchar(20)'), 'CMP'+@tipefecte)
Set @ctcomp = ISNULL(@parXML.value('(/parametri/@ctcomp)[1]', 'varchar(40)'), '')
select @denctcomp=isnull(Denumire_cont,'') from conturi where cont=@ctcomp
Set @stergcomp = ISNULL(@parXML.value('(/parametri/@stergcomp)[1]', 'int'), 0)
Set @gencomp = ISNULL(@parXML.value('(/parametri/@gencomp)[1]', 'int'), 0)
Set @tert = ISNULL(@parXML.value('(/parametri/@tertfiltru)[1]', 'char(20)'), '')
select @dentert=isnull(Denumire,'') from terti where tert=@tert

begin try
	if @stergcomp=0 and @gencomp=0
		raiserror('Bifati macar optiunea "Generare..."!' ,16,1)
	if isnull(@idcomp,'')=''
		raiserror('Completati nr. / identificator doc.!' ,16,1)
	if not exists (select 1 from conturi where cont=@ctcomp and Are_analitice=0)
		raiserror('Cont inexistent sau cu analitice!' ,16,1)
	if isnull(@tert,'')<>'' and not exists (select 1 from terti where tert=@tert)
		raiserror('Tert inexistent!' ,16,1)

	if @stergcomp=1 or @gencomp=1 exec GenerareCompensariEfecte @tipefecte=@tipefecte, 
		@datacomp=@datacomp, @idcomp=@idcomp, @ctcomp=@ctcomp, @stergerecomp=@stergcomp, 
		@generarecomp=@gencomp, @tert=@tert

	select 'Terminat operatie!' as textMesaj, 
		'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch  
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
