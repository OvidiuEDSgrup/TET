--***
/* procedura pentru calcul indemnizatii concedii de odihna (brute/nete), prima de vacanta */
Create procedure calcul_concedii_de_odihna
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @pData_inceput datetime, @pZile_lucratoare int, @pIndemnizatie_CO float, @pLocm char(9), @pCalcul_prima int, @Procent_prima float, 
	@pCalcul_CO_net int, @pCalcul_COnet_prima int, @lData_op int, @dData_op datetime, @Calcul_CO_net_FDP int, @Recalc_CO_luniant int,
	@StergCONetAnt int=0
As
Begin
	declare @Utilizator char(10), @nLunaInch int, @nAnulInch int, @dDataInch datetime, @Data datetime, @Marca char(6), @Tip_CO char(1), @Data_inceput datetime, @Data_sfarsit datetime, @Zile_CO int, 
	@Calcul_manual int, @Indemnizatie_CO float, @Media_zilnica float,@Zile_prima_vacanta int, @nData_inreg float, @dData_inreg datetime, @Tip_salarizare char(1), @Regim_lucru float, 
	@Loc_de_munca char(9), @Grupa_de_munca char(1), @Salar_de_incadrare float, @Salar_de_baza float, @pTip_salarizare char(1), @Somaj int, @CASS float, @Zile_CO_an int, @Data_angajarii datetime,
	@Tip_colab char(3), @Funct_public int, @Salar_de_baza_istpers float, @Data_primei datetime, @vData_primei datetime, @Prima_vacanta float, @Data_inceput_CO datetime, @Data_primei_datainc datetime,
	@Prima_vacanta_datainc float, @Gasit_prima_ant int, @Zile_CO_marca int, @Ore_CO int, @Ore_CO_marca int, @Ore_luna int, @Ani_vechime int, @Suma_CO float, @Coef_ded float, @Nr_pers_intr int, 
	@Contor int, @lCalcul_prima int, @Baza_calcul_prima char(1), @Pun_ore_in_pontaj int, @gmarca char(6), @gLoc_de_munca char(9),@nData_op float, @vData_inceput datetime, @vPrima_vacanta float, 
	@vPrima_bruta float, @vPrima_neta float, @nSomaj float, @nCasindiv float, @lBuget int, @lInstitutie int,@Sindrom int,@Stoehr int, @Spicul int,@Salubris int, @COEV_macheta int,
	@RotIndCO int, @Pontaj_zilnic int

	set @nLunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @nAnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	SET @Utilizator = dbo.fIaUtilizator('')
	IF @Utilizator IS NULL or @nLunaInch not between 1 and 12 or @nAnulInch<=1901
		RETURN -1
	set @dDataInch=dbo.eom(convert(datetime,str(@nLunaInch,2)+'/01/'+str(@nAnulInch,4)))
