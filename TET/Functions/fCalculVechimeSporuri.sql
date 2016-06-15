--***
/**	functie pentru determinare 
		vechime totala in munca/vechime la intrare (in unitate)/vechime in meserie (specialitate pt. ANAR) (@CeLaInchLuna=1)
		spor vechime (@CeLaInchLuna='2')
		spor specific (@CeLaInchLuna=3)
		zile concediu de odihna (@CeLaInchLuna=4)
		spor vechime specialitate (@CeLaInchLuna=5) 
			- pentru ANAR, campul vechime_in_meserie din infopers este utilizat ca si vechime in specialitate 
			- pentru ANAR, campul spor_cond_8 din infopers este utilizat ca si spor pentru vechime in specialitate (pentru ANAR)
*/
Create function fCalculVechimeSporuri
	(@dataJos datetime, @dataSus datetime, @pMarca char(6), @InchidereLuna int, @CO int, @CeLaInchLuna char(1), @LmDunca char(9), @strictLaDataSus int)
returns @VechimeSporuri table 
	(Data datetime, Marca char(6), Vechime_totala datetime, Vechime_totala_car char(8), dVechime_la_intrare datetime, Vechime_la_intrare char(6), 
		dVechime_in_meserie datetime, Vechime_in_meserie char(6), Spor_vechime float, Spor_specific float, Spor_cond_8 float, Zile_CO_ramase int, Zile_CO_an int, Gradatia int)
As
Begin
	declare @utilizator varchar(20), @lista_lm int, @LunaInchisa int, @AnulInchis int, @dDataInch datetime, 
	@GrilaSpspecSubunit int, @SpspecLunaVech int, @Spspec_CMCC2ani int, @LmGrila2Spspec int, @cLmGrila2Spspec int, 
	@VechMZileNepl int, @VechimeRL int, @ZileCOVechUnit int, @ZileCOVechFan int, @IncrementVechIntr int, @Elite int, @Salubris int, @IncrementVechMeserie int, 
	@Marca char(6), @Loc_de_munca char(9), @ZileCOan int, @RL real, @DataAngajarii datetime, @Tip_colab char(3), @Plecat int, @DataPlec datetime, 
	@VechimeTotala datetime, @vVechimeTotala datetime, @vVechimeTotalaCar char(8), @VechimeLaIntrare char(6), @vVechimeLaIntrare char(6), @VechimeInMeserie char(6), @vVechimeInMeserie char(6), 
	@SporVechime float, @vSporVechime float, @SporSpecific float, @vSporSpecific float, @SporCond8 float, @vSporCond8 float, 
	@ZileCORamAnant int, @VechimeTotalaAni int, @VechimeTotalaLuni int, @dVechimeLaIntrare datetime, @VechimeLaIntrareAni int, @VechimeLaIntrareLuni int, @VechimeLaIntrareZile int, 
	@ZileLaVechime int, @VechimeUnitate datetime, @VechimeUnitateAni int, @vVechimeUnitateAni int, @vVechimeUnitateLuni int, @vVechimeUnitateZile int,
	@dVechimeInMeserie datetime, @VechimeInMeserieAni int, @VechimeInMeserieLuni int, @VechimeInMeserieZile int, @vVechimeInMeserieAni int, @vVechimeInMeserieLuni int, 
	@ZileCOcuvenite int, @VechimeCalculAni int, @ZileCOefectuate int, @ZileCOEfectAnant int, @ZileCOramase int,	@ZileCOcalc int, @ZileCFSNem int, @Gradatia int, 
	@AngajatLuna int, @PlecatLuna int, @AngajatPlecat int, @ConditieRL int, @ZileExcepSpSpec int, @NrLuniSupl int, @NrZileSupl int, @dataIncLuna datetime, @dataSfLuna datetime

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	set @LmGrila2Spspec=dbo.iauParL('PS','GRILA2SSP')
	set @cLmGrila2Spspec=dbo.iauParA('PS','GRILA2SSP')
	set @GrilaSpspecSubunit=dbo.iauParL('PS','SSPLIMSUB')
	set @SpspecLunaVech=dbo.iauParL('PS','SSPLUNVEC')
	set @Spspec_CMCC2ani=dbo.iauParL('PS','SSP-CMCC2')
	set @VechMZileNepl=dbo.iauParL('PS','VECHMDIM')
	set @VechimeRL=dbo.iauParL('PS','VECHPRL')
	set @ZileCOVechUnit=dbo.iauParL('PS','ZICOVECHU')
	set @ZileCOVechFan=dbo.iauParL('PS','ZICOVEFAN')
	set @IncrementVechIntr=dbo.iauParL('PS','INCVECINT')
	set @LunaInchisa=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @AnulInchis=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	set @dDataInch=dbo.eom(convert(datetime,str(@LunaInchisa,2)+'/01/'+str(@AnulInchis,4)))
	set @Elite=dbo.iauParL('SP','ELITE')
	set @Salubris=dbo.iauParL('SP','SALUBRIS')
	if exists (select 1 from grspor where cod='In' and Nrcrt>1)
		set @IncrementVechMeserie=1
