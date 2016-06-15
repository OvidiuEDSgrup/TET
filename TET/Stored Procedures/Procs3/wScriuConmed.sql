--***
Create procedure wScriuConmed @sesiune varchar(50), @parXML xml 
as
declare @ptupdate int, @tip varchar(40), @subtip varchar(2), @datalunii datetime, @Datalunii_1 datetime, @o_marca varchar(6), @marca varchar(6), 
@o_tipdiagnostic varchar(2), @tip_diagnostic varchar(2), @o_datainceput datetime, @data_inceput datetime, @data_sfarsit datetime, @Data_inceput_CM_initial datetime, 
@Zile_lucr_CM int, @Zile_luna_anterioara int, @Zile_calend_luna_ant int, @Serie_CM varchar(10), @Numar_CM varchar(10), @zile_stagiu int, @zile_asigurate int, @zile_asigurate_12luni int, 
@Serie_CM_ini varchar(10),@Numar_CM_ini varchar(10), @CM_initial varchar(20), @Cod_diagnostic varchar(10), @Cod_urgenta varchar(10), @Cod_grupaA varchar(10), 
@Data_acordarii datetime, @Cnp_copil char(13), @Loc_prescriere int, @Medic_prescriptor char(50), @Unitate_sanitara char(50), @Nr_aviz_me char(10),
@Media_zilnica float, @Ind_calc_manual int, @codac varchar(20), @Procent float, @Baza_calcul float, @Zile_lucratoare_in_luna int, 
@Indemnizatie_unitate float, @Indemnizatie_CAS float, @Zile_cu_reducere int, @Indemnizatii_calc_manual int, @Suma float, 
@densalariat varchar(50), @denlm varchar(30), @lmpontaj varchar(9), @denlmpontaj varchar(30), @denfunctie varchar(30), 
@salarincadrare float, @Continuare int, @Zile_calend_in_continuare int, @Zile_calend_12_luni int, @Zile_calend_CMcrt int, 
@Ore_CM int, @userASiS varchar(20), @docXML xml, @docXMLIaDLSalarii xml, @docXMLPontaj xml, @eroare xml, @mesaj varchar(254), @mesajEroare varchar(1000), @mesajAvertizare varchar(1000)

