--***
/**	procedura Formular pontaj	*/
Create
procedure [dbo].[psFormularPontaj] 
@DataJ datetime, @DataS datetime, @MarcaJ char(6), @MarcaS char(6), @pFunctie char(6), 
@LocmJ char(9), @LocmS char(9), @lTipStat int, @cTipStat char(10), @Ordonare int, @lGrupaM int, @cGrupaM char(1), 
@lGrupaMExcep int, @AreDreptCond int=1, @cListaCond char(1)='T', @SirMarci varchar(1000)=''
as
begin
	declare @Salimob int, @lDreptCond int, @OSNRN int, @O100RN int, @Colas int, @Data datetime, 
	@Marca char(6), @Nume char(50), @LocMunca char(9), @Nivel char(9), @DenumireNivel char(30), 
	@RegimL decimal(5,2), @DataAngajarii datetime, @Plecat int, @DataPlecarii datetime, @TotalOre int, 
	@OreLucrate int, @OreSuplimentare int, @OreNoapte int, @OreCO int, @OreCM int, @OreCFS int, @OreNemotivate int, 
	@OreINT int, @GrupLocm char(9), @Tip char(3), @cComanda varchar(1000), @HostID char(8)

	Set @lDreptCond=dbo.iauParL('PS','DREPTCOND')
	Set @OSNRN=dbo.iauParL('PS','OSNRN')
	Set @O100RN=dbo.iauParL('PS','O100NRN')
	Set @Salimob=dbo.iauParL('SP','SALIMOB')
	Set @Colas=dbo.iauParL('SP','COLAS')
	Set @HostID=isnull((select convert(char(8),abs(convert(int,host_id())))),'')

--	creare cursor in care se vor defalca orele pe zile pe orizontala
	If not exists (Select * from tempdb..sysobjects where name = '##FormularPontaj' and type = 'U') 
	Begin
		create table ##FormularPontaj (HostID char(8), Data datetime, Marca char(6), Nume char(50), Loc_de_munca char(9), Nivel char(9), Denumire_nivel char(30), RegimL decimal(5,2), Ziua1 char(4), Ziua2 char(4), Ziua3 char(4), Ziua4 char(4), Ziua5 char(4), Ziua6 char(4), Ziua7 char(4), Ziua8 char(4), Ziua9 char(4), Ziua10 char(4), Ziua11 char(4), Ziua12 char(4), Ziua13 char(4), Ziua14 char(4), Ziua15 char(4), Ziua16 char(4), Ziua17 char(4), Ziua18 char(4), Ziua19 char(4), Ziua20 char(4), Ziua21 char(4), Ziua22 char(4), Ziua23 char(4), 
		Ziua24 char(4), Ziua25 char(4), Ziua26 char(4), Ziua27 char(4), Ziua28 char(4), Ziua29 char(4), Ziua30 char(4), Ziua31 char(4),
		Total_Ore int, Ore_lucrate int, Ore_suplimentare int, Ore_de_noapte int, Ore_CO int, Ore_CM int, Ore_CFS int, Ore_nemotivate int, 
		Ore_INT int, Grup_locm char(9))
		Create Unique Clustered Index [Data_Marca] ON ##FormularPontaj (HostID Asc, Data Asc, Marca Asc)
	End