--	de vazut daca pun data jos=data inchisa+1
--	set @dataJos=DATEADD(day,1, @dDataInch)
	set @dataIncLuna=dbo.BOM(@dataSus)
	set @dataSfLuna=dbo.EOM(@dataSus)

	Declare VechimeSporuri Cursor For
	Select p.Marca, p.Loc_de_munca, p.Zile_concediu_de_odihna_an, p.Salar_lunar_de_baza, p.Data_angajarii_in_unitate, p.Loc_ramas_vacant, p.Data_plec, p.Tip_colab, 
	p.Vechime_totala, i.Vechime_la_intrare, i.Vechime_in_meserie, p.Spor_vechime, p.Spor_specific, i.Spor_cond_8, isnull(s.Coef_invalid,0), 
	(case when (p.Data_angajarii_in_unitate<@dataIncLuna or not(year(p.Vechime_totala)=1900 and month(p.Vechime_totala)=1)) then isnull(po.ZileCFSnem,0) else 0 end)
	from personal p
		left outer join infopers i on i.marca=p.marca
		left outer join istpers s on s.marca=p.marca and s.data=dateadd(day,-1,dbo.boy(@dataSus))
		left outer join (select Marca, sum((ore_concediu_fara_salar+ore_nemotivate)/regim_de_lucru) as ZileCFSNem 
			from pontaj where data between @dataIncLuna and @dataSfLuna Group by Marca) po on @VechMZileNepl=1 and po.Marca=p.Marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
	where (isnull(@pMarca,'')='' or p.Marca=@pMarca) and (not(@CeLaInchLuna='3' and @LmDunca<>'') or p.Loc_de_munca=@LmDunca)
		and (@lista_lm=0 or lu.cod is not null)
		and (not(@LmGrila2Spspec=1 and @CeLaInchLuna='3' and @InchidereLuna=0) 
		or @LmDunca<>'' and p.Loc_de_munca=@LmDunca or @LmDunca='' and p.Loc_de_munca<>@cLmGrila2Spspec)
		and p.Data_angajarii_in_unitate<=@dataSus

	open VechimeSporuri
	fetch next from VechimeSporuri into @Marca, @Loc_de_munca, @ZileCOan, @RL, @DataAngajarii, @Plecat, @DataPlec, @Tip_colab, 
		@VechimeTotala, @VechimeLaIntrare, @VechimeInMeserie, @SporVechime, @SporSpecific, @SporCond8, @ZileCORamAnant, @ZileCFSNem
	While @@fetch_status = 0
	Begin
--		scad mai jos 2 astfel: 1- inseamna prima luna de dupa luna inchisa care se incrementeaza in formula de calcul a vechimii-
--		celalalt 1 - daca dau lista la o anumita luna sa aduca datele la inceputul lunii (intereseaza sporurile valabile pt. luna respectiva, adica cele de la finalul lunii anterioare)
		set @NrLuniSupl=(case when DateDiff(month,@dDataInch,@dataSus)>1 then DateDiff(month,@dDataInch,@dataSus)-2 else 0 end)
		set @NrZileSupl=0
