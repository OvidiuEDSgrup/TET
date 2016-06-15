--***
/**	functie pt. tichete de masa	*/
Create function fTichete_de_masa 
	(@dataJos datetime, @dataSus datetime, @marca char(6)=null, @tiplista char(30)='', @ordonare char(1)='1', @centralizat_nivel int=0, @lungime_nivel int=0, 
	@tipoperatie char(1)=null, @locm char(9)=null, @strict int=0, @mandatar char(6)=null, @tipstat char(200)=null, @listaDrept char(1)='T', 
	@serieinceput char(13)=null, @seriesfarsit char(13)=null, @Serii int=0) 
returns @tichete_de_masa table
	(Data datetime, Marca char(6), Nume char(50), CNP char(13), Loc_de_munca char(9), Denumire_lm char(30), Cod_functie char(6), Denumire_functie char(30), 
	Tip_operatie char(1), Serie_inceput char(13), Serie_sfarsit char(13), Nr_tichete float, Valoare_unitara_tichet float, Valoare_imprimat float, TVA_imprimat float, 
	Valoare_tichete float, Impozit float, Zile_lucrate int, Nr_tichete_pontaj int, 
	Mandatar char(6), Nume_mandatar char(50), Ordonare_mandatar char(50), Ordonare_locm char(50), Ordonare char(50), Zile_delegatie int)
as
/*	Exemplu de apel
	declare @dataJos datetime, @dataSus datetime, @marca varchar(6), @tiplista varchar(30), @ordonare char(1), @centralizat_nivel int, @lungime_nivel int, 
		@tipoperatie char(1), @locm varchar(9), @strict varchar(20), @mandatar char(6), @tipstat char(200), @listaDrept char(1), @serieinceput char(13), @seriesfarsit char(13), @Serii int
	select @dataJos='11/01/2014', @dataSus='11/30/2014', @marca='1018', @tiplista='Tip operatie', @ordonare='1', @centralizat_nivel=0, @lungime_nivel=0, 
		@tipoperatie=null, @locm=null, @strict=0, @mandatar=null, @tipstat=null, @listaDrept='T', @serieinceput=null, @seriesfarsit=null, @Serii=0
	select * from dbo.fTichete_de_masa (@datajos, @datasus, @marca, @tiplista, @ordonare, @centralizat_nivel, @lungime_nivel, @tipoperatie, @locm, @strict, @mandatar, @tipstat, 'T', 
		@serieinceput, @seriesfarsit, @serii)
*/
begin
	declare @userASiS char(10), @dreptConducere int, @OreS_RN int, @Ore100_RN int, @ORegieFaraOS2 int, @ore_int_rn int, @aredreptcond int, @lista_drept char(1), 
	@ticheteMacheta int, @TichetePersonalizate int, @tabelaNCtichete char(2), @ParcurgTichete int, @Dafora int, @Remarul int

	set @userASiS=dbo.fIaUtilizator(null)
	set @dreptConducere=dbo.iauParL('PS','DREPTCOND')
	set @OreS_RN = dbo.iauParL('PS','OSNRN')
	set @Ore100_RN = dbo.iauParL('PS','O100NRN')
	set @ORegieFaraOS2 = dbo.iauParL('PS','OREG-FOS2')
	set @ore_int_rn = dbo.iauParL('PS','OINTNRN')
	set @ticheteMacheta = dbo.iauParL('PS','OPTICHINM')
	set @TichetePersonalizate=dbo.iauParL('PS','TICHPERS')
	set @tabelaNCtichete=(case when len(rtrim(convert(char(2),dbo.iauParN('PS','NC-TICHM'))))>1 then right(rtrim(convert(char(2),dbo.iauParN('PS','NC-TICHM'))),1) else '1' end)
	set @ParcurgTichete=(case when @ticheteMacheta=1 or @tabelaNCtichete='2' then 1 else 0 end)
	set @Dafora = dbo.iauParL('SP','DAFORA')
	set @Remarul=dbo.iauParL('SP','REMARUL')

