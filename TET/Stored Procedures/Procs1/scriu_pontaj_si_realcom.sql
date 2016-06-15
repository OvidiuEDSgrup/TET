--***
/**	proc. scriu pontaj/realcom	*/
Create procedure scriu_pontaj_si_realcom
	@dataJos datetime, @dataSus datetime, @DataP datetime, @Pontaj_weekend int
As
declare @DataIncr datetime, @InstPubl int, @lPontajZilnic int, @RLVariabil int, @SalariatiPeComenzi int, @Spc_ORN int, @COMacheta int, @COEVMacheta int, 
	@OreLuna int, @NrmLuna int, @lGestionareTichete int, @nNrTichete float, @lTicheteMarca int, @lTicheteZL int, 
	@lTicheteZLDim int, @lTicheteRL int, @lZileFaraTicheteAng int, @nZileFaraTichete int

set @InstPubl=dbo.iauParL('PS','INSTPUBL')
set @RLVariabil=dbo.iauParL('PS','REGIMLV')
set @SalariatiPeComenzi=dbo.iauParL('PS','SALCOM')
set @lPontajZilnic=dbo.iauParL('PS','PONTZILN')
set @Spc_ORN=dbo.iauParL('PS','SP-C-ORN')
set @COMacheta=dbo.iauParL('PS','OPZILECOM')
set @COEVMacheta=dbo.iauParL('PS','COEVMCO')
set @OreLuna=dbo.iauParLN(dbo.eom(@DataP),'PS','ORE_LUNA')
set @NrmLuna=dbo.iauParLN(dbo.eom(@DataP),'PS','NRMEDOL')
set @nNrTichete=dbo.iauParLN(dbo.eom(@DataP),'PS','NRTICHETE')
set @lGestionareTichete=dbo.iauParL('PS','TICHETE')
set @lTicheteZL=dbo.iauParL('PS','TICHZLUC')
set @lTicheteZLDim=dbo.iauParL('PS','TICHZLDIM')
set @lTicheteMarca=dbo.iauParL('PS','TICHMARCA')
set @lTicheteRL=dbo.iauParL('PS','TICH-RLTP')
set @lZileFaraTicheteAng=dbo.iauParL('PS','TICNUZANG')
set @nZileFaraTichete=dbo.iauParN('PS','TICNUZANG')-1

update #pontaj_automat set 
Ore_regie=(case when a.Tip_salarizare in ('1','3') and a.Ore_regie>0 
	then a.Ore_regie*(case when @RLVariabil=1 and p.Salar_lunar_de_baza<>0 
			then (case when p.Grupa_de_munca='C' then a.Regim_de_lucru/8 else p.Salar_lunar_de_baza/(case when a.Tip_salarizare='1' then @OreLuna else @NrmLuna end) end) 
			else 1 end)
		-a.Ore_concediu_medical-(case when @COMacheta=1 then a.Ore_concediu_de_odihna else 0 end)-a.Ore_invoiri-a.Ore_nemotivate-a.Ore_concediu_fara_salar
		-(case when @InstPubl=1 then 0 else a.Ore_intrerupere_tehnologica+a.Ore end)
		-(case when @COEVMacheta=1 then a.Ore_obligatii_cetatenesti else 0 end)-isnull(cm.ZCM2ani,0)*a.Regim_de_lucru else a.Ore_regie end),
Ore_acord=(case when a.Tip_salarizare not in ('1','3') and a.Ore_acord>0 
	then a.Ore_acord*(case when @RLVariabil=1 and p.Salar_lunar_de_baza<>0 
			then (case when p.Grupa_de_munca='C' then a.Regim_de_lucru/8 else p.Salar_lunar_de_baza/(case when a.Tip_salarizare='1' then @OreLuna else @NrmLuna end) end) 
			else 1 end)
		-a.Ore_concediu_medical-(case when @COMacheta=1 then a.Ore_concediu_de_odihna else 0 end)-a.Ore_invoiri-a.Ore_nemotivate-a.Ore_concediu_fara_salar
		-(case when @InstPubl=1 then 0 else a.Ore_intrerupere_tehnologica+a.Ore end)
		-(case when @COEVMacheta=1 then a.Ore_obligatii_cetatenesti else 0 end) -isnull(cm.ZCM2ani,0)*a.Regim_de_lucru else a.Ore_acord end)
