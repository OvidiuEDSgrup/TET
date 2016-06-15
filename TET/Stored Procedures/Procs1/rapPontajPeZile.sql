--***
/**	procedura pentru raportul de Pontaj pe zile */
Create procedure rapPontajPeZile
	@dataJos datetime, @dataSus datetime, @marca char(6), @locm char(9)=null, @strict int=0, 
	@functie char(6)=null, @tipstat varchar(30)=null, @grupaMunca char(1)=null, @grupaMExcep int=0, @sirmarci varchar(1000)=null,
	@grupare int, @cDreptCond char(1)='T', @alfabetic int=0, @tipraport int=1, @dinweb int=0
/*
	@tipraport=0	->	Necompletat (->formular pontaj)
	@tipraport=1	->	Completat
	@dinweb -> daca =1 atunci completez spatii in fata la informatia la nivel de zi, pentru aspect mai bun in web
*/	
as
begin try
	set transaction isolation level read uncommitted
	declare @utilizator char(10), @dreptConducere int, @OSNRN int, @O100RN int, @ORegieFaraOS2 int, @RegimLV int, @Dafora int, @Colas int, @tip char(3), 
			@AreDreptCond int, @listaDreptCond char(1), @OreLuna float, @NrmLuna float

	set @utilizator=dbo.fIaUtilizator(null)
	set @dreptConducere=dbo.iauParL('PS','DREPTCOND')
	set @OSNRN=dbo.iauParL('PS','OSNRN')
	set @O100RN=dbo.iauParL('PS','O100NRN')
	set @ORegieFaraOS2=dbo.iauParL('PS','OREG-FOS2')
	set @RegimLV=dbo.iauParL('PS','REGIMLV')
	set @Dafora=dbo.iauParL('SP','DAFORA')
	set @Colas=dbo.iauParL('SP','COLAS')
	set @OreLuna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
	set @NrmLuna=dbo.iauParLN(@dataSus,'PS','NRMEDOL')
	
--	verific daca utilizatorul are/nu are dreptul de Salarii conducere (SALCOND)
	set @listaDreptCond=@cDreptCond
	set @areDreptCond=0
	if  @dreptConducere=1 
	begin
		set @areDreptCond=isnull((select dbo.verificDreptUtilizator(@utilizator,'SALCOND')),0)
		if @areDreptCond=0 -- daca utilizatorul nu are drept conducere atunci are acces doar la cei de tip salariat
			set @listaDreptCond='S'
	end
	
	if object_id('tempdb..#tmpPontaj') is not null drop table #tmpPontaj
	if object_id('tempdb..#pontajPeZile') is not null drop table #pontajPeZile

