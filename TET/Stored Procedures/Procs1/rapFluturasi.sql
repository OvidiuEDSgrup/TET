--***
create procedure rapFluturasi @datasus datetime, @locm char(20), @tip_stat varchar(30),
	@marci varchar(30), @functii varchar(30), @str_nivel varchar(40), @ordonare int = 2, @nrexemplare int=1
as 
begin
/*		PS/Fluturasi.rdl
declare @datasus datetime, @locm char(20),@tip_stat char(30), --@marci_str varchar(20),
	@marci varchar(30),@functii varchar(30),@str_nivel varchar(40)
select @datasus='2011-1-1', @marci='215'
--*/
set transaction isolation level read uncommitted
if object_id('tempdb..#neordonate') is not null drop table #neordonate
if object_id('tempdb..#cfgrapps') is not null drop table #cfgrapps
if object_id('tempdb..#sumecfg') is not null drop table #sumecfg
if object_id('tempdb..#brut') is not null drop table #brut
if object_id('tempdb..#stat') is not null drop table #stat
if object_id('tempdb..#stat1') is not null drop table #stat1
if object_id('tempdb..#tichete') is not null drop table #tichete

declare @maxRanduriPagina int
select @maxRanduriPagina=Val_numerica from par where Tip_parametru='PS' and Parametru in ('FLUTNRPAG')
if isnull(@maxRanduriPagina,0)=0
	set @maxRanduriPagina=78

declare @q_datajos datetime,@q_datasus datetime, @q_locm varchar(20), @q_tip_stat varchar(100),
	@q_marci varchar(300),@q_functii varchar(300), @q_str_nivel varchar(40), 
	@ImpozitTichete int, @tich_datajos datetime, @tich_datasus datetime,
	@spSistPrgLaOre int,		-- parametru pentru spor sistematic peste program calculat dupa ore introduse 
	@spSpecific varchar(100),	-- parametru pentru denumire spor specific
	@indCondTipSuma int			-- parametru pentru indemnizatie de conducere de tip suma
	
set @q_datajos=dateadd(d,1-day(@datasus),@datasus)
	set @q_datasus=dateadd(d,-1,dateadd(m,1,@q_datajos))
	set @q_locm=@locm
	set @q_tip_stat=@tip_stat set @q_marci=@marci set @q_functii=@functii set @q_str_nivel=@str_nivel
--	citesc perioada de impozitare a tichetelor pt. luna curenta
	set @ImpozitTichete=dbo.iauParLL(@q_datasus,'PS','DJIMPZTIC')
	set @tich_datajos=dbo.iauParLD(@q_datasus,'PS','DJIMPZTIC')
	set @tich_datasus=dbo.iauParLD(@q_datasus,'PS','DSIMPZTIC')
	if isnull(@tich_datajos,'01/01/1901')='01/01/1901'
		set @tich_datajos=@q_datajos
	if isnull(@tich_datasus,'01/01/1901')='01/01/1901'
		set @tich_datasus=@q_datasus
	select @spSistPrgLaOre=MAX(case when Parametru='SP-PR-ORE' then Val_logica else 0 end),
		@spSpecific=MAX(case when Parametru='SSPEC' then Val_alfanumerica else '' end),
		@indCondTipSuma=MAX(case when Parametru='INDC-SUMA' then Val_logica else 0 end)
	from par where Tip_parametru='PS' and Parametru in ('SP-PR-ORE','SSPEC','INDC-SUMA')
	
declare @i int, @niv int		
	set @i=(select max(nivel) from lm) set @niv=1

declare @q_utilizator varchar(20)
SET @q_utilizator = dbo.fIaUtilizator('')
IF @q_utilizator IS NULL
	RETURN -1

select e.marca as parinte,max(e.cod_functie) as cod_functie, max(regim_de_lucru) regim_de_lucru,max(p.proc_sist_prg) proc_sist_prg,
	avg(isnull(p.indice,1)) as indice, max(e.Spor_de_functie_suplimentara) Spor_de_functie_suplimentara
into #stat1
from (select e.cod_functie,e.marca,e.grupa_de_munca,e.loc_ramas_vacant,e.data_plec,e.loc_de_munca, 
	e.Spor_de_functie_suplimentara Spor_de_functie_suplimentara
		 from personal e 
		where (e.marca=@q_marci or @q_marci is null) and (e.cod_functie=@q_functii or @q_functii is null)
		--and charindex('|'+e.grupa_de_munca+'|',@q_gr_munca_str)<>0 
		and (e.loc_ramas_vacant=0 or e.data_plec>@q_datajos)
	) as e
	left join (select p.marca,p.loc_de_munca,max(isnull(regim_de_lucru,8)) as regim_de_lucru,max(isnull(p.Sistematic_peste_program,0)) proc_sist_prg,
					(select isnull(max(procent_corectie)/100, max(case p.tip_salarizare when 2 then r.norma_de_timp when 4 then r.norma_de_timp
		when 5 then (case when p.coeficient_acord=0 then 1 else p.coeficient_acord end) when 7 then p.coeficient_acord else 1 end))
		from corectii where tip_corectie_venit='l-' and data between @q_datajos and @q_datasus and marca=p.marca and loc_de_munca=p.loc_de_munca)
							as indice
					from pontaj p left join realcom r on p.marca=r.marca and p.data=r.data and p.loc_de_munca=r.loc_de_munca
						and 'PS'+rtrim(p.numar_curent)=r.numar_document left join comenzi c on c.comanda=r.comanda
					where p.data between @q_datajos and @q_datasus group by p.marca ,r.comanda,p.loc_de_munca
				) p on 
p.marca=e.marca		-- p
	where (e.marca=@q_marci or @q_marci is null) and (e.cod_functie=@q_functii or @q_functii is null)
	--and charindex('|'+e.grupa_de_munca+'|',@q_gr_munca_str)<>0 
	and (e.loc_ramas_vacant=0 or e.data_plec>@q_datajos)
	and (isnull(e.loc_de_munca,p.loc_de_munca) like rtrim(@q_locm)+'%' or @q_locm is null)
group by e.cod_functie,e.marca
order by e.cod_functie,e.marca		/**	Filtrarea */

update #stat1 set Spor_de_functie_suplimentara=0
	where exists(select 1 from par where Tip_parametru='PS' and parametru='SPFS-SUMA' and val_logica=1)

select max(t1.regim_de_lucru) regim_de_lucru,max(t1.proc_sist_prg) proc_sist_prg,
	t1.cod_functie,t1.parinte as marca,max(t1.indice) as indice, max(t1.Spor_de_functie_suplimentara) Spor_de_functie_suplimentara,
	count(1) as nr into #stat
	from #stat1 t1 inner join #stat1 t2 on t1.cod_functie>t2.cod_functie or (t1.cod_functie=t2.cod_functie and t1.parinte>=t2.parinte)
	group by t1.cod_functie,t1.parinte	/**Ordonarea fluturasilor*/
	
