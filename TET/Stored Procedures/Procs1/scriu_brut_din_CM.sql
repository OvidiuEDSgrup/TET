--***
/**	proc. scriu brut din CM	*/
Create procedure scriu_brut_din_CM
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @pLoc_de_munca char(9), @Din_inversare int
As
Begin
	declare @Comp_saln int, @SalarNetValuta int, @SalarNetFCM int, @Data datetime, @Marca char(6), 
	@Tip_diagnostic char(2), @Ind_unitate float, @Ind_Fnuass float, @Ind_Faambp float, 
	@Loc_de_munca char(9), @Salar_orar float, @Regim_de_lucru float
	Set @Comp_saln=dbo.iauParL('PS','COMPSALN')
	Set @SalarNetValuta=dbo.iauParL('PS','SALNETV')
	Set @SalarNetFCM=dbo.iauParL('PS','SALNPO-CM')

	declare cursor_scriu_brut_din_CM cursor for
	Select a.Data, a.Marca, a.Tip_diagnostic, a.Indemnizatie_unitate, 
	(case when not(a.tip_diagnostic in ('2-','3-','4-') or a.tip_diagnostic in ('10','11') and a.Suma=1) then a.Indemnizatie_CAS else 0 end), 
	(case when a.tip_diagnostic in ('2-','3-','4-') or a.tip_diagnostic in ('10','11') and a.Suma=1 then a.Indemnizatie_CAS else 0 end),
	isnull((select max(j.Loc_de_munca) from pontaj j where j.data between @dataJos and @dataSus and j.marca=a.Marca and j.Ore_concediu_medical>0),
	isnull((select max(j.Loc_de_munca) from pontaj j where j.data between @dataJos and @dataSus and j.marca=a.Marca and j.Loc_munca_pentru_stat_de_plata=1),p.Loc_de_munca)),
	isnull((select max(j.Regim_de_lucru) from pontaj j where j.data between @dataJos and @dataSus and j.marca=a.Marca),8)
	from conmed a 
		left outer join personal p on a.marca=p.marca
	where data between @dataJos and @dataSus and (year(a.Data)<2006 or a.Tip_diagnostic<>'0-')
		and (@pMarca='' or a.Marca=@pMarca) and (@pLoc_de_munca='' or p.Loc_de_munca like rtrim(@pLoc_de_munca)+'%')

	open cursor_scriu_brut_din_CM
	fetch next from cursor_scriu_brut_din_CM into @Data, @Marca, @Tip_diagnostic, @Ind_unitate, @Ind_Fnuass, @Ind_Faambp, @Loc_de_munca, @Regim_de_lucru
	while @@fetch_status = 0
	Begin
		if not((@Comp_saln=1 or @SalarNetValuta=1 or @SalarNetFCM=1 or @Tip_diagnostic='0-') and @Din_inversare=1)
		Begin
			Set @Salar_orar=0
			exec scriuBrut_salarii @Data, @marca, @loc_de_munca, 1,  
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @Ind_unitate, @Ind_Fnuass, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 		
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @Salar_orar, 0, 0, 0, 0, 0, @Ind_Faambp, @Regim_de_lucru
		End
		fetch next from cursor_scriu_brut_din_CM into @Data, @Marca, @Tip_diagnostic, @Ind_unitate, @Ind_Fnuass, @Ind_Faambp, @Loc_de_munca, @Regim_de_lucru
	End
	Close cursor_scriu_brut_din_CM
	Deallocate cursor_scriu_brut_din_CM
End
