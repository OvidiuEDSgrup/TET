--***
/**	procedura calcul Dim L118	*/
Create
procedure  psCalculDiminuariL118 
@DataJ datetime, @DataS datetime, @pmarca char(6), @pLocm char(6)
as
Begin
	if exists (select 1 from sysobjects where [type]='P' and [name]='psCalculDiminuariL118SP')
	Begin
		exec psCalculDiminuariSP @DataJ, @DataS, @pmarca, @pLocm
	End
	else
	Begin
	declare @TipCorectieDiminuare char(2), @ProcentDiminuare decimal(10,2), @SalMin float, @OreLuna int, @NrMedOL int, 
	@Subtipcor int, @Data datetime, @Marca char(6), @Loc_de_munca char(9), @GrpMP char(1), @VenitTotal decimal(10), 		@SumeExceptate decimal(10), @BazaComparatie decimal(10), @BazaDiminuare decimal(10), @ValoareDiminuare decimal(10), 		@SirCorectiiExceptate char(100)
	Set @ProcentDiminuare=dbo.iauParN('PS','DIML118')
	Set @TipCorectieDiminuare=dbo.iauParA('PS','DIML118')
	Set @SirCorectiiExceptate=dbo.iauParA('PS','CEXCDL118')
	Set @SalMin=dbo.iauParLN(@DataS,'PS','S-MIN-BR')
	Set @OreLuna=dbo.iauParLN(@DataS,'PS','ORE_LUNA')
	Set @NrMedOL=dbo.iauParLN(@DataS,'PS','NRMEDOL')
	Set @Subtipcor=dbo.iauParL('PS','SUBTIPCOR')
	Declare cursor_diminuari Cursor For
	select b.Data, b.Marca, max(p.Loc_de_munca), max(p.Grupa_de_munca), 
	sum(b.Venit_total), sum(b.Ind_c_medical_unitate+b.Ind_c_medical_CAS+b.Spor_cond_9)+isnull(max(c.Suma_corectie),0), 
	round(((@SalMin/8*(case when max(p.Salar_lunar_de_baza)=0 then 8 else max(p.Salar_lunar_de_baza) end))
	/(@OreLuna/8*(case when max(p.Salar_lunar_de_baza)=0 then 8 else max(p.Salar_lunar_de_baza) end)))
	*sum(b.Ore_lucrate_regim_normal+b.Ore_concediu_de_odihna+b.Ore_obligatii_cetatenesti),0)
	from brut b
	left outer join personal p on b.Marca=p.Marca
	left outer join (select dbo.eom(data) as Data, Marca, sum((case when c.tip_corectie_venit='G-' or isnull(s.tip_corectie_venit,'')='G-' 		or suma_corectie<0 then -1 else 1 end)*suma_corectie) as Suma_corectie 
	from corectii c left outer join subtipcor s on c.Tip_corectie_venit=s.Subtip where @SirCorectiiExceptate<>'' and c.data between 		@DataJ and @DataS and (@Subtipcor=0 and charindex(c.tip_corectie_venit,@SirCorectiiExceptate)<>0 
	or @Subtipcor=1 and c.Tip_corectie_venit in (select s.Subtip from Subtipcor s where 		charindex(s.tip_corectie_venit,@SirCorectiiExceptate)<>0)) group by dbo.eom(data), Marca) c on b.Data=c.Data and b.Marca=c.Marca
	where b.data between @DataJ and @DataS and (@pmarca = '' or b.marca=@pmarca) 
	and (@pLocm='' or p.Loc_de_munca=@pLocm)
	group by b.Data, b.Marca
	open cursor_diminuari
	fetch next from cursor_diminuari into @data, @marca, @Loc_de_munca, @GrpMP, @VenitTotal, @SumeExceptate, @BazaComparatie 
	While @@fetch_status = 0 
	Begin
		Set @ValoareDiminuare=round((@VenitTotal-@SumeExceptate)*@ProcentDiminuare/100,0)
		Set @ValoareDiminuare=(case when (@VenitTotal-@SumeExceptate)-@ValoareDiminuare<@BazaComparatie then 			@VenitTotal-@SumeExceptate-@BazaComparatie else @ValoareDiminuare end)
		Set @ValoareDiminuare=-@ValoareDiminuare
		if @ValoareDiminuare<>0
		Begin
		insert into corectii (Data, Marca, Loc_de_munca, Tip_corectie_venit, Suma_corectie, Procent_corectie, Suma_neta)
		values (@DataJ, @Marca, @Loc_de_munca, @TipCorectieDiminuare, @ValoareDiminuare, 0, 0)
		update brut set CMCAS=0, CMunitate=0, CO=0, Restituiri=0, Diminuari=0, Suma_impozabila=0, Premiu=0, 
		Diurna=0, Cons_admin=0, Sp_salar_realizat=0, Suma_imp_separat=0, Compensatie=0
		where marca=@marca and data=@DataS and loc_de_munca=@loc_de_munca
		update net set CM_incasat=0, CO_incasat=0, Suma_incasata=0, Suma_neimpozabila=0, Diferenta_impozit=0
		where marca=@marca and data=@DataS
		exec calcul_corectii @DataJ, @DataS, @Marca, ''
		update brut set venit_total=venit_total+@ValoareDiminuare, 									Venit_cond_normale=Venit_cond_normale+(case when @GrpMP in ('N','P','C') then @ValoareDiminuare else 0 end), 
		Venit_cond_deosebite=Venit_cond_deosebite+(case when @GrpMP in ('D') then @ValoareDiminuare else 0 end), 
		Venit_cond_speciale=Venit_cond_speciale+(case when @GrpMP in ('S') then @ValoareDiminuare else 0 end) 
		where brut.data=@DataS and brut.marca=@marca and brut.Loc_de_munca=@Loc_de_munca 
		End
	fetch next from cursor_diminuari into @data, @marca, @Loc_de_munca, @GrpMP, @VenitTotal, @SumeExceptate, @BazaComparatie 
	End
	End
End
close cursor_diminuari
Deallocate cursor_diminuari
