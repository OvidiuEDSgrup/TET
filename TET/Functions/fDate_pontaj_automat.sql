--***
/**	functie. pentru operatia de generare pontaj automat */
Create function fDate_pontaj_automat 
	(@dataJos datetime, @dataSus datetime, @DataIncr datetime, @Tip char(2), @pMarca char(6), @FormularPontaj int, @detalierePeZile int)
returns @fDate_pontaj_automat table
	(Tip char(2), Denumire varchar(30), tip_ore_pontaj varchar(30), Marca char(6), RL decimal(6,2), Zile decimal(6,2), Ore int, 
		Data_inceput datetime, Data_sfarsit datetime, Ora_inceput varchar(10), Ora_sfarsit varchar(10))
As
/*
	@tip='TC' -> returnare doar concediile, fara regim de lucru
*/
Begin
	declare @PontajZilnic int, @RegimLV int, @PlataCuOra int, @COMacheta int, @Dafora int, @OreLuna float, @NrmLuna float 

	Set @RegimLV=dbo.iauParL('PS','REGIMLV')
	Set @PlataCuOra=dbo.iauParL('PS','SALOR-REG')
	Set @PontajZilnic=dbo.iauParL('PS','PONTZILN')
	Set @Dafora=dbo.iauParL('SP','DAFORA')
	Set @COMacheta=dbo.iauParL('PS','OPZILECOM')
	Set @OreLuna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
	Set @NrmLuna=dbo.iauParLN(@dataSus,'PS','NRMEDOL')

	insert into @fDate_pontaj_automat
--	determin regimul de lucru
	select 'RL', 'Regim de lucru', '', marca, 
	(case when Grupa_de_munca in ('O','P') or (Grupa_de_munca in ('C') or Grupa_de_munca in ('N','D','S') and @PlataCuOra=0) and @RegimLV=0 
		then (case when Salar_lunar_de_baza=0 then (case when Grupa_de_munca in ('O','P') then 3 else 8 end) else Salar_lunar_de_baza end) 
		else (case when @RegimLV=1 and Salar_lunar_de_baza<>0 then round(Salar_lunar_de_baza*8/(case when Tip_salarizare in ('1','2') then @OreLuna else @NrmLuna end),
			(case when @Dafora=1 then 2 else 0 end)) else 8 end) end) as RL, 
	(case when (month(Data_angajarii_in_unitate)=month(@dataSus) and year(Data_angajarii_in_unitate)=year(@dataSus) or Loc_ramas_vacant=1 and month(Data_plec)=month(@dataSus) 
		and year(Data_plec)=year(@dataSus)) and @PontajZilnic=0 
			then dbo.Zile_lucratoare((case when month(Data_angajarii_in_unitate)=month(@dataSus) and year(Data_angajarii_in_unitate)=year(@dataSus) 
				then Data_angajarii_in_unitate else dbo.bom(@dataSus) end),
			(case when Loc_ramas_vacant=1 and month(Data_plec)=month(@dataSus) and year(Data_plec)=year(@dataSus) then DateAdd(day,-1,Data_plec) 
				else dbo.eom(@dataSus) end)) else @OreLuna/8.00 end) as Zile, 0 as Ore, @dataJos, @dataSus, '', ''			
	from personal 
	where (@Tip='' or @Tip='RL') and (@pMarca='' or Marca=@pMarca) and @FormularPontaj=0
	union all
--	concedii medicale	
	select 'CM', 'Concediu medical', 'Ore_concediu_medical', cm.marca, 0 as RL, 
		(case when @detalierePeZile=1 then 1 when @PontajZilnic=1 or @FormularPontaj=1 then 
			(case when max(cm.Data_inceput)<=@DataIncr and @DataIncr<=max(cm.Data_sfarsit) then 1*(case when max(cm.tip_diagnostic)='10' then 0.25 else 1 end) else 0 end) 
			else sum(cm.Zile_lucratoare*(case when cm.tip_diagnostic='10' then 0.25 else 1 end)) end) as Zile_CM, 0 as Ore,
		(case when @detalierePeZile=1 then fc.Data else @dataJos end), (case when @detalierePeZile=1 then fc.Data else @dataSus end), '', ''				
	from conmed cm
		left outer join dbo.fCalendar(@dataJos,@dataSus) fc on @detalierePeZile=1 and fc.data between cm.data_inceput and cm.Data_sfarsit
	where (@Tip='' or @Tip in ('CM','TC')) 
		and cm.Data_inceput between @dataJos and @dataSus and (@pMarca='' or cm.Marca=@pMarca)
		and ((@PontajZilnic=1 or @FormularPontaj=1) and cm.Data_inceput<=@DataIncr and @DataIncr<=cm.Data_sfarsit 
			or @PontajZilnic=0 and @FormularPontaj=0) 
		and cm.Tip_diagnostic<>'0-' 
		and (@detalierePeZile=0 or not exists (select 1 from conalte ca where ca.Data=cm.data and ca.Marca=cm.Marca and ca.Data_inceput=cm.Data_inceput))
	Group by Marca, (case when @detalierePeZile=1 then fc.Data else @dataJos end), (case when @detalierePeZile=1 then fc.Data else @dataSus end)
	union all 