from #pontaj_automat a
	left outer join personal p on a.Marca=p.Marca
	left outer join 
		(select marca, (case when @lPontajZilnic=1 then (case when max(Data_inceput)<=@DataP and @DataP<=max(Data_sfarsit) then 1 else 0 end) else sum(Zile_lucratoare) end) as ZCM2ani 
		from conmed where data between dbo.bom(@DataP) and dbo.eom(@DataP) and (@lPontajZilnic=1 and Data_inceput<=@DataP 
			and @DataP<=Data_sfarsit or @lPontajZilnic=0) and Tip_diagnostic='0-' Group by Marca) cm on a.Marca=cm.Marca

update #pontaj_automat set 
	Ore__cond_1=(case when @Spc_ORN=1 and a.Spor_conditii_1<>0 then a.ore_regie+a.ore_acord else 0 end),
	Ore__cond_2=(case when @Spc_ORN=1 and a.Spor_conditii_2<>0 then a.ore_regie+a.ore_acord else 0 end),
	Ore__cond_3=(case when @Spc_ORN=1 and a.Spor_conditii_3<>0 then a.ore_regie+a.ore_acord else 0 end),
	Ore__cond_4=(case when @Spc_ORN=1 and a.Spor_conditii_4<>0 then a.ore_regie+a.ore_acord else 0 end),
	Ore__cond_5=(case when @Spc_ORN=1 and a.Spor_conditii_5<>0 then a.ore_regie+a.ore_acord else 0 end),
	Ore_donare_sange=(case when @Spc_ORN=1 and a.Spor_conditii_6<>0 then a.ore_regie+a.ore_acord else 0 end), 
	Ore__cond_6=round((a.Ore_regie+a.Ore_acord-(isnull(pb.Zile,0)*a.Regim_de_lucru+isnull(pz.Zile,0)*a.Regim_de_lucru)-
		(case when @lZileFaraTicheteAng=1 and DateAdd(day,@nZileFaraTichete,p.Data_angajarii_in_unitate)>=@dataJos 
			then dbo.psZileFaraTichete(@dataJos,@dataSus,a.marca)*a.Regim_de_lucru else 0 end)-a.Spor_cond_10)/
		(case when @lTicheteRL=1 and p.Grupa_de_munca='C' then 8 else a.Regim_de_lucru end)*
		(case when @lTicheteZLDim=1 and t.NrTichete<@OreLuna/8 then t.NrTichete/(@OreLuna/8) else 1 end),0)
from #pontaj_automat a
	left outer join personal p on a.Marca=p.Marca
	left outer join dbo.fDate_pontaj_automat (@dataJos, @dataSus, @DataP, 'PB', '', 0, 0) pb on a.Marca=pb.Marca 
	left outer join dbo.fDate_pontaj_automat (@dataJos, @dataSus, @DataP, 'PZ', '', 0, 0) pz on a.Marca=pz.Marca
	left outer join (select marca, (case when dbo.iauExtinfopProc(Marca,'NRTICHETE')=0 then @nNrTichete else dbo.iauExtinfopProc(Marca,'NRTICHETE') end) as NrTichete 
					from personal) t on t.Marca=a.Marca

update #pontaj_automat set Ore_lucrate=a.ore_regie+a.ore_acord,
	Ore__cond_6=(case when @lGestionareTichete=0 or @Pontaj_weekend=1 and a.ore_regie+a.ore_acord<>0 or @lTicheteMarca=1 and p.Loc_de_munca_din_pontaj=0 
	then 0 
	else (case when @lTicheteZL=1 and (p.Grupa_de_munca in ('N','D','S') or p.Grupa_de_munca='C' and (p.Tip_colab='' or @lTicheteMarca=1) or p.Grupa_de_munca in ('P','O') and @lTicheteMarca=1) 
		then (case when Ore__cond_6>t.NrTichete then t.NrTichete else Ore__cond_6 end) 
		else (case when @lTicheteZL=0 and (p.Grupa_de_munca in ('N','D','S') or p.Grupa_de_munca='C' and p.Tip_colab='') 
			then (case when (month(p.Data_angajarii_in_unitate)=month(@DataP) and year(p.Data_angajarii_in_unitate)=year(@DataP) 
					or p.Loc_ramas_vacant=1 and month(p.Data_plec)=month(@DataP) and year(p.Data_plec)=year(@DataP)) 
				then (dbo.Zile_lucratoare((case when month(p.Data_angajarii_in_unitate)=month(@DataP) and year(p.Data_angajarii_in_unitate)=year(@DataP) 
					then p.Data_angajarii_in_unitate else dbo.bom(@DataP) end),
					(case when p.Loc_ramas_vacant=1 and month(p.Data_plec)=month(@DataP) and year(p.Data_plec)=year(@DataP) then DateAdd(day,-1,p.Data_plec) else dbo.eom(@DataP) end)) 
					- (case when @lTicheteZL=1 then 0 else @OreLuna/8-t.NrTichete end))
				else t.NrTichete*(case when @lTicheteRL=1 and p.Grupa_de_munca='C' then a.Regim_de_lucru/8 else 1 end) end)-
				(a.Ore_concediu_medical+a.Ore_concediu_de_odihna+a.Ore_nemotivate+a.Ore_concediu_fara_salar+a.Ore_obligatii_cetatenesti+ a.Spor_cond_10)/a.Regim_de_lucru else 0 end) end) end)
