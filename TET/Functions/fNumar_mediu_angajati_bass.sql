--***
/**	functie numar mediu ang bass	*/
Create function fNumar_mediu_angajati_bass 
	(@dataJos datetime, @dataSus datetime)
Returns float
As
Begin
	Declare @utilizator varchar(20), @multiFirma int, @lista_lm int, @NumarMediu float, @OreSRN bit, @Ore100RN bit, @ORegieFaraOS2 int, @OreIntRN bit, @OreLuna float, @Somesana int, 
		@Pasmatex int, @Salubris int, @Colas int, @STOUG28 int, @PontajZilnic int

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	set @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	set @OreSRN = dbo.iauParL('PS','OSNRN')
	set @Ore100RN = dbo.iauParL('PS','O100NRN')
	set @ORegieFaraOS2 = dbo.iauParL('PS','OREG-FOS2')
	set @OreIntRN = dbo.iauParL('PS','OINTNRN')
	set @OreLuna = dbo.iauParLN(@DataSus,'PS','ORE_LUNA')
	set @Somesana = dbo.iauParL('SP','SOMESANA')
	set @Pasmatex = dbo.iauParL('SP','PASMATEX')
	set @Salubris = dbo.iauParL('SP','SALUBRIS')
	set @Colas = dbo.iauParL('SP','COLAS')
	set @STOUG28 = dbo.iauParLL(@DataSus,'PS','STOUG28')
	set @PontajZilnic = dbo.iauParL('PS','PONTZILN')
	set @NumarMediu = 0

	if year(@DataSus)>=2011
	Begin
		declare @tmpbass table (cnp varchar(13))
		insert into @tmpbass
		select p.Cod_numeric_personal
		from pontaj a 
			left outer join personal p on a.Marca=p.Marca
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
		where a.data between @DataJos and @DataSus and a.grupa_de_munca<>'O' 
			and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null)
			and (a.ore_regie+(case when @Somesana=1 then 0 else a.ore_acord end)
				-@OreSRN*(a.ore_suplimentare_1+(case when @ORegieFaraOS2=1 then 0 else a.ore_suplimentare_2 end)+a.ore_suplimentare_3+a.ore_suplimentare_4)
				-@Ore100RN*a.ore_spor_100+(case when @Pasmatex=0 then a.ore_intrerupere_tehnologica+(case when @STOUG28=1 then 0 else a.ore end) else 0 end)
				+a.ore_concediu_de_odihna+a.ore_concediu_medical+a.ore_obligatii_cetatenesti+(case when @Colas=1 then a.Spor_cond_8 else 0 end)
				+(case when @Salubris=1 then (a.ore_suplimentare_1+a.ore_suplimentare_2-a.ore_suplimentare_3+a.ore_suplimentare_4) else 0 end)<>0
			or a.Marca in (select Marca from brut where Data=@DataSus and VENIT_TOTAL<>0))

		/*	Am adaugat partea de mai jos pentru acele cazuri de salariati fara pozitii in pontaj dar cu pozitie in brut cu venit total<>0. 
			Si acei salariati (CNP-uri) trebuie luati in calcul la plafonare CAS */
		insert into @tmpbass
		select p.Cod_numeric_personal
		from brut a 
			left outer join personal p on a.Marca=p.Marca
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
		where a.data between @DataJos and @DataSus and p.grupa_de_munca<>'O' 
			and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null)
			and a.VENIT_TOTAL<>0 
			and not exists (select 1 from @tmpbass t where t.cnp=p.cod_numeric_personal)
		
		set @NumarMediu=isnull((select count(distinct cnp) from @tmpbass),0) 
	End
	else 
	Begin
		set @NumarMediu=round(isnull((select sum((case when a.ZileAsig>@OreLuna/8.00 then @OreLuna/8.00 else a.ZileAsig end))
		from (select p.Cod_numeric_personal, sum(round((a.ore_regie+(case when @Somesana=1 then 0 else a.ore_acord end)
			-@OreSRN*(a.ore_suplimentare_1+(case when @ORegieFaraOS2=1 then 0 else a.ore_suplimentare_2 end)+a.ore_suplimentare_3+a.ore_suplimentare_4)
			-@Ore100RN*a.ore_spor_100+(case when @Pasmatex=0 then a.ore_intrerupere_tehnologica+(case when @STOUG28=1 then 0 else a.ore end) else 0 end)
			+a.ore_concediu_de_odihna+a.ore_obligatii_cetatenesti+(case when @Colas=1 then a.Spor_cond_8 else 0 end)
			+(case when @Salubris=1 then (a.ore_suplimentare_1+a.ore_suplimentare_2-a.ore_suplimentare_3+a.ore_suplimentare_4) else 0 end))/a.regim_de_lucru,
			(case when @PontajZilnic=1 then 3 else 0 end))) as ZileAsig
		from pontaj a 
			left outer join personal p on a.Marca=p.Marca
		where a.data between @DataJos and @DataSus and a.grupa_de_munca<>'O' Group by p.Cod_numeric_personal) a),0)/convert(float,@OreLuna/8),2)
	End

	Return (@NumarMediu)
End
