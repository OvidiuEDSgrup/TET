--***
/**	functie pt. virament carduri	*/
Create function fCarduri 
	(@dataJos datetime, @dataSus datetime, @Avans int, @RestDePlata int, @Corectii int, @CO int, @Retineri int, 
	@lApareCorU int, @lApareCorO int, @lApareCorM int, @ScriuSumaNeta int, @FaraCAS int, @FaraSomaj int, @FaraCASS int, @FaraImpozit int, 
	@cTipCorectie char(2), @lSirCor int, @cSirCor char(200), @GestSumePl int, @lTipCard int, @cTipCard char(25), @lBanca2 int, 
	@lNrStat int, @nNrStat float, @lStareCor int, @cStareCor char(1), @FiltruDataCorU int, @DataCorUJ datetime, @DataCorUS datetime, 
	@FiltruDataCorO int, @DataCorOJ datetime, @DataCorOS datetime, @DataCorMJ datetime, 
	@DataCorMS datetime, @SiMMzero int, @cSirCodben char(200), @FiltruDataOP int,  @DataOP decimal(10), 
	@DataRetJ datetime, @DataRetS datetime, @DataDoc datetime, @lTipPers int, @cTipPers char(1), @DoarCOLunaCrt int)
returns @fCarduri table
	(Tip_suma char(10),Data datetime,Marca char(6),Nume char(50),Loc_de_munca char(9),Cont_banca char(50),Tip_corectie_venit char(2), Suma float)
As
Begin
	declare @utilizator varchar(20), @Subtipcor int, @AccesDataCorectie int, @nCASind float, @nSomaj_ind float

	set @utilizator=dbo.fIaUtilizator(null)
	set @Subtipcor=dbo.iauParL('PS','SUBTIPCOR')
	set @AccesDataCorectie=dbo.iauParL('PS','ACCESDCOR')
	set @nCASind=dbo.iauParLN(@dataSus,'PS','CASINDIV')
	set @nSomaj_ind=dbo.iauParLN(@dataSus,'PS','SOMAJIND')
	
	insert into @fCarduri
--	calcul avans sau rest de plata
	select 'AL', a.Data, a.Marca, p.Nume, p.Loc_de_munca, 
		(case when @lBanca2=1 then isnull((select max(val_inf) from extinfop e where e.marca=a.marca and e.cod_inf='CONT2'),'') else p.Cont_in_banca end),
		'', (case when @Avans=1 then a.Avans+a.Premiu_la_avans-isnull(r.Retinut_la_avans,0) else a.Rest_de_plata end)
	from net a 
		left outer join personal p on a.marca=p.marca
		left outer join fMod_plata_la_data (@dataSus,'') f on a.marca=f.marca
		left outer join (select Marca, sum(Retinut_la_avans) as Retinut_la_avans from resal where data=@dataSus group by marca) r on @Avans=1 and a.marca=r.marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.Loc_de_munca
	where (@Avans=1 or @RestDePlata=1) and a.Data=@dataSus 
		and (@lTipCard=0 or @lTipCard=1 and @lBanca2=0 and f.Banca=@cTipCard 
			or @lTipCard=1 and @lBanca2=1 and isnull((select max(val_inf) from extinfop e where e.marca=a.marca and e.cod_inf='BANCA2'),'')=@cTipCard)
		and (@SiMMzero=1 or (case when @Avans=1 then a.Avans+a.Premiu_la_avans-isnull(r.Retinut_la_avans,0) else a.Rest_de_plata end)>0)
		and (@lTipPers=0 or p.tip_salarizare between (case when @cTipPers='T' then '1' else '3' end) and (case when @cTipPers='T' then '2' else '7' end))
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
	union all
