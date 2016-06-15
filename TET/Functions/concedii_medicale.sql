--***
/**	functie concedii medicale	*/
Create function concedii_medicale 
	(@MarcaJ char(6), @MarcaS char(6), @DataJ datetime, @DataS datetime, @CodBoalaJos char(2), @CodBoalaSus char(2), @lTipDiagnosticExceptie bit, @cTipDiagnosticExceptat char(2),
	@cLocmJ char(9), @cLocmS char(9), @lActivitate bit, @cActivitate varchar(20), @ordonare char(1), @alfabetic int, @lLocmStatie int, @cLocmStatie char(200), @CMmm30Zile int, 
	@Luni_istoric int=6) 
returns @concedii_medicale table
	(Data datetime, Marca char(6), Nume char(50), Loc_de_munca char(9), Denumire_locm char(30), Medie_zilnica float, 
	Cod_diagnostic char(2), Denumire_diagnostic char(30), Data_inceput datetime, Data_sfarsit datetime, Procent float, Zile_calendaristice int, Zile_lucratoare int, Zile_unitate int, Zile_buget int, 
	Zile_anterioare int, Indemnizatie_unitate int, Indemnizatie_FNUASS float, Indemnizatie_FAMBP float, zile_platite_FNUASS int, zile_platite_FAMBP int, Data_inceput_cm_initial datetime, baza_calcul float,
	Baza1 float, Baza2 float, Baza3 float, Baza4 float, Baza5 float, Baza6 float, Baza7 float, Baza8 float, Baza9 float, Baza10 float, Baza11 float, Baza12 float, Baza_Stagiu float, 
	Z_st1 int, Z_st2 int, Z_st3 int, Z_st4 int, Z_st5 int, Z_st6 int, Z_st7 int, Z_st8 int, Z_st9 int, Z_st10 int, Z_st11 int, Z_st12 int, Zile_Stagiu int, 
	Z_luc1 int, Z_luc2 int, Z_luc3 int, Z_luc4 int, Z_luc5 int, Z_luc6 int, Z_luc7 int, Z_luc8 int, Z_luc9 int, Z_luc10 int, Z_luc11 int, Z_luc12 int, 
	Tip_concediu char(10), vechime datetime, spor10 float, data_risc int, serie_cmini char(10))