--	concedii de odihna	
	select 'CO', 'Concediu de odihna', 'Ore_concediu_de_odihna', co.Marca, 0 as RL, 
		(case when @detalierePeZile=1 then 1 when @PontajZilnic=1 or @FormularPontaj=1 
			then (case when max(co.Data_inceput)<=@DataIncr and @DataIncr<=max(co.Data_sfarsit) then 1 else 0 end)
			else sum((case when co.Tip_concediu='5' then -1 else 1 end)*co.Zile_CO) end) as Zile_CO, 0 as Ore, 
		(case when @detalierePeZile=1 then fc.Data else @dataJos end), (case when @detalierePeZile=1 then fc.Data else @dataSus end), '', ''
	from concodih co
		left outer join dbo.fCalendar(@dataJos,@dataSus) fc on @detalierePeZile=1 and fc.data between co.data_inceput and co.Data_sfarsit
	where (@Tip='' or @Tip in ('CO','TC')) 
		and co.Data between @dataJos and @dataSus and (@pMarca='' or co.Marca=@pMarca) 
		and ((@PontajZilnic=1 or @FormularPontaj=1) and co.Data_inceput<=@DataIncr and @DataIncr<=co.Data_sfarsit 
			or @PontajZilnic=0 and @FormularPontaj=0) 
		and co.Tip_concediu in ('1','4','5','7','8') 
	Group by Marca, (case when @detalierePeZile=1 then fc.Data else @dataJos end), (case when @detalierePeZile=1 then fc.Data else @dataSus end)
	union all 
--	obligatii cetatenesti	
	select 'OB', 'Obligatii cetatenesti', 'Ore_obligatii_cetatenesti', marca, 0 as RL, 
		(case when @detalierePeZile=1 then 1 when @PontajZilnic=1 or @FormularPontaj=1 
			then (case when max(Data_inceput)<=@DataIncr and @DataIncr<=max(Data_sfarsit) then 1 else 0 end)
			else sum(Zile_CO) end) as Zile_CO, 0 as Ore, 
		(case when @detalierePeZile=1 then fc.Data else @dataJos end), (case when @detalierePeZile=1 then fc.Data else @dataSus end), '', ''
	from concodih co
		left outer join dbo.fCalendar(@dataJos,@dataSus) fc on @detalierePeZile=1 and fc.data between co.data_inceput and co.Data_sfarsit
	where (@Tip='' or @Tip in ('OB','TC')) 
		and co.data between @dataJos and @dataSus and (@pMarca='' or co.Marca=@pMarca) 
		and ((@PontajZilnic=1 or @FormularPontaj=1) and co.Data_inceput<=@DataIncr and @DataIncr<=co.Data_sfarsit 
			or @PontajZilnic=0 and @FormularPontaj=0) 
		and co.Tip_concediu in ('2','E') 
	Group by Marca, (case when @detalierePeZile=1 then fc.Data else @dataJos end), (case when @detalierePeZile=1 then fc.Data else @dataSus end)
	union all