--	cumulare la avans sau rest de plata a corectiilor O, M, U
	select 'AL', a.Data, a.Marca, p.Nume, a.Loc_de_munca, 
		(case when @lBanca2=1 then isnull((select max(val_inf) from extinfop e where e.marca=a.marca and e.cod_inf='CONT2'),'') else p.Cont_in_banca end),
		a.Tip_corectie_venit, (case when (@Subtipcor=0 and tip_corectie_venit='O-' or @Subtipcor=1 and tip_corectie_venit in (select s.subtip from subtipcor s where s.tip_corectie_venit='O-')) 
		then (case when a.Suma_neta<>0 then a.Suma_neta else round(a.Suma_corectie*(100-@nCASind-convert(float,p.As_sanatate)/10)/100,0) end) else a.Suma_corectie end)
	from corectii a 
		left outer join personal p on a.marca=p.marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.Loc_de_munca
	where (@Avans=1 or @RestDePlata=1) and a.Marca<>''
		and (@lApareCorU=1 and (@FiltruDataCorU=1 and data between @DataCorUJ and @DataCorUS or @FiltruDataCorU=0 and data between @dataJos and @dataSus) 
		and (@Subtipcor=0 and tip_corectie_venit='U-' or @Subtipcor=1 and tip_corectie_venit in (select s.subtip from subtipcor s where s.tip_corectie_venit='U-'))
			or @lApareCorO=1 and (@FiltruDataCorO=1 and data between @DataCorOJ and @DataCorOS or @FiltruDataCorO=0 and data between @dataJos and @dataSus) 
		and (@Subtipcor=0 and tip_corectie_venit='O-' or @Subtipcor=1 and tip_corectie_venit in (select s.subtip from subtipcor s where s.tip_corectie_venit='O-')) 
			or @lApareCorM=1 and data between @DataCorMJ and @DataCorMS 
		and (@Subtipcor=0 and tip_corectie_venit='M-' or @Subtipcor=1 and tip_corectie_venit in (select s.subtip from subtipcor s where s.tip_corectie_venit='M-')))
		and (@lTipCard=0 or @lTipCard=1 and @lBanca2=0 and p.Banca=@cTipCard 
			or @lTipCard=1 and @lBanca2=1 and isnull((select max(val_inf) from extinfop e where e.marca=a.marca and e.cod_inf='BANCA2'),'')=@cTipCard) 
		and (@SiMMzero=1 or a.Suma_neta>0 or a.Suma_corectie>0)
		and (@lTipPers=0 or p.tip_salarizare between (case when @cTipPers='T' then '1' else '3' end) and (case when @cTipPers='T' then '2' else '7' end))
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
	union all
--	calcul retineri salariati
	select 'RS', a.Data, a.Marca, p.Nume, p.Loc_de_munca, 
		(case when @lBanca2=1 then isnull((select max(val_inf) from extinfop e where e.marca=a.marca and e.cod_inf='CONT2'),'') else p.Cont_in_banca end), '', (a.Retinut_la_lichidare+a.Retinut_la_avans)
	from resal a 
		left outer join personal p on a.marca=p.marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.Loc_de_munca
	where @Retineri=1 and a.Data between @dataJos and @dataSus
		and (@lTipCard=0 or @lTipCard=1 and @lBanca2=0 and p.Banca=@cTipCard or 
			@lTipCard=1 and @lBanca2=1 and isnull((select max(val_inf) from extinfop e where e.marca=a.marca and e.cod_inf='BANCA2'),'')=@cTipCard )
		and charindex (','+rtrim (a.Cod_beneficiar)+',',rtrim(@cSirCodben))<>0 
		and (@SiMMzero=1 or a.Retinut_la_lichidare+a.Retinut_la_avans>0)
		and (@lTipPers=0 or p.tip_salarizare between (case when @cTipPers='T' then '1' else '3' end) and (case when @cTipPers='T' then '2' else '7' end))
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
	union all
--	calcul indemnizatii concedii de odihna
	select 'CO', a.Data, a.Marca, max(p.Nume), max(p.Loc_de_munca), 
		(case when @lBanca2=1 then isnull((select max(val_inf) from extinfop e where e.marca=a.marca and e.cod_inf='CONT2'),'') else max(p.Cont_in_banca) end), '', sum(a.Indemnizatie_CO)
	from concodih a 
		left outer join personal p on a.marca=p.marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.Loc_de_munca
	where @CO=1 and (@FiltruDataOP=0 and a.Data=@dataSus or @FiltruDataOP=1 and a.Prima_vacanta=@DataOP and (@DoarCOLunaCrt=0 or a.Data=@dataSus)) 
		and a.Tip_concediu='9' and (@lTipCard=0 or @lTipCard=1 and @lBanca2=0 and p.Banca=@cTipCard 
			or @lTipCard=1 and @lBanca2=1 and isnull((select max(val_inf) from extinfop e where e.marca=a.marca and e.cod_inf='BANCA2'),'')=@cTipCard) 
		and (@SiMMzero=1 or a.Indemnizatie_CO>0)
		and (@lTipPers=0 or p.tip_salarizare between (case when @cTipPers='T' then '1' else '3' end) and (case when @cTipPers='T' then '2' else '7' end))
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
	Group by a.Data, a.Marca
	union all
