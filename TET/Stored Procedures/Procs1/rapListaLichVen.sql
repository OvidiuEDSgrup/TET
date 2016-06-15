--***
Create procedure [dbo].[rapListaLichVen] @DataJ datetime, @DataS datetime, @oMarca int, @Marca char(6), @unLm int, @Lm char(9), @Strict int, 
	@Centralizat char(1)='S', @NivelCentr int=0
as
begin
	declare @userASiS char(10), @LmStatPlSal int, @CodBenSindicat char(13), @CodBenCONet char(13), 
	@Subtipret int, @TipRetSind char(1), @IndCondSalBaza int, @SpSpecSalBaza int, @Sp1SalBaza int, 
	@Salubris int, @LungimeNivel int

	set @userASiS=dbo.fIaUtilizator(null)
	set @LmStatPlSal=dbo.iauParL('PS','LOCMSALAR')
	set @CodBenSindicat=dbo.iauParA('PS','SIND%')
	set @CodBenCONet=dbo.iauParA('PS','CODBCO')
	set @Subtipret=dbo.iauParl('PS','SUBTIPRET')
	select @TipRetSind=Tip_retinere from tipret where Subtip in (select Tip_retinere from benret where Cod_beneficiar=@CodBenSindicat)
	set @IndCondSalBaza=dbo.iauParL('PS','SBAZA-IND')
	set @SpSpecSalBaza=dbo.iauParL('PS','S-BAZA-SP')
	set @Sp1SalBaza=dbo.iauParL('PS','S-BAZA-S1')
	set @Salubris=dbo.iauParL('SP','SALUBRIS')
	select @LungimeNivel=Lungime from strlm where Nivel=@NivelCentr

	if object_id('tempdb..#TmpCorectii') is not null drop table #TmpCorectii
	if object_id('tempdb..#TmpBrut') is not null drop table #TmpBrut

--	cursor pt. date din corectii pe marci
	SELECT dbo.eom(c.Data) Data, P.loc_de_munca Loc_de_munca, P.marca,
	sum( CASE TIP_CORECTIE_VENIT WHEN 'H-' THEN  C.SUMA_CORECTIE ELSE 0 END ) SumaImpoz,
	sum( CASE TIP_CORECTIE_VENIT WHEN 'I-' THEN C.SUMA_CORECTIE ELSE 0 END ) Premii,
	sum( CASE TIP_CORECTIE_VENIT WHEN 'G-' THEN 
	(CASE WHEN C.SUMA_CORECTIE= 0 AND C.Procent_corectie<> 0 THEN -round( (P.SALAR_DE_INCADRARE/ 100) * C.Procent_corectie,0) 
		WHEN C.SUMA_CORECTIE<> 0 AND C.Procent_corectie= 0  THEN -C.SUMA_CORECTIE 
		WHEN C.SUMA_CORECTIE<> 0 AND C.Procent_corectie<> 0  THEN -C.SUMA_CORECTIE ELSE 0 END)
	ELSE 0 END) AlteDrepturi,
	sum( CASE TIP_CORECTIE_VENIT WHEN 'K-' THEN C.SUMA_CORECTIE ELSE 0 END ) ConsAdmin,
	sum( CASE WHEN (TIP_CORECTIE_VENIT='J-' OR TIP_CORECTIE_VENIT='F-' OR TIP_CORECTIE_VENIT='D-') THEN C.SUMA_CORECTIE ELSE 0 END ) AlteCorectii,
	sum( CASE TIP_CORECTIE_VENIT WHEN 'X-' THEN C.SUMA_CORECTIE ELSE 0 END ) Premii2,
	COUNT( DISTINCT P.marca) NrPers
	into #TmpCorectii
 	FROM CORECTII C
		INNER JOIN PERSONAL P ON C.marca= P.marca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=c.Loc_de_munca
	WHERE C.data BETWEEN @DataJ AND @DataS
		AND (@oMarca= 0 OR p.marca=@Marca)
		AND (@unLm=0 or P.loc_de_munca like rtrim(@Lm) +(case when @Strict= 0 then '%' else '' end))
		AND (P.Loc_ramas_vacant= 0 OR ( P.Loc_ramas_vacant= 1 AND P.data_plec >= @DataJ))
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	GROUP BY dbo.eom(c.Data), P.loc_de_munca, P.marca