/*	pun in tabela temporara corectiile care s-au introdus ca si procent (diminuari-G, procent lucrat acord-L) */
select data, marca, sum(Diminuari) as diminuari, sum(Sp_salar_realizat) as sp_salar_realizat
into #brut
from brut b
where b.data between @q_datajos and @q_datasus
group by data, marca

/**	se preiau retinerile configurabile pe baza tabelei cfgRapPS - daca nu exista este creata*/

--if not exists (select 1 from sysobjects where name='cfgRapPS' and xtype='U')
	exec initcfgrapps
	
select grup, tip, subtipuri, denumire, ordine into #cfgrapps
from cfgrapps c where c.raport='rapFluturasi' --and denumire<>'' 
	or c.raport='' and 
	not exists (select 1 from cfgRapPS cc where cc.raport='rapFluturasi' and cc.grup=c.grup and cc.tip=c.tip)

declare @ret_pe_beneficiari int
set @ret_pe_beneficiari=0		/**	daca nu e pe beneficiari se vor lua denumirile subtipurilor de retineri din tipret*/
if exists (select 1 from #cfgRapPS where grup='R' and rtrim(isnull(subtipuri,''))<>''
		and charindex('|',subtipuri)<>len(subtipuri)			-->>  e pe beneficiari daca cel putin un camp retinere are beneficiar,
		and charindex('|',replace(subtipuri,'|,','  '))<len(subtipuri))		 -->> beneficiarul aflandu-se fie intre caracterele '|' si ',' 
	set @ret_pe_beneficiari=1
	--> se iau datele retinerilor (este necesar acest pas deoarece pot fi cu sau fara subtipuri)
	declare @ret_cu_subtipuri int
	set @ret_cu_subtipuri=isnull((select val_logica from par where Tip_parametru='PS' and parametru like 'subtipret'),0)
	select (case when @ret_pe_beneficiari=1 then b.denumire_beneficiar else t.Denumire end) as denumire,
					b.cod_beneficiar, b.Tip_retinere
		into #benret
			from tipret t left join benret	b on b.Tip_retinere=t.subtip
			where @ret_cu_subtipuri=1
			union all
	select  (case when @ret_pe_beneficiari=1 then b.denumire_beneficiar else t.Denumire_tip end) as denumire,
				b.cod_beneficiar, b.Tip_retinere
			from  dbo.fTip_retineri(1) t left join benret	b on b.Tip_retinere=t.Tip_retinere
			where @ret_cu_subtipuri=0
	
select isnull(c.grup,'R') grup, r.marca,		/**	retineri salarii configurabile	*/
	max(rtrim(ltrim(case when c.ordine is null then '<Alte ret>' when len(c.denumire)>1 then c.denumire else
				b.Denumire end))) as denumire,
--	'R'+isnull(convert(varchar(10),c.ordine),'Alte') 
					/**	daca se vrea dinamic la nivel de marca, se foloseste linia de mai jos ca "ordine", altfel cea de deasupra */
--		'R0'+--(case when c.ordine is null then 'Alte' else 
			convert(varchar(10),row_number() over (partition by marca order by isnull(ordine,1000)))-- end)
		   ordine, 
		sum(r.retinut_la_lichidare) as suma, isnull(max(c.ordine),1000) as ordin into #sumecfg
		from resal r left join #benret b on b.Cod_beneficiar=r.Cod_beneficiar
		left join #cfgRapPS c on (@ret_pe_beneficiari=0 and rtrim(b.Tip_retinere)+'|'=rtrim(c.subtipuri) or 
				@ret_pe_beneficiari=1 and charindex(','+rtrim(b.Tip_retinere)+'|'+rtrim(b.Cod_beneficiar)+',',','+rtrim(c.subtipuri)+',')>0)
			and c.grup='R'
 where r.data between @q_datajos and @q_datasus and (@q_marci is null or marca=@q_marci)
	group by r.marca, c.tip, c.subtipuri, c.ordine,c.grup
union all

select isnull(c.grup,'SP') ,r.marca,	/**	sume sporuri configurabile	*/
		max(rtrim(ltrim(case when c.ordine is null then '<Alte sp>' when len(isnull(c.denumire,''))>1 then c.denumire else
				isnull(p.val_alfanumerica,'<Sp'+right(r.coloana,1)+'>') end))) as denumire,
	convert(varchar(10),row_number() over (partition by marca order by isnull(ordine,1000))-1)
	--max(convert(varchar(20),(case when r.coloana='Spor_specific' then 0 else right(r.coloana,1) end)))
	 ordine,
	sum(r.suma), isnull(c.ordine+1,1000) as ordin from
(
select b.marca, b.Spor_specific, b.Spor_cond_1, b.Spor_cond_2, b.Spor_cond_3, b.Spor_cond_4, b.Spor_cond_5, b.Spor_cond_6, b.Spor_cond_7, b.Spor_cond_8
from brut b inner join #stat p on b.Marca=p.marca
	where b.Data between @q_datajos and @q_datasus) r
unpivot (suma for coloana in (Spor_specific, Spor_cond_1, Spor_cond_2, Spor_cond_3, Spor_cond_4, Spor_cond_5, 
	Spor_cond_6, Spor_cond_7, Spor_cond_8)) r 
	left join #cfgrapps c on (c.tip=0 and r.coloana='Spor_specific' or c.tip=right(r.coloana,1))
			and c.grup='SP'
	left join par p on p.tip_parametru='PS' and (parametru='SSPEC' and r.coloana='Spor_specific' 
					or parametru like 'SCOND%' and len(rtrim(parametru))=6 and right(rtrim(parametru),1)=right(r.coloana,1) and Val_alfanumerica<>'')
	where abs(suma)>0 --and (@q_marci is null or marca=@q_marci)
group by r.marca, c.tip, c.subtipuri, c.ordine,c.grup
union all

select isnull(c.grup,'SP') ,r.marca,	/**	procente sporuri configurabile	*/
		'' as denumire,
	'PR0'+convert(varchar(10),row_number() over (partition by marca order by isnull(ordine,1000))-1)
	--max(convert(varchar(20),(case when r.coloana='Spor_specific' then 0 else right(r.coloana,1) end)))
	 ordine,
--	Lucian 26.09.2012: - am inlocuit sum cu max pt. a nu insuma procentele in cazul pontajelor pe marca multe locuri de munca
--	sum(case when p.tip_parametru is null then 0 else r.suma end) from
	max(case when p.tip_parametru is null then 0 else r.suma end), isnull(c.ordine+1,1000) as ordin from
