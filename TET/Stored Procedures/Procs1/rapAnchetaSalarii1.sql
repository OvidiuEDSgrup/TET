--***
Create procedure rapAnchetaSalarii1 
	(@dataJos datetime, @dataSus datetime, @setlm varchar(20)=null)
as
declare @eroare varchar(2000)
begin try
	set transaction isolation level read uncommitted
	if object_id('tempdb..#randuri') is not null drop table #randuri
	if object_id('tempdb..#brut') is not null drop table #brut
	if object_id('tempdb..#pontaj') is not null drop table #pontaj
	if object_id('tempdb..#istPers') is not null drop table #istPers

	declare @utilizator varchar(20), @lista_lm int, @q_datajos datetime, @q_datasus datetime, @q_sal_min int, @IT1SuspContr int, @IT2SuspContr int, @IT3SuspContr int

	set @utilizator = dbo.fIaUtilizator(null)	-- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	set @q_datajos=@dataJos set @q_datasus=@dataSus 
	set @q_sal_min=dbo.iauParLN(@dataSus,'PS','S-MIN-BR')
	select @IT1SuspContr=max(case when Parametru='IT1-SUSPC' then Val_logica else 0 end),
		@IT2SuspContr=max(case when Parametru='PROC2INT' then Val_logica else 0 end),
		@IT3SuspContr=max(case when Parametru='PROC3INT' then Val_logica else 0 end)
	from par 
	where Tip_parametru='PS' and Parametru in ('IT1-SUSPC','PROC2INT','PROC3INT')

	select i.* into #istpers
	from istPers i
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.Loc_de_munca
	where i.data between @q_datajos and @q_datasus	
		and (@lista_lm=0 or lu.cod is not null)
		and (@setlm is null or exists (select 1 from proprietati p where p.Cod_proprietate='TIPBALANTA' and p.Tip='LM' and valoare=@setlm and rtrim(i.Loc_de_munca) like rtrim(p.cod)+'%'))

	select b.data, b.marca, sum(ore_lucrate_regim_normal) as ore_lucrate_regim_normal, sum(ore_concediu_de_odihna) as ore_concediu_de_odihna,
		sum(ore_intrerupere_tehnologica) as ore_intrerupere_tehnologica, SUM(ore_obligatii_cetatenesti) as ore_obligatii_cetatenesti,
		sum(venit_total-Ind_c_medical_CAS-Ind_c_medical_unitate-Spor_cond_9-CMCAS-CMunitate) as venit_total
	into #brut
	from brut b
		inner join #istPers i on i.Data=b.Data and i.Marca=b.Marca
	where b.data between @q_datajos and @q_datasus
	group by b.data, b.marca

	select dbo.eom(p.data) as data, p.marca, 
		sum((case when @IT1SuspContr=0 then ore_intrerupere_tehnologica else 0 end)) as ore_intrerupere_tehnologica, 
		sum((case when @IT1SuspContr=0 then ore else 0 end)) as ore_intrerupere_tehnologica_2, 
		sum((case when @IT3SuspContr=0 then Spor_cond_8 else 0 end)) as ore_intrerupere_tehnologica_3
	into #pontaj
	from pontaj p
		inner join istPers i on i.Data=dbo.eom(p.data) and i.Marca=p.Marca
	where p.data between @q_datajos and @q_datasus
	group by dbo.eom(p.data), p.marca

	select '1' as ordine,-2 as grupa,'TOTAL' as nume_grupa, 0 as int_jos, 100000 as int_sus into #randuri union all
	select '1' as ordine,-1 as grupa,'din care: femei' as nume_grupa, 0 as int_jos, 100000 as int_sus union all
	select '4' as ordine,0 as grupa,'MUNCITORI' as nume_grupa, 0 as int_jos, 100000 as int_sus union all
	select '4' as ordine,1 as grupa,'Sub sal de baza min brut pe tara' as nume_grupa, 1 as int_jos, @q_sal_min-1 as int_sus union all
	select '4' as ordine,2,'La nivelul sal de baza min brut pe tara' as nume_grupa, @q_sal_min as int_jos, @q_sal_min as int_sus union all
	select '4' as ordine,3,'Peste sal de baza min brut pe tara - pana la 800' as nume_grupa, @q_sal_min+1 as int_jos, 800 as int_sus union all
	select '4' as ordine,4,'' as nume_grupa, 801 as int_jos, 1000 as int_sus union all
	select '4' as ordine,5,'' as nume_grupa, 1001 as int_jos, 1500 as int_sus union all
	select '4' as ordine,6,'' as nume_grupa, 1501 as int_jos, 2000 as int_sus union all
	select '4' as ordine,7,'' as nume_grupa, 2001 as int_jos, 3000 as int_sus union all
	select '4' as ordine,8,'' as nume_grupa, 3001 as int_jos, 4000 as int_sus union all
	select '4' as ordine,9,'' as nume_grupa, 4001 as int_jos, 5000 as int_sus union all
	select '4' as ordine,10,'' as nume_grupa, 5001 as int_jos, 6000 as int_sus union all
	select '4' as ordine,11,'' as nume_grupa, 6001 as int_jos, 7000 as int_sus union all
	select '4' as ordine,12,'' as nume_grupa, 7001 as int_jos, 8000 as int_sus union all
	select '4' as ordine,13,'peste 8000' as nume_grupa, 8001 as int_jos, 100000 as int_sus

	update #randuri set nume_grupa=convert(varchar(10),int_jos)+' - '+convert(varchar(10),int_sus) where nume_grupa=''

	select (case when c.grupa>0 then 'Repartizarea salariatilor din coloana 3 pe grupe de salarii brute realizate (lei) in luna '
								+isnull((select max(rtrim(lunaalfa)) from calstd cl where cl.luna=month(max(b.data))),
									convert(varchar(2),month(max(b.data))))+' '+convert(varchar(4),year(max(b.data)))
							else '' end) as grupa_tip,
	max(c.ordine+r.ordine) as ordine,
		sum(case when (r.grupa=-1 or c.grupa=-1) and p.sex=1 then 0
				 when (c.grupa=0) then 
					(case when i.grupa_de_munca in ('N','D','S') and ore_lucrate_regim_normal+ore_concediu_de_odihna
						+po.ore_intrerupere_tehnologica+po.ore_intrerupere_tehnologica_2+po.ore_intrerupere_tehnologica_3+ore_obligatii_cetatenesti>=l.val_numerica/8*
						(case when i.salar_lunar_de_baza<>0 then i.salar_lunar_de_baza else 8 end) and not((r.grupa=0) and isnull(f.cod_functie,'')<='4') 
					and not ((r.grupa>=0) and (r.grupa<14)and isnull(f.cod_functie,'')<='4' or (r.grupa>=14) and isnull(f.cod_functie,'')>'4') then 1 else 0 end)
				 when (r.grupa>=0) and (r.grupa<14)and isnull(f.cod_functie,'')<='4' or (r.grupa>=14) and isnull(f.cod_functie,'')>'4' then 0
			else (case when (r.grupa>=0) and (r.grupa<14)and isnull(f.cod_functie,'')<='4' or (r.grupa>=14) and isnull(f.cod_functie,'')>'4' then 0 
			else (case when ((c.grupa>0) and (c.grupa<14)) and (i.grupa_de_munca not in ('N','D','S') or ore_lucrate_regim_normal+ore_concediu_de_odihna
				+po.ore_intrerupere_tehnologica+po.ore_intrerupere_tehnologica_2+po.ore_intrerupere_tehnologica_3+ore_obligatii_cetatenesti<l.val_numerica/8*
					(case when i.salar_lunar_de_baza<>0 then i.salar_lunar_de_baza else 8 end)) then 0 else 1 end) end) end) as det,
		max(r.grupa) as grupa_rand, max(c.grupa) as grupa_col,	--Salar_de_baza, --isnull((select 1 from pontaj where ),0)i.*
		max(case when r.grupa<>14 then r.nume_grupa else 'ALTE CATEGORII DE SALARIATI' end) as nume_rand,
		max(case rtrim(c.nume_grupa) 
				when 'Total' then 'Efectivul de salariati la '+convert(varchar(10),@q_datasus,103)
				when 'MUNCITORI' then 'Nr sal care au lucrat cel putin '+convert(varchar(2),l.val_numerica/8)+' de zile si au fost platiti integral'
			else c.nume_grupa end) as nume_col
	from (select ordine, grupa, nume_grupa, int_jos, int_sus from #randuri union all select '5' as ordine, grupa+14, nume_grupa, int_jos, int_sus from #randuri where grupa>=0)	r
		left join #randuri c on 1=1 
		left join par_lunari l on l.Data between @q_datajos and @q_datasus and l.Tip='PS' and l.parametru='ORE_LUNA'
		left join #istpers i on 1=1 and i.salar_de_baza between r.int_jos and r.int_sus 
		left join #brut b on i.marca=b.marca and b.data between @q_datajos and @q_datasus and b.venit_total between c.int_jos and c.int_sus
		left join #pontaj po on i.marca=po.marca and po.data between @q_datajos and @q_datasus 
		left join personal p on i.marca=p.marca
		left outer join extinfop e on i.cod_functie=e.marca and e.Cod_inf='#CODCOR'
		left outer join functii_cor f on e.val_inf=f.Cod_functie
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.Loc_de_munca
	where i.data between @q_datajos and @q_datasus	
		and (isnull(i.salar_de_baza,-1) between r.int_jos and r.int_sus and isnull(b.venit_total,-1) between c.int_jos and c.int_sus) 
		and (@lista_lm=0 or lu.cod is not null)
	group by r.grupa,c.grupa
	order by ordine,grupa_col,grupa_rand

	drop table #randuri

end try

begin catch
	set @eroare='Procedura rapAnchetaSalarii1 (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
	
if object_id('tempdb..#randuri') is not null drop table #randuri
if object_id('tempdb..#brut') is not null drop table #brut
if object_id('tempdb..#pontaj') is not null drop table #pontaj
