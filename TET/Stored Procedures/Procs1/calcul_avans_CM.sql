--***
/**	procedura calcul avans CM	*/
Create 
procedure calcul_avans_CM
	@DataJos datetime, @DataSus datetime, @pMarca char(6), @Avans_CM float output, @Zile_lucr_CM115 int output
As
Begin
	declare @Data datetime, @Marca char(6), @Data_inceput datetime, @Data_sfarsit datetime, @Zile_lucratoare_CM int,
	@Procent_CM float, @Baza_de_calcul float, @Avans_proc_CM int, @Proc_avans_CM float, @nProc_avans float, @nOre_avans float, @Ore_luna float, @Zile_luna float, @Zile_lucr_115 int, @Sp1_suma int, @Sp2_suma int, @Sp3_suma int, @Sp4_suma int, 
	@Sp5_suma int, @Sp6_suma int, @Spspec_suma int, @Indcond_suma int
	Set @Ore_luna=dbo.iauParLN(@datasus,'PS','ORE_LUNA')
	Set @Zile_luna=@Ore_luna/8
	Set @nProc_avans=dbo.iauParN('PS','PROCAV')
	Set @Avans_proc_CM=dbo.iauParL('PS','AV_%CM')
	Set @Proc_avans_CM=dbo.iauParN('PS','AV_%CM')
	Set @nOre_avans=dbo.iauParN('PS','OREAVANS')
	Set @Spspec_suma=dbo.iauParL('PS','SSP-SUMA')
	Set @Sp1_suma=dbo.iauParL('PS','SC1-SUMA')
	Set @Sp2_suma=dbo.iauParL('PS','SC2-SUMA')
	Set @Sp3_suma=dbo.iauParL('PS','SC3-SUMA')
	Set @Sp4_suma=dbo.iauParL('PS','SC4-SUMA')
	Set @Sp5_suma=dbo.iauParL('PS','SC5-SUMA')
	Set @Sp6_suma=dbo.iauParL('PS','SC6-SUMA')
	Set @Indcond_suma=dbo.iauParL('PS','INDC-SUMA')
	Set @Zile_lucr_CM115=0

	Declare cursor_avans_CM Cursor For
	Select a.Data, a.Marca, a.Data_inceput, a.Data_sfarsit, a.Zile_lucratoare, a.Procent_aplicat, p.Salar_de_incadrare 
	*(case when @Proc_avans_CM<>0 then 1 else 
	(1+p.Spor_vechime/100+(case when @Indcond_suma=0 then p.indemnizatia_de_conducere/100 else 0 end)
	+(case when @Spspec_suma=0 then p.spor_specific/100 else 0 end)
	+(case when @Sp1_suma=0 then p.spor_conditii_1/100 else 0 end)
	+(case when @Sp2_suma=0 then p.spor_conditii_2/100 else 0 end)
	+(case when @Sp3_suma=0 then p.spor_conditii_3/100 else 0 end)
	+(case when @Sp4_suma=0 then p.spor_conditii_4/100 else 0 end)
	+(case when @Sp5_suma=0 then p.spor_conditii_5/100 else 0 end)
	+(case when @Sp6_suma=0 then p.spor_conditii_6/100 else 0 end)) end)
	from conmed a
		left outer join personal p on a.marca=p.marca
	where a.Data=@DataSus and a.Marca=@pmarca and a.Tip_diagnostic<>'0-'

	open cursor_avans_CM
	fetch next from cursor_avans_CM into @Data, @Marca, @Data_inceput, @Data_sfarsit, @Zile_lucratoare_CM, @Procent_CM, @Baza_de_calcul
	While @@fetch_status=0
	Begin
		Set @Zile_lucr_115=0
		if @Data_inceput<=dateadd(day,14,@DataJos) and @Data_sfarsit>dateadd(day,14,@DataJos) or @Proc_avans_CM<>0
			Set @Zile_lucr_115=dbo.Zile_lucratoare(@Data_inceput,(case when @Proc_avans_CM<>0 and @Data_sfarsit<=dateadd(day,14,@DataJos) then @Data_sfarsit else dateadd(day,14,@DataJos) end))

		if @Proc_avans_CM=0 or @Data_inceput>=@DataJos and @Data_inceput<=dateadd(day,14,@DataJos)
		Begin
			Set @Avans_CM=@Avans_CM+round(@Baza_de_calcul/((case when @Proc_avans_CM<>0 then @nOre_avans else @Ore_luna end)/8)*(case when @Zile_lucr_115<>0 or @Proc_avans_CM<>0 then @Zile_lucr_115 else @Zile_lucratoare_CM end)
			*(case when @Proc_avans_CM<>0 then @Proc_avans_CM/100 else @Procent_CM end)*@nProc_avans/100,0)
			Set @Zile_lucr_CM115=@Zile_lucr_CM115+sum(case when @Zile_lucr_115<>0 or @Proc_avans_CM<>0
			then @Zile_lucr_115 else @Zile_lucratoare_CM end)
		End
		fetch next from cursor_avans_CM into @Data, @Marca, @Data_inceput, @Data_sfarsit, @Zile_lucratoare_CM, @Procent_CM, @Baza_de_calcul
	End
	close cursor_avans_CM
	Deallocate cursor_avans_CM
End
