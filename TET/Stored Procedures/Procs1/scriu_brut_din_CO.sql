--***
/**	proc. scriu brut din CO	*/
Create procedure scriu_brut_din_CO
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @pLoc_de_munca char(9)
As
Begin
	declare @Data datetime, @Marca char(6), @Indemnizatie_CO float, @Indemnizatie_COEV float, @Loc_de_munca char(9), 
	@Salar_orar float, @Regim_de_lucru float, @COEV_macheta int
	Set @COEV_macheta=dbo.iauParL('PS','COEVMCO')

	declare cursor_scriu_brut_din_CO cursor for
	Select a.Data, a.Marca, round(sum((case when @COEV_macheta=0 or @COEV_macheta=1 and a.Tip_concediu not in ('2','E') then 
	(case when a.Tip_concediu='5' then -1 else 1 end)*a.Indemnizatie_CO else 0 end)),0), 
	round(sum((case when @COEV_macheta=1 and a.Tip_concediu in ('2','E') then a.Indemnizatie_CO else 0 end)),0), 
	isnull((select max(j.Loc_de_munca) from pontaj j where j.data between @dataJos and @dataSus and j.marca=a.Marca and j.Ore_concediu_de_odihna>0),
	isnull((select max(j.Loc_de_munca) from pontaj j where j.data between @dataJos and @dataSus and j.marca=a.Marca and j.Loc_munca_pentru_stat_de_plata=1),max(p.Loc_de_munca))),
	isnull((select max(j.Regim_de_lucru) from pontaj j where j.data between @dataJos and @dataSus and j.marca=a.Marca),8)
	from concodih a 
		left outer join personal p on a.marca=p.marca
	where data between @dataJos and @dataSus and a.Marca<>'' and a.Tip_concediu not in ('9','C','P','V')
		and a.Data_inceput between @dataJos and @dataSus and (@pMarca='' or a.Marca=@pMarca) 
		and (@pLoc_de_munca='' or p.Loc_de_munca like rtrim(@pLoc_de_munca)+'%')
	Group by a.Data, a.Marca

	open cursor_scriu_brut_din_CO
	fetch next from cursor_scriu_brut_din_CO into @Data, @Marca, @Indemnizatie_CO, @Indemnizatie_COEV, @Loc_de_munca, @Regim_de_lucru
	while @@fetch_status = 0
	Begin
		Set @Salar_orar=0
		exec scriuBrut_salarii @Data, @marca, @loc_de_munca, 1,  
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @Indemnizatie_COEV, 0, 0, 0, @Indemnizatie_CO, 0, 0, 0, 0, 0, 0, 0, 0, 		
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @Salar_orar, 0, 0, 0, 0, 0, 0, @Regim_de_lucru
		fetch next from cursor_scriu_brut_din_CO into @Data, @Marca, @Indemnizatie_CO, @Indemnizatie_COEV, @Loc_de_munca, @Regim_de_lucru
	End
	Close cursor_scriu_brut_din_CO
	Deallocate cursor_scriu_brut_din_CO
End
