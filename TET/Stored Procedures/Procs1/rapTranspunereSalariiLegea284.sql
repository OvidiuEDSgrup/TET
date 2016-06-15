--***
/**	procedura pt. stat de personal 
	grupare = 1 -> Salariati
	grupare = 2 -> Functii, Salariati
	grupare = 3 -> Locuri de munca, Salariati
*/
/*
	exec rapTranspunereSalariiLegea284 '01/01/2014', null, null, 0, null, '', 'A', '', 'T', '3', 1, 0
*/
Create procedure rapTranspunereSalariiLegea284
	(@data datetime, @marca char(6)=null, @locm char(9)=null, @strict int=0, @functie char(6)=null, @grupaMunca char(1), @tipPersonal char(1)='A', 
	@tipStat varchar(30), @listaDrept char(1), @grupare char(1), @alfabetic int, @salariatiactivi int=0)
as
declare @eroare varchar(2000)
begin try
	set transaction isolation level read uncommitted
	if object_id('tempdb..#tmppers') is not null drop table #tmppers
	if object_id('tempdb..#statpers') is not null drop table #statpers
	if object_id('tempdb..#lm') is not null drop table #lm
	if object_id('tempdb..#functii') is not null drop table #functii
	if object_id('tempdb..#functii_lm') is not null drop table #functii_lm

	declare @dataJos datetime, @dataSus datetime, @utilizator varchar(20),  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	@lunaInch int, @anulInch int, @dataInch datetime, @dreptConducere int, @liste_drept char(1), @areDreptCond int, @regimVariabil int, @i int 

	set @dataJos=dbo.BOM(@data)
	set @dataSus=dbo.EOM(@data)	
	set @utilizator = dbo.fIaUtilizator(null)
	set @lunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @anulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	set @dataInch=dbo.eom(convert(datetime,str(@lunaInch,2)+'/01/'+str(@anulInch,4)))

	Set @dreptConducere=dbo.iauParL('PS','DREPTCOND')
	Set @regimVariabil=dbo.iauParL('PS','REGIMLV')

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
	(select Data, Loc_de_munca, Cod_functie, Tip_personal, Salar_de_incadrare, Pozitie_stat, RANK() over (partition by Loc_de_munca, Cod_functie order by Data Desc) as ordine
	from functii_lm f 
	where Data<=@DataSus and (@locm is null or Loc_de_munca like rtrim(@locm)+(case when @strict=0 then '%' else '' end)) 
		and (@functie is null or Cod_functie=@functie) and (@tipPersonal='A' or Tip_personal=@tipPersonal)
		and not exists (select 1 from ValidCat v where v.Tip='LM' and v.Cod=f.Loc_de_munca and @data between v.Data_jos and v.Data_sus)) a
	where Ordine=1

	select cod_functie, denumire, nivel_de_studii, nullif(detalii.value('/row[1]/@tipfunctie','varchar(100)'),'') as tipfunctie,
		nullif(detalii.value('/row[1]/@grad','varchar(100)'),'') as grad, nullif(detalii.value('/row[1]/@treapta','varchar(100)'),'') as treapta
	into #functii
	from functii