begin try
	--BEGIN TRAN
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuConmedSP')
		exec wScriuConmedSP @sesiune, @parXML OUTPUT
	if exists (select 1 from sysobjects where [type]='P' and [name]='wValidareConmed')
		exec wValidareConmed @sesiune, @parXML
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	declare crsConmed cursor for
	select isnull(ptupdate, 0) as ptupdate, isnull(tip, '') as tip, isnull(subtip, '') as subtip, 
	isnull(datalunii,'01/01/1901') as datalunii, isnull(o_marca, isnull(marca, '')) as o_marca, 
	(case when isnull(marca, '')='' then isnull(marca_poz, '') else isnull(marca, '') end) as marca, 
	isnull(o_tipdiagnostic, '') as o_tipdiagnostic, isnull(tip_diagnostic, '') as tip_diagnostic,
	isnull(o_datainceput, '01/01/1901') as o_datainceput, 
	isnull(data_inceput, '01/01/1901') as data_inceput,
	isnull(data_sfarsit, '01/01/1901') as data_sfarsit,
	isnull(Serie_CM, '') as Serie_CM,
	isnull(Numar_CM, '') as Numar_CM,
	isnull(CM_initial, '') as CM_initial,
	isnull(Cod_diagnostic, '') as Cod_diagnostic,
	isnull(Cod_urgenta, '') as Cod_urgenta,
	isnull(Cod_grupaA, '') as Cod_grupaA,
	isnull(Data_acordarii,'') as Data_acordarii,
	isnull(Cnp_copil,'') as Cnp_copil,
	isnull(Loc_prescriere,0) as Loc_prescriere,
	isnull(Medic_prescriptor,'') as Medic_prescriptor,
	isnull(Unitate_sanitara,'') as Unitate_sanitara,
	isnull(Nr_aviz_me,'') as Nr_aviz_me,
	isnull(Media_zilnica,0) as Media_zilnica,
	isnull(Ind_calc_manual,0) as Ind_calc_manual,
	isnull(Indemnizatie_unitate,0) as Indemnizatie_unitate,
	isnull(Indemnizatie_CAS,0) as Indemnizatie_CAS,
	isnull(densalariat,'') as densalariat, 
	isnull(denlm,'') as denlm,
	isnull(denfunctie,'') as denfunctie,
	isnull(salarincadrare,0) as salarincadrare,
	(case when isnull(lmpontaj,'')='' then (select p.loc_de_munca from personal p where p.marca=isnull(a.marca, a.marca_poz)) else 		isnull(lmpontaj,'') end) as lmpontaj,
	isnull(denlmpontaj,'') as denlmpontaj
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		ptupdate int '@update',
		tip varchar(40) '../@tip', 
		subtip varchar(2) '@subtip', 
		datalunii datetime '../@data',
		o_marca varchar(6) '@o_marca', 
		marca varchar(6) '../@marca', 
		marca_poz varchar(6) '@marca', 
		o_tipdiagnostic varchar(2) '@o_tipconcediu', 
		tip_diagnostic varchar(2) '@tipconcediu', 
		o_datainceput datetime '@o_datainceput', 
		data_inceput datetime '@datainceput', 
		data_sfarsit datetime '@datasfarsit', 
		Serie_CM varchar(10) '@seriecm',
		Numar_CM varchar(10) '@numarcm',
		CM_initial varchar(20) '@cminitial',
		Cod_diagnostic varchar(10) '@coddiagnostic',
		Cod_urgenta varchar(10) '@codurgenta',
		Cod_grupaA varchar(10) '@codgrupaa',
		Data_acordarii datetime '@dataacordarii',
		Cnp_copil varchar(13) '@cnpcopil',
		Loc_prescriere int '@locprescriere',
		Medic_prescriptor varchar(50) '@medicprescriptor',
		Unitate_sanitara varchar(50) '@unitatesanitara',
		Nr_aviz_me varchar(10) '@nravizme',
		Media_zilnica float '@mediazilnica', 
		Ind_calc_manual int '@calculmanual', 
		Indemnizatie_unitate float '@indunitate', 
		Indemnizatie_CAS float '@indcas', 
		densalariat varchar(50) '../@densalariat', 
		denlm varchar(30) '../@denlm', 
		denfunctie varchar(30) '../@denfunctie', 
		salarincadrare float '../@salarincadrare', 
		lmpontaj varchar(30) '@lm', 
		denlmpontaj varchar(30) '@denlm' 
	) a

	open crsConmed
	fetch next from crsConmed into @ptupdate, @tip, @subtip, @datalunii,@o_marca,@marca,@o_tipdiagnostic,@tip_diagnostic,
	@o_datainceput, @data_inceput, @data_sfarsit, @Serie_CM, @Numar_CM, @CM_initial, @Cod_diagnostic, @Cod_urgenta, @Cod_grupaA, 
	@Data_acordarii, @Cnp_copil, @Loc_prescriere, @Medic_prescriptor, @Unitate_sanitara, @Nr_aviz_me,
	@Media_zilnica, @Ind_calc_manual, @Indemnizatie_unitate, @Indemnizatie_CAS, 
	@densalariat, @denlm, @denfunctie, @salarincadrare, @lmpontaj, @denlmpontaj
	while @@fetch_status=0
	begin
		Set @Datalunii_1=dbo.bom(@datalunii)
		exec psInitParLunari @dataJos=@Datalunii_1, @dataSus=@datalunii, @deLaInchidere=0
		Set @Zile_lucr_CM=dbo.Zile_lucratoare(@data_inceput,@data_sfarsit)
		Set @Serie_CM_ini=(case when @CM_initial<>'' then left(@CM_initial,charindex(' ',@CM_initial)-1) else '' end)
		Set @Numar_CM_ini=(case when @CM_initial<>'' then substring(@CM_initial,charindex(' ',@CM_initial)+1,10) else '' end)
		Set @Continuare=(case when @CM_initial<>'' then 1 else 0 end)
		Select @Zile_luna_anterioara=0, @Zile_calend_luna_ant=0, @Zile_calend_CMcrt=0, @Zile_calend_in_continuare=0, @Zile_calend_12_luni=0
		Set @Zile_calend_CMcrt=DATEDIFF(DAY,@data_inceput,@data_sfarsit)+1

