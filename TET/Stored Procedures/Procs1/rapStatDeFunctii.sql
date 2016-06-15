--***
/**	procedura pentru noul raport web Stat de functii.rdl	
	Grupare = F - > Functii
	Grupare = L - > Locuri de munca
**/
Create procedure rapStatDeFunctii
	(@dataJos datetime, @dataSus datetime, @marca char(6)=null, @functie char(6)=null, @filtruFunctieArbore int=0, @locm char(9)=null, @strict int=0, 
	@grupare char(50), @faraSalariatiPlecatiLuna int=0, @tipPersonal char(1)=null, @desfasurare int=0)
as
begin try
	set transaction isolation level read uncommitted
	if object_id('tempdb..#stat_functii') is not null drop table #stat_functii
	if object_id('tempdb..#functii_lm') is not null drop table #functii_lm
	if object_id('tempdb..#stat_final') is not null drop table #stat_final
	if object_id('tempdb..#posturivacante') is not null drop table #posturivacante	

	declare @anulInch int, @lunaInch int, @dataInch datetime
	set @AnulInch=dbo.iauParN('PS','ANUL-INCH')
	set @LunaInch=dbo.iauParN('PS','LUNA-INCH')
	set @dataInch=dbo.eom(convert(datetime,str(@lunaInch,2)+'/01/'+str(@anulInch,4)))
	
	declare @utilizator varchar(20)  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @utilizator = dbo.fIaUtilizator(null)

--	apelez scrierea in istoric pesonal (din istpers se iau datele pt. raport - cu avantaj in cazul modificarilor de salar operate pe CTRL+D)
	if isnull((select type from sysobjects where name='istPers'),'')='U' and (not exists (select 1 from istPers where Data=@dataSus) or 1=1)
		if @dataJos>@dataInch
			exec scriuistPers @dataJos, @dataSus, @marca, @locm, 1, 1, 0, 0, @dataSus

--	selectez din functii_lm pozitiile valabile la data generarii raportului
	select * into #functii_lm from 
	(select Data, Loc_de_munca, Cod_functie, Denumire, Tip_personal, Salar_de_incadrare, 
		Numar_posturi*(case when Regim_de_lucru<>0 then Regim_de_lucru/8 else 1 end) as Numar_posturi, 
		Pozitie_stat, RANK() over (partition by Loc_de_munca, Cod_functie order by Data Desc) as ordine
	from functii_lm f 
	where Data<=@DataSus and (@locm is null or Loc_de_munca like rtrim(@locm)+(case when @strict=0 then '%' else '' end)) 
		and (@functie is null or Cod_functie like rtrim(@functie)+(case when @filtruFunctieArbore=1 then '%' else '' end))
		and not exists (select 1 from ValidCat v where v.Tip='LM' and v.Cod=f.Loc_de_munca and @dataSus between v.Data_jos and v.Data_sus)) a
	where Ordine=1