--	Pun datele in tabela temporara pt. a face cateva operatii ulterioare
	select i.Data, i.Marca, i.Nume, i.cod_functie, 
	rtrim(f.Denumire)+(case when isnull(f.Grad,'')<>'' then ', grad '+f.grad else '' end)
		+(case when isnull(f.Treapta,'')<>'' then ', treapta '+f.Treapta else '' end)
		+(case when isnull(f.tipfunctie,'')='Executie' then ', gradatia '+convert(varchar(10),sc.gradatia) else '' end) as denumire_functie, 
	f.Nivel_de_studii, i.loc_de_munca, lm.denumire as denumire_lm, lm.nivel+1 as niv, 
	sc.Vechime_totala_car as vechime_totala, sc.Vechime_in_meserie as vechime_specialitate, 
	i.Salar_de_incadrare as salar_de_incadrare, isnull(cs.Salar_orar,0) as coeficient_ierarhizare, 
	isnull(round(pl.Val_numerica*cs.Salar_orar,0),0) as salar_de_incadrare_grila, isnull(round(pl.Val_numerica*cs.Salar_orar,0),0)-i.Salar_de_incadrare as diferenta_salar, 
	0 as numar_curent, 0 as numar_curent_ordonare, isnull(fl.Pozitie_stat,0) as pozitie_stat, space(100) as ordonare1, 0 as ordonare2, space(100) as ordonare3 
	into #tmpPers
	from istpers i 
		left outer join personal p on p.Marca=i.Marca
		left outer join infopers e on e.marca=p.marca
		left outer join #functii f on f.cod_functie=i.cod_functie
		left outer join lm on lm.cod=isnull(i.loc_de_munca,p.loc_de_munca)
		left outer join #functii_lm fl on fl.Cod_functie=i.cod_functie and fl.Loc_de_munca=i.Loc_de_munca
		left outer join fCalculVechimeSporuri (@dataJos, @dataSus, '', 0, 0, '', '', 0) sc on sc.Marca=i.Marca
		left outer join categs cs on cs.Categoria_salarizare=i.Categoria_salarizare
		left outer join par_lunari pl on pl.Data=i.data and pl.tip='PS' and pl.Parametru='S-MIN-BR'
	where i.data=@dataSus and (@marca is null or i.marca=@marca) and p.data_angajarii_in_unitate<=(case when @salariatiactivi=1 then @data else @dataSus end) 
		and isnull(i.Grupa_de_munca,p.Grupa_de_munca) not in ('O','P')
		and (@functie is null or isnull(i.cod_functie,p.cod_functie)=@functie) and (@locm is null or i.Loc_de_munca like rtrim(@locm)+(case when @strict=0 then '%' else '' end))
		and (isnull(@grupaMunca,'')='' or isnull(i.grupa_de_munca,p.grupa_de_munca)=@grupaMunca) and (isnull(@tipStat,'')='' or @tipStat=e.religia)
		and (@tipPersonal='A' or (@tipPersonal='T' and isnull(i.tip_salarizare,p.Tip_salarizare) in ('1','2')) or (@tipPersonal='M' and isnull(i.tip_salarizare,p.Tip_salarizare) in ('3','4','5','6','7'))) 
		and (@dreptConducere=0 or (@dreptConducere=1 and @areDreptCond=1 and (@liste_drept='T' or @liste_drept='C' and p.pensie_suplimentara=1 or @liste_drept='S' and p.pensie_suplimentara<>1)) 
		or (@dreptConducere=1 and @areDreptCond=0 and @liste_drept='S' and p.pensie_suplimentara<>1))
		and (convert(int,p.loc_ramas_vacant)=0 or convert(int,p.loc_ramas_vacant)=1 and p.data_plec>(case when @salariatiactivi=1 then @data else @dataJos end))
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=isnull(i.loc_de_munca,p.loc_de_munca)))

--	stabilesc gruparea
	update #tmpPers 
	set ordonare1=(case when @grupare='2' then Cod_functie when @grupare='3' 
				then isnull(replicate('0',9-len(RTRIM(p.Valoare)))+convert(varchar(10),p.Valoare),a.Loc_de_munca) else '' end),
		ordonare2=(case when @grupare='3' then isnull(Pozitie_stat,0) else 0 end),
		ordonare3=(case when @alfabetic=1 then Nume else Marca end)
	from #tmpPers a
		left outer join proprietati p on p.Tip='LM' and p.Cod=a.Loc_de_munca and p.Cod_proprietate='ORDINESTAT' and p.Valoare<>''