(
select p.marca, p.Spor_specific, p.spor_conditii_1, p.spor_conditii_2, p.spor_conditii_3, p.spor_conditii_4, p.spor_conditii_5, p.spor_conditii_6, p.spor_cond_7
from pontaj p inner join #stat s on s.Marca=p.marca
	where p.Data between @q_datajos and @q_datasus) r
unpivot (suma for coloana in (Spor_specific, spor_conditii_1, spor_conditii_2, spor_conditii_3, spor_conditii_4, spor_conditii_5, 
		spor_conditii_6, spor_cond_7)) r 
	left join #cfgrapps c on (c.tip=0 and r.coloana='Spor_specific' or c.tip=right(r.coloana,1))
			and c.grup='SP'
	left join par p on (substring(p.parametru,3,1)=right(r.coloana,1) and p.Tip_parametru='PS' and p.Parametru like 'sc%-suma' and len(parametru)=8 and Val_logica=0)
					or (r.coloana='Spor_specific' and p.Tip_parametru='PS' and p.Parametru like 'SSP-SUMA' and len(parametru)=8 and Val_logica=0)
					or (r.coloana='Spor_cond_7' and p.Tip_parametru='PS' and p.Parametru like 'SCOND7' and p.val_alfanumerica<>'')
	where abs(suma)>0 --and (p.tip_parametru is not null)
group by r.marca, c.tip, c.subtipuri, c.ordine,c.grup
union all

select isnull(c.grup,'SP') ,r.marca,	/**	ore sporuri configurabile	*/
		'' as denumire,
--	Lucian: 17.01.2013 decrementat cu -1 ordinea si pt. ore similar cu procentele daca spor specific nu este configurat. 
--	Poate ar trebui tratat ca la stat de plata. Acolo e facut altfel
	'OR0'+convert(varchar(10),row_number() over (partition by marca order by isnull(ordine,1000))-(case when @spSpecific='' then 1 else 0 end))
	 ordine,
	sum(case when p.tip_parametru is null then 0 else r.suma end), isnull(c.ordine+1,1000) as ordin from
(
select p.marca, p.Ore__cond_1, p.Ore__cond_2, p.Ore__cond_3, p.Ore__cond_4, p.Ore__cond_5
from pontaj p inner join #stat s on s.Marca=p.marca
	where p.Data between @q_datajos and @q_datasus) r
unpivot (suma for coloana in (Ore__cond_1, Ore__cond_2, Ore__cond_3, Ore__cond_4, Ore__cond_5)) r 
	left join #cfgrapps c on (c.tip=right(r.coloana,1))
			and c.grup='SP'
	left join par p on (substring(p.parametru,6,1)=right(r.coloana,1) and p.Tip_parametru='PS' and p.Parametru like 'SCOND%' and len(parametru)=6 and Val_logica=1)
	where abs(suma)>0 --and (p.tip_parametru is not null)
group by r.marca, c.tip, c.subtipuri, c.ordine,c.grup

union all
		/**	corectii CR= retineri, CV=venituri:	*/
			-->> cazul corectiilor fara subtipuri
select isnull(c.grup,(case when t.Tip_corectie_venit in ('M-','C-','E-','Q-','P-') then 'CR' else 'CV' end)) ,r.marca,
		max(rtrim(ltrim(case when c.ordine is null then '<Alte cr.r.>' when len(isnull(c.denumire,''))>1 then c.denumire else
				t.Denumire end))) as denumire,
	--isnull(c.grup,(case when t.Tip_corectie_venit in ('M-','C-','E-','Q-','P-') then 'CR' else 'CV' end))+
		convert(varchar(10),row_number() over (partition by r.marca,
		isnull(c.grup,(case when t.Tip_corectie_venit in ('M-','C-','E-','Q-','P-') then 'CR' else 'CV' end)) order by isnull(ordine,1000)))
	 ordine,
		sum((case when r.Tip_corectie_venit='L-' then b.sp_salar_realizat when r.Tip_corectie_venit='G-' then b.diminuari else r.Suma_corectie end)),
		isnull(c.ordine,1000) as ordin
	from corectii r inner join #stat s on s.Marca=r.marca
		left join tipcor t on t.Tip_corectie_venit=r.Tip_corectie_venit
		left join #cfgrapps c on charindex(','+rtrim(t.Tip_corectie_venit)+',',','+rtrim(c.subtipuri)+',')>0
				and c.grup in ('CR','CV')
		left outer join #brut b on b.Marca=r.Marca
	where (abs(Suma_corectie)>0 or Procent_corectie<>0) --and (p.tip_parametru is not null)
		and r.Data between @q_datajos and @q_datasus
		and not exists (select 1 from par where Tip_parametru='PS' and parametru='subtipcor' and Val_logica=1)
group by r.marca, c.tip, c.subtipuri, c.ordine,isnull(c.grup,(case when t.Tip_corectie_venit in ('M-','C-','E-','Q-','P-') then 'CR' else 'CV' end))
union all	-->> cazul corectiilor pe subtipuri
select isnull(c.grup,(case when t.Tip_corectie_venit in ('M-','C-','E-','Q-','P-') then 'CR' else 'CV' end)) ,r.marca,
		max(rtrim(ltrim(case when c.ordine is null then '<Alte cr.r.>' when len(isnull(c.denumire,''))>1 then c.denumire else
				t.Denumire end))) as denumire,
	--isnull(c.grup,(case when t.Tip_corectie_venit in ('M-','C-','E-','Q-','P-') then 'CR' else 'CV' end))+
		convert(varchar(10),row_number() over (partition by r.marca,
				isnull(c.grup,(case when t.Tip_corectie_venit in ('M-','C-','E-','Q-','P-') then 'CR' else 'CV' end)) order by isnull(ordine,1000)))
	 ordine,
		sum((case when t.Tip_corectie_venit='L-' then b.sp_salar_realizat when t.Tip_corectie_venit='G-' then b.diminuari else r.Suma_corectie end)),
		isnull(c.ordine,1000) as ordin
	from corectii r inner join #stat s on s.Marca=r.marca
		left join subtipcor t on t.Subtip=r.Tip_corectie_venit
		--left join tipcor t on t.Tip_corectie_venit=r.Tip_corectie_venit
		left join #cfgrapps c on charindex(','+rtrim(t.Subtip)+',',','+rtrim(c.subtipuri)+',')>0
				and c.grup in ('CR','CV')
		left outer join #brut b on b.Marca=r.Marca				
	where (abs(Suma_corectie)>0 or Procent_corectie<>0) --and (p.tip_parametru is not null)
		and r.Data between @q_datajos and @q_datasus
		and exists (select 1 from par where Tip_parametru='PS' and parametru='subtipcor' and Val_logica=1)