--	ingrijire copil 2 ani
	select 'IC', 'Ingrijire copil 2 ani', '', cm.marca, 0 as RL, 
		(case when @detalierePeZile=1 then 1 when @PontajZilnic=1 or @FormularPontaj=1 
			then (case when max(cm.Data_inceput)<=@DataIncr and @DataIncr<=max(cm.Data_sfarsit) then 1 else 0 end)
			else sum(Zile_lucratoare) end) as ZCM_2ani, 0 as Ore,
		(case when @detalierePeZile=1 then fc.Data else @dataJos end), (case when @detalierePeZile=1 then fc.Data else @dataSus end), '', ''
	from conmed cm
		left outer join dbo.fCalendar(@dataJos,@dataSus) fc on @detalierePeZile=1 and fc.data between cm.data_inceput and cm.Data_sfarsit
	where (@Tip='' or @Tip in ('IC','TC')) 
		and cm.data between @dataJos and @dataSus and cm.Tip_diagnostic='0-' and (@pMarca='' or cm.Marca=@pMarca) 
		and ((@PontajZilnic=1 or @FormularPontaj=1) and cm.Data_inceput<=@DataIncr and @DataIncr<=cm.Data_sfarsit 
			or @PontajZilnic=0 and @FormularPontaj=0) 
	Group by Marca, (case when @detalierePeZile=1 then fc.Data else @dataJos end), (case when @detalierePeZile=1 then fc.Data else @dataSus end)
	union all 
	select max(t.prescurtare), max(t.Denumire), max(t.Ore_pontaj), marca, 0 as RL, 
		(case when @PontajZilnic=1 or @FormularPontaj=1 or @detalierePeZile=1
			then (case when (max(ca.Data_inceput)<=@DataIncr and @DataIncr<=max(ca.Data_sfarsit) or @detalierePeZile=1) 
				and (ca.Tip_concediu not in ('2','3') or max(ca.Indemnizatie)=0) then 1 else 0 end) 
			else sum((case when ca.Indemnizatie=0 then Zile else 0 end)) end) as Zile_CFS, 
		(case when @PontajZilnic=1 
			then (case when max(ca.Data_inceput)<=@DataIncr and @DataIncr<=max(ca.Data_sfarsit) then max(ca.Indemnizatie) else 0 end) 
			else sum(ca.Indemnizatie) end) as Ore,
		(case when @detalierePeZile=1 then fc.Data else @dataJos end), (case when @detalierePeZile=1 then fc.Data else @dataSus end), 
		(case when convert(char(10),max(ca.Data_inceput),108)='00:00:00' then '' else convert(char(10),max(ca.Data_inceput),108) end), 
		(case when convert(char(10),max(ca.Data_sfarsit),108)='00:00:00' then '' else convert(char(10),max(ca.Data_sfarsit),108) end)
	from conalte ca
		left outer join dbo.fTip_ConcediiAlte() t on t.Tip_concediu=ca.Tip_concediu
		left outer join dbo.fCalendar(@dataJos,@dataSus) fc on @detalierePeZile=1 and fc.data between convert(char(10),ca.data_inceput,101) and convert(char(10),ca.Data_sfarsit,101) 
	where (@Tip='' or @Tip='TC' or @Tip=t.prescurtare) 
		and ca.data between @dataJos and @dataSus and (@pMarca='' or ca.Marca=@pMarca) 
		and ((@PontajZilnic=1 or @FormularPontaj=1) and ca.Data_inceput<=@DataIncr and @DataIncr<=ca.Data_sfarsit 
			or @PontajZilnic=0 and @FormularPontaj=0) 
		and (@detalierePeZile=0 or (ca.Tip_concediu in ('1','2','3','4','5','6','9','R','F','H') 
			or ca.Tip_concediu in ('A','B','C','D','E','N') and not(@PontajZilnic=1 or @FormularPontaj=1 or @detalierePeZile=1)
			or ca.Tip_concediu='M' and not exists (select 1 from conmed cm where ca.Data=cm.data and ca.Marca=cm.Marca and ca.Data_inceput=cm.Data_inceput)))
	Group by Marca, ca.Tip_concediu, (case when @detalierePeZile=1 then fc.Data else @dataJos end), (case when @detalierePeZile=1 then fc.Data else @dataSus end)
	
	if @tip='DT'	--	detasari operate in salariati
	begin
		declare @detasari table (Marca varchar(6), DataInceput datetime, DataFinal datetime, DataInceputLuna datetime, DataSfarsitLuna datetime)
		insert into @detasari
		select Marca, DataInceput, DataFinal, '', '' from fRevisalDetasari (@dataJos, @dataSus, @pMarca, null)
		update @detasari 
			set DataInceputLuna=(case when DataInceput<@dataJos then @dataJos else DataInceput end),
				DataSfarsitLuna=(case when DataFinal>@dataSus then @dataSus else DataFinal end)

		insert into @fDate_pontaj_automat
		select 'DT', 'Detasare', '', dt.marca, 0 as RL, 
			(case when @detalierePeZile=1 then 1 when @PontajZilnic=1 or @FormularPontaj=1 
				then (case when max(dt.DataInceputLuna)<=@DataIncr and @DataIncr<=max(dt.DataSfarsitLuna) then 1 else 0 end)
				else sum(dbo.zile_lucratoare(dt.DataInceputLuna,dt.DataSfarsitLuna)) end) as zile, 0 as Ore,
			(case when @detalierePeZile=1 then fc.Data else @dataJos end), (case when @detalierePeZile=1 then fc.Data else @dataSus end), '', ''
		from @detasari dt
			left outer join dbo.fCalendar(@dataJos,@dataSus) fc on @detalierePeZile=1 and fc.data between dt.DataInceputLuna and dt.DataSfarsitLuna
		where (@Tip='' or @Tip in ('DT')) 
			and (@pMarca='' or dt.Marca=@pMarca) 
			and ((@PontajZilnic=1 or @FormularPontaj=1) and dt.DataInceputLuna<=@DataIncr and @DataIncr<=dt.DataSfarsitLuna 
				or @PontajZilnic=0 and @FormularPontaj=0) 
		Group by Marca, (case when @detalierePeZile=1 then fc.Data else @dataJos end), (case when @detalierePeZile=1 then fc.Data else @dataSus end)
	end

	if @tip='SC'	--	suspendari contracte operate in salariati, neplatite care trebuie sa ajunga in pontaj ca ore de suspendare contract si ulterior in D112.
	begin
		declare @suspendari table (Marca varchar(6), Data_inceput datetime, Data_final datetime, Data_inceput_luna datetime, Data_sfarsit_luna datetime)
		insert into @suspendari
		select Marca, Data_inceput, Data_final, '', '' from fRevisalSuspendari (@dataJos, @dataSus, @pMarca)
		where Temei_legal not in ('Art51Alin1LiteraA','Art51Alin1LiteraB','Art51Alin1LiteraC',	--exceptam suspendarile care sunt tratate separat: crestere copil pana la 2 ani
				'Art54','Art51Alin2','Art52Alin1LiteraA','Art51Alin1LiteraD',	--	concediu fara salar, nemotivate, cercetare disciplinara, formare profesionala.
				'Art52Alin1LiteraD')	--	pe durata detasarii

		update @suspendari
			set Data_inceput_luna=(case when Data_inceput<@dataJos then @dataJos else Data_inceput end),
				Data_sfarsit_luna=(case when Data_final>@dataSus then @dataSus else Data_final end)

		insert into @fDate_pontaj_automat
		select 'SC', 'Suspendare', '', sc.marca, 0 as RL, 
			(case when @detalierePeZile=1 then 1 when @PontajZilnic=1 or @FormularPontaj=1 
				then (case when max(sc.Data_inceput_luna)<=@DataIncr and @DataIncr<=max(sc.Data_sfarsit_luna) then 1 else 0 end)
				else sum(dbo.zile_lucratoare(sc.Data_inceput_luna,sc.Data_sfarsit_luna)) end) as zile, 0 as Ore,
			(case when @detalierePeZile=1 then fc.Data else @dataJos end), (case when @detalierePeZile=1 then fc.Data else @dataSus end), '', ''
		from @suspendari sc
			left outer join dbo.fCalendar(@dataJos,@dataSus) fc on @detalierePeZile=1 and fc.data between sc.Data_inceput_luna and sc.Data_sfarsit_luna
		where (@Tip='' or @Tip in ('SC')) 
			and (@pMarca='' or sc.Marca=@pMarca) 
			and ((@PontajZilnic=1 or @FormularPontaj=1) and sc.Data_inceput_luna<=@DataIncr and @DataIncr<=sc.Data_sfarsit_luna 
				or @PontajZilnic=0 and @FormularPontaj=0) 
		Group by sc.Marca, (case when @detalierePeZile=1 then fc.Data else @dataJos end), (case when @detalierePeZile=1 then fc.Data else @dataSus end)
	end

--	daca se face detalierea pe zile sterg zilele de sarbatori legale/sambata/duminica
	delete from @fDate_pontaj_automat where @detalierePeZile=1 and (datename(WeekDay, Data_inceput) in ('Sunday','Saturday') or Data_inceput in (select data from calendar))

	return
End
