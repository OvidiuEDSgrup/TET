--***
Create procedure [dbo].[rapListaLichRet] 
	@DataJ datetime, @DataS datetime, @oMarca int, @Marca char(6), @unLm int, @Lm char(9), @Strict int, 
	@Centralizat char(1)='S', @NivelCentr int=0, @DetTipRet int=1
as
begin
	declare @userASiS char(10), @CodBenSindicat char(13), @CodBenCONet char(13), @Subtipret int,
	@TipRetSind char(1), @LungimeNivel int

	set @userASiS=dbo.fIaUtilizator(null)
	set @CodBenSindicat=dbo.iauParA('PS','SIND%')
	set @CodBenCONet=dbo.iauParA('PS','CODBCO')
	set @Subtipret=dbo.iauParl('PS','SUBTIPRET')
	select @TipRetSind=Tip_retinere from tipret where Subtip in (select Tip_retinere from benret where Cod_beneficiar=@CodBenSindicat)
	select @LungimeNivel=Lungime from strlm where Nivel=@NivelCentr

	if object_id('tempdb..#TmpCorectii') is not null drop table #TmpCorectii
	if object_id('tempdb..#TmpNet') is not null drop table #TmpNet
	if object_id('tempdb..#TmpRetineri') is not null drop table #TmpRetineri
	if object_id('tempdb..#Retineri') is not null drop table #Retineri
	
--	cursor pt. date din corectii pe marci
	SELECT dbo.eom(c.Data) Data, c.loc_de_munca Loc_de_munca, P.Marca Marca, 
		sum( CASE C.TIP_CORECTIE_VENIT WHEN 'M-' THEN  C.SUMA_CORECTIE ELSE 0 END ) AvansPremii,
		sum( CASE C.TIP_CORECTIE_VENIT WHEN 'E-' THEN  C.SUMA_CORECTIE ELSE 0 END ) AvansCorectie,
		sum( CASE C.TIP_CORECTIE_VENIT WHEN 'P-' THEN  C.SUMA_CORECTIE ELSE 0 END ) DifImpozit
	into #TmpCorectii
 	FROM CORECTII C
		INNER JOIN PERSONAL P ON C.MARCA= P.MARCA
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=c.Loc_de_munca
	WHERE C.data between @DataJ and @DataS AND (@oMarca= 0 OR p.marca=@Marca)
		and (@unLm=0 or c.loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end))
		and ( P.Loc_ramas_vacant= 0 OR ( P.Loc_ramas_vacant= 1 AND P.data_plec >= @DataJ))
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	GROUP BY dbo.eom(c.Data), c.loc_de_munca, P.MARCA

--	cursor pt. date din net
	SELECT net.Data, net.loc_de_munca Loc_de_munca, p.marca,
		sum( net.Somaj_1) Somaj, sum( net.Diferenta_Impozit) DifImpozit, sum( net.Impozit) Impozit, 
		SUM (net.Pensie_suplimentara_3) CAS, sum( net.Asig_sanatate_din_net) AsigSanNet, 
		sum( net.Suma_incasata) AvansPremii, sum( net.CO_incasat) AvansCorectie,
		sum( net.Avans+net.Premiu_la_avans) Avans, 
		sum( net.Debite_externe) DebiteExterne, sum( net.Debite_interne) DebiteInterne, 
		sum( net.Rate) AS Rate, sum( net.Cont_curent) AS CARContCrt, 
		sum( net.rest_de_plata) AS RestDePlata, 
		sum(net.Somaj_1+net.Diferenta_Impozit+net.Impozit+net.Pensie_suplimentara_3+net.Asig_sanatate_din_net
		+net.Suma_incasata+net.CO_incasat+net.Avans+net.Premiu_la_avans) as ContribAvans
	into #TmpNet
	FROM net
		INNER JOIN PERSONAL P ON net.marca= p.marca
	where net.Data BETWEEN @DataJ AND @DataS and net.data=dbo.eom(net.data) 
		and (@oMarca= 0 OR p.marca=@Marca) 
		and (@unLm=0 or net.loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end))
		and (P.Loc_ramas_vacant= 0 OR ( P.Loc_ramas_vacant= 1 AND P.data_plec >= @DataJ))
	GROUP BY net.Data, net.loc_de_munca , p.marca

--	cursor pt. date din retineri
	SELECT r.Data, p.loc_de_munca Loc_de_munca, p.marca, 
		sum( CASE WHEN PATINDEX('%CAR%',b.Obiect_retinere)>0 or (case when @Subtipret=1 then isnull(t.Tip_retinere,0) else b.Tip_retinere end)='4' THEN  /*r.Retinut_la_avans+*/  r.Retinut_la_lichidare ELSE 0 END) AS CARContCrt,
		sum( CASE WHEN b.Cod_beneficiar= '2001' or @CodBenSindicat<>'' and b.Cod_beneficiar=@CodBenSindicat THEN  /*r.Retinut_la_avans+*/ r.Retinut_la_lichidare ELSE 0 END) AS Sindicat,
		sum( CASE WHEN b.Cod_beneficiar= '1256' or @CodBenCONet<>'' and b.Cod_beneficiar=@CodBenCONet THEN  r.Retinut_la_avans+ (case when b.Cod_beneficiar= '1256' then r.Retinere_progr_la_lichidare else r.Retinut_la_lichidare end) ELSE 0 END) AS AvansCO, 
		sum( CASE WHEN (case when @Subtipret=1 then isnull(t.Tip_retinere,0) else b.Tip_retinere end)= '5' and @DetTipRet=0
		THEN  r.Retinut_la_avans+ r.Retinere_progr_la_lichidare ELSE 0 END) AS PensiiFacultative
	into #TmpRetineri
	FROM benret b
		INNER JOIN resal r ON b.cod_beneficiar= r.cod_beneficiar
		LEFT OUTER JOIN tipret t ON b.Tip_retinere= t.Subtip
		INNER JOIN PERSONAL P ON r.marca= p.marca
	WHERE r.Data BETWEEN @DataJ AND @DataS AND (@oMarca=0 OR p.marca=@Marca) 
		AND (@unLm=0 or P.loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end))
		AND (P.Loc_ramas_vacant= 0 OR (P.Loc_ramas_vacant= 1 AND P.data_plec >= @DataJ))
	GROUP BY r.Data, p.loc_de_munca, p.marca

