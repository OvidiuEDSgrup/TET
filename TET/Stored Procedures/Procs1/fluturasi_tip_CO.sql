--***
/**	fluturasi tip CO	*/
Create procedure fluturasi_tip_CO
	@datajos datetime, @datasus datetime, @HostID char(10), @pmarca char(6), @conditie1 bit, @conditie2 bit, @conditie3 bit
as
Begin
	declare @Marca char(6), @Tip_CO char(20), @Ore_co int, @Ind_co float,  @ore char(20), @cand_scriu bit, @Dafora int, @OreLuna int

	set @Dafora=dbo.iauParL('SP','DAFORA')
	set @OreLuna=dbo.iauParLN(@datasus,'PS','ORE_LUNA')

	Declare cursor_fluturasi_tip_CO Cursor For
	select a.Marca, (case when a.Tip_concediu in ('1','7') then 'CO-Anual' when a.Tip_concediu in ('4','8') then 'CO-Anual an ant.' 
		when a.Tip_concediu='2'  then 'CO-Eveniment' when a.Tip_concediu='5'  then 'Chemare-CO' 
		when a.Tip_concediu='3'  then 'CO-Neef.an.crt.' when a.Tip_concediu='6'  then 'CO-Neef.an.ant.' else 'CO-Anual' end), 
		sum(a.Zile_Co*(case when isnull(i.Salar_lunar_de_baza,p.Salar_lunar_de_baza)<>0 
		then isnull(i.Salar_lunar_de_baza,p.Salar_lunar_de_baza)/(case when @Dafora=1 and i.Grupa_de_munca='C' then @OreLuna/8.00 else 1 end) else 8 end)), 
		sum(round(a.Indemnizatie_co,0))
	from concodih a
		left outer join personal p on p.Marca=a.Marca
		left outer join istpers i on i.Data=a.Data and i.Marca=a.Marca
	where a.Data between @datajos and @datasus and a.Marca=@pmarca and a.Tip_concediu in ('1','2','3','4','5','6','7','8')
	group by a.data, a.marca, a.Tip_concediu

	open cursor_fluturasi_tip_CO
	fetch next from cursor_fluturasi_tip_CO into @Marca, @Tip_CO, @Ore_co, @Ind_co
	While @@fetch_status = 0 
	Begin
		if (@Ore_co<>0 or @Ind_co<>0)  
		Begin
			Set @ore=str(@ore_co,3)+' ore'
			Set @cand_scriu=(case when @Ore_co<>0 or @Ind_co<>0 then 1 else 0 end)
			exec scriu_fluturasi @HostID, @marca, 'V', @Tip_CO, @Ore, @Ind_co, @conditie1, @conditie2, @conditie3, @cand_scriu, 'V'
		End
		fetch next from cursor_fluturasi_tip_CO into @Marca, @Tip_CO, @Ore_co, @Ind_co
	End
	close cursor_fluturasi_tip_CO 
	Deallocate cursor_fluturasi_tip_CO
End