--	cursor pt. date din brut
	SELECT b.Data, (case when @LmStatPlSal=1 then P.Loc_de_munca else N.loc_de_munca end) Loc_de_munca,
	b.marca, sum( isnull( P.SALAR_DE_INCADRARE, 0)) SalIncadrare,
	sum( B.realizat__regie-(case when @IndCondSalBaza=1 then b.ind_nemotivate else 0 end)
	-(case when @SpSpecSalBaza=1 then round(b.spor_specific,0) else 0 end)-(case when @Sp1SalBaza=1 then round(b.spor_cond_1,0) else 0 end))
	/*sum( B.ind_regim_normal)*/+
	isnull((select sum(pj.Salar_categoria_lucrarii*pj.Ore_lucrate) 
			from pontaj pj 
			where pj.data BETWEEN @DataJ AND @DataS and pj.marca=b.marca),0) Regie,
	sum( B.realizat_acord) ACORD,
	sum( (case when @Salubris=1 then 0 else B.Indemnizatie_ore_supl_1+B.Indemnizatie_ore_supl_2+B.Indemnizatie_ore_supl_3+B.Indemnizatie_ore_supl_4 end) +B.indemnizatie_ore_spor_100) IndOreSupl,
	sum( B.ind_obligatii_cetatenesti) IndOblCet,
	sum( (case when @Salubris=1 then B.Indemnizatie_ore_supl_1+B.Indemnizatie_ore_supl_2 else B.Ind_intrerupere_tehnologica +B.Ind_invoiri end)) IndIntrTehn,
	sum( round(B.spor_cond_1,0)) SpCond1, sum( round(B.spor_cond_6,0)) SpCond6, 
	sum( round(B.spor_cond_3,0)) SpCond3, sum( round(B.ind_ore_de_noapte,0)) SpNoapte, 
	sum( round(B.spor_cond_2,0)) SpCond2, sum( round(B.spor_cond_4,0)) SpCond4,
	sum( round(B.spor_cond_5,0)) SpCond5, sum( round(B.spor_cond_7,0)) SpCond7,
	sum( round(B.spor_specific,0)) SpSpecific, sum( round(B.spor_vechime,0)) SpVechime,
	sum( B.Ind_nemotivate) IndCond, sum( B.ind_concediu_de_odihna) IndCO,
	sum( B.suma_imp_separat) PrimaV, sum( B.ind_c_medical_unitate+B.CMUnitate) CMUnitate,
	sum( B.ind_c_medical_CAS+B.CMCAS) CMFnuass, sum( B.spor_cond_9) CMFaambp,
	sum( B.Spor_sistematic_peste_program+ B.Spor_de_functie_suplimentara) AlteSporuri,
	sum( B.Premiu) PREMII, sum( B.Suma_impozabila) SumaImpoz,	sum( B.Cons_admin) ConsAdmin,
	sum( B.Diurna+B.Restituiri+B.CO) AlteCorectii, sum( -B.Diminuari+B.Sp_salar_realizat) AlteDrepturi,
	Sum( B.Venit_Total) as VenitTotal, COUNT( DISTINCT B.marca) NrPers
	into #TmpBrut
	FROM BRUT B
		INNER JOIN net N ON (B.marca=N.marca and B.data=N.data)
--		INNER JOIN brut B1 ON (B.marca= B1.marca and B.data= B1.data) 
		LEFT JOIN PERSONAL P ON B.marca= P.marca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=b.Loc_de_munca
	WHERE /*(B1.Loc_munca_pt_stat_de_plata= 1 
	or isnull((select count(1) from brut B2 where B2.Data=B.Data and B2.Marca=B.Marca),0)=1) AND */
	B.data BETWEEN @DataJ AND @DataS 
		AND (@oMarca= 0 OR B.marca=@Marca) 
		AND (@unLm=0 or N.loc_de_munca like rtrim(@Lm) +(case when @Strict=0 then '%' else '' end))
		AND (P.Loc_ramas_vacant= 0 OR (P.Loc_ramas_vacant= 1 AND P.data_plec >= @DataJ))
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	GROUP BY b.Data, (case when @LmStatPlSal=1 then P.Loc_de_munca else N.loc_de_munca end), B.marca