--	Set @Media_zilnica=0
--	citesc datele pt. concediile medicale care sunt in continuare
		if @Continuare=1 and @Tip_diagnostic<>'0-' -- and @Ind_calc_manual=0
			Select @Zile_luna_anterioara=a.Zile_lucratoare+a.Zile_luna_anterioara, 
				@Zile_calend_luna_ant=a.Zile_CAS+DateDiff(day,a.Data_inceput,a.Data_sfarsit)+1,
				@Media_zilnica=(case when @Ind_calc_manual=0 then isnull(a.Indemnizatia_zi,0) else @Media_zilnica end),
				@Cod_diagnostic=(case when @Cod_diagnostic='' then a.Cod_diagnostic else @Cod_diagnostic end)
			from (select top 1 c.Data_inceput, c.Data_sfarsit, c.Zile_lucratoare, c.Zile_luna_anterioara, c.Indemnizatia_zi, i.Zile_CAS, i.Alfa as Cod_diagnostic
				from conmed c
					left outer join infoconmed i on c.Data=i.Data and c.Marca=i.Marca and c.Data_inceput=i.Data_inceput
				where @Continuare=1 and c.data between dbo.eom(dateadd(month,-1,@datalunii)) and @datalunii 
					and c.Marca=@Marca and c.Data_sfarsit<=@data_inceput-1 
					and (i.Nr_certificat_CM_initial=@Numar_CM_ini or i.Nr_certificat_CM=@Numar_CM_ini) 
				order by c.data_inceput desc) a

		if @Tip_diagnostic<>'0-' and @Ind_calc_manual=0
			select @Media_zilnica=(case when @Media_zilnica=0 then isnull((select round(sum(Baza_cci_plaf)/sum(Zile_asig),4) from dbo.fIstoric_cm(@datalunii,@Marca,@Tip_diagnostic,@Data_inceput,@Continuare,0,0)),0) else @Media_zilnica end)
		Set @Zile_lucratoare_in_luna=(case when dbo.iauParLN(@datalunii,'PS','ORE_LUNA')=0 then dbo.zile_lucratoare(@Datalunii_1,@datalunii) else dbo.iauParLN(@datalunii,'PS','ORE_LUNA')/8 end)
		Set @Indemnizatii_calc_manual=@Ind_calc_manual
		Set @Suma=(case when @Cod_urgenta<>'' and @tip_diagnostic in ('2-','3-','4-') then 1 else 0 end)
		Set @Procent=0
		Set @Zile_cu_reducere=0
--		Set @Indemnizatie_unitate=0
--		Set @Indemnizatie_CAS=0
		Set @Baza_calcul=round(@Media_zilnica*@Zile_lucratoare_in_luna,0)
		if @ptupdate=1 and (@marca<>@o_marca or @Data_inceput<>@o_datainceput)
		Begin
			delete from conmed where Data=@Datalunii and Marca=@o_marca and Data_inceput=@o_datainceput
			delete from infoconmed where Data=@Datalunii and Marca=@o_marca and Data_inceput=@o_datainceput
		End

