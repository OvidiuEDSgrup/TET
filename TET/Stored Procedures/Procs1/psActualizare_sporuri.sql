--***
/**	procedura pentru actualizare 
		vechime totala in munca/vechime la intrare (in unitate)/vechime in meserie (specialitate pt. ANAR) (@CeLaInchLuna=1)
		spor vechime (@CeLaInchLuna='2')
		spor specific (@CeLaInchLuna=3)
		zile concediu de odihna (@CeLaInchLuna=4)
		spor vechime specialitate (@CeLaInchLuna=5) 
			- pentru ANAR, campul vechime_in_meserie din infopers este utilizat ca si vechime in specialitate 
			- pentru ANAR, campul spor_cond_8 din infopers este utilizat ca si spor pentru vechime in specialitate (pentru ANAR)
*/
Create procedure psActualizare_sporuri
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @InchidereLuna int, @CO int, @CeLaInchLuna char(1), @LmDunca char(9)
As
Begin
	declare @utilizator varchar(20), @lista_lm int, @LmGrila2Spspec int, @cLmGrila2Spspec int, @ZileCOVechUnit int, @ZileCOVechFan int, @IncrementVechIntr int, @IncrementVechMeserie int, 
	@LunaInchisa int, @Marca char(6), @Loc_de_munca char(9), @ZileCOan int, @DataAngajarii datetime, @Plecat int, @DataPlec datetime, 
	@Vechime_totala datetime, @Vechime_la_intrare char(6), @Vechime_in_meserie char(6),
	@vVechime_totala datetime, @vVechime_la_intrare char(6), @vVechime_in_meserie char(6),
	@vSpor_vechime float, @vSpor_specific float, @vSpor_cond_8 float, @vZile_CO_ramase int, @vZile_CO_an int

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	set @LmGrila2Spspec=dbo.iauParL('PS','GRILA2SSP')
	set @cLmGrila2Spspec=dbo.iauParA('PS','GRILA2SSP')
	set @ZileCOVechUnit=dbo.iauParL('PS','ZICOVECHU')
	set @ZileCOVechFan=dbo.iauParL('PS','ZICOVEFAN')
	set @IncrementVechIntr=dbo.iauParL('PS','INCVECINT')
	set @LunaInchisa=dbo.iauParN('PS','LUNA-INCH')
	if exists (select 1 from grspor where cod='In' and Procent<>0)
		set @IncrementVechMeserie=1

	Declare ActSporuri Cursor For
	Select p.Marca, p.Loc_de_munca, p.Zile_concediu_de_odihna_an, p.Data_angajarii_in_unitate, p.Loc_ramas_vacant, p.Data_plec, 
		p.Vechime_totala, i.Vechime_la_intrare, i.Vechime_in_meserie, c.Vechime_totala, c.Vechime_la_intrare, c.Vechime_in_meserie, 
		c.Spor_vechime, c.Spor_specific, c.Spor_cond_8, c.Zile_CO_ramase, c.Zile_CO_an
	from personal p
		left outer join infopers i on i.marca=p.marca
		left outer join istpers s on s.marca=p.marca and s.data=dateadd(day,-1,dbo.boy(@dataSus))
		left outer join fCalculVechimeSporuri (@dataJos, @dataSus, @pMarca, @InchidereLuna, @CO, @CeLaInchLuna, @LmDunca, 0) c on p.Marca=c.Marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
	where (@pMarca='' or p.Marca=@pMarca) and (not(@CeLaInchLuna='3' and @LmDunca<>'') or p.Loc_de_munca=@LmDunca)
		and (@lista_lm=0 or lu.cod is not null) 
		and (not(@LmGrila2Spspec=1 and @CeLaInchLuna='3' and @InchidereLuna=0) 
			or @LmDunca<>'' and p.Loc_de_munca=@LmDunca or @LmDunca='' and p.Loc_de_munca<>@cLmGrila2Spspec)
		and p.Data_angajarii_in_unitate<=@dataSus

	open ActSporuri
	fetch next from ActSporuri into @Marca, @Loc_de_munca, @ZileCOan, @DataAngajarii, @Plecat, @DataPlec, 
		@Vechime_totala, @Vechime_la_intrare, @Vechime_in_meserie, @vVechime_totala, @vVechime_la_intrare, @vVechime_in_meserie, 
		@vSpor_vechime, @vSpor_specific, @vSpor_cond_8, @vZile_CO_ramase, @vZile_CO_an

	While @@fetch_status = 0
	Begin
