--***
/**	procedura update pe venituri pe conditii de munca */
Create
procedure [dbo].[pUpdate_venit_conditii_munca]
	(@DataJ datetime,@DataS datetime,@MarcaJ char(6),@MarcaS char(6),@LmJ char(9),@LmS char(9),@GrupaM char(1),
	@Ore_luna float, @OreM_luna float,@ScadOS_RN int,@NuSpc_OIT float,@Sp6_suma int,@Spc_sfixa int,@Sp6_prsuma int,
	@Suma_bazasp6 float, @Sp6_oreluna int,@Spc_O100 int,@Salubris int,@Colas int,@ARLCJ int,@Drumor int, @Term char(8))
As
Begin
	update ##brut_cond
	Set Venit_conditii=Venit_conditii+
		isnull((select round(sum((case when @Sp6_suma=1 and @Spc_sfixa=1 then a.spor_conditii_6 when @Sp6_suma=1 then a.spor_conditii_6*(case when Ore_donare_sange=0 and @Drumor=1 then ((case when a.tip_salarizare<3 then @Ore_luna else @OreM_luna end)/8*c.regim_de_lucru) when Ore_donare_sange=0  then (a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100) else Ore_donare_sange end)/((case when a.tip_salarizare<3 or @Sp6_oreluna=1 then @Ore_luna else @OreM_luna end)/8*c.regim_de_lucru) else a.spor_conditii_6/100*(case when @Sp6_prsuma=1 then @Suma_bazasp6*convert(int,(a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100
		+@ARLCJ*(@ScadOS_RN*(ore_suplimentare_1+ore_suplimentare_2+ore_suplimentare_3+ore_suplimentare_4)+ @NuSpc_OIT*ore_spor_100))/c.regim_de_lucru)/((case when a.tip_salarizare<3 or @Sp6_oreluna=1 then @Ore_luna else @OreM_luna end)/8) else (case when a.Ore_donare_sange>0 then a.Ore_donare_sange else (a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100+@Spc_O100*a.ore_spor_100
		+@Salubris*(ore_suplimentare_1+ore_suplimentare_2-ore_suplimentare_3+ore_suplimentare_4)) end)*c.salar_orar end) end)),0)+
		(case when @Colas=1 then round(sum(a.spor_cond_8*c.salar_orar*75/100),0) else 0 end) 
		from pontaj a,personal b,##salor c
			where a.data between @DataJ and @DataS and a.marca=b.marca and c.HostID=@Term and a.Data=c.Data and a.marca=c.marca 
			and a.loc_de_munca=c.loc_de_munca and a.numar_curent=c.numar_curent and brut.marca=a.marca and brut.loc_de_munca=a.loc_de_munca 
			and a.marca between @MarcaJ and @MarcaS and a.loc_de_munca between @LmJ and @LmS 
			and a.grupa_de_munca=@GrupaM group by a.marca,a.loc_de_munca),0)
	from brut
	where brut.data=@DataS and brut.marca between @MarcaJ and @MarcaS and brut.loc_de_munca between @LmJ and @LmS
	and brut.data=##brut_cond.data and brut.Marca=##brut_cond.Marca and brut.loc_de_munca=##brut_cond.loc_de_munca
	and ##brut_cond.Terminal=@Term
End