--		avertizari privind faptul ca salariatul nu are stagiu complet in ultimele 6 luni/12 luni.
		if @continuare=0
		begin
			select @zile_asigurate=sum(zile_asig) from dbo.fIstoric_cm(@datalunii,@Marca,@Tip_diagnostic,@Data_inceput,@Continuare,0,0)
			set @zile_asigurate=isnull(@zile_asigurate,0)
			set @zile_stagiu=(select sum(val_numerica)/8.00 from par_lunari where tip='PS' and parametru='ORE_LUNA' 
				and data between dbo.eom(dateadd(month,-6,@Data_inceput)) and dbo.eom(dateadd(month,-1,@Data_inceput)))
			select @zile_asigurate_12luni=sum(zile_asig) from dbo.fIstoric_cm(@datalunii,@Marca,@Tip_diagnostic,@Data_inceput,@Continuare,0,12)
			if @tip_diagnostic in ('1-','7-','8-','9-','10','11','13') and @zile_asigurate_12luni<22
			begin
				select @Media_zilnica=0, @Indemnizatii_calc_manual=1	-- Daca nu are stagiu, se pune media zilnica=0 si indemnizatii calculate manual=1.
				set @mesajAvertizare='Salariatul nu are stagiul MINIM de cotizare pe ultimele 12 luni anterioare concediului medical: zile asigurate ('+rtrim(convert(char(3),@zile_asigurate_12luni))
					+') mai mic decat numarul minim de zile de stagiu (22) prevazut in OUG 158/2005!' 
				select @mesajAvertizare as textMesaj for xml raw, root('Mesaje')
			end
			if @tip_diagnostic<>'0-' and @zile_asigurate<>@zile_stagiu
				select 'Salariatul nu are stagiu de cotizare complet pe ultimele 6 luni anterioare concediului medical: zile stagiu ('+rtrim(convert(char(3),@zile_asigurate))+ 
					+') diferit de zile lucratoare ('+rtrim(convert(char(3),@zile_stagiu))+')!' as textMesaj for xml raw, root('Mesaje')
		end

		exec scriuConmed @datalunii, @Marca, @Tip_diagnostic, @Data_inceput, @Data_sfarsit, @Zile_lucr_CM, 
		@Zile_cu_reducere, @Zile_luna_anterioara, @Media_zilnica, @Procent, @Indemnizatie_unitate, @Indemnizatie_CAS, 
		@Baza_calcul, @Zile_lucratoare_in_luna, @Indemnizatii_calc_manual, @Suma, @Serie_CM, @Numar_CM, @Serie_CM_ini, @Numar_CM_ini, 
		@Cod_urgenta, @Cod_grupaA, @Data_acordarii, @Cnp_copil, @Loc_prescriere, @Medic_prescriptor, 
		@Unitate_sanitara, @Nr_aviz_me, 0, @Cod_diagnostic, @Zile_calend_luna_ant

		exec calcul_concedii_medicale @Datalunii_1, @Datalunii, @Marca, @data_inceput, @Zile_lucr_CM, @Zile_cu_reducere, 
		@Zile_luna_anterioara, @Media_zilnica, @Procent, @Indemnizatie_unitate, @Indemnizatie_CAS, @Baza_calcul, 
		@Zile_lucratoare_in_luna, @Indemnizatii_calc_manual, 1, ''

		Select @Ore_CM=isnull(sum(cm.Zile_lucratoare)*max((case when p.Salar_lunar_de_baza<>0 then Salar_lunar_de_baza else 8 end)),0) 
		from conmed cm
			left outer join personal p on cm.Marca=p.Marca
		where cm.data=@Datalunii and cm.Data_inceput between @Datalunii_1 and @Datalunii and cm.Marca=@Marca and cm.Tip_diagnostic<>'0-'

--	avertizari legate de durata de acordare a concediilor medicale de incapacitate temporara de munca pe ultimele 12 luni (fara aviz medic expert)
		declare	@Tip_diagnostic_IT char(30), @DataLunii_11 datetime
		set @Tip_diagnostic_IT='1-5-6-'  --121314 pentru moment am scos cele 3 tipuri de diagnostic din lista intrucat pt. acestea se pot acorda alte durate de concedii medicale
		set @DataLunii_11=dbo.eom(DateADD(month,-11,@datalunii))

		set @Zile_calend_12_luni=dbo.fCalculZileCMefectuate(@marca, @DataLunii_11, @datalunii, @data_inceput, @Tip_diagnostic_IT)
		if charindex(@tip_diagnostic,@Tip_diagnostic_IT)<>0 and @Zile_calend_12_luni+@Zile_calend_CMcrt>90 and @Nr_aviz_me=''
			select 'Numarul de zile calendaristice de CM pt. incapacitate temporara de munca acordate pe ultimele 12 luni, fara avizul medicului expert ('+rtrim(convert(char(3),@Zile_calend_12_luni+@Zile_calend_CMcrt))+')'
				+', depaseste 90 de zile!' as textMesaj for xml raw, root('Mesaje')

