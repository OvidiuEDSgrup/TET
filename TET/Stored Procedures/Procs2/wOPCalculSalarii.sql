--***
Create procedure wOPCalculSalarii @sesiune varchar(50), @parXML xml
as

declare @CalculAcord int, @CalculCO int, @CalculCM int, @CalculLichidare int, @CalculBrutNet int, @Precizie int, @GenDimL118 int, @GenerareNC int, 
	@marca varchar(6), @densalariat varchar(50), @lm varchar(9), @denlm varchar(30), 
	@luna int, @an int, @dataJos datetime, @dataSus datetime, @datalunii datetime, @lunaalfa varchar(15), 
	@userASiS varchar(20), @multiFirma int, @lunainch int,@anulinch int, @datainch datetime, @nrLMFiltru int, @LMFiltru varchar(9)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPCalculSalarii' 

select @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
if exists (select * from sysobjects where name ='par' and xtype='V')
	set @multiFirma=1

set @CalculCO = ISNULL(@parXML.value('(/parametri/@calculco)[1]', 'int'), 0)
set @CalculCM = ISNULL(@parXML.value('(/parametri/@calculcm)[1]', 'int'), 0)
set @CalculAcord = ISNULL(@parXML.value('(/parametri/@calculacord)[1]', 'int'), 0)
set @CalculLichidare = ISNULL(@parXML.value('(/parametri/@calcullich)[1]', 'int'), 0)
set @CalculBrutNet = ISNULL(@parXML.value('(/parametri/@cbrutnet)[1]', 'int'), 0)
set @Precizie = ISNULL(@parXML.value('(/parametri/@precizie)[1]', 'int'), 0)
set @GenDimL118 = ISNULL(@parXML.value('(/parametri/@gendiml118)[1]', 'int'), 0)
set @GenerareNC = ISNULL(@parXML.value('(/parametri/@genncsal)[1]', 'int'), 0)

select @nrLMFiltru=count(1), @LMFiltru=isnull(min(Cod),'') from LMfiltrare where utilizator=@userASiS and cod in (select cod from lm where Nivel=1)
set @datalunii = ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '')
set @luna = ISNULL(@parXML.value('(/parametri/@luna)[1]', 'int'), 0)
set @an = ISNULL(@parXML.value('(/parametri/@an)[1]', 'int'), 0)
if @luna<>0 and @an<>0
	set @datalunii=dbo.eom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
set @dataJos = dbo.bom(@datalunii)
set @dataSus = dbo.eom(@datalunii)
select @lunaalfa=LunaAlfa from fCalendar(@dataSus,@dataSus)
set @marca = ISNULL(@parXML.value('(/parametri/@marca)[1]', 'varchar(6)'), '')
select @densalariat=isnull(Nume,'') from personal where marca=@marca
set @lm = ISNULL(@parXML.value('(/parametri/@lm)[1]', 'varchar(9)'), '')
set @lm=(case when dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru=1 then @LMFiltru else @lm end)
select @denlm=isnull(Denumire,'') from lm where cod=@lm

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
	if @marca<>'' and @marca not in (select p.marca from personal p 
		where (dbo.f_areLMFiltru(@userASiS)=0 or p.loc_de_munca in (select cod from LMfiltrare where utilizator=@userASiS)))
		raiserror('Marca selectata nu este incadrata pe un loc de munca din lista de locuri de munca pe care aveti acces!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm='' and @marca=''
		raiserror('Filtrati un loc de de munca pentru calcul!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm<>'' and @marca='' 
		and @lm not in (select cod from LMfiltrare where utilizator=@userASiS)
		raiserror('Locul de munca filtrat nu se regaseste in lista de locuri de munca pe care aveti acces!' ,16,1)
	if @dataSus<=@datainch
		raiserror('Luna pe care doriti sa efectuati calcul salarii este inchisa!' ,16,1)

	exec psCalculSalarii @dataJos, @dataSus, @marca, @lm, @CalculCM, @CalculCO, @CalculAcord, @CalculLichidare, @CalculBrutNet, @Precizie, @GenDimL118
	if exists (select * from sysobjects where name ='wOPCalculSalariiSP1')
		exec wOPCalculSalariiSP1 @sesiune=@sesiune, @parXML=@parXML

	if @GenerareNC=1 and @marca='' and (@nrLMFiltru=0 or 1=1)
		exec PSGenNCSalarii @dataJos, @dataSus, '', 1, 1, 1, 1, 1, 1, 0

	select 'S-a efectuat calcul salarii pt. luna '+rtrim(@lunaalfa)+' anul '+convert(char(4),year(@dataSus))+
	(case when @marca<>'' then ', pt. salariatul '+rtrim(@densalariat) else '' end)+
	(case when @lm<>'' then ', pt. locul de munca '+rtrim(@denlm) else '' end)+'!' as textMesaj, 
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')

	declare @parXMLValidari xml
	set @parXMLValidari=(select convert(char(10),@datajos,101) as datajos, convert(char(10),@datasus,101) as datasus, 'CE,SI,DP,PE,NP,SN,' as tipvalidare for xml raw)
	if exists (select 1 from sys.objects where name='wOPPrefiltrareVerificariDLSalarii' and type='P')  
		exec wOPPrefiltrareVerificariDLSalarii @sesiune, @parXMLValidari

	--COMMIT TRAN
end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='(wOPCalculSalarii) '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
