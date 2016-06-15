--***
/**	procedura calcul spor conditii	*/
Create
procedure  [dbo].[pCalcul_spor_conditii]
@DataJ datetime, @DataS datetime, @MarcaJos char(6), @MarcaSus char(6), @LocmJos char(9), @LocmSus char(9), @Ore_luna float, @OreM_luna float, @ScadOS_RN int, @ScadO100_RN int, @NuSpc_OIT float, @Sp1_suma int,@Sp2_suma int,@Sp3_suma int, @Sp4_suma int,@Sp5_suma int, @Sp6_suma int, @Sp1_oreg int, @Sp2_oreac int, @Spc_sumafixa int, @Sp6_proc_suma int, @Suma_bazasp6 float, @Sp6_oreluna int, @Spc_O100 int, @Sp1_sumazi int, @Plata_ora int, @Pasmatex int, @Drumco int, @Salubris int, @DSVET int, @ARLCJ int, @Gencom int, @Drumor int, @Term char(8) 
As
Begin
/*
Variabila @SpCondOL s-a adaugat pt. compatibilitate in urma in cazul calculului sporurilor de conditii functie de ore introduse.
Pana la introducerea variabilei, daca s-a setat [X]Dupa ore introduse, si orele introduse erau 0, calculul se facea la ore lucrate.
*/
	declare @SpCondOL int, @SpCond1OI int, @SpCond2OI int, @SpCond3OI int, @SpCond4OI int, @SpCond5OI int, @SpCond6OI int
	set @SpCondOL=dbo.iauParL('PS','SCONDOL')
	set @SpCond1OI=dbo.iauParL('PS','SCOND1')
	set @SpCond2OI=dbo.iauParL('PS','SCOND2')
	set @SpCond3OI=dbo.iauParL('PS','SCOND3')
	set @SpCond4OI=dbo.iauParL('PS','SCOND4')
	set @SpCond5OI=dbo.iauParL('PS','SCOND5')
	set @SpCond6OI=dbo.iauParL('PS','SCOND6')

	If not exists (Select * from tempdb..sysobjects where name='##brut_spc' and type = 'U')
	Begin
		Create table dbo.##brut_spc (Terminal char(8), Data datetime, Marca char(6), Loc_de_munca char(9), Spor_cond_1 float, 		Spor_cond_2 float, Spor_cond_3 float, Spor_cond_4 float, Spor_cond_5 float, Spor_cond_6 float)
		Create Unique Clustered Index Data_marca_lm on [##brut_spc] (Terminal, Data, Marca, Loc_de_munca)
	End
	delete from ##brut_spc where Terminal=@Term
	insert into dbo.##brut_spc (Terminal,Data,Marca,Loc_de_munca,Spor_cond_1,Spor_cond_2,Spor_cond_3,Spor_cond_4, Spor_cond_5, Spor_cond_6) 
	select @Term, @DataS, a.Marca, a.Loc_de_munca,
	round(sum(case when @SpCond1OI=1 and a.Ore__cond_1=0 and @SpCondOL=0 or @DSVET=1 then 0 when @Sp1_suma=1 and @Spc_sumafixa=1 then a.spor_conditii_1 when @Sp1_suma=1 and @Sp1_sumazi=1 then a.spor_conditii_1*(case when a.Ore__cond_1>0 then a.Ore__cond_1/c.regim_de_lucru else  convert(int,(ore_acord+ore_regie+@ScadOS_RN*(ore_suplimentare_1+ore_suplimentare_2+ore_suplimentare_3+ore_suplimentare_4)+ @ScadO100_RN*ore_spor_100)/c.regim_de_lucru) end) when @Sp1_suma=1 then a.spor_conditii_1*(case when Ore__cond_1=0 and @Drumor=1 or @Drumco=1 then (@Ore_luna/8*c.regim_de_lucru) when Ore__cond_1=0 then @Sp1_oreg*a.ore_acord+a.ore_regie+ a.ore_intrerupere_tehnologica*@NuSpc_OIT/100 else Ore__cond_1 end)/(@Ore_luna/8*c.regim_de_lucru) else a.spor_conditii_1/100*(case when a.Ore__cond_1>0 then a.Ore__cond_1 else (@Sp1_oreg*a.ore_acord+a.ore_regie+ a.ore_intrerupere_tehnologica*@NuSpc_OIT/100+@Spc_O100*a.ore_spor_100) end)*(case when @Plata_ora=1 and b.salar_lunar_de_baza<>0 then b.salar_lunar_de_baza/@Ore_luna else c.salar_orar end) end),0),
	round(sum(case when @SpCond2OI=1 and a.Ore__cond_2=0 and @SpCondOL=0 or @Gencom=1 then 0 when @Sp2_suma=1 and @Spc_sumafixa=1 then a.spor_conditii_2 when @Sp2_suma=1 then a.spor_conditii_2*(case when Ore__cond_2=0 and @Drumor=1 or @Drumco=1 then (@Ore_luna/8*c.regim_de_lucru) when Ore__cond_2=0 then (a.ore_acord+@Sp2_oreac*a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100+(case when @Pasmatex=1 then a.ore_concediu_de_odihna else 0 end)) else Ore__cond_2 end)/(@Ore_luna/8*c.regim_de_lucru) else a.spor_conditii_2/100*(case when a.Ore__cond_2>0 then a.Ore__cond_2 else (a.ore_acord+@Sp2_oreac*a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100+(case when @Pasmatex=1 then a.ore_concediu_de_odihna else 0 end)+@Spc_O100*a.ore_spor_100) end)*c.salar_orar end),0),
	round(sum(case when @SpCond3OI=1 and a.Ore__cond_3=0 and @SpCondOL=0 then 0 when @Sp3_suma=1 and @Spc_sumafixa=1 then a.spor_conditii_3 when @Sp3_suma=1 then a.spor_conditii_3*(case when Ore__cond_3=0 and @Drumor=1 or @Drumco=1 then (@Ore_luna/8*c.regim_de_lucru) when Ore__cond_3=0 then a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100 else Ore__cond_3 end)/(@Ore_luna/8*c.regim_de_lucru) else a.spor_conditii_3/100*(case when a.Ore__cond_3>0 then a.Ore__cond_3 else (a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100+@Spc_O100*a.ore_spor_100) end)*c.salar_orar end),0),
	round(sum(case when @SpCond4OI=1 and a.Ore__cond_4=0 and @SpCondOL=0 then 0 when @Sp4_suma=1 and @Spc_sumafixa=1 then a.spor_conditii_4 when @Sp4_suma=1 then a.spor_conditii_4*(case when Ore__cond_4=0 and @Drumor=1 or @Drumco=1 then (@Ore_luna/8*c.regim_de_lucru) when Ore__cond_4=0 then a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100 else Ore__cond_4 end)/(@Ore_luna/8*c.regim_de_lucru) else a.spor_conditii_4/100*(case when a.Ore__cond_4>0 then a.Ore__cond_4 else (a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100+@Spc_O100*a.ore_spor_100) end)*c.salar_orar end),0),
	round(sum(case when @SpCond5OI=1 and a.Ore__cond_5=0 and @SpCondOL=0 then 0 when @Sp5_suma=1 and @Spc_sumafixa=1 then a.spor_conditii_5 when @Sp5_suma=1 then a.spor_conditii_5*(case when Ore__cond_5=0 and @Drumor=1 or @Drumco=1 then (@Ore_luna/8*c.regim_de_lucru) when Ore__cond_5=0 then a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100 else Ore__cond_5 end)/(@Ore_luna/8*c.regim_de_lucru) else a.spor_conditii_5/100*(case when a.Ore__cond_5>0 then a.Ore__cond_5 else (a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100+@Spc_O100*a.ore_spor_100) end)*c.salar_orar end),0),
	round(sum(case when @SpCond6OI=1 and a.Ore_donare_sange=0 and @SpCondOL=0 then 0 when @Sp6_suma=1 and @Spc_sumafixa=1 then a.spor_conditii_6 when @Sp6_suma=1 then a.spor_conditii_6*(case when Ore_donare_sange=0 and @Drumor=1 or @Drumco=1 then ((case when a.tip_salarizare<3 then @Ore_luna else @OreM_luna end)/8*c.regim_de_lucru) when Ore_donare_sange=0 then a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100 else Ore_donare_sange end)/((case when a.tip_salarizare<3 or @Sp6_oreluna=1 then @Ore_luna else @OreM_luna end)/8*c.regim_de_lucru) else a.spor_conditii_6/100*(case when @Sp6_proc_suma=1 then @Suma_bazasp6*convert(int,(a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100+ @ARLCJ*(@ScadOS_RN*(ore_suplimentare_1+ore_suplimentare_2+ore_suplimentare_3+ore_suplimentare_4)+ @ScadO100_RN*ore_spor_100))/c.regim_de_lucru)/((case when a.tip_salarizare<3 or @Sp6_oreluna=1 then @Ore_luna else @OreM_luna end)/8) else (case when a.Ore_donare_sange>0 then a.Ore_donare_sange else (a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100+@Spc_O100*a.ore_spor_100+ @Salubris*(ore_suplimentare_1+ore_suplimentare_2-ore_suplimentare_3)) end)*c.salar_orar end) end),0)
	from pontaj a,personal b,##salor c 
	where a.data between @DataJ and @DataS and a.marca=b.marca and c.HostID=@Term and a.Data=c.Data and a.marca=c.marca 
		and a.marca between @MarcaJos and @MarcaSus and a.loc_de_munca=c.loc_de_munca 
		and a.loc_de_munca between @LocmJos and @LocmSus and a.numar_curent=c.numar_curent 
	group by a.marca,a.loc_de_munca

	update brut set Spor_cond_1=b.Spor_cond_1, Spor_cond_2=b.Spor_cond_2, Spor_cond_3=b.Spor_cond_3, 
		Spor_cond_4=b.Spor_cond_4, Spor_cond_5=b.Spor_cond_5, Spor_cond_6=b.Spor_cond_6
	from ##brut_spc b 
	where brut.data between @DataJ and @DataS and brut.marca between @MarcaJos and @MarcaSus 
		and brut.loc_de_munca between @LocmJos and @LocmSus and b.Terminal=@Term and brut.Data=b.Data 
		and brut.marca=b.marca and brut.loc_de_munca=b.loc_de_munca 
	delete from ##brut_spc where Terminal=@Term
End
