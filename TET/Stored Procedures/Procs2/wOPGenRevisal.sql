--***
Create procedure wOPGenRevisal @sesiune varchar(50), @parXML xml
as

declare @dataregistru datetime, @oMarca int, @Marca varchar(6), @unLm int, @lm varchar(9), 
@oSub int, @cSub varchar(9), @tipsocietate varchar(60), @CodFiscalParinte varchar(13), @DenAngParinte varchar(100), @reprlegal varchar(100), 
@inXML int, @cDirector varchar(254), @datalunii datetime, @lunaalfa varchar(15), @luna int, @an int, @dataJos datetime, @dataSus datetime, 
@userASiS varchar(20), @nrLMFiltru int, @LMFiltru varchar(9), @parXMLValidari xml

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenRevisal' 

set @oSub=0
set @cSub=dbo.iauParA('GE','SUBPRO')
set @dataregistru = ISNULL(@parXML.value('(/parametri/@dataregistru)[1]', 'datetime'), '')
set @Marca = ISNULL(@parXML.value('(/parametri/@marca)[1]', 'varchar(6)'), '')
set @oMarca=(case when @Marca<>'' then 1 else 0 end)
set @lm = ISNULL(@parXML.value('(/parametri/@lm)[1]', 'varchar(9)'), '')
set @unLm=(case when @Lm<>'' then 1 else 0 end)
set @tipsocietate = ISNULL(@parXML.value('(/parametri/@tipsoc)[1]', 'varchar(60)'), '')
set @CodFiscalParinte =  ISNULL(@parXML.value('(/parametri/@codfiscpar)[1]', 'varchar(13)'), '')
set @DenAngParinte =  ISNULL(@parXML.value('(/parametri/@denangpar)[1]', 'varchar(100)'), '')
set @reprlegal = ISNULL(@parXML.value('(/parametri/@reprlegal)[1]', 'varchar(100)'), '')

set @inXML=1
set @cDirector=(select top 1 val_alfanumerica from par where Tip_parametru='AR' and Parametru='CALEFORM')

select @nrLMFiltru=count(1), @LMFiltru=isnull(min(Cod),'') from LMfiltrare where utilizator=@userASiS and cod in (select cod from lm where Nivel=1)
set @datalunii = ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '')
set @luna = ISNULL(@parXML.value('(/parametri/@luna)[1]', 'int'), 0)
set @an = ISNULL(@parXML.value('(/parametri/@an)[1]', 'int'), 0)
if @luna<>0 and @an<>0
	set @datalunii=dbo.eom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
set @dataJos = dbo.bom(@datalunii)
set @dataSus = dbo.eom(@datalunii)
select @lunaalfa=LunaAlfa from fCalendar(@dataSus,@dataSus)

if exists (select 1 from sys.objects where name='wOPGenRevisalSP1' and type='P')  
	exec wOPGenRevisalSP1 @sesiune, @parXML

set @parXMLValidari=(select convert(char(10),@datajos,101) as datajos, convert(char(10),@datasus,101) as datasus, 'RV' as tipvalidare for xml raw)
if exists (select 1 from sys.objects where name='wOPPrefiltrareVerificariDLSalarii' and type='P')  
	exec wOPPrefiltrareVerificariDLSalarii @sesiune, @parXMLValidari

begin try  
--	BEGIN TRAN
--	validari
	if @marca<>'' and @marca not in (select marca from personal)
		raiserror('Marca inexistenta!' ,16,1)
	if @marca<>'' and @marca not in (select p.marca from personal p 
		where (dbo.f_areLMFiltru(@userASiS)=0 or p.loc_de_munca in (select cod from LMfiltrare where utilizator=@userASiS)))
		raiserror('Marca selectata nu este incadrata pe un loc de munca din lista de locuri de munca pe care aveti acces!' ,16,1)
	if @lm<>'' and @lm not in (select cod from lm)
		raiserror('Loc de munca inexistent!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm='' and @marca=''
		raiserror('Filtrati un loc de de munca pentru generare registru electronic!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm<>'' and @marca='' 
		and @lm not in (select cod from LMfiltrare where utilizator=@userASiS)
		raiserror('Locul de munca filtrat nu se regaseste in lista de locuri de munca pe care aveti acces!' ,16,1)

--	salvare parametrii 
	exec setare_par 'PS', 'ITMTIPSOC', 'Tip societate pentru ITM', 1, 0, @tipsocietate
	exec setare_par 'PS', 'ITMCODFP', 'Cod fiscal parinte pentru ITM', 1, 0, @CodFiscalParinte
	exec setare_par 'PS', 'ITMDENPAR', 'Denumire parinte pentru ITM', 1, 0, @DenAngParinte
	exec setare_par 'PS', 'ITMNUME', 'Reprezentant legal pentru ITM', 1, 0, @reprlegal

	exec genRevisal
		@dataJos, 
		@dataSus, 
		@dataregistru,
		@oMarca, @Marca, 
		@unLm, @Lm, 0, 
		'',	--filtru Sir de marci
		0, '', '', -- filtru data angajarii/plecarii
		0, '', '', -- filtru data modificarii
		@oSub, @cSub, 
		@tipsocietate, -- Tip societate (SediuSocial, Filiala, Sucursala)
		@ReprLegal, -- reprezentant legal
		@cDirector, -- cale generare fisier XML
		@inXML

	select 'S-a efectuat generarea registrului electronic in vigoare la data de '+convert(char(10),@dataregistru,103)+'!' as textMesaj, 
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
--	COMMIT TRAN
end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='(wOPGenRevisal) '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
