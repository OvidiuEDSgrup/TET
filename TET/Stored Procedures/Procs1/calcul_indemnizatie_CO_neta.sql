--***
/**	procedura calcul ind. CO neta	*/
Create 
procedure  calcul_indemnizatie_CO_neta
	@DataJ datetime, @DataS datetime, @Data_CO datetime, @Marca char(6), @Tip_CO char(1), @Data_inceput datetime, 
	@Data_sfarsit datetime, @Zile_CO int, @Suma_CO float, @Nr_pers_intr int, @Grupa_de_munca char(1), @Tip_colab char(1), @Somaj int, @nSomaj float, @CASS float, @nCasindiv float, @Calcul_CO_net_FDP int, @Recalc_CO_luniant int, @Salubris int, @COEV_macheta int, @Ore_luna float, @Data_inchisa datetime, @nData_inreg float, @lData_op int, @nData_op float
As
Begin
	declare @Venit_net int, @Venit_baza int, @Ded_pers float, @Retineri float, @Impozit float, @Indemnizatie_CO_net float, @Data_sfarsit_net datetime
	Set @Data_sfarsit_net=(case when @Data_sfarsit>@Data_CO then @Data_CO else @Data_sfarsit end)
	Select @Venit_net=0, @Venit_baza=0, @Ded_pers=0, @Impozit=0, @Retineri=0, @Indemnizatie_CO_net=0
	Begin
		If (@Tip_CO in ('1','3','4','6','7','8') or @COEV_macheta=1 and @Tip_CO='2') and  
		(not(@Tip_CO in ('7','8') and year(@Data_inceput)=year(@DataJ) and month(@Data_inceput)=month(@DataJ)) or 			@Recalc_CO_luniant=1)
		Begin
			Set @Venit_net=@Suma_CO-round(@Suma_CO*(case when @Somaj=1 then @nSomaj/100 else 0 end),0)- 				round(@Suma_CO*@CASS/1000,0)-round(@Suma_CO*@nCasindiv/100,0)
			if @Grupa_de_munca not in ('O','P') and @Tip_colab<>'FDP' and @Calcul_CO_net_FDP=0
				exec calcul_deducere @Suma_CO, @Nr_pers_intr, @Ded_pers output

			Set @Venit_baza=(case when @Venit_net-@Ded_pers<0 then 0 else @Venit_net-@Ded_pers end)
			exec calcul_impozit_salarii @Venit_baza, @Impozit output, 0
			if @Salubris=1 and @Zile_CO>@Ore_luna/16 
				exec calcul_retineri_CO_Salubris @Marca, @Data_inchisa, @Retineri output

			Set @Indemnizatie_CO_net=@Venit_net-@Impozit-@Retineri
			exec scriuConcodih @Data_CO, @Marca, '9', @Data_inceput, @Data_sfarsit_net, @Zile_CO, 
				@Indemnizatie_CO_net, @nData_inreg, @lData_op, @nData_op, 1
		End
	End
End	
