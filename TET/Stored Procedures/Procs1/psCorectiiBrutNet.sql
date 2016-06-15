--***
/**	proc. corectii brut net	*/
Create procedure psCorectiiBrutNet 
	@dataJos datetime, @dataSus datetime, @marca char(6), @locm char(9), @Precizie int
As
Begin
	declare @Tip_corectie_venit char(2), @ordonare varchar(2)
	update corectii set Suma_corectie=0 where Data between @dataJos and @dataSus and (@marca='' or Marca=@marca) 
		and (@locm='' or Loc_de_munca like rtrim(@locm)+'%') and Suma_neta>=1 

	declare CorectiiBrutNet cursor for
	select distinct Tip_corectie_venit, (case when Tip_corectie_venit='AI' then 'ZZ' else Tip_corectie_venit end) as ordonare 
	from corectii 
	where Data between @dataJos and @dataSus and (@marca='' or Marca=@marca) 
		and (@locm='' or Loc_de_munca like rtrim(@locm)+'%') and Suma_neta>=1
	Order by (case when Tip_corectie_venit='AI' then 'ZZ' else Tip_corectie_venit end)

	open CorectiiBrutNet
	fetch next from CorectiiBrutNet into @Tip_corectie_venit, @ordonare
	While @@fetch_status = 0 
	Begin
		exec psCalcul_lichidare @dataJos, @dataSus, @marca, @locm, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		exec psCalculBrutNet @dataJos, @dataSus, @marca, @locm, @Precizie, @Tip_corectie_venit
		fetch next from CorectiiBrutNet into @Tip_corectie_venit, @ordonare
	End
	close CorectiiBrutNet
	Deallocate CorectiiBrutNet
End
