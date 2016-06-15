--***
/**	procedura prima de vacanta	*/
Create 
procedure calcul_prima_de_vacanta
@Datajos datetime, @Datasus datetime, @pCalcul_prima int, @Baza_calcul_prima char(1), @Procent_prima float, @Media_zilnica float, @Indemnizatie_CO float, @Tip_concediu char(1), @Zile_CO int, @Zile_prima_vacanta int, @Zile_CO_an int, @Zile_CO_marca int, @Data_angajarii datetime, @Salar_de_incadrare float, @Salar_de_baza float, @Salar_de_baza_istpers float, @Functionar_public int, @Gasit_prima_ant int, @Ani_vechime int, @lBuget int, @lInstitutie int, @Sindrom int, @Stoehr int, @Spicul int, @Salubris int, @vPrima_vacanta float output
As
Begin
	declare @Nr_luni_prima int 
	if @pCalcul_prima=1 and @Baza_calcul_prima='2'
		Set @Nr_luni_prima=(case when @Data_angajarii<dbo.boy(@DataSus) then 12 
			else 12-month(@Data_angajarii)+(case when day(@Data_angajarii)=1 then 1 else 0 end) end)

	if @pCalcul_prima=1 and @Sindrom=1
		Set @vPrima_vacanta=@Indemnizatie_CO*(case when @Ani_vechime<3 then 0.5 
		when @Ani_vechime<5 then 0.55 when @Ani_vechime<10 then 0.6 
		when @Ani_vechime<15 then 0.65 else 0.7 end)

	if (@Stoehr=1 or @pCalcul_prima=1 and @Baza_calcul_prima='1') and @Sindrom=0
		Set @vPrima_vacanta=@vPrima_vacanta+(case when @tip_concediu in ('1','3','4') 
			then @Indemnizatie_CO*(case when @pCalcul_prima=1 and @Procent_prima<>0 then @Procent_prima/100 else 1 end) else 0 end)
	if @Spicul=1 or @pCalcul_prima=1 and @Baza_calcul_prima='2' and @Gasit_prima_ant=0
		Set @vPrima_vacanta=(case when @lBuget=1 or @lInstitutie=1 
			then (case when @Functionar_public=1 then @Salar_de_baza_istpers else @Salar_de_baza end) else @Salar_de_incadrare end)*@Procent_prima/100*@Nr_luni_prima/12

	if @pCalcul_prima=1 and @Baza_calcul_prima='5' and @Gasit_prima_ant=0
		Set @vPrima_vacanta=(case when @Media_zilnica=0 then @Indemnizatie_CO/@Zile_CO else @Media_zilnica end)*@Zile_CO_an*@Procent_prima/100

	If @Spicul=1
		Set @vPrima_vacanta=round(@vPrima_vacanta*@Zile_prima_vacanta/12,0)

	if @pCalcul_prima=1 and @Baza_calcul_prima='3' and @Gasit_prima_ant=0
		Set @vPrima_vacanta=@Procent_prima

	if @pCalcul_prima=1 and @Baza_calcul_prima='6' and @Gasit_prima_ant=0
		Set @vPrima_vacanta=round(@Procent_prima*@Zile_CO/@Zile_CO_an,0)
--	rotunjire
	Set @vPrima_vacanta=round(@vPrima_vacanta,0)
End