group by r.marca, c.tip, c.subtipuri, c.ordine,isnull(c.grup,(case when t.Tip_corectie_venit in ('M-','C-','E-','Q-','P-') then 'CR' else 'CV' end))
order by r.marca, ordine

		/**	se rearanjeaza datele astfel incat sa nu fie pauza in fluturas intre corectii si celelalte sume configurabile:	*/
update #sumecfg set denumire='<Alte cr.v.>' where grup='CV' and denumire='<Alte cr.r.>'

--select * from #sumecfg where grup='CR'
update s set ordine=convert(int,ordine)+convert(int,maxim)
from #sumecfg s, (select marca, max(ordine) maxim from #sumecfg x where grup='R' group by marca) x
	where s.grup='CR' and s.marca=x.marca
	
update s set ordine=convert(int,ordine)+convert(int,maxim)
from #sumecfg s, (select marca, max(ordine) maxim from #sumecfg x where grup='SP' and ordine not like 'PR%' and ordine not like 'OR%' group by marca) x
	where s.grup='CV' and s.marca=x.marca

update #sumecfg set ordine=(case when ordine<10 then 'R0' else 'R' end)+rtrim(ordine)
	where grup in ('R','CR')

update #sumecfg set ordine=(case when ordine<10 then 'SP0' else 'SP' end)+rtrim(ordine)
	where grup in ('SP','CV') and ordine not like 'PR%' and ordine not like 'OR%'

--	recodific orele pt. sporuri (daca o anumita persoana nu are toate sporurile si apre o decalare la suffix intre spor/procent/ore) cu suffixul sporului corespunzator
update ore set ordine=left(ore.ordine,2)+substring(sp.ordine,3,2)
from #sumecfg ore
		left outer join #sumecfg sp on sp.grup=ore.grup and sp.marca=ore.marca and sp.ordin=ore.ordin
	where ore.grup='SP' and ore.ordine like 'OR%' and substring(ore.ordine,3,2)<>substring(sp.ordine,3,2)

--	am apelat functia fTichete_de_masa pentru a citi separat tichetele de masa cuvenite si suplimentare
select @q_datasus as data_salar, Data, Marca, (case when tip_operatie='S' then 'S' else '' end) as tip_tichete, 
	sum((case when tip_operatie='R' then -1 else 1 end)*Nr_tichete) as numar_tichete, sum((case when tip_operatie='R' then -1 else 1 end)*valoare_tichete) as valoare_tichete
into #tichete
from fTichete_de_masa (@tich_datajos, @tich_datasus, @q_Marci, '', '1', 0, 0, null, @q_locm, 0, null, null, 'T', '', '', 0)
group by Data, Marca, (case when tip_operatie='S' then 'S' else '' end)
/*
select c.* from #sumecfg c
where grup in ('CR','R','sp','cv')
--order by marca,grup desc*/
--select marca,suma,ordine from #sumecfg
	/**	datele propriu-zie*/
select rtrim(isnull(e.nume,'')) as nume,
	rtrim(isnull(lm.denumire,'')) as nume_lm, rtrim(isnull(f.denumire,'')) as nume_functie, 
	rtrim(isnull(s.regim_de_lucru,8)) as regim_de_lucru,
	rtrim(isnull(e.marca,'')) as marca, 
	rtrim(e.loc_de_munca) as loc_de_munca,
	rtrim(isnull(e.cod_functie,'')) as functia,
	rtrim(isnull(e.spor_vechime,0)) as proc_spor_vechime,
	isnull(e.salar_de_incadrare,0) as sal_tarif,
	(isnull(b.ore_lucrate,0))/isnull(s.regim_de_lucru,8) as zi_lu,
	(isnull(b.ore_acord,0))/isnull(s.regim_de_lucru,8) as zi_acord,
	isnull(b.Ore_concediu_de_odihna,0)/isnull(s.regim_de_lucru,8)	as zi_co,		--	(isnull(c.zile_co,0)) 
	isnull(b.Ore_obligatii_cetatenesti,0)/isnull(s.regim_de_lucru,8) as zi_ev,		--	(isnull(c.zile_ev,0)) 
	convert(float,isnull(m.Zile_cm_unitate,0)) as zi_bo, --isnull(convert(float,b.Ore_concediu_medical),0)/isnull(s.regim_de_lucru,8) as zi_bo,	--isnull(convert(float,m.zile_cu_reducere),0)
	convert(float,isnull(m.Zile_cm_fonduri,0)) as zi_bs, --isnull(b.CMCAS,0)/isnull(s.regim_de_lucru,8) as zi_bs, --convert(float,(isnull(m.zile_lucratoare,0)-isnull(m.zile_cu_reducere,0)))
	isnull(b.ore_concediu_fara_salar,0)/isnull(s.regim_de_lucru,8) as zi_cfs,
	isnull(b.ore_nemotivate,0)/isnull(s.regim_de_lucru,8) as zi_ne,
	isnull(b.Ore_lucrate,0) as ore_lucrate,
	isnull(b.ore_acord,0) as ore_acord,
	isnull(s.indice,1) as indice,
	(case when @indCondTipSuma=1 or e.Indemnizatia_de_conducere=0 then '' else convert(varchar(10),isnull(e.Indemnizatia_de_conducere,0))+'%' end) as proc_ind_cond,
	isnull(b.Indemnizatia_de_conducere,0) as ind_cond_suma,
	isnull(b.total_salar,0) as total_salar,
	isnull(b.realizat_acord,0) as realizat_acord,
	isnull(b.Ind_concediu_de_odihna,0) as ind_co, --	isnull(c.ind_co,0)
	isnull(b.Ind_obligatii_cetatenesti,0) as ind_ev,		--	isnull(c.ind_ev,0)
	isnull(b.Ind_c_medical_unitate,0) as suma_bo,
	isnull(b.Ind_c_medical_CAS,0) as suma_bs,	--isnull(m.indemnizatie_cas,0)
