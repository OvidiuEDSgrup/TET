--***
Create
procedure wOPCalculAvans @sesiune varchar(50), @parXML xml
as

declare @datalunii datetime, @dataJos datetime, @dataSus datetime, @luna int, @an int, @lunaalfa varchar(15), 
@marca varchar(6), @densalariat varchar(50), @lm varchar(9), @denlm varchar(30), @LocmJ varchar(9), @LocmS varchar(9), @Strict int, 
@GenerareCorI int, @Avans0Plecati int, @userASiS varchar(20), @multiFirma int, @lunainch int,@anulinch int, @datainch datetime, @nrLMFiltru int, @LMFiltru varchar(9)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPCalculAvans' 

select @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
if exists (select * from sysobjects where name ='par' and xtype='V')
	set @multiFirma=1

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
set @lm = ISNULL(@parXML.value('(/parametri/@lm)[1]', 'varchar(9)'), '')
set @lm=(case when dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru=1 then @LMFiltru else @lm end)
set @LocmJ=@lm
set @LocmS=rtrim(@lm)+(case when @Strict=1 then '' else 'ZZZ' end)
set @strict = ISNULL(@parXML.value('(/parametri/@strict)[1]', 'int'), 0)
select @densalariat=isnull(Nume,'') from personal where marca=@marca
select @denlm=isnull(Denumire,'') from lm where cod=@lm
set @GenerareCorI = ISNULL(@parXML.value('(/parametri/@genpremiu)[1]', 'int'), 0)
set @Avans0Plecati = ISNULL(@parXML.value('(/parametri/@genavans0)[1]', 'int'), 0)

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
	if @lm<>'' and @lm not in (select cod from lm)
		raiserror('Loc de munca inexistent!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm='' and @marca=''
		raiserror('Filtrati un loc de de munca pentru calcul!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm<>'' and @marca='' 
		and @lm not in (select cod from LMfiltrare where utilizator=@userASiS)
		raiserror('Locul de munca filtrat nu se regaseste in lista de locuri de munca pe care aveti acces!' ,16,1)
	if @dataSus<=@datainch
		raiserror('Luna pe care doriti sa efectuati calculul de avans este inchisa!' ,16,1)

	exec calcul_avans_salarii @dataJos, @dataSus, @marca, @LocmJ, @LocmS, @GenerareCorI, @Avans0Plecati
	select 'S-a efectuat calcul de avans pe luna '+rtrim(@lunaalfa)+' '+convert(char(4),year(@dataSus))+
	(case when @marca<>'' then ', pt. salariatul '+rtrim(@densalariat) else '' end)+
	(case when @lm<>'' then ', pt. locul de munca '+rtrim(@denlm) else '' end)+'!' as textMesaj, 
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
	--COMMIT TRAN
end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='(wOPCalculAvans) '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
