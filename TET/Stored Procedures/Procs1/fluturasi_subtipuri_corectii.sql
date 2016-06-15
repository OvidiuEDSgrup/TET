--***
/**	fluturasi subtipuri corectii	*/
Create procedure fluturasi_subtipuri_corectii
	@datajos datetime, @datasus datetime, @HostID char(10), @pmarca char(6), @conditie1 bit, @conditie2 bit, @conditie3 bit, @tip_corectie char(2)
as
Begin
	declare @Marca char(6), @Tip_corectie_venit char(2), @Denumire char(50), @Suma_corectie float, @Suma_neta float, @textSumaNeta varchar(100), @cand_scriu bit

	Declare cursor_fluturasi_subtipuri_corectii Cursor For
	select a.Marca, a.Tip_corectie_venit, max(s.Denumire), 
		sum(a.Suma_corectie+(case when s.Tip_corectie_venit='G-' then round(i.salar_de_incadrare*a.Procent_corectie/100,0) else 0 end)),
		sum(a.Suma_neta)
	from corectii a
		left outer join personal p on p.marca=a.marca
		left outer join istpers i on i.data=@datasus and i.marca=a.marca
		left outer join subtipcor s on s.Subtip=a.Tip_corectie_venit
	where a.marca=@pmarca and a.Data between @datajos and @datasus 
		and (@tip_corectie='' and s.Tip_corectie_venit<>'M-' or s.Tip_corectie_venit=@tip_corectie)
	group by a.data, a.marca, a.tip_corectie_venit

	open cursor_fluturasi_subtipuri_corectii
	fetch next from cursor_fluturasi_subtipuri_corectii into
		@Marca, @Tip_corectie_venit, @Denumire, @Suma_corectie, @Suma_neta
	While @@fetch_status = 0 
	Begin
		set @textSumaNeta = (case when @suma_neta<>0 then left('NET: '+convert(varchar(10),@suma_neta),10) else '' end) 
		if @Suma_corectie<>0
			exec scriu_fluturasi @HostID,@marca,'V',@Denumire,@textSumaNeta,@Suma_corectie,@conditie1,@conditie2,@conditie3,0,'V'

	 	fetch next from cursor_fluturasi_subtipuri_corectii into @Marca,  @Tip_corectie_venit, @Denumire, @Suma_corectie, @Suma_neta 
	End
	close cursor_fluturasi_subtipuri_corectii 
	Deallocate cursor_fluturasi_subtipuri_corectii
End