--	verific luna inchisa
	IF @dataSus<=@dDataInch
	Begin
		raiserror('(calcul_concedii_de_odihna) Luna pe care doriti sa efectuati calcul concedii de odihna este inchisa!' ,16,1)
		RETURN -1
	End	

	Set @Pun_ore_in_pontaj=dbo.iauParL('PS','ORECOPONT')
	Set @lCalcul_prima=dbo.iauParL('PS','PV%-INDCO')
	if @Procent_prima=0
		Set @Procent_prima=dbo.iauParN('PS','PV%-INDCO')
	Set @Baza_calcul_prima=dbo.iauParA('PS','PV%-INDCO')
	Set @nSomaj=dbo.iauParLN(@dataSus,'PS','SOMAJIND')
	Set @nCasindiv=dbo.iauParLN(@dataSus,'PS','CASINDIV')
	Set @lBuget=dbo.iauParL('PS','UNITBUGET')
	Set @lInstitutie=dbo.iauParL('PS','INSTPUBL')
	Set @Sindrom=dbo.iauParL('SP','SINDROM')
	Set @Stoehr=dbo.iauParL('SP','STOEHR')
	Set @Spicul=dbo.iauParL('SP','SPICUL')
	Set @Salubris=dbo.iauParL('SP','SALUBRIS')
	Set @COEV_macheta=dbo.iauParL('PS','COEVMCO')
	Set @RotIndCO=dbo.iauParN('PS','ROTINDCO')
	Set @Pontaj_zilnic=dbo.iauParL('PS','PONTZILN')
	Set @nData_op=datediff(day,convert(datetime,'01/01/1901'),@dData_op)+693961

	exec psGenerare_CO @dataJos=@dataJos, @dataSus=@dataSus, @marca=@pmarca, @lm=@pLocm

	Declare cursor_CO Cursor For
	Select a.data, a.marca, a.tip_concediu, a.Data_inceput, a.Data_sfarsit, a.Zile_CO, a.Introd_manual, 
		a.Indemnizatie_CO, a.Zile_prima_vacanta, a.Prima_vacanta float, '01/01/1901', 
		isnull(j.Tip_sal,''), isnull(j.RL,8), p.Loc_de_munca, p.Grupa_de_munca, p.Salar_de_incadrare, p.Salar_de_baza, 
		p.Tip_salarizare, p.Somaj_1, p.As_sanatate, p.Zile_concediu_de_odihna_an, p.Data_angajarii_in_unitate, 
		p.Tip_colab, p1.Actionar, i.Salar_de_baza, isnull(c.Data,''), isnull(c.Suma_corectie,0), isnull(d.Data_inceput,''), 
		isnull(c1.Data,''), isnull(c1.Suma_corectie,0), 
		isnull((select count(1) from corectii c where c.data between dbo.boy(a.data) and a.data_inceput-1 and c.marca=a.marca and c.tip_corectie_venit='O-'),0),
		(case when dbo.iauParLN(a.Data,'PS','ORE_LUNA')=0 then dbo.zile_lucratoare(dbo.bom(a.Data),a.Data)*8 else dbo.iauParLN(a.Data,'PS','ORE_LUNA') end),
		isnull((select count(1) from persintr s where s.data between @dataJos and @dataSus and s.marca=a.marca and coef_ded<>0),0)
	from concodih a 
		left outer join personal p on a.marca=p.marca 
		left outer join infopers p1 on a.marca=p1.marca 
		left outer join istpers i on a.Data-1=i.Data and a.marca=i.marca 
		left outer join (select Marca, max(Tip_salarizare) as Tip_sal, max(Regim_de_lucru) as RL from pontaj where data between @dataJos and @dataSus group by Marca) j on a.Marca=j.Marca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'O-', @pmarca, @pLocm, 0) c on c.Data=a.Data and c.Marca=a.Marca
		left outer join concodih d on a.Data=d.Data and a.Marca=d.Marca and c.Data=d.Data_inceput and d.tip_concediu between '1' and '4'
		left outer join corectii c1 on a.Data_inceput=c1.Data and a.Marca=c1.Marca and c1.tip_corectie_venit='O-'
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.Loc_de_munca 
	where /*a.data between @dataJos and @dataSus and*/ (@pmarca='' or a.marca=@pmarca) 
		and (@pLocm='' or p.Loc_de_munca like rtrim(@pLocm)+'%')
		and (@pData_inceput='01/01/1901' or a.Data_inceput=@pData_inceput) and (@lData_op=0 or a.Prima_vacanta=@nData_op)
		and a.Tip_concediu not in ('9','C','P','V') and (a.Data=@dataSus and a.Tip_concediu in ('1','2','3','4','5','6','7','8','E') 
			or a.Data>@dataSus and a.Tip_concediu in ('7','8') and a.Prima_vacanta in 
			(select co.Prima_vacanta from concodih co where co.data=@dataSus and co.marca=a.Marca and co.tip_concediu in ('1','4')))
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
	order by a.marca, a.data 

	open cursor_CO
	fetch next from cursor_CO into @Data, @Marca, @Tip_CO, @Data_inceput, @Data_sfarsit, @Zile_CO, @Calcul_manual, @Indemnizatie_CO, @Zile_prima_vacanta, @nData_inreg, @dData_inreg, 
		@Tip_salarizare, @Regim_lucru, @Loc_de_munca, @Grupa_de_munca, @Salar_de_incadrare, @Salar_de_baza, @pTip_salarizare, @Somaj, @CASS, @Zile_CO_an, 
		@Data_angajarii, @Tip_colab, @Funct_public, @Salar_de_baza_istpers, @Data_primei, @Prima_vacanta, @Data_inceput_CO, @Data_primei_datainc, 
		@Prima_vacanta_datainc, @Gasit_prima_ant, @Ore_luna, @Nr_pers_intr
	While @@fetch_status = 0 
	Begin
		Set @gmarca=@marca
		Set @gLoc_de_munca=@loc_de_munca
		Set @Zile_CO_marca=0
		Set @Ore_CO_marca=0
		Set @vPrima_vacanta=0
		Set @Contor=0
		Set @vData_inceput=@Data_inceput
		update pontaj set ore_concediu_de_odihna=0 
		where @Pun_ore_in_pontaj=1 and @Pontaj_zilnic=0	-- tratat sa nu se faca actualizarea orelor in pontaj daca Pontaj zilnic (ar trebui actualizata fiecare zi din pontaj nu doar ultima zi)
			and data between @dataJos and @dataSus 
			and marca=@marca and @pData_inceput='01/01/1901'
		While @marca=@gmarca and @@fetch_status=0 
		Begin
			select @Ore_CO=0
			if exists (select * from sys.objects WHERE object_id = OBJECT_ID(N'zile_lucratoareSP') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
				set @Zile_CO=dbo.zile_lucratoareSP(@Data_inceput, @Data_sfarsit, @Marca)
			if exists (select * from sys.objects WHERE object_id = OBJECT_ID(N'ore_lucratoareSP') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
				set @Ore_CO=dbo.ore_lucratoareSP(@Data_inceput, @Data_sfarsit, @Marca)
				
			Set @Zile_CO_marca=@Zile_CO_marca+(case when @Tip_CO in ('1','4','5') or @Tip_CO in ('7','8') and year(@Data_inceput)=year(@dataJos) and month(@Data_inceput)=month(@dataJos) 
				then (case when @Tip_CO='5' then -1 else 1 end)* @Zile_CO else 0 end)
			Set @Ore_CO_marca=@Ore_CO_marca+(case when @Tip_CO in ('1','4','5') or @Tip_CO in ('7','8') and year(@Data_inceput)=year(@dataJos) and month(@Data_inceput)=month(@dataJos) 
				then (case when @Tip_CO='5' then -1 else 1 end)* @Ore_CO else 0 end)
			
			if (not(@Tip_CO in ('7','8') and year(@Data_inceput)=year(@dataJos) and month(@Data_inceput)=month(@dataJos))
			or @Recalc_CO_luniant=1) and @Calcul_manual=0
			Begin
				if exists (select * from sys.objects WHERE object_id = OBJECT_ID(N'calcul_indemnizatie_COSP') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
					Set @Indemnizatie_CO=(select dbo.calcul_indemnizatie_COSP (@dataJos, @dataSus, @Data, @Marca, @Tip_CO, @Zile_CO, @Regim_lucru, @Data_inceput, @Data_sfarsit))
				else
					Set @Indemnizatie_CO=(select dbo.calcul_indemnizatie_CO	(@dataJos, @dataSus, @Data, @Marca, @Tip_CO, @Zile_CO, @Regim_lucru, @Data_inceput, @Data_sfarsit))

				Set @Media_zilnica=(case when @Zile_CO=0 then 0 else round(@Indemnizatie_CO/@Zile_CO,2) end)
				Set @Indemnizatie_CO=round(@Indemnizatie_CO,@RotIndCO)

				update concodih Set Indemnizatie_CO=@Indemnizatie_CO, Zile_CO=(case when Zile_CO<>@Zile_CO then @Zile_CO else @Zile_CO end)
				where Data=@Data and Marca=@Marca and Tip_concediu=@Tip_CO and Data_inceput=@Data_inceput				
--	calcul prima de vacanta
				Select @vPrima_vacanta=0 where @pCalcul_prima=1 and @Baza_calcul_prima='1'
				exec calcul_prima_de_vacanta @dataJos, @dataSus, @pCalcul_prima, @Baza_calcul_prima, @Procent_prima, @Media_zilnica, 
					@Indemnizatie_CO, @Tip_CO, @Zile_CO, @Zile_prima_vacanta, @Zile_CO_an, @Zile_CO_marca, @Data_angajarii, 			
					@Salar_de_incadrare, @Salar_de_baza, @Salar_de_baza_istpers, @Funct_public, @Gasit_prima_ant, @Ani_vechime, 			
					@lBuget, @lInstitutie, @Sindrom, @Stoehr, @Spicul, @Salubris, @vPrima_vacanta output
				If @pCalcul_prima=1 and @vPrima_vacanta<>0 and @Baza_calcul_prima='1'
				Begin
					Set @vData_primei=(case when @Prima_vacanta=0 or @Prima_vacanta_datainc<>0 then @Data_inceput else @Data end)
					exec scriuCorectii @vData_primei, @Marca, @Loc_de_munca, 'O-', @vPrima_vacanta, 0, 0
				End
				Set @Suma_CO=@Indemnizatie_CO+(case when @pCalcul_COnet_prima=1 then (case when @pCalcul_prima=0 then 
						(case when @Data_primei=@Data_inceput_CO and @Prima_vacanta<>0 then @Prima_vacanta_datainc 
							else (case when @Contor=0 then @Prima_vacanta else 0 end) end) 
						else (case when @lCalcul_prima=1 and @Baza_calcul_prima=1 or @lCalcul_prima=0 or @Contor=0 then @vPrima_vacanta else 0 end) end) else 0 end)
				Set @Contor=@Contor+1
				If @StergCONetAnt=1
					delete from ConcOdih where Data=@Data and Marca=@Marca and Data_inceput=@Data_inceput and Tip_concediu='9' 
				If @pCalcul_CO_net=1
					exec dbo.calcul_indemnizatie_CO_neta @dataJos, @dataSus, @Data, @Marca,@Tip_CO,@Data_inceput,@Data_sfarsit,@Zile_CO,@Suma_CO,@Nr_pers_intr,
					@Grupa_de_munca, @Tip_colab, @Somaj, @nSomaj, @CASS, @nCasindiv, @Calcul_CO_net_FDP, 
					@Recalc_CO_luniant,@Salubris,@COEV_macheta,@Ore_luna,@dDataInch,@nData_inreg,@lData_op,@nData_op
			End
			fetch next from cursor_CO into @Data, @Marca, @Tip_CO, @Data_inceput, @Data_sfarsit, @Zile_CO, @Calcul_manual, @Indemnizatie_CO, @Zile_prima_vacanta, 
				@nData_inreg, @dData_inreg, @Tip_salarizare, @Regim_lucru, @Loc_de_munca, @Grupa_de_munca, @Salar_de_incadrare, @Salar_de_baza, @pTip_salarizare, @Somaj, @CASS, 
				@Zile_CO_an, @Data_angajarii, @Tip_colab, @Funct_public, @Salar_de_baza_istpers, @Data_primei, @Prima_vacanta, @Data_inceput_CO, 
				@Data_primei_datainc, @Prima_vacanta_datainc, @Gasit_prima_ant, @Ore_luna, @Nr_pers_intr
		End 
		update pontaj set ore_concediu_de_odihna=(case when @Ore_CO_marca<>0 then @Ore_CO_marca else @Zile_CO_marca*regim_de_lucru end)
		where @Pun_ore_in_pontaj=1 and @Pontaj_zilnic=0	-- tratat sa nu se faca actualizarea orelor in pontaj daca Pontaj zilnic (ar trebui actualizata fiecare zi din pontaj nu doar ultima zi)
			and data between @dataJos and @dataSus and marca=@gmarca 
			and exists (select 1 from pontaj j where j.data between @dataJos and @dataSus and j.marca=@gmarca and j.loc_munca_pentru_stat_de_plata=1 and j.numar_curent=pontaj.numar_curent) 
			and @pData_inceput='01/01/1901' 
		If @pCalcul_prima=1 and @vPrima_vacanta<>0 and @Baza_calcul_prima<>'1' --and @Tip_CO not in ('7','8')
		Begin
			Set @vData_primei=(case when @Prima_vacanta=0 or @Prima_vacanta_datainc<>0 or 1=1 then @vData_inceput else @Data end)
			Set @vPrima_bruta=(case when @Baza_calcul_prima<>'6' then @vPrima_vacanta else 0 end)
			Set @vPrima_neta=(case when @Baza_calcul_prima='6' then @vPrima_vacanta else 0 end)
			exec scriuCorectii @vData_primei, @gMarca, @gLoc_de_munca, 'O-', @vPrima_bruta, 0, @vPrima_neta
		End
		Set @Contor=0
		Set @gmarca=@marca
		Set @gLoc_de_munca=@loc_de_munca
	End
	close cursor_CO
	Deallocate cursor_CO
End
