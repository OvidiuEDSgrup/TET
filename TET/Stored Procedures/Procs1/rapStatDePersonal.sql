--***
/**	procedura pt. stat de personal 
	grupare = 1 -> Salariati
	grupare = 2 -> Functii, Salariati
	grupare = 3 -> Locuri de munca, Salariati
*/
Create procedure rapStatDePersonal
	(@data datetime, @marca char(6)=null, @locm char(9)=null, @strict int=0, @functie char(6)=null, @grupaMunca char(1), @tipPersonal char(1)='A', 
	@tipStat varchar(30), @listaDrept char(1), @grupare char(1), @alfabetic int, @posturivacante int=0, @salariatiactivi int=0)
as
declare @eroare varchar(2000)
begin try
	set transaction isolation level read uncommitted
	if object_id('tempdb..#statpers') is not null drop table #statpers
	if object_id('tempdb..#lm') is not null drop table #lm
	if object_id('tempdb..#tmpPers') is not null drop table #tmpPers
	if object_id('tempdb..#posturivacante') is not null drop table #posturivacante
	if object_id('tempdb..#functii_lm') is not null drop table #functii_lm
		
	declare @dataJos datetime, @dataSus datetime, @utilizator varchar(20),  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	@lunaInch int, @anulInch int, @dataInch datetime, @OreLuna int, @NrMediuOre float, @dreptConducere int, @liste_drept char(1), @areDreptCond int, @bugetari int, @regimVariabil int, 
	@lindc_suma int, @lspf_supl_suma int, @lspec_suma int, @lspc1_suma int, @lspc2_suma int, @lspc3_suma int, @lspc4_suma int, @lspc5_suma int, @lspc6_suma int, @i int 

	set @dataJos=dbo.BOM(@data)
	set @dataSus=dbo.EOM(@data)	
	set @utilizator = dbo.fIaUtilizator(null)
	set @lunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @anulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	set @dataInch=dbo.eom(convert(datetime,str(@lunaInch,2)+'/01/'+str(@anulInch,4)))

	Set @OreLuna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
	Set @NrMediuOre=dbo.iauParLN(@dataSus,'PS','NRMEDOL')
	Set @dreptConducere=dbo.iauParL('PS','DREPTCOND')
	Set @bugetari=dbo.iauParL('PS','UNITBUGET')
	Set @regimVariabil=dbo.iauParL('PS','REGIMLV')
	Set @lindc_suma=dbo.iauParL('PS','INDC-SUMA')
	Set @lspf_supl_suma=dbo.iauParL('PS','SPFS-SUMA')
	Set @lspec_suma=dbo.iauParL('PS','SSP-SUMA')
	Set @lspc1_suma=dbo.iauParL('PS','SC1-SUMA')
	Set @lspc2_suma=dbo.iauParL('PS','SC2-SUMA')
	Set @lspc3_suma=dbo.iauParL('PS','SC3-SUMA')
	Set @lspc4_suma=dbo.iauParL('PS','SC4-SUMA')
	Set @lspc5_suma=dbo.iauParL('PS','SC5-SUMA')
	Set @lspc6_suma=dbo.iauParL('PS','SC6-SUMA')

--	verific daca utilizatorul are/nu are dreptul de Salarii conducere (SALCOND)
	set @liste_drept=@listaDrept
	set @areDreptCond=0
	if  @dreptConducere=1 
	begin
		set @areDreptCond=isnull((select dbo.verificDreptUtilizator(@utilizator,'SALCOND')),0)
		if @areDreptCond=0
			set @liste_drept='S'
	end

--	apelez scrierea in istoric pesonal (din istpers se iau datele pt. raport - cu avantaj in cazul modificarilor de salar operate pe CTRL+D)
	if isnull((select type from sysobjects where name='istPers'),'')='U' and (not exists (select 1 from istPers where Data=@dataSus) or 1=1)
		if @dataJos>@dataInch
		begin
			declare @vmarca char(6), @vlocm char(9)
			select @vmarca=isnull(@marca,''), @vlocm=isnull(@locm,'')
			exec scriuistPers @dataJos, @dataSus, @vmarca, @vlocm, 1, 1, 0, 0, @dataSus
		end	