--		pentru salariatii cu timp partial, daca se utilizeaza functia la o data mai mare decat data lunii inchise cu mai mult de 2 luni, 
--		se vor determina nr. de luni/zile proportional cu regimul de lucru.
		if @VechimeRL=1 and @RL<8 and @NrLuniSupl<>0
		Begin
			declare @RegimL int -- variabila pentru regim de lucru intreg 
			set @RegimL=convert(int,@RL)
			set @NrZileSupl=(case when (@NrLuniSupl*@RegimL)%8.00<>0 then round(31*(@NrLuniSupl*@RegimL/8.00-round(@NrLuniSupl*@RegimL/8.00,0,1)),0) else 0 end)
			set @NrLuniSupl=round(@NrLuniSupl*@RegimL/8.00,0,1)
		End	
		select @vVechimeTotala=@VechimeTotala, @vVechimeLaIntrare=@VechimeLaIntrare, @vVechimeInMeserie=@VechimeInMeserie

--		determin zile exceptate de la baza calcul procent spor specific
		Select @ZileExcepSpSpec=isnull(sum(datediff(day,data_inceput,data_sfarsit)+1),0) from conmed 
		where @Spspec_CMCC2ani=1 and marca=@marca and tip_diagnostic='0-' and data between @DataAngajarii and @dataSfLuna

--		determin vechimea in unitate functie de vechimea la intrare (din infopers) si perioada de la data angajarii pana la zi.
		set @VechimeUnitate=DateAdd(day,DateDiff(day,@DataAngajarii,@dataJos-1),DateAdd(month,(case when @InchidereLuna=1 then 0 else -1 end),'01/01/1900'))
		Select @VechimeUnitate=DateAdd(day,-@ZileExcepSpSpec,@VechimeUnitate) where @Spspec_CMCC2ani=1
		set @VechimeUnitate=DateAdd(day,convert(int,right(@VechimeLaIntrare,2)), DateAdd(month,convert(int,substring(@VechimeLaIntrare,3,2)), DateAdd(year,convert(int,left(@VechimeLaIntrare,2)),@VechimeUnitate)))
		set @AngajatLuna=(case when @DataAngajarii>@dataIncLuna and @DataAngajarii<=@dataSfLuna then 1 else 0 end)
		set @PlecatLuna=(case when @Plecat=1 and @DataPlec>=@dataIncLuna and @DataPlec<@dataSfLuna then 1 else 0 end)
		set @AngajatPlecat=(case when month(@DataAngajarii)=month(@dataSus) and year(@DataAngajarii)=year(@dataSus) and @Plecat=1 and month(@DataPlec)=month(@dataSus) and year(@DataPlec)=year(@dataSus) then 1 else 0 end)
		set @ConditieRL=(case when @VechimeRL=1 and @RL>0 and @RL<8 then 1 else 0 end)

--		calculez nr. de zile de CO ramase la inchiderea lunii decembrie 
		set @ZileCOcuvenite=@ZileCOan
		Select @ZileCOefectuate=0, @ZileCOramase=0

		-- calculam tot timpul zilele ramase si in procedura de inchidere le vom actualiza in tabela doar la inchiderea lunii decembrie
		-- sau nu, ca merge mai greu
		if @InchidereLuna=1 and month(@dataSus)=12 and @CeLaInchLuna='4' 
		Begin
			set @ZileCOcuvenite=isnull(dbo.Zile_CO_cuvenite(@Marca,@dataSus,0),0)
			set @ZileCOefectuate=isnull(dbo.Zile_CO_platite(@Marca,@dataSus),0)
			set @ZileCOramase=(case when @ZileCOcuvenite+@ZileCORamAnant-@ZileCOefectuate<0 and 1=0 then 0 else @ZileCOcuvenite+@ZileCORamAnant-@ZileCOefectuate end)
		End
		set @ZileLaVechime=-@ZileCFSNem+(case when @AngajatPlecat=1 then datediff(day,@DataAngajarii,@DataPlec) 
			when @AngajatLuna=1 then datediff(day,@DataAngajarii,@dataSus) 
			when @PlecatLuna=1 then datediff(day,@dataIncLuna,@DataPlec)+1 
--		mai adaug la @ZileLaVechime nr. de zile de la inceputul lunii pana la ziua curenta, pt. cazul in care se doreste vechimea la zi
			when @dataJos=@dataSus or @strictLaDataSus=1 and @NrLuniSupl<>0 then DateDiff(day,dbo.bom(@dataSus),@dataSus)+1
			when @ConditieRL=1 then datediff(day,@dataJos,@dataSus)+1 else 0 end)

		set @ZileLaVechime=(case when @ConditieRL=1 then round(@ZileLaVechime*@RL/8.00,0) else @ZileLaVechime end)

