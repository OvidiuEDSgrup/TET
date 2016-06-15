--***
	--/*
create procedure rapStatDePlata(@datajos datetime, @datasus datetime, @locm char(20)=null,
	@marci varchar(30)=null, @functii varchar(30)=null, @cu_tabel bit=0, @grupare int=1, 
	@rettip int=0,	--> parametru ascuns in raport care determina nivelul de grupare (pe beneficiari/subtipuri/tipuri) al retinerilor
	@tipSalarizare char(1)=null, --> null-Toti salariatii, T-Tesa, M-Muncitori
	@istoric int=0,	-->	@istoric=0 pt. raportul Stat de plata; @istoric=1 pt. raportul Istoric salarizare
	@tipangajat char(1)=null, --> null-Toti angajatii, C-Colaboratori, S-Salariati
	@setlm varchar(20)=null,	-->	set de locuri de munca (proprietate TIPBALANTA)
	@sex int=null,	-->	null-Toate, 1-Masculin, 0-Feminin
	@activitate varchar(20)=null,	--> cod activitate din tabela personal
	@niveltotalizare int=null	-->	indica nivelul de loc de munca maxim la care se doreste centralizarea datelor
	)
as--*/
set transaction isolation level read uncommitted
declare @eroare varchar(2000)
begin try
/*
declare @maxSporuri varchar(10), @maxRetineri varchar(10)		/**	numarul maxim de date configurabile care au loc pt afisare in raport*/
select @maxSporuri='SP04', @maxRetineri='R07'
*/
declare @q_datajos datetime,@q_datasus datetime, @q_locm varchar(20),
	@q_marci varchar(300),@q_functii varchar(300),@q_grupare int, @q_centru varchar(1),
	@ImpozitTichete int, @tich_datajos datetime, @tich_datasus datetime, @q_tipSalarizare char(1), @q_tipangajat char(1)
set @q_datajos=dbo.bom(@datajos) set @q_datasus=dbo.eom(@datasus) set @q_locm=@locm 
	 set @q_marci=@marci set @q_functii=@functii set @q_tipSalarizare=@tipSalarizare 
	 set @q_tipangajat=@tipangajat
--	citesc perioada de impozitare a tichetelor pt. luna curenta
	set @ImpozitTichete=dbo.iauParLL(@q_datasus,'PS','DJIMPZTIC')
	set @tich_datajos=dbo.iauParLD(@q_datasus,'PS','DJIMPZTIC')
	set @tich_datasus=dbo.iauParLD(@q_datasus,'PS','DSIMPZTIC')
	if isnull(@tich_datajos,'01/01/1901')='01/01/1901'
		set @tich_datajos=@datajos
	if isnull(@tich_datasus,'01/01/1901')='01/01/1901'
		set @tich_datasus=@q_datasus
--select @tich_datajos, @tich_datasus
declare @i int, @niv int		
	set @niv=1

declare @unitbuget int, @dafora int, @regimlv int, @ore_luna int, @nrmedol float, @indcond_suma int, 
	@oresupl1 int, @oresupl2 int, @oresupl3 int, @oresupl4 int

select @unitbuget=val_logica from par where Parametru='unitbuget' and Tip_parametru='PS'
select @dafora=val_logica from par where Parametru='dafora'
select @regimlv=val_logica from par where Parametru='regimlv' and Tip_parametru='PS'
select @indcond_suma=val_logica from par where Parametru='indc-suma' and Tip_parametru='PS'
select @oresupl1=val_logica from par where Parametru='OSUPL1' and Tip_parametru='PS'
select @oresupl2=val_logica from par where Parametru='OSUPL2' and Tip_parametru='PS'
select @oresupl3=val_logica from par where Parametru='OSUPL3' and Tip_parametru='PS'
select @oresupl4=val_logica from par where Parametru='OSUPL4' and Tip_parametru='PS'
select @ore_luna=val_numerica from par_lunari where Parametru='ore_luna' and Tip='PS' and data=@datasus
select @nrmedol=val_numerica from par_lunari where Parametru='nrmedol' and Tip='PS' and data=@datasus

select @unitbuget=ISNULL(@unitbuget,0), @dafora=ISNULL(@dafora,0), @regimlv=isnull(@regimlv ,0)

declare @utilizator varchar(20)  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
SET @utilizator = dbo.fIaUtilizator('')
IF @utilizator IS NULL
	RETURN -1

if object_id('tempdb..#perTich') is not null drop table #perTich
if object_id('tempdb..#tichete') is not null drop table #tichete
create table #perTich (datalunii datetime, datajos datetime, datasus datetime)
insert into #perTich
select data_lunii, dbo.iauParLD(fc.data_lunii,'PS','DJIMPZTIC'), dbo.iauParLD(fc.data_lunii,'PS','DSIMPZTIC')
from fCalendar (@dataJos, @datasus) fc where data=data_lunii
create table #tichete (marca varchar(6), data_salar datetime, data datetime, numar_tichete int, valoare_tichete float)
declare @datalunii datetime, @dataImpozJos datetime, @dataImpozSus datetime
declare tmpTich cursor for
select datalunii, datajos, datasus
from #perTich

open tmpTich
fetch next from tmpTich into @Datalunii, @dataImpozJos, @dataImpozSus
While @@fetch_status = 0 
Begin
		insert into #tichete (marca, data_salar, data, numar_tichete, valoare_tichete)
		select marca, @Datalunii, data, numar_tichete, valoare_tichete from dbo.fNC_tichete (@dataImpozJos, @dataImpozSus, isnull(@q_Marci,''),1)
		fetch next from tmpTich into @Datalunii, @dataImpozJos, @dataImpozSus
End
 
 	/**	prin intermediu tabelei #personal se filtreaza informatiile*/
select i.data,p.loc_ramas_vacant,max(i.nume) as nume,max(p.cod_numeric_personal) as cod_numeric_personal,max(i.cod_functie) as cod_functie,
			max(i.marca) as marca,max(n.loc_de_munca) as loc_de_munca,max(i.spor_vechime) as spor_vechime,max(i.salar_de_incadrare) as salar_de_incadrare
			,max(i.Indemnizatia_de_conducere) as Indemnizatia_de_conducere
		,max(i.grupa_de_munca) as grupa_de_munca,max(i.data_plec) as data_plec,
		max(i.salar_de_baza/(168*(case when i.salar_lunar_de_baza=0 then 8 else i.salar_lunar_de_baza end)/8)) as salar_lunar,
		MAX(p.Salar_de_baza) as salar_de_baza1,MAX(p.Salar_lunar_de_baza) as salar_lunar_de_baza,MAX(p.Tip_salarizare) as Tip_salarizare,
		max(p.Spor_de_functie_suplimentara) Spor_de_functie_suplimentara
		into #personal
		from istpers i 
			left join personal p on i.marca=p.marca
			inner join net n on i.Data=n.Data and i.marca=n.marca			
		where (i.marca=@q_marci or @q_marci is null) and (i.cod_functie=@q_functii or @q_functii is null)
		--	and (p.loc_ramas_vacant=0 or p.data_plec>@q_datajos)	--> conditie scoasa pentru cei de la Arges cu plati retroactive
			and i.data between @q_datajos and @q_datasus
			and (@q_tipSalarizare is null or @q_tipSalarizare='T' and i.Tip_salarizare in ('1','2') or @q_tipSalarizare='M' and i.Tip_salarizare in ('3','4','5','6','7'))
			and (@q_tipangajat is null or @q_tipangajat='C' and i.Grupa_de_munca in ('P','O') or @q_tipangajat='S' and i.Grupa_de_munca in ('N','D','S','C'))
			and (@setlm is null or exists(select 1 from proprietati p where p.Cod_proprietate='TIPBALANTA' and p.Tip='LM' and p.Valoare=@setlm and rtrim(n.Loc_de_munca) like rtrim(p.cod)+'%'))
			and (@sex is null or p.sex=@sex)
			and (@activitate is null or p.Activitate=@activitate)
--			and i.Marca in ('585','25')
		group by i.Data, i.marca, p.loc_ramas_vacant		-- personal si exceptii
	--test	select * from #personal where marca=@q_marci
	/**	se elimina locurile de munca pentru care nu are drepturi utilizatorul sau care nu trebuie sa apara in statul de plata*/
delete p from #personal p where not ((p.loc_de_munca like rtrim(@q_locm)+'%' or @q_locm is null) 
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=p.loc_de_munca)))
		or exists( select 1 from proprietati pr where pr.tip='LM' and pr.Cod_proprietate='NUSTAT' and pr.valoare=1 and p.loc_de_munca=pr.Cod)

declare @nr_zile_lucr_luna int
set @nr_zile_lucr_luna=isnull((select max(p.val_numerica) as nr_zile_lucr_luna from par_lunari p
	where p.data between @q_datajos and @q_datasus and 
	p.parametru='ore_luna' and p.tip='PS'),168)

/**<cfgRapPS:	se preiau campurile configurabile pe baza tabelei cfgRapPS - daca nu exista este creata*/
begin

	--if not exists (select 1 from sysobjects where name='cfgRapPS' and xtype='U')
		exec initcfgrapps
	/** Pregatire configurare parte dinamica: */
			--> se iau denumirile sporurilor standard/generale
	select grup, tip, subtipuri, denumire, ordine into #cfgrapps
	from cfgrapps c where c.raport='rapStatDePlata' --and denumire<>'' 
		or c.raport='' and 
		not exists (select 1 from cfgRapPS cc where cc.raport='rapStatDePlata' and cc.grup=c.grup and (cc.grup='R' and cc.subtipuri=c.subtipuri or cc.grup<>'R' and cc.tip=c.tip))

	update c set c.denumire=n.nume
	from #cfgrapps c,
	(	select 'supl1' as subtipuri, isnull((select rtrim(Val_alfanumerica) from par where tip_parametru='PS' and parametru = 'osupl1'),'supl1') as nume
		union all
		select 'supl2' as subtipuri, isnull((select rtrim(Val_alfanumerica) from par where tip_parametru='PS' and parametru = 'osupl2'),'supl2') as nume
		union all
		select 'supl3' as subtipuri, isnull((select rtrim(Val_alfanumerica) from par where tip_parametru='PS' and parametru = 'osupl3'),'supl3') as nume
		union all
		select 'supl4' as subtipuri, isnull((select rtrim(Val_alfanumerica) from par where tip_parametru='PS' and parametru = 'osupl4'),'supl4') as nume
		union all
		select 'sist prg' as subtipuri, isnull((select rtrim(val_alfanumerica) as nume from par where tip_parametru='PS' and parametru='SPSISTPRG'),'Sist. prg.')
		union all
		select 'funct suplim' as subtipuri, isnull((select rtrim(val_alfanumerica) as nume from par where tip_parametru='PS' and parametru='SPFCTSUPL'),'Fct. supl.')
	) n
	 where c.grup='SG' and c.subtipuri=n.subtipuri and len(isnull(c.denumire,''))<=1
	 
	 update c set c.denumire=c.denumire+' '+n.procent
	 from #cfgrapps c, 
	 (	select 'supl1' as subtipuri, isnull((select rtrim(Val_numerica)+'%' from par where tip_parametru='PS' and parametru = 'osupl1'),'') as procent
		union all
		select 'supl2' as subtipuri, isnull((select rtrim(Val_numerica)+'%' from par where tip_parametru='PS' and parametru = 'osupl2'),'')
		union all
		select 'supl3' as subtipuri, isnull((select rtrim(Val_numerica)+'%' from par where tip_parametru='PS' and parametru = 'osupl3'),'')
		union all
		select 'supl4' as subtipuri, isnull((select rtrim(Val_numerica)+'%' from par where tip_parametru='PS' and parametru = 'osupl4'),'')
		union all
		select 'noapte',' 25%'
	)n where c.grup='SG' and c.subtipuri=n.subtipuri
	
	declare @ret_pe_beneficiari int
	set @ret_pe_beneficiari=0		/**	daca nu e pe beneficiari se vor lua denumirile subtipurilor de retineri din tipret*/
	if exists (select 1 from #cfgRapPS where grup='R' and rtrim(isnull(subtipuri,''))<>''
			and charindex('|',subtipuri)<>len(subtipuri)			-->>  e pe beneficiari daca cel putin un camp retinere are beneficiar,
			and charindex('|',replace(subtipuri,'|,','  '))<len(subtipuri))		 -->> beneficiarul aflandu-se fie intre caracterele '|' si ',' 
		set @ret_pe_beneficiari=1
		--> se iau datele retinerilor (este necesar acest pas deoarece pot fi cu sau fara subtipuri)
	declare @ret_cu_subtipuri int
	set @ret_cu_subtipuri=isnull((select val_logica from par where Tip_parametru='PS' and parametru like 'subtipret'),0)
	if (@rettip<>0) set @ret_cu_subtipuri=2
	select (case when @ret_pe_beneficiari=1 then b.denumire_beneficiar else t.Denumire end) as denumire,
					b.cod_beneficiar, b.Tip_retinere, c.tip+'|'+c.subtipuri+'|'+convert(varchar(20),c.ordine) as grupare, c.grup, c.ordine
		into #benret
			from tipret t left join benret	b on b.Tip_retinere=t.subtip
				left join #cfgRapPS c on (@ret_pe_beneficiari=0 and rtrim(b.Tip_retinere)+'|'=rtrim(c.subtipuri) or 
					@ret_pe_beneficiari=1 and charindex(','+rtrim(b.Tip_retinere)+'|'+rtrim(b.Cod_beneficiar)+',',','+rtrim(c.subtipuri)+',')>0)
				and c.grup='R'
			where @ret_cu_subtipuri=1
			union all
	select  (case when @ret_pe_beneficiari=1 then b.denumire_beneficiar else t.Denumire_tip end) as denumire,
				b.cod_beneficiar, b.Tip_retinere, c.tip+'|'+c.subtipuri+'|'+convert(varchar(20),c.ordine) as grupare, c.grup, c.ordine
			from  dbo.fTip_retineri(1) t left join benret	b on b.Tip_retinere=t.Tip_retinere
				left join #cfgRapPS c on (@ret_pe_beneficiari=0 and rtrim(b.Tip_retinere)+'|'=rtrim(c.subtipuri) or 
					@ret_pe_beneficiari=1 and charindex(','+rtrim(b.Tip_retinere)+'|'+rtrim(b.Cod_beneficiar)+',',','+rtrim(c.subtipuri)+',')>0)
				and c.grup='R'
			where @ret_cu_subtipuri=0
			union all
	select t.Denumire_tip, b.cod_beneficiar,b.tip_retinere, t.tip_retinere as grupare, c.grup, c.ordine
			from dbo.fTip_retineri(1) t
			left join  tipret ti on ti.Tip_retinere=t.Tip_retinere
			inner join benret b on b.Tip_retinere=ti.Subtip
			left join #cfgRapPS c on (@ret_pe_beneficiari=0 and rtrim(b.Tip_retinere)+'|'=rtrim(c.subtipuri) or 
					@ret_pe_beneficiari=1 and charindex(','+rtrim(b.Tip_retinere)+'|'+rtrim(b.Cod_beneficiar)+',',','+rtrim(c.subtipuri)+',')>0)
				and c.grup='R'
			where @ret_cu_subtipuri=2
	update b set ordine=bb.ordine 
		from #benret b inner join (select min(ordine) ordine, bb.grupare from #benret bb group by bb.grupare) bb on bb.grupare=b.grupare

