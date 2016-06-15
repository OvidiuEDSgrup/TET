/** procedura pentru afisare date in Fisa individuala a salariatului **/
--***
Create procedure wIaFisaIndividuala @sesiune varchar(50), @parXML XML
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wIaFisaIndividualaSP')
begin 
	declare @returnValue int 
	exec @returnValue = wIaFisaIndividualaSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator varchar(10), @mesaj varchar(200), @marca varchar(6), @data datetime, @ImpozitTichete int, @DataTicJ datetime, @DataTicS datetime
---declare @parmarca int=108,@pardata datetime='2010-10-31'
begin try
	select
		@marca = isnull(@parXML.value('(/row/@marca)[1]','varchar(6)'),null),
		@data = isnull(@parXML.value('(/row/@data)[1]','datetime'),'1901-01-01')

	Set @ImpozitTichete=dbo.iauParLL(@data,'PS','DJIMPZTIC')
	Set @DataTicJ=dbo.iauParLD(@data,'PS','DJIMPZTIC')
	Set @DataTicS=dbo.iauParLD(@data,'PS','DSIMPZTIC')
	Set @DataTicJ=(case when @DataTicJ='01/01/1901' then @data else @DataTicJ end)
	Set @DataTicS=(case when @DataTicS='01/01/1901' then @data else @DataTicS end)
		
	if @marca is null 
	begin
		set @mesaj='Marca necompletata!'
		raiserror(@mesaj,11,1)
		return -1
	end
	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
		
	declare @lista_lm int
	set @lista_lm=dbo.f_arelmfiltru(@utilizator)

	select convert(char(10),i.data,101) as data, rtrim(i.Marca) as marca, rtrim(i.Nume) as densalariat, 
	rtrim(i.Cod_functie) as codfunctie, rtrim(i.loc_de_munca) as lmistpers, rtrim(i.Categoria_salarizare) as categsal, 
	rtrim(i.Tip_salarizare) as tipsalarizare, i.Grupa_de_munca as grupamunca,
	convert(decimal(12,2),i.Salar_de_incadrare) as salarincadrare, convert(decimal(8,2),i.Indemnizatia_de_conducere) as indcond, i.Mod_angajare as modangajare, 
	convert(char(1),p.Sex) as sex, convert(char(10),p.Data_nasterii,101) as datanasterii, p.Cod_numeric_personal as cnp,
	rtrim(p.Studii) as studii, rtrim(p.Profesia) as profesia, rtrim(p.Copii) as buletin,
	(case when rtrim(p.Strada)<>'' then 'Str. '+rtrim(p.Strada) else '' end)+(case when rtrim(p.Numar)<>'' then ' Nr. '+rtrim(p.Numar) else '' end)+ 
	(case when rtrim(p.Bloc)<>'' then ' Bl. '+rtrim(p.Bloc) else '' end)+(case when rtrim(p.Scara)<>'' then ' Sc. '+rtrim(p.Scara) else '' end)+
	(case when rtrim(p.Etaj)<>'' then ' Et. '+rtrim(p.Etaj) else '' end)+(case when rtrim(p.Apartament)<>''then ' Ap. '+rtrim(p.Apartament) else '' end)+
	(case when p.Sector<>0 then ' Sect. '+RTRIM(CONVERT(char(2),p.Sector)) else '' end)+(case when rtrim(p.Localitate)<>'' then ' Loc. '+rtrim(p.Localitate) else '' end)+
	(case when rtrim(p.Judet)<>'' then ' Jud. '+rtrim(p.Judet) else '' end) as adresa, 
	convert(int,p.Loc_ramas_vacant) as plecat, rtrim(p.Loc_de_munca) as lmpers, convert(decimal(10,3),p.Salar_orar) as salarorar, 
	p.Vechime_totala, p.Pensie_suplimentara as listaacces, convert(decimal(5,2),p.As_sanatate) as proccass,
	convert(decimal(8,6),isnull(po.Coeficient_acord,0)) as coef_acord,isnull(f.Denumire,'') as denfunctie, isnull(lm.Denumire,'') as denlm,
	convert(decimal(12,0),isnull(n1.VENIT_TOTAL,0)) as venittotal, convert(decimal(12,0),isnull(n1.VENIT_NET,0)) as salarnet, convert(decimal(12,0),isnull(n1.Impozit,0)) as impozit,
	convert(decimal(12,0),isnull(n1.Pensie_suplimentara_3,0)) as casindiv, convert(decimal(12,0),isnull(n1.Somaj_1,0)) as somajindiv, convert(decimal(12,0),isnull(n1.Asig_sanatate_din_net,0)) as cassindiv,
	convert(decimal(12,0),isnull(n1.CM_incasat,0)) as cmincasat, convert(decimal(12,0),isnull(n1.CO_incasat,0)) as coincasat, convert(decimal(12,2),isnull(n1.Debite_externe,0)) as debitexterne,
	convert(decimal(12,2),isnull(n1.Rate,0)) as rate, convert(decimal(12,2),isnull(n1.Debite_interne,0)) as debiteinterne, convert(decimal(12,0),isnull(n1.cont_curent,0)) as contcurent,
	convert(decimal(12,0),isnull(n1.suma_incasata,0)) as sumaincasata, convert(decimal(12,0),isnull(n1.suma_neimpozabila,0)) as sumaneimp, convert(decimal(12,0),isnull(n1.Avans,0)) as avans,
	convert(decimal(12,0),isnull(n1.Premiu_la_avans,0)) as premiulaavans, convert(decimal(12,0),isnull(n1.REST_DE_PLATA,0)) as restdeplata,
	convert(decimal(12,0),isnull(n1.VEN_NET_IN_IMP,0)) as venitnet, convert(decimal(12,0),isnull(n1.Ded_baza,0)) as dedbaza, convert(decimal(12,0),isnull(n1.VENIT_BAZA,0)) as bazaimpozit,
	convert(decimal(12,0),isnull(n2.Ded_baza,0)) as dedpensiefac, isnull(b.ore_lucrate,0) as orelucrate, convert(decimal(12,0),isnull(b.ind_normal,0)) as indregnormal,
	isnull(b.ore_regie,0) as oreregie, convert(decimal(12,0),isnull(b.realizat_regie,0)) as realizatregie, isnull(b.ore_acord,0) as oreacord,
	convert(decimal(12,0),isnull(b.realizat_acord,0)) as realizatacord, convert(decimal(12,0),isnull(b.Salar_categoria_lucrarii,0)) as salarcatlucr, isnull(b.ore_regim_normal,0) as oreregimnormal,
	convert(decimal(12,0),isnull(b.sp_peste_program,0)) as sppesteprogram, convert(decimal(12,0),isnull(b.sp_func_supl,0)) as spfuncsupl, convert(decimal(12,0),isnull(b.sp_specific,0)) as spspecific,
	convert(decimal(12,0),isnull(b.sp_cond1,0)) as spcond1, convert(decimal(12,0),isnull(b.sp_cond2,0)) as spcond2, convert(decimal(12,0),isnull(b.sp_cond3,0)) as spcond3,
	convert(decimal(12,0),isnull(b.sp_cond4,0)) as spcond4, convert(decimal(12,0),isnull(b.sp_cond5,0)) as spcond5, convert(decimal(12,0),isnull(b.sp_cond6,0)) as spcond6, 
	convert(decimal(12,0),isnull(b.sp_cond7,0)) as spcond7, convert(decimal(12,0),isnull(b.sp_cond8,0)) as spcond8, 
	convert(decimal(7,3),isnull(b.regim_lucru,0)) as regimlucru, convert(decimal(12,0),isnull(b.sp_vechime,0)) as spvechime,
	isnull(b.ore_supl1,0) as oresupl1, convert(decimal(12,0),isnull(b.ind_ore_supl1,0)) as indoresupl1, isnull(b.ore_supl2,0) as oresupl2, convert(decimal(12,0),isnull(b.ind_ore_supl2,0)) as indoresupl2,
	isnull(b.ore_supl3,0) as oresupl3, convert(decimal(12,0),isnull(b.ind_ore_supl3,0)) as indoresupl3, isnull(b.ore_supl4,0) as oresupl4, convert(decimal(12,0),isnull(b.ind_ore_supl4,0)) as indoresupl4,
	isnull(b.ore_noapte,0) as orenoapte, convert(decimal(12,0),isnull(b.ind_ore_noapte,0)) as indorenoapte, isnull(b.ore_spor100,0) as orespor100, convert(decimal(12,0),isnull(b.ind_ore_spor100,0)) as indorespor100,
	isnull(b.ore_intr_tehn,0) as oreintrtehn, convert(decimal(12,0),isnull(b.ind_ore_intr_tehn,0)) as indintrtehn, isnull(b.ore_obl_cet,0) as oreoblcet, convert(decimal(12,0),isnull(b.ind_ore_obl_cet,0)) as indoblcet,
	isnull(b.ore_CO,0) as oreco, convert(decimal(12,0),isnull(ind_ore_CO,0)) as indoreco, 
	isnull(b.ore_CM,0) as orecm, convert(decimal(12,0),isnull(b.ind_CM_unitate,0)) as indcmunitate, 
	convert(decimal(12,0),isnull(b.ind_CM_CAS,0)) as indcmfnuass, convert(decimal(12,0),isnull(b.CM_FAMBP,0)) as cmfaambp, 
	isnull(b.ore_invoiri,0) as ore_invoiri, isnull(b.Ore_nemotivate,0) as orenemotivate, isnull(b.ore_CFS,0) as orecfs, 
	convert(decimal(12,0),isnull(b.ind_conducere,0)) as indconducere,
	convert(decimal(12,0),isnull(b.total_lucrat,0)) as total_lucrat, convert(decimal(12,0),isnull(b.total_nelucrat,0)) as totalnelucrat, 
	convert(decimal(12,2),isnull(b.Restituiri,0)) as restituiri,
	convert(decimal(12,2),isnull(b.Diminuari,0)) as diminuari, convert(decimal(12,2),isnull(b.suma_impozabila,0)) as sumaimpozabila, convert(decimal(12,2),isnull(corectiaD,0)) as corectiaD,
	convert(decimal(12,2),isnull(b.premiu,0)) as premiu, convert(decimal(12,2),isnull(b.diurna,0)) as diurna, convert(decimal(12,2),isnull(b.cons_admin,0)) as consadmin, convert(decimal(12,2),isnull(b.procent_timp_lucrat,0)) as procenttimplucrat,
	convert(decimal(12,2),isnull(b.suma_imp_sep,0)) as sumaimpsep, isnull(b.ore_suplimentare,0) as oresuplimentare, convert(decimal(12,2),isnull(b.total_spor,0)) as totalspor,
	convert(decimal(12,2),isnull(b.total_spor,0)+isnull(b.dif_brut,0)+isnull(n1.suma_neimpozabila,0)) as totalspordif,
	convert(decimal(12,2),isnull(n1.CAS+n2.CAS,0)) as casunit, convert(decimal(12,2),isnull(n1.Asig_sanatate_pl_unitate,0)) as cassunit,
	convert(decimal(12,2),isnull(n1.Somaj_5,0)) as somajunit, convert(decimal(12,2),isnull(n2.Somaj_5,0)) as fondgarantare, 
	convert(decimal(12,2),isnull(n1.Ded_suplim,0)) as cci, convert(decimal(12,2),n1.Fond_de_risc_1) as accmunca,
	convert(decimal(12,2),isnull(t.Valoare_tichete,0)) as valtichete,
	convert(decimal(12,2),isnull(t.Numar_tichete,0)) as nrtichete,
	convert(decimal(12,2),isnull(n1.VENIT_NET,0)-isnull(b.ind_CM_CAS+b.CM_FAMBP,0)
	+isnull(n1.Pensie_suplimentara_3+n1.Somaj_1+n1.Asig_sanatate_din_net+n1.Impozit
	+n1.CAS+n2.CAS+n1.Asig_sanatate_pl_unitate+n1.Somaj_5+n2.Somaj_5+n1.Ded_suplim+n1.Fond_de_risc_1,0)
	+isnull(t.Valoare_tichete,0)) as totalchelt
	from istpers i
		left outer join personal p on p.Marca=i.Marca
		left outer join pontaj po on po.Marca=i.Marca and po.Data=i.Data
		left outer join functii f on f.Cod_functie=i.Cod_functie
		left outer join lm on lm.Cod=i.Loc_de_munca
		left outer join net n1 on n1.marca=i.Marca and n1.Data=i.Data
		left outer join net n2 on n2.marca=i.Marca and n2.Data=dbo.bom(i.Data)
		left outer join fNC_tichete (@DataTicJ, @DataTicS, '', 1) t on @ImpozitTichete=1 and t.Marca=i.Marca
		left outer join (select marca,data, sum(total_ore_lucrate) as ore_lucrate, sum(Ind_regim_normal) as ind_normal,
			sum(Ore_lucrate__regie) as ore_regie, sum(realizat__regie) as realizat_regie, sum(Ore_lucrate_acord) as ore_acord,
			sum(realizat_acord) as realizat_acord, sum(Salar_categoria_lucrarii) as Salar_categoria_lucrarii, sum(Ore_lucrate_regim_normal) as ore_regim_normal,
			sum(Spor_sistematic_peste_program) as sp_peste_program,sum(Spor_de_functie_suplimentara) as sp_func_supl,
			sum(Spor_specific) as sp_specific, sum(Spor_cond_1) as sp_cond1, sum(Spor_cond_2) as sp_cond2, sum(Spor_cond_3) as sp_cond3,
			sum(Spor_cond_4) as sp_cond4, sum(Spor_cond_5) as sp_cond5, sum(Spor_cond_6) as sp_cond6, sum(Spor_cond_7) as sp_cond7,
			sum(Spor_cond_8) as sp_cond8, sum(Spor_cond_9) as CM_FAMBP, max(Spor_cond_10) as regim_lucru, sum(Spor_vechime) as sp_vechime,
			sum(Ore_suplimentare_1) as ore_supl1, sum(Indemnizatie_ore_supl_1) as ind_ore_supl1,
			sum(Ore_suplimentare_2) as ore_supl2, sum(Indemnizatie_ore_supl_2) as ind_ore_supl2,
			sum(Ore_suplimentare_3) as ore_supl3, sum(Indemnizatie_ore_supl_3) as ind_ore_supl3,
			sum(Ore_suplimentare_4) as ore_supl4, sum(Indemnizatie_ore_supl_4) as ind_ore_supl4,
			sum(Ore_de_noapte) as ore_noapte, sum(Ind_ore_de_noapte) as ind_ore_noapte,
			sum(Ore_spor_100) as ore_spor100, sum(Indemnizatie_ore_spor_100) as ind_ore_spor100,
			sum(Ore_intrerupere_tehnologica) as ore_intr_tehn, sum(Ind_intrerupere_tehnologica+Ind_invoiri) as ind_ore_intr_tehn,
			sum(Ore_obligatii_cetatenesti) as ore_obl_cet, sum(Ind_obligatii_cetatenesti) as ind_ore_obl_cet,
			sum(Ore_concediu_de_odihna) as ore_CO, sum(Ind_concediu_de_odihna) as ind_ore_CO,
			sum(Ore_concediu_medical) as ore_CM, sum(Ind_c_medical_unitate) as ind_CM_unitate, sum(Ind_c_medical_CAS) as ind_CM_CAS,
			sum(Ore_invoiri) as ore_invoiri, sum(Ore_nemotivate) as ore_nemotivate, sum(Ore_concediu_fara_salar) as ore_CFS,sum(Ind_nemotivate) as ind_conducere,
			sum(Realizat__regie+Realizat_acord+Indemnizatie_ore_supl_1+Indemnizatie_ore_supl_2+Indemnizatie_ore_supl_3+Indemnizatie_ore_supl_4+Ind_ore_de_noapte+sp_salar_realizat+Salar_categoria_lucrarii+Indemnizatie_ore_spor_100) as total_lucrat,
			sum(Ind_c_medical_unitate+Ind_c_medical_CAS+Ind_concediu_de_odihna+Ind_intrerupere_tehnologica+Spor_cond_9+Ind_invoiri+Ind_obligatii_cetatenesti) as total_nelucrat,
			sum(Restituiri) as restituiri, sum(Diminuari) as diminuari, sum(suma_impozabila) as suma_impozabila,
			sum(CO) as corectiaD, sum(premiu) as premiu, sum(Diurna) as diurna, sum(cons_admin) as cons_admin,
			sum(sp_salar_realizat) as procent_timp_lucrat, sum(suma_imp_separat+suma_imp_separat) as suma_imp_sep,
			sum(Ore_suplimentare_4+Ore_suplimentare_3+Ore_suplimentare_2+Ore_suplimentare_1+Ore_de_noapte) as ore_suplimentare,
			sum(Spor_cond_1+Spor_cond_2+Spor_cond_3+Spor_cond_4+Spor_cond_5+Spor_cond_6+Spor_cond_7+Spor_cond_8+Spor_vechime+Spor_de_functie_suplimentara+Spor_sistematic_peste_program+Spor_specific) as total_spor,
			sum(Restituiri+Diminuari+premiu+CO+suma_impozabila+Diurna+cons_admin+Ind_nemotivate) as dif_brut
			from brut where data=@data group by data,marca) b on b.data=i.Data and b.marca=i.marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and i.loc_de_munca=lu.cod
	where i.Marca=@marca and i.data=@data and (@lista_lm=0 or lu.cod is not null) 
	for xml raw
end try

begin catch
	set @mesaj = '(wIaFisaIndividuala)'+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