--	avertizari legate de durata de acordare a concediilor medicale pe tipuri de diagnostic
		set @Zile_calend_in_continuare=@Zile_calend_luna_ant+@Zile_calend_CMcrt
		if @tip_diagnostic='1-' and @Zile_calend_in_continuare>90 and @Nr_aviz_me=''
			select 'Numarul de zile calendaristice de CM acordate pt. tip diagnostic boala obisnuita: '+convert(char(3),@Zile_calend_in_continuare)
				+', depaseste durata de acordare a acestui tip de CM: 90 de zile!' as textMesaj for xml raw, root('Mesaje')
		if @tip_diagnostic='8-' and @Zile_calend_in_continuare>126
			select 'Numarul de zile calendaristice de CM acordate pt. tip diagnostic sarcina si lahuzie: '+convert(char(3),@Zile_calend_in_continuare)
				+', depaseste durata de acordare a acestui tip de CM: 126 de zile!' as textMesaj for xml raw, root('Mesaje')
		if @Nr_aviz_me<>'' and @Zile_calend_in_continuare>183
			select 'Numarul de zile calendaristice de CM acordate cu avizul medicului expert: '+convert(char(3),@Zile_calend_in_continuare)
				+', depaseste durata de acordare a acestui tip de CM: 183 de zile!' as textMesaj for xml raw, root('Mesaje')

		If @Ore_CM<>0
		Begin
			Set @docXMLPontaj='<row tip="'+rtrim(@tip)+'" marca="'+rtrim(@marca)+'" data="'+convert(char(10),@datalunii,101)
				+'" densalariat="'+rtrim(@densalariat)+'" denlm="'+rtrim(@denlm)+'" denfunctie="'+rtrim(@denfunctie)
				+'" salarincadrare="'+rtrim(convert(char(10),convert(decimal(10,2),@salarincadrare)))+'">'
				+'<row subtip="'+@subtip+'" data="'+convert(char(10),@datalunii,101)+'" orecm="'+rtrim(convert(char(10),@Ore_CM))
					+'" lm="'+rtrim(@lmpontaj)+'" denlm="'+rtrim(@denlmpontaj)+ '"/></row>'
			exec wScriuPontaj @sesiune=@sesiune, @parXML=@docXMLPontaj
		End
		fetch next from crsConmed into @ptupdate, @tip, @subtip, @datalunii,@o_marca,@marca,@o_tipdiagnostic,@tip_diagnostic,
		@o_datainceput, @data_inceput, @data_sfarsit, @Serie_CM, @Numar_CM, @CM_initial, @Cod_diagnostic, @Cod_urgenta, @Cod_grupaA, 
		@Data_acordarii, @Cnp_copil, @Loc_prescriere, @Medic_prescriptor, @Unitate_sanitara, @Nr_aviz_me,
		@Media_zilnica, @Ind_calc_manual, @Indemnizatie_unitate, @Indemnizatie_CAS, 
		@densalariat, @denlm, @denfunctie, @salarincadrare, @lmpontaj, @denlmpontaj
	end
	set @docXMLIaDLSalarii='<row tip="'+rtrim(@tip)+'" subtip="'+rtrim(@subtip)+'" marca="'+rtrim(@marca)+
	'" data="'+convert(char(10),@datalunii,101)+'" densalariat="'+rtrim(@densalariat)+'" denlm="'+rtrim(@denlm)+
	'" denfunctie="'+rtrim(@denfunctie)+'" salarincadrare="'+rtrim(convert(char(10),convert(decimal(10,2),@salarincadrare)))+'"/>'
	exec wIaPozSalarii @sesiune=@sesiune, @parXML=@docXMLIaDLSalarii 
	--COMMIT TRAN
end try

begin catch
	--ROLLBACK TRAN
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0)=0
		set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
--
declare @cursorStatus int
set @cursorStatus=(select top 1 is_open from sys.dm_exec_cursors(0) where name='crsConmed' and session_id=@@SPID)
if @cursorStatus=1 
	close crsConmed 
if @cursorStatus is not null 
	deallocate crsConmed 
--
begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