--	corectii pe marci
	select 'CS', a.Data, a.Marca, p.Nume, p.Loc_de_munca,
		(case when @lBanca2=1 then isnull((select max(val_inf) from extinfop e where e.marca=a.marca and e.cod_inf='CONT2'),'') else p.Cont_in_banca end), a.Tip_corectie_venit, 
		((case when @ScriuSumaNeta=1 or a.Suma_neta<>0 then a.Suma_neta else a.Suma_corectie end)
		-(case when @ScriuSumaNeta=1 or @Subtipcor=0 and a.Tip_corectie_venit in ('C-','E-','M-') 
		or @Subtipcor=1 and a.Tip_corectie_venit in (select s.subtip from subtipcor s where s.tip_corectie_venit in ('C-','E-','M-')) then 0 
		else (case when @FaraCAS=1 then round(a.Suma_corectie*@nCASind/100,0) else 0 end)
		+(case when @FaraCASS=1 then round(a.Suma_corectie*p.As_sanatate/10/100,0) else 0 end)
		+(case when @FaraSomaj=1 then round(a.Suma_corectie*@nSomaj_ind/100,0) else 0 end) 
		+(case when @FaraImpozit=1 then dbo.fCalcul_impozit_salarii(a.Suma_corectie
		-((case when @FaraCAS=1 then round(a.Suma_corectie*@nCASind/100,0) else 0 end)
		+(case when @FaraCASS=1 then round(a.Suma_corectie*p.As_sanatate/10/100,0) else 0 end)
		+(case when @FaraSomaj=1 then round(a.Suma_corectie*@nSomaj_ind/100,0) else 0 end)),0,0) else 0 end) end))
	from corectii a 
		left outer join personal p on a.marca=p.marca
		left outer join corectii b on b.Data=dateadd(year,200,a.Data) and b.Marca=a.Marca and a.Tip_corectie_venit=b.Tip_corectie_venit and a.Loc_de_munca=b.Loc_de_munca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.Loc_de_munca
	where @Corectii=1 and (@AccesDataCorectie=0 and a.Data between @dataJos and @dataSus or @AccesDataCorectie=1 and a.Data between @DataCorOJ and @DataCorOS) 
		and a.Marca<>''
		and (@lTipCard=0 or @lTipCard=1 and @lBanca2=0 and p.Banca=@cTipCard 
			or @lTipCard=1 and @lBanca2=1 and isnull((select max(val_inf) from extinfop e where e.marca=a.marca and e.cod_inf='BANCA2'),'')=@cTipCard)
		and (@lSirCor=0 and (@Subtipcor=0 and a.tip_corectie_venit=@cTipCorectie 
			or @Subtipcor=1 and a.tip_corectie_venit in (select s.subtip from subtipcor s where s.tip_corectie_venit=@cTipCorectie)) 
			or @lSirCor=1 and (@Subtipcor=0 and charindex (','+rtrim (a.Tip_corectie_venit)+',',rtrim(@cSirCor))<>0 
			or @Subtipcor=1 and charindex (','+rtrim (a.Tip_corectie_venit)+',',rtrim(@cSirCor))<>0)) 
		and (@lNrStat=0 or a.Suma_neta=@nNrStat)
		and (@SiMMzero=1 or @ScriuSumaNeta=0 and a.Suma_corectie>0 or @ScriuSumaNeta=1 and a.Suma_neta>0)
		and (@lStareCor=0 or @cStareCor=1 and b.Procent_corectie between 1 and 3 or @cStareCor=2 and b.Procent_corectie=0)
		and (@lTipPers=0 or p.tip_salarizare between (case when @cTipPers='T' then '1' else '3' end) and (case when @cTipPers='T' then '2' else '7' end))
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
	order by a.Marca
	return
End