-----------------
	isnull(b.ore_suplimentare_1,0) as suplCM_ore,	--	isnull(p.ore_suplim_cm,0)
	isnull(b.Indemnizatie_ore_supl_1,0) as suplCM_suma,
	isnull(b.Ore_suplimentare_2,0) as suplM_ore,	--	isnull(p.ore_suplim_m,0)
	isnull(b.Indemnizatie_ore_supl_2,0) as suplM_suma,
	isnull(b.Ore_suplimentare_3,0) as supl3_ore,	--	isnull(p.ore_suplim_m,0)
	isnull(b.Indemnizatie_ore_supl_3,0) as supl3_suma,
	isnull(b.Ore_suplimentare_4,0) as supl4_ore,	--	isnull(p.ore_suplim_m,0)
	isnull(b.Indemnizatie_ore_supl_4,0) as supl4_suma,
	isnull(b.Ore_spor_100,0) as sp100_ore,			--	isnull(p.ore_spor_100,0)
	isnull(b.Indemnizatie_ore_spor_100,0) as sp100_suma,
	isnull(e.Spor_de_noapte,0) as noapte_proc, 
	isnull(b.ore_de_noapte,0) as noapte_ore, isnull(b.ind_ore_de_noapte,0) as noapte_suma,
	isnull(b.Ore_intrerupere_tehnologica,0)-isnull(po.ore_intrerupere_tehnologica_2,0) ore_intr_tehn_1,
	round(isnull(b.Ind_intrerupere_tehnologica_1,0),0) ind_intr_tehn_1,
	isnull(po.ore_intrerupere_tehnologica_2,0) ore_intr_tehn_2,
	round(isnull(b.ind_intrerupere_tehnologica_2,0),0) ind_intr_tehn_2,
	isnull(s.proc_sist_prg,0) as proc_sist_prg,
	isnull(po.Ore_sistematic_peste_program,0) as ore_sist_prg,
	isnull(b.Spor_sistematic_peste_program,0) as sist_prg_suma,		--(ok)
	isnull(b.spor_vechime,0) sp_vech_suma,
	isnull(b.venit_brut,0) as venit_brut,
	isnull(n.ret_CAS,0) as ret_CAS,
	isnull(n.somaj_1,0) as ret_somaj,
	isnull(n.CASS,0) as CASS,n.ded as deduceri,
	isnull(b.diminuari,0) as diminuari,
	isnull(b.restituiri,0) as restituiri,
	isnull(b.Suma_impozabila,0) as corectii,	--isnull(cr.corectii,0) 
	isnull(n.Baza_impozit,0)  as Baza_impozit,
	isnull(n.impozit,0)  as impozit,
	isnull(n.venit_net,0)  as venit_net,
	isnull(n.avans,0) as avans,
	isnull(n.rest_de_plata,0) as cuvenit_net,
	isnull(b.premiu,0) as premiu,	--(isnull(cr.cor_prem,0)+ISNULL(n.avans_premiu,0))
--	Lucian: am pus sa nu ia in calcul suma_incasata din tabela net intrucat se ia in considerare la partea de CR= retineri, corectia tip M-.
	/*isnull(n.suma_incasata,0)*/0 suma_incasata,
	isnull(n.premiu_la_avans,0) premiu_la_avans,
	isnull(s.Spor_de_functie_suplimentara,0) as proc_fct_suplim,
	isnull(b.Spor_de_functie_suplimentara,0) suma_fct_suplim,
					isnull(sc.R01,0) R01,				-->> retinerile (inclusiv corectiile)
					isnull(sc.R02,0) R02,
					isnull(sc.R03,0) R03,
					isnull(sc.R04,0) R04,
					isnull(sc.R05,0) R05,
					isnull(sc.R06,0) R06,
					isnull(sc.R07,0) R07,
					isnull(sc.R08,0) R08,
					isnull(sc.R09,0) R09,
					isnull(sc.R10,0) R10,
					isnull(sc.R11,0) R11,
					isnull(sc.R12,0) R12,
					isnull(sc.R13,0) R13,
					isnull(sc.R14,0) R14,
					isnull(sc.R15,0) R15,
					isnull(densc.R01,0) DR01,
					isnull(densc.R02,0) DR02,
					isnull(densc.R03,0) DR03,
					isnull(densc.R04,0) DR04,
					isnull(densc.R05,0) DR05,
					isnull(densc.R06,0) DR06,
					isnull(densc.R07,0) DR07,
					isnull(densc.R08,0) DR08,
					isnull(densc.R09,0) DR09,
					isnull(densc.R10,0) DR10,
					isnull(densc.R11,0) DR11,
					isnull(densc.R12,0) DR12,
					isnull(densc.R13,0) DR13,
					isnull(densc.R14,0) DR14,
					isnull(densc.R15,0) DR15,
					isnull(sc.SP00,0) SP00,				-->> sporurile (inclusiv corectiile)
					isnull(sc.SP01,0) SP01,
					isnull(sc.SP02,0) SP02,
					isnull(sc.SP03,0) SP03,
					isnull(sc.SP04,0) SP04,
					isnull(sc.SP05,0) SP05,
					isnull(sc.SP06,0) SP06,
					isnull(sc.SP07,0) SP07,
					isnull(sc.SP08,0) SP08,
					isnull(sc.SP09,0) SP09,
					isnull(sc.SP10,0) SP10,
					isnull(sc.SP11,0) SP11,
					isnull(sc.SP12,0) SP12,
					isnull(sc.SP13,0) SP13,
					isnull(sc.SP14,0) SP14,
					isnull(densc.SP00,'')+(case when sc.OR00<>0 then ' '+isnull(rtrim(convert(char(10),sc.PR00)),'')+'%' else '' end) DSP00,
					isnull(densc.SP01,'')+(case when sc.OR01<>0 then ' '+isnull(rtrim(convert(char(10),sc.PR01)),'')+'%' else '' end) DSP01,
					isnull(densc.SP02,'')+(case when sc.OR02<>0 then ' '+isnull(rtrim(convert(char(10),sc.PR02)),'')+'%' else '' end) DSP02,
					isnull(densc.SP03,'')+(case when sc.OR03<>0 then ' '+isnull(rtrim(convert(char(10),sc.PR03)),'')+'%' else '' end) DSP03,
					isnull(densc.SP04,'')+(case when sc.OR04<>0 then ' '+isnull(rtrim(convert(char(10),sc.PR04)),'')+'%' else '' end) DSP04,
					isnull(densc.SP05,'')+(case when sc.OR05<>0 then ' '+isnull(rtrim(convert(char(10),sc.PR05)),'')+'%' else '' end) DSP05,
					isnull(densc.SP06,'') DSP06,
					isnull(densc.SP07,'') DSP07,
					isnull(densc.SP08,'') DSP08,
					isnull(densc.SP09,'') DSP09,
					isnull(densc.SP10,'') DSP10,
					isnull(densc.SP11,'') DSP11,
					isnull(densc.SP12,'') DSP12,
					isnull(densc.SP13,'') DSP13,
					isnull(densc.SP14,'') DSP14,
					(case when isnull(sc.OR00,0)=0 then (case when sc.PR00<>0 then isnull(rtrim(convert(char(10),sc.PR00)),'')+'%' else '' end) else isnull(rtrim(convert(char(10),sc.OR00)),'') end) PR00,
					(case when isnull(sc.OR01,0)=0 then (case when sc.PR01<>0 then isnull(rtrim(convert(char(10),sc.PR01)),'')+'%' else '' end) else isnull(rtrim(convert(char(10),sc.OR01)),'') end) PR01,
					(case when isnull(sc.OR02,0)=0 then (case when sc.PR02<>0 then isnull(rtrim(convert(char(10),sc.PR02)),'')+'%' else '' end) else isnull(rtrim(convert(char(10),sc.OR02)),'') end) PR02,
					(case when isnull(sc.OR03,0)=0 then (case when sc.PR03<>0 then isnull(rtrim(convert(char(10),sc.PR03)),'')+'%' else '' end) else isnull(rtrim(convert(char(10),sc.OR03)),'') end) PR03,
					(case when isnull(sc.OR04,0)=0 then (case when sc.PR04<>0 then isnull(rtrim(convert(char(10),sc.PR04)),'')+'%' else '' end) else isnull(rtrim(convert(char(10),sc.OR04)),'') end) PR04,
					(case when isnull(sc.OR05,0)=0 then (case when sc.PR05<>0 then isnull(rtrim(convert(char(10),sc.PR05)),'')+'%' else '' end) else isnull(rtrim(convert(char(10),sc.OR05)),'') end) PR05,
					isnull(rtrim(convert(char(10),sc.PR06)),'')+'%' PR06,
					isnull(sc.OR00,0) OR00,
					isnull(sc.OR01,0) OR01,
					isnull(sc.OR02,0) OR02,
					isnull(sc.OR03,0) OR03,
					isnull(sc.OR04,0) OR04,
					isnull(sc.OR05,0) OR05,
	(select count(1) from persintr pi where pi.marca=s.marca and pi.data between @q_datajos and @q_datasus and pi.Coef_ded<>0) as nr_pers_intr,
	convert(int,isnull(t.Numar_tichete,0)) as nr_tichete, convert(decimal(10,1),isnull(t.Valoare_tichete,0)) as valt_tichete, 
	convert(int,isnull(ts.Numar_tichete,0)) as nr_tichete_supl, convert(decimal(10,1),isnull(ts.Valoare_tichete,0)) as valt_tichete_supl, 
	(case when @ordonare=3 then '' when @ordonare=1 then e.Loc_de_munca else e.Cod_functie end)+'|'+(case when @ordonare in (1,3) then e.Nume else e.marca end) as ordonare,
	convert(varchar(1000),'X') as separator_orizontal, --(case when num.nr_ret>num.nr_spor then num.nr_ret else num.nr_spor end) 
	0 randuri, 0 nr_rand, 0 as dublura
	into #neordonate		-- pentru impartirea pe pagini colectez datele in aceasta tabela temporara
