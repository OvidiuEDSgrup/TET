--***
Create
procedure wOPCalculCO @sesiune varchar(50), @parXML xml
as
Begin
	declare @datalunii datetime, @dataJos datetime, @dataSus datetime, @luna int, @an int, @lunaalfa varchar(15), 
	@marca varchar(6), @densalariat varchar(50), @lm varchar(9), @denlm varchar(30), 
	@CalculPrimaV int, @ProcentPrimaV int, @StergCONetAnt int, @CalculCOnet int, @CalculCOnetPrimaV int, @lDataOperarii int, @dDataOperarii datetime, 
	@CalculCOnetFDP int, @RecalculCOLuniant int, @userASiS varchar(20), @lunainch int,@anulinch int, @datainch datetime, @nrLMFiltru int, @LMFiltru varchar(9)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPCalculCO' 

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
	Set @CalculPrimaV = ISNULL(@parXML.value('(/parametri/@calcprimav)[1]', 'int'), 0)
	Set @ProcentPrimaV = ISNULL(@parXML.value('(/parametri/@procprimav)[1]', 'int'), 0)
	Set @StergCONetAnt = ISNULL(@parXML.value('(/parametri/@stergconet)[1]', 'int'), 0)
	Set @CalculCOnet = ISNULL(@parXML.value('(/parametri/@calcconet)[1]', 'int'), 0)
	Set @CalculCOnetPrimaV = ISNULL(@parXML.value('(/parametri/@calcconetprv)[1]', 'int'), 0)
	Set @lDataOperarii = ISNULL(@parXML.value('(/parametri/@odataop)[1]', 'int'), 0)
	Set @dDataOperarii = ISNULL(@parXML.value('(/parametri/@dataop)[1]', 'datetime'), '')
	Set @CalculCOnetFDP = ISNULL(@parXML.value('(/parametri/@calcconetfdp)[1]', 'int'), 0)
	Set @RecalculCOLuniant = ISNULL(@parXML.value('(/parametri/@recalccolant)[1]', 'int'), 0)

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
		if @marca<>'' and @marca not in (select p.marca from personal p 
			where (dbo.f_areLMFiltru(@userASiS)=0 or p.loc_de_munca in (select cod from LMfiltrare where utilizator=@userASiS)))
			raiserror('Marca selectata nu este incadrata pe un loc de munca din lista de locuri de munca pe care aveti acces!' ,16,1)
		if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm='' and @marca=''
			raiserror('Filtrati un loc de de munca pentru calcul!' ,16,1)
		if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm<>'' and @marca='' 
			and @lm not in (select cod from LMfiltrare where utilizator=@userASiS)
			raiserror('Locul de munca filtrat nu se regaseste in lista de locuri de munca pe care aveti acces!' ,16,1)
		if @dataSus<=@datainch
			raiserror('Luna pe care doriti sa efectuati calcul concedii de odihna este inchisa!' ,16,1)

		exec calcul_concedii_de_odihna @dataJos, @dataSus, @marca, '01/01/1901', 0, 0, @lm, 
		@CalculPrimaV, @ProcentPrimaV, @CalculCOnet, @CalculCOnetPrimaV, 
		@lDataOperarii, @dDataOperarii, @CalculCOnetFDP, @RecalculCOLuniant, @StergCONetAnt

		exec setare_par 'PS', 'CO-NETFDP', 'Calcul CO net fara ded. pers', @CalculCONetFDP, 0, ''
		exec setare_par 'PS', 'CO-RCIT78', 'Recalcul indemniz. tip 7 si 8', @RecalculCOLuniant, 0, ''

		select 'S-a efectuat calcul de concedii de odihna pt. luna '+rtrim(@lunaalfa)+' anul '+convert(char(4),year(@dataSus))+
		(case when @marca<>'' then ', pt. salariatul '+rtrim(@densalariat) else '' end)+'!' as textMesaj, 
		'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
	--COMMIT TRAN
	end try  

	begin catch  
	--ROLLBACK TRAN
		declare @eroare varchar(254) 
		set @eroare='(wOPCalculCO) '+ERROR_MESSAGE()
		raiserror(@eroare, 16, 1) 
	end catch
End
