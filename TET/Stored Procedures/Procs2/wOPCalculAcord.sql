--***
Create
procedure wOPCalculAcord @sesiune varchar(50), @parXML xml
as

declare @datalunii datetime, @dataJos datetime, @dataSus datetime, @luna int, @an int, @lunaalfa varchar(15), 
@lm varchar(9), @denlm varchar(30), @AcordIndividual int, @ValidarePontaj int, @AcordGlobal int, 
@userASiS varchar(20), @lunainch int,@anulinch int, @datainch datetime, @nrLMFiltru int, @LMFiltru varchar(9)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPCalculAcord' 

select @nrLMFiltru=count(1), @LMFiltru=isnull(min(Cod),'') from LMfiltrare where utilizator=@userASiS and cod in (select cod from lm where Nivel=1)
set @datalunii = ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '')
set @luna = ISNULL(@parXML.value('(/parametri/@luna)[1]', 'int'), 0)
set @an = ISNULL(@parXML.value('(/parametri/@an)[1]', 'int'), 0)
if @luna<>0 and @an<>0
	set @datalunii=dbo.eom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
set @dataJos = dbo.bom(@datalunii)
set @dataSus = dbo.eom(@datalunii)
Select @lunaalfa=LunaAlfa from fCalendar(@dataSus,@dataSus)

set @lm = ISNULL(@parXML.value('(/parametri/@lm)[1]', 'varchar(9)'), '')
set @lm=(case when dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru=1 then @LMFiltru else @lm end)
select @denlm=isnull(Denumire,'') from lm where cod=@lm
set @AcordIndividual = ISNULL(@parXML.value('(/parametri/@acordind)[1]', 'int'), 0)
set @ValidarePontaj = ISNULL(@parXML.value('(/parametri/@validpontaj)[1]', 'int'), 0)
set @AcordGlobal = ISNULL(@parXML.value('(/parametri/@acordglobal)[1]', 'int'), 0)

set @lunainch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
set @anulinch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
if @lunainch not between 1 and 12 or @anulinch<=1901 
	set @datainch='01/01/1901'
else 
	set @datainch=dbo.eom(convert(datetime,str(@lunainch,2)+'/01/'+str(@anulinch,4)))

begin try  
	--BEGIN TRAN
	if @lm<>'' and @lm not in (select cod from lm)
		raiserror('Loc de munca inexistent!' ,16,1)
	if @dataSus<=@datainch
		raiserror('Luna pe care doriti sa efectuati calculul de acord este inchisa!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm=''
		raiserror('Filtrati un loc de de munca pentru calcul!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm<>'' and @lm not in (select cod from LMfiltrare where utilizator=@userASiS)
		raiserror('Locul de munca filtrat nu se regaseste in lista de locuri de munca pe care aveti acces!' ,16,1)

	exec calcul_acord_salarii @dataJos, @dataSus, @AcordIndividual, @ValidarePontaj, @AcordGlobal, '', @lm

	select 'S-a efectuat calcul de acord pe luna '+rtrim(@lunaalfa)+' '+convert(char(4),year(@dataSus))+
	(case when @lm<>'' then ', pt. locul de munca '+rtrim(@denlm) else '' end)+'!' as textMesaj, 
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
	--COMMIT TRAN
end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='(wOPCalculAcord) '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