--		scriu zile concediu de odihna ramase din anul anterior la inchiderea lunii decembrie 
		if @InchidereLuna=1 and month(@dataSus)=12 and @CeLaInchLuna='4'
			update istpers set Coef_invalid=isnull(@vZile_CO_ramase,Coef_invalid) 
			where marca=@Marca and data=@dataSus

--		scriu vechime totala in munca
		if @CeLaInchLuna='1' and (@DataAngajarii<@dataJos or not(year(@Vechime_totala)=1900 and month(@Vechime_totala)=1)) and @InchidereLuna=1
			update personal set vechime_totala=@vVechime_totala where marca=@Marca

--		scriu vechime la intrare
		if (@CeLaInchLuna='1' and @InchidereLuna=1 or @CO=1) and (@ZileCOVechUnit=1 or @IncrementVechIntr=1) and @dataSus>=@DataAngajarii and (@Plecat=0 or @DataPlec>=@dataJos)
			update infopers set Vechime_la_intrare=@vVechime_la_intrare where marca=@Marca and @CO=0

--		scriu vechime in meserie
		if @CeLaInchLuna='1' and @InchidereLuna=1 and @IncrementVechMeserie=1 and @dataSus>=@DataAngajarii and (@Plecat=0 or @DataPlec>=@dataJos)
			update infopers set Vechime_in_meserie=@vVechime_in_meserie where marca=@Marca and @CO=0

--		scriu zile concediu de odihna cuvenite pe an conform vechimii 
		if @LunaInchisa=12 and @ZileCOVechFan=0 or @LunaInchisa=11 and @ZileCOVechFan=1 or @CO=1
			update personal set Zile_concediu_de_odihna_an=isnull(@vZile_CO_an,Zile_concediu_de_odihna_an) 
			where personal.marca=@Marca

		if @CO=0
		Begin
--		scriu spor vechime
			update personal set Spor_vechime=isnull(@vSpor_vechime,Spor_vechime) 
			where personal.marca=@Marca and @CeLaInchLuna='2' and Tip_colab not in ('DAC','CCC','ECT')
--		scriu spor specific	
			if @CeLaInchLuna='3'
				update personal set Spor_specific=isnull(@vSpor_specific,Spor_specific) 
				where personal.marca=@Marca and Tip_colab not in ('DAC','CCC','ECT')
--		scriu spor conditii 8 (vechime in specialitate la ANAR). Momentan nu se foloseste.
			if @CeLaInchLuna='5' and 1=0
				update ip set ip.Spor_cond_8=isnull(@vSpor_cond_8,ip.Spor_cond_8) 
				from infoPers ip
					left outer join personal p on p.marca=ip.marca
				where ip.marca=@Marca and p.Tip_colab not in ('DAC','CCC','ECT')
		End
		fetch next from ActSporuri into @Marca, @Loc_de_munca, @ZileCOan, @DataAngajarii, @Plecat, @DataPlec, 
			@Vechime_totala, @Vechime_la_intrare, @Vechime_in_meserie, @vVechime_totala, @vVechime_la_intrare, @vVechime_in_meserie, 
			@vSpor_vechime, @vSpor_specific, @vSpor_cond_8, @vZile_CO_ramase, @vZile_CO_an
	End
	close ActSporuri
	Deallocate ActSporuri
End

/*
	exec psActualizare_sporuri_cu_functie '11/01/2011', '11/30/2011', '', 1, 0, '3', ''
*/
