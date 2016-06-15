--***
/**	procedura pentru calcul concedii medicale */
Create procedure calcul_concedii_medicale
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @pDataInceput datetime, @pZileLucratoare int, @pZileUnitate int OUTPUT, @pZileCMLunaAnterioara int, 
	@pIndemnizatiaZilnica float, @pProcent float OUTPUT, @pIndemnizatieUnitate float OUTPUT, @pIndemnizatieCAS float OUTPUT, @pBazaCalcul float, @pZileLucratoareLuna int, 
	@pIndemnizatiiCalcManual int, @RecalculMedieZilnica int, @pLocm char(9)=''
As
Begin
	declare @Utilizator char(10), @nLunaInch int, @nAnulInch int, @dDataInch datetime, @data datetime, @marca char(6), @tip_diagnostic char(2), @Data_inceput datetime, @Data_sfarsit datetime, 
	@Zile_lucratoare int, @Zile_luna_anterioara int, @Indemnizatia_zi float, @Procent float, @Indemnizatie_unitate float, @Zile_cu_reducere int, @Indemnizatie_CAS float, @Baza_calcul float, 
	@Zile_lucratoare_in_luna int, @Indemnizatii_calc_manual int, @Suma float, @Serie_CM_initial char(10), @Numar_CM_initial char(10), @Regim_de_lucru float, @Ore_CM int, 
	@vIndemnizatie_unitate1378 float, @vIndemnizatie_CAS459 float, @vIndemnizatie_CAS1378 float, @vZile_luna_anterioara int, @Nr_zile_angajator_cal float, @Nr_zile_angajator_lucr float, 
	@Data_inceput_cm_initial datetime, @Data_sfarsit_calcul datetime, @Exista_cm_luna_crt int, @Data_inceput_cm_luna_crt datetime, @Zile_CM_marca decimal(5,2), @Pun_ore_cm_in_pontaj int, 
	@gmarca char(6), @Continuare int, @MediaZilnica decimal(10,4), @vZile_lucratoare_in_luna int

	set @nLunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @nAnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	set @Utilizator = dbo.fIaUtilizator('')
	IF @Utilizator IS NULL or @nLunaInch not between 1 and 12 or @nAnulInch<=1901
		RETURN -1
	set @dDataInch=dbo.eom(convert(datetime,str(@nLunaInch,2)+'/01/'+str(@nAnulInch,4)))
--	verific luna inchisa
	IF @dataSus<=@dDataInch
	Begin
		raiserror('(calcul_concedii_medicale) Luna pe care doriti sa efectuati calcul concedii medicale este inchisa!' ,16,1)
		RETURN -1
	End	

	set @Pun_ore_cm_in_pontaj = dbo.iauParL('PS','ORECMPONT')
	update po set ore_concediu_medical=0 
	from pontaj po
		left outer join personal p on p.Marca=po.marca
	where @Pun_ore_cm_in_pontaj=1 and data between @dataJos and @dataSus 
		and (@pMarca='' or po.marca=@pMarca) and (@pLocm='' or p.Loc_de_munca like rtrim(@pLocm)+'%')

	Declare cursor_CM Cursor For
	Select a.data, a.marca, a.tip_diagnostic, a.Data_inceput, a.Data_sfarsit, a.Zile_lucratoare, a.Zile_luna_anterioara, a.Indemnizatia_zi, a.Baza_calcul, a.Zile_lucratoare_in_luna, 
		a.Indemnizatii_calc_manual, a.Suma, b.Serie_certificat_CM_initial, b.Nr_certificat_CM_initial, 
		isnull((select max(j.regim_de_lucru) from pontaj j where j.data between @dataJos and @dataSus and j.marca=a.marca),8),
		isnull((select max(j.ore_concediu_medical) from pontaj j where j.data between @dataJos and @dataSus and j.marca=a.marca),''),
		isnull((select count(1) from conmed c where c.data=a.data and c.marca=a.marca and c.zile_luna_anterioara=0),0), 
		isnull((select min(data_inceput) from conmed c where c.data=a.data and c.marca=a.marca and c.zile_luna_anterioara=0),convert(datetime,'01/01/1901',104)) 
	from conmed a 
		left outer join infoconmed b on b.data=a.data and b.Marca=a.Marca and b.Data_inceput=a.Data_inceput
		left outer join personal p on p.Marca=a.Marca
	where a.data between @dataJos and @dataSus and (@pMarca='' or a.marca=@pMarca) and (@pLocm='' or p.Loc_de_munca like rtrim(@pLocm)+'%')
	order by a.Data, a.Marca, a.Data_inceput

	open cursor_CM
	fetch next from cursor_CM into @data, @marca, @tip_diagnostic, @Data_inceput, @Data_sfarsit, @Zile_lucratoare, @Zile_luna_anterioara, @Indemnizatia_zi, @Baza_calcul, 
		@Zile_lucratoare_in_luna, @Indemnizatii_calc_manual, @Suma, @Serie_CM_initial, @Numar_CM_initial, @Regim_de_lucru, @Ore_CM, @Exista_cm_luna_crt, @Data_inceput_cm_luna_crt
	While @@fetch_status = 0 
	Begin
		set @gmarca=@marca
		set @Zile_CM_marca=0

		While @marca = @gmarca and @@fetch_status = 0 
		Begin
