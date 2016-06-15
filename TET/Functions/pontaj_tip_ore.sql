--***
/**	functie pontaj pe tip de ore	*/
Create function pontaj_tip_ore
	(@dData_jos datetime, @dData_sus datetime, @cMarca_jos char(6), @cMarca_sus char(6), @cLm_jos char(9), @cLm_sus char(9)) 
returns @pontaj_tip_ore table
	(Marca char(6), Data datetime, Loc_de_munca char(9), Tip_ore char(30), Ore int, Ordine int)
as
begin
	declare @OSNRN bit, @ORegieFaraOS2 int, @Colas bit, @proc_sant1 float, @proc_sant2 float, @den_os1 char(20),@den_os2 char(20),@den_os3 char(20), @den_os4 char(20), 
		@den_sp1 char(20), @den_sp2 char(20), @den_sp3 char(20), @den_sp4 char(20), @den_sp5 char(20), @den_sp6 char(20), @den_sp8 char(20), @den_intr2 char(20) 

	Set @OSNRN = dbo.iauParL('PS','OSNRN') 
	Set @ORegieFaraOS2 = dbo.iauParL('PS','OREG-FOS2') 
	Set @Colas = dbo.iauParL('SP','COLAS') 
	Set @proc_sant1 = dbo.iauParN('PS','SPSANT1') 
	Set @proc_sant2 = dbo.iauParN('PS','SPSANT2') 
	Set @den_os1 = dbo.iauParA('PS','OSUPL1') 
	Set @den_os2 = dbo.iauParA('PS','OSUPL2') 
	Set @den_os3 = dbo.iauParA('PS','OSUPL3') 
	Set @den_os4 = dbo.iauParA('PS','OSUPL4') 
	Set @den_sp1 = dbo.iauParA('PS','SCOND1') 
	Set @den_sp2 = dbo.iauParA('PS','SCOND2') 
	Set @den_sp3 = dbo.iauParA('PS','SCOND3') 
	Set @den_sp4 = dbo.iauParA('PS','SCOND4') 
	Set @den_sp5 = dbo.iauParA('PS','SCOND5') 
	Set @den_sp6 = dbo.iauParA('PS','SCOND6') 
	Set @den_sp8 = dbo.iauParA('PS','SCOND8') 
	Set @den_intr2 = dbo.iauParA('PS','PROC2INT') 

	insert @pontaj_tip_ore
	select Marca, Data, Loc_de_munca, 'Ore regie' as Tip_ore, Ore_regie as Ore, 1 
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore_regie<>0
	union all
	select Marca, Data, Loc_de_munca, @den_os1, Ore_suplimentare_1, 2
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore_suplimentare_1<>0
	union all
	select Marca, Data, Loc_de_munca, @den_os2, Ore_suplimentare_2, 3
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore_suplimentare_2<>0
	union all
	select Marca, Data, Loc_de_munca, @den_os3, Ore_suplimentare_3, 4
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore_suplimentare_3<>0
	union all
	select Marca, Data, Loc_de_munca, @den_os4, Ore_suplimentare_4, 5
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore_suplimentare_4<>0
	union all
	select Marca, Data, Loc_de_munca, @den_sp1, Ore__cond_1, 6
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore__cond_1<>0
	union all
	select Marca, Data, Loc_de_munca, @den_sp2, Ore__cond_2, 7
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore__cond_2<>0
	union all
	select Marca, Data, Loc_de_munca, 'Ore Noapte', Ore_de_noapte, 8
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore_de_noapte<>0
	union all
	select Marca, Data, Loc_de_munca, @den_intr2, ore, 9
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and ore<>0
	union all
	select Marca, Data, Loc_de_munca, @den_sp8, Spor_cond_8, 10
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Spor_cond_8<>0
	union all 
	select Marca, Data, Loc_de_munca, (case when @Colas=1 then 'Form Prof.' else 'Ore plat. 100%' end), Ore_spor_100, 11
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore_spor_100<>0
	union all
	select Marca, Data, Loc_de_munca, 'CO', Ore_concediu_de_odihna, 12
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore_concediu_de_odihna<>0
	union all
	select Marca, Data, Loc_de_munca, 'CM', Ore_concediu_medical, 13
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore_concediu_medical<>0
	union all
	select Marca, Data, Loc_de_munca, 'ZLP-DS', Ore_obligatii_cetatenesti, 14
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore_obligatii_cetatenesti<>0
	union all
	select Marca, Data, Loc_de_munca, 'CFS', Ore_concediu_fara_salar, 15
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore_concediu_fara_salar<>0
	union all
	select Marca, Data, Loc_de_munca, 'Invoiri', Ore_invoiri, 16
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore_invoiri<>0
	union all
	select Marca, Data, Loc_de_munca, 'Nemotivate', Ore_nemotivate, 17
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore_nemotivate<>0
	union all
	select Marca, Data, Loc_de_munca, 'Delegatie', Spor_cond_10, 18
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Spor_cond_10<>0
	union all
	select Marca, Data, Loc_de_munca, 'Detasare', Spor_cond_9, 19
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Spor_cond_9<>0
	union all
	select Marca, Data, Loc_de_munca, @den_sp3, Ore__cond_3, 20
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore__cond_3<>0
	union all
	select Marca, Data, Loc_de_munca, @den_sp4, Ore__cond_4, 21
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore__cond_4<>0
	union all
	select Marca, Data, Loc_de_munca, @den_sp5, Ore__cond_5, 22
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore__cond_5<>0
	union all
	select Marca, Data, Loc_de_munca, rtrim(@den_sp6)+(case when @Colas=1 then '1' else '' end), Ore_donare_sange, 23
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore_donare_sange<>0 
		and (@Colas=0 or spor_conditii_6=@proc_sant1)
	union all 
	select Marca, Data, Loc_de_munca, rtrim(@den_sp6)+(case when @Colas=1 then '2' else '' end), Ore_donare_sange, 24
	from pontaj a
	where a.data between @dData_jos and @dData_sus and a.marca between @cMarca_jos and @cMarca_sus and a.loc_de_munca between @cLm_jos and @cLm_sus and Ore_donare_sange<>0 
		and @Colas=1 and spor_conditii_6=@proc_sant2

	return
end