--	pun in tabela temporara corectiile care s-au introdus ca si procent (diminuari-G, procent lucrat acord-L)
	select data, marca, sum(Diminuari) as diminuari, sum(Sp_salar_realizat) as sp_salar_realizat
	into #brut_corectii
	from brut b
	where b.data between @q_datajos and @q_datasus
	group by data, marca

	--test select * from #benret
	--select * from #cfgrapps c where c.grup='R'
	select r.data, isnull(c.grup,'R') grup, r.marca,		/**	retineri salarii configurabile	*/
		max(rtrim(ltrim(case	when c.ordine is null then '<Alte ret>'
								when @ret_cu_subtipuri=2 then c.denumire
								when len(c.denumire)>1 then c.denumire 
								else c.denumire end))) as denumire,
	--	'R'+isnull(convert(varchar(10),c.ordine),'Alte') 
						/**	daca se vrea dinamic la nivel de marca, se foloseste linia de mai jos ca "ordine", altfel cea de deasupra */
	--		'R0'+--(case when c.ordine is null then 'Alte' else 
				convert(varchar(10),row_number() over (partition by r.marca order by isnull(max(ordine),1000)))-- end)
			   as ordine,
			sum(r.retinut_la_lichidare) as suma, isnull(max(ordine),1000) as ordin into #sumecfg
		from resal r 
			inner join #personal p on r.data=p.data and r.marca=p.marca
			left join #benret c on c.Cod_beneficiar=r.Cod_beneficiar
		/*	left join #cfgRapPS c on (@ret_pe_beneficiari=0 and rtrim(b.Tip_retinere)+'|'=rtrim(c.subtipuri) or 
					@ret_pe_beneficiari=1 and charindex(','+rtrim(b.Tip_retinere)+'|'+rtrim(b.Cod_beneficiar)+',',','+rtrim(c.subtipuri)+',')>0)*/
				and c.grup='R'
	where r.data between @q_datajos and @q_datasus --and (@q_marci is null or marca=@q_marci)
		group by r.data, r.marca, --c.tip, c.subtipuri, 
			c.grupare, c.grup
	union all

	select r.data, isnull(c.grup,'SG') ,r.marca,	/**	sume sporuri standard configurabile	*/
			max(rtrim(ltrim(case when c.ordine is null then '<Alte sg>' else c.denumire end))) as denumire,
		convert(varchar(10),row_number() over (partition by marca order by isnull(ordine,1000))-1)
		--max(convert(varchar(20),(case when r.coloana='Spor_specific' then 0 else right(r.coloana,1) end)))
		 ordine,
		sum(r.suma), isnull(ordine,1000) as ordin from
	(
	select b.data, b.marca, b.ind_nemotivate [ind cond], b.Spor_vechime [spor vechime], b.Indemnizatie_ore_supl_1 [supl1], 
			b.Indemnizatie_ore_supl_2 [supl2], b.Indemnizatie_ore_supl_3 [supl3], 
			b.Indemnizatie_ore_supl_4 [supl4], b.Indemnizatie_ore_spor_100 [sp100%],
			b.Ind_ore_de_noapte [noapte], b.Spor_sistematic_peste_program [sist prg],
			b.Spor_de_functie_suplimentara [funct suplim]
	from brut b 
			inner join #personal p on b.data=p.data and b.Marca=p.marca
		where b.Data between @q_datajos and @q_datasus) r
	unpivot (suma for coloana in ([ind cond], [spor vechime], [supl1], [supl2], [supl3],
			[supl4], [sp100%], [noapte], [sist prg], [funct suplim])) r 
		left join #cfgrapps c on charindex(','+rtrim(r.coloana)+',',','+rtrim(c.subtipuri)+',')>0
				and c.grup='SG'
		where (abs(suma)>0 or r.coloana='supl1' and @oresupl1=1 and exists (select 1 from brut b1 where b1.Data=r.Data and b1.Ore_suplimentare_1<>0)
				or r.coloana='supl2' and @oresupl2=1 and exists (select 1 from brut b1 where b1.Data=r.Data and b1.Ore_suplimentare_2<>0)
				or r.coloana='supl3' and @oresupl3=1 and exists (select 1 from brut b1 where b1.Data=r.Data and b1.Ore_suplimentare_3<>0)
				or r.coloana='supl4' and @oresupl4=1 and exists (select 1 from brut b1 where b1.Data=r.Data and b1.Ore_suplimentare_4<>0))
			--and (@q_marci is null or marca=@q_marci)
	group by r.data, r.marca, c.tip, c.subtipuri, c.ordine, c.grup
	union all

	select dbo.eom(r.data), 'OG' grup ,r.marca,	/**	sume sporuri standard configurabile	*/
			max(rtrim(ltrim(case when c.ordine is null then '<Alte sg>' else c.denumire end))) as denumire,
		convert(varchar(10),row_number() over (partition by marca order by isnull(ordine,1000))-1)
		--max(convert(varchar(20),(case when r.coloana='Spor_specific' then 0 else right(r.coloana,1) end)))
		 ordine,
		sum(isnull(r.suma,0)), isnull(ordine,1000) as ordin from
	(
	select p.data, p.marca, p.ore_suplimentare_1 [supl1], 
			p.ore_suplimentare_2 [supl2], p.ore_suplimentare_3 [supl3], 
			p.ore_suplimentare_4 [supl4], p.ore_spor_100 [sp100%],
			p.ore_de_noapte [noapte], p.ore_sistematic_peste_program [sist prg]
	from pontaj p 
			inner join #personal s on dbo.eom(p.data)=s.data and p.Marca=s.marca
		where p.Data between @q_datajos and @q_datasus) r
	unpivot (suma for coloana in ([supl1], [supl2], [supl3],
			[supl4], [sp100%], [noapte], [sist prg])) r 
		left join #cfgrapps c on charindex(','+rtrim(r.coloana)+',',','+rtrim(c.subtipuri)+',')>0
				and c.grup='SG'
		where abs(suma)>0 --and (@q_marci is null or marca=@q_marci)
	group by dbo.eom(r.data), r.marca, c.tip, c.subtipuri, c.ordine, c.grup
	union all
	
	select r.data, 'PG' grup, r.marca,	/**	sume sporuri standard configurabile	*/
			max(rtrim(ltrim(case when c.ordine is null then '<Alte sg>' else c.denumire end))) as denumire,
		convert(varchar(10),row_number() over (partition by marca order by isnull(ordine,1000))-1)
		--max(convert(varchar(20),(case when r.coloana='Spor_specific' then 0 else right(r.coloana,1) end)))
		 ordine,
		max(isnull(r.suma,0)), isnull(ordine,1000) as ordin from
	(
	select dbo.eom(p.data) as data, p.marca, 
--	Lucian: am 	tratat procent pentru indemnizatia de conducere daca aceasta nu este de tip suma
		convert(decimal(10,2),max(isnull((case when @indcond_suma=0 then s.Indemnizatia_de_conducere else 0 end),0))) [ind cond],
		convert(decimal(10,2),max(s.Spor_vechime)) [spor vechime], 
--	Lucian: am 	lasat pt. ore spor 100%, procent=0 (este afisat in capul de tabel)
		convert(decimal(10,2),0/*sum(isnull(p.ore_spor_100,0))/convert(float,@nr_zile_lucr_luna)*/) [sp100%]
		,convert(decimal(10,2),max(isnull(p.Sistematic_peste_program,0))) [sist prg]
		,convert(decimal(10,2),max(isnull(s.Spor_de_functie_suplimentara,0))) [funct suplim]
	from pontaj p 
		inner join #personal s on s.data=dbo.eom(p.data) and p.Marca=s.marca
	where p.Data between @q_datajos and @q_datasus group by dbo.eom(p.data), p.marca) r
		unpivot (suma for coloana in ([ind cond], [spor vechime], --[supl1], [supl2], [supl3],[supl4], [noapte] ,
		[sp100%],[sist prg], [funct suplim]
		)) r 
		left join #cfgrapps c on charindex(','+rtrim(r.coloana)+',',','+rtrim(c.subtipuri)+',')>0
				and c.grup='SG'
		where abs(suma)>0
	group by r.data, r.marca, c.tip, c.subtipuri, c.ordine, c.grup
	union all
	
	select r.data, isnull(c.grup,'SP') ,r.marca,	/**	sume sporuri configurabile	*/
			max(rtrim(ltrim(case when c.ordine is null then '<Alte sp>' when len(isnull(c.denumire,''))>1 then c.denumire else
					isnull(p.val_alfanumerica,'<Sp'+right(r.coloana,1)+'>') end))) as denumire,
		convert(varchar(10),row_number() over (partition by marca order by isnull(ordine,1000))-1)
		 ordine,
		sum(r.suma), isnull(ordine+1,1000) as ordin from
	(
	select b.data, b.marca, b.Spor_specific, b.Spor_cond_1, b.Spor_cond_2, b.Spor_cond_3, b.Spor_cond_4, b.Spor_cond_5, b.Spor_cond_6, b.Spor_cond_7, b.Spor_cond_8
	from brut b 
		inner join #personal p on p.data=b.data and p.Marca=b.marca
	where b.Data between @q_datajos and @q_datasus) r
	unpivot (suma for coloana in (Spor_specific, Spor_cond_1, Spor_cond_2, Spor_cond_3, Spor_cond_4, Spor_cond_5, 
		Spor_cond_6, Spor_cond_7, Spor_cond_8)) r 
		left join #cfgrapps c on (c.tip=0 and r.coloana='Spor_specific' or c.tip=right(r.coloana,1))
				and c.grup='SP'
		left join par p on p.tip_parametru='PS' and (parametru='SSPEC' and r.coloana='Spor_specific' 
				or parametru like 'SCOND%' and len(rtrim(parametru))=6 and right(rtrim(parametru),1)=right(r.coloana,1) and Val_alfanumerica<>'')
		where abs(suma)>0--and (@q_marci is null or marca=@q_marci)
	group by r.data, r.marca, c.tip, c.subtipuri, c.ordine, c.grup
	union all

	select dbo.eom(r.data), 'PR' ,r.marca,	/**	procente sporuri configurabile	*/
			'' as denumire,
		convert(varchar(10),row_number() over (partition by marca order by isnull(ordine,1000))-1) ordine,
		max(case when p.tip_parametru is null then 0 else r.suma end), 
		isnull(ordine+1,1000) as ordin from
	(
	select p.data, p.marca, p.Spor_specific, p.spor_conditii_1, p.spor_conditii_2, p.spor_conditii_3, p.spor_conditii_4, p.spor_conditii_5, p.spor_conditii_6, p.spor_cond_7, p.Spor_cond_8
	from pontaj p 
			inner join #personal s on s.data=dbo.eom(p.data) and s.Marca=p.marca
		where p.Data between @q_datajos and @q_datasus) r
	unpivot (suma for coloana in (Spor_specific, spor_conditii_1, spor_conditii_2, spor_conditii_3, spor_conditii_4, spor_conditii_5, 
		spor_conditii_6, spor_cond_7, spor_cond_8)) r 
		left join #cfgrapps c on (c.tip=0 and r.coloana='Spor_specific' or c.tip=right(r.coloana,1)) 
				and c.grup='SP' 
		left join par p on (substring(p.parametru,3,1)=right(r.coloana,1) and p.Tip_parametru='Ps' and p.Parametru like 'sc%-suma' and len(parametru)=8 and Val_logica=0)
				or (r.coloana='Spor_specific' and p.Tip_parametru='Ps' and p.Parametru like 'SSP-SUMA' and len(parametru)=8 and Val_logica=0)
				or (r.coloana='Spor_cond_7' and p.Tip_parametru='PS' and p.Parametru like 'SCOND7' and p.val_alfanumerica<>'')
				or (r.coloana='Spor_cond_8' and p.Tip_parametru='PS' and p.Parametru like 'SCOND8' and p.val_alfanumerica<>'')
		where abs(suma)>0 --and (p.tip_parametru is not null)
	group by dbo.eom(r.data), r.marca, c.tip, c.subtipuri, c.ordine, c.grup
	union all

	select dbo.eom(r.data), 'OR', r.marca,	/**	ore sporuri configurabile	*/
			'' as denumire,
		convert(varchar(10),row_number() over (partition by marca order by isnull(ordine,1000))-1)
		 ordine,
		sum(r.suma), isnull(ordine+1,1000) as ordin from
	(
	select p.data, p.marca, p.Ore__cond_1, p.Ore__cond_2, p.Ore__cond_3, p.Ore__cond_4, p.Ore__cond_5
	from pontaj p 
			inner join #personal s on s.data=dbo.eom(p.data) and s.Marca=p.marca
		where p.Data between @q_datajos and @q_datasus) r
	unpivot (suma for coloana in (Ore__cond_1, Ore__cond_2, Ore__cond_3, Ore__cond_4, Ore__cond_5)) r 
		left join #cfgrapps c on (c.tip=0 and r.coloana='Spor_specific' or c.tip=right(r.coloana,1))
				and c.grup='SP'
		where abs(suma)>0
	group by dbo.eom(r.data), r.marca, c.tip, c.subtipuri, c.ordine, c.grup
	union all

			/**	corectii CR= retineri, CV=venituri:	*/
				-->> cazul corectiilor fara subtipuri
	select dbo.eom(r.data), isnull(c.grup,(case when r.Tip_corectie_venit in ('M-','C-','E-','Q-','P-') then 'CR' else 'CV' end)), r.marca, 
			max(rtrim(ltrim(case when c.ordine is null then '<Alte cr.r.>' when len(isnull(c.denumire,''))>1 then c.denumire else
					t.Denumire end))) as denumire,
			convert(varchar(10),row_number() over (partition by r.marca,
			isnull(c.grup,(case when r.Tip_corectie_venit in ('M-','C-','E-','Q-','P-') then 'CR' else 'CV' end)) order by isnull(ordine,1000))) ordine, 
			sum((case when r.Tip_corectie_venit='L-' then bc.sp_salar_realizat when r.Tip_corectie_venit='G-' then bc.diminuari else r.Suma_corectie end)), 
			isnull(ordine,1000) as ordin
		from corectii r 
			inner join #personal s on s.data=dbo.eom(r.data) and s.Marca=r.marca
			left join tipcor t on t.Tip_corectie_venit=r.Tip_corectie_venit
			left join #cfgrapps c on charindex(','+rtrim(r.Tip_corectie_venit)+',',','+rtrim(c.subtipuri)+',')>0 and c.grup in ('CR','CV')
			left outer join #brut_corectii bc on bc.Marca=r.Marca and bc.Data=dbo.eom(r.data)
		where (abs(Suma_corectie)>0 or Procent_corectie<>0)
			and r.Data between @q_datajos and @q_datasus
			and not exists (select 1 from par where Tip_parametru='PS' and parametru='subtipcor' and Val_logica=1)
	group by dbo.eom(r.data), r.marca, c.tip, c.subtipuri, c.ordine, isnull(c.grup,(case when r.Tip_corectie_venit in ('M-','C-','E-','Q-','P-') then 'CR' else 'CV' end))
	union all	-->> cazul corectiilor pe subtipuri

	select dbo.eom(r.data), isnull(c.grup,(case when t.Tip_corectie_venit in ('M-','C-','E-','Q-','P-') then 'CR' else 'CV' end)), r.marca,
			max(rtrim(ltrim(case when c.ordine is null then '<Alte cr.r.>' when len(isnull(c.denumire,''))>1 then c.denumire else
					t.Denumire end))) as denumire,
			convert(varchar(10),row_number() over (partition by r.marca,
					isnull(c.grup,(case when t.Tip_corectie_venit in ('M-','C-','E-','Q-','P-') then 'CR' else 'CV' end)) order by isnull(ordine,1000))) ordine,
			sum((case when t.Tip_corectie_venit='L-' then bc.sp_salar_realizat when t.Tip_corectie_venit='G-' then bc.diminuari else r.Suma_corectie end)), isnull(ordine,1000) as ordin
		from corectii r 
			inner join #personal s on s.data=dbo.eom(r.data) and s.Marca=r.marca
			left join subtipcor t on t.Subtip=r.Tip_corectie_venit
			left join #cfgrapps c on charindex(','+rtrim(t.Subtip)+',',','+rtrim(c.subtipuri)+',')>0 and c.grup in ('CR','CV')
			left outer join #brut_corectii bc on bc.Marca=r.Marca and bc.Data=dbo.eom(r.data)
		where (abs(Suma_corectie)>0 or Procent_corectie<>0)
			and r.Data between @q_datajos and @q_datasus
			and exists (select 1 from par where Tip_parametru='PS' and parametru='subtipcor' and Val_logica=1)
	group by dbo.eom(r.data), r.marca, c.tip, c.subtipuri, c.ordine, isnull(c.grup,(case when t.Tip_corectie_venit in ('M-','C-','E-','Q-','P-') then 'CR' else 'CV' end))
