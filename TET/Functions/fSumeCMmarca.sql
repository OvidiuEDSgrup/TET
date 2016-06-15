--***
/**	functie pt. sume concedii medicale centralizate pe marca */
Create function fSumeCMmarca 
	(@dataJos datetime, @dataSus datetime, @pMarca char(6))
returns @SumeCMmarca table
	(Data datetime, Marca char(6), indcm_unit_19 float, indcm_cas_19 float, 
	ore_luna_cm float, indcm float, indcm_cas_18 float, zcm_18 int, zcm_18_ant int, baza_casi_ant float, baza_cascm_ant float, 
	zcm_2341011 int, indcm_234 float, indcm_unit_234 float, zcm15 int, zcm_8915 int, indcm_8915 float, zcm_78 int, indcm_78 float, 
	indcm_somaj float, ingrijire_copil_sarcina int, zcm_unitate int, zcm_fonduri int)
As
Begin
	declare @utilizator varchar(20), @multiFirma int, @lista_lm int, @Salar_minim float, @Salar_mediu float, @HostID char(8)

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	set @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1
	
	set @Salar_minim=dbo.iauParLN(@dataSus,'PS','S-MIN-BR')
	set @Salar_mediu=dbo.iauParLN(@dataSus,'PS','SALMBRUT')
	set @HostID=(select convert(char(8), abs(convert(int, host_id()))))
	
	insert into @SumeCMmarca
	select a.data as data, a.marca, sum(indemnizatie_unitate) as indcm_unit_19, sum(indemnizatie_cas) as indcm_cas_19, 
	max(zile_lucratoare_in_luna*8) as ore_luna_cm, sum(indemnizatie_unitate+indemnizatie_cas) as indcm,
	sum((case when tip_diagnostic<>'0-' then indemnizatie_cas else 0 end)) as indcm_cas_18, 
	sum((case when tip_diagnostic<>'0-' and not(tip_diagnostic='2-' or tip_diagnostic='3-' or tip_diagnostic='4-' or 
	(tip_diagnostic='10' or tip_diagnostic='11') and suma=1) and tip_diagnostic<>'15' then zile_lucratoare else 0 end)) as zcm_18, 
	sum((case when tip_diagnostic<>'0-' and not(tip_diagnostic='2-' or tip_diagnostic='3-' or tip_diagnostic='4-' or 
	(tip_diagnostic='10' or tip_diagnostic='11') and suma=1) and tip_diagnostic<>'15' and data_inceput<@dataJos then zile_lucratoare else 0 end)) as zcm_18_ant, 
	sum((case when tip_diagnostic<>'0-' and not(tip_diagnostic='2-' or tip_diagnostic='3-' or tip_diagnostic='4-' or 
	(tip_diagnostic='10' or tip_diagnostic='11') and suma=1) and data_inceput<@dataJos then 
	round(zile_lucratoare*(case when data_inceput<@dataJos then isnull(l.val_numerica,@Salar_minim) else @Salar_minim end)/convert(float,zile_lucratoare_in_luna),0) else 0 end)) as baza_casi_ant,
	sum((case when tip_diagnostic<>'0-' and not(tip_diagnostic='2-' or tip_diagnostic='3-' or tip_diagnostic='4-' or 
	(tip_diagnostic='10' or tip_diagnostic='11') and suma=1) and data_inceput<@dataJos then 
	round(zile_lucratoare*(case when data_inceput<@dataJos then isnull(l.val_numerica,@Salar_minim) else @Salar_minim end)/convert(float,zile_lucratoare_in_luna),0) else 0 end)) as baza_cascm_ant,
	sum((case when tip_diagnostic in ('2-','3-','4-') or tip_diagnostic in ('10','11') and suma=1 then zile_lucratoare else 0 end)) as zcm_2341011, 
	sum((case when tip_diagnostic in ('2-','3-','4-') then (case when a.data>='08/01/2008' then 0 else indemnizatie_unitate end) + indemnizatie_cas else 0 end)) as indcm_234, 
	sum((case when tip_diagnostic in ('2-','3-','4-') then indemnizatie_unitate else 0 end)) as indcm_unit_234, 
	sum((case when tip_diagnostic in ('15') then zile_lucratoare else 0 end)) as zcm15, 
	sum((case when tip_diagnostic in ('8-','9-','15') then zile_lucratoare else 0 end)) as zcm_8915, 
	sum((case when tip_diagnostic in ('8-','9-','15') then indemnizatie_cas else 0 end)) as indcm_8915, 
	sum((case when tip_diagnostic in ('7-','8-') then zile_lucratoare else 0 end)) as zcm_78,
	sum((case when tip_diagnostic in ('7-','8-') then indemnizatie_cas else 0 end)) as indcm_78, 
	sum((case when tip_diagnostic not in ('7-','8-') then indemnizatie_cas else 0 end)) as indcm_somaj, 
	isnull((select count(1) from conmed c where c.data=a.data and c.marca=a.marca and c.tip_diagnostic in ('0-','7-','8-')),0) as ingrijire_copil_sarcina,
	sum((case when tip_diagnostic<>'0-' then Zile_cu_reducere else 0 end)) as zcm_unitate,
	sum((case when tip_diagnostic<>'0-' then Zile_lucratoare-Zile_cu_reducere else 0 end)) as zcm_fonduri
	from conmed a
		left outer join par_lunari l on l.data=dbo.eom(a.data_inceput) and l.tip='PS' and l.parametru='S-MIN-BR'
		left outer join personal p on a.Marca=p.Marca
		left outer join istPers i on a.Data=i.Data and a.Marca=i.Marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=isnull(i.Loc_de_munca,p.loc_de_munca)
	where a.data between @dataJos and @dataSus and (@pMarca='' or a.marca=@pMarca)
		and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null)
	group by a.data, a.marca

	return
End

/*
select * from fSumeCMmarca ('02/01/2011','02/28/2011','')
*/