--	creare tabela temporara in care se pun datele de prelucrat (fie din functii_lm fie din istpers)
	Create table #stat_functii (Tip char(2), Data datetime, Loc_de_munca char(9), Cod_functie char(6), Denumire varchar(50), Tip_personal char(1), 
		Salar_de_incadrare float, Numar_posturi float, Pozitie_stat int)

	if exists (select 1 from #functii_lm)
		insert into #stat_functii
		select 'SF', @dataSus, Loc_de_munca, Cod_functie, Denumire, Tip_personal, Salar_de_incadrare, Numar_posturi, Pozitie_stat from #functii_lm
	else 	
		insert into #stat_functii
		select distinct 'IP', Data, Loc_de_munca, Cod_functie, '', '', 0, 0, 0 from istPers i where i.Data between @dataJos and @dataSus 

--	selectul aproape final; mai fac ulterior numerotarea pozitiilor, inserarea marcilor vacante si insumarea pe locuri de munca si functii
	select s.Data as Data, (case when @grupare='F' then '' else s.Loc_de_munca end) as Loc_de_munca, max(lm.Denumire) as Denumire_lm, 
		s.Cod_functie as Cod_functie, max((case when s.Denumire<>'' then s.Denumire else f.Denumire end)) as Denumire_functie, 
		isnull(i.Marca,'V') as Marca, max(isnull(i.Nume,'VACANT')) as Nume, max(fc.Cod_functie) as Functie_COR, max(f.Nivel_de_studii) as nivel_studii,
		(case when max(s.Tip)='SF' then max((case when @grupare='F' then np.numar_posturi else s.Numar_posturi end)) else count(i.Marca) end) as numar_posturi, 
		count(i.Marca) as numar_salariati, 0 as posturi_vacante,
		(case when max(i.Grupa_de_munca) in ('N','D','S') then 'Norma intreaga' when max(i.Grupa_de_munca)='C' then 'Timp partial' else '' end) as tip_contract,
		(case when max(i.Mod_angajare)='D' then 'Determinata' when max(i.Mod_angajare)='N' then 'Nedeterminata' else '' end) as durata_contract, 
		max(isnull(i.Salar_de_incadrare,0)) as salar_de_incadrare, 0 as numar_curent, 0 as ordine_grup, 
		1 as nivel, max(lm.nivel)+(case when @grupare='L' then 2 else 1 end) as niv, 
		max(rtrim(s.Loc_de_munca)+s.cod_functie)+' '+max(isnull(i.Marca,'V')) as cod, max(s.Loc_de_munca)+space(10) as parinte,
		(case when @grupare='L' then max(fl.Pozitie_stat) else s.Cod_functie end) as ordonare
	into #stat_final
	from #stat_functii s 
		left outer join istPers i on i.Loc_de_munca=s.Loc_de_munca and i.Cod_functie=s.Cod_functie and i.Data=@dataSus and i.Grupa_de_munca not in ('O','P') 
		left outer join personal p on p.Marca=i.Marca 
		left outer join functii f on f.Cod_functie=s.Cod_functie
		left outer join extinfop e on e.Marca=s.Cod_functie and e.Cod_inf='#CODCOR'
		left outer join Functii_COR fc on fc.Cod_functie=e.Val_inf
		left outer join lm on lm.Cod=s.Loc_de_munca 
		left outer join #functii_lm fl on fl.Cod_functie=s.cod_functie and fl.Loc_de_munca=s.Loc_de_munca
		left outer join (select cod_functie, sum(Numar_posturi) as numar_posturi from #functii_lm group by Cod_functie) np on np.Cod_functie=s.cod_functie 
	where (i.Data is null or i.Data between @dataJos and @dataSus and isnull(i.Grupa_de_munca,'') not in ('O','P') 
			and (convert(char(1),p.loc_ramas_vacant)=0 or (convert(char(1),p.loc_ramas_vacant)=1 and (@faraSalariatiPlecatiLuna=0 and p.data_plec>=dbo.bom(i.Data) 
			or @faraSalariatiPlecatiLuna=1 and p.data_plec>i.Data))) and p.data_angajarii_in_unitate<=i.Data and (@marca is null or i.Marca=@marca)) 
		and (@functie is null or s.Cod_functie like rtrim(@functie)+(case when @filtruFunctieArbore=1 then '%' else '' end)) 
		and (@locm is null or s.Loc_de_munca like rtrim(@locm)+(case when @strict=0 then '%' else '' end)) 
		and (s.Tip='IP' or @tipPersonal is null or s.Tip_personal=@tipPersonal)
		and (s.Tip='SF' or @tipPersonal is null or @tipPersonal='T' and isnull(i.Tip_salarizare,'') in ('1','2') or @tipPersonal='M' and isnull(i.Tip_salarizare,'') in ('3','4','5','6','7'))
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=s.Loc_de_munca))
	group by s.Data, (case when @grupare='F' then '' else s.Loc_de_munca end), s.Cod_functie, isnull(i.Marca,'V')
	order by Data, (case when @grupare='F' then '' else s.Loc_de_munca end), ordonare, max(i.Nume)

