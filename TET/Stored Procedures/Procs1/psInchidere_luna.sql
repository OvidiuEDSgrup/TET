--***
/**	procedura de prelucrare date la inchidere luna salarii **/
Create procedure psInchidere_luna
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @PreluareVechime int, @PreluareSporVechime int, @PreluareSporSpecific int, 
	@PreluareRetineri int, @PreluareAvans int, @PreluarePersintr int, @PreluareCorLm int, @PreluareCONeefect int, @PreluarePensiiFac int, @PreluareParLunari int
As
Begin
	declare @utilizator varchar(20), @lista_lm int, 
	@dataJosNext datetime, @dataSusNext datetime, @Pensie_ded float, @lApelProcIL1 int, @lApelProcIL2 int, 
	@nLunaInch int, @LunaInchAlfa char(15), @nAnulInch int, @dDataInch datetime, @nLunaBloc int, @LunaBlocAlfa char(15), @nAnulBloc int, @dDataBloc datetime, 
	@nLunaNext int, @LunaNextAlfa char(15), @nAnulNext int, @cComanda varchar(2000), @cDataSave char(6)

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	set @dataJosNext=dbo.bom(DateAdd(month,1,@dataSus))
	set @dataSusNext=dbo.eom(DateAdd(month,1,@dataSus))
	set @Pensie_ded=dbo.iauParN('PS','PENSIEDED')
	set @lApelProcIL1=dbo.iauParL('PS','PROCIL1')
	set @lApelProcIL2=dbo.iauParL('PS','PROCIL2')
	set @nLunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @nAnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	set @nLunaBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNABLOC'), 1)
	set @nAnulBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANULBLOC'), 1901)
	set @dDataBloc=dateadd(month,1,convert(datetime,str(@nLunaBloc,2)+'/01/'+str(@nAnulBloc,4)))
	set @cDataSave=left(convert(char(10),@dataSus,101),2)+right(convert(char(10),@dataSus,101),4)
	
	if @nLunaInch not between 1 and 12 or @nAnulInch<=1901
		return
	set @dDataInch=dateadd(month,1,convert(datetime,str(@nLunaInch,2)+'/01/'+str(@nAnulInch,4)))

--	restrictie daca luna inchisa
	if @dataSus>@dDataInch and @dataSus<DateAdd(month,1,@dDataInch)
	Begin
--	salvare tabele personal si infopers 
/*
		Set @cComanda='if (select count(1) from sysobjects where name='+char(39)+'personal'+@cDataSave+char(39)+')=0'+
			' select * into personal'+@cDataSave+' from personal'
		exec (@cComanda)
		Set @cComanda='if (select count(1) from sysobjects where name='+char(39)+'infopers'+@cDataSave+char(39)+')=0'+
			' select * into infopers'+@cDataSave+' from infopers'
		exec (@cComanda)
*/
		If @lApelProcIL1=1
			exec inchlunasp1 @dataJos, @dataSus, @pMarca

		if @PreluareVechime=1
			exec psActualizare_sporuri @dataJos, @dataSus, @pMarca, 1, 0, '1', ''
		if @PreluareSporVechime=1
			exec psActualizare_sporuri @dataJos, @dataSus, @pMarca, 1, 0, '2', ''
		if @PreluareSporSpecific=1
			exec psActualizare_sporuri @dataJos, @dataSus, @pMarca, 1, 0, '3', ''
		if @PreluareCONeefect=1
			exec psActualizare_sporuri @dataJos, @dataSus, @pMarca, 1, 0, '4', ''

--	preluare avans exceptie
		if @PreluareAvans=1
			insert into avexcep (Marca, Data, Ore_lucrate_la_avans, Suma_avans, Premiu_la_avans)
			Select a.Marca, @dataSusNext, a.Ore_lucrate_la_avans, a.Suma_avans, a.Premiu_la_avans 
			from avexcep a
				left outer join personal p on a.marca=p.marca
				left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
			where (@pMarca='' or a.Marca=@pMarca) and a.data between @dataJos and @dataSus and not(p.Loc_ramas_vacant=1 and p.data_plec<=DateADD(day,1,@dataSus))
				and (@lista_lm=0 or lu.cod is not null) 
				and not exists (select 1 from avexcep b where b.data=@dataSusNext and b.Marca=a.Marca)
