--***
Create procedure wOPGenerareIntrastat @sesiune varchar(50), @parXML xml
as

declare @flux char(1), @tipdecl char(1), @nume_persct varchar(150), @prenume_persct varchar(50), @functie_persct varchar(50), @telefon_persct varchar(150), @fax_persct varchar(50), @email_persct varchar(50), 
	@luna int, @an int, @lunaalfa varchar(15), @datajos datetime, @datasus datetime, @calefisier varchar(300), 
	@userASiS varchar(10), @nrLMFiltru int, @LMFiltru varchar(9)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenerareIntrastat'

set @flux = ISNULL(@parXML.value('(/parametri/@flux)[1]', 'char(1)'), 'I')
set @tipdecl = ISNULL(@parXML.value('(/parametri/@tipdecl)[1]', 'char(1)'), 'N')
set @nume_persct = ISNULL(@parXML.value('(/parametri/@numepersct)[1]', 'varchar(150)'), '')
set @prenume_persct = ISNULL(@parXML.value('(/parametri/@prenpersct)[1]', 'varchar(50)'), '')
set @functie_persct = ISNULL(@parXML.value('(/parametri/@functiepersct)[1]', 'varchar(50)'), '')
set @telefon_persct = ISNULL(@parXML.value('(/parametri/@telpersct)[1]', 'varchar(50)'), '')
set @fax_persct = ISNULL(@parXML.value('(/parametri/@faxpersct)[1]', 'varchar(50)'), '')
set @email_persct = ISNULL(@parXML.value('(/parametri/@emailpersct)[1]', 'varchar(50)'), '')
set @luna = ISNULL(@parXML.value('(/parametri/@luna)[1]', 'int'), 0)
set @an = ISNULL(@parXML.value('(/parametri/@an)[1]', 'int'), 0)
exec luare_date_par 'AR', 'CALEFORM', 0, 0, @calefisier output
select @calefisier=rtrim(@calefisier)

if @luna<>0 and @an<>0
begin
	set @datajos=dbo.bom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
	set @datasus=dbo.eom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
end
select @lunaalfa=LunaAlfa from fCalendar(@datajos,@datajos)
select @nrLMFiltru=count(1), @LMFiltru=isnull(max(Cod),'') from LMfiltrare where utilizator=@userASiS

begin try  
	/*if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>0
		raiserror('Nu puteti efectua operatia fiindca aveti drepturi de acces doar pe anumite locuri de munca!' ,16,1)
	*/		
	if @luna=0 or @an=0
		raiserror('Alegeti luna si anul!' ,16,1)
			
	if rtrim(left(@calefisier,4))='' 
		raiserror('Completati cale fisier in parametri!' ,16,1)
			
	if @nume_persct='' or @prenume_persct='' or @functie_persct=''
		raiserror('Completati nume, prenume si functie persoana de contact!' ,16,1)
			
	exec genAnexaDeclaratieIntrastat @sesiune=@sesiune, @datajos=@datajos, @datasus=@datasus, @flux=@flux, @tipdecl=@tipdecl, 
		@nume_persct=@nume_persct, @prenume_persct=@prenume_persct, @functie_persct=@functie_persct, 
		@telefon_persct=@telefon_persct, @fax_persct=@fax_persct, @email_persct=@email_persct, 
		@dinRia=1, @caleFisier=@calefisier

	exec setare_par 'EI', 'NUMEPCT', 'Nume pers. contact intrastat', 0, 0, @nume_persct
	exec setare_par 'EI', 'PRNUMEPCT', 'Prenume pers. contact intrastat', 0, 0, @prenume_persct
	exec setare_par 'EI', 'POZPCT', 'Functie pers.contact intrastat', 0, 0, @functie_persct
	exec setare_par 'EI', 'TELPCT', 'Telefon pers.contact intrastat', 0, 0, @telefon_persct
	exec setare_par 'EI', 'FAXPCT', 'Fax pers.contact intrastat', 0, 0, @fax_persct
	exec setare_par 'EI', 'EMAILPCT', 'Email pers.contact intrastat', 0, 0, @email_persct

	declare @dateInitializare XML
	set @dateInitializare='<row data="'+convert(char(10),@datasus,101)+'" flux="'+rtrim(@flux)+'" faramesaj="1'+' "/>'

	select 'Afisare erori intrastat' nume, 'YL' codmeniu, 'D' tipmacheta, 'YS' tip, 'EI' subtip,'O' fel,
		(SELECT @dateInitializare ) dateInitializare
	for xml raw('deschideMacheta'), ROOT('Mesaje')

	select 'Terminat operatia'+/*rtrim(@lunaalfa)+' anul '+convert(char(4),year(@datas))+*/'!' 
		as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch  
	declare @eroare varchar(1000) 
	set @eroare=ERROR_MESSAGE()+' (wOPGenerareIntrastat)'
	raiserror(@eroare, 16, 1) 
end catch
