--***
Create procedure rapCorectiiSalariati
	@dataJos datetime, @dataSus datetime, @pmarca varchar(6)=null, @locm char(9)=null, @strict int=0, @corectie char(2)=null, @subtipcorectie char(2)=null, 
	@listaconducere char(1), @pmandatar varchar(9)=null, @sex int=null, @sirmarci char(200)=null, @tipcard varchar(30)=null, @tipstarecor char(1)=null, 
	@afisaresumaneta int=0, @ordonare int=1, @alfabetic int=1, @evidentierecas int=0
as
begin try
	set transaction isolation level read uncommitted
	declare @AreDreptCond int, @eroare varchar(2000), @userASiS char(10), @lDreptCond int, @Subtipcor int, @SalCompens int, @CorSalCompens char(2), 
	@pCASIndiv decimal(5,2), @pSomajIndiv decimal(5,2), @SalarMediu decimal(10), @spSIND int, 
	@Data datetime, @Marca varchar(6), @Nume varchar(50), @TipCorectie char(2), @TipCorectieSubtip char(2), @DenumireCor varchar(30), 
	@SumaNeta float, @SumaCorectie float, @Procent_corectie float, @OrdonareTipCor char(2), @Cod_functie varchar(6), @DenFunctie varchar(30), 
	@Lm varchar(9), @DenLM varchar(30), @OrdonareLM varchar(9), @Mandatar varchar(6), @Mandatar_nume varchar(50), @Banca varchar(25), 
	@GrupaMunca char(1), @SomajPersonal int, @ProcCass decimal(5,2), @TipImpozitare char(1), @Grad_invalid char(1), 
	@Diminuari float, @SumaCorectieM float, @SumaAchitata float, @AchitatLa int, @cAchitatLa varchar(10), @cOrdonare varchar(100),
	@CASIndiv decimal(10), @CASSIndiv decimal(10), @SomajIndiv decimal(10), @VenitBaza decimal(10), @Impozit decimal(10), @RestPlata decimal(10)

	IF OBJECT_ID('tempdp..#Corectii') IS NOT NULL drop table #Corectii
	
	Create table #Corectii 
		(data datetime, marca varchar(6), nume varchar(50), cod_functie varchar(6), den_functie varchar(30), lm varchar(9), den_lm varchar(30), 
		tip_corectie char(2), tip_corectie_subtip char(2), den_corectie varchar(30), suma_neta float, suma_corectie float, procent_corectie float, ordonare_tipcor char(2), ordonare_lm varchar(9), 
		mandatar varchar(6), nume_mandatar varchar(50), banca varchar(25), procent_cass decimal(5,2), diminuari float, suma_corectieM float, 
		suma_achitata float, achitat_la varchar(10), ordonare varchar(100), 
		cas_indiv decimal(10), cass_indiv decimal(10), somaj_indiv decimal(10), baza_impozit decimal(10), impozit decimal(10), rest_plata decimal(10))
	Create index indx on #Corectii (data, marca, Lm, tip_corectie)

	set @userASiS=dbo.fIaUtilizator(null) 	-- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	IF @userASiS IS NULL
		RETURN -1

	set @lDreptCond=dbo.iauParL('PS','DREPTCOND')
	
	declare @drept int, @liste_drept char(1)
	set @liste_drept=@listaconducere
	if @lDreptCond=1 
	begin
		set @AreDreptCond=isnull((select dbo.verificDreptUtilizator(@userASiS,'SALCOND')),0)
		if @AreDreptCond=0
			set @liste_drept='S'
	end
	
	set @Subtipcor=dbo.iauParL('PS','SUBTIPCOR')
	set @SalCompens=dbo.iauParL('PS','SALCOMP')
	set @pCASIndiv=dbo.iauParLN(@dataSus,'PS','CASINDIV')
	set @pSomajIndiv=dbo.iauParLN(@dataSus,'PS','SOMAJIND')
	set @SalarMediu=dbo.iauParLN(@dataSus,'PS','SALMBRUT')
	set @spSIND=dbo.iauParL('SP','SINDROM')

	declare tmpCorectii cursor for
	select c.Data, c.Marca, isnull(p.nume,'') as Nume, c.Tip_corectie_venit as TipCorectie, isnull(s.Tip_corectie_venit,'') as TipCorSubtip, 
		max((case when @Subtipcor=1 and s.subtip<>'' then s.denumire else t.denumire end)) as DenumireCor, 
		c.suma_neta, max((case when c.Tip_corectie_venit='G-' or s.Tip_corectie_venit='G-' then -1 else 1 end)*c.Suma_corectie) as Suma_corectie, 
		/*max((case when @AfisareSumaNeta=1 then c.suma_neta 
			else (case when c.Tip_corectie_venit='G-' or s.Tip_corectie_venit='G-' then -1 else 1 end)*c.Suma_corectie end)) as Suma, */
		c.Procent_corectie, (case when @Ordonare<>1 then c.tip_corectie_venit else '' end) OrdonareTipCor, p.cod_functie, max(f.denumire) as DenFunctie, 
		c.loc_de_munca, max(lm.denumire) as DenLM, (case when @Ordonare in ('3','4','5') then c.loc_de_munca else '' end) as OrdonareLM, 
		(case when @Ordonare in ('3','4','5') then isnull((select mandatar from mandatar where loc_munca=max(c.loc_de_munca)),'') else '' end) as mandatar, 
		(case when @Ordonare in ('3','4','5') then (select p1.nume from personal p1, mandatar h where p1.marca=h.mandatar and h.loc_munca=max(c.loc_de_munca)) else '' end) as mandatar_nume, 
		max(p.banca) as Banca, max(p.Grupa_de_munca) as GrupaMunca, max(p.somaj_1) as SomajPersonal, 
		max(p.As_sanatate) ProcCass, max(p.Tip_impozitare) as TipImpozitare, max(p.Grad_invalid) as Grad_invalid, 
		(select b.diminuari from brut b where b.data=c.data and b.marca=c.marca and b.loc_de_munca=c.loc_de_munca) as diminuari, 
		(case when c.tip_corectie_venit='M-' then c.Suma_corectie else 0 end) as SumaCorectieM, 
		isnull(max(a.suma_corectie),0) as SumaAchitata, isnull(max(a.procent_corectie),0) as AchitatLa, 
		(case when @Ordonare=1 then (case when @Alfabetic=1 then p.nume else c.marca end) else c.Tip_corectie_venit+(case when @Alfabetic=1 then p.nume else '' end) end) as Ordonare
	from corectii c 
		left outer join personal p on c.marca=p.marca
		left outer join functii f on p.cod_functie=f.cod_functie
		left outer join lm on c.loc_de_munca=lm.cod
		left outer join corectii a on a.marca = c.marca and a.data = DateAdd(year,200, c.data) and a.tip_corectie_venit = c.tip_corectie_venit
		left outer join tipcor t on c.tip_corectie_venit=t.tip_corectie_venit
		left outer join subtipcor s on c.tip_corectie_venit=s.subtip
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=c.Loc_de_munca
	where c.data between @dataJos and @dataSus and (@pmarca is null or c.Marca=@pmarca) 
		and (@locm is null or c.Loc_de_munca like rtrim(@locm)+(case when @strict=1 then '' else '%' end))
		and (@corectie is null or @Subtipcor=0 and c.Tip_corectie_venit=@corectie or @Subtipcor=1 and s.Tip_corectie_venit=@corectie) 
		and (@subtipcorectie is null or c.tip_corectie_venit=@subtipcorectie)
		and (@lDreptCond=0 or (@AreDreptCond=1 and (@liste_drept='T' or @liste_drept='C' and p.pensie_suplimentara=1 or @liste_drept='S' and p.pensie_suplimentara<>1)) or (@AreDreptCond=0 and p.pensie_suplimentara<>1)) 
		and (@pmandatar is null or exists (select loc_munca from mandatar where mandatar=@pmandatar and loc_munca=c.loc_de_munca)) 
		and (@sex is null or p.sex=@sex) and (@sirmarci is null or charindex(','+rtrim(ltrim(c.marca))+',',@sirmarci)>0) and (@tipcard is null or p.banca=@tipcard) 
		and (@tipstarecor is null or @tipstarecor='1' and isnull(a.procent_corectie,0)<>0 or @tipstarecor='2' and isnull(a.procent_corectie,0)=0)
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	group by c.marca, p.nume, c.Tip_corectie_venit, isnull(s.Tip_corectie_venit,''), c.suma_neta, c.suma_corectie, c.procent_corectie, c.data, p.cod_functie,  c.loc_de_munca 
	order by Mandatar, OrdonareLM, Ordonare, c.Data	

	open tmpCorectii
	fetch next from tmpCorectii into @Data, @Marca, @Nume, @TipCorectie, @TipCorectieSubtip, @DenumireCor, @SumaNeta, @SumaCorectie, @Procent_corectie, 
		@OrdonareTipCor, @Cod_functie, @DenFunctie, @Lm, @DenLM, @OrdonareLM, @Mandatar, @Mandatar_nume, @Banca, @GrupaMunca, @SomajPersonal, @ProcCass, 
		@TipImpozitare, @Grad_invalid, @Diminuari, @SumaCorectieM, @SumaAchitata, @AchitatLa, @cOrdonare
	While @@fetch_status = 0 
	Begin
		select @VenitBaza=0, @Impozit=0
		select @CASIndiv=(case when (@EvidentiereCAS=1 or @spSIND=1) and @GrupaMunca<>'O' then
			ROUND((case when year(@Data)>=2011 and @SumaCorectie>5*@SalarMediu then 5*@SalarMediu else @SumaCorectie end)*@pCASIndiv/100,0) else 0 end)
		select @CASSIndiv=(case when @TipCorectie<>'U' and @TipCorectieSubtip<>'U-' then ROUND(@SumaCorectie*@ProcCass/10/100,0) else 0 end)
		select @SomajIndiv=ROUND((case when @TipCorectie<>'U' and @TipCorectieSubtip<>'U-' and @SomajPersonal<>0 
			and not(@SalCompens=1 and (@TipCorectie=@CorSalCompens or @TipCorectieSubtip=@CorSalCompens)) then @SumaCorectie*@pSomajIndiv/100 else 0 end),0)
		if @TipCorectie<>'U' and @TipCorectieSubtip<>'U-'
		Begin
			set @VenitBaza=@SumaCorectie-(@CASIndiv+@CASSIndiv+@SomajIndiv)
			if @VenitBaza>0 and @TipImpozitare<>'3' and @Grad_invalid not in ('1','2')
				exec calcul_impozit_salarii @VenitBaza, @Impozit output, 0
		End
		Set @RestPlata=(case when @TipCorectie='U' and @TipCorectieSubtip='U-' then @SumaCorectie else @VenitBaza-@Impozit end)
		insert into #Corectii
		select @Data, @Marca, @Nume, @Cod_functie, @DenFunctie, @Lm, @DenLM, @TipCorectie, @TipCorectieSubtip, @DenumireCor, @SumaNeta, @SumaCorectie, @Procent_corectie, 
		@OrdonareTipCor, @OrdonareLM, @Mandatar, @Mandatar_nume, @Banca, @ProcCass, @Diminuari, @SumaCorectieM, @SumaAchitata, 
		(case when @AchitatLa='1' then 'Avans' when @AchitatLa='2' then 'Lichidare' when @AchitatLa='3' then 'Alta data' when @AchitatLa='4' then 'Casa' else 'Neinres.' end),
		@cOrdonare, @CASIndiv, @CASSIndiv, @SomajIndiv, @VenitBaza, @Impozit, @RestPlata
		
		fetch next from tmpCorectii into @Data, @Marca, @Nume, @TipCorectie, @TipCorectieSubtip, @DenumireCor, @SumaNeta, @SumaCorectie, @Procent_corectie, 
			@OrdonareTipCor, @Cod_functie, @DenFunctie, @Lm, @DenLM, @OrdonareLM, @Mandatar, @Mandatar_nume, @Banca, @GrupaMunca, @SomajPersonal, @ProcCass, 
			@TipImpozitare, @Grad_invalid, @Diminuari, @SumaCorectieM, @SumaAchitata, @AchitatLa, @cOrdonare
	End
	select data, marca, nume, cod_functie, den_functie, lm, den_lm, tip_corectie, tip_corectie_subtip, den_corectie, suma_neta, suma_corectie, procent_corectie, 
		ordonare_tipcor, ordonare_lm, mandatar, nume_mandatar, banca, procent_cass, diminuari, suma_corectieM, 
		suma_achitata, achitat_la, cas_indiv, cass_indiv, somaj_indiv, baza_impozit, impozit, rest_plata
	from #Corectii	
	order by mandatar, ordonare_lm, ordonare, data
end try

begin catch
	set @eroare='Procedura rapCorectiiSalariati (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

declare @cursorStatus int
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='tmpCorectii' and session_id=@@SPID )
if @cursorStatus=1 
	close tmpCorectii 
if @cursorStatus is not null 
	deallocate tmpCorectii 

IF OBJECT_ID('tempdp..#Corectii') IS NOT NULL drop table #Corectii

/*
	exec rapCorectiiSalariati '03/01/2012', '03/31/2012', null, null, 0, null, null, 'T', null, null, null, null, null, 0, '1', 0, 1
*/