--		determin vechimea totala in munca
--		incrementez vechimea totala in munca doar daca functia este apelata de la inchidere de luna sau daca se apeleaza functia din raportul de previzionare sporuri/zile CO in avans cu mai mult de 1 luna fata de luna inchisa
		if @dataSus>@dDataInch and (@DataAngajarii<@dataJos or not(year(@VechimeTotala)=1900 and month(@VechimeTotala)=1)) 
			and (DateDiff(month,@dDataInch,@dataSus)>1 or @InchidereLuna=1 and @CeLaInchLuna='1')
			set @vVechimeTotala=dateadd(day,@NrZileSupl,dateadd(month,(case when @AngajatLuna=1 or @PlecatLuna=1 or @ConditieRL=1 then 0 else 1 end)+@NrLuniSupl, dateadd(day,@ZileLaVechime,@VechimeTotala)))

		set @vVechimeTotalaCar=dbo.fVechimeAALLZZ(@vVechimeTotala)

--		determin vechimea la intrare
		if (@ZileCOVechUnit=1 or @IncrementVechIntr=1) 
		Begin
			if /*@dataSus>@dDataInch and @dataSus>=@DataAngajarii and (@Plecat=0 or @DataPlec>=@dataJos) or*/ 1=1
				set @dVechimeLaIntrare=DateAdd(day,(case when convert(int,right(@VechimeLaIntrare,2))-1<0 then 0 
				else convert(int,right(@VechimeLaIntrare,2))-1 end),DateAdd(month,(case when convert(int,substring(@VechimeLaIntrare,3,2))-1<0 then 0 
					else convert(int,substring(@VechimeLaIntrare,3,2))-1 end),DateAdd(year,convert(int,left(@VechimeLaIntrare,2)),'01/01/1900')))
		End
		else 
			set @dVechimeLaIntrare=@VechimeUnitate

--		determin vechimea in meserie
		if @IncrementVechMeserie=1 
		Begin
			if /*@dataSus>@dDataInch and @dataSus>=@DataAngajarii and (@Plecat=0 or @DataPlec>=@dataJos) or*/ 1=1
				set @dVechimeInMeserie=DateAdd(day,(case when convert(int,right(@VechimeInMeserie,2))-1<0 then 0 
					else convert(int,right(@VechimeInMeserie,2))-1 end),DateAdd(month,(case when convert(int,substring(@VechimeInMeserie,3,2))-1<0 then 0 
						else convert(int,substring(@VechimeInMeserie,3,2))-1 end),DateAdd(year,convert(int,left(@VechimeInMeserie,2)),'01/01/1900')))
		End
--	incrementare vechimi		
		if @dataSus>@dDataInch and @dataSus>=@DataAngajarii and (@Plecat=0 or @DataPlec>=@dataJos)
		begin
			set @dVechimeLaIntrare=DateAdd(day,@ZileLaVechime+@NrZileSupl,DateAdd(month,(case when @AngajatLuna=1 or @PlecatLuna=1 or @ConditieRL=1 then 0 else 1 end)
				+(case when @ZileCOVechUnit=1 or @IncrementVechIntr=1 then @NrLuniSupl else 0 end)-(case when convert(int,substring(@VechimeLaIntrare,3,2))-1<0 then 1 else 0 end), @dVechimeLaIntrare))