--	verific daca utilizatorul are/nu are dreptul de Salarii conducere (SALCOND)
	set @lista_drept=@listaDrept
	set @areDreptCond=0
	if  @dreptConducere=1 
	begin
		set @areDreptCond=isnull((select dbo.verificDreptUtilizator(@userASiS,'SALCOND')),0)
		if @areDreptCond=0
			set @lista_drept='S'
	end
	set @tipoperatie=nullif(@tipoperatie,'T')

	declare @pontaj table (Data datetime, Marca char(6), Zile_lucrate int, Ore_lucrate int, Zile_delegatie int, Nr_tichete_pontaj int)
	insert into @pontaj 
	select dbo.EOM(data) as Data, Marca, 
		round(sum(Ore__cond_6),0) as Zile_lucrate, round(sum(Ore_lucrate),0) as Ore_lucrate, 
		round(sum(Spor_cond_10/regim_de_lucru),0) as Zile_delegatie,
		round(sum((ore_lucrate-(case when @OreS_RN=1 then Ore_suplimentare_1+(case when @ORegieFaraOS2=1 then 0 else Ore_suplimentare_2 end)+Ore_suplimentare_3+Ore_suplimentare_4 else 0 end)
			-(case when @Ore100_RN=1 then Ore_spor_100 else 0 end)-Spor_cond_10)/regim_de_lucru),0) as Nr_tichete_pontaj
	from pontaj 
	where data between @dataJos and @dataSus 
	group by dbo.EOM(data), Marca

	insert into @tichete_de_masa
	select a.Data_lunii, a.Marca, max(isnull(i.Nume,p.Nume)) as Nume, max(p.Cod_numeric_personal) as Cod_numeric_personal, 
		max(isnull(i.Loc_de_munca,p.Loc_de_munca)) as Loc_de_munca, max(lm.Denumire) as denumire_lm, max(isnull(i.Cod_functie,p.Cod_functie)) as cod_functie, max(f.Denumire) as denumire_functie,
		(case when @tipoperatie is null and @tiplista not in ('Balanta','Tip operatie') then 'T' else max(a.Tip_operatie) end) as tip_operatie, 
		(case when @Serii=1 or @tiplista='Balanta' then a.Serie_inceput else '' end), max(a.Serie_sfarsit), 
		sum(a.Nr_tichete) as Nr_tichete, sum(a.Valoare_tichet) as Valoare_tichet, sum(a.Valoare_imprimat) as Valoare_imprimat, sum(a.TVA_imprimat) as TVA_imprimat, 
		sum((case when @tiplista<>'' and @tiplista<>'Tip operatie' and a.tip_operatie in ('R','C') then -1 else 1 end)*a.Nr_tichete*a.Valoare_tichet) as Valoare_tichete, 0 as impozit, 
		max(isnull(po.Zile_lucrate,0)) as Zile_lucrate, max(isnull(po.Nr_tichete_pontaj,0)) as Nr_tichete_pontaj, 
		max(isnull(m.Mandatar,'')), max(isnull(p1.Nume,'')), (case when @Ordonare='4' then max(m.Mandatar) else '' end) as Ordonare_mandatar,
		(case when @Ordonare in ('3'/*,'4'*/) then '' else 
		max((case when @centralizat_nivel=1 then (case when @Dafora=1 and left(isnull(i.Loc_de_munca,p.Loc_de_munca),3)='101' then left(isnull(i.Loc_de_munca,p.Loc_de_munca),5) 
			else left(isnull(i.Loc_de_munca,p.Loc_de_munca),@Lungime_nivel) end) else isnull(i.Loc_de_munca,p.Loc_de_munca) end)) end) as Ordonare_locm,
		(case when @ordonare in ('1'/*,'4'*/) then a.Marca else max(isnull(i.Nume,p.Nume)) end) as Ordonare, 
		max(isnull(po.Zile_delegatie,0)) as Zile_delegatie
	from tichete a
		left outer join personal p on a.Marca=p.Marca
		left outer join istpers i on a.Data_lunii=i.Data and a.Marca=i.Marca
		left outer join @pontaj po on po.Data=a.Data_lunii and po.Marca=a.Marca
		left outer join infopers b on a.Marca=b.Marca
		left outer join lm on lm.Cod=isnull(i.Loc_de_munca,p.Loc_de_munca)
		left outer join mandatar m on m.loc_munca=isnull(i.Loc_de_munca,p.Loc_de_munca)
		left outer join personal p1 on m.Mandatar=p1.Marca
		left outer join functii f on isnull(i.Cod_functie,p.Cod_functie)=f.Cod_functie
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=isnull(i.Loc_de_munca,p.Loc_de_munca)
	where @ParcurgTichete=1
		and (@marca is null or a.marca=@marca) and a.data_lunii between @dataJos and @dataSus 
		and (@TichetePersonalizate=1 and (tip_operatie in ('C','S','R') or @Remarul=0 and tip_operatie in ('P','X'))
			or @TichetePersonalizate=0 and (tip_operatie in ('P','S','X') 
				or @TicheteMacheta=1 and tip_operatie='C' 
					and (@tipoperatie='C' or not exists (select 1 from tichete b where b.Data_lunii=a.data_lunii and b.Marca=a.Marca and b.Tip_operatie='P' and b.Serie_inceput<>'' and b.Serie_sfarsit<>'')) 
				or tip_operatie='R' and valoare_tichet<>0))
		and (@tipoperatie is null or a.tip_operatie=@tipoperatie)
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
		and (@locm is null or isnull(i.Loc_de_munca,p.Loc_de_munca) like rtrim(@locm)+(case when @strict=1 then '' else '%' end)) 
		and (@mandatar is null or m.mandatar=@mandatar) and (@tipstat is null or b.religia=@tipstat) 
		and (@dreptConducere=0 or (@aredreptcond=1 and (@lista_drept='T' or @lista_drept='C' and p.pensie_suplimentara=1 
			or @lista_drept='S' and p.pensie_suplimentara<>1)) or (@aredreptcond=0 and p.pensie_suplimentara<>1))
	group by a.Data_lunii, a.Marca, (case when @Serii=1 or @tiplista='Balanta' then a.Serie_inceput else '' end), (case when @tiplista='Tip operatie' then a.tip_operatie else '' end)
	union all 
	select dbo.eom(a.data) as data, a.Marca, max(isnull(i.Nume,p.Nume)) as nume, max(p.Cod_numeric_personal) as cnp, max(isnull(i.Loc_de_munca,p.Loc_de_munca)), 
		max(lm.Denumire) as den_lm, max(isnull(i.Cod_functie,p.Cod_functie)) as cod_functie, max(f.Denumire) as den_functie,
		'', '', '', sum(a.Ore__cond_6) as Nr_tichete, dbo.iauParLN(dbo.eom(a.data),'PS','VALTICHET'), 0, 0, 
		sum(a.Ore__cond_6)*dbo.iauParLN(dbo.eom(a.data),'PS','VALTICHET'), 0 as impozit, 
		round(sum(Ore_lucrate/regim_de_lucru),0) as Zile_lucrate, 
		round(sum((ore_lucrate-(case when @OreS_RN=1 then Ore_suplimentare_1+(case when @ORegieFaraOS2=1 then 0 else Ore_suplimentare_2 end)+Ore_suplimentare_3+Ore_suplimentare_4 else 0 end)
			-(case when @Ore100_RN=1 then Ore_spor_100 else 0 end))/regim_de_lucru),0) as Nr_tichete_pontaj, 
		max(isnull(m.Mandatar,'')) as mandatar, max(isnull(p1.Nume,'')) as nume_mandatar, (case when @Ordonare='4' then max(m.Mandatar) else '' end) as Ordonare_mandatar,
		max((case when @Ordonare in ('3'/*,'4'*/) then '' else 
		(case when @centralizat_nivel=1 then (case when @Dafora=1 and left(isnull(i.Loc_de_munca,p.Loc_de_munca),3)='101' then left(isnull(i.Loc_de_munca,p.Loc_de_munca),5) 
				else left(isnull(i.Loc_de_munca,p.Loc_de_munca),@Lungime_nivel) end) 
			else isnull(i.Loc_de_munca,p.Loc_de_munca) end) end)) as Ordonare_locm,
		(case when @ordonare in ('1'/*,'4'*/) then a.Marca else max(isnull(i.Nume,p.Nume)) end) as Ordonare, 
		round(sum(a.Spor_cond_10),0) as Zile_delegatie
	from pontaj a
		left outer join personal p on a.Marca=p.Marca
		left outer join istpers i on dbo.eom(a.Data)=i.Data and a.Marca=i.Marca
		left outer join infopers b on a.Marca=b.Marca
		left outer join lm on isnull(i.Loc_de_munca,p.Loc_de_munca)=lm.Cod
		left outer join mandatar m on m.loc_munca=isnull(i.Loc_de_munca,p.Loc_de_munca)
		left outer join personal p1 on m.Mandatar=p1.Marca
		left outer join functii f on f.Cod_functie=isnull(i.Cod_functie,p.Cod_functie)
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=isnull(i.Loc_de_munca,p.Loc_de_munca)
	where @ParcurgTichete=0
		and (@marca is null or a.marca=@marca) and a.data between @dataJos and @dataSus 
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
		and (@locm is null or isnull(i.Loc_de_munca,p.Loc_de_munca) like rtrim(@locm)+(case when @strict=1 then '' else '%' end)) 
		and (@mandatar is null or m.mandatar=@mandatar) and (@tipstat is null or b.religia=@tipstat) 
		and (@dreptConducere=0 or (@aredreptcond=1 and (@lista_drept='T' or @lista_drept='C' and p.pensie_suplimentara=1 
			or @lista_drept='S' and p.pensie_suplimentara<>1)) or (@aredreptcond=0 and p.pensie_suplimentara<>1))
	group by dbo.eom(a.data), a.marca		
	order by Ordonare_mandatar, Ordonare_locm, Ordonare

	update @tichete_de_masa set Impozit=dbo.fCalcul_impozit_salarii(Valoare_tichete,0,0)

	return
end