--	numar pozitiile in ordinea generari raportului
	update #tmpPers set Numar_curent=n.Numar_curent, Numar_curent_ordonare=n.Numar_curent 
		from #tmpPers a
			inner join (select Marca, Loc_de_munca, Cod_functie, ROW_NUMBER() over (order by ordonare1, ordonare2, ordonare3) as Numar_curent from #tmpPers a
			) n on a.marca=n.marca and a.Loc_de_munca=n.Loc_de_munca and a.Cod_functie=n.Cod_functie
	
	select a.Numar_curent as Numar_curent, a.numar_curent_ordonare, a.Data, a.marca, a.nume, a.cod_functie, a.denumire_functie, a.Nivel_de_studii, a.loc_de_munca, a.denumire_lm, 
		a.data_angajarii_in_unitate, a.loc_ramas_vacant, a.data_plec as data_plecarii, vechime_totala, vechime_specialitate, 
		a.categoria_salarizare as clasa_salarizare, a.coeficient_ierarhizare, a.salar_de_incadrare, a.salar_de_incadrare_grila, diferenta_salar, 
		1 as nivel, niv as niv, rtrim(Loc_de_munca)+cod_functie+' '+marca as cod, Loc_de_munca as parinte
	into #statpers
	from 
	(select a.Numar_curent, a.numar_curent_ordonare, isnull(i.Data,@dataSus) as Data, a.marca, a.nume, a.cod_functie, a.denumire_functie, a.Nivel_de_studii, a.loc_de_munca, a.denumire_lm, a.niv, 
		isnull(p.data_angajarii_in_unitate,'') as data_angajarii_in_unitate, isnull(p.loc_ramas_vacant,0) as loc_ramas_vacant, a.vechime_totala, a.vechime_specialitate, 
		isnull(i.categoria_salarizare,'') as categoria_salarizare, a.coeficient_ierarhizare, 
		a.salar_de_incadrare as salar_de_incadrare, a.salar_de_incadrare_grila as salar_de_incadrare_grila, a.diferenta_salar, 
		isnull(p.data_plec,'') as data_plec, isnull(i.salar_de_baza,0) as salar_de_baza, (case when p.sex=1 then 'M' else 'F'  end) as sex
	from #tmpPers a
		left outer join personal p on a.Marca=p.Marca
		left outer join istpers i on i.data=@dataSus and i.marca=a.marca
		left outer join infopers e on e.marca=a.marca
	) a 
	order by numar_curent_ordonare

--	le-am pus aici si nu in select sa fie mai clar modul de functionare
	if @grupare=1 update #statpers set parinte='<T>'+space(6), niv=1	-- daca nu se doresc locuri de munca in stat ramane totalul ca loc de munca

	if @grupare=2 update #statpers set parinte=Cod_functie, niv=2	-- daca se doreste grupare pe functii