--	selectez din functii_lm pozitiile valabile la data generarii raportului
	select * into #functii_lm from 
	(select Data, Loc_de_munca, Cod_functie, Tip_personal, Salar_de_incadrare, Numar_posturi, (case when Regim_de_lucru=0 then 8 else Regim_de_lucru end) as regim_de_lucru, 
		Pozitie_stat, RANK() over (partition by Loc_de_munca, Cod_functie order by Data Desc) as ordine
	from functii_lm f 
	where Data<=@DataSus and (@locm is null or Loc_de_munca like rtrim(@locm)+(case when @strict=0 then '%' else '' end)) 
		and (@functie is null or Cod_functie=@functie) and (@tipPersonal='A' or Tip_personal=@tipPersonal)
		and not exists (select 1 from ValidCat v where v.Tip='LM' and v.Cod=f.Loc_de_munca and @data between v.Data_jos and v.Data_sus)) a
	where Ordine=1

--	Pun datele in tabela temporara pt. a face cateva operatii ulterioare
	select i.Data, i.Marca, i.Nume, i.cod_functie, f.Denumire as denumire_functie, i.loc_de_munca, lm.denumire as denumire_lm, lm.nivel+1 as niv, 
	(case when isnull(s.Temei_legal,'')<>'' then 0 else i.Salar_de_incadrare end) as salar_de_incadrare, 
	(case when isnull(s.Temei_legal,'')<>'' and s.Data_inceput<=@data and s.Data_sfarsit>=@data then 'Suspendat' when isnull(i2.Motiv,'')<>'' then i2.Motiv else '' end) as observatii, 
	isnull(i1.Marca_inlocuitoare,'') as marca_inlocuitoare, 
	0 as numar_curent, 0 as numar_curent_ordonare, fl.Numar_posturi as numar_posturi, 1 as numar_salariati, isnull(fl.Pozitie_stat,0) as pozitie_stat, 
	(case when i.Salar_lunar_de_baza<>0 and @regimVariabil=0 then i.Salar_lunar_de_baza else 8 end) as regim_de_lucru, 
	(case when DateDiff(month,@dataInch,@dataSus)>1 then sc.Spor_vechime else i.Spor_vechime end) as spor_vechime, 
	(case when DateDiff(month,@dataInch,@dataSus)>1 then sc.Spor_specific else i.Spor_specific end) as spor_specific, 
	space(100) as ordonare1, 0 as ordonare2, space(100) as ordonare3 
	into #tmpPers
	from istpers i 
		left outer join personal p on p.Marca=i.Marca
		left outer join infopers e on e.marca=p.marca
		left outer join functii f on f.cod_functie=i.cod_functie
		left outer join lm on lm.cod=isnull(i.loc_de_munca,p.loc_de_munca)
		left outer join dbo.fRevisalSuspendari (@dataJos, @data, '') s on s.Marca=p.Marca
		left outer join dbo.fSalariatiInlocuitori (@dataJos, @dataSus, '') i1 on i1.Marca=p.Marca and i1.Data_inceput<=@data and i1.Data_sfarsit>=@data
		left outer join dbo.fSalariatiInlocuitori (@dataJos, @dataSus, '') i2 on i2.Marca_inlocuitoare=p.Marca and i2.Data_inceput<=@data and i2.Data_sfarsit>=@data
		left outer join #functii_lm fl on fl.Cod_functie=i.cod_functie and fl.Loc_de_munca=i.Loc_de_munca
		left outer join fCalculVechimeSporuri (@dataJos, @dataSus, '', 0, 0, '', '', 0) sc on sc.Marca=i.Marca
	where i.data=@dataSus and (@marca is null or i.marca=@marca) and p.data_angajarii_in_unitate<=(case when @salariatiactivi=1 then @data else @dataSus end) 
		and isnull(i.Grupa_de_munca,p.Grupa_de_munca) not in ('O','P')
		and (@functie is null or isnull(i.cod_functie,p.cod_functie)=@functie) and (@locm is null or i.Loc_de_munca like rtrim(@locm)+(case when @strict=0 then '%' else '' end))
		and (isnull(@grupaMunca,'')='' or isnull(i.grupa_de_munca,p.grupa_de_munca)=@grupaMunca) and (isnull(@tipStat,'')='' or @tipStat=e.religia)
		and (@tipPersonal='A' or (@tipPersonal='T' and isnull(i.tip_salarizare,p.Tip_salarizare) in ('1','2')) or (@tipPersonal='M' and isnull(i.tip_salarizare,p.Tip_salarizare) in ('3','4','5','6','7'))) 
		and (@dreptConducere=0 or (@dreptConducere=1 and @areDreptCond=1 and (@liste_drept='T' or @liste_drept='C' and p.pensie_suplimentara=1 or @liste_drept='S' and p.pensie_suplimentara<>1)) 
		or (@dreptConducere=1 and @areDreptCond=0 and @liste_drept='S' and p.pensie_suplimentara<>1))
		and (convert(int,p.loc_ramas_vacant)=0 or convert(int,p.loc_ramas_vacant)=1 and p.data_plec>(case when @salariatiactivi=1 then @data else @dataJos end))
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=isnull(i.loc_de_munca,p.loc_de_munca)))