from istpers e 
	inner join #stat s on s.marca=e.marca and isnull(rtrim(s.marca),'')<>'' and e.data=@q_datasus
	left join (select marca,sum((isnull(b.realizat__regie,0)+isnull(b.Salar_categoria_lucrarii,0))) as total_salar,
					sum(isnull(b.realizat_acord,0)) as realizat_acord, 
					sum(venit_total) as venit_brut,
					sum(isnull(ore_de_noapte,0)) as ore_de_noapte, sum(isnull(ind_ore_de_noapte,0)) as ind_ore_de_noapte,
					max(b.ind_nemotivate) as indemnizatia_de_conducere,
					sum(isnull(Ind_c_medical_unitate,0)) as Ind_c_medical_unitate,
					sum(b.spor_sistematic_peste_program) as spor_sistematic_peste_program,
					sum(b.Indemnizatie_ore_supl_1) as Indemnizatie_ore_supl_1,sum(b.Indemnizatie_ore_supl_2) as Indemnizatie_ore_supl_2, 
					sum(b.Indemnizatie_ore_supl_3) as Indemnizatie_ore_supl_3, sum(b.Indemnizatie_ore_supl_4) as Indemnizatie_ore_supl_4,
					sum(b.Indemnizatie_ore_spor_100) as Indemnizatie_ore_spor_100,
					sum(Ind_c_medical_CAS) Ind_c_medical_CAS,
					sum(Ore_lucrate__regie+Ore_lucrate_acord) as ore_lucrate,
					sum(Ore_lucrate_acord) as ore_acord,
					sum(Ore_concediu_de_odihna) Ore_concediu_de_odihna, sum(ore_concediu_fara_salar) ore_concediu_fara_salar,
					sum(Ore_concediu_medical) Ore_concediu_medical, 
					sum(cmunitate) cmunitate,
					sum(ore_nemotivate) as ore_nemotivate,
					sum(Ind_concediu_de_odihna) Ind_concediu_de_odihna,
					sum(ore_suplimentare_1) ore_suplimentare_1, sum(Ore_suplimentare_2) Ore_suplimentare_2, 
					sum(ore_suplimentare_3) ore_suplimentare_3, sum(Ore_suplimentare_4) Ore_suplimentare_4,
					sum(Ore_spor_100) Ore_spor_100,
					sum(Ore_intrerupere_tehnologica) ore_intrerupere_tehnologica,
					sum(Ind_intrerupere_tehnologica) ind_intrerupere_tehnologica_1,
					sum(Ind_invoiri) ind_intrerupere_tehnologica_2,
					sum(b.Diminuari) Diminuari,
					sum(Restituiri) Restituiri,
					sum(spor_vechime) spor_vechime,
					sum(b.Ore_obligatii_cetatenesti) Ore_obligatii_cetatenesti,
					sum(b.Ind_obligatii_cetatenesti) Ind_obligatii_cetatenesti,
					sum(b.CMCAS) CMCAS,
					sum(b.Suma_impozabila) Suma_impozabila,
					sum(b.premiu) premiu,
					sum(Spor_de_functie_suplimentara) Spor_de_functie_suplimentara
			from brut b where data between @q_datajos and @q_datasus group by b.marca) b on b.marca=e.marca			-- b
	left join (select m.Marca, sum(m.Zile_cu_reducere) as Zile_cm_unitate, sum(m.Zile_lucratoare-m.Zile_cu_reducere) as Zile_cm_fonduri
			from conmed m where m.data between @q_datajos and @q_datasus and m.Tip_diagnostic<>'0-' group by m.marca) m on m.Marca=e.Marca
	left join (select Marca, sum(Ore_sistematic_peste_program) as Ore_sistematic_peste_program, sum(Ore) ore_intrerupere_tehnologica_2
			from pontaj po where po.data between @q_datajos and @q_datasus group by po.marca) po on po.Marca=e.Marca and (@spSistPrgLaOre=1 or b.ore_intrerupere_tehnologica<>0)
	left join (select n.marca,max(n.pensie_suplimentara_3) as ret_CAS,
					max(n.ded_baza) as ded,
					max(case when day(n.Data)=1 then 0 else n.Asig_sanatate_din_net end) as CASS,
					max(n.Venit_baza) as Baza_impozit, max(n.impozit+n.Diferenta_impozit) as impozit, max(n.venit_net) as venit_net, sum(n.avans) as avans,
					sum(n.REST_DE_PLATA) as rest_de_plata,
					max(n.somaj_1) as somaj_1,
					sum(n.Suma_incasata) Suma_incasata,
					sum(n.Premiu_la_avans) Premiu_la_avans
				from net n where n.data between @q_datajos and @q_datasus group by n.marca) as n on n.marca=e.marca	-- n
	left join functii f on e.cod_functie=f.cod_functie left join lm on lm.cod=e.loc_de_munca