--	tratez aici si vechimea in meserie
			set @dVechimeInMeserie=DateAdd(day,@ZileLaVechime+@NrZileSupl,DateAdd(month,(case when @AngajatLuna=1 or @PlecatLuna=1 or @ConditieRL=1 then 0 else 1 end)
				+(case when @IncrementVechIntr=1 then @NrLuniSupl else 0 end)-(case when convert(int,substring(@VechimeInMeserie,3,2))-1<0 then 1 else 0 end), @dVechimeInMeserie))
		end

		set @VechimeLaIntrareAni=(case when left(convert(char(10),@dVechimeLaIntrare,11),2)='99' then 0 
			else convert(int,left(convert(char(10),@dVechimeLaIntrare,11),2))+(case when substring(convert(char(10),@dVechimeLaIntrare,11),4,2)='12' then 1 else 0 end) end)
		set @VechimeLaIntrareLuni=(case when substring(convert(char(10),@dVechimeLaIntrare,11),4,2)='12' then 0 else convert(int,substring(convert(char(10),@dVechimeLaIntrare,11),4,2)) end)
		set @VechimeLaIntrareZile=convert(int,right(rtrim(convert(char(10),@dVechimeLaIntrare,11)),2))

--		incrementez vechimea la intrare doar daca functia este apelata de la inchidere de luna sau daca se apeleaza functia din raportul de previzionare sporuri/zile CO in avans cu mai mult de 1 luna fata de luna inchisa
		if @InchidereLuna=1 and @CeLaInchLuna='1' or DateDiff(month,@dDataInch,@dataSus)>1
			set @vVechimeLaIntrare=(case when @VechimeLaIntrareAni<10 then '0' else '' end)+rtrim(convert(char(2),@VechimeLaIntrareAni))+(case when @VechimeLaIntrareLuni<10 then '0' else '' end)
				+rtrim(convert(char(2),@VechimeLaIntrareLuni))+(case when @VechimeLaIntrareZile<10 then '0' else '' end)+rtrim(convert(char(2),@VechimeLaIntrareZile))

--	stabilesc vechimea in meserie pe componente (ani/luni/zile)
		set @VechimeInMeserieAni=(case when left(convert(char(10),@dVechimeInMeserie,11),2)='99' then 0 
			else convert(int,left(convert(char(10),@dVechimeInMeserie,11),2))+(case when substring(convert(char(10),@dVechimeInMeserie,11),4,2)='12' then 1 else 0 end) end)
		set @VechimeInMeserieLuni=(case when substring(convert(char(10),@dVechimeInMeserie,11),4,2)='12' then 0 else convert(int,substring(convert(char(10),@dVechimeInMeserie,11),4,2)) end)
		set @VechimeInMeserieZile=convert(int,right(rtrim(convert(char(10),@dVechimeInMeserie,11)),2))

--		incrementez vechimea in meserie doar daca functia este apelata de la inchidere de luna sau daca se apeleaza functia din raportul de previzionare sporuri (poate vom afisa in raportul de previzionare si acest spor)
		if @InchidereLuna=1 and @CeLaInchLuna='1' or DateDiff(month,@dDataInch,@dataSus)>1
			set @vVechimeInMeserie=(case when @VechimeInMeserieAni<10 then '0' else '' end)+rtrim(convert(char(2),@VechimeInMeserieAni))+(case when @VechimeInMeserieLuni<10 then '0' else '' end)
				+rtrim(convert(char(2),@VechimeInMeserieLuni))+(case when @VechimeInMeserieZile<10 then '0' else '' end)+rtrim(convert(char(2),@VechimeInMeserieZile))

		Select @VechimeTotalaAni=convert(int,left(convert(char(10),@vVechimeTotala,11),2)),
			@VechimeTotalaLuni=convert(int,substring(convert(char(10),@vVechimeTotala,11),4,2))

		Select @VechimeCalculAni=(case when @VechimeTotalaAni=99 then 0 
			else @VechimeTotalaAni+(case when @VechimeTotalaLuni=12 or @Salubris=1 and @CO=1 and @LunaInchisa<@VechimeTotalaLuni then 1 else 0 end) end)
			where @Elite=0 and @ZileCOVechUnit=0
		Select @VechimeCalculAni=(case when left(@vVechimeLaIntrare,2)='99' then 0 
			else convert(int,left(@vVechimeLaIntrare,2))+(case when substring(@vVechimeLaIntrare,3,2)='12' then 1 else 0 end) end)
			where @Elite=0 and @ZileCOVechUnit=1
		Select @VechimeCalculAni=year(@dataSus)-year(@DataAngajarii)+(case when month(@dataSus)-month(@DataAngajarii)>0 then 0 else -1 end) 
			where @Elite=1
		Select @VechimeCalculAni=@VechimeCalculAni+1 
			where @LunaInchisa=11 and @Elite=0 and @ZileCOVechFan=1