--	inserez si pozitiile din functii_lm care nu au salariati
	insert into #tmpPers (data, marca, nume, cod_functie, denumire_functie, loc_de_munca, denumire_lm, niv, salar_de_incadrare, observatii, marca_inlocuitoare, 
			numar_curent, numar_curent_ordonare, numar_posturi, numar_salariati, pozitie_stat, regim_de_lucru, spor_vechime, spor_specific, ordonare1, ordonare2, ordonare3)
	select @dataSus, 'V', 'VACANT', fl.Cod_functie, f.Denumire, fl.Loc_de_munca, lm.Denumire, lm.nivel+1 as niv, fl.Salar_de_incadrare, 
		'', '',  0, 0, fl.Numar_posturi, 0 , fl.Pozitie_stat, fl.Regim_de_lucru, 0 as spor_vechime, 0 as spor_specific, '', 0, ''
	from #functii_lm fl
		left outer join functii f on f.cod_functie=fl.cod_functie
		left outer join lm on lm.cod=fl.loc_de_munca
	where not exists (select Marca from #tmpPers t where t.Loc_de_munca=fl.Loc_de_munca and t.Cod_functie=fl.Cod_functie)

--	inserez pozitii pentru posturile vacante
	if @posturivacante=1
	begin
		declare @v int
		set @v=1
		create table #posturivacante (nrpoz int)
		create index tmpvacant on #posturivacante (nrpoz)
		while @v<51
		Begin
			insert into #posturivacante values(@v)
			set @v=@v+1
		End
		insert into #tmpPers (data, marca, nume, cod_functie, denumire_functie, loc_de_munca, denumire_lm, niv, salar_de_incadrare, observatii, marca_inlocuitoare, 
			numar_curent, numar_curent_ordonare, numar_posturi, numar_salariati, pozitie_stat, regim_de_lucru, spor_vechime, spor_specific, ordonare1, ordonare2, ordonare3)
		select Data, 'V'+rtrim(convert(char(2),v.nrpoz)), 'VACANT'+rtrim(convert(char(2),v.nrpoz)), Cod_functie, Denumire_functie, Loc_de_munca, denumire_lm, niv, 0, '', '', 0, 0, 
			numar_posturi, 1 as numar_salariati, pozitie_stat as pozitie_stat, Regim_de_lucru, 0 as spor_vechime, 0 as spor_specific, 
			'' as ordonare1, 0 as ordonare2, '' as ordonare3
			from (select Data, Loc_de_munca, max(Denumire_lm) as Denumire_lm, Cod_functie, max(Denumire_functie) as Denumire_functie, max(niv) as niv, MAX(Marca) as marca, 
				max(numar_posturi) as numar_posturi, sum(numar_salariati) as numar_salariati, max(numar_posturi)-sum(numar_salariati) as posturi_vacante, MAX(pozitie_stat) as pozitie_stat,
				max(regim_de_lucru) as regim_de_lucru
				from #tmpPers group by Data, Loc_de_munca, Cod_functie) a
			left outer join #posturivacante v on v.nrpoz<=a.posturi_vacante ---(case when left(a.Marca,1)='V' then 1 else 0 end)
		where nrpoz is not null	
	end
	delete from #tmpPers where Marca='V'

--	stabilesc gruparea
	update #tmpPers 
	set ordonare1=(case when @grupare='2' then Cod_functie when @grupare='3' 
				then isnull(replicate('0',9-len(RTRIM(p.Valoare)))+convert(varchar(10),p.Valoare),a.Loc_de_munca) else '' end),
		ordonare2=(case when @grupare='3' then isnull(Pozitie_stat,0) else 0 end),
		ordonare3=(case when @alfabetic=1 then Nume else Marca end)
	from #tmpPers a
		left outer join proprietati p on p.Tip='LM' and p.Cod=a.Loc_de_munca and p.Cod_proprietate='ORDINESTAT' and p.Valoare<>''

--	numar pozitiile in ordinea generari raportului (mai putin pozitiile care sunt marci inlocuitoare)
	update #tmpPers set Numar_curent=n.Numar_curent, Numar_curent_ordonare=n.Numar_curent 
		from #tmpPers a
			inner join (select Marca, Loc_de_munca, Cod_functie, ROW_NUMBER() over (order by ordonare1, ordonare2, ordonare3) as Numar_curent from #tmpPers a
			where not exists (select 1 from #tmpPers b where b.marca_inlocuitoare=a.marca)) n on a.marca=n.marca and a.Loc_de_munca=n.Loc_de_munca and a.Cod_functie=n.Cod_functie
	where not exists (select 1 from #tmpPers b where b.marca_inlocuitoare=a.marca)
--	pun numar curent la marcile inlocuitoare
	update #tmpPers set Numar_curent_ordonare=ISNULL((select Numar_curent from #tmpPers b where b.marca_inlocuitoare=#tmpPers.marca),0)
	where #tmpPers.numar_curent=0

	select a.Numar_curent as Numar_curent, a.numar_curent_ordonare, a.Data, a.marca, a.nume, a.cod_functie, a.denumire_functie, a.loc_de_munca, a.denumire_lm, a.grupa_de_munca,  
		a.categoria_salarizare, (case when Marca_inlocuitoare<>'' then 0 else round(a.regim_de_lucru/8.00,3) end) as Norma, a.regim_de_lucru, 
		a.data_angajarii_in_unitate, a.loc_ramas_vacant, a.data_plec as data_plecarii, 
		a.salar_de_incadrare, a.Salar_de_baza, a.salar_orar, a.indemnizatia_de_conducere, a.spor_vechime, a.spor_de_noapte, a.spor_sistematic_peste_program, 
		(case when @lspf_supl_suma=1 then 0 else a.spor_de_functie_suplimentara end) as spor_de_functie_suplimentara, 
		(case when @lspec_suma=1 then 0 else a.spor_specific end) as spor_specific, (case when @lspc1_suma=1 then 0 else a.spor_conditii_1 end) as spor_conditii_1, 
		(case when @lspc2_suma=1 then 0 else a.Spor_conditii_2 end) as Spor_conditii_2, (case when @lspc3_suma=1 then 0 else a.spor_conditii_3 end) as spor_conditii_3, 
		(case when @lspc4_suma=1 then 0 else a.spor_conditii_4 end) as spor_conditii_4, (case when @lspc5_suma=1 then 0 else a.spor_conditii_5 end) as spor_conditii_5, 
		(case when @lspc6_suma=1 then 0 else a.spor_conditii_6 end) as spor_conditii_6, a.spor_cond_7, 
		a.ind_cond_calc, a.sp_vech_calc, a.sp_sist_calc, a.sp_func_supl_calc, a.sp_spec, a.sp1_calc, a.Sp2_calc, a.Sp3_calc, a.Sp4_calc, a.Sp5_calc, a.sp6_calc, sp7_calc, spnoapte_calc, 
		a.ind_cond_calc+a.sp_sist_calc+a.sp_func_supl_calc+a.sp1_calc+a.sp2_calc+a.sp3_calc+a.sp4_calc+a.sp5_calc+a.sp6_calc+a.sp7_calc+spnoapte_calc as Alte_sporuri, 
		a.Salar_de_incadrare+a.sp_vech_calc+a.ind_cond_calc+a.sp_sist_calc+a.sp_func_supl_calc+a.sp_spec+a.sp1_calc+a.sp2_calc+a.sp3_calc+a.sp4_calc+a.sp5_calc+a.sp6_calc+a.sp7_calc+spnoapte_calc as Total_salar, 
		a.observatii, a.Marca_inlocuitoare, 1 as nivel, niv as niv, rtrim(Loc_de_munca)+cod_functie+' '+marca as cod, Loc_de_munca as parinte
	into #statpers
	from 
	(select a.Numar_curent, a.numar_curent_ordonare, isnull(i.Data,@dataSus) as Data, a.marca, a.nume, a.cod_functie, a.denumire_functie, a.loc_de_munca, a.denumire_lm, a.niv, 
		isnull(i.grupa_de_munca,'') as grupa_de_munca, isnull(i.categoria_salarizare,'') as categoria_salarizare, isnull(a.salar_de_incadrare,0) as salar_de_incadrare,
		isnull(i.indemnizatia_de_conducere,0) as indemnizatia_de_conducere, isnull(p.data_angajarii_in_unitate,'') as data_angajarii_in_unitate, isnull(p.loc_ramas_vacant,0) as loc_ramas_vacant, 
		isnull(p.data_plec,'') as data_plec, 
		/*isnull(round(i.salar_de_incadrare/(case when isnull(i.Tip_salarizare,p.Tip_salarizare)<'3' then @OreLuna else @NrMediuOre end),3),0)*/0 as salar_orar, 
		isnull(i.salar_de_baza,0) as salar_de_baza, 
		isnull(a.spor_vechime,0) as spor_vechime, isnull(i.spor_de_noapte,0) as spor_de_noapte, isnull(i.spor_sistematic_peste_program,0) as spor_sistematic_peste_program, 
		isnull(i.spor_de_functie_suplimentara,0) as spor_de_functie_suplimentara, 
		isnull(a.spor_specific,0) as spor_specific, isnull(i.spor_conditii_1,0) as spor_conditii_1, isnull(i.spor_conditii_2,0) as spor_conditii_2, isnull(i.spor_conditii_3,0) as spor_conditii_3, 
		isnull(i.spor_conditii_4,0) as spor_conditii_4, isnull(i.spor_conditii_5,0) as spor_conditii_5, isnull(i.spor_conditii_6,0) as spor_conditii_6, isnull(e.spor_cond_7,0) as spor_cond_7, 
		(case when left(a.Nume,6)='VACANT' then a.regim_de_lucru else dbo.iau_regim_lucru(a.marca,@dataSus) end) as regim_de_lucru, (case when p.sex=1 then 'M' else 'F'  end) as sex,
		isnull(round(a.salar_de_incadrare*(case when @lindc_suma=1 then 0 else i.indemnizatia_de_conducere/100 end ),0)
			+(case when @lindc_suma=1 then i.indemnizatia_de_conducere else 0 end),0) as ind_cond_calc,
		isnull(round(a.salar_de_incadrare*a.spor_vechime/100,0),0) as sp_vech_calc,
		isnull(round(a.salar_de_incadrare*i.spor_sistematic_peste_program/100,0),0) as sp_sist_calc,
		isnull(round(a.salar_de_incadrare*(case when @lspf_supl_suma=1 then 0 else i.spor_de_functie_suplimentara/100.00 end),0)+(case when @lspf_supl_suma=1 then i.spor_de_functie_suplimentara else 0 end),0) as sp_func_supl_calc,
		isnull(round((a.salar_de_incadrare)*(case when @lspec_suma=1 then 0 else a.spor_specific/100 end ),0)+(case when @lspec_suma=1 then a.spor_specific else 0 end),0) as sp_spec,
		isnull(round((case when @lspc1_suma=0 then a.salar_de_incadrare*i.spor_conditii_1/100 else i.spor_conditii_1 end),0),0) as sp1_calc,
		isnull(round((case when @lspc2_suma=0 then a.salar_de_incadrare*i.spor_conditii_2/100 else i.spor_conditii_2 end),0),0) as sp2_calc,
		isnull(round((case when @lspc3_suma=0 then a.salar_de_incadrare*i.spor_conditii_3/100 else i.spor_conditii_3 end),0),0) as sp3_calc,
		isnull(round((case when @lspc4_suma=0 then a.salar_de_incadrare*i.spor_conditii_4/100 else i.spor_conditii_4 end),0),0) as sp4_calc,
		isnull(round((case when @lspc5_suma=0 then a.salar_de_incadrare*i.spor_conditii_5/100 else i.spor_conditii_5 end),0),0) as sp5_calc,
		isnull(round((case when @lspc6_suma=0 then a.salar_de_incadrare*i.spor_conditii_6/100 else i.spor_conditii_6 end),0),0) as sp6_calc,
		isnull(round(a.salar_de_incadrare*e.spor_cond_7/100,0),0) as sp7_calc, 
		isnull((case when isnull(x.Val_inf,'') in ('Inegal','OreDeNoapte') or 1=1 then round(a.salar_de_incadrare*i.Spor_de_noapte/100 ,0) else 0 end),0) as spnoapte_calc, 
		a.Observatii as observatii, a.Marca_inlocuitoare
	from #tmpPers a
		left outer join personal p on a.Marca=p.Marca
		left outer join istpers i on i.data=@dataSus and i.marca=a.marca
		left outer join infopers e on e.marca=a.marca
		left outer join extinfop x on x.Marca=a.Marca and x.Cod_inf='REPTIMPMUNCA'
	) a 
	order by numar_curent_ordonare

--	procedura specifica pentru calcul sporuri - unde este cazul
	if exists (select 1 from sys.objects where name='rapStatDePersonalSP' and type='P')
		exec rapStatDePersonalSP @data, @marca, @locm, @strict, @functie, @grupaMunca, @tipPersonal, @tipStat, @listaDrept, @grupare, @alfabetic, @posturivacante, @salariatiactivi

--	le-am pus aici si nu in select sa fie mai clar modul de functionare
	if @grupare=1 update #statpers set parinte='<T>'+space(6), niv=1	-- daca nu se doresc locuri de munca in stat ramane totalul ca loc de munca

	if @grupare=2 update #statpers set parinte=Cod_functie, niv=2	-- daca se doreste grupare pe functii

--	Lucian (22.05.2012) mut locurile de munca de nivel X (care au copii) ca si loc de munca de nivel X+1 pt. a putea avea total pe aceste locuri de munca
if @grupare=3 
	update #statpers set parinte=(case when exists (select 1 from #statpers s left outer join lm on s.loc_de_munca=lm.Cod where lm.Cod_parinte=#statpers.loc_de_munca) then rtrim(parinte)+'_' else parinte end),
	loc_de_munca=(case when exists (select 1 from #statpers s left outer join lm on s.loc_de_munca=lm.Cod where lm.Cod_parinte=#statpers.loc_de_munca) then rtrim(loc_de_munca)+'_' else loc_de_munca end),
	niv=(case when exists (select 1 from #statpers s left outer join lm on s.loc_de_munca=lm.Cod where lm.Cod_parinte=#statpers.loc_de_munca) then niv+1 else niv end)

--	am creat tabela (in loc de into) pt. uniformizare structura (al 3=lea union all nu functiona corect in totalizarea pe cod parinte)
	create table #lm (Nivel int, Cod char(9), Cod_parinte char(9), Denumire char(30))
	
	insert into #lm
	select (select min(nivel) from lm)-1 as nivel, convert(char(9),'<T>') as cod, '' as cod_parinte, 'Total' as denumire
	union all	-->> total general
	select 
	Nivel, Cod, (case when isnull(rtrim(Cod_parinte),'')='' then '<T>' else cod_parinte end), Denumire
	from lm
	union all	-->> linii pt. locurile de munca de nivel superior care au copii - le mut la nivel inferior
	select 
	Nivel+1, rtrim(Cod)+'_', Cod, Denumire
	from lm
	where exists (select 1 from lm lm1 where lm1.Cod_parinte=lm.cod)

	set @i=(select max(nivel) from #lm)
	declare @nrcrtmax int
	select @nrcrtmax=max(numar_curent_ordonare) from #statpers
	while @i>-1 and @grupare<>'2' --	generare totaluri pe locuri de munca de nivel superior (inclusiv Total general)
	begin
		select @nrcrtmax=@nrcrtmax+1 from #statpers
		insert into #statpers (numar_curent, numar_curent_ordonare, Data, marca, nume, cod_functie, denumire_functie, loc_de_munca, denumire_lm, grupa_de_munca,  
			categoria_salarizare, norma, regim_de_lucru, data_angajarii_in_unitate, loc_ramas_vacant, data_plecarii, 
			salar_de_incadrare, Salar_de_baza, salar_orar, indemnizatia_de_conducere, spor_vechime, spor_de_noapte, spor_sistematic_peste_program,
			spor_de_functie_suplimentara, spor_specific, spor_conditii_1, Spor_conditii_2, spor_conditii_3, spor_conditii_4, spor_conditii_5, spor_conditii_6, spor_cond_7, 
			ind_cond_calc, sp_vech_calc, sp_sist_calc, sp_func_supl_calc, sp_spec, sp1_calc, Sp2_calc, Sp3_calc, Sp4_calc, Sp5_calc, sp6_calc, sp7_calc, spnoapte_calc, 
			Alte_sporuri, Total_salar, observatii, Marca_inlocuitoare, nivel, niv, cod, parinte)
		select @nrcrtmax, isnull(convert(int,max(p.Valoare)),@nrcrtmax), data, '' as marca, '' as nume, max(Cod_functie) as cod_functie, '' as denumire_functie,
		max(s.loc_de_munca) as loc_de_munca, max(rtrim(lm.denumire)) as denumire_lm, '' as grupa_de_munca, '' as categoria_salarizare, sum(norma) as norma, 0 as regim_de_lucru, 
		'' as data_angajarii_in_unitate, 0 as loc_ramas_vacant, '' as data_plecarii, 
		sum(salar_de_incadrare), sum(Salar_de_baza), sum(salar_orar), sum(indemnizatia_de_conducere), sum(spor_vechime), sum(spor_de_noapte), sum(spor_sistematic_peste_program), 
		sum(spor_de_functie_suplimentara), sum(spor_specific), sum(spor_conditii_1), sum(Spor_conditii_2), sum(spor_conditii_3), sum(spor_conditii_4), sum(spor_conditii_5), 
		sum(spor_conditii_6), sum(spor_cond_7), sum(ind_cond_calc), sum(sp_vech_calc), sum(sp_sist_calc), sum(sp_func_supl_calc), sum(sp_spec), sum(sp1_calc), sum(Sp2_calc), 
		sum(Sp3_calc), sum(Sp4_calc), sum(Sp5_calc), sum(sp6_calc), sum(sp7_calc), sum(spnoapte_calc), sum(Alte_sporuri), sum(Total_salar), 
		'' as observatii, '' as Marca_inlocuitoare, 2 as nivel, max(lm.nivel) as niv, max(isnull(lm.cod,'')) as cod, rtrim(max(isnull(lm.cod_parinte,''))) as parinte
		from #statpers s
			left join #lm lm on lm.cod=s.parinte 
			left outer join proprietati p on p.Tip='LM' and p.Cod=s.Loc_de_munca and p.Cod_proprietate='ORDINESTAT' and p.Valoare<>''
		where @i=lm.nivel and lm.cod is not null and s.nivel>0
		group by Data, isnull(lm.cod_parinte,''), s.parinte
	
		set @i=@i-1
	end

	if @grupare='2'	--	generez totaluri pe functii si total general
	begin
		select @nrcrtmax=max(numar_curent_ordonare)+1 from #statpers
		insert into #statpers (numar_curent, numar_curent_ordonare, Data, marca, nume, cod_functie, denumire_functie, loc_de_munca, denumire_lm, grupa_de_munca,  
			categoria_salarizare, norma, regim_de_lucru, data_angajarii_in_unitate, loc_ramas_vacant, data_plecarii, 
			salar_de_incadrare, Salar_de_baza, salar_orar, indemnizatia_de_conducere, spor_vechime, spor_de_noapte, spor_sistematic_peste_program,
			spor_de_functie_suplimentara, spor_specific, spor_conditii_1, Spor_conditii_2, spor_conditii_3, spor_conditii_4, spor_conditii_5, spor_conditii_6, spor_cond_7, 
			ind_cond_calc, sp_vech_calc, sp_sist_calc, sp_func_supl_calc, sp_spec, sp1_calc, Sp2_calc, Sp3_calc, Sp4_calc, Sp5_calc, sp6_calc, sp7_calc, spnoapte_calc, 
			Alte_sporuri, Total_salar, observatii, Marca_inlocuitoare, nivel, niv, cod, parinte)
		select @nrcrtmax, @nrcrtmax, data, '' as marca, '' as nume, Cod_functie as cod_functie, max(denumire_functie) as denumire_functie,
		'' as loc_de_munca, '' as denumire_lm, '' as grupa_de_munca, '' as categoria_salarizare, sum(norma) as norma, 0 as regim_de_lucru, 
		'' as data_angajarii_in_unitate, 0 as loc_ramas_vacant, '' as data_plecarii, 
		sum(salar_de_incadrare), sum(Salar_de_baza), sum(salar_orar), sum(indemnizatia_de_conducere), sum(spor_vechime), sum(spor_de_noapte), sum(spor_sistematic_peste_program), 
		sum(spor_de_functie_suplimentara), sum(spor_specific), sum(spor_conditii_1), sum(Spor_conditii_2), sum(spor_conditii_3), sum(spor_conditii_4), sum(spor_conditii_5), 
		sum(spor_conditii_6), sum(spor_cond_7), sum(ind_cond_calc), sum(sp_vech_calc), sum(sp_sist_calc), sum(sp_func_supl_calc), sum(sp_spec), sum(sp1_calc), sum(Sp2_calc), 
		sum(Sp3_calc), sum(Sp4_calc), sum(Sp5_calc), sum(sp6_calc), sum(sp7_calc), sum(spnoapte_calc), sum(Alte_sporuri), sum(Total_salar), 
		'' as observatii, '' as Marca_inlocuitoare, 2 as nivel, 1 as niv, Cod_functie as cod, '<T>' as parinte
		from #statpers s
		group by Data, Cod_functie

		select @nrcrtmax=@nrcrtmax+1
		insert into #statpers (numar_curent, numar_curent_ordonare, Data, marca, nume, cod_functie, denumire_functie, loc_de_munca, denumire_lm, grupa_de_munca,  
			categoria_salarizare, norma, regim_de_lucru, data_angajarii_in_unitate, loc_ramas_vacant, data_plecarii, 
			salar_de_incadrare, Salar_de_baza, salar_orar, indemnizatia_de_conducere, spor_vechime, spor_de_noapte, spor_sistematic_peste_program,
			spor_de_functie_suplimentara, spor_specific, spor_conditii_1, Spor_conditii_2, spor_conditii_3, spor_conditii_4, spor_conditii_5, spor_conditii_6, spor_cond_7, 
			ind_cond_calc, sp_vech_calc, sp_sist_calc, sp_func_supl_calc, sp_spec, sp1_calc, Sp2_calc, Sp3_calc, Sp4_calc, Sp5_calc, sp6_calc, sp7_calc, spnoapte_calc, 
			Alte_sporuri, Total_salar, observatii, Marca_inlocuitoare, nivel, niv, cod, parinte)
		select max(numar_curent), max(numar_curent_ordonare), data, '' as marca, '' as nume, '<T>' as cod_functie, 'Total' as denumire_functie,
		'' as loc_de_munca, '' as denumire_lm, '' as grupa_de_munca, '' as categoria_salarizare, sum(norma) as norma, 0 as regim_de_lucru, 
		'' as data_angajarii_in_unitate, 0 as loc_ramas_vacant, '' as data_plecarii, 
		sum(salar_de_incadrare), sum(Salar_de_baza), sum(salar_orar), sum(indemnizatia_de_conducere), sum(spor_vechime), sum(spor_de_noapte), sum(spor_sistematic_peste_program), 
		sum(spor_de_functie_suplimentara), sum(spor_specific), sum(spor_conditii_1), sum(Spor_conditii_2), sum(spor_conditii_3), sum(spor_conditii_4), sum(spor_conditii_5), 
		sum(spor_conditii_6), sum(spor_cond_7), sum(ind_cond_calc), sum(sp_vech_calc), sum(sp_sist_calc), sum(sp_func_supl_calc), sum(sp_spec), sum(sp1_calc), sum(Sp2_calc), 
		sum(Sp3_calc), sum(Sp4_calc), sum(Sp5_calc), sum(sp6_calc), sum(sp7_calc), sum(spnoapte_calc), sum(Alte_sporuri), sum(Total_salar), 
		'' as observatii, '' as Marca_inlocuitoare, 2 as nivel, 0 as niv, '<T>' as cod, '' as parinte
		from #statpers s
		where nivel=1
		group by Data
	end

	select numar_curent, numar_curent_ordonare, Data, marca, nume, cod_functie, denumire_functie, loc_de_munca, denumire_lm, nivel, niv, rtrim(cod) as cod, rtrim(parinte) as parinte, 
		grupa_de_munca, categoria_salarizare, norma, regim_de_lucru, data_angajarii_in_unitate, loc_ramas_vacant, data_plecarii, 
		salar_de_incadrare, Salar_de_baza, salar_orar, indemnizatia_de_conducere, spor_vechime, spor_de_noapte, spor_sistematic_peste_program, 
		spor_de_functie_suplimentara, spor_specific, spor_conditii_1, Spor_conditii_2, spor_conditii_3, spor_conditii_4, spor_conditii_5, spor_conditii_6, spor_cond_7, 
		ind_cond_calc, sp_vech_calc, sp_sist_calc, sp_func_supl_calc, sp_spec, sp1_calc, Sp2_calc, Sp3_calc, Sp4_calc, Sp5_calc, sp6_calc, sp7_calc, spnoapte_calc, 
		Alte_sporuri, Total_salar, observatii, Marca_inlocuitoare
	from #statpers
	where (@grupare in ('2','3') or @grupare='1' and (nivel=2 and cod='<T>' or nivel=1))
	order by (case when @grupare='1' then '' else nivel end), numar_curent_ordonare, numar_curent desc
	
end try

begin catch
	set @eroare='Procedura rapStatDePersonal (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

if object_id('tempdb..#tmpPers') is not null drop table #tmpPers
if object_id('tempdb..#lm') is not null drop table #lm
if object_id('tempdb..#functii_lm') is not null drop table #functii_lm
if object_id('tempdb..#posturivacante') is not null drop table #posturivacante
if object_id('tempdb..#statpers') is not null drop table #statpers

/*
	exec rapStatDePersonal '07/01/2012', 'A013', null, 0, null, '', 'A', '', 'T', '3', 1, 0, 1
*/