/*
	Lucian: afisare procent corectii pentru cazul corectiilor fara subtipuri si pt cele care intra in venitul brut
*/
	union all
	select dbo.eom(r.data), 'PV', r.marca, 
			max(rtrim(ltrim(case when c.ordine is null then '<Alte cr.r.>' when len(isnull(c.denumire,''))>1 then c.denumire else t.Denumire end))) as denumire,
			convert(varchar(10),row_number() over (partition by r.marca, 'PV' order by isnull(ordine,1000))) ordine, 
			max(r.Procent_corectie), 
			isnull(ordine,1000) as ordin
		from corectii r 
			inner join #personal s on s.data=dbo.eom(r.data) and s.Marca=r.marca
			left join tipcor t on t.Tip_corectie_venit=r.Tip_corectie_venit
			left join #cfgrapps c on charindex(','+rtrim(r.Tip_corectie_venit)+',',','+rtrim(c.subtipuri)+',')>0 and c.grup in ('CR','CV')
		where Procent_corectie<>0 
			and r.Data between @q_datajos and @q_datasus
			and not exists (select 1 from par where Tip_parametru='PS' and parametru='subtipcor' and Val_logica=1)
			and r.Tip_corectie_venit not in ('M-','C-','E-','Q-','P-')
	group by dbo.eom(r.data), r.marca, c.tip, c.subtipuri, c.ordine

	order by r.marca, r.data, ordine
	/**	re-ordonare date (astfel incat sa nu fie pauza in fluturas intre sumele configurabile): */


	-- test select * from #sumecfg --where grup in ('og','PG','SG','PR') order by grup, ordin
	update #sumecfg set denumire='<Alte cr.v.>' where grup='CV' and denumire='<Alte cr.r.>'
	update r set ordine=rr.ordine
	from #sumecfg r,
	(select grup, ordin, row_number() over (partition by grup order by ordin) ordine from #sumecfg group by grup, ordin)
		  rr 
		where r.ordin=rr.ordin and r.grup=rr.grup

	delete s from #sumecfg s where 
		not exists( select 1 from #sumecfg t where (/*t.grup='SG' and s.grup in ('PG','OG') or*/ t.grup='SP' and s.grup in ('PR','OR'))
				and s.ordin=t.ordin and s.marca=t.marca)
	and s.grup in ('PR','OR')

	/*
	update s set ordine=t.ordine from #sumecfg s, #sumecfg t where 
		(t.grup='SG' and s.grup in ('PG','OG') or t.grup='SP' and s.grup in ('PR','OR')) 
		and s.ordin=t.ordin and s.marca=t.marca --and s.grup in ('PR','OR')
	*/
	update s set ordine=t.ordine from #sumecfg s, (select ordine, ordin, grup from #sumecfg group by ordine, ordin, grup) t where 
		(t.grup='SG' and s.grup in ('PG','OG') or t.grup='SP' and s.grup in ('PR','OR') or t.grup='CV' and s.grup in ('PV')) 
		and s.ordin=t.ordin --and s.marca=t.marca --and s.grup in ('PR','OR')

	/**	unificare si ordonare sporuri standard cu sporuri specifice: */
	update s set ordine=convert(int,ordine)+isnull(convert(int,maxim),0)
	from #sumecfg s, (select max(ordine) maxim from #sumecfg x where grup in ('SG','PG','OG')) x
		where s.grup in ('SP','PR','OR')

	update s set grup='SP' from #sumecfg s where s.grup='SG'

	update r set r.ordine=r.ordine-1 from #sumecfg r where r.grup in ('PR','SP','OR','PG','SG','OG')
--	Lucian: 05.04.2012 pus isnull pe urmatoarele 2 update-uri pt. a se afisa corect coloanele de corectii
	update s set ordine=convert(int,ordine)+isnull(convert(int,maxim),0)
	from #sumecfg s, (select max(ordine) maxim from #sumecfg x where grup='R') x
		where s.grup='CR'

	update s set ordine=convert(int,ordine)+isnull(convert(int,maxim),0)
	from #sumecfg s, (select max(ordine) maxim from #sumecfg x where grup='SP' and ordine not like 'PR%') x
		where s.grup in ('CV','PV')
		--test	select distinct denumire, ordine, ordin from #sumecfg s where grup='R' order by s.ordine

	update #sumecfg set ordine=(case when ordine<10 then 'R0' else 'R' end)+rtrim(ordine)
		where grup in ('R','CR')

	update #sumecfg set ordine=(case when ordine<10 then 'SP0' else 'SP' end)+rtrim(ordine)
		where grup in ('SP','CV')

	--select * from #sumecfg where ordine like 'R%' and ordine>@maxRetineri
	/*

	if exists (select 1 from #sumecfg where ordine like 'r%' and ordine>@maxRetineri)
	begin
		insert into #sumecfg(Marca, denumire,grup,ordin, ordine, suma)
		select marca, '<Alte sp>', 'CR', 0, @maxRetineri, 0	from #sumecfg s
			where ordine like 'r%' and ordine>@maxRetineri and 
				not exists(select 1 from #sumecfg t where t.marca=s.marca and t.ordine like 'r%' and t.ordine=@maxRetineri)
				
		select sum(suma) from
		(
		select marca, 
		sum(suma) as suma from #sumecfg where ordine like 'r%' and rtrim(ordine)>=rtrim(@maxRetineri)
				group by marca) x
				
			update s set denumire='<Alte sp>', suma=t.suma	--s.suma+
			from #sumecfg s,
			(
			select marca, sum(suma) as suma from #sumecfg where ordine like 'r%' and rtrim(ordine)>=rtrim(@maxRetineri)
				group by marca) t where s.marca=t.marca and s.ordine=@maxRetineri --left(@maxRetineri,3)
			delete from #sumecfg where ordine like 'r%' and ordine>@maxRetineri
			--select * from #sumecfg where ordine like 'SP%' and ordine>@maxSporuri
	end	
--	select marca,ordine, count(1) from #sumecfg s group by marca, ordine order by count(1) desc		--*/
	
	/**	se trec orele si procentele in grupul sporuri:	*/

	update s set grup='SP', ordine=s.grup+'0'+convert(varchar(20),ordine)
	from #sumecfg s
		where s.grup in ('PR','OR')
		
	update s set grup='SP', ordine=replace(s.grup,'G','R')+'0'+convert(varchar(20),ordine)
	from #sumecfg s
		where s.grup in ('PG','OG')

	update s set grup='CV', ordine=replace(s.grup,'V','R')+'0'+convert(varchar(20),ordine)
	from #sumecfg s
		where s.grup in ('PV')

	insert into #sumecfg(grup, marca, denumire, ordine, suma, ordin)			--> completat denumirea pt ore noapte fara remuneratie; de fapt, o peticeala
	select grup, marca, denumire, replace(ordine,'OR','SP'), 0 suma, ordin from #sumecfg s where s.ordine like 'OR%'
		and not exists (select 1 from #sumecfg t where t.marca=s.marca and t.grup=s.grup and t.ordine=replace(s.ordine,'OR','SP'))
		
		--	!cfgRapPS/>
		/**	se iau datele pe marci (ore si sume)*/
--	select * from #sumecfg order by grup, ordine
		-- test select * from #sumecfg --where grup in ('og','PG','SG','PR') order by grup, ordin
end

select e.data, rtrim(isnull(e.nume,'')) as nume,rtrim(isnull(lm.denumire,''))+space(20) as nume_lm, rtrim(isnull(f.denumire,'')) as nume_functie, 
	1 as nivel,e.cod_numeric_personal, -- denumiri
	p.regim_de_lucru,
	isnull(e.cod_functie,'')+' '+isnull(e.marca,'') as marca, convert(char(9),isnull(lm.cod,''))+space(5) as parinte,
	isnull(e.cod_functie,'')+' '+isnull(e.marca,'')+(case when @istoric=1 then CONVERT(char(10),e.data,112) else '' end) as cod,
	(case when @q_grupare=0 then isnull(p.loc_de_munca,e.loc_de_munca) else e.loc_de_munca end)
	--e.loc_de_munca
	as loc_de_munca, lm.nivel+1+(case when @istoric=1 then 1 else 0 end) as niv,
	isnull(e.cod_functie,'') as functia, isnull(e.spor_vechime,0) as proc_spor_vechime,
	isnull((e.spor_vechime/100)*salar_de_incadrare,0) as suma_spor_vechime,
	isnull(e.salar_de_incadrare,0)+isnull(e.Indemnizatia_de_conducere,0) as salar_de_baza,
	isnull(e.salar_de_incadrare,0) as sal_tarif,
	--isnull(e.salar_lunar,0) as salar_orar
	(case when (@dafora=1 or @regimlv=1) and e.salar_lunar_de_baza>0 then Round (e.salar_de_incadrare/e.salar_lunar_de_baza/0.05,12,0)*0.05
	else (case when @unitbuget=1 then e.salar_de_baza1 else e.salar_de_incadrare end) end)/
		((case when e.Tip_salarizare='1' or e.Tip_salarizare='2' then @ore_luna else @nrmedol end )* 
		(case when charindex(e.grupa_de_munca,'COP')<>0 and e.Salar_lunar_de_baza>0 then e.Salar_lunar_de_baza/8 else 1 end)) 
		 as salar_orar
	,	(isnull(p.ore_regie,0)+isnull(p.ore_acord,0))/p.regim_de_lucru as zi_lu,
	isnull(c.zile_co,0)/isnull(nn.nr,1000000000) as zi_co,
	isnull(c.zile_ev,0)/isnull(nn.nr,1000000000) as zi_ev,
	isnull(convert(float,m.zile_cu_reducere),0)/isnull(nn.nr,1000000000) as zi_bo,
	convert(float,(isnull(m.zile_lucratoare,0)-isnull(m.zile_cu_reducere,0)))/isnull(nn.nr,100000000) as zi_bs,
	isnull(m.zi_ba,0) as zi_ba,
	isnull(p.ore_concediu_fara_salar/p.regim_de_lucru,0) as zi_cfs,
	isnull(p.ore_nemotivate/p.regim_de_lucru,0) as zi_ne, isnull(p.salar_ore_lu,0) as salar_ore_lu,	
	isnull(p.ore_lucrate,0) as ore_lucrate,
	1 as indice,--round(isnull(s.sal_cuv,0)/isnull(nn.nr,100000000),0) 
	round((isnull(p.salar_orar,0)-isnull(b.Indemnizatia_de_conducere,0)/
	(case when isnull(p.ore_lucrate,0)=0 then 0.1 else p.ore_lucrate end)
	) *isnull(p.ore_lucrate,0)
	,0)
	as sal_cuv, 0 as ind_cond,
	isnull(b.Indemnizatia_de_conducere,0) as ind_cond_suma,
	(isnull(b.realizat_regie,0)+isnull(b.realizat_acord,0)+isnull(b.Salar_categoria_lucrarii,0))/isnull(nn.nr,1000000000) as total_salar,
	isnull(p.Ore_concediu_de_odihna,0) as ore_neco, isnull(c.ind_co,0)/isnull(nn.nr,1000000000) as ind_co,	
	isnull(c.zile_ev*p.regim_de_lucru,0)/isnull(nn.nr,1000000000) as ore_ev, isnull(c.ind_ev,0)/isnull(nn.nr,1000000000) as ind_ev,
	isnull(p.Ore_intr_tehn_1,0)+isnull(p.Ore_intr_tehn_2,0) as ore_intr_tehn, 0 as ind_intr_tehn, 
	isnull(m.zile_cu_reducere*p.regim_de_lucru,0)/isnull(nn.nr,100000000) as ore_bo, 
	isnull(b.Ind_c_medical_unitate,0)/isnull(nn.nr,100000000) as suma_bo,
	(isnull(m.zile_lucratoare,0)-isnull(m.zile_cu_reducere,0))*p.regim_de_lucru/isnull(nn.nr,10000000) as ore_bs,
	isnull(m.indemnizatie_cas,0)/isnull(nn.nr,100000000) as suma_bs,
	 isnull(zi_ba*p.regim_de_lucru,0) as ore_ba, isnull(m.suma_ba,0) as suma_ba,isnull(p.ore_nemotivate,0) as ore_ne,
	isnull(p.ore_concediu_fara_salar,0) as ore_cfs,
	isnull(p.ore_suplim_cm,0) as suplCM_ore,isnull(p.suplCM_suma,0) as suplCM_suma,	
	isnull(p.ore_suplim_m,0) as suplM_ore,isnull(p.suplM_suma,0) as suplM_suma,
	isnull(p.ore_spor_100,0) as sp100_ore, isnull(b.Indemnizatie_ore_spor_100,0)/isnull(nn.nr,10000000) as sp100_suma,
	isnull(p.ore_de_noapte,0) as noapte_ore, isnull(p.noapte_suma,0) as noapte_suma,
	isnull(p.proc_sist_prg,0) as proc_sist_prg,
	isnull(p.sist_prg_ore,0) as sist_prg_ore,isnull(p.sist_prg_suma,0)/100 as sist_prg_suma,		--(ok)
	isnull(p.ore_lucrate,0) as sp_vech_ore,isnull(b.spor_vechime,0)/isnull(nn.nr,100000000) as sp_vech_suma, 
	-- date aferente marcilor
	b.venit_brut/isnull(nn.nr,100000000) as venit_brut,n.ret_CAS/isnull(nn.nr,100000000) ret_CAS,n.somaj_1/isnull(nn.nr,100000000) as ret_somaj,
		n.CASS/isnull(nn.nr,100000000) cass,n.ded/isnull(nn.nr,100000000) as deduceri,
	isnull(n.impozit,0)/isnull(nn.nr,100000000)  as impozit,
		isnull(n.avans,0)/isnull(nn.nr,100000000) as avans,
	n.rest_de_plata/isnull(nn.nr,100000000) as cuvenit_net,
	b.loc_de_munca as loc_de_munca_b,
	isnull(e.Spor_de_functie_suplimentara,0) as proc_fct_suplim,
	isnull(b.Spor_de_functie_suplimentara,0) suma_fct_suplim,
	isnull(n.Ven_net_in_imp,0) venit_net,
	isnull(n.Venit_baza,0) venit_impozabil,
	isnull(n.venit_net,0) sal_net,
					isnull(sc.R01,'') R01,				-->> retinerile (inclusiv corectiile)
					isnull(sc.R02,'') R02,
					isnull(sc.R03,'') R03,
					isnull(sc.R04,'') R04,
					isnull(sc.R05,'') R05,
					isnull(sc.R06,'') R06,
					isnull(sc.R07,'') R07,
					isnull(sc.R08,'') R08,
					isnull(sc.R09,'') R09,
					isnull(sc.R10,'') R10,
					isnull(sc.R11,'') R11,
					isnull(sc.R12,'') R12,
					isnull(sc.R13,'') R13,
					isnull(sc.R14,'') R14,
					isnull(sc.R15,'') R15,
-->> calculez alte retineri de afisat in raportul Istoric salarizare.RDL
-->> ar trebui scazut din restul de plata, sumele care se aduna la el, fara a face parte din brut (aj. deces, corectia U - vedem daca sunt cazuri)
					isnull(n.Venit_net,0)-isnull(n.Rest_de_plata,0)-isnull(n.avans,0)
						-isnull(sc.R01,0)-isnull(sc.R02,0)-isnull(sc.R03,0)-isnull(sc.R04,0)
						-isnull(sc.R05,0)-isnull(sc.R06,0)-isnull(sc.R07,0)-isnull(sc.R08,0)-isnull(sc.R09,0)-isnull(sc.R10,0)	
						-isnull(sc.R11,0)-isnull(sc.R12,0)-isnull(sc.R13,0)-isnull(sc.R14,0)-isnull(sc.R15,0) as alte_retineri,	
					isnull(densc.R01,'') DR01,
					isnull(densc.R02,'') DR02,
					isnull(densc.R03,'') DR03,
					isnull(densc.R04,'') DR04,
					isnull(densc.R05,'') DR05,
					isnull(densc.R06,'') DR06,
					isnull(densc.R07,'') DR07,
					isnull(densc.R08,'') DR08,
					isnull(densc.R09,'') DR09,
					isnull(densc.R10,'') DR10,
					isnull(densc.R11,'') DR11,
					isnull(densc.R12,'') DR12,
					isnull(densc.R13,'') DR13,
					isnull(densc.R14,'') DR14,
					isnull(densc.R15,'') DR15,
					isnull(sc.SP00,'') SP00,				-->> sporurile (inclusiv corectiile)
					isnull(sc.SP01,'') SP01,
					isnull(sc.SP02,'') SP02,
					isnull(sc.SP03,'') SP03,
					isnull(sc.SP04,'') SP04,
					isnull(sc.SP05,'') SP05,
					isnull(sc.SP06,'') SP06,
					isnull(sc.SP07,'') SP07,
					isnull(sc.SP08,'') SP08,
					isnull(sc.SP09,'') SP09,
					isnull(sc.SP10,'') SP10,
					isnull(sc.SP11,'') SP11,
					isnull(sc.SP12,'') SP12,
					isnull(sc.SP13,'') SP13,
					isnull(sc.SP14,'') SP14,
					isnull(densc.SP00,'') DSP00,
					isnull(densc.SP01,'') DSP01,
					isnull(densc.SP02,'') DSP02,
					isnull(densc.SP03,'') DSP03,
					isnull(densc.SP04,'') DSP04,
					isnull(densc.SP05,'') DSP05,
					isnull(densc.SP06,'') DSP06,
					isnull(densc.SP07,'') DSP07,
					isnull(densc.SP08,'') DSP08,
					isnull(densc.SP09,'') DSP09,
					isnull(densc.SP10,'') DSP10,
					isnull(densc.SP11,'') DSP11,
					isnull(densc.SP12,'') DSP12,
					isnull(densc.SP13,'') DSP13,
					isnull(densc.SP14,'') DSP14,
					isnull(sc.PR00,'') PR00,
					isnull(sc.PR01,'') PR01,
					isnull(sc.PR02,'') PR02,
					isnull(sc.PR03,'') PR03,
					isnull(sc.PR04,'') PR04,
					isnull(sc.PR05,'') PR05,
					isnull(sc.PR06,'') PR06,
					isnull(sc.PR07,'') PR07,
					isnull(sc.PR08,'') PR08,
					isnull(sc.PR09,'') PR09,
					isnull(sc.PR10,'') PR10,
					isnull(sc.PR11,'') PR11,
					isnull(sc.PR12,'') PR12,
					isnull(sc.PR13,'') PR13,
					isnull(sc.PR14,'') PR14,
					isnull(sc.OR00,'') OR00,
					isnull(sc.OR01,'') OR01,
					isnull(sc.OR02,'') OR02,
					isnull(sc.OR03,'') OR03,
					isnull(sc.OR04,'') OR04,
					isnull(sc.OR05,'') OR05,
					isnull(sc.OR06,'') OR06,
					isnull(sc.OR07,'') OR07,
					isnull(sc.OR08,'') OR08,
					isnull(sc.OR09,'') OR09,
					isnull(sc.OR10,'') OR10,
					isnull(sc.OR11,'') OR11,
					isnull(sc.OR12,'') OR12,
					isnull(sc.OR13,'') OR13,
					isnull(sc.OR14,'') OR14,
					1 angajati,
					isnull(t.Valoare_tichete,0) as valt_tichete,
					isnull(t.Numar_tichete,0) as nr_tichete,
					b.ore_invoiri
into #stat
from #personal as e
	left join (select data, marca,sum(b.realizat__regie) as realizat_regie, sum(b.realizat_acord) as realizat_acord, sum(b.Salar_categoria_lucrarii) as salar_categoria_lucrarii, 
					sum(b.ind_concediu_de_odihna) as ind_concediu_de_odihna,sum(venit_total) as venit_brut,sum(b.premiu) as premii, 
					sum(isnull(ore_de_noapte,0)) as ore_de_noapte, sum(isnull(ind_ore_de_noapte,0)) as ind_ore_de_noapte,
					sum(isnull(spor_vechime,0)) as spor_vechime,max(b.ind_nemotivate) as indemnizatia_de_conducere,
					sum(isnull(Ind_c_medical_unitate,0)) as Ind_c_medical_unitate,
					sum(b.spor_sistematic_peste_program) as spor_sistematic_peste_program,
					sum(b.Indemnizatie_ore_supl_1) as Indemnizatie_ore_supl_1,sum(b.Indemnizatie_ore_supl_2) as Indemnizatie_ore_supl_2,
					sum(b.Indemnizatie_ore_spor_100) as Indemnizatie_ore_spor_100,max(b.loc_de_munca) as loc_de_munca,
					sum(isnull(Spor_specific,0)) Spor_specific,
					sum(isnull(Spor_cond_1,0)) Spor_cond_1,
					sum(isnull(Spor_cond_2,0)) Spor_cond_2,
					sum(isnull(Spor_cond_3,0)) Spor_cond_3,
					sum(isnull(Spor_cond_4,0)) Spor_cond_4,
					sum(isnull(Spor_cond_5,0)) Spor_cond_5,
					sum(isnull(Spor_cond_6,0)) Spor_cond_6,
					sum(isnull(Spor_cond_7,0)) Spor_cond_7,
					sum(isnull(Spor_cond_8,0)) Spor_cond_8,
					sum(isnull(Spor_de_functie_suplimentara,0)) Spor_de_functie_suplimentara,
					sum(isnull(ore_invoiri,0)) ore_invoiri
		from brut b where data between @q_datajos and @q_datasus group by b.data, b.marca) b on b.data=e.data and b.marca=e.marca			-- b
	left join (select dbo.eom(p.Data) as data, max(p.loc_de_munca) as loc_de_munca,p.marca,max(isnull(p.salar_orar,0)) as salar_orar, sum(isnull(p.ore_regie,0)) as ore_regie,			
					sum(isnull(ore_acord,0)) as ore_acord,
					sum(isnull((case when 
							isnull(p.salar_categoria_lucrarii,0)<>0 then p.salar_categoria_lucrarii else p.salar_orar end),0)
						*isnull(p.ore_suplimentare_1,0)*2) as suplCM_suma,
					sum(isnull((case when 
							isnull(p.salar_categoria_lucrarii,0)<>0 then p.salar_categoria_lucrarii else p.salar_orar end),0)
						*isnull(p.ore_suplimentare_2,0)*2) as suplM_suma,
					sum(0.25*isnull((case when 
							isnull(p.salar_categoria_lucrarii,0)<>0 then p.salar_categoria_lucrarii else p.salar_orar end),0)*isnull(p.ore_de_noapte,0)) as noapte_suma,
					sum(isnull(p.ore_sistematic_peste_program,0)*isnull(p.Sistematic_peste_program,0)*isnull((case when 
							isnull(p.salar_categoria_lucrarii,0)<>0 then p.salar_categoria_lucrarii else p.salar_orar end),0)) as sist_prg_suma,
					sum(isnull(p.ore_lucrate,0)*isnull((case when 
							isnull(p.salar_categoria_lucrarii,0)<>0 then p.salar_categoria_lucrarii else p.salar_orar end),0)) as salar_ore_lu,
					max(isnull(regim_de_lucru,8)) as regim_de_lucru,sum(isnull(p.Ore_concediu_de_odihna,0)) as Ore_concediu_de_odihna,
					sum(p.ore_concediu_fara_salar) as ore_concediu_fara_salar,sum(p.ore_nemotivate) as ore_nemotivate,
					sum(p.Ore_intrerupere_tehnologica) as Ore_intr_tehn_1, sum(p.Ore) as Ore_intr_tehn_2,
					sum(isnull(p.ore_suplimentare_1,0)) as ore_suplim_cm, sum(isnull(p.ore_suplimentare_2,0)) as ore_suplim_m,
					sum(isnull(p.ore_spor_100,0)) as ore_spor_100,sum(isnull(p.ore_de_noapte,0)) as ore_de_noapte,
					sum(isnull(p.ore_sistematic_peste_program,0)) as sist_prg_ore,
					sum(isnull(p.ore_lucrate,0)) as ore_lucrate,
					max(isnull(p.Sistematic_peste_program,0)) as proc_sist_prg
					from pontaj p
					where p.data between @q_datajos and @q_datasus group by dbo.eom(p.Data), p.marca,
						(case when @q_grupare=0 then p.loc_de_munca else '' end)
				) p on p.data=e.data and p.marca=e.marca	-- p
	left join (select count(distinct (case when @q_grupare=0 then p.loc_de_munca else '' end)) as nr, p.marca 
										from brut --pontaj 
											p left join realcom r 
									on p.marca=r.marca and p.data=r.data and p.loc_de_munca=r.loc_de_munca
						--and 'PS'+rtrim(p.numar_curent)=r.numar_document							
					where p.data between @q_datajos and @q_datasus group by p.marca) nn on e.marca=nn.marca
	left join (select c.data, marca,sum(case when c.tip_concediu not in ('2','E') then isnull(c.zile_co,0) else 0 end) as zile_co
							,sum(case when c.tip_concediu in ('2','E') then isnull(c.zile_co,0) else 0 end) as zile_ev
							,sum(case when c.tip_concediu not in ('2','E') then isnull(c.indemnizatie_co,0) else 0 end) as ind_co
							,sum(case when c.tip_concediu in ('2','E') then isnull(c.indemnizatie_co,0) else 0 end) as ind_ev
					from concodih c where data between @q_datajos and @q_datasus group by c.data, c.marca) c on 
	c.data=e.data and c.marca=e.marca																						
-- c
	left join (select data, marca, sum(isnull(m.zile_cu_reducere,0)) as zile_cu_reducere, sum(m.zile_lucratoare) as zile_lucratoare,
					sum(case when tip_diagnostic='2-' or tip_diagnostic='3-' or tip_diagnostic='4-' then m.zile_lucratoare else 0 end) as zi_ba,
					sum(isnull(m.indemnizatie_unitate,0)) as indemnizatie_unitate, sum(isnull(m.indemnizatie_cas,0)) as indemnizatie_cas,
					sum(case when tip_diagnostic='2-' or tip_diagnostic='3-' or tip_diagnostic='4-' then isnull(m.indemnizatie_unitate,0)+isnull(m.indemnizatie_cas,0)
							else 0 end) as suma_ba
					from conmed m where data between @q_datajos and @q_datasus and m.Tip_diagnostic<>'0-' group by m.data, m.marca) m on 
	m.data=e.data and m.marca=e.marca	-- m
	left join (select n.data, n.marca,max(n.pensie_suplimentara_3) as ret_CAS,max(n.ded_baza) as ded,
					max(n.Asig_sanatate_din_net) as CASS,
					max(n.impozit) as impozit,sum(n.avans)+SUM(ISNULL(a.premiu_la_avans,0)) as avans,sum(n.co_incasat) as co_incasat,
					sum(n.REST_DE_PLATA) as rest_de_plata,max(n.somaj_1) as somaj_1,
					max(n.Ven_net_in_imp) Ven_net_in_imp, max(n.Venit_baza) Venit_baza, max(n.venit_net) venit_net
					from net n left join avexcep a on a.marca=n.marca and a.data=n.data 
					where n.data between @q_datajos and @q_datasus and n.data=dateadd(d,-day(dateadd(M,1,n.data)),dateadd(M,1,n.data))
					group by n.data, n.marca) as n on n.data=e.data and n.marca=e.marca	-- n = linia din net in ultima zi a lunii
	left join functii f on e.cod_functie=f.cod_functie 
	left join lm on lm.cod=e.loc_de_munca
	left join speciflm sl on sl.loc_de_munca=e.loc_de_munca
/*
	left join (select Data_lunii, Marca, SUM(convert(decimal(12,2),
			(case when t.Tip_operatie='C' or t.Tip_operatie='P' or t.Tip_operatie='S' then Nr_tichete*Valoare_tichet else -Nr_tichete*Valoare_tichet end)
			)) as valt_tichete,
			sum((case when t.Tip_operatie='C' or t.Tip_operatie='P' or t.Tip_operatie='S' then Nr_tichete else -Nr_tichete end)
			) as nr_tichete from tichete t where Data_lunii between @tich_datajos and @tich_datasus
				group by Data_lunii, marca) t on t.marca=e.marca and t.Data_lunii=e.data
*/
--	am apelat functia pentru a citi fie din pontaj, fie din tichete
	--left join dbo.fNC_tichete (pt.datajos, pt.datasus, isnull(@q_Marci,''),1) t on t.marca=e.marca and t.Data=e.data
	left join #tichete t on t.marca=e.marca and t.Data_salar=e.data
	left join (
		select * from (select data,marca,suma,ordine from #sumecfg) x
		pivot(sum(suma) 
		for ordine in (	[R01],[R02],[R03],[R04],[R05],[R06],[R07],[R08],[R09],		-- retineri
						[R10],[R11],[R12],[R13],[R14],[R15],[R16],[R17],[R18],[R19],[R20],
						[R21],[R22],[R23],[R24],[R25],[R26],[R27],[R28],[R29],[R30],[R31],[R32],[R33],[R34],[R35],			-- si corectii retineri
					[SP00], [SP01], [SP02], [SP03], [SP04], [SP05], [SP06], [SP07], [SP08],	-- sume sporuri
					[SP09], [SP10], [SP11], [SP12], [SP13], [SP14],							-- corectii venituri
					[PR00], [PR01], [PR02], [PR03], [PR04], [PR05], [PR06], [PR07], [PR08],
					[PR09], [PR10], [PR11], [PR12], [PR13], [PR14],	-- procente sporuri
					[OR00], [OR01], [OR02], [OR03], [OR04], [OR05], [OR06], [OR07], [OR08],
					[OR09], [OR10], [OR11], [OR12], [OR13], [OR14])						-- ore sporuri
		) as pvt) sc on sc.data=e.data and sc.marca=e.marca
	left join (
		select * from (select data,marca,denumire,ordine from #sumecfg) x
		pivot(max(denumire) 
		for ordine in ([R1],[R2],[R3],[R4],[R5],[R6],[R7],[R8],[R9],[RAlte])
		) as pvt) denret on denret.data=e.data and denret.marca=e.marca
	left join (
		select * from (select data,marca,denumire,ordine from #sumecfg) x
		pivot(max(denumire) 
		for ordine in ([R01],[R02],[R03],[R04],[R05],[R06],[R07],[R08],[R09],		-- retineri
						[R10],[R11],[R12],[R13],[R14],[R15],								-- corectii retineri
					[SP00], [SP01], [SP02], [SP03], [SP04], [SP05], [SP06], [SP07], [SP08],	-- sume sporuri
					[SP09], [SP10], [SP11], [SP12], [SP13], [SP14])							-- corectii venituri
		) as pvt) densc on densc.data=e.data and densc.marca=e.marca

--create index Principal on #stat (data, marca, loc_de_munca)

if @grupare=2 and @istoric=0 update #stat set parinte='<T>'+space(10), niv=1	-- daca nu se doresc locuri de munca in stat ramane totalul ca loc de munca

--daca grupare pe cnp, marci nu ne mai intereseaza nivelul aferent locurilor de munca
if @grupare=4 update s set niv=(select min(niv) from #stat s1 where s1.cod_numeric_personal=s.cod_numeric_personal) from #stat s 

-- luare date pe marci din brut:
select top 0 1 as nivel,data,marca,Loc_de_munca, Total_ore_lucrate, Ore_lucrate__regie, Realizat__regie, Ore_lucrate_acord, Realizat_acord, 
	Ore_suplimentare_1, Indemnizatie_ore_supl_1, Ore_suplimentare_2, Indemnizatie_ore_supl_2, Ore_suplimentare_3, Indemnizatie_ore_supl_3, Ore_suplimentare_4, Indemnizatie_ore_supl_4, 
	Ore_spor_100, Indemnizatie_ore_spor_100, Ore_de_noapte, Ind_ore_de_noapte, Ore_lucrate_regim_normal, Ind_regim_normal, Ore_intrerupere_tehnologica, Ind_intrerupere_tehnologica, 
	Ore_obligatii_cetatenesti, Ind_obligatii_cetatenesti, Ore_concediu_fara_salar, Ind_concediu_fara_salar, Ore_concediu_de_odihna, Ind_concediu_de_odihna, 
	Ore_concediu_medical, Ind_c_medical_unitate, Ind_c_medical_CAS, Ore_invoiri, Ind_invoiri, Ore_nemotivate, Ind_nemotivate, Salar_categoria_lucrarii, CMCAS, CMunitate, CO, Restituiri, 
	Diminuari, Suma_impozabila, Premiu, Diurna, Cons_admin, Sp_salar_realizat, Suma_imp_separat, Spor_vechime, Spor_de_noapte, Spor_sistematic_peste_program, Spor_de_functie_suplimentara, 
	Spor_specific, Spor_cond_1, Spor_cond_2, Spor_cond_3, Spor_cond_4, Spor_cond_5, Spor_cond_6, Compensatie, VENIT_TOTAL, Salar_orar, 
	Venit_cond_normale, Venit_cond_deosebite, Venit_cond_speciale, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10 into #brut from brut
union all
select 1 as nivel,b.data,max(b.marca),isnull(e.loc_de_munca,b.loc_de_munca)
	as Loc_de_munca, sum(round(b.Total_ore_lucrate,0)), sum(round(b.Ore_lucrate__regie,0)), sum(round(b.Realizat__regie,0)), sum(round(b.Ore_lucrate_acord,0)), sum(round(b.Realizat_acord,0)), 
	sum(round(b.Ore_suplimentare_1,0)), sum(round(b.Indemnizatie_ore_supl_1,0)), sum(round(b.Ore_suplimentare_2,0)), sum(round(b.Indemnizatie_ore_supl_2,0)), 
	sum(round(b.Ore_suplimentare_3,0)), sum(round(b.Indemnizatie_ore_supl_3,0)), sum(round(b.Ore_suplimentare_4,0)), sum(round(b.Indemnizatie_ore_supl_4,0)), 
	sum(round(b.Ore_spor_100,0)), sum(round(b.Indemnizatie_ore_spor_100,0)),sum(round(b.Ore_de_noapte,0)), sum(round(b.Ind_ore_de_noapte,0)), 
	sum(round(b.Ore_lucrate_regim_normal,0)), sum(round(b.Ind_regim_normal,0)), sum(round(b.Ore_intrerupere_tehnologica,0)), sum(round(b.Ind_intrerupere_tehnologica,0)), 
	sum(round(b.Ore_obligatii_cetatenesti,0)), sum(round(b.Ind_obligatii_cetatenesti,0)), sum(round(b.Ore_concediu_fara_salar,0)), sum(round(b.Ind_concediu_fara_salar,0)), 
	sum(round(b.Ore_concediu_de_odihna,0)), sum(round(b.Ind_concediu_de_odihna,0)), sum(round(b.Ore_concediu_medical,0)), sum(round(b.Ind_c_medical_unitate,0)), 
	sum(round(b.Ind_c_medical_CAS,0)), sum(round(b.Ore_invoiri,0)), sum(round(b.Ind_invoiri,0)), sum(round(b.Ore_nemotivate,0)), sum(round(b.Ind_nemotivate,0)), 
	sum(round(b.Salar_categoria_lucrarii,0)), sum(round(b.CMCAS,0)), sum(round(b.CMunitate,0)), sum(round(b.CO,0)), sum(round(b.Restituiri,0)), sum(round(b.Diminuari,0)), 
	sum(round(b.Suma_impozabila,0)), sum(round(b.Premiu,0)), sum(round(b.Diurna,0)), sum(round(b.Cons_admin,0)), sum(round(b.Sp_salar_realizat,0)), sum(round(b.Suma_imp_separat,0)), 
	sum(round(b.Spor_vechime,0)), sum(round(b.Spor_de_noapte,0)), sum(round(b.Spor_sistematic_peste_program,0)), sum(round(b.Spor_de_functie_suplimentara,0)), sum(round(b.Spor_specific,0)), 
	sum(round(b.Spor_cond_1,0)), sum(round(b.Spor_cond_2,0)), sum(round(b.Spor_cond_3,0)), sum(round(b.Spor_cond_4,0)), sum(round(b.Spor_cond_5,0)), sum(round(b.Spor_cond_6,0)), 
	sum(round(b.Compensatie,0)), sum(round(b.VENIT_TOTAL,0)), max(b.Salar_orar), sum(round(b.Venit_cond_normale,0)), sum(round(b.Venit_cond_deosebite,0)), sum(round(b.Venit_cond_speciale,0)), 
	sum(round(b.Spor_cond_7,0)), sum(round(b.Spor_cond_8,0)), sum(round(b.Spor_cond_9,0)), sum(round(b.Spor_cond_10,0))
from brut b right join net e on e.data=b.data and e.marca=b.marca
where b.data between @q_datajos and @q_datasus --and e.data=b.data
group by b.data, isnull(e.loc_de_munca,b.loc_de_munca), b.marca

--select rtrim(reverse(substring(reverse(#stat.cod),1,charindex(' ',reverse(#stat.cod))))),* from #stat
select s.* into #altstat from #stat s left join #brut b on s.data=b.data and s.loc_de_munca_b=b.loc_de_munca and ltrim(reverse(substring(reverse(rtrim(s.marca)),1,charindex(' ',ltrim(reverse(s.marca))))))=b.marca where s.nivel=1
delete from #stat where nivel=1

insert into #stat(data,nume,nume_lm, nume_functie,nivel,cod_numeric_personal, 
regim_de_lucru, marca,parinte, cod, loc_de_munca, niv, 
	functia, proc_spor_vechime, suma_spor_vechime, salar_de_baza, sal_tarif, 
	salar_orar, zi_lu, zi_co, zi_ev, zi_bo, zi_bs, zi_ba, zi_cfs, zi_ne, 
	salar_ore_lu, ore_lucrate,indice, sal_cuv, ind_cond, ind_cond_suma, total_salar, ore_neco, ind_co, 
	ore_ev, ind_ev,	ore_intr_tehn, ind_intr_tehn, ore_bo, suma_bo, ore_bs, suma_bs, ore_ba, suma_ba, ore_ne, ore_cfs,
	suplCM_ore, suplCM_suma, suplM_ore, suplM_suma, sp100_ore, sp100_suma, noapte_ore, noapte_suma,
	proc_sist_prg, sist_prg_ore, sist_prg_suma, 
	sp_vech_ore, sp_vech_suma, venit_brut, ret_CAS, ret_somaj, CASS, deduceri,
	impozit, avans,	cuvenit_net, loc_de_munca_b, proc_fct_suplim, suma_fct_suplim,
	venit_net, venit_impozabil, sal_net,
	R01,R02,R03,R04,R05,R06,R07,R08,R09,R10,R11,R12,R13,R14,R15,alte_retineri,
	DR01,DR02,DR03,DR04,DR05,DR06,DR07,DR08,DR09,DR10,DR11,DR12,DR13,DR14,DR15,
	SP00, SP01, SP02, SP03, SP04, SP05, SP06, SP07, SP08, SP09, SP10, SP11, SP12, SP13, SP14,
	DSP00, DSP01, DSP02, DSP03, DSP04, DSP05, DSP06, DSP07, DSP08, DSP09, DSP10, DSP11, DSP12, DSP13, DSP14,
	PR00, PR01, PR02, PR03, PR04, PR05, PR06, PR07, PR08, PR09, PR10, PR11,	PR12, PR13, PR14,
	OR00, OR01, OR02, OR03, OR04, OR05, OR06, OR07, OR08, OR09, OR10, OR11, OR12, OR13, OR14,
	valt_tichete, nr_tichete, angajati, ore_invoiri)
select s.Data, isnull(s.nume,''), isnull(s.nume_lm,''), isnull(s.nume_functie,''), isnull(s.nivel,''), isnull(s.cod_numeric_personal,''), 
	isnull(s.regim_de_lucru,''), isnull(s.marca,''), isnull(s.parinte,'')+space(5), isnull(s.cod,'')+space(5), isnull(s.loc_de_munca,''),isnull(s.niv,''),
	isnull(s.functia,''),isnull(s.proc_spor_vechime,''), isnull(b.spor_vechime,''), isnull(s.salar_de_baza,''), isnull(s.sal_tarif,''), 
	isnull(s.salar_orar,''), isnull((b.ore_lucrate__regie+b.ore_lucrate_acord)/s.regim_de_lucru,'') as zi_lu,
	isnull(b.ore_concediu_de_odihna/s.regim_de_lucru,''),isnull(s.zi_ev,''), isnull(b.ore_concediu_medical/s.regim_de_lucru-s.zi_bs,''), 
	isnull(s.zi_bs,''), isnull(s.zi_ba,''), isnull(b.Ore_concediu_fara_salar/s.regim_de_lucru,''), isnull(b.ore_nemotivate/s.regim_de_lucru,''), 
	isnull(b.ind_regim_normal,''), isnull((b.ore_lucrate__regie+b.ore_lucrate_acord),''), isnull(s.indice,''), 
	round(b.Ind_regim_normal-b.ind_nemotivate,0)*s.indice, isnull(s.ind_cond,''), isnull(b.ind_nemotivate,''), 
	isnull(b.realizat__regie+b.realizat_acord+b.Salar_categoria_lucrarii,''), isnull(b.ore_concediu_de_odihna,''),isnull(b.ind_concediu_de_odihna,'') ind_co, 
	isnull(s.ore_ev,''), isnull(s.ind_ev,''), isnull(s.ore_intr_tehn,''), isnull(b.Ind_intrerupere_tehnologica+b.Ind_invoiri,''), 
	isnull(b.ore_concediu_medical-s.ore_bs,''), isnull(b.ind_c_medical_unitate,''), isnull(s.ore_bs,''), 
	isnull(b.Ind_c_medical_CAS,''), isnull(s.ore_ba,''), isnull(b.spor_cond_9,''), isnull(b.ore_nemotivate,''), isnull(b.Ore_concediu_fara_salar,''),
	isnull(b.Ore_suplimentare_1,''), isnull(b.Indemnizatie_ore_supl_1,''), isnull(b.Ore_suplimentare_2,''), isnull(b.Indemnizatie_ore_supl_2,''),
	isnull(b.ore_spor_100,''), isnull(b.indemnizatie_ore_spor_100,''), isnull(b.Ore_de_noapte,''), isnull(b.Ind_ore_de_noapte,''),
	isnull(s.proc_sist_prg,''), isnull(s.sist_prg_ore,''), isnull(b.Spor_sistematic_peste_program,''),
	isnull(s.sp_vech_ore,''), isnull(b.spor_vechime,''), isnull(b.venit_total,''), isnull(s.ret_CAS,''), isnull(s.ret_somaj,''), isnull(s.CASS,''),
	isnull(s.deduceri,''), isnull(s.impozit,''), isnull(s.avans,''), isnull(s.cuvenit_net,''), 
	s.loc_de_munca_b, isnull(s.proc_fct_suplim,0) proc_fct_suplim, isnull(s.suma_fct_suplim,0) suma_fct_suplim,
	isnull(s.venit_net,0) venit_net, isnull(s.venit_impozabil,0) venit_impozabil, isnull(s.sal_net,0) sal_net,
			s.R01, s.R02, s.R03, s.R04, s.R05, s.R06, s.R07, s.R08, s.R09, s.R10, s.R11, s.R12, s.R13, s.R14, s.R15, s.alte_retineri, 
			s.DR01, s.DR02, s.DR03, s.DR04, s.DR05, s.DR06, s.DR07, s.DR08, s.DR09, s.DR10, s.DR11, s.DR12, s.DR13, s.DR14, s.DR15,
			s.SP00, s.SP01, s.SP02, s.SP03, s.SP04, s.SP05, s.SP06, s.SP07, s.SP08, s.SP09, s.SP10, s.SP11, s.SP12, s.SP13, s.SP14,
			s.DSP00, s.DSP01, s.DSP02, s.DSP03, s.DSP04, s.DSP05, s.DSP06, s.DSP07, s.DSP08, s.DSP09, s.DSP10, s.DSP11, s.DSP12, s.DSP13, s.DSP14,
			s.PR00, s.PR01, s.PR02, s.PR03, s.PR04, s.PR05, s.PR06, s.PR07, s.PR08, s.PR09, s.PR10, s.PR11,	s.PR12, s.PR13, s.PR14,
			s.OR00, s.OR01, s.OR02, s.OR03, s.OR04, s.OR05, s.OR06, s.OR07, s.OR08, s.OR09, s.OR10, s.OR11, s.OR12, s.OR13, s.OR14,
			s.valt_tichete, s.nr_tichete, 1, b.ore_invoiri
from #altstat s left join #brut b on b.data=s.data and b.loc_de_munca=s.loc_de_munca and 
		ltrim(reverse(substring(reverse(rtrim(s.marca)),1,charindex(' ',ltrim(reverse(s.marca))))))=b.marca
drop table #altstat
drop table #brut
drop table #brut_corectii

--	Lucian (31.03.2012) mut locurile de munca de nivel X (care au copii) ca si loc de munca de nivel X+1 pt. a putea avea total pe aceste locuri de munca
if @grupare<>2 and @grupare<>4 
	update #stat set parinte=(case when exists (select 1 from #stat s left outer join lm on s.loc_de_munca=lm.Cod where lm.Cod_parinte=#stat.loc_de_munca) then rtrim(parinte)+'_'+space(14-(len(rtrim(parinte))+1)) else parinte end),
	loc_de_munca=(case when exists (select 1 from #stat s left outer join lm on s.loc_de_munca=lm.Cod where lm.Cod_parinte=#stat.loc_de_munca) then rtrim(loc_de_munca)+'_' else loc_de_munca end),
	niv=(case when exists (select 1 from #stat s left outer join lm on s.loc_de_munca=lm.Cod where lm.Cod_parinte=#stat.loc_de_munca) then niv+1 else niv end)

--	apel procedura specifica (daca exista) care va permite modificarea datelor din tabela #stat (inainte de preluarea randurilor de total)
if exists (select * from sysobjects where name ='rapStatDePlataSP' and xtype='P')
	exec rapStatDePlataSP @datajos=@datajos, @datasus=@datasus, @cu_tabel=@cu_tabel, @grupare=@grupare, @rettip=@rettip, @istoric=@istoric

--	Lucian (31.03.2012) am creat tabela (in loc de into) pt. uniformizare structura (al 3=lea union all nu functiona corect in totalizarea pe cod parinte)
create table #lm (Nivel int, Cod char(10), Cod_parinte char(10), Denumire char(30))

insert into #lm
select (select min(nivel) from lm)-1 as nivel, convert(char(10),'<T>') as cod, '' as cod_parinte, 'Total' as denumire
union all	-->> total general
select 
Nivel, Cod, (case when isnull(rtrim(Cod_parinte),'')='' then convert(char(10),'<T>') else cod_parinte end), Denumire
from lm
union all	-->> Lucian (31.03.2012) linii pt. locurile de munca de nivel superior care au copii - le mut la nivel inferior
select 
Nivel+1, rtrim(Cod)+'_', convert(char(10),Cod), Denumire
from lm
where exists (select 1 from lm lm1 where lm1.Cod_parinte=lm.cod)
--Create Unique Clustered Index Cod on #lm (Cod)

set @i=(select max(nivel) from #lm)

while @i>-1 and @grupare in (0,1,2,3)
begin
	insert into #stat (data,nume,nume_lm, nume_functie,nivel,cod_numeric_personal, regim_de_lucru, marca,parinte, cod, loc_de_munca, niv, 
	functia, proc_spor_vechime, suma_spor_vechime, salar_de_baza, sal_tarif, salar_orar, zi_lu, zi_co, zi_ev, zi_bo, zi_bs, 
	zi_ba, zi_cfs, zi_ne, salar_ore_lu, ore_lucrate,indice, sal_cuv, ind_cond, ind_cond_suma, total_salar, ore_neco, ind_co, ore_ev, ind_ev, ore_intr_tehn, ind_intr_tehn, ore_bo, suma_bo,
	ore_bs, suma_bs, ore_ba, suma_ba, ore_ne, ore_cfs, suplCM_ore, suplCM_suma, suplM_ore, suplM_suma, sp100_ore, sp100_suma, 
	noapte_ore, noapte_suma, proc_sist_prg,	sist_prg_ore, sist_prg_suma, 
	sp_vech_ore, sp_vech_suma, venit_brut, ret_CAS, ret_somaj, CASS, deduceri, 
	impozit, avans, cuvenit_net, loc_de_munca_b, proc_fct_suplim, suma_fct_suplim,
	venit_net, venit_impozabil, sal_net,
	R01,R02,R03,R04,R05,R06,R07,R08,R09,R10,R11,R12,R13,R14,R15,alte_retineri, 
	DR01,DR02,DR03,DR04,DR05,DR06,DR07,DR08,DR09,DR10,DR11,DR12,DR13,DR14,DR15,
	SP00, SP01, SP02, SP03, SP04, SP05, SP06, SP07, SP08, SP09, SP10, SP11, SP12, SP13, SP14,
	DSP00, DSP01, DSP02, DSP03, DSP04, DSP05, DSP06, DSP07, DSP08, DSP09, DSP10, DSP11, DSP12, DSP13, DSP14,
	PR00, PR01, PR02, PR03, PR04, PR05, PR06, PR07, PR08, PR09, PR10, PR11,	PR12, PR13, PR14,
	OR00, OR01, OR02, OR03, OR04, OR05, OR06, OR07, OR08, OR09, OR10, OR11, OR12, OR13, OR14,
	valt_tichete, nr_tichete, angajati, ore_invoiri)
	select '' as data,'' as nume,max(rtrim(lm.denumire)) as nume_lm, '' as nume_functie,(case when @istoric=1 then 3 else 2 end) as nivel,max(cod_numeric_personal) as cod_numeric_personal,
		max(regim_de_lucru) as regim_de_lucru,'' as marca,
		max(isnull(lm.cod_parinte,''))+space(4) as parinte, max(isnull(lm.cod,''))+space(4) as cod, max(s.loc_de_munca) as loc_de_munca, 
		max(lm.nivel) as niv, max(isnull(functia,'')) as functia, max(isnull(proc_spor_vechime,0)) as proc_spor_vechime,
		sum(isnull(suma_spor_vechime,0)) as suma_spor_vechime, max(salar_de_baza) as salar_de_baza, 
		sum(isnull(sal_tarif,0)) as sal_tarif, max(s.salar_orar) as salar_orar, 
		sum(zi_lu) as zi_lu, sum(s.zi_co) as zi_co, sum(zi_ev) as zi_ev, 
		sum(zi_bo) as zi_bo, sum(zi_bs) as zi_bs, 
		sum(zi_ba) as zi_ba, sum(zi_cfs) as zi_cfs, sum(zi_ne) as zi_ne, 
		sum(salar_ore_lu) as salar_ore_lu, sum(ore_lucrate) as ore_lucrate,
		avg(isnull(indice,1)) as indice, sum(isnull(round(sal_cuv,0),0)) as sal_cuv, max(isnull(ind_cond,0)) as ind_cond	--max(?) => ident =>sum(?)
		, sum(ind_cond_suma) as ind_cond_suma, sum(total_salar) as total_salar, sum(ore_neco) as ore_neco, 
		sum(ind_co) as ind_co, sum(ore_ev) as ore_ev, sum(ind_ev) as ind_ev, sum(ore_intr_tehn) as ore_intr_tehn, sum(ind_intr_tehn) as ind_intr_tehn, 
		sum(ore_bo) as ore_bo, sum(suma_bo) as suma_bo, sum(ore_bs) as ore_bs, sum(suma_bs) as suma_bs, 
		sum(ore_ba) as ore_ba, sum(suma_ba) as suma_ba, sum(ore_ne) as ore_ne, sum(ore_cfs) as ore_cfs, 
		sum(suplCM_ore) as suplCM_ore, sum(suplcm_suma) as suplCM_suma,
		sum(suplM_ore) as suplM_ore, sum(suplm_suma) as suplM_suma, 
		sum(sp100_ore) as sp100_ore, sum(sp100_suma) as sp100_suma, 
		sum(noapte_ore) as noapte_ore, sum(round(noapte_suma,0)) as noapte_suma,
		max(proc_sist_prg),	sum(sist_prg_ore) as sist_prg_ore, sum(sist_prg_suma) as sist_prg_suma, 
		sum(sp_vech_ore) as sp_vech_ore, sum(sp_vech_suma) as sp_vech_suma, 
		sum(venit_brut) as venit_brut, sum(ret_CAS) as ret_CAS, sum(ret_somaj) as ret_somaj, sum(cass) as CASS, sum(deduceri) as deduceri, 
		sum(impozit) as impozit, sum(avans) as avans, sum(cuvenit_net) as cuvenit_net, 
	max(loc_de_munca_b),
	sum(isnull(s.proc_fct_suplim,0)) proc_fct_suplim, sum(isnull(s.suma_fct_suplim,0)) suma_fct_suplim,
	sum(s.venit_net) venit_net, sum(s.venit_impozabil) venit_impozabil, sum(s.sal_net) sal_net,
	sum(R01), sum(R02), sum(R03), sum(R04), sum(R05), sum(R06), sum(R07), sum(R08), sum(R09), sum(R10), sum(R11), sum(R12), sum(R13), 
		sum(R14), sum(R15), sum(alte_retineri), 
	max(DR01),max(DR02),max(DR03),max(DR04),max(DR05),max(DR06),max(DR07),max(DR08),max(DR09),max(DR10),max(DR11),max(DR12),max(DR13),max(DR14),max(DR15),
	sum(SP00), sum(SP01), sum(SP02), sum(SP03), sum(SP04), sum(SP05), sum(SP06), sum(SP07), sum(SP08), sum(SP09), sum(SP10), sum(SP11), 
		sum(SP12), sum(SP13), sum(SP14),
	max(DSP00), max(DSP01), max(DSP02), max(DSP03), max(DSP04), max(DSP05), max(DSP06), max(DSP07), max(DSP08), max(DSP09), max(DSP10), max(DSP11), max(DSP12), max(DSP13), max(DSP14),
	avg(s.PR00), avg(s.PR01), avg(s.PR02), avg(s.PR03), avg(s.PR04), avg(s.PR05), avg(s.PR06), avg(s.PR07), avg(s.PR08), avg(s.PR09), avg(s.PR10), avg(s.PR11), avg(s.PR12), avg(s.PR13), avg(s.PR14),
	sum(s.OR00), sum(s.OR01), sum(s.OR02), sum(s.OR03), sum(s.OR04), sum(s.OR05), sum(s.OR06), sum(s.OR07), sum(s.OR08), sum(s.OR09), sum(s.OR10), sum(s.OR11), sum(s.OR12), sum(s.OR13), sum(s.OR14),
	sum(s.valt_tichete), sum(s.nr_tichete), (case when @istoric=1 and max(s.nivel)=1 then count (distinct s.marca) else sum(s.angajati) end), sum(s.ore_invoiri)
	from #stat s
		left join #lm lm on lm.cod=s.parinte 
	where @i=lm.nivel and lm.cod is not null and s.nivel>0
	group by isnull(lm.cod_parinte,''), s.parinte
	
	set @i=@i-1
end

--	daca raport de istoric este nevoie de total pe marca
if @istoric=1
begin
	alter table #stat alter column parinte varchar(50)
	alter table #stat alter column cod varchar(50)
--	modific parintele pentru a face gruparea in raport pe marca	
	update #stat set parinte=parinte+marca where nivel=1

	insert into #stat (data,nume,nume_lm, nume_functie,nivel,cod_numeric_personal, regim_de_lucru, marca,parinte, cod, loc_de_munca, niv, 
	functia, proc_spor_vechime, suma_spor_vechime, salar_de_baza, sal_tarif, salar_orar, zi_lu, zi_co, zi_ev, zi_bo, zi_bs, 
	zi_ba, zi_cfs, zi_ne, salar_ore_lu, ore_lucrate,indice, sal_cuv, ind_cond, ind_cond_suma, total_salar, ore_neco, ind_co, ore_ev, ind_ev, ore_intr_tehn, ind_intr_tehn, ore_bo, suma_bo,
	ore_bs, suma_bs, ore_ba, suma_ba, ore_ne, ore_cfs, suplCM_ore, suplCM_suma, suplM_ore, suplM_suma, sp100_ore, sp100_suma, 
	noapte_ore, noapte_suma, proc_sist_prg,	sist_prg_ore, sist_prg_suma, 
	sp_vech_ore, sp_vech_suma, venit_brut, ret_CAS, ret_somaj, CASS, deduceri, 
	impozit, avans, cuvenit_net, loc_de_munca_b, proc_fct_suplim, suma_fct_suplim,
	venit_net, venit_impozabil, sal_net,
	R01,R02,R03,R04,R05,R06,R07,R08,R09,R10,R11,R12,R13,R14,R15,alte_retineri,
	DR01,DR02,DR03,DR04,DR05,DR06,DR07,DR08,DR09,DR10,DR11,DR12,DR13,DR14,DR15,
	SP00, SP01, SP02, SP03, SP04, SP05, SP06, SP07, SP08, SP09, SP10, SP11, SP12, SP13, SP14,
	DSP00, DSP01, DSP02, DSP03, DSP04, DSP05, DSP06, DSP07, DSP08, DSP09, DSP10, DSP11, DSP12, DSP13, DSP14,
	PR00, PR01, PR02, PR03, PR04, PR05, PR06, PR07, PR08, PR09, PR10, PR11,	PR12, PR13, PR14,
	OR00, OR01, OR02, OR03, OR04, OR05, OR06, OR07, OR08, OR09, OR10, OR11, OR12, OR13, OR14,
	valt_tichete, nr_tichete, angajati, ore_invoiri)
	select '' as data, (case when @grupare=4 then max(rtrim(s.nume_lm)) else max(s.nume) end) as nume, max(rtrim(s.nume_lm)) as nume_lm, '' as nume_functie, 2 as nivel, max(cod_numeric_personal) as cod_numeric_personal,
		max(regim_de_lucru) as regim_de_lucru, s.marca as marca,
--	la total pe marca parintele devine cod
		(case when @grupare=4 then max(cod_numeric_personal) else max(isnull(s.loc_de_munca,''))+space(5) end) as parinte, max(isnull(s.parinte,'')) as cod, max(s.loc_de_munca) as loc_de_munca, 
		max(s.niv)-1 as niv, max(isnull(functia,'')) as functia, max(isnull(proc_spor_vechime,0)) as proc_spor_vechime,
		max(isnull(suma_spor_vechime,0)) as suma_spor_vechime, max(salar_de_baza) as salar_de_baza, 
		sum(isnull(sal_tarif,0)) as sal_tarif, max(s.salar_orar) as salar_orar, 
		sum(zi_lu) as zi_lu, sum(s.zi_co) as zi_co, sum(zi_ev) as zi_ev,sum(zi_bo) as zi_bo, sum(zi_bs) as zi_bs, 
		sum(zi_ba) as zi_ba, sum(zi_cfs) as zi_cfs, sum(zi_ne) as zi_ne, 
		sum(salar_ore_lu) as salar_ore_lu, sum(ore_lucrate) as ore_lucrate,
		avg(isnull(indice,1)) as indice, sum(isnull(round(sal_cuv,0),0)) as sal_cuv, max(isnull(ind_cond,0)) as ind_cond	--max(?) => ident =>sum(?)
		, sum(ind_cond_suma) as ind_cond_suma, sum(total_salar) as total_salar, sum(ore_neco) as ore_neco, 
		sum(ind_co) as ind_co, sum(ore_ev) as ore_ev, sum(ind_ev) as ind_ev, sum(ore_intr_tehn) as ore_intr_tehn, sum(ind_intr_tehn) as ind_intr_tehn, 
		sum(ore_bo) as ore_bo, sum(suma_bo) as suma_bo, sum(ore_bs) as ore_bs, sum(suma_bs) as suma_bs, 
		sum(ore_ba) as ore_ba, sum(suma_ba) as suma_ba, sum(ore_ne) as ore_ne, sum(ore_cfs) as ore_cfs, 
		sum(suplCM_ore) as suplCM_ore, sum(suplcm_suma) as suplCM_suma,
		sum(suplM_ore) as suplM_ore, sum(suplm_suma) as suplM_suma, 
		sum(sp100_ore) as sp100_ore, sum(sp100_suma) as sp100_suma, 
		sum(noapte_ore) as noapte_ore, sum(round(noapte_suma,0)) as noapte_suma,
		max(proc_sist_prg),	sum(sist_prg_ore) as sist_prg_ore, sum(sist_prg_suma) as sist_prg_suma, 
		sum(sp_vech_ore) as sp_vech_ore, sum(sp_vech_suma) as sp_vech_suma, 
		sum(venit_brut) as venit_brut, sum(ret_CAS) as ret_CAS, sum(ret_somaj) as ret_somaj, sum(cass) as CASS, sum(deduceri) as deduceri, 
		sum(impozit) as impozit, sum(avans) as avans, sum(cuvenit_net) as cuvenit_net, 
	max(loc_de_munca_b),
	sum(isnull(s.proc_fct_suplim,0)) proc_fct_suplim, sum(isnull(s.suma_fct_suplim,0)) suma_fct_suplim,
	sum(s.venit_net) venit_net, sum(s.venit_impozabil) venit_impozabil, sum(s.sal_net) sal_net,
	sum(R01), sum(R02), sum(R03), sum(R04), sum(R05), sum(R06), sum(R07), sum(R08), sum(R09), sum(R10), sum(R11), sum(R12), sum(R13), 
		sum(R14), sum(R15), sum(alte_retineri), 
	max(DR01),max(DR02),max(DR03),max(DR04),max(DR05),max(DR06),max(DR07),max(DR08),max(DR09),max(DR10),max(DR11),max(DR12),max(DR13),max(DR14),max(DR15),
	sum(SP00), sum(SP01), sum(SP02), sum(SP03), sum(SP04), sum(SP05), sum(SP06), sum(SP07), sum(SP08), sum(SP09), sum(SP10), sum(SP11), 
		sum(SP12), sum(SP13), sum(SP14),
	max(DSP00), max(DSP01), max(DSP02), max(DSP03), max(DSP04), max(DSP05), max(DSP06), max(DSP07), max(DSP08), max(DSP09), max(DSP10), max(DSP11), max(DSP12), max(DSP13), max(DSP14),
	avg(s.PR00), avg(s.PR01), avg(s.PR02), avg(s.PR03), avg(s.PR04), avg(s.PR05), avg(s.PR06), avg(s.PR07), avg(s.PR08), avg(s.PR09), avg(s.PR10), avg(s.PR11), avg(s.PR12), avg(s.PR13), avg(s.PR14),
	sum(s.OR00), sum(s.OR01), sum(s.OR02), sum(s.OR03), sum(s.OR04), sum(s.OR05), sum(s.OR06), sum(s.OR07), sum(s.OR08), sum(s.OR09), sum(s.OR10), sum(s.OR11), sum(s.OR12), sum(s.OR13), sum(s.OR14),
	sum(s.valt_tichete), sum(s.nr_tichete), count (distinct s.marca), sum(s.ore_invoiri)
	from #stat s
	where s.nivel=1
	group by s.marca, s.loc_de_munca
	
	if @grupare=4
		insert into #stat (data,nume,nume_lm, nume_functie,nivel,cod_numeric_personal, regim_de_lucru, marca,parinte, cod, loc_de_munca, niv, 
		functia, proc_spor_vechime, suma_spor_vechime, salar_de_baza, sal_tarif, salar_orar, zi_lu, zi_co, zi_ev, zi_bo, zi_bs, 
		zi_ba, zi_cfs, zi_ne, salar_ore_lu, ore_lucrate,indice, sal_cuv, ind_cond, ind_cond_suma, total_salar, ore_neco, ind_co, ore_ev, ind_ev, ore_intr_tehn, ind_intr_tehn, ore_bo, suma_bo,
		ore_bs, suma_bs, ore_ba, suma_ba, ore_ne, ore_cfs, suplCM_ore, suplCM_suma, suplM_ore, suplM_suma, sp100_ore, sp100_suma, 
		noapte_ore, noapte_suma, proc_sist_prg,	sist_prg_ore, sist_prg_suma, 
		sp_vech_ore, sp_vech_suma, venit_brut, ret_CAS, ret_somaj, CASS, deduceri, 
		impozit, avans, cuvenit_net, loc_de_munca_b, proc_fct_suplim, suma_fct_suplim,
		venit_net, venit_impozabil, sal_net,
		R01,R02,R03,R04,R05,R06,R07,R08,R09,R10,R11,R12,R13,R14,R15,alte_retineri,
		DR01,DR02,DR03,DR04,DR05,DR06,DR07,DR08,DR09,DR10,DR11,DR12,DR13,DR14,DR15,
		SP00, SP01, SP02, SP03, SP04, SP05, SP06, SP07, SP08, SP09, SP10, SP11, SP12, SP13, SP14,
		DSP00, DSP01, DSP02, DSP03, DSP04, DSP05, DSP06, DSP07, DSP08, DSP09, DSP10, DSP11, DSP12, DSP13, DSP14,
		PR00, PR01, PR02, PR03, PR04, PR05, PR06, PR07, PR08, PR09, PR10, PR11,	PR12, PR13, PR14,
		OR00, OR01, OR02, OR03, OR04, OR05, OR06, OR07, OR08, OR09, OR10, OR11, OR12, OR13, OR14,
		valt_tichete, nr_tichete, angajati, ore_invoiri)
		select '' as data, max(s.nume) as nume, max(rtrim(s.nume)) as nume_lm, '' as nume_functie, 3 as nivel, cod_numeric_personal,
			max(regim_de_lucru) as regim_de_lucru, '' as marca,
	--	la total pe CNP, CNP-ul devine cod
			max(isnull(s.loc_de_munca,''))+space(4) as parinte, cod_numeric_personal as cod, max(s.loc_de_munca) as loc_de_munca, 
			max(s.niv)-2 as niv, max(isnull(functia,'')) as functia, max(isnull(proc_spor_vechime,0)) as proc_spor_vechime,
			max(isnull(suma_spor_vechime,0)) as suma_spor_vechime, max(salar_de_baza) as salar_de_baza, 
			sum(isnull(sal_tarif,0)) as sal_tarif, max(s.salar_orar) as salar_orar, 
			sum(zi_lu) as zi_lu, sum(s.zi_co) as zi_co, sum(zi_ev) as zi_ev,sum(zi_bo) as zi_bo, sum(zi_bs) as zi_bs, 
			sum(zi_ba) as zi_ba, sum(zi_cfs) as zi_cfs, sum(zi_ne) as zi_ne, 
			sum(salar_ore_lu) as salar_ore_lu, sum(ore_lucrate) as ore_lucrate,
			avg(isnull(indice,1)) as indice, sum(isnull(round(sal_cuv,0),0)) as sal_cuv, max(isnull(ind_cond,0)) as ind_cond	--max(?) => ident =>sum(?)
			, sum(ind_cond_suma) as ind_cond_suma, sum(total_salar) as total_salar, sum(ore_neco) as ore_neco, 
			sum(ind_co) as ind_co, sum(ore_ev) as ore_ev, sum(ind_ev) as ind_ev, sum(ore_intr_tehn) as ore_intr_tehn, sum(ind_intr_tehn) as ind_intr_tehn, 
			sum(ore_bo) as ore_bo, sum(suma_bo) as suma_bo, sum(ore_bs) as ore_bs, sum(suma_bs) as suma_bs, 
			sum(ore_ba) as ore_ba, sum(suma_ba) as suma_ba, sum(ore_ne) as ore_ne, sum(ore_cfs) as ore_cfs, 
			sum(suplCM_ore) as suplCM_ore, sum(suplcm_suma) as suplCM_suma,
			sum(suplM_ore) as suplM_ore, sum(suplm_suma) as suplM_suma, 
			sum(sp100_ore) as sp100_ore, sum(sp100_suma) as sp100_suma, 
			sum(noapte_ore) as noapte_ore, sum(round(noapte_suma,0)) as noapte_suma,
			max(proc_sist_prg),	sum(sist_prg_ore) as sist_prg_ore, sum(sist_prg_suma) as sist_prg_suma, 
			sum(sp_vech_ore) as sp_vech_ore, sum(sp_vech_suma) as sp_vech_suma, 
			sum(venit_brut) as venit_brut, sum(ret_CAS) as ret_CAS, sum(ret_somaj) as ret_somaj, sum(cass) as CASS, sum(deduceri) as deduceri, 
			sum(impozit) as impozit, sum(avans) as avans, sum(cuvenit_net) as cuvenit_net, 
		max(loc_de_munca_b),
		sum(isnull(s.proc_fct_suplim,0)) proc_fct_suplim, sum(isnull(s.suma_fct_suplim,0)) suma_fct_suplim,
		sum(s.venit_net) venit_net, sum(s.venit_impozabil) venit_impozabil, sum(s.sal_net) sal_net,
		sum(R01), sum(R02), sum(R03), sum(R04), sum(R05), sum(R06), sum(R07), sum(R08), sum(R09), sum(R10), sum(R11), sum(R12), sum(R13), 
			sum(R14), sum(R15), sum(alte_retineri), 
		max(DR01),max(DR02),max(DR03),max(DR04),max(DR05),max(DR06),max(DR07),max(DR08),max(DR09),max(DR10),max(DR11),max(DR12),max(DR13),max(DR14),max(DR15),
		sum(SP00), sum(SP01), sum(SP02), sum(SP03), sum(SP04), sum(SP05), sum(SP06), sum(SP07), sum(SP08), sum(SP09), sum(SP10), sum(SP11), 
			sum(SP12), sum(SP13), sum(SP14),
		max(DSP00), max(DSP01), max(DSP02), max(DSP03), max(DSP04), max(DSP05), max(DSP06), max(DSP07), max(DSP08), max(DSP09), max(DSP10), max(DSP11), max(DSP12), max(DSP13), max(DSP14),
		avg(s.PR00), avg(s.PR01), avg(s.PR02), avg(s.PR03), avg(s.PR04), avg(s.PR05), avg(s.PR06), avg(s.PR07), avg(s.PR08), avg(s.PR09), avg(s.PR10), avg(s.PR11), avg(s.PR12), avg(s.PR13), avg(s.PR14),
		sum(s.OR00), sum(s.OR01), sum(s.OR02), sum(s.OR03), sum(s.OR04), sum(s.OR05), sum(s.OR06), sum(s.OR07), sum(s.OR08), sum(s.OR09), sum(s.OR10), sum(s.OR11), sum(s.OR12), sum(s.OR13), sum(s.OR14),
		sum(s.valt_tichete), sum(s.nr_tichete), count (distinct s.marca), sum(s.ore_invoiri)
		from #stat s
		where s.nivel=1
		group by s.cod_numeric_personal
End

--	selectez din functii_lm pozitiile valabile la data generarii raportului
	select * into #functii_lm from 
	(select Data, Loc_de_munca, Cod_functie, Pozitie_stat, RANK() 
		over (partition by Loc_de_munca, Cod_functie order by Data Desc) as ordine
	from functii_lm where (@locm is null or Loc_de_munca like rtrim(@locm)+'%')
		and (@q_functii is null or Cod_functie=@q_functii) and (@q_tipSalarizare is null or Tip_personal=@q_tipSalarizare) and Data<=@q_datasus) a
	where Ordine=1

--	apel procedura specifica (daca exista) care va permite modificarea datelor din tabela #stat (dupa prelucrarea randurilor de total si inainte de selectul final)
if exists (select * from sysobjects where name ='rapStatDePlataSP1' and xtype='P')
	exec rapStatDePlataSP1 @datajos=@datajos, @datasus=@datasus, @cu_tabel=@cu_tabel, @grupare=@grupare, @rettip=@rettip, @istoric=@istoric

if @niveltotalizare is not null and @grupare in (0,1,3)
	delete from #stat where niv>@niveltotalizare

select /*s.SP00, s.SP01, s.SP02, s.SP03, s.SP04, s.SP05, s.SP06, s.SP07, s.SP08, s.SP09, s.SP10, s.SP11, s.SP12, s.SP13, s.SP14,
	s.R01, s.R02, s.R03, s.R04, s.R05, s.R06, s.R07, s.R08, s.R09, s.R10, s.R11, s.R12, s.R13, s.R14, s.R15,*/
	s.data, nume, nume_lm, nume_functie, nivel as nivel,cod_numeric_personal as cnp,marca, parinte, cod, s.loc_de_munca as loc_de_munca,
	niv, functia, proc_spor_vechime, suma_spor_vechime, salar_de_baza, sal_tarif, salar_orar, zi_lu, zi_co,zi_ev, zi_bo, zi_bs, zi_ba, zi_cfs, 
	zi_ne, salar_ore_lu, ore_lucrate,indice, sal_cuv, ind_cond, ind_cond_suma, total_salar, ore_neco, ore_bo, suma_bo, ore_bs, suma_bs, 
	ore_ba, suma_ba, ore_intr_tehn, ind_intr_tehn, ore_ne, ore_cfs, suplCM_ore, suplCM_suma, suplM_ore, suplM_suma, sp100_ore, sp100_suma, noapte_ore, noapte_suma, 
	proc_sist_prg, sist_prg_ore, sist_prg_suma, sp_vech_ore, sp_vech_suma, venit_brut, ret_CAS, ret_somaj, CASS, deduceri, 
	impozit, avans, cuvenit_net, regim_de_lucru as RN,ind_co, ore_ev, ind_ev , @nr_zile_lucr_luna nr_zile_lucr_luna,
	s.proc_fct_suplim, s.suma_fct_suplim, s.venit_net, s.venit_impozabil, sal_net,
	s.R01, s.R02, s.R03, s.R04, s.R05, s.R06, s.R07, s.R08, s.R09, s.R10, s.R11, s.R12, s.R13, s.R14, s.R15, s.alte_retineri, 
	s.DR01, s.DR02, s.DR03, s.DR04, s.DR05, s.DR06, s.DR07, s.DR08, s.DR09, s.DR10, s.DR11, s.DR12, s.DR13, s.DR14, s.DR15,
	s.SP00, s.SP01, s.SP02, s.SP03, s.SP04, s.SP05, s.SP06, s.SP07, s.SP08, s.SP09, s.SP10, s.SP11, s.SP12, s.SP13, s.SP14,
	s.DSP00, s.DSP01, s.DSP02, s.DSP03, s.DSP04, s.DSP05, s.DSP06, s.DSP07, s.DSP08, s.DSP09, s.DSP10, s.DSP11, s.DSP12, s.DSP13, s.DSP14,
	s.PR00, s.PR01, s.PR02, s.PR03, s.PR04, s.PR05, s.PR06, s.PR07, s.PR08, s.PR09, s.PR10, s.PR11,	s.PR12, s.PR13, s.PR14,
	s.OR00, s.OR01, s.OR02, s.OR03, s.OR04, s.OR05, s.OR06, s.OR07, s.OR08, s.OR09, s.OR10, s.OR11, s.OR12, s.OR13, s.OR14,
	s.valt_tichete, s.nr_tichete, s.angajati, s.ore_invoiri
from #stat s
left outer join #functii_lm f on f.Loc_de_munca=s.loc_de_munca and f.Cod_functie=s.functia
	where (@grupare=3 or @grupare=1 or @grupare=0 and (@istoric=0 and nivel=2 or @istoric=1 and nivel=3) 
			or (@grupare=2 or @grupare=4) and (nivel=2 and (cod='<T>' or @istoric=1) or nivel=1) or @grupare=4 and nivel=3)
		--and niv<2
	order by (case when @grupare in (2,4) then '' else nivel end)--len(rtrim(cod)),loc_de_munca asc, nume asc --len(rtrim(functia)) asc ,rtrim(functia) asc
	,(case when @grupare in (2,4) then '' else s.loc_de_munca end)
	,(case when @grupare=3 then isnull(replicate('0',6-len(convert(varchar(6),f.Pozitie_stat)))+convert(varchar(10),f.Pozitie_stat),functia) else '' end)
	,(case when @grupare=3 then marca else nume end), data
	--*/--*/--*/--*/--*/--*/--*/--*/--*/--*/
end try
begin catch
	set @eroare='Procedura rapStatDePlata (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

if object_id('tempdb..#cfgrapps') is not null drop table #cfgrapps
if object_id('tempdb..#sumecfg') is not null drop table #sumecfg
if object_id('tempdb..#personal') is not null drop table #personal
if object_id('tempdb..#stat') is not null drop table #stat
if object_id('tempdb..#lm') is not null drop table #lm
if object_id('tempdb..#benret') is not null drop table #benret
if object_id('tempdb..#functii_lm') is not null drop table #functii_lm
--*/