--	selectez datele de luat in calcul
	select s.data, p.marca, isnull(i.nume,p.nume) as nume, isnull(i.loc_de_munca,p.loc_de_munca) as lm, lm.Denumire as den_lm, lm.nivel, 
	(case when isnull(pr.Valoare,'')<>'' and p.Grupa_de_munca<>'C' then convert(int,pr.Valoare)
--	daca exista modificare de regim de lucru in cursul lunii, citesc regimul de lucru pana la data modificarii din luna anterioara
		when isnull(e.Procent,0)<>0 and s.Data<e.Data_inf then ia.Salar_lunar_de_baza
--	Tratat calcul regim de lucru functie de setarea [X]Regim de lucru variabil sau Specific Dafora.
		when isnull(i.Salar_lunar_de_baza,p.Salar_lunar_de_baza)=0 then 8 
			else (case when (@RegimLV=1 or @Dafora=1) and isnull(i.Salar_lunar_de_baza,p.Salar_lunar_de_baza)<>0 
				then round(isnull(i.Salar_lunar_de_baza,p.Salar_lunar_de_baza)*8/(case when isnull(i.Tip_salarizare,p.Tip_salarizare) in ('1','2') then @OreLuna else @NrmLuna end),(case when @Dafora=1 then 2 else 0 end)) 
				else isnull(i.Salar_lunar_de_baza,p.Salar_lunar_de_baza) 
				end) 
			end) as regim_de_lucru, 
	(case when isnull(i.Salar_lunar_de_baza,p.Salar_lunar_de_baza)=0 then 8 else isnull(i.Salar_lunar_de_baza,p.Salar_lunar_de_baza) end) as regim_de_lucru_lunar, convert(char(3),'') as tip_ore, 
	p.Data_angajarii_in_unitate as data_angajarii, convert(int, p.Loc_ramas_vacant) as plecat, p.Data_plec as data_plecarii, 
	(case when @grupare=1 then '' else isnull(i.loc_de_munca,p.loc_de_munca) end) as grup_lm
	into #tmpPontaj
	from personal p
		left outer join istpers i on p.Marca=i.Marca and i.Data=@datasus
		left outer join istpers ia on p.Marca=ia.Marca and ia.Data=DateADD(day,-1,@dataJos)
		left outer join dbo.fCalendar(@dataJos, @dataSus) s on s.Data_lunii=@dataSus
		left outer join infopers ip on p.Marca=ip.Marca 
		left outer join lm on lm.Cod=isnull(i.loc_de_munca,p.loc_de_munca)
		left outer join proprietati pr on pr.tip='LM' and pr.cod_proprietate='REGIML' and pr.Cod=isnull(i.loc_de_munca,p.loc_de_munca) and pr.Valoare<>''
		left outer join extinfop e on e.Marca=p.Marca and e.cod_inf='DATAMRL' and e.Procent<>0 and e.Data_inf between @dataJos and @dataSus
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=isnull(i.loc_de_munca,p.loc_de_munca)
	where (@marca is null or p.Marca like rtrim(@marca)+'%') 
		and (@functie is null or isnull(i.Cod_functie,p.Cod_functie)=@functie) 
		and (@locm is null or isnull(i.loc_de_munca,p.loc_de_munca) like rtrim(@locm)+(case when @strict=0 then '%' else '' end))
		and (p.Loc_ramas_vacant=0 or p.Data_plec>=@dataJos) 
		and p.Data_angajarii_in_unitate<=@dataSus and (@tipstat is null or ip.Religia=@tipstat)
		and (@grupamunca is null or (@grupaMExcep=0 and isnull(i.grupa_de_munca,p.grupa_de_munca)=@grupamunca or @grupaMExcep=1 and isnull(i.grupa_de_munca,p.grupa_de_munca)<>@grupamunca)) 
		and (@dreptConducere=0 or (@AreDreptCond=1 and (@listaDreptCond='T' or @listaDreptCond='C' and p.pensie_suplimentara=1 or @listaDreptCond='S' and p.pensie_suplimentara<>1)) 
			or (@AreDreptCond=0 and p.pensie_suplimentara<>1)) 
		and (@sirmarci is null or charindex(','+rtrim(ltrim(p.marca))+',',rtrim(@sirmarci))>0)
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
	order by grup_lm, (case when @alfabetic=0 then p.marca else p.nume end)

--	daca completez coloanele din raport (daca nu se tipareste raportul cu scop de formular)
	if @tipraport=1	
		update #tmpPontaj set @tip=(Select max(Tip) from fDate_pontaj_automat(@dataJos, @dataSus, Data, '', Marca, 1, 0) where tip<>'RL'),
			tip_ore=(case when DateName(weekday,Data) in ('Saturday','Sunday') or Data in (select Data from calendar) 
				or Data<data_angajarii or plecat=1 and Data>=data_plecarii then (case when @dinweb=1 then space(2) else '' end)+'X' 
			when isnull(@tip,'')='' then (case when regim_de_lucru>=1 
						then (case when @dinweb=1 then space(2) else '' end)+rtrim(convert(char(2),convert(int,regim_de_lucru))) 
				else rtrim(convert(char(5),regim_de_lucru)) end) 
			else @tip end)

