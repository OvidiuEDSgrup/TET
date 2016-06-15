--***
Create procedure wOPInchidereLunaPS @sesiune varchar(50), @parXML xml
as

declare @datalunii datetime, @luna int, @an int, @dataJos datetime, @dataSus datetime, @lunaalfa varchar(15), @marca varchar(6), @densalariat varchar(50), 
	@PreluareVechime int, @PreluareSporVechime int, @PreluareSporSpecific int, @PreluareRetineri int, @PreluareAvans int, 
	@PreluarePersintr int, @PreluareCorectiiLocm int, @PreluareCOneefect int, @PreluarePensiiFac int, @PreluareParLunari int, 
	@userASiS varchar(20), @lunainch int,@anulinch int, @datainch datetime, @err int, @nrLMFiltru int, @multiFirma int, @LMFiltru varchar(9), @parXMLAlerte xml

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPInchidereLunaPS' 

set @LMFiltru=''
select @nrLMFiltru=count(1), @LMFiltru=isnull(min(Cod),'') from LMfiltrare where utilizator=@userASiS and cod in (select cod from lm where Nivel=1)

set @datalunii = ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '')
set @luna = ISNULL(@parXML.value('(/parametri/@luna)[1]', 'int'), 0)
set @an = ISNULL(@parXML.value('(/parametri/@an)[1]', 'int'), 0)
if @luna<>0 and @an<>0
	set @datalunii=dbo.eom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
set @dataJos = dbo.bom(@datalunii)
set @dataSus = dbo.eom(@datalunii)
set @marca = ISNULL(@parXML.value('(/parametri/@marca)[1]', 'varchar(6)'), '')
select @densalariat=isnull(Nume,'') from personal where marca=@marca
set @PreluareVechime = ISNULL(@parXML.value('(/parametri/@prelvech)[1]', 'int'), 0)
set @PreluareSporVechime = ISNULL(@parXML.value('(/parametri/@prelspvech)[1]', 'int'), 0)
set @PreluareSporSpecific = ISNULL(@parXML.value('(/parametri/@prelspspec)[1]', 'int'), 0)
set @PreluareRetineri = ISNULL(@parXML.value('(/parametri/@prelretineri)[1]', 'int'), 0)
set @PreluareAvans = ISNULL(@parXML.value('(/parametri/@prelavans)[1]', 'int'), 0)
set @PreluarePersintr = ISNULL(@parXML.value('(/parametri/@prelpersintr)[1]', 'int'), 0)
set @PreluareCorectiiLocm = ISNULL(@parXML.value('(/parametri/@prelcorlm)[1]', 'int'), 0)
set @PreluareCOneefect = ISNULL(@parXML.value('(/parametri/@prelconeef)[1]', 'int'), 0)
set @PreluarePensiiFac = ISNULL(@parXML.value('(/parametri/@prelpensiif)[1]', 'int'), 0)
set @PreluareParLunari = ISNULL(@parXML.value('(/parametri/@prelparlun)[1]', 'int'), 0)

select @lunaalfa=LunaAlfa from fCalendar(@dataSus,@dataSus)
set @lunainch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
set @anulinch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
if @lunainch not between 1 and 12 or @anulinch<=1901 
	set @datainch='01/01/1901'
else 
	set @datainch=dbo.eom(convert(datetime,str(@lunainch,2)+'/01/'+str(@anulinch,4)))

begin try  
	--BEGIN TRAN
	if @marca<>'' and @marca not in (select marca from personal)
		raiserror('Marca inexistenta!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>0 and @multiFirma=0
		raiserror('Utilizatorii ce au proprietatea LOCMUNCA nu pot executa inchiderea de luna!' ,16,1)
	if @dataSus<=@datainch
		raiserror('Luna pe care doriti sa o inchideti este inchisa deja! Verificati care este ultima luna initializata!' ,16,1)
	if @dataSus>dbo.bom(DateAdd(month,2,@datainch))
		raiserror('Nu puteti face inchidere pentru aceasta luna! Verificati care este ultima luna initializata!' ,16,1)

	exec psInchidere_luna @dataJos, @dataSus, @marca, @PreluareVechime, @PreluareSporVechime, @PreluareSporSpecific, 
		@PreluareRetineri, @PreluareAvans, @PreluarePersintr, @PreluareCorectiiLocm, @PreluareCOneefect, @PreluarePensiiFac, @PreluareParLunari

	select 'S-a efectuat inchiderea de luna '+rtrim(@lunaalfa)+' '+convert(char(4),year(@dataSus))+'!' as textMesaj, 
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')

	if exists (select 1 from sys.objects where name='wOPPrefiltrareAlerteSalarii' and type='P')  
	begin
		declare @dataInchNext datetime
		set @dataInchNext=DateADD(month,1,@datainch)
		set @parXMLAlerte=(select month(@dataInchNext) as luna, year(@dataInchNext) as an, 'T' as tipalerta, 
			(case when @PreluareSporSpecific=1 then 1 else 0 end) as inchidereluna for xml raw)
		exec wOPPrefiltrareAlerteSalarii @sesiune=@sesiune, @parXML=@parXMLAlerte
	end

	--COMMIT TRAN
end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='(wOPInchidereLunaPS) '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