--		determin zile CO conform grilei
		Select @ZileCOcalc=isnull((select top 1 Suma from grspor a where a.Cod='Co' and a.Limita>=@VechimeCalculAni+1 order by Nrcrt Asc),@ZileCOan) 

		Select @VechimeCalculAni=(case when @VechimeTotalaAni=99 then 0 else @VechimeTotalaAni end)+
		(case when @VechimeTotalaLuni=12 or @Salubris=1 and @CO=1 and @LunaInchisa<@VechimeTotalaLuni then 1 else 0 end) where @Elite=0

--		determin procent spor vechime conform grilei si gradatia
		select @vSporVechime=isnull((select top 1 Procent from grspor a where a.Cod='Ve' and a.Limita>=@VechimeCalculAni+1 order by a.Nrcrt Asc),@SporVechime) 
		select @Gradatia=isnull((select top 1 NrCrt from grspor a where a.Cod='Ve' and a.Limita>=@VechimeCalculAni+1 order by a.Nrcrt Asc),@SporVechime) 
		if isnull((select top 1 NrCrt from grspor a where a.Cod='Ve' order by a.Nrcrt Asc),0)=1 
			set @gradatia=@gradatia-1

		if @Tip_colab in ('DAC','CCC','ECT') 
			set @vSporVechime=0
--		daca zile de CO se determina functie de vechimea in unitate sau daca [X]Vechimea la intrare se incrementeaza, campul Vechime_la_intrare din infopers se incrementeaza la inchiderea de luna (+1)	
--		in acest caz vechimea in unitate pt. determinare spor specific sa nu mai tina cont de data angajarii (se tine cont de aceasta la inceput de while)
		if @ZileCOVechUnit=1 or @IncrementVechIntr=1
		Begin
--			determin vechimea in ani/luni pornind de la vechimea la intrare din infopers (ca sa nu ma fac convert in datetime din vechime la intrare)
			set @vVechimeUnitateAni=convert(int,left(@vVechimeLaIntrare,2))
			set @vVechimeUnitateLuni=convert(int,substring(@vVechimeLaIntrare,3,2))
		End	
		else 
		Begin
			set @vVechimeUnitateAni=convert(int,left(convert(char(10),@VechimeUnitate,11),2))
			set @vVechimeUnitateLuni=convert(int,substring(convert(char(10),@VechimeUnitate,11),4,2))
		End	
		set @VechimeUnitateAni=(case when @vVechimeUnitateAni=99 then 0 else @vVechimeUnitateAni end)+(case when @vVechimeUnitateLuni=12 then 1 else 0 end)
		set @VechimeCalculAni=@VechimeUnitateAni+(case when @LmGrila2Spspec=0 and @vVechimeUnitateLuni<>12 and @SpspecLunaVech=0 
			then round(@vVechimeUnitateLuni/12.00,(case when @GrilaSpspecSubunit=1 then 2 else 0 end)) else 0 end)

--		determin procent spor specific conform grilei
		select @vSporSpecific=isnull((select top 1 Procent from grspor a where a.Cod=(case when @LmGrila2Spspec=1 and @Loc_de_munca=@cLmGrila2Spspec then 'Du' else 'Sp' end) 
			and a.Limita>=@VechimeCalculAni+(case when @GrilaSpspecSubunit=1 then 0.01 else 1 end) order by a.Nrcrt Asc),@SporSpecific) 
		if @Tip_colab in ('DAC','CCC','ECT')
			set @vSporSpecific=0

		if @IncrementVechMeserie=1
		Begin
