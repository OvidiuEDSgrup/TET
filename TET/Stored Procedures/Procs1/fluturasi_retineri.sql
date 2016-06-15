--***
/**	fluturasi retineri	*/
Create procedure fluturasi_retineri
	@datajos datetime, @datasus datetime, @HostID char(10), @pmarca char(6), @conditie1 bit, @conditie2 bit, @conditie3 bit, @parcurg_retineri int, @parcurg_retineri_neef int 
as
Begin
	declare @data datetime, @marca char(6), @cod_beneficiar char(13), @tip_retinere char(1), @denumire_beneficiar char(30), @numar_document char(10), @data_document datetime, 
	@Valoare_totala_pe_doc float, @Valoare_retinuta_pe_doc float, @Retinere_progr_la_avans float, @Retinere_progr_la_lichidare float, @Procent_progr_la_lichidare float, 
	@Retinut_la_avans float, @Retinut_la_lichidare float, @retinut_codben float, @Retinere_Salubris float, @Retinere_Elcond float, 
	@Salubris bit, @Elcond bit, @GFRBrazi bit, @inversare_semn bit, @gcod_beneficiar char(13),@ore_procent char(20), @valoare float, @Contor int, @Ob_retinere bit

	Exec Luare_date_par 'SP', 'SALUBRIS', @Salubris output , 0, 0
	Exec Luare_date_par 'SP', 'ELCOND', @Elcond output , 0, 0
	Exec Luare_date_par 'SP', 'GFRBRAZI', @GFRBrazi output , 0, 0
	Exec Luare_date_par 'PS', 'INVSRET', @inversare_semn output , 0, 0
	Exec Luare_date_par 'PS', 'FLDROBRET', @Ob_retinere output , 0, 0
	Set @Contor=0

	declare cursor_fluturasi_retineri cursor for
	select a.data, a.marca, a.cod_beneficiar, isnull(b.tip_retinere,''), isnull((case when @Ob_retinere=1 then b.obiect_retinere else b.denumire_beneficiar end),''), 
	a.numar_document, a.data_document, a.Valoare_totala_pe_doc, a.Valoare_retinuta_pe_doc, a.Retinere_progr_la_avans, a.Retinere_progr_la_lichidare, 
	a.Procent_progr_la_lichidare, a.Retinut_la_avans, a.Retinut_la_lichidare
	from resal a 
		left outer join benret b on b.cod_beneficiar=a.cod_beneficiar
	where a.data=@datasus and a.marca=@pmarca 
		and (@parcurg_retineri_neef =0 or a.Retinut_la_lichidare<a.Retinere_progr_la_lichidare)
		and a.cod_beneficiar<>''
	order by a.data, a.marca, a.cod_beneficiar, a.numar_document

	open cursor_fluturasi_retineri
	fetch next from cursor_fluturasi_retineri into 
		@data, @marca, @cod_beneficiar, @tip_retinere, @denumire_beneficiar, @numar_document, @data_document, 
		@Valoare_totala_pe_doc, @Valoare_retinuta_pe_doc, @Retinere_progr_la_avans, @Retinere_progr_la_lichidare, 
		@Procent_progr_la_lichidare, @Retinut_la_avans, @Retinut_la_lichidare
	While @@fetch_status = 0 
	Begin
		Set @Contor=@Contor+1
		Set @gcod_beneficiar=@cod_beneficiar
		while @gcod_beneficiar=@cod_beneficiar and @@fetch_status = 0
		begin
			if @parcurg_retineri=1 and @Salubris=1 and @cod_beneficiar='1256' and @Retinut_la_lichidare<@Retinere_progr_la_lichidare 
				Set @retinere_Salubris = @Retinut_la_lichidare-@Retinere_progr_la_lichidare 
			Set @retinut_codben = @retinut_codben + @Retinut_la_lichidare
			if @parcurg_retineri_neef =1 and @Contor = 1
				exec scriu_fluturasi @HostID, @marca, 'V','Retineri neefect--------------', '', 0,@conditie1,@conditie2,@conditie3,1,'R'
			if @parcurg_retineri=1 and @Elcond=0 --not elcond
			Begin
				Set @ore_procent = (case when @Procent_progr_la_lichidare=0 
					then (case when @GFRBrazi=1 and @tip_retinere='4' then convert(char(8),@Valoare_retinuta_pe_doc) else '' end) 
					else str(@Procent_progr_la_lichidare,5,2)+'%' end)
				Set @Valoare = (case when @inversare_semn =1 then -1 else 1 end)*
					(case when @parcurg_retineri_neef =0 then (case when @Salubris=1 and @Cod_beneficiar='1256' 
					then @Retinere_progr_la_lichidare else @Retinut_la_avans+@Retinut_la_lichidare end)
					else @Retinere_progr_la_lichidare-@Retinut_la_lichidare end)
				exec scriu_fluturasi @HostID, @marca, 'V', @denumire_beneficiar, @ore_procent, @Valoare, @conditie1, @conditie2, @conditie3, 1,'R'
			End

			fetch next from cursor_fluturasi_retineri into 
			@data, @marca, @cod_beneficiar, @tip_retinere, @denumire_beneficiar, @numar_document, @data_document, 
			@Valoare_totala_pe_doc, @Valoare_retinuta_pe_doc, @Retinere_progr_la_avans, @Retinere_progr_la_lichidare, 
			@Procent_progr_la_lichidare, @Retinut_la_avans, @Retinut_la_lichidare
		End
		if @parcurg_retineri=1 and @Elcond=1
		Begin
			Set @Retinere_Elcond = (case when @inversare_semn =1 then -1 else 1 end)*@retinut_codben
			exec scriu_fluturasi @HostID, @marca, 'V', @denumire_beneficiar, @ore_procent, @Retinere_Elcond, @conditie1, @conditie2, @conditie3, 0,'R'
		End
	End
	if @parcurg_retineri=0
		exec scriu_fluturasi @HostID, @marca, 'V', '', '', 0, @conditie1, @conditie2, @conditie3, 1, 'R'

	if exists (select 1 from sys.objects where name='fluturasi_retineriSP' and type='P')
		exec fluturasi_retineriSP @datajos, @datasus, @HostID, @pmarca, @conditie1, @conditie2, @conditie3

	close cursor_fluturasi_retineri
	Deallocate cursor_fluturasi_retineri
End
