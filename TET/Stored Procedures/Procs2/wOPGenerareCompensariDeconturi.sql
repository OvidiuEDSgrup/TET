--***
Create procedure wOPGenerareCompensariDeconturi @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPGenerareCompensariDeconturiSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPGenerareCompensariDeconturiSP @sesiune, @parXML
	return @returnValue
end

declare @datacomp datetime, @idcomp varchar(20), @jurnalcomp varchar(3),
	@stergcomp int, @gencomp int, @ctcomp varchar(40), @ctexceptie varchar(40), @lm varchar(9), @marca varchar(6), @ctdecont varchar(40), 
	@denlm varchar(80), @densalariat varchar(80), @denctdecont varchar(80)--, @userASiS varchar(10)

--exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenerareCompensariDeconturi'

Set @datacomp = ISNULL(@parXML.value('(/parametri/@datacomp)[1]', 'datetime'), '01/01/1901')
Set @idcomp = ISNULL(@parXML.value('(/parametri/@idcomp)[1]', 'varchar(20)'), 'CMP')
Set @jurnalcomp = ISNULL(@parXML.value('(/parametri/@jurnalcomp)[1]', 'varchar(20)'), '')
Set @stergcomp = ISNULL(@parXML.value('(/parametri/@stergcomp)[1]', 'int'), 0)
Set @gencomp = ISNULL(@parXML.value('(/parametri/@gencomp)[1]', 'int'), 0)
Set @ctcomp = ISNULL(@parXML.value('(/parametri/@ctcomp)[1]', 'varchar(40)'), '')
Set @ctexceptie = ISNULL(@parXML.value('(/parametri/@ctexceptie)[1]', 'varchar(40)'), '')
Set @lm = ISNULL(@parXML.value('(/parametri/@lm)[1]', 'varchar(20)'), '')
select @denlm=isnull(Denumire,'') from lm where cod=@lm
Set @marca = ISNULL(@parXML.value('(/parametri/@marca)[1]', 'varchar(6)'), '')
select @densalariat=isnull(Nume,'') from personal where marca=@marca
Set @ctdecont = ISNULL(@parXML.value('(/parametri/@ctdecont)[1]', 'varchar(40)'), '')
select @denctdecont=isnull(Denumire_cont,'') from conturi where cont=@ctdecont

begin try
	if @stergcomp=0 and @gencomp=0
		raiserror('Bifati macar optiunea "Generare..."!' ,16,1)
	if isnull(@idcomp,'')=''
		raiserror('Completati nr. / identificator doc.!' ,16,1)
	if isnull(@ctcomp,'')='' 
		raiserror('Cont compensare necompletat!' ,16,1)
	if isnull(@ctcomp,'')<>'' and not exists (select 1 from conturi where cont=@ctcomp)
		raiserror('Cont compensare inexistent sau cu analitice!' ,16,1)
	if isnull(@ctdecont,'')<>'' and not exists (select 1 from conturi where cont=@ctdecont and Are_analitice=0)
		raiserror('Cont deconturi inexistent sau cu analitice!' ,16,1)
	if isnull(@marca,'')<>'' and not exists (select 1 from personal where marca=@marca)
		raiserror('Marca inexistenta!' ,16,1)
	if isnull(@lm,'')<>'' and not exists (select 1 from lm where cod=@lm)
		raiserror('Loc de munca inexistent!' ,16,1)

	if @stergcomp=1 or @gencomp=1 
		exec GenerareCompensariDeconturi 
			@tipdecont='T', @stergerecomp=@stergcomp, @generarecomp=@gencomp, @datacomp=@datacomp, @idcomp=@idcomp, 
			@jurnalcomp=@jurnalcomp, @ctcomp=@ctcomp, @marca=@marca, @lm=@lm, @ctdecont=@ctdecont, @ctexceptie=@ctexceptie

	select 'Terminat operatie!' as textMesaj, 
		'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch  
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
