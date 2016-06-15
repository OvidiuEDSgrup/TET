--***
Create procedure wOPGenerareCorectiiSoldEfecte @sesiune varchar(50), @parXML xml
as

declare @tipefecte char(2),@soldefecte float,@datacorectii datetime,@idcorectii varchar(20),
@ctcorectii varchar(40),@stergcorectii int,@gencorectii int,@tertfiltru varchar(13),
@dentert varchar(80),@denctcorectii varchar(80)--, @userASiS varchar(10)

--exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenerareCorectiiSoldEfecte'

Set @tipefecte = ISNULL(@parXML.value('(/parametri/@tipefecte)[1]', 'char(20)'), 'P')
Set @soldefecte = ISNULL(@parXML.value('(/parametri/@soldefecte)[1]', 'float'), 0)
Set @datacorectii = ISNULL(@parXML.value('(/parametri/@datacorectii)[1]', 'datetime'), '01/01/1901')
Set @idcorectii = ISNULL(@parXML.value('(/parametri/@idcorectii)[1]', 'varchar(20)'), 'COR'+@tipefecte)
Set @ctcorectii = ISNULL(@parXML.value('(/parametri/@ctcorectii)[1]', 'varchar(40)'), '')
select @denctcorectii=isnull(Denumire_cont,'') from conturi where cont=@ctcorectii
Set @stergcorectii = ISNULL(@parXML.value('(/parametri/@stergcorectii)[1]', 'int'), 0)
Set @gencorectii = ISNULL(@parXML.value('(/parametri/@gencorectii)[1]', 'int'), 0)
Set @tertfiltru = ISNULL(@parXML.value('(/parametri/@tertfiltru)[1]', 'varchar(20)'), '')
select @dentert=isnull(Denumire,'') from terti where tert=@tertfiltru

begin try
	if @stergcorectii=0 and @gencorectii=0
		raiserror('Bifati macar optiunea "Generare..."!' ,16,1)
	if @gencorectii=1 and @soldefecte=0
		raiserror('Soldul nu poate fi nul!' ,16,1)
	if isnull(@idcorectii,'')=''
		raiserror('Completati nr. / identificator doc.!' ,16,1)
	if not exists (select 1 from conturi where cont=@ctcorectii and Are_analitice=0)
		raiserror('Cont inexistent sau cu analitice!' ,16,1)
	if isnull(@tertfiltru,'')<>'' and not exists (select 1 from terti where tert=@tertfiltru)
		raiserror('Tert inexistent!' ,16,1)

	if @stergcorectii=1 or @gencorectii=1 exec GenerareCorectiiSoldEfecte @tipefecte=@tipefecte,
		@soldefecte=@soldefecte,@datacorectii=@datacorectii,@idcorectii=@idcorectii,
		@ctcorectii=@ctcorectii,@stergerecorectii=@stergcorectii,@generarecorectii=@gencorectii,
		@tertfiltru=@tertfiltru

	select 'Terminat operatie!' as textMesaj, 
		'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch  
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