--	centralizare date
	select @DataS as Data, (case when @Centralizat='T' then '' else LM.Cod end) as LM, 
		(case when @Centralizat='T' then '' else max(LM.denumire) end) as DenLM, 
		(case when @Centralizat='S' then T1.Marca else '' end) as Marca, (case when @Centralizat='S' then max(p.Nume) else '' end) as Nume, 
		sum( round( isnull(T1.Somaj, 0), 2) ) as Somaj, 
		sum( round( isnull(T1.Impozit, 0), 2)) as Impozit, 
		sum( round( isnull(T1.CAS, 0), 2)) as CAS, 
		sum( round( isnull(T1.AsigSanNet, 0), 2)) as AsigSanNet, 
		sum( round( isnull(T1.AvansPremii, 0), 2)) as AvansPremii,
		sum( round( isnull(T1.DifImpozit, 0), 2)) as DifImpozit,
		sum( round( isnull(T1.Avans, 0)+ isnull(T1.AvansCorectie, 0), 2)) Avans,
		sum( round( isnull(T3.avansco, 0), 2)) AvansCO,	
		sum( round( isnull(T1.DebiteExterne - (case when @TipRetSind='1' and @DetTipRet=0 then T3.sindicat else 0 end) 
		- (case when @DetTipRet=1 then T3.PensiiFacultative else 0 end), 0), 2)) as DebiteExterne, 	
		sum( round( isnull(T1.DebiteInterne, 0) - isnull((case when @DetTipRet=1 then 0 else T3.AvansCO end)
		+(case when @TipRetSind='3' and @DetTipRet=0 then T3.Sindicat else 0 end), 0), 2)) as DebiteInterne,
		sum( round( isnull(T1.Rate, 0), 2)) as Rate,
		sum( round( isnull(T3.CARContCrt, 0), 2)) as CARContCrt,
		sum( round( isnull(T3.PensiiFacultative, 0), 2)) as PensiiFacultative,
		sum( round( isnull(T3.Sindicat, 0), 2)) as Sindicat,
		sum( round( isnull(T1.RestDePlata, 0), 2)) as RestDePlata, 
		sum( isnull(T1.ContribAvans,0)) as ContribAvans
	into #Retineri
	FROM #TmpNet AS T1 				
		left outer join personal p ON T1.MARCA=p.Marca
		full outer join #TmpCorectii AS T4 ON (/*T1.codlm= T4.codlm and*/T1.Data=T4.Data and T1.marca=T4.marca)
		full outer join #TmpRetineri AS T3 ON ISNULL (T1.Data, T4.Data)=T3.Data and ISNULL (T1.marca, T4.marca)=T3.marca
		inner join LM ON (@Centralizat='T' and LM.cod=T1.Loc_de_munca or @Centralizat='S' and LM.cod= isnull( T1.Loc_de_munca, isnull( T4.Loc_de_munca, T3.Loc_de_munca)) 
		or @Centralizat in ('N','L') and LM.cod=LEFT( isnull( T1.Loc_de_munca, isnull( T4.Loc_de_munca, T3.Loc_de_munca)), LEN( RTRIM( LM.cod))))
	WHERE (@unLm=0 or LM.cod like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end))
	GROUP BY (case when @Centralizat='T' then '' else LM.Cod end), 
		(case when @Centralizat='S' then T1.Marca else '' end)
	HAVING (@Centralizat<>'N' or @Centralizat='N' and len(rtrim((case when @Centralizat='T' then '' else LM.Cod end)))=@NivelCentr)	
	ORDER BY (case when @Centralizat='T' then '' else LM.Cod end), 
		(case when @Centralizat='S' then T1.Marca else '' end)

	select Data, LM, DenLM, Marca, Nume, Somaj, Impozit, CAS, AsigSanNet, AvansPremii, DifImpozit,
		Avans, AvansCO,	DebiteExterne, DebiteInterne, Rate, CARContCrt, PensiiFacultative,
		Sindicat, RestDePlata, 
		DebiteExterne+DebiteInterne+(case when @DetTipRet=0 then ContribAvans+AvansCO else CARContCrt+Rate+PensiiFacultative end) as TotalRetineri,
		DebiteExterne+DebiteInterne+AvansCO+ContribAvans+CARContCrt+Rate+PensiiFacultative as Total
	from #Retineri	
	Order by LM, Marca

	if object_id('tempdb..#TmpCorectii') is not null drop table #TmpCorectii
	if object_id('tempdb..#TmpNet') is not null drop table #TmpNet
	if object_id('tempdb..#TmpRetineri') is not null drop table #TmpRetineri
	if object_id('tempdb..#Retineri') is not null drop table #Retineri
	
	return
end

/*
	exec rapListaLichRet '04/01/2011', '04/30/2011', 0, '', 0, '', 0, 'T', 0, 0
*/