--	creez cursor prin detalierea la nivel de marca pe zile pe verticala (left outer join pe fCalendar(@DataJ, @DataS)
	declare FormPontaj cursor for
	select s.Data, a.Marca, a.Nume, (case when @Salimob=1 then left(a.Loc_de_munca,2) else a.Loc_de_munca end) as Loc_munca, 
	c.Nivel, c.Denumire, (case when isnull(pr.Valoare,'')<>'' and a.Grupa_de_munca<>'C' then convert(int,pr.Valoare) when a.Salar_lunar_de_baza=0 then 8 else a.Salar_lunar_de_baza end), a.Data_angajarii_in_unitate, 
	convert(int, a.Loc_ramas_vacant), a.Data_plec, 
	isnull(p.Total_Ore,0), isnull(p.Ore_lucrate,0), isnull(p.Ore_suplimentare,0), isnull(p.Ore_de_noapte,0), 
	isnull(p.Ore_CO,0), isnull(p.Ore_CM,0), isnull(p.Ore_CFS,0), isnull(p.Ore_nemotivate,0), isnull(p.Ore_INT,0), 
	(case when @Ordonare<=2 then '' else a.Loc_de_munca end) as Grup_loc_de_munca
	from personal a
		left outer join dbo.fCalendar(@DataJ, @DataS) s on s.Data_lunii=@DataS
		left outer join infopers b on a.Marca=b.Marca 
		left outer join lm c on c.Cod=(case when @Salimob=1 then left(a.Loc_de_munca,2) else a.Loc_de_munca end)
		left outer join (select Marca, sum(Ore_regie+ore_acord+
		(case when @OSNRN=1 then 0 else Ore_suplimentare_1+Ore_suplimentare_2+Ore_suplimentare_3+Ore_suplimentare_4 end)+
		(case when @O100RN=1 then 0 else Ore_spor_100 end)+Ore_concediu_de_odihna+Ore_concediu_medical+Ore_concediu_fara_salar+ 
		Ore_nemotivate+Ore_intrerupere_tehnologica+Ore+(case when @Colas=1 then Spor_cond_8 else 0 end)) as Total_ore, 
		sum(Ore_regie+ore_acord) as Ore_lucrate, sum(Ore_suplimentare_1+Ore_suplimentare_2+Ore_suplimentare_3+Ore_suplimentare_4+Ore_spor_100) as Ore_suplimentare, 
		sum(Ore_de_noapte) as Ore_de_noapte, sum(Ore_concediu_de_odihna) as Ore_CO, sum(Ore_concediu_medical) as Ore_CM, 
		sum(Ore_concediu_fara_salar) as Ore_CFS, sum(Ore_nemotivate) as Ore_nemotivate, 
		sum(Ore_intrerupere_tehnologica+Ore+(case when @Colas=1 then Spor_cond_8 else 0 end)) as Ore_INT 
		from pontaj where data between @DataJ and @DataS Group by Marca) p on a.Marca=p.Marca
		left outer join proprietati pr on pr.tip='LM' and pr.cod_proprietate='REGIML' and pr.Cod=a.Loc_de_munca and pr.Valoare<>''
	where a.Marca between @MarcaJ and @MarcaS and (@pFunctie='' or a.Cod_functie=@pFunctie) 
		and a.Loc_de_munca between @LocmJ and @LocmS and (a.Loc_ramas_vacant=0 or a.Data_plec>=@DataJ) 
		and a.Data_angajarii_in_unitate<=@DataS and (@lTipStat=0 or b.Religia=@cTipStat)
		and (@lGrupaM=0 or (@lGrupaMExcep=0 and a.grupa_de_munca=@cGrupaM or @lGrupaMExcep=1 and a.grupa_de_munca<>@cGrupaM)) 
		and (@lDreptCond=0 or (@AreDreptCond=1 and (@cListaCond='T' or @cListaCond='C' and a.pensie_suplimentara=1 or @cListaCond='S' and a.pensie_suplimentara<>1)) or (@AreDreptCond=0 and a.pensie_suplimentara<>1)) 
		and (@SirMarci='' or charindex(','+rtrim(ltrim(a.marca))+',',rtrim(@SirMarci))>0)
	order by Grup_loc_de_munca, (case when @Ordonare in (1,3) then a.marca when @Ordonare in (2,4) then a.nume else a.nume end)

	open FormPontaj
	fetch next from FormPontaj into @Data,@Marca,@Nume,@LocMunca,@Nivel,@DenumireNivel,@RegimL,@DataAngajarii, 
	@Plecat, @DataPlecarii, @TotalOre, @OreLucrate, @OreSuplimentare, @OreNoapte, @OreCO, @OreCM, @OreCFS, 
	@OreNemotivate, @OreINT, @GrupLocm
	while @@fetch_status=0
	Begin
		select @Tip=''
--	inserare pozitie pe marca in cursor 
		if isnull((select count(1) from ##FormularPontaj where HostID=@HostID and Data=@DataS and Marca=@Marca),0)=0
			insert into ##FormularPontaj values 
			(@HostID, @DataS, @Marca, @Nume, @LocMunca, @Nivel, @DenumireNivel, @RegimL, 
			'', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', @TotalOre, @OreLucrate, @OreSuplimentare, @OreNoapte, @OreCO, @OreCM, @OreCFS, @OreNemotivate, @OreINT, @GrupLocm)
		Select @Tip=Tip from fDate_pontaj_automat(@DataJ, @DataS, @Data, '', @Marca, 1) where tip<>'RL'
		Select @Tip=(case when DateName(weekday,@Data) in ('Saturday','Sunday') or @Data in (select Data from calendar) 
		or @Data<@DataAngajarii or @Plecat=1 and @Data>=@DataPlecarii then 'X' when isnull(@tip,'')='' 
		then (case when @RegimL>=1 then rtrim(convert(char(2),convert(int,@RegimL))) else rtrim(convert(char(5),@RegimL)) end) else @tip end)
--	creare comanda pentru updatarea cursorului pt. fiecare zi parcursa.
		Set @cComanda='update ##FormularPontaj set Ziua'+rtrim(convert(char(2),day(@Data)))+'='+char(39)+@Tip+char(39)+
		' where HostID='+@HostID+' and marca='+char(39)+@Marca+char(39)
		exec (@cComanda)

		fetch next from FormPontaj into @Data, @Marca, @Nume, @LocMunca, @Nivel, @DenumireNivel, @RegimL, @DataAngajarii,
		@Plecat, @DataPlecarii, @TotalOre, @OreLucrate, @OreSuplimentare, @OreNoapte, @OreCO, @OreCM, @OreCFS, 
		@OreNemotivate, @OreINT, @GrupLocm
	End
	close FormPontaj
	Deallocate FormPontaj

	select * from ##FormularPontaj
	order by Grup_locm, (case when @Ordonare in (1,3) then marca when @Ordonare in (2,4) then nume else nume end)
	delete from ##FormularPontaj where HostID=@HostID
End
