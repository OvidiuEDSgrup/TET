--***
/**	fluturasi componente saln	*/
Create procedure fluturasi_comp_saln
	@datajos datetime, @datasus datetime, @HostID char(10), @pmarca char(6), @conditie1 bit, @conditie2 bit, @conditie3 bit
as
Begin
	declare @data datetime, @marca char(6), @cod_componenta char(13), @denumire_comp char(30), @valoare_comp char(80), 
	@procent float, @CorI float, @CorK float, @Ore_lucrate_marca int, @Salar_net_marca float, @Val_tichete_marca float, 
	@ore char(20), @valoare float, @gmarca char(6), @ore_luna float, @saln_ref float, 
	@den_suma_impozabila char(30), @den_premiu char(30), @den_cons_admin char(30)

	Set @den_suma_impozabila = isnull((select denumire from tipcor where tip_corectie_venit='H-'),'')
	Set @den_premiu = isnull((select denumire from tipcor where tip_corectie_venit='I-'),'')
	Set @den_cons_admin = isnull((select denumire from tipcor where tip_corectie_venit='K-'),'')
	Set @Ore_luna = dbo.iauParLN(@Datasus,'PS','ORE_LUNA')
	--Exec Luare_date_par 'PS', 'ORE_LUNA', 0, @ore_luna output, 0
	Exec Luare_date_par 'PS', 'S-NET-REF', 0, @saln_ref output, 0

--	creare cursor pentru scriere in tabela flutur
	declare cursor_fluturasi_comp_saln cursor for
	select a.data, a.marca, a.cod_comp, isnull(b.denumire,''), a.val_comp, a.procent, isnull(c1.suma_neta,0), isnull(c2.suma_neta,0), 
		isnull((select sum(ore_regie+ore_acord) from pontaj where data between @datajos and @datasus and marca=a.marca),0)
	from componente a
		left outer join catinfop b on b.cod=a.cod_comp
		left outer join corectii c1 on c1.marca=a.marca and c1.data=a.data and c1.tip_corectie_venit='I-'
		left outer join corectii c2 on c2.marca=a.marca and c2.data=a.data and c2.tip_corectie_venit='K-'
	where a.data=@datasus and a.marca=@pmarca 
	order by a.data, a.marca, a.cod_comp, a.val_comp

	open cursor_fluturasi_comp_saln
	fetch next from cursor_fluturasi_comp_saln into 
		@data, @marca, @cod_componenta, @denumire_comp, @valoare_comp, @procent, @CorI, @CorK, @Ore_lucrate_marca
	While @@fetch_status = 0 
	Begin
		Set @gmarca=@marca
		Set @Salar_net_marca = 0
		Set @Val_tichete_marca = 0
		Set @valoare=@saln_ref*@ore_lucrate_marca/@ore_luna
		exec scriu_fluturasi @HostID, @marca, 'V', 'SALAR NET REFERINTA', '', @Valoare, @conditie1, @conditie2, @conditie3, 1, ''
		Set @Salar_net_marca=@Salar_net_marca+@saln_ref*@ore_lucrate_marca/@ore_luna
		while @gmarca=@marca and @@fetch_status = 0
		begin
			if @cod_componenta<>''
			Begin
				Set @ore=str(@procent,7)+'%'
				Set @valoare=@saln_ref*@ore_lucrate_marca/@ore_luna*@procent/100
				exec scriu_fluturasi @HostID, @marca, 'V', @denumire_comp, @ore, @Valoare, @conditie1, @conditie2, @conditie3, 1, ''
				Set @Salar_net_marca=@Salar_net_marca+@saln_ref*@ore_lucrate_marca/@ore_luna*@procent/100
			End
			if @cod_componenta=''
				Set @Val_tichete_marca = @Val_tichete_marca+@procent

			fetch next from cursor_fluturasi_comp_saln into 
			@data, @marca, @cod_componenta, @denumire_comp, @valoare_comp, @procent, @CorI, @CorK, @Ore_lucrate_marca
		End
		exec scriu_fluturasi @HostID, @marca, 'V', '-------------------', '', 0, @conditie1, @conditie2, @conditie3, 1, ''
		exec scriu_fluturasi @HostID, @marca, 'V', @den_suma_impozabila, '', @salar_net_marca, @conditie1, @conditie2, @conditie3, 0, ''
		Set @valoare = - @val_tichete_marca
		exec scriu_fluturasi @HostID, @marca, 'V', 'DIN CARE TICHETE', '', @valoare, @conditie1, @conditie2, @conditie3, 1, ''
		if @corI<>0
			exec scriu_fluturasi @HostID, @marca, 'V', @den_premiu, '', @corI, @conditie1, @conditie2, @conditie3, 0, ''
		if @corK<>0
			exec scriu_fluturasi @HostID, @marca, 'V', @den_cons_admin, '', @corK, @conditie1, @conditie2, @conditie3, 0, ''
		Set @valoare=@salar_net_marca-@val_tichete_marca+@corI+@corK
		exec scriu_fluturasi @HostID, @marca, 'V', 'TOTAL', '', @valoare, @conditie1, @conditie2, @conditie3, 1, ''
	End
	close cursor_fluturasi_comp_saln
	Deallocate cursor_fluturasi_comp_saln
End