/*
	left join (select Marca, SUM(convert(decimal(12,2),
			(case when t.Tip_operatie='C' or t.Tip_operatie='P' or t.Tip_operatie='S' then Nr_tichete*Valoare_tichet else -Nr_tichete*Valoare_tichet end)
			)) as valt_tichete,
			sum((case when t.Tip_operatie='C' or t.Tip_operatie='P' or t.Tip_operatie='S' then Nr_tichete else -Nr_tichete end)
			) as nr_tichete from tichete t where Data_lunii between @tich_datajos and @tich_datasus
				group by marca) t on t.marca=e.marca
*/
--	am apelat functia pentru a citi fie din pontaj, fie din tichete
--	left join dbo.fNC_tichete (@tich_datajos, @tich_datasus, isnull(@q_Marci,''),1) t on t.marca=e.marca and t.Data=e.data
--	am apelat #tichete unde am pus separat tichetele cuvenite si cele suplimentare
	left join #tichete t on t.marca=e.marca and t.Data_salar=e.data and t.tip_tichete=''
	left join #tichete ts on ts.marca=e.marca and ts.Data_salar=e.data and ts.tip_tichete='S'
	left join (
		select * from (select marca,suma,ordine from #sumecfg) x
		pivot(sum(suma) 
		for ordine in (	[R01],[R02],[R03],[R04],[R05],[R06],[R07],[R08],[R09],		-- retineri
						[R10],[R11],[R12],[R13],[R14],[R15],							-- corectii retineri
					[SP00], [SP01], [SP02], [SP03], [SP04], [SP05], [SP06], [SP07], [SP08],	-- sume sporuri
					[SP09], [SP10], [SP11], [SP12], [SP13], [SP14],							-- corectii venituri
					[PR00], [PR01], [PR02], [PR03], [PR04], [PR05], [PR06],
					[OR00], [OR01], [OR02], [OR03], [OR04], [OR05])			-- procente sporuri
					--[CR1], [CR2], [CR3], [CR4], [CR5], [CR6],						
					--[CV1], [CV2], [CV3], [CV4], [CV5], [CV6])						
		) as pvt) sc on sc.marca=e.marca
	left join (
		select * from (select marca,denumire,ordine from #sumecfg) x
		pivot(max(denumire) 
		for ordine in ([R01],[R02],[R03],[R04],[R05],[R06],[R07],[R08],[R09],		-- retineri
						[R10],[R11],[R12],[R13],[R14],[R15],								-- corectii retineri
					[SP00], [SP01], [SP02], [SP03], [SP04], [SP05], [SP06], [SP07], [SP08],	-- sume sporuri
					[SP09], [SP10], [SP11], [SP12], [SP13], [SP14])							-- corectii venituri
		) as pvt) densc on densc.marca=e.marca
	where (e.marca=@q_marci or @q_marci is null) and (e.cod_functie=@q_functii or @q_functii is null)
	and (isnull(e.loc_de_munca,lm.cod) like rtrim(@q_locm)+'%' or @q_locm is null) --and (s.loc_ramas_vacant=0 or e.data_plec>@q_datajos)
	and (dbo.f_areLMFiltru(@q_utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@q_utilizator and l.cod=isnull(e.loc_de_munca,lm.cod)))

--	mutat aici SP-ul pentru a tine cont la numerotare pagini de eventuale randuri adaugate in SP
if exists (select 1 from sysobjects where name='rapFluturasiSP' and xtype='P')
	exec rapFluturasiSP @datasus, @locm, @tip_stat, @marci, @functii, @str_nivel, @ordonare, @nrexemplare

	/**	o mica numerotare a randurilor*/
update n set nr_rand=o.nr_rand
from #neordonate n, 
	(select row_number() over (order by ordonare) nr_rand, marca, dublura from #neordonate) o where n.marca=o.marca and n.dublura=o.dublura
	/**	numaram randurile care sunt vizibile in raport:	*/

update #neordonate set randuri=8+
	(case when abs(zi_lu)+abs(ore_lucrate)+abs((total_salar+realizat_acord)-(ind_cond_suma))+abs(ret_CAS)<0.000001 then 0 else 1 end)
	+(case when abs(indice)+abs(ret_somaj)<0.000001 then 0 else 1 end)
	+(case when abs(zi_co)+(zi_co*regim_de_lucru)+abs(ind_co)+abs(CASS)<0.000001 then 0 else 1 end)
	+(case when abs(zi_ev)+abs(zi_ev*regim_de_lucru)+abs(ind_ev)+abs(deduceri)<0.000001 then 0 else 1 end)
	+(case when abs(zi_bo)+abs(zi_bo*regim_de_lucru)+abs(suma_bo)+abs(baza_impozit)<0.000001 then 0 else 1 end)
	+(case when abs(zi_bs)+abs(zi_bs*regim_de_lucru)+abs(suma_bs)+abs(impozit)<0.000001 then 0 else 1 end)
	+(case when abs(zi_ne)+abs(zi_ne*regim_de_lucru)+abs(avans)<0.000001 then 0 else 1 end)
	+(case when abs(zi_cfs)+abs(zi_cfs*regim_de_lucru)+abs(suma_incasata)<0.000001 then 0 else 1 end)
	+(case when abs(ore_intr_tehn_1)+abs(premiu_la_avans)<0.000001 then 0 else 1 end)
	+(case when abs(ore_intr_tehn_2)+abs(R01)<0.000001 then 0 else 1 end)
	+(case when abs(ind_cond_suma)+abs(R02)<0.000001 then 0 else 1 end)
	+(case when abs(suplCM_ore)+abs(suplCM_suma)+abs(R03)<0.000001 then 0 else 1 end)
	+(case when abs(suplM_ore)+abs(suplM_suma)+abs(R04)<0.000001 then 0 else 1 end)
	+(case when abs((case when sp100_ore<>0 then sp100_ore else supl3_ore end))+abs((case when sp100_suma<>0 then sp100_suma else supl3_suma end))+abs(R05)<0.000001 then 0 else 1 end)
	+(case when abs(noapte_ore)+abs(noapte_ore)+abs(R06)<0.000001 then 0 else 1 end)
	+(case when abs(proc_sist_prg)+abs(sist_prg_suma)+abs(R07)<0.000001 then 0 else 1 end)
	+(case when abs(suma_fct_suplim)+abs(R08)<0.000001 then 0 else 1 end)
	+(case when abs((proc_spor_vechime))+abs(sp_vech_suma)+abs(R09)<0.000001 then 0 else 1 end)
	+(case when abs(SP00)+abs(R10)<0.000001 then 0 else 1 end)
	+(case when abs(SP01)+abs(R11)<0.000001 then 0 else 1 end)
	+(case when abs(SP02)+abs(R12)<0.000001 then 0 else 1 end)
	+(case when abs(SP03)+abs(R13)<0.000001 then 0 else 1 end)
	+(case when abs(SP04)+abs(R14)<0.000001 then 0 else 1 end)
	+(case when abs(SP05)+abs(R15)<0.000001 then 0 else 1 end)
	+(case when abs(SP06)<0.000001 then 0 else 1 end)
	+(case when abs(SP07)<0.000001 then 0 else 1 end)
	+(case when abs(SP08)<0.000001 then 0 else 1 end)
	+(case when abs(SP09)<0.000001 then 0 else 1 end)
	+(case when abs(SP10)<0.000001 then 0 else 1 end)
	+(case when abs(SP11)<0.000001 then 0 else 1 end)
	+(case when abs(SP12)<0.000001 then 0 else 1 end)
	+(case when abs(SP13)<0.000001 then 0 else 1 end)
	+(case when abs(SP14)<0.000001 then 0 else 1 end)
	+(case when abs(corectii)+abs(nr_tichete_supl)+abs(valt_tichete_supl)<0.000001 then 0 else 1 end)
	+(case when abs(diminuari)+abs(nr_tichete)+abs(valt_tichete)<0.000001 then 0 else 1 end)
	+(case when abs((venit_brut))+abs((cuvenit_net))<0.000001 then 0 else 1 end)

--	pus aici SP1 pentru a adaugat la randuri 3 pozitii (mai mult spatiu intre fluturasi la Angajatorul)
if exists (select 1 from sysobjects where name='rapFluturasiSP1' and xtype='P')
	exec rapFluturasiSP1 @datasus, @locm, @tip_stat, @marci, @functii, @str_nivel, @ordonare

	/**	se trece maximul de randuri pentru fiecare pereche de fluturasi care vor aparea in paralel	*/
update n set randuri=x.randuri
--,nr_rand=x.nr_rand
from #neordonate n inner join 
					(select max(randuri) randuri, nr_rand+1 + ((nr_rand) % 2)-1 as nr_rand
					from #neordonate n group by nr_rand+1 + ((nr_rand) % 2)) x
					on  n.nr_rand+1 + ((n.nr_rand) % 2)-1=x.nr_rand
--order by n.nr_rand*/

/**	Urmeaza fortarea trecerii la pagina noua - pentru a evita taierea fluturasilor;
	asta se realizeaza prin marirea spatiului dintre fluturasi, cu replace pe caracterul '|' in
	raportul propriu-zis	*/
declare @randuri int, @nr_rand int, @totalpagina int
set @totalpagina=0

declare _cr cursor for select max(randuri), nr_rand+1+ ((nr_rand) % 2)-1 from #neordonate group by nr_rand+1 + ((nr_rand) % 2) order by nr_rand+1 + ((nr_rand) % 2)
open _cr
fetch next from _cr into @randuri, @nr_rand
while (@@FETCH_STATUS=0)
begin
	if (@totalpagina+@randuri>@maxRanduriPagina) 
	begin
		update n set 
			separator_orizontal=rtrim(separator_orizontal)+replicate('|X',@maxRanduriPagina-@totalpagina)
			from #neordonate n where n.nr_rand+3 + ((n.nr_rand) % 2)-1=@nr_rand 
		set @totalpagina=0
	end
	set @totalpagina=@totalpagina+@randuri
	fetch next from _cr into @randuri, @nr_rand
end
close _cr
deallocate _cr

select --nr_rand, randuri,
	nume, nume_lm, nume_functie, regim_de_lucru, marca, loc_de_munca, functia, proc_spor_vechime, sal_tarif, zi_lu, zi_acord, zi_co, zi_ev, zi_bo, 
	zi_bs, zi_cfs, zi_ne, ore_lucrate, ore_acord, indice, proc_ind_cond, ind_cond_suma, total_salar+realizat_acord as total_salar, realizat_acord, ind_co, ind_ev, suma_bo, suma_bs, suplCM_ore, suplCM_suma, 
	suplM_ore, suplM_suma, supl3_ore, supl3_suma, supl4_ore, supl4_suma, sp100_ore, sp100_suma, noapte_proc, noapte_ore, noapte_suma, ore_intr_tehn_1, ind_intr_tehn_1, ore_intr_tehn_2, ind_intr_tehn_2, 
	proc_sist_prg, ore_sist_prg, sist_prg_suma, sp_vech_suma, venit_brut, ret_CAS, 
	ret_somaj, CASS, deduceri, diminuari, restituiri, corectii, baza_impozit, impozit, venit_net, avans, cuvenit_net, premiu, suma_incasata, premiu_la_avans, 
	proc_fct_suplim, suma_fct_suplim, R01, R02, R03, R04, R05, R06, R07, R08, R09, R10, R11, R12, R13, R14, R15, DR01, DR02, DR03, DR04, DR05, 
	DR06, DR07, DR08, DR09, DR10, DR11, DR12, DR13, DR14, DR15, SP00, SP01, SP02, SP03, SP04, SP05, SP06, SP07, SP08, SP09, SP10, SP11, SP12, 
	SP13, SP14, DSP00, DSP01, DSP02, DSP03, DSP04, DSP05, DSP06, DSP07, DSP08, DSP09, DSP10, DSP11, DSP12, DSP13, DSP14, 
	PR00, PR01, PR02, PR03, PR04, PR05, PR06, OR00, OR01, OR02, OR03, OR04, OR05, 
	nr_pers_intr, nr_tichete, valt_tichete, nr_tichete_supl, valt_tichete_supl, separator_orizontal
	from #neordonate
order by ordonare
--e.cod_functie,e.marca
if object_id('tempdb..#neordonate') is not null drop table #neordonate
if object_id('tempdb..#cfgrapps') is not null drop table #cfgrapps
if object_id('tempdb..#sumecfg') is not null drop table #sumecfg
if object_id('tempdb..#brut') is not null drop table #brut
if object_id('tempdb..#stat') is not null drop table #stat
if object_id('tempdb..#stat1') is not null drop table #stat1
if object_id('tempdb..#tichete') is not null drop table #tichete
end