--		calculez numarul de zile lucratoare de CM anterioare (daca din greseala acesta nu a fost completat/sugerat la introducere). 
---		este necesar la determinarea nr. de zile lucratoare platite de unitate/CAS
			if @Zile_luna_anterioara=0 and @Numar_CM_initial<>''
				Select @Zile_luna_anterioara=isnull(sum(a.Zile_lucratoare),0)
				from (select c.Zile_lucratoare from conmed c
						left outer join infoconmed i on c.Data=i.Data and c.Marca=i.Marca and c.Data_inceput=i.Data_inceput
					where c.data<=@dataSus and c.Marca=@Marca and c.Data_sfarsit<=@Data_inceput-1 
						and (i.Nr_certificat_CM_initial=@Numar_CM_initial or i.Nr_certificat_CM=@Numar_CM_initial)) a

			if exists (select * from sys.objects WHERE object_id = OBJECT_ID(N'zile_lucratoareSP') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
				set @Zile_lucratoare=dbo.zile_lucratoareSP(@Data_inceput, @Data_sfarsit, @Marca)
			set @Data_inceput_cm_initial=convert(datetime,'01/01/1901',104)
			set @Zile_cu_reducere=0
			set @Nr_zile_angajator_cal=(case when @tip_diagnostic in ('2-','3-','4-') then 3 else 5 end)
			set @Nr_zile_angajator_lucr=@Nr_zile_angajator_cal
			set @Continuare=(case when @Zile_luna_anterioara>0 or @Numar_CM_initial<>'' then 1 else 0 end)
			if @Continuare=1
				set @Data_inceput_cm_initial=dbo.data_inceput_cm (@data, @marca, @data_inceput, @Continuare)
			set @Data_inceput_cm_initial=(case when @Data_inceput_cm_initial<>'01/01/1901' then @Data_inceput_cm_initial 
				else (case when @Exista_cm_luna_crt<>0 and @Zile_luna_anterioara<>0 then @Data_inceput_cm_luna_crt else @Data_inceput end) end)
			set @vZile_lucratoare_in_luna=(case when dbo.iauParLN(dbo.EOM(@data_inceput),'PS','ORE_LUNA')=0 then dbo.zile_lucratoare(dbo.BOM(@data_inceput),dbo.EOM(@data_inceput)) 
				else dbo.iauParLN(dbo.EOM(@data_inceput),'PS','ORE_LUNA')/8 end)
			set @vZile_lucratoare_in_luna=(case when @Zile_lucratoare_in_luna<>@vZile_lucratoare_in_luna then @vZile_lucratoare_in_luna else @Zile_lucratoare_in_luna end)
			if @RecalculMedieZilnica=1 and @Indemnizatii_calc_manual=0 and @tip_diagnostic<>'0-'
			Begin
				set @MediaZilnica=0	
				set @MediaZilnica=dbo.fPSCalculMedieZilnicaCM (@data,@marca,@tip_diagnostic,@data_inceput,@Zile_luna_anterioara, @Continuare,0,@Numar_CM_initial)
				set @Indemnizatia_zi=(case when @MediaZilnica=0 then @Indemnizatia_zi else @MediaZilnica end)
				set @Baza_calcul=@Indemnizatia_zi*@vZile_lucratoare_in_luna
			End
			set @data_sfarsit_calcul=dateadd(day, @Nr_zile_angajator_cal-1, @Data_inceput_cm_initial)
			if (@Data_sfarsit-@Data_inceput>=@Nr_zile_angajator_cal or @Zile_luna_anterioara>0 or @Numar_CM_initial<>'')
			Begin
				set @Nr_zile_angajator_lucr=dbo.zile_lucratoare(@Data_inceput_cm_initial,@data_sfarsit_calcul)
				if exists (select * from sys.objects WHERE object_id = OBJECT_ID(N'zile_lucratoareSP') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
					set @Nr_zile_angajator_lucr=dbo.zile_lucratoareSP(@Data_inceput_cm_initial, @data_sfarsit_calcul, @Marca)
			End
			if @tip_diagnostic in ('2-','3-','4-') and (@Data_sfarsit-@Data_inceput>=@Nr_zile_angajator_cal or @Zile_luna_anterioara>0 or @Numar_CM_initial<>'') 
			Begin
				set @Nr_zile_angajator_lucr=dbo.zile_lucratoare(@Data_inceput_cm_initial,@data_sfarsit_calcul)
				if exists (select * from sys.objects WHERE object_id = OBJECT_ID(N'zile_lucratoareSP') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
					set @Nr_zile_angajator_lucr=dbo.zile_lucratoareSP(@Data_inceput_cm_initial, @data_sfarsit_calcul, @Marca)
			End
			set @Procent=(case when @tip_diagnostic in ('10','11') then 0.25 
				when @tip_diagnostic in ('1-','7-','13','15') then 0.75 
				when @tip_diagnostic in ('5-','6-','12','14') or @tip_diagnostic in ('2-','3-','4-') and @Suma=1 then 1
				when @tip_diagnostic in ('2-','3-','4-') then 0.8 else 0.85 end) 
			set @vZile_luna_anterioara=(case when @Zile_luna_anterioara>@Nr_zile_angajator_lucr then @Nr_zile_angajator_lucr else @Zile_luna_anterioara end)

			set @vIndemnizatie_unitate1378=round((case when @Zile_lucratoare+@vZile_luna_anterioara<=@Nr_zile_angajator_lucr 
				then @Zile_lucratoare else @Nr_zile_angajator_lucr-@vZile_luna_anterioara end)*@Indemnizatia_zi*@Procent,0)
			set @Indemnizatie_unitate=(case when @tip_diagnostic in ('0-','7-','8-','9-','10','11','15') then 0 else round(@vIndemnizatie_unitate1378,0) end)

			set @vIndemnizatie_CAS459=round(@Zile_lucratoare*@Indemnizatia_zi*@Procent,0)
			set @vIndemnizatie_CAS1378=round((case when @Zile_lucratoare+@vZile_luna_anterioara<=@Nr_zile_angajator_lucr 
				then 0 else @Zile_lucratoare-(@Nr_zile_angajator_lucr-@vZile_luna_anterioara) end)*@Indemnizatia_zi*@Procent,0)
			set @Indemnizatie_CAS=(case when @tip_diagnostic in ('0-','7-','8-','9-','10','11','15') then round(@vIndemnizatie_CAS459,0) else round(@vIndemnizatie_CAS1378,0) end)

			set @Zile_cu_reducere=(case when @tip_diagnostic in ('2-','3-','4-') 
				then (case when @vZile_luna_anterioara=0 then dbo.valoare_minima(@Nr_zile_angajator_lucr,@Zile_lucratoare,0) 
					else dbo.valoare_maxima(0,@Nr_zile_angajator_lucr-@vZile_luna_anterioara,0) end) 
				else (case when @tip_diagnostic in ('1-','5-','6-','12','13','14') and @Zile_lucratoare+@vZile_luna_anterioara<=@Nr_zile_angajator_lucr then @Zile_lucratoare 
					else (case when @tip_diagnostic in ('1-','5-','6-','12','13','14') and @Zile_lucratoare+@vZile_luna_anterioara>@Nr_zile_angajator_lucr 
						then @Nr_zile_angajator_lucr-@vZile_luna_anterioara else 0 end) end) end)

			update conmed set Procent_aplicat=@Procent, 
				Zile_lucratoare=(case when Zile_lucratoare<>@Zile_lucratoare then @Zile_lucratoare else Zile_lucratoare end),
				Zile_cu_reducere=@Zile_cu_reducere, Zile_lucratoare_in_luna=@vZile_lucratoare_in_luna
			where data=@Data and marca=@Marca and Data_inceput=@Data_inceput
--	30/12/2011 - scos linia de mai jos. Calcul manual va insemna doar medie zilnica. Indemnizatiile se vor calcula tot timpul functie de media zilnica.
--				if @Indemnizatii_calc_manual=0
			update conmed set Indemnizatie_unitate=@Indemnizatie_unitate, Indemnizatie_CAS=@Indemnizatie_CAS, 
				Indemnizatia_zi=(case when @RecalculMedieZilnica=1 and @Indemnizatia_zi<>0 then @Indemnizatia_zi else Indemnizatia_zi end), 
				Baza_calcul=(case when @RecalculMedieZilnica=1 and @Indemnizatia_zi<>0 then @Baza_calcul else Baza_calcul end)
			where data=@Data and marca=@Marca and Data_inceput=@Data_inceput
			If @pMarca<>''
			Begin
				set @pProcent=@Procent
				set @pZileLucratoare=@Zile_lucratoare
				If @Indemnizatii_calc_manual=0 or 1=1
				Begin
					set @pIndemnizatieUnitate=@Indemnizatie_unitate
					set @pIndemnizatieCAS=@Indemnizatie_CAS
					set @pZileUnitate=@Zile_cu_reducere
				End
			End
			set @Zile_CM_marca=@Zile_CM_marca+(case when year(@data_inceput)=year(@dataSus) and month(@data_inceput)=month(@dataSus) and @Tip_diagnostic<>'0-' 
				then @Zile_lucratoare*(case when @tip_diagnostic='10' then 0.25 else 1 end) else 0 end)

			fetch next from cursor_CM into @data, @marca, @tip_diagnostic, @Data_inceput, @Data_sfarsit, @Zile_lucratoare, @Zile_luna_anterioara, @Indemnizatia_zi, 
			@Baza_calcul, @Zile_lucratoare_in_luna, @Indemnizatii_calc_manual, @Suma, @Serie_CM_initial, @Numar_CM_initial, @Regim_de_lucru, @Ore_CM, @Exista_cm_luna_crt, 
			@Data_inceput_cm_luna_crt
		End 
		update pontaj set ore_concediu_medical=round(@Zile_CM_marca*regim_de_lucru,0)
		where @Pun_ore_cm_in_pontaj=1 and data between @dataJos and @dataSus and marca=@gmarca 
			and numar_curent in (select max(j.numar_curent) from pontaj j where j.data between @dataJos and @dataSus and j.marca=@gmarca and j.loc_munca_pentru_stat_de_plata=1)
		set @gmarca=@marca
	End
	close cursor_CM
	Deallocate cursor_CM
End
