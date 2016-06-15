--***
Create procedure wOPGenNCSalarii @sesiune varchar(50), @parXML xml
as

declare @StergNCSalarii int, @StergNCTichete int, @StergNCZilieri int, @GenNCSalarii int, @GenNCTichete int, @GenNCZilieri int, 
@lm varchar(9), @denlm varchar(30), @datalunii datetime, @lunaalfa varchar(15), @luna int, @an int, @dataJos datetime, @dataSus datetime, @marca varchar(6), @densalariat varchar(50), 
@userASiS varchar(20), @lunabloc int,@anulbloc int, @databloc datetime, @nrLMFiltru int, @LMFiltru varchar(9)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenNCSalarii' 

set @StergNCSalarii = ISNULL(@parXML.value('(/parametri/@stergncsal)[1]', 'int'), 0)
set @StergNCTichete = ISNULL(@parXML.value('(/parametri/@stergnctich)[1]', 'int'), 0)
set @StergNCZilieri = ISNULL(@parXML.value('(/parametri/@stergnczilieri)[1]', 'int'), 0)
set @GenNCSalarii = ISNULL(@parXML.value('(/parametri/@genncsal)[1]', 'int'), 0)
set @GenNCTichete = ISNULL(@parXML.value('(/parametri/@gennctich)[1]', 'int'), 0)
set @GenNCZilieri = ISNULL(@parXML.value('(/parametri/@gennczilieri)[1]', 'int'), 0)

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

set @lunabloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNABLOC'), 1)
set @anulbloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULBLOC'), 1901)
if @lunabloc not between 1 and 12 or @anulbloc<=1901 
	set @databloc='01/01/1901'
else 
	set @databloc=dbo.eom(convert(datetime,str(@lunabloc,2)+'/01/'+str(@anulbloc,4)))

begin try  
	--BEGIN TRAN
	if @marca<>'' and @marca not in (select marca from personal)
		raiserror('Marca inexistenta!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm='' and 1=0
		raiserror('Filtrati un loc de de munca pentru generarea notei contabile!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm<>'' and @lm not in (select cod from LMfiltrare where utilizator=@userASiS)
		raiserror('Locul de munca filtrat nu se regaseste in lista de locuri de munca pe care aveti acces!' ,16,1)
	if @dataSus<=@databloc
		raiserror('Luna pe care doriti sa efectuati generarea notei contabile este blocata din punct de vedere contabil!' ,16,1)

	exec PSGenNCSalarii @dataJos=@dataJos, @dataSus=@dataSus, @pMarca=@Marca, 
		@StergNCSalarii=@StergNCSalarii, @StergNCTichete=@StergNCTichete, @StergNCZilieri=@StergNCZilieri, @GenNCSalarii=@GenNCSalarii, @GenNCTichete=@GenNCTichete, @GenNCZilieri=@GenNCZilieri, @ParteProc=0

	select 'S-a efectuat generarea notei contabile de salarii pt. luna '+rtrim(@lunaalfa)+' anul '+convert(char(4),year(@dataSus))+
	(case when @marca<>'' then ', pt. salariatul '+rtrim(@densalariat) else '' end)+
	(case when @lm<>'' then ', pt. locul de munca '+rtrim(@denlm) else '' end)+'!' as textMesaj, 
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
	--COMMIT TRAN
end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='(wOPGenNCSalarii) '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
