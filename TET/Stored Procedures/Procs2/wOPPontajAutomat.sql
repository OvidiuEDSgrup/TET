--***
Create procedure wOPPontajAutomat @sesiune varchar(50), @parXML xml
as

declare @datalunii datetime, @dataJos datetime, @dataSus datetime, @luna int, @an int, @lunaalfa varchar(15), @marca varchar(6), @lm varchar(9), @tipstat char(100), 
@GrupaMExceptata char(1), @PontajOresS int, @OresS char(1), @PontajOresD int, @OresD char(1), @StergerePontaj int, @GenerarePontaj int, 
@densalariat varchar(50), @denlm varchar(30), @userASiS varchar(20), @multiFirma int, 
@lunainch int,@anulinch int, @datainch datetime, @PontajZilnic int, @nrLMFiltru int, @LMFiltru varchar(9)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPPontajAutomat' 

select @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
if exists (select * from sysobjects where name ='par' and xtype='V')
	set @multiFirma=1

select @nrLMFiltru=count(1), @LMFiltru=isnull(min(Cod),'') from LMfiltrare where utilizator=@userASiS and cod in (select cod from lm where Nivel=1)
set @PontajZilnic=dbo.iauParL('PS','PONTZILN') 
set @datalunii = ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '')
set @luna = ISNULL(@parXML.value('(/parametri/@luna)[1]', 'int'), 0)
set @an = ISNULL(@parXML.value('(/parametri/@an)[1]', 'int'), 0)
if @luna<>0 and @an<>0
	set @datalunii=dbo.eom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
set @dataJos = @parXML.value('(/parametri/@dataj)[1]', 'datetime')
set @dataSus = @parXML.value('(/parametri/@datas)[1]', 'datetime')
if @PontajZilnic=0 or @dataJos is Null or @dataSus is Null
Begin
	set @dataJos = dbo.bom(@datalunii)
	set @dataSus = dbo.eom(@datalunii)
End
select @lunaalfa=LunaAlfa from fCalendar(@dataSus,@dataSus)
set @marca = ISNULL(@parXML.value('(/parametri/@marca)[1]', 'varchar(6)'), '')
set @lm = ISNULL(@parXML.value('(/parametri/@lm)[1]', 'varchar(9)'), '')
set @lm=(case when dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru=1 and not(@lm like rtrim(@lmfiltru)+'%') then @LMFiltru else @lm end)
select @densalariat=isnull(Nume,'') from personal where marca=@marca
select @denlm=isnull(Denumire,'') from lm where cod=@lm
set @tipstat = ISNULL(@parXML.value('(/parametri/@tipstat)[1]', 'varchar(100)'), '')
set @GrupaMExceptata = ISNULL(@parXML.value('(/parametri/@grupamexcep)[1]', 'char(1)'), '')
set @PontajOresS = ISNULL(@parXML.value('(/parametri/@poressamb)[1]', 'int'), 0)
set @OresS = ISNULL(@parXML.value('(/parametri/@tiporessamb)[1]', 'char(1)'), 0)
set @PontajOresD = ISNULL(@parXML.value('(/parametri/@poresdum)[1]', 'int'), 0)
set @OresD = ISNULL(@parXML.value('(/parametri/@tiporesdum)[1]', 'char(1)'), 0)
set @StergerePontaj = ISNULL(@parXML.value('(/parametri/@stergere)[1]', 'int'), 0)
set @GenerarePontaj = ISNULL(@parXML.value('(/parametri/@generare)[1]', 'int'), 0)

set @lunainch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
set @anulinch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
if @lunainch not between 1 and 12 or @anulinch<=1901 
	set @datainch='01/01/1901'
else 
	set @datainch=dbo.eom(convert(datetime,str(@lunainch,2)+'/01/'+str(@anulinch,4)))

begin try  
	--BEGIN TRAN
	if @multiFirma=1 and @lm=''
		raiserror('Nu ati selectat o unitate la intrarea in aplicatie!' ,16,1)
	if @marca<>'' and @marca not in (select marca from personal)
		raiserror('Marca inexistenta!' ,16,1)
	if @lm<>'' and @lm not in (select cod from lm)
		raiserror('Loc de munca inexistent!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm=''
		raiserror('Filtrati un loc de de munca pentru calcul!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm<>'' and @lm not in (select cod from LMfiltrare where utilizator=@userASiS)
		raiserror('Locul de munca filtrat nu se regaseste in lista de locuri de munca pe care aveti acces!' ,16,1)
	if @PontajOresS=1 and @OresS=''
		raiserror('Trebuie sa selectati tipul de ore suplimentare pt. orele pontate sambata!' ,16,1)
	if @PontajOresD=1 and @OresD=''
		raiserror('Trebuie sa selectati tipul de ore suplimentare pt. orele pontate duminica!' ,16,1)
	if @dataSus<=@datainch
		raiserror('Luna pe care doriti sa efectuati pontaj automat este inchisa!' ,16,1)

	exec generare_pontaj_automat @dataJos, @dataSus, @marca, @lm, @tipstat, @GrupaMExceptata, @PontajOresS, @OresS, @PontajOresD, @OresD, @StergerePontaj, @GenerarePontaj
	select 'S-a efectuat Pontajul automat pe luna '+rtrim(@lunaalfa)+' '+convert(char(4),year(@dataSus))+
	(case when @marca<>'' then ', pt. salariatul '+rtrim(@densalariat) else '' end)+
	(case when @lm<>'' then ', pt. locul de munca '+rtrim(@lm)+' - '+rtrim(@denlm) else '' end)+'!' as textMesaj, 
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
	--COMMIT TRAN
end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='(wOPPontajAutomat) '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
