--***
Create procedure wOPRefacereNoteBugetari @sesiune varchar(50), @parXML xml
as

declare @userASiS varchar(10), @datajos datetime, @datasus datetime, @angBugetare int, @ordonantari int, @op int, @indbug char(20)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPRefacereNoteBugetari'

Set @datajos = ISNULL(@parXML.value('(/parametri/@datajos)[1]', 'datetime'), '01/01/1901')
Set @datasus = ISNULL(@parXML.value('(/parametri/@datasus)[1]', 'datetime'), '12/31/2999')
Set @indbug = ISNULL(@parXML.value('(/parametri/@indbug)[1]', 'varchar(20)'), '')
Set @angBugetare = ISNULL(@parXML.value('(/parametri/@angbug)[1]', 'int'), 0)
Set @ordonantari = ISNULL(@parXML.value('(/parametri/@ordonantari)[1]', 'int'), 0)
Set @op = ISNULL(@parXML.value('(/parametri/@op)[1]', 'int'), 0)

begin try
	if @indbug<>'' and not exists (select 1 from indbug where indbug=@indbug)
		raiserror('Indicator bugetar inexistent!' ,16,1)

	exec RefacereNoteALOP @dataJos=@datajos, @dataSus=@dataSus, @indicator=@indbug, @AngBugetare=@AngBugetare, @Ordonantari=@Ordonantari, @OP=@OP
	
	select 'Terminat operatie!' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch  
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()+' ('+ OBJECT_NAME(@@PROCID)+')'
	raiserror(@eroare, 16, 1) 
end catch