--	mut orele de afisat de pe verticala pe orizontala (prin pivotare)
	select marca, nume, lm, den_lm, nivel, regim_de_lucru, grup_lm, 
		ISNULL(ziua1,'') as ziua1, ISNULL(ziua2,'') as ziua2, ISNULL(ziua3,'') as ziua3, ISNULL(ziua4,'') as ziua4, ISNULL(ziua5,'') as ziua5, 
		ISNULL(ziua6,'') as ziua6, ISNULL(ziua7,'') as ziua7, ISNULL(ziua8,'') as ziua8, ISNULL(ziua9,'') as ziua9, ISNULL(ziua10,'') as ziua10, 
		ISNULL(ziua11,'') as ziua11, ISNULL(ziua12,'') as ziua12, ISNULL(ziua13,'') as ziua13, ISNULL(ziua14,'') as ziua14, ISNULL(ziua15,'') as ziua15, 
		ISNULL(ziua16,'') as ziua16, ISNULL(ziua17,'') as ziua17, ISNULL(ziua18,'') as ziua18, ISNULL(ziua19,'') as ziua19, ISNULL(ziua20,'') as ziua20, 
		ISNULL(ziua21,'') as ziua21, ISNULL(ziua22,'') as ziua22, ISNULL(ziua23,'') as ziua23, ISNULL(ziua24,'') as ziua24, ISNULL(ziua25,'') as ziua25,  
		ISNULL(ziua26,'') as ziua26, ISNULL(ziua27,'') as ziua27, ISNULL(ziua28,'') as ziua28, ISNULL(ziua29,'') as ziua29, ISNULL(ziua30,'') as ziua30, 
		ISNULL(ziua31,'') as ziua31
	into #pontajPeZile
	from (
		select marca, nume, lm, den_lm, nivel, regim_de_lucru_lunar as regim_de_lucru, grup_lm,
			'ziua'+convert(char(2),day(data)) as camp, isnull(tip_ore,'') as tip_ore
		from #tmpPontaj where data between @dataJos and @dataSus) a
			pivot (max(tip_ore) for camp in 
				([ziua1],[ziua2],[ziua3],[ziua4],[ziua5],[ziua6],[ziua7],[ziua8],[ziua9],[ziua10],
				[ziua11],[ziua12],[ziua13],[ziua14],[ziua15],[ziua16],[ziua17],[ziua18],[ziua19],[ziua20],
				[ziua21],[ziua22],[ziua23],[ziua24],[ziua25],[ziua26],[ziua27],[ziua28],[ziua29],[ziua30],[ziua31])) b

--	selectul final
	select p.marca, p.nume, p.lm, p.den_lm, p.nivel, regim_de_lucru, 
		ziua1, ziua2, ziua3, ziua4, ziua5, ziua6, ziua7, ziua8, ziua9, ziua10, 
		ziua11, ziua12, ziua13, ziua14, ziua15, ziua16, ziua17, ziua18, ziua19, ziua20, 
		ziua21, ziua22, ziua23, ziua24, ziua25, ziua26, ziua27, ziua28, ziua29, ziua30, ziua31,
		isnull(total_ore,0) as total_ore, isnull(ore_lucrate,0) as ore_lucrate, isnull(ore_suplimentare,0) as ore_suplimentare, 
		isnull(ore_de_noapte,0) as ore_de_noapte, isnull(ore_co,0) as ore_co, isnull(ore_cm,0) as ore_cm, 
		isnull(ore_cfs,0) as ore_cfs, isnull(ore_nemotivate,0) as ore_nemotivate, isnull(ore_intr,0) as ore_intr, grup_lm 
	from #pontajPeZile p
		left outer join (select Marca, 
			sum(Ore_regie+ore_acord+
				(case when @OSNRN=1 then (case when @ORegieFaraOS2=1 then Ore_suplimentare_2 else 0 end) else Ore_suplimentare_1+Ore_suplimentare_2+Ore_suplimentare_3+Ore_suplimentare_4 end)+
				(case when @O100RN=1 then 0 else Ore_spor_100 end)+Ore_concediu_de_odihna+Ore_concediu_medical+Ore_concediu_fara_salar+ 
				Ore_nemotivate+Ore_intrerupere_tehnologica+Ore+(case when @Colas=1 then Spor_cond_8 else 0 end)) as Total_ore, 
			sum(Ore_regie+ore_acord) as Ore_lucrate, sum(Ore_suplimentare_1+Ore_suplimentare_2+Ore_suplimentare_3+Ore_suplimentare_4+Ore_spor_100) as Ore_suplimentare, 
			sum(Ore_de_noapte) as Ore_de_noapte, sum(Ore_concediu_de_odihna) as Ore_CO, sum(Ore_concediu_medical) as Ore_CM, 
			sum(Ore_concediu_fara_salar) as Ore_CFS, sum(Ore_nemotivate) as Ore_nemotivate, 
			sum(Ore_intrerupere_tehnologica+Ore+(case when @Colas=1 then Spor_cond_8 else 0 end)) as Ore_intr 
		from pontaj where data between @dataJos and @dataSus Group by Marca) t on t.Marca=p.Marca and @tipraport=1
	order by grup_lm, (case when @alfabetic=0 then p.Marca else p.Nume end)

end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapPontajPeZile (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

/*
	exec rapPontajPeZile '03/01/2012', '03/31/2012', null, null, 0, null, null, null, 0, null, '1', 'T', 0, 1, 0
	exec psFormularPontaj '10/01/2012', '10/31/2012', '', 'zzzzzz', '', '', 'ZZZZZZZZZ', 0, '', 3 , 0, 'C', 0, 1.00000000 , 'T', ''
*/
