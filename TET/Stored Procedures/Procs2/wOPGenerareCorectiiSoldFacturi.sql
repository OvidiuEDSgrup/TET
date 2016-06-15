--***
Create procedure wOPGenerareCorectiiSoldFacturi @sesiune varchar(50), @parXML xml
as

declare @tipfact char(2),@soldfact float,@datacorectii datetime,@nrcorectii varchar(20),
@ctcorectii varchar(40),@jurnalcorectii varchar(3),@stergcorectii int,@gencorectii int,
@lmfiltru varchar(9),@tertfiltru varchar(13),@ctfactfiltru varchar(40),
@denlm varchar(80),@dentert varchar(80),@denctfact varchar(80),@denctcorectii varchar(80)--, @userASiS varchar(10)

--exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenerareCorectiiSoldFacturi'

Set @tipfact = ISNULL(@parXML.value('(/parametri/@tipfact)[1]', 'char(20)'), 'F')
Set @soldfact = ISNULL(@parXML.value('(/parametri/@soldfact)[1]', 'float'), 0)
Set @datacorectii = ISNULL(@parXML.value('(/parametri/@datacorectii)[1]', 'datetime'), '01/01/1901')
Set @nrcorectii = ISNULL(NULLIF(@parXML.value('(/parametri/@nrcorectii)[1]', 'varchar(20)'),''), 'COR'+@tipfact)
Set @ctcorectii = ISNULL(@parXML.value('(/parametri/@ctcorectii)[1]', 'varchar(40)'), '')
select @denctcorectii=isnull(Denumire_cont,'') from conturi where cont=@ctcorectii
Set @jurnalcorectii = ISNULL(@parXML.value('(/parametri/@jurnalcorectii)[1]', 'varchar(20)'), '')
Set @stergcorectii = ISNULL(@parXML.value('(/parametri/@stergcorectii)[1]', 'int'), 0)
Set @gencorectii = ISNULL(@parXML.value('(/parametri/@gencorectii)[1]', 'int'), 0)
Set @lmfiltru = ISNULL(@parXML.value('(/parametri/@lmfiltru)[1]', 'varchar(20)'), '')
select @denlm=isnull(Denumire,'') from lm where cod=@lmfiltru
Set @tertfiltru = ISNULL(@parXML.value('(/parametri/@tertfiltru)[1]', 'varchar(20)'), '')
select @dentert=isnull(Denumire,'') from terti where tert=@tertfiltru
Set @ctfactfiltru = ISNULL(@parXML.value('(/parametri/@ctfactfiltru)[1]', 'varchar(40)'), '')
select @denctfact=isnull(Denumire_cont,'') from conturi where cont=@ctfactfiltru

begin try
	if @stergcorectii=0 and @gencorectii=0
		raiserror('Bifati macar optiunea "Generare..."!' ,16,1)
	if @gencorectii=1 and @soldfact=0
		raiserror('Soldul nu poate fi nul!' ,16,1)
	if isnull(@nrcorectii,'')=''
		raiserror('Completati nr. / identificator doc.!' ,16,1)
	if not exists (select 1 from conturi where cont=@ctcorectii and Are_analitice=0)
		raiserror('Cont corectii inexistent sau cu analitice!' ,16,1)
	if isnull(@ctfactfiltru,'')<>'' and not exists (select 1 from conturi where cont=@ctfactfiltru and Are_analitice=0)
		raiserror('Cont facturi inexistent sau cu analitice!' ,16,1)
	if isnull(@tertfiltru,'')<>'' and not exists (select 1 from terti where tert=@tertfiltru)
		raiserror('Tert inexistent!' ,16,1)
	if isnull(@lmfiltru,'')<>'' and not exists (select 1 from lm where cod=@lmfiltru)
		raiserror('Loc de munca inexistent!' ,16,1)

	if @stergcorectii=1 or @gencorectii=1 exec GenerareCorectiiSoldFacturi @tipfact=@tipfact,
		@soldfact=@soldfact,@datacorectii=@datacorectii,@nrcorectii=@nrcorectii,
		@ctcorectii=@ctcorectii,@jurnalcorectii=@jurnalcorectii,
		@stergerecorectii=@stergcorectii,@generarecorectii=@gencorectii,
		@lmfiltru=@lmfiltru,@tertfiltru=@tertfiltru,@ctfactfiltru=@ctfactfiltru

	select 'Terminat operatie!' as textMesaj, 
		'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch  
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