--	centralizare date
	select @DataS as Data, (case when @Centralizat='T' then '' else LM.Cod end) as LM, 
	(case when @Centralizat='T' then '' else max(LM.denumire) end) as DenLM, 
	(case when @Centralizat='S' then isnull(T1.Marca, T2.Marca) else '' end) as Marca, (case when @Centralizat='S' then max(P.nume)else '' end) as Nume, 
	sum( round( isnull( T1.SalIncadrare, 0), 0)) SalIncadrare,
	sum( round( isnull( T1.REGIE, 0), 0)) REGIE, sum( round( isnull( T1.ACORD, 0), 0)) ACORD,
	sum( round( isnull( T1.IndOreSupl, 0),0)) IndOreSupl, sum( round( isnull( T1.IndOblCet, 0), 0)) IndOblCet,
	sum( round( isnull( T1.IndIntrTehn, 0), 0)) IndIntrTehn, sum( round( isnull( T1.SpCond1, 0), 0)) SpCond1,
	sum( round( isnull( T1.SpCond6, 0), 0)) SpCond6, sum( round( isnull( T1.SpCond3, 0), 0)) SpCond3,
	sum( round( isnull( T1.SpNoapte, 0),0)) SpNoapte, sum( round( isnull( T1.SpCond2, 0), 0)) SpCond2,
	sum( round( isnull( T1.SpCond4, 0), 0)) SpCond4, sum( round( isnull( T1.SpCond5, 0), 0)) SpCond5,
	sum( round( isnull( T1.SpCond7, 0), 0)) SpCond7, sum( round( isnull( T1.SpSpecific, 0), 0)) SpSpecific,
	sum( round( isnull( T1.SpVechime, 0), 0)) SpVechime, sum( round( isnull( T1.IndCond, 0), 0)) IndCond,
	sum( round( isnull( T1.SumaImpoz, 0), 0)) SumaImpoz, sum( round( isnull( T1.IndCO, 0), 0)) IndCO,
	sum( round( isnull( T1.PrimaV, 0), 0)) PrimaV, sum( round( isnull( T1.Premii,0)-isnull( T2.Premii2,0),0)) Premii,
	sum( round( isnull( T2.Premii2,0), 0)) Premii2, 
	sum( round( isnull( T1.AlteDrepturi,0)+isnull(T1.ConsAdmin,0)+isnull(T1.AlteCorectii,0)+ isnull(T1.AlteSporuri, 0), 0)) AlteDrept,
	sum( round( isnull( T1.CMUnitate, 0), 0)) CMUnitate, sum( round( isnull( T1.CMFnuass, 0), 0)) CMFnuass,
	sum( round( isnull( T1.CMFaambp, 0), 0)) CMFaambp, 
	sum(T1.VenitTotal-(T1.CMFnuass+T1.CMFaambp)) as TotalSalar, sum(T1.VenitTotal) as TotalBrut,
	COUNT (DISTINCT isnull(T1.Marca, T2.Marca)) NrPers
	from #TmpBrut AS T1		
		full outer join #TmpCorectii AS T2 ON (/*T1.Loc_de_munca= T2.Loc_de_munca and*/ T1.Data=T2.Data and T1.Marca= T2.Marca)
		left outer join personal P ON isnull(T1.Marca, T2.Marca)= P.Marca
		inner join LM ON (@Centralizat='T' and LM.cod=T1.Loc_de_munca or @Centralizat='S' and LM.COD=isnull( T1.Loc_de_munca, T2.Loc_de_munca) 
		or @Centralizat in ('N','L') and LM.COD=left(isnull( T1.Loc_de_munca, T2.Loc_de_munca), LEN( RTRIM( LM.cod))))
	WHERE (@unLm=0 or isnull( T1.Loc_de_munca, T2.Loc_de_munca) like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end))
	GROUP BY (case when @Centralizat='T' then '' else LM.Cod end), 
		(case when @Centralizat='S' then isnull(T1.Marca, T2.Marca) else '' end)
	HAVING (@Centralizat<>'N' or @Centralizat='N' and len(rtrim((case when @Centralizat='T' then '' else LM.Cod end)))=@LungimeNivel)	
	Order BY (case when @Centralizat='T' then '' else LM.Cod end), 
		(case when @Centralizat='S' then isnull(T1.Marca, T2.Marca) else '' end)

	if object_id('tempdb..#TmpCorectii') is not null drop table #TmpCorectii
	if object_id('tempdb..#TmpBrut') is not null drop table #TmpBrut

	return
end

/*
	exec rapListaLichVen '07/01/2011', '07/31/2011', 0, '', 0, '', 0, 'S', 0
*/