--			determin vechimea in ani/luni pornind de la vechimea in meserie din infopers (ca sa nu ma fac convert in datetime din vechime in meserie)
			set @vVechimeInMeserieAni=convert(int,left(@vVechimeInMeserie,2))
			set @vVechimeInMeserieLuni=convert(int,substring(@vVechimeInMeserie,3,2))
			set @VechimeInMeserieAni=(case when @vVechimeInMeserieAni=99 then 0 else @vVechimeInMeserieAni end)+(case when @vVechimeInMeserieLuni=12 then 1 else 0 end)
			set @VechimeCalculAni=@VechimeInMeserieAni+(case when @vVechimeInMeserieLuni<>12 and @SpspecLunaVech=0 
				then round(@vVechimeInMeserieLuni/12.00,(case when @GrilaSpspecSubunit=1 then 2 else 0 end)) else 0 end)

--		determin gradatia conform grilei de spor vechime in specialitate. 
--		comentat partea de mai jos. Aurel spune ca gradatia este functie de vechimea totala in munca. Cei de la Ape Cris spun ca este functie de vechimea in specialitate
/*			select @Gradatia=isnull((select top 1 NrCrt from grspor a 
				where a.Cod='In' and a.Limita>=@VechimeCalculAni+(case when @GrilaSpspecSubunit=1 then 0.01 else 1 end) order by a.Nrcrt Asc),0) */

--		determin procent spor conditii 8 (vechime in meserie=specialitate) conform grilei. Pentru moment nu se va calcula. Nu este necesar.
			select @vSporCond8=isnull((select top 1 Procent from grspor a 
				where 1=0 and a.Cod='In' and a.Limita>=@VechimeCalculAni+(case when @GrilaSpspecSubunit=1 then 0.01 else 1 end) order by a.Nrcrt Asc),@SporCond8) 
			if @Tip_colab in ('DAC','CCC','ECT')
				set @vSporCond8=0
		End	
--		set @vSporCond8=isnull(@vSporCond8,0)

		insert @VechimeSporuri
		values (@dataSus, @Marca, @vVechimeTotala, @vVechimeTotalaCar, @dVechimeLaIntrare, @vVechimeLaIntrare, @dVechimeInMeserie, @vVechimeInMeserie, 
			@vSporVechime, @vSporSpecific, @vSporCond8, @ZileCOramase, @ZileCOcalc, @Gradatia)
		
		fetch next from VechimeSporuri into @Marca, @Loc_de_munca, @ZileCOan, @RL, @DataAngajarii, @Plecat, @DataPlec, @Tip_colab, 
			@VechimeTotala, @VechimeLaIntrare, @VechimeInMeserie, @SporVechime, @SporSpecific, @SporCond8, @ZileCORamAnant, @ZileCFSNem
	End
	Close VechimeSporuri
	Deallocate VechimeSporuri
	return
End

/*
	select a.Marca, a.Vechime_totala as pVechime_totala, a.Vechime_la_intrare as pVechime_la_intrare, a.Spor_vechime as pSpor_vechime, a.Spor_specific as pSpor_specific,
		p.Vechime_totala, p.Spor_vechime, p.Spor_specific, i.Vechime_la_intrare --into sporuri0911 
		from fCalculVechimeSporuri('10/01/2011', '10/31/2011', '', 1, 0, '3', '') a
		left outer join personal p on a.marca=p.marca
		left outer join infopers i on a.marca=i.marca
	where a.Spor_vechime<>p.Spor_vechime or a.Spor_specific<>p.Spor_specific
	drop table sporuri0911
	select * from sporuri0911
	select a.* from fCalculVechimeSporuri('07/01/2012', '07/31/2012', '102', 0, 0, '1', '') a
	select a.* from fCalculVechimeSporuri('08/01/2012', '08/31/2012', '102', 0, 0, '1', '') a
	select a.* from fCalculVechimeSporuri('08/02/2012', '08/02/2012', '102', 0, 0, '1', '') a
	select a.* from fCalculVechimeSporuri('01/01/2014', '01/31/2014', '', 0, 0, '1', '') a where marca='1'
*/