as
begin
	declare @Data datetime, @DataJPoz datetime, @Marca char(6), @Nume char(50), @Loc_de_munca char(9), @denlocm char(50), 
	@Medie_zilnica float, @Cod_diagnostic char(2), @Denumire_diagnostic char(30), @Data_inceput datetime, @Data_sfarsit datetime, @Procent float, 
	@Zile_calendaristice int, @Zile_unitate int, @Zile_buget int, @Indemnizatie_unitate float, @Indemnizatie_FNUASS float,
	@Indemnizatie_FAAMBP float, @Data_inceput_cm_initial datetime, @baza_calcul float, @Tip_concediu char(10), @datacmi datetime, 
	@Zile_anterioare int, @Zile_lucratoare int, @zile_platite_FNUASS int, @zile_platite_FAMBP int, @vechime datetime, @spor10 float, 
	@data_risc int, @serie_cmini char(10), @o1 char(30), @o2 char(30), @Continuare int, @ZileCMsusp int

	declare @utilizator varchar(20)
	SET @utilizator = dbo.fIaUtilizator('')

	declare concedii_medicale cursor for 
	select a.data,a.marca,isnull(i.Nume,p.Nume),isnull(i.Loc_de_munca,p.Loc_de_munca),c.denumire,a.Indemnizatia_zi, a.Tip_diagnostic, f.Denumire, 
		a.Data_inceput, a.Data_sfarsit, a.Procent_aplicat, day(a.data_sfarsit-a.data_inceput), 
		a.Zile_lucratoare, a.Zile_cu_reducere, a.Zile_lucratoare-a.Zile_cu_reducere, a.zile_luna_anterioara, a.Indemnizatie_unitate,
		(case when ((a.tip_diagnostic in ('2-','3-','4-')) or (a.tip_diagnostic in ('10','11') and a.suma=1)) then 0 else indemnizatie_CAS end), 
		(case when ((a.tip_diagnostic in ('2-','3-','4-')) or (a.tip_diagnostic in ('10','11') and a.suma=1)) then indemnizatie_CAS else 0 end), 
		(case when ((a.tip_diagnostic in ('2-','3-','4-')) or (a.tip_diagnostic in ('10','11') and a.suma=1)) then 0 else a.zile_lucratoare-a.zile_cu_reducere end),
		(case when ((a.tip_diagnostic in ('2-','3-','4-')) or (a.tip_diagnostic in ('10','11') and a.suma=1)) then a.zile_lucratoare-a.zile_cu_reducere else 0 end),
		(case when a.Zile_luna_anterioara=0 and isnull(e.Serie_certificat_CM_initial,'')='' or a.Tip_diagnostic='0-' then a.Data_inceput else 
		(select dbo.data_inceput_cm(@DataS, a.marca, a.Data_inceput, 1)) end), 
		(case when a.Zile_luna_anterioara=0 and isnull(e.Serie_certificat_CM_initial,'')='' then 'Initial' else 'Continuare' end),
		a.baza_calcul, p.vechime_totala, b.spor_cond_10, a.suma as data_risc, e.serie_certificat_cm_initial,
		(case when @ordonare='1' then (case when @alfabetic=1 then p.nume else a.marca end) 
			else (case when @ordonare='2' then a.tip_diagnostic else isnull(i.loc_de_munca,p.loc_de_munca) end) end) as ordonare1,
		(case when @alfabetic=1 then p.nume else a.marca end) as ordonare2
	from conmed a
		left outer join istpers i on a.Data=i.Data and a.Marca=i.Marca
		left outer join personal p on a.Marca=p.Marca
		left outer join infopers b on a.Marca=b.Marca
		left outer join lm c on isnull(i.Loc_de_munca,p.Loc_de_munca)=c.Cod
		left outer join infoconmed e on a.Data=e.Data and a.Marca=e.Marca and a.Data_inceput=e.Data_inceput
		left outer join dbo.fDiagnostic_CM() f on a.Tip_diagnostic=f.Tip_diagnostic
	where a.data between @DataJ and @DataS and (@MarcaJ='' or a.marca between @MarcaJ and @MarcaS)
		and (@cLocmJ='' or isnull(i.Loc_de_munca,p.Loc_de_munca) between @cLocmJ and @cLocmS) 
		and a.tip_diagnostic between @CodBoalaJos and @CodBoalaSus
		and (@lTipDiagnosticExceptie=0 or a.tip_diagnostic<>@cTipDiagnosticExceptat) 
		and (@lActivitate=0 or p.Activitate=@cActivitate) and (@lLocmStatie=0 or isnull(i.Loc_de_munca,p.Loc_de_munca) like  rtrim(@cLocmStatie)+'%')
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=isnull(i.Loc_de_munca,p.Loc_de_munca)))
	order by ordonare1, ordonare2, a.data

	open concedii_medicale
	fetch next from concedii_medicale into @Data, @Marca, @Nume, @Loc_de_munca, @Denlocm, @Medie_zilnica, @Cod_diagnostic, @Denumire_diagnostic, @Data_inceput, @Data_sfarsit, @Procent, 
		@Zile_calendaristice, @Zile_lucratoare, @Zile_unitate, @Zile_buget, @Zile_anterioare, @Indemnizatie_unitate, @Indemnizatie_FNUASS, @Indemnizatie_FAAMBP, @zile_platite_FNUASS, @zile_platite_FAMBP, 
		@Data_inceput_cm_initial,@Tip_concediu,@baza_calcul,@vechime,@spor10,@data_risc,@serie_cmini,@o1,@o2
	While @@fetch_status = 0 
	Begin
		Set @DataJPoz=dbo.bom(@Data)
		Set @datacmi=dbo.eom(@Data_inceput_cm_initial)	
		Set @Continuare=(case when @Zile_anterioare>0 or @serie_cmini<>'' then 1 else 0 end)
		Select @ZileCMsusp=Zile_CM_suspendare from dbo.fPSCalculZileCMSuspendare (@Marca,@DataJPoz,@Data)
		if @CMmm30Zile=0 or @ZileCMsusp>0
			insert @concedii_medicale 
			select @Data,@Marca,@Nume,@Loc_de_munca,@Denlocm,@Medie_zilnica,@Cod_diagnostic,@Denumire_diagnostic,
			@Data_inceput,@Data_sfarsit,@Procent,@Zile_calendaristice,@Zile_lucratoare,@Zile_unitate,@Zile_buget,@Zile_lucratoare,
			@Indemnizatie_unitate,@Indemnizatie_FNUASS,@Indemnizatie_FAAMBP,@zile_platite_FNUASS,@zile_platite_FAMBP,
			@Data_inceput_cm_initial,@baza_calcul,Baza_stagiu1,Baza_stagiu2,Baza_stagiu3,Baza_stagiu4,Baza_stagiu5,Baza_stagiu6,
			Baza_stagiu7,Baza_stagiu8,Baza_stagiu9,Baza_stagiu10,Baza_stagiu11,Baza_stagiu12,0,
			Zile_stagiu1,Zile_stagiu2,Zile_stagiu3,Zile_stagiu4,Zile_stagiu5,Zile_stagiu6,
			Zile_stagiu7,Zile_stagiu8,Zile_stagiu9,Zile_stagiu10,Zile_stagiu11,Zile_stagiu12,0,
			Zile_lucr1,Zile_lucr2,Zile_lucr3,Zile_lucr4,Zile_lucr5,Zile_lucr6,Zile_lucr7,
			Zile_lucr8,Zile_lucr9,Zile_lucr10,Zile_lucr11,Zile_lucr12, @Tip_concediu, @vechime, @spor10, @data_risc, @serie_cmini
			from dbo.stagiu_cm (@Data, @Marca, @Data_inceput, @Datacmi, @Continuare, @Luni_istoric) 

		fetch next from concedii_medicale into @Data, @Marca, @Nume, @Loc_de_munca, @DenLocm, @Medie_zilnica, @Cod_diagnostic, @Denumire_diagnostic, @Data_inceput, @Data_sfarsit, @Procent, 
			@Zile_calendaristice, @Zile_lucratoare, @Zile_unitate, @Zile_buget, @Zile_anterioare, @Indemnizatie_unitate, @Indemnizatie_FNUASS, @Indemnizatie_FAAMBP, @zile_platite_FNUASS, @zile_platite_FAMBP, 
			@Data_inceput_cm_initial, @Tip_concediu, @baza_calcul, @vechime, @spor10, @data_risc, @serie_cmini, @o1, @o2
	End
	update @concedii_medicale Set Baza_Stagiu=Baza1+Baza2+Baza3+Baza4+Baza5+Baza6,
		Zile_Stagiu=Z_st1+Z_st2+Z_st3+Z_st4+Z_st5+Z_st6
	close concedii_medicale
	Deallocate concedii_medicale

	return
end