--	mut locurile de munca de nivel X (care au copii) ca si loc de munca de nivel X+1 pt. a putea avea total pe aceste locuri de munca
if @grupare=3 
	update #statpers 
		set parinte=(case when exists (select 1 from #statpers s left outer join lm on s.loc_de_munca=lm.Cod where lm.Cod_parinte=#statpers.loc_de_munca) then rtrim(parinte)+'_' else parinte end),
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
		insert into #statpers (numar_curent, numar_curent_ordonare, Data, marca, nume, cod_functie, denumire_functie, nivel_de_studii, loc_de_munca, denumire_lm, 
			data_angajarii_in_unitate, loc_ramas_vacant, data_plecarii, vechime_totala, vechime_specialitate, 
			clasa_salarizare, coeficient_ierarhizare, salar_de_incadrare, salar_de_incadrare_grila, diferenta_salar, nivel, niv, cod, parinte)
		select @nrcrtmax, isnull(convert(int,max(p.Valoare)),@nrcrtmax), data, '' as marca, '' as nume, max(Cod_functie) as cod_functie, '' as denumire_functie, '' as nivel_de_studii, 
			max(s.loc_de_munca) as loc_de_munca, max(rtrim(lm.denumire)) as denumire_lm, '' as data_angajarii_in_unitate, '' as loc_ramas_vacant, '' as data_plecarii, 
			'' as categoria_salarizare, 0 as coeficient_ierarhizare, '' as vechime_totala, '' as vechime_specialitate, sum(salar_de_incadrare), sum(salar_de_incadrare_grila), sum(diferenta_salar),  
			2 as nivel, max(lm.nivel) as niv, max(isnull(lm.cod,'')) as cod, rtrim(max(isnull(lm.cod_parinte,''))) as parinte
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
		insert into #statpers (numar_curent, numar_curent_ordonare, Data, marca, nume, cod_functie, denumire_functie, Nivel_de_studii, loc_de_munca, denumire_lm, 
			data_angajarii_in_unitate, loc_ramas_vacant, data_plecarii, vechime_totala, vechime_specialitate, 
			clasa_salarizare, coeficient_ierarhizare, salar_de_incadrare, salar_de_incadrare_grila, diferenta_salar, nivel, niv, cod, parinte)
		select @nrcrtmax, @nrcrtmax, data, '' as marca, '' as nume, Cod_functie as cod_functie, max(denumire_functie) as denumire_functie, max(Nivel_de_studii) as nivel_de_studii, 
		'' as loc_de_munca, '' as denumire_lm, '' as data_angajarii_in_unitate, '' as loc_ramas_vacant, '' as data_plecarii, '' as vechime_totala, '' as vechime_specialitate, 
		'' as categoria_salarizare, 0 as coeficient_ierarhizare, sum(salar_de_incadrare), sum(salar_de_incadrare_grila), sum(diferenta_salar) as diferenta_salar, 
		2 as nivel, 1 as niv, Cod_functie as cod, '<T>' as parinte
		from #statpers s
		group by Data, Cod_functie

		select @nrcrtmax=@nrcrtmax+1
		insert into #statpers (numar_curent, numar_curent_ordonare, Data, marca, nume, cod_functie, denumire_functie, Nivel_de_studii, loc_de_munca, denumire_lm, 
			data_angajarii_in_unitate, loc_ramas_vacant, data_plecarii, vechime_totala, vechime_specialitate, 
			clasa_salarizare, coeficient_ierarhizare, salar_de_incadrare, salar_de_incadrare_grila, diferenta_salar, nivel, niv, cod, parinte)
		select max(numar_curent), max(numar_curent_ordonare), data, '' as marca, '' as nume, '<T>' as cod_functie, 'Total' as denumire_functie, '' as Nivel_de_studii, 
		'' as loc_de_munca, '' as denumire_lm, '' as data_angajarii_in_unitate, '' as loc_ramas_vacant, '' as data_plecarii, '' as vechime_totala, '' as vechime_specialitate, 
		'' as categoria_salarizare, 0 as coeficient_ierarhizare, sum(salar_de_incadrare), sum(salar_de_incadrare_grila), sum(diferenta_salar) as diferenta_salar, 2 as nivel, 0 as niv, '<T>' as cod, '' as parinte
		from #statpers s
		where nivel=1
		group by Data
	end
	
	select numar_curent, numar_curent_ordonare, Data, marca, nume, cod_functie, denumire_functie, nivel_de_studii, loc_de_munca, denumire_lm, nivel, niv, rtrim(cod) as cod, rtrim(parinte) as parinte, 
		vechime_totala, vechime_specialitate, clasa_salarizare, coeficient_ierarhizare, salar_de_incadrare, salar_de_incadrare_grila, diferenta_salar
	from #statpers
	where (@grupare in ('2','3') or @grupare='1' and (nivel=2 and cod='<T>' or nivel=1))
	order by (case when @grupare='1' then '' else nivel end), numar_curent_ordonare, numar_curent desc

end try

begin catch
	set @eroare='Procedura rapTranspunereSalariiLegea284 (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

if object_id('tempdb..#tmpPers') is not null drop table #tmpPers
if object_id('tempdb..#lm') is not null drop table #lm
if object_id('tempdb..#functii_lm') is not null drop table #functii_lm
if object_id('tempdb..#statpers') is not null drop table #statpers