--	preluare persoane in intretinere
		if @PreluarePersintr=1
		Begin
			insert into persintr (Marca, Tip_intretinut, Cod_personal, Nume_pren, Data, Grad_invalid, Coef_ded, Data_nasterii)
			Select a.Marca,(case when a.Tip_intretinut in ('C','U') and datediff(day,a.Data_nasterii,@dataSusNext)>6574 then 'A' else a.Tip_intretinut end),
			a.Cod_personal, a.Nume_pren, @dataSusNext, a.Grad_invalid, 
			(case when isnull(e.Data_exp_ded,'01/01/1901')>=@dataJos and isnull(e.Data_exp_ded,'01/01/1901')<=@dataSus then 0 else a.Coef_ded end), a.Data_nasterii
			from persintr a
				left outer join extpersintr e on e.Data=a.Data and e.Marca=a.Marca and e.Cod_personal=a.Cod_personal
				left outer join personal p on a.marca=p.marca
				left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
			where a.data between @dataJos and @dataSus and (p.Loc_ramas_vacant=0 or p.Data_plec>DateADD(day,1,@dataSus))
				and (@lista_lm=0 or lu.cod is not null)
				and not exists (select 1 from persintr b where b.Data=@dataSusNext and b.Marca=a.Marca and b.Cod_personal=a.Cod_personal)

			insert into extpersintr (Data, Marca, Cod_personal, Data_exp_ded, Data_exp_coasig, Venit_lunar, Deducere, Coasigurat, Tip_intretinut_2, Valoare, Observatii)
			Select @dataSusNext, a.Marca, a.Cod_personal, isnull(e.Data_exp_ded,'01/01/1901'), isnull(e.Data_exp_coasig,'01/01/1901'), isnull(e.Venit_lunar,0), 
				isnull(e.Deducere,0), isnull(e.Coasigurat,''), isnull(e.Tip_intretinut_2,''), isnull(e.Valoare,0), isnull(e.Observatii,'')
			from persintr a
				left outer join extpersintr e on e.Data=a.Data and e.Marca=a.Marca and e.Cod_personal=a.Cod_personal
				left outer join personal p on a.marca=p.marca
				left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
			where (@pMarca='' or a.Marca=@pMarca) and a.data between @dataJos and @dataSus and (p.Loc_ramas_vacant=0 or p.Data_plec>DateADD(day,1,@dataSus))
				and (@lista_lm=0 or lu.cod is not null) 
				and not exists (select 1 from extpersintr b where b.Data=@dataSusNext and b.Marca=a.Marca and b.Cod_personal=a.Cod_personal)
		End
--	preluare retineri pe sold
		if @PreluareRetineri=1
			insert into Resal (Data, Marca, Cod_beneficiar, Numar_document, Data_document, Valoare_totala_pe_doc, Valoare_retinuta_pe_doc, Retinere_progr_la_avans, Retinere_progr_la_lichidare, 
				Procent_progr_la_lichidare, Retinut_la_avans, Retinut_la_lichidare)
			Select @dataSusNext, a.Marca, a.Cod_beneficiar, a.Numar_document, a.Data_document, a.Valoare_totala_pe_doc, a.Valoare_retinuta_pe_doc, a.Retinere_progr_la_avans, 
				a.Retinere_progr_la_lichidare, a.Procent_progr_la_lichidare, 0, 0
			from resal a
				left outer join personal p on a.marca=p.marca
				left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
			where (@pMarca='' or a.Marca=@pMarca) and a.data between @dataJos and @dataSus and (p.Loc_ramas_vacant=0 or p.Data_plec>DateADD(day,1,@dataSus))
				and (@lista_lm=0 or lu.cod is not null) 
				and (a.Valoare_totala_pe_doc=0 or a.Valoare_totala_pe_doc>0 and round(convert(decimal(14,2),a.Valoare_totala_pe_doc),2)>round(convert(decimal(14,2),a.Valoare_retinuta_pe_doc),2))
				and not exists (select 1 from resal b where b.Data=@dataSusNext and b.Marca=a.Marca and b.Cod_beneficiar=a.Cod_beneficiar and b.Numar_document=a.Numar_document)
--	preluare corectii pe locuri de munca
		if @PreluareCorLm=1
			insert into corectii (Data, Marca, Loc_de_munca, Tip_corectie_venit, Suma_corectie, Procent_corectie, Suma_neta)
			Select @dataSusNext, a.Marca, a.Loc_de_munca, a.Tip_corectie_venit, a.Suma_corectie, a.Procent_corectie, a.Suma_neta
			from corectii a
				left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=a.loc_de_munca
			where a.data between @dataJos and @dataSus and a.Marca=''
				and (@lista_lm=0 or lu.cod is not null) 
				and not exists (select 1 from corectii b where b.Data=@dataSusNext and b.Marca='' and b.Loc_de_munca=a.Loc_de_munca and b.Tip_corectie_venit=a.Tip_corectie_venit)

--	preluare date corectia T (pensii facultative suportate de angajator)
		insert into corectii (Data, Marca, Loc_de_munca, Tip_corectie_venit, Suma_corectie, Procent_corectie, Suma_neta)
		Select @dataSusNext, a.Marca, a.Loc_de_munca, a.Tip_corectie_venit, a.Suma_corectie, a.Procent_corectie, a.Suma_neta
		from corectii a
			left outer join subtipcor s on a.Tip_corectie_venit=s.Subtip
			left outer join personal p on a.marca=p.marca
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
		where a.data between @dataJos and @dataSus and a.Marca<>'' and (a.Tip_corectie_venit='T-' or s.Tip_corectie_venit='T-')
			and (@lista_lm=0 or lu.cod is not null) 
			and not exists (select 1 from corectii b where b.Data=@dataSusNext and b.Marca='' and b.Loc_de_munca=a.Loc_de_munca 
				and b.Tip_corectie_venit=a.Tip_corectie_venit)