--	inserez pozitii pentru posturile vacante
	declare @i int
	set @i=1
	create table #posturivacante (nrpoz int)
	create index tmpvacant on #posturivacante (nrpoz)
	while @i<51
	Begin
		insert into #posturivacante values(@i)
		set @i=@i+1
	End
	insert into #stat_final
	select Data, Loc_de_munca, denumire_lm, Cod_functie, Denumire_functie, 'V', 'VACANT', functie_cor, nivel_studii, 0, 0, 0, '', '', 0, 0, 0, nivel, niv, cod, parinte, ordonare 
		from (select Data, Loc_de_munca, max(Denumire_lm) as Denumire_lm, Cod_functie, max(Denumire_functie) as Denumire_functie, max(functie_cor) as functie_cor, max(Marca) as marca, 
			max(nivel_studii) as nivel_studii, max(numar_posturi)-sum(numar_salariati) as posturi_vacante, MAX(ordonare) as ordonare, 
			max(nivel) as nivel, MAX(niv) as niv, MAX(cod) as cod, MAX(parinte) as parinte
			from #stat_final group by Data, Loc_de_munca, Cod_functie) a
		left outer join #posturivacante v on v.nrpoz<=a.posturi_vacante-(case when a.Marca='V' then 1 else 0 end)
	where nrpoz is not null	

--	numar pozitiile in ordinea generari raportului (mai putin pozitiile care sunt marci inlocuitoare) - pt. cazul in care va trebui afisat numar curent + suspendati/inlocuitori
	update #stat_final set numar_curent=n.numar_curent
		from #stat_final a
			inner join (select Loc_de_munca, Cod_functie, Marca, 
						ROW_NUMBER() over (order by data, isnull(replicate('0',9-len(RTRIM(p.Valoare)))+convert(varchar(10),p.Valoare),loc_de_munca), ordonare, marca) as numar_curent 
					from #stat_final a
						left outer join proprietati p on p.Tip='LM' and p.Cod=a.Loc_de_munca and p.Cod_proprietate='ORDINESTAT' and p.Valoare<>'') n 
				on a.Loc_de_munca=n.Loc_de_munca and a.Cod_functie=n.Cod_functie and a.marca=n.marca 

--	determin ordinea pe grupare, pt. ca pe totaluri sa se insumeze numarul de posturi de pe o singura marca la nivel de lm/functie
	update #stat_final set ordine_grup=a.ordine_grup
		from (select data, loc_de_munca, cod_functie, Marca, 
			RANK() over (partition by data, isnull(replicate('0',9-len(RTRIM(p.Valoare)))+convert(varchar(10),p.Valoare),loc_de_munca), ordonare order by numar_curent) as ordine_grup
		from #stat_final a
			left outer join proprietati p on p.Tip='LM' and p.Cod=a.Loc_de_munca and p.Cod_proprietate='ORDINESTAT' and p.Valoare<>'') a 
	where #stat_final.Loc_de_munca=a.Loc_de_munca and #stat_final.Cod_functie=a.Cod_functie and #stat_final.Marca=a.Marca

	if @grupare='F' update #stat_final set parinte=Cod_functie, niv=2	-- daca se doreste grupare pe functii

	if @grupare='L' 
		update #stat_final set parinte=(case when exists (select 1 from #stat_final s left outer join lm on s.loc_de_munca=lm.Cod where lm.Cod_parinte=#stat_final.loc_de_munca) 
				then rtrim(Loc_de_munca)+'_ '+rtrim(Cod_functie) else rtrim(Loc_de_munca)+' '+rtrim(Cod_functie) end),
			loc_de_munca=(case when exists (select 1 from #stat_final s left outer join lm on s.loc_de_munca=lm.Cod 
					where lm.Cod_parinte=#stat_final.loc_de_munca) then rtrim(loc_de_munca)+'_' else loc_de_munca end),
			niv=(case when exists (select 1 from #stat_final s left outer join lm on s.loc_de_munca=lm.Cod where lm.Cod_parinte=#stat_final.loc_de_munca) then niv+1 else niv end)

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

	declare @nrcrtmax int
	if @grupare='L' --	generare totaluri pe locuri de munca si functii
	begin
		select @nrcrtmax=max(numar_curent)+1 from #stat_final
		insert into #stat_final (Data, Loc_de_munca, Denumire_lm, Cod_functie, Denumire_functie, Marca, Nume, functie_cor, nivel_studii, numar_posturi, numar_salariati, 
			posturi_vacante, tip_contract, durata_contract, salar_de_incadrare, numar_curent, ordine_grup, nivel, niv, cod, parinte)
		select s.Data, s.loc_de_munca, max(denumire_lm) as denumire_lm, s.Cod_functie, max(Denumire_functie) as Denumire_functie, '' as Marca, '' as Nume, 
		max(functie_cor) as functie_cor, max(nivel_studii) as nivel_studii, sum((case when s.Ordine_grup=1 then s.numar_posturi else 0 end)), sum(numar_salariati), 
		sum(s.posturi_vacante), '' as tip_contract, '' as durata_contract, 0 as salar_de_incadrare, max(isnull(f.Pozitie_stat,@nrcrtmax)) as Pozitie_stat, 
		max(ordine_grup) as ordine_grup, 2 as nivel, max(niv)-1 as niv, rtrim(s.Loc_de_munca)+' '+rtrim(s.Cod_functie) as cod, s.Loc_de_munca as parinte
		from #stat_final s
			left join #functii_lm f on f.Loc_de_munca=s.Loc_de_munca and f.Cod_functie=s.Cod_functie
		group by s.Data, s.Loc_de_munca, s.Cod_functie
	end

	set @i=(select max(nivel) from #lm)
	select @nrcrtmax=max(numar_curent) from #stat_final
	while @i>-1 and @grupare='L'	--	generare totaluri pe locuri de munca de nivel superior (inclusiv Total general)
	begin
		select @nrcrtmax=@nrcrtmax+1 from #stat_final
		insert into #stat_final (Data, Loc_de_munca, Denumire_lm, Cod_functie, Denumire_functie, Marca, Nume, functie_cor, nivel_studii, numar_posturi, numar_salariati, 
		posturi_vacante, tip_contract, durata_contract, salar_de_incadrare, numar_curent, ordine_grup, nivel, niv, cod, parinte)
		select Data, max(Loc_de_munca) as loc_de_munca, max(lm.Denumire) as Denumire_lm, max(Cod_functie) as Cod_functie, '' as Denumire_functie, '' as Marca, '' as Nume, 
		'' as functie_cor, '' as nivel_studii, sum(numar_posturi), sum(numar_salariati), 
		sum(posturi_vacante), '' as tip_contract, '' as durata_contract, 0 as salar_de_incadrare, isnull(convert(int,max(p.Valoare)),@nrcrtmax), max(ordine_grup), 
		3 as nivel, max(lm.nivel) as niv, max(isnull(lm.cod,'')) as cod, rtrim(max(isnull(lm.cod_parinte,''))) as parinte
		from #stat_final s
			left join #lm lm on lm.cod=s.parinte 
			left outer join proprietati p on p.Tip='LM' and p.Cod=s.Loc_de_munca and p.Cod_proprietate='ORDINESTAT' and p.Valoare<>''			
		where @i=lm.nivel and lm.cod is not null and s.nivel>1
		group by Data, isnull(lm.cod_parinte,''), s.parinte
	
		set @i=@i-1
	end

	if @grupare='F'	--	generare totaluri pe functii si total general
	begin
		select @nrcrtmax=max(numar_curent)+1 from #stat_final
		insert into #stat_final (Data, Loc_de_munca, Denumire_lm, Cod_functie, Denumire_functie, Marca, Nume, functie_cor, nivel_studii, numar_posturi, numar_salariati, 
			posturi_vacante, tip_contract, durata_contract, salar_de_incadrare, numar_curent, ordine_grup, nivel, niv, cod, parinte)
		select Data, '' as loc_de_munca, '' as denumire_lm, Cod_functie, max(Denumire_functie) as Denumire_functie, '' as Marca, '' as Nume, 
		max(functie_cor) as functie_cor, max(nivel_studii) as nivel_studii, sum((case when s.Ordine_grup=1 then numar_posturi else 0 end)), sum(numar_salariati), 
		sum(posturi_vacante), '' as tip_contract, '' as durata_contract, 0 as salar_de_incadrare, @nrcrtmax, max(ordine_grup) as ordine_grup, 
		2 as nivel, 1 as niv, Cod_functie as cod, '<T>' as parinte
		from #stat_final s
		group by Data, Cod_functie
	
		select @nrcrtmax=@nrcrtmax+1 from #stat_final
		insert into #stat_final (Data, Loc_de_munca, Denumire_lm, Cod_functie, Denumire_functie, Marca, Nume, functie_cor, nivel_studii, numar_posturi, numar_salariati, 
			posturi_vacante, tip_contract, durata_contract, salar_de_incadrare, numar_curent, ordine_grup, nivel, niv, cod, parinte)
		select Data, '' as Loc_de_munca, '' as denumire_lm, '<T>' as Cod_functie, 'Total' as Denumire_functie, '' as Marca, '' as Nume, '' as functie_cor, '' as nivel_studii, 
		sum(numar_posturi), sum(numar_salariati), sum(posturi_vacante), '' as tip_contract, '' as durata_contract, 0 as salar_de_incadrare, @nrcrtmax, max(ordine_grup) as ordine_grup, 
		2 as nivel, 0 as niv, '<T>' as cod, '' as parinte
		from #stat_final s
		where niv=1
		group by Data
	end

	select Data, Loc_de_munca, Denumire_lm, Cod_functie, Denumire_functie, nivel, niv, rtrim(cod) as cod, rtrim(parinte) as parinte, Marca, Nume, functie_cor, nivel_studii, 
		numar_posturi, numar_salariati, posturi_vacante, tip_contract, durata_contract, salar_de_incadrare, numar_curent, ordine_grup
	from #stat_final
	order by nivel, numar_curent, (case when @grupare='L' then cod else Functie_COR end)
end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapStatDeFunctii (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

if object_id('tempdb..#stat_functii') is not null drop table #stat_functii
if object_id('tempdb..#functii_lm') is not null drop table #functii_lm
if object_id('tempdb..#stat_final') is not null drop table #stat_final
if object_id('tempdb..#posturivacante') is not null drop table #posturivacante	

/*
	exec rapStatDeFunctii '03/01/2012', '03/31/2012', null, null, 0, null, 0, 'F', 0, null, 0
*/	