from #pontaj_automat a 	
-- legatura pe un select virtual pt. a avea nr. de tichete teoretic cuvenite pe marca (sa nu fie case when in fiecare loc unde se utiliza variabila @nNrTichete) 
	left outer join (select marca, (case when dbo.iauExtinfopProc(Marca,'NRTICHETE')=0 then @nNrTichete else dbo.iauExtinfopProc(Marca,'NRTICHETE') end) as NrTichete 
					from personal) t on t.Marca=a.Marca, personal p
where a.Marca=p.Marca

update #pontaj_automat set Ore__cond_6=0 from #pontaj_automat a where a.Ore__cond_6<0

insert into pontaj (Data, Marca, Numar_curent, Loc_de_munca, Loc_munca_pentru_stat_de_plata, 
	Tip_salarizare, Regim_de_lucru, Salar_orar, Ore_lucrate, Ore_regie, Ore_acord, Ore_suplimentare_1, Ore_suplimentare_2, Ore_suplimentare_3, Ore_suplimentare_4, Ore_spor_100, 
	Ore_de_noapte, Ore_intrerupere_tehnologica, Ore_concediu_de_odihna, Ore_concediu_medical, Ore_invoiri, Ore_nemotivate, Ore_obligatii_cetatenesti, Ore_concediu_fara_salar, Ore_donare_sange, 
	Salar_categoria_lucrarii, Coeficient_acord, Realizat, Coeficient_de_timp, Ore_realizate_acord, Sistematic_peste_program, Ore_sistematic_peste_program, Spor_specific, 
	Spor_conditii_1, Spor_conditii_2, Spor_conditii_3, Spor_conditii_4, Spor_conditii_5, Spor_conditii_6, Ore__cond_1, Ore__cond_2, Ore__cond_3, Ore__cond_4, Ore__cond_5, Ore__cond_6, 
	Grupa_de_munca, Ore, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10)
select Data, Marca, Numar_curent, Loc_de_munca, Loc_munca_pentru_stat_de_plata, Tip_salarizare, Regim_de_lucru, Salar_orar, Ore_lucrate, Ore_regie, Ore_acord, 
	Ore_suplimentare_1, Ore_suplimentare_2, Ore_suplimentare_3, Ore_suplimentare_4, Ore_spor_100, Ore_de_noapte, Ore_intrerupere_tehnologica, 
	Ore_concediu_de_odihna, Ore_concediu_medical, Ore_invoiri, Ore_nemotivate, Ore_obligatii_cetatenesti, Ore_concediu_fara_salar, Ore_donare_sange, Salar_categoria_lucrarii, 
	Coeficient_acord, Realizat, Coeficient_de_timp, Ore_realizate_acord, Sistematic_peste_program, Ore_sistematic_peste_program, Spor_specific, Spor_conditii_1, 
	Spor_conditii_2, Spor_conditii_3, Spor_conditii_4, Spor_conditii_5, Spor_conditii_6, Ore__cond_1, Ore__cond_2, Ore__cond_3, Ore__cond_4, Ore__cond_5, Ore__cond_6, 
	Grupa_de_munca, Ore, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10 
from #pontaj_automat

If @SalariatiPeComenzi=1
	insert into realcom (Marca, Loc_de_munca, Numar_document, Data, Comanda, Cod_reper, Cod, Cantitate, Categoria_salarizare, Norma_de_timp, Tarif_unitar)
	select a.Marca, a.Loc_de_munca, 'PS'+rtrim(convert(char(10),a.Numar_curent)), a.Data, i.Centru_de_cost_exceptie, '', '', a.Ore_regie+a.Ore_acord, 1, 0, a.Salar_orar
	from #pontaj_automat a
		left outer join personal p on a.Marca=p.Marca
		left outer join infopers i on a.Marca=i.Marca
	where a.Marca=i.Marca and a.Marca=p.Marca