--	actualizez locul de munca din personal dupa ultimul loc de munca din net (cel bifat pentru stat de plata)
		update personal set loc_de_munca=isnull(NET.loc_de_munca, personal.loc_de_munca) 
			from net 
				left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=net.loc_de_munca
			where data=@dataSus and net.marca=personal.marca and personal.loc_de_munca<>net.loc_de_munca
				and (@lista_lm=0 or lu.cod is not null) 
				and (@pMarca='' or personal.Marca=@pMarca)
--	apelare procedura pt. scriere date in salariati (din extinfop). Datele operate in avans in CTRL+D din macheta salariati.
		exec Actualizare_date_salariati @dataJos, @dataSus, '', ''
--	preluare pensii facultative
		if @PreluarePensiiFac=1
			insert into extinfop (Marca, Cod_inf, Val_inf, Data_inf, Procent)
			select e.Marca, e.Cod_inf, ltrim(rtrim(convert(char(10),@Pensie_ded))), dbo.boy(@dataSusNext), (case when e.Procent<>0 then e.Procent/*round(@Pensie_ded/12,0)*/ else 0 end)
			from extinfop e
				left outer join personal p on e.marca=p.marca
				left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
			where (@pMarca='' or e.Marca=@pMarca) and e.cod_inf='PENSIIF' and e.data_inf=dbo.boy(@dataSus) 
				and (e.val_inf<>'' and convert(int,e.val_inf)<>0 or e.Procent<>0)
				and (@lista_lm=0 or lu.cod is not null) 
				and p.Loc_ramas_vacant=0 and 
				not exists (select 1 from extinfop e1 where e1.cod_inf=e.cod_inf and e1.Marca=e.Marca and e1.data_inf=dbo.boy(@dataSusNext))

		if @PreluareParLunari=1
			exec psInitParLunari @dataJosNext, @dataSusNext, 1
		
		If @lApelProcIL2=1
			exec inchlunasp2 @dataJos, @dataSus, @pMarca

--	apelez scrierea in istoric personal pentru luna ulterioara lunii inchisa
		exec scriuistPers @dataJosNext, @dataSusNext, @pMarca, '', 1, 1, 0, 0, '01/01/1901'

		exec setare_par 'PS', 'VECTOTSAL', 'Vechime totala in Salariati:+1 luna', @PreluareVechime, 0, ''
		exec setare_par 'PS', 'SPORVECHS', 'Spor vech Salariati:conf.grila', @PreluareSporVechime, 0, ''
		exec setare_par 'PS', 'SPORSPES', 'Spor spec Salariati:conf.grila', @PreluareSporSpecific, 0, ''
		exec setare_par 'PS', 'RETOPRETI', 'Preluare retineri conform ratelor', @PreluareRetineri, 0, ''
		exec setare_par 'PS', 'PRELAVEXC', 'Preluare avans exceptie', @PreluareAvans, 0, ''
		exec setare_par 'PS', 'PRCFPSINT', 'Preluare coef.pers.intretinere', @PreluarePersintr, 0, ''
		exec setare_par 'PS', 'PRELCORLM', 'Preluare corectii pe loc munca', @PreluareCorLm, 0, ''
		exec setare_par 'PS', 'ZILECORAM', 'Preluare zile CO ramase neef.', @PreluareCONeefect, 0, ''
		Select @nLunaInch=month(@dataSus), @nAnulInch=year(@dataSus), @nLunaNext=month(@dataSusNext), @nAnulNext=year(@dataSusNext)
		Select @LunaInchAlfa=isnull(LunaAlfa,'') from dbo.fCalendar(@dataSus,@dataSus)
		Select @LunaNextAlfa=isnull(LunaAlfa,'') from dbo.fCalendar(@dataSusNext,@dataSusNext)
-- luna inchisa
		exec setare_par 'PS', 'LUNA-INCH', 'Ultima luna inchisa', 0, @nLunaInch, @LunaInchAlfa
		exec setare_par 'PS', 'ANUL-INCH', 'Anul inchis', 0, @nAnulInch, ''
		set @dDataInch=dateadd(month,1,convert(datetime,str(@nLunaInch,2)+'/01/'+str(@nAnulInch,4)))

		if @dDataBloc<@dDataInch
		Begin
			exec setare_par 'PS', 'LUNABLOC', 'Ultima luna blocata', 0, @nLunaInch, @LunaInchAlfa
			exec setare_par 'PS', 'ANULBLOC', 'Anul blocat', 0, @nAnulInch, ''
		End
-- luna de lucru
		exec setare_par 'PS', 'LUNA', 'Luna curenta', 0, @nLunaNext, @LunaNextAlfa
		exec setare_par 'PS', 'ANUL', 'Anul de lucru', 0, @nAnulNext, ''
	End
End
