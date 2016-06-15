--***
	--/*
create procedure statwebg(@datajos datetime,@datasus datetime, @locm char(20),
	@marci varchar(30),@functii varchar(30),@cu_tabel bit=0)
as--*/

declare @q_datajos datetime,@q_datasus datetime, @q_locm varchar(20),
	@q_marci varchar(300),@q_functii varchar(300),@q_grupare int, @q_centru varchar(1)
set @q_datajos=@datajos set @q_datasus=@datasus set @q_locm=@locm 
	 set @q_marci=@marci set @q_functii=@functii
declare @i int, @niv int		set @i=(select max(nivel) from lm) set @niv=1

declare @unitbuget int, @dafora int, @regimlv int, @ore_luna int, @nrmedol int
select @unitbuget=val_logica from par where Parametru='unitbuget' and Tip_parametru='PS'
select @dafora=val_logica from par where Parametru='dafora'
select @regimlv=val_logica from par where Parametru='regimlv' and Tip_parametru='PS'
select @ore_luna=val_numerica from par_lunari where Parametru='ore_luna' and Tip='PS' and data=@datasus
select @nrmedol=val_numerica from par_lunari where Parametru='nrmedol' and Tip='PS' and data=@datasus

select @unitbuget=ISNULL(@unitbuget,0), @dafora=ISNULL(@dafora,0), @regimlv=isnull(@regimlv ,0)

declare @utilizator varchar(20)  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
SET @utilizator = dbo.fIaUtilizator('')
IF @utilizator IS NULL
	RETURN -1

select e.loc_ramas_vacant,max(i.nume) as nume,max(e.cod_numeric_personal) as cod_numeric_personal,max(i.cod_functie) as cod_functie,
			max(i.marca) as marca,max(i.loc_de_munca) as loc_de_munca,max(i.spor_vechime) as spor_vechime,max(i.salar_de_incadrare) as salar_de_incadrare
			,max(i.Indemnizatia_de_conducere) as Indemnizatia_de_conducere
		,max(i.grupa_de_munca) as grupa_de_munca,max(i.data_plec) as data_plec,max(i.salar_de_baza/(168*(case when i.salar_lunar_de_baza=0 then 8 else i.salar_lunar_de_baza end)/8)) as salar_lunar,
		MAX(e.Salar_de_baza) as salar_de_baza1,MAX(e.Salar_lunar_de_baza) as salar_lunar_de_baza,MAX(e.Tip_salarizare) as Tip_salarizare,
		isnull((select sum(rr.valoare_retinuta_pe_doc)  from tipret tt inner join benret bb on tt.subtip=bb.tip_retinere
		inner join resal rr on rr.cod_beneficiar=bb.cod_beneficiar where tt.denumire like '%sindicat%' and rr.marca=i.marca
		and rr.Data between @q_datajos and @q_datasus),0) as sind,
	isnull((select sum(rr.valoare_retinuta_pe_doc)  from tipret tt inner join benret bb on tt.subtip=bb.tip_retinere
		inner join resal rr on rr.cod_beneficiar=bb.cod_beneficiar where tt.denumire='car' and rr.marca=i.marca
		and rr.Data between @q_datajos and @q_datasus),0) as car,
	isnull((select sum(rr.valoare_retinuta_pe_doc)  from tipret tt inner join benret bb on tt.subtip=bb.tip_retinere
		inner join resal rr on rr.cod_beneficiar=bb.cod_beneficiar where tt.denumire='apdp' and rr.marca=i.marca
		and rr.Data between @q_datajos and @q_datasus),0) as apdp,
	isnull((select sum(rr.valoare_retinuta_pe_doc)  from tipret tt inner join benret bb on tt.subtip=bb.tip_retinere
					inner join resal rr on rr.cod_beneficiar=bb.cod_beneficiar where tt.denumire like '%popriri%' and 
					rr.marca=i.marca and rr.Data between @q_datajos and @q_datasus
			),0) as prop,
	isnull((select sum(rr.valoare_retinuta_pe_doc)  from tipret tt inner join benret bb on tt.subtip=bb.tip_retinere
					inner join resal rr on rr.cod_beneficiar=bb.cod_beneficiar where tt.denumire like '%garant%' and 
						rr.marca=i.marca and rr.Data between @q_datajos and @q_datasus
			),0) as garantii,
	isnull((select sum(rr.valoare_retinuta_pe_doc)  from tipret tt inner join benret bb on tt.subtip=bb.tip_retinere
					inner join resal rr on rr.cod_beneficiar=bb.cod_beneficiar where tt.denumire like '%echipament%' and 
						rr.marca=i.marca and rr.Data between @q_datajos and @q_datasus
			),0) as echipamente
		into #personal
		 from istpers i left join personal e on i.marca=e.marca
		where (e.marca=@q_marci or @q_marci is null) and (e.cod_functie=@q_functii or @q_functii is null)
		and (e.loc_ramas_vacant=0 or e.data_plec>@q_datajos) and i.data=@q_datasus
		group by i.marca,e.loc_ramas_vacant		-- personal si exceptii

select rtrim(isnull(e.nume,'')) as nume,rtrim(isnull(lm.denumire,'')) as nume_lm, rtrim(isnull(f.denumire,'')) as nume_functie, 
	1 as nivel,e.cod_numeric_personal, -- denumiri
	p.regim_de_lucru,
	isnull(e.cod_functie,'')+' '+isnull(e.marca,'') as marca, isnull(lm.cod,'') as parinte,
	isnull(e.cod_functie,'')+' '+isnull(e.marca,'') as cod,
	(case when @q_grupare=0 then isnull(p.loc_de_munca,e.loc_de_munca) else e.loc_de_munca end)
	--e.loc_de_munca
	as loc_de_munca, lm.nivel+1 as niv,
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
	(isnull(b.realizat_regie,0)+isnull(b.realizat_acord,0))/isnull(nn.nr,1000000000) as total_salar,
	isnull(p.Ore_concediu_de_odihna,0) as ore_neco,
	--(isnull(b.ind_concediu_de_odihna,0))/nn.nr as suma_neco, 
	isnull(c.ind_co,0)/isnull(nn.nr,1000000000) as ind_co,	isnull(c.ind_ev,0)/isnull(nn.nr,1000000000) as ind_ev,
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
	isnull(p.proc_sist_prg,0) as proc_sist_prg,isnull(p.proc_inloc,0) as proc_inloc,isnull(p.proc_inf,0) as proc_inf,
	isnull(p.proc_mast,0) as proc_mast,isnull(p.proc_op_calc,0) as proc_op_calc,isnull(p.proc_mobil,0) as proc_mobil,
	isnull(p.sist_prg_ore,0) as sist_prg_ore,isnull(p.sist_prg_suma,0)/100 as sist_prg_suma,		--(ok)
	isnull(p.inloc_ore,0) as inloc_ore,isnull(b.inloc_suma,0) as inloc_suma, isnull(p.inf_ore,0) as inf_ore,
	isnull(p.inf_suma,0)/100 as inf_suma,	
	isnull(p.master_ore,0) as master_ore,isnull(p.master_suma,0)/100 as master_suma,
	isnull(p.op_calc_ore,0) as op_calc_ore,isnull(p.op_calc_suma,0)/100 as op_calc_suma,isnull(p.mobil_ore,0) as mobil_ore,
	isnull(p.mobil_suma,0)/100 as mobil_suma,	-- (ok)
	isnull(p.ore_lucrate,0) as sp_vech_ore,isnull(b.spor_vechime,0)/isnull(nn.nr,100000000) as sp_vech_suma, 
	-- date aferente marcilor
	b.venit_brut/isnull(nn.nr,100000000) as venit_brut,n.ret_CAS/isnull(nn.nr,100000000) ret_CAS,n.somaj_1/isnull(nn.nr,100000000) as ret_somaj,
		n.CASS/isnull(nn.nr,100000000) cass,n.ded/isnull(nn.nr,100000000) as deduceri,
	isnull(cr.avans,0)/isnull(nn.nr,100000000) as premii,
	isnull(cr.diminuari,0)/isnull(nn.nr,100000000) as diminuari,
	e.sind/isnull(nn.nr,100000000) as sind,
	isnull(cr.corectii,0)/isnull(nn.nr,100000000) as corectii,isnull(n.impozit,0)/isnull(nn.nr,100000000)  as impozit,
		isnull(n.avans,0)/isnull(nn.nr,100000000) as avans,isnull(cr.avans_co,0)/isnull(nn.nr,100000000) as avans_co,
	e.car/isnull(nn.nr,100000000) as car,
	e.apdp/isnull(nn.nr,100000000) as apdp,n.rest_de_plata/isnull(nn.nr,100000000) 
		as cuvenit_net,
	isnull(cr.pr_vac,0)/isnull(nn.nr,100000000) as pr_vac,
	isnull(cr.pr_pens,0)/isnull(nn.nr,100000000) as pr_pens,
	isnull(cr.profit,0)/isnull(nn.nr,100000000) as profit,
	e.prop/isnull(nn.nr,100000000) as prop,
	e.garantii/isnull(nn.nr,100000000) as garantii,
	e.echipamente/isnull(nn.nr,100000000) as echipamente,
	isnull(cr.alte_ret,0)/isnull(nn.nr,100000000) as alte_ret,
		isnull(cr.cor_prem,0)/isnull(nn.nr,100000000) as cor_prem,b.loc_de_munca as loc_de_munca_b
into #stat
from #personal as e
	left join (select marca,sum(b.realizat__regie) as realizat_regie,sum(b.realizat_acord) as realizat_acord,
					sum(b.ind_concediu_de_odihna) as ind_concediu_de_odihna,sum(venit_total) as venit_brut,sum(b.premiu) as premii, 
					sum(isnull(ore_de_noapte,0)) as ore_de_noapte, sum(isnull(ind_ore_de_noapte,0)) as ind_ore_de_noapte,
					sum(isnull(Spor_cond_4,0)) as op_calc_suma,sum(isnull(Spor_cond_2,0)) as inf_suma,
					sum(isnull(Spor_cond_3,0)) as master_suma,sum(isnull(Spor_cond_5,0)) as 
mobil_suma,sum(isnull(Spor_cond_1,0)) as inloc_suma,
					sum(isnull(spor_vechime,0)) as spor_vechime,max(b.ind_nemotivate) as indemnizatia_de_conducere,
					sum(isnull(Ind_c_medical_unitate,0)) as Ind_c_medical_unitate,
					sum(b.spor_sistematic_peste_program) as spor_sistematic_peste_program,
					sum(b.Indemnizatie_ore_supl_1) as Indemnizatie_ore_supl_1,sum(b.Indemnizatie_ore_supl_2) as Indemnizatie_ore_supl_2,
					sum(b.Indemnizatie_ore_spor_100) as Indemnizatie_ore_spor_100,max(b.loc_de_munca) as loc_de_munca
		from brut b where data between @q_datajos and @q_datasus group by b.marca) b on b.marca=e.marca			-- b
	left join (select max(p.loc_de_munca) as loc_de_munca,p.marca,max(isnull(p.salar_orar,0))  as salar_orar,sum(isnull(p.ore_regie,0)) as 
ore_regie,			sum(isnull(ore_acord,0)) as ore_acord,
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
					sum(isnull(p.spor_conditii_1,0)*isnull(p.ore__cond_1,0)*isnull((case when 
							isnull(p.salar_categoria_lucrarii,0)<>0 then p.salar_categoria_lucrarii else p.salar_orar end),0)) as inloc_suma,
					sum(isnull(p.ore_lucrate,0)*isnull((case when 
							isnull(p.salar_categoria_lucrarii,0)<>0 then p.salar_categoria_lucrarii else p.salar_orar end),0)) as salar_ore_lu,
					sum(isnull(p.ore__cond_2,0)*isnull(p.spor_conditii_2,0)*isnull((case when 
							isnull(p.salar_categoria_lucrarii,0)<>0 then p.salar_categoria_lucrarii else p.salar_orar end),0)) as inf_suma,
					sum(isnull(p.ore__cond_3,0)*isnull(p.spor_conditii_3,0)*isnull((case when 
							isnull(p.salar_categoria_lucrarii,0)<>0 then p.salar_categoria_lucrarii else p.salar_orar end),0)) as master_suma,
					sum(isnull(p.ore__cond_4,0)*isnull(p.spor_conditii_4,0)*isnull((case when 
							isnull(p.salar_categoria_lucrarii,0)<>0 then p.salar_categoria_lucrarii else p.salar_orar end),0)) as op_calc_suma,
					sum(isnull(p.ore__cond_5,0)*isnull(p.spor_conditii_5,0)*isnull((case when 
							isnull(p.salar_categoria_lucrarii,0)<>0 then p.salar_categoria_lucrarii else p.salar_orar end),0)) as mobil_suma,
					max(isnull(regim_de_lucru,8)) as regim_de_lucru,sum(isnull(p.Ore_concediu_de_odihna,0)) as Ore_concediu_de_odihna,
					sum(p.ore_concediu_fara_salar) as ore_concediu_fara_salar,sum(p.ore_nemotivate) as ore_nemotivate,
					sum(isnull(p.ore_suplimentare_1,0)) as ore_suplim_cm, sum(isnull(p.ore_suplimentare_2,0)) as ore_suplim_m,
					sum(isnull(p.ore_spor_100,0)) as ore_spor_100,sum(isnull(p.ore_de_noapte,0)) as ore_de_noapte,
					sum(isnull(p.ore_sistematic_peste_program,0)) as sist_prg_ore,
					sum(isnull(p.ore__cond_1,0)) as inloc_ore,	sum(isnull(p.ore__cond_2,0)) as inf_ore,		
					sum(isnull(p.ore__cond_3,0)) as master_ore,	sum(isnull(p.ore__cond_4,0)) as op_calc_ore,
					sum(isnull(p.ore__cond_5,0)) as mobil_ore,	sum(isnull(p.ore_lucrate,0)) as ore_lucrate,
					max(isnull(p.Sistematic_peste_program,0)) as proc_sist_prg,max(isnull(p.spor_conditii_1,0)) as proc_inloc,max(isnull(p.spor_conditii_2,0)) as proc_inf,
					max(isnull(p.spor_conditii_3,0)) as proc_mast,max(isnull(p.spor_conditii_4,0)) as proc_op_calc,max(isnull(p.spor_conditii_5,0)) as proc_mobil
					from pontaj p
					where p.data between @q_datajos and @q_datasus group by p.marca ,
					(case when @q_grupare=0 then p.loc_de_munca else '' end)
				) p on p.marca=e.marca	-- p
	left join (select count(distinct (case when @q_grupare=0 then p.loc_de_munca else '' end)) as nr,p.marca from pontaj p left join realcom r 
									on p.marca=r.marca and p.data=r.data and p.loc_de_munca=r.loc_de_munca
						and 'PS'+rtrim(p.numar_curent)=r.numar_document
					where p.data between @q_datajos and @q_datasus group by p.marca) nn on e.marca=nn.marca
	left join (select marca,sum(case when c.tip_concediu<>2 then isnull(c.zile_co,0) else 0 end) as zile_co
							,sum(case when c.tip_concediu=2 then isnull(c.zile_co,0) else 0 end) as zile_ev
							,sum(case when c.tip_concediu<>2 then isnull(c.indemnizatie_co,0) else 0 end) as ind_co
							,sum(case when c.tip_concediu=2 then isnull(c.indemnizatie_co,0) else 0 end) as ind_ev
					from concodih c where data between @q_datajos and @q_datasus group by c.marca) c on 
c.marca=e.marca																						
-- c
	left join (select marca,sum(isnull(m.zile_cu_reducere,0))  as zile_cu_reducere,sum(m.zile_lucratoare) as zile_lucratoare,
					sum(case when tip_diagnostic='2-' or tip_diagnostic='3-' then m.zile_lucratoare else 0 end) as zi_ba,
					sum(isnull(m.indemnizatie_unitate,0)) as indemnizatie_unitate, sum(isnull(m.indemnizatie_cas,0)) as 
indemnizatie_cas,
					sum(case when tip_diagnostic='2-' or tip_diagnostic='3-' then 
isnull(m.indemnizatie_unitate,0)+isnull(m.indemnizatie_cas,0)
								else 0 end) as suma_ba
					from conmed m where data between @q_datajos and @q_datasus group by m.marca) m on 
m.marca=e.marca	-- m
	left join (select n.marca,max(n.pensie_suplimentara_3) as ret_CAS,max(n.ded_baza) as ded,
					max(case when day(n.data)=1 then 0 else n.Asig_sanatate_din_net end) as CASS,
					max(n.impozit) as impozit,sum(n.avans)+SUM(ISNULL(a.premiu_la_avans,0)) as avans,sum(n.co_incasat) as co_incasat,
					sum(n.REST_DE_PLATA) as rest_de_plata,max(n.somaj_1) as somaj_1
					from net n left join avexcep a on a.marca=n.marca and a.data=n.data -- between @q_datajos and @q_datasus
					where n.data between @q_datajos and @q_datasus group by n.marca) as n on 
n.marca=e.marca	-- n
	left join (select	sum(case when tip_corectie_venit in ('IA' ,'IB') then suma_corectie else 0 end) as pr_vac,
		sum(case when tip_corectie_venit in ('IC' ,'S1') then suma_corectie else 0 end) as cor_prem,
		sum(case when tip_corectie_venit='ID' then suma_corectie else 0 end) as pr_pens,
		sum(case when tip_corectie_venit='K1' then suma_corectie else 0 end) as profit,
		sum(case when charindex(tip_corectie_venit,'A1|A2|B1|D1|D2|H1|IE|IF|IG|IH|II|IJ|IK|IL|IM|IN|IO|IP|IQ|IR|J1|K2|L1')<>0 
			then suma_corectie else 0 end) as corectii,
		sum(case when tip_corectie_venit='P1' then suma_corectie else 0 end) as impozit,
		sum(case when tip_corectie_venit in ('M1','M2','M4') then suma_corectie else 0 end) as avans,
		sum(case when tip_corectie_venit='M3' then suma_corectie else 0 end) as avans_co,
		sum(case when tip_corectie_venit='S2' then suma_corectie else 0 end) as premii,
		sum(case when tip_corectie_venit='S2' then suma_corectie else 0 end) as alte_ret,
		sum(case when charindex(tip_corectie_venit,'G1|G2|G3|G4')<>0 then suma_corectie else 0 end) as diminuari
	,marca from corectii where data between @q_datajos and @q_datasus group by marca) as cr on cr.marca=e.marca
	left join functii f on e.cod_functie=f.cod_functie 
	left join lm on lm.cod=e.loc_de_munca	--isnull(p.loc_de_munca,e.loc_de_munca)	
	left join speciflm sl on sl.loc_de_munca=e.loc_de_munca --isnull(p.loc_de_munca,e.loc_de_munca)
	--left join (select parinte as marca,avg(indice) as indice,round(sum(isnull(sal_cuv,0)),0) as sal_cuv,sum(ind_cond_suma) as ind_cond_suma from #stat group by parinte) s on s.marca=e.marca
	where (e.marca=@q_marci or @q_marci is null) and (e.cod_functie=@q_functii or @q_functii is null)
	and (--isnull(p.loc_de_munca,e.loc_de_munca) 
			e.loc_de_munca like rtrim(@q_locm)+'%' or @q_locm is null) 
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=e.loc_de_munca))
	--and (e.loc_ramas_vacant=0 or e.data_plec>@q_datajos)
	--and (sl.marca= @q_centru or @q_centru is null)
--/*
-- luare date pe marci din brut:
select top 0 1 as nivel,marca,Loc_de_munca, Total_ore_lucrate, Ore_lucrate__regie, Realizat__regie, Ore_lucrate_acord, Realizat_acord, Ore_suplimentare_1, Indemnizatie_ore_supl_1, Ore_suplimentare_2, Indemnizatie_ore_supl_2, Ore_suplimentare_3, Indemnizatie_ore_supl_3, Ore_suplimentare_4, Indemnizatie_ore_supl_4, Ore_spor_100, Indemnizatie_ore_spor_100, Ore_de_noapte, Ind_ore_de_noapte, Ore_lucrate_regim_normal, Ind_regim_normal, Ore_intrerupere_tehnologica, Ind_intrerupere_tehnologica, Ore_obligatii_cetatenesti, Ind_obligatii_cetatenesti, Ore_concediu_fara_salar, Ind_concediu_fara_salar, Ore_concediu_de_odihna, Ind_concediu_de_odihna, Ore_concediu_medical, Ind_c_medical_unitate, Ind_c_medical_CAS, Ore_invoiri, Ind_invoiri, Ore_nemotivate, Ind_nemotivate, Salar_categoria_lucrarii, CMCAS, CMunitate, CO, Restituiri, Diminuari, Suma_impozabila, Premiu, Diurna, Cons_admin, Sp_salar_realizat, Suma_imp_separat, Spor_vechime, Spor_de_noapte, Spor_sistematic_peste_program, Spor_de_functie_suplimentara, Spor_specific, Spor_cond_1, Spor_cond_2, Spor_cond_3, Spor_cond_4, Spor_cond_5, Spor_cond_6, Compensatie, VENIT_TOTAL, Salar_orar, Venit_cond_normale, Venit_cond_deosebite, Venit_cond_speciale, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10 into #brut from brut
union all
select 1 as nivel,max(b.marca),
isnull(e.loc_de_munca,b.loc_de_munca)--(case when @q_grupare=0 then b.loc_de_munca else isnull(e.loc_de_munca,b.loc_de_munca) end)
as Loc_de_munca, sum(round(b.Total_ore_lucrate,0)), sum(round(b.Ore_lucrate__regie,0)), sum(round(b.Realizat__regie,0)), sum(round(b.Ore_lucrate_acord,0)), sum(round(b.Realizat_acord,0)), sum(round(b.Ore_suplimentare_1,0)), sum(round(b.Indemnizatie_ore_supl_1,0)), sum(round(b.Ore_suplimentare_2,0)), sum(round(b.Indemnizatie_ore_supl_2,0)), sum(round(b.Ore_suplimentare_3,0)), sum(round(b.Indemnizatie_ore_supl_3,0)), sum(round(b.Ore_suplimentare_4,0)), sum(round(b.Indemnizatie_ore_supl_4,0)), sum(round(b.Ore_spor_100,0)), sum(round(b.Indemnizatie_ore_spor_100,0)),sum(round(b.Ore_de_noapte,0)), sum(round(b.Ind_ore_de_noapte,0)), sum(round(b.Ore_lucrate_regim_normal,0)), sum(round(b.Ind_regim_normal,0)), sum(round(b.Ore_intrerupere_tehnologica,0)), sum(round(b.Ind_intrerupere_tehnologica,0)), sum(round(b.Ore_obligatii_cetatenesti,0)), sum(round(b.Ind_obligatii_cetatenesti,0)), sum(round(b.Ore_concediu_fara_salar,0)), sum(round(b.Ind_concediu_fara_salar,0)), sum(round(b.Ore_concediu_de_odihna,0)), sum(round(b.Ind_concediu_de_odihna,0)), sum(round(b.Ore_concediu_medical,0)), sum(round(b.Ind_c_medical_unitate,0)), sum(round(b.Ind_c_medical_CAS,0)), sum(round(b.Ore_invoiri,0)), sum(round(b.Ind_invoiri,0)), sum(round(b.Ore_nemotivate,0)), sum(round(b.Ind_nemotivate,0)), sum(round(b.Salar_categoria_lucrarii,0)), sum(round(b.CMCAS,0)), sum(round(b.CMunitate,0)), sum(round(b.CO,0)), sum(round(b.Restituiri,0)), sum(round(b.Diminuari,0)), sum(round(b.Suma_impozabila,0)), sum(round(b.Premiu,0)), sum(round(b.Diurna,0)), sum(round(b.Cons_admin,0)), sum(round(b.Sp_salar_realizat,0)), sum(round(b.Suma_imp_separat,0)), sum(round(b.Spor_vechime,0)), sum(round(b.Spor_de_noapte,0)), sum(round(b.Spor_sistematic_peste_program,0)), sum(round(b.Spor_de_functie_suplimentara,0)), sum(round(b.Spor_specific,0)), sum(round(b.Spor_cond_1,0)), sum(round(b.Spor_cond_2,0)), sum(round(b.Spor_cond_3,0)), sum(round(b.Spor_cond_4,0)), sum(round(b.Spor_cond_5,0)), sum(round(b.Spor_cond_6,0)), sum(round(b.Compensatie,0)), sum(round(b.VENIT_TOTAL,0)), max(b.Salar_orar), sum(round(b.Venit_cond_normale,0)), sum(round(b.Venit_cond_deosebite,0)), sum(round(b.Venit_cond_speciale,0)), sum(round(b.Spor_cond_7,0)), sum(round(b.Spor_cond_8,0)), sum(round(b.Spor_cond_9,0)), sum(round(b.Spor_cond_10,0))
from brut b right join istpers e on b.marca=e.marca
where b.data between @datajos and @datasus and e.data=@datasus 
--and not exists (select 1 from lm where lm.cod=b.loc_de_munca and lm.cod_parinte='')
group by isnull(e.loc_de_munca,b.loc_de_munca) --(case when @q_grupare=0 then b.loc_de_munca else isnull(e.loc_de_munca,b.loc_de_munca) end)
		 , b.marca
/*
update #stat set sal_cuv=cantitate*tarif_unitar from realcom r where r.Marca=rtrim(reverse(substring(reverse(#stat.cod),1,charindex(' ',reverse(#stat.cod)))))
		and RTRIM(#stat.cod)=RTRIM(r.Marca) and
		r.Data between @q_datajos and @q_datasus and #stat.sal_cuv=0
*/
--select rtrim(reverse(substring(reverse(#stat.cod),1,charindex(' ',reverse(#stat.cod))))),* from #stat

select s.* into #altstat from #stat s left join #brut b on s.loc_de_munca_b=b.loc_de_munca and ltrim(reverse(substring(reverse(rtrim(s.marca)),1,charindex(' ',ltrim(reverse(s.marca))))))=b.marca where s.nivel=1
delete from #stat where nivel=1

insert into #stat 
select isnull(s.nume,''), isnull(s.nume_lm,''), isnull(s.nume_functie,''), isnull(s.nivel,''), isnull(s.cod_numeric_personal,''), isnull(s.regim_de_lucru,''), isnull(s.marca,''), isnull(s.parinte,''), isnull(s.cod,''), isnull(s.loc_de_munca,''), isnull(s.niv,''), isnull(s.functia,''),isnull(s.proc_spor_vechime,''), isnull(b.spor_vechime,''), isnull(s.salar_de_baza,''), isnull(s.sal_tarif,''), isnull(s.salar_orar,''), isnull((b.ore_lucrate__regie+b.ore_lucrate_acord)/s.regim_de_lucru,'') as zi_lu,isnull(b.ore_concediu_de_odihna/s.regim_de_lucru,''),isnull(s.zi_ev,''), isnull(b.ore_concediu_medical/s.regim_de_lucru-s.zi_bs,''), isnull(s.zi_bs,''), isnull(s.zi_ba,''), isnull(b.Ore_concediu_fara_salar/s.regim_de_lucru,''), isnull(b.ore_nemotivate/s.regim_de_lucru,''), isnull(b.ind_regim_normal,''), isnull((b.ore_lucrate__regie+b.ore_lucrate_acord),''), isnull(s.indice,''), 
			round(b.Ind_regim_normal-b.ind_nemotivate,0)--,0)
			*s.indice
			,isnull(s.ind_cond,''), isnull(b.ind_nemotivate,''), isnull(b.realizat__regie+b.realizat_acord,''), isnull(b.ore_concediu_de_odihna,''), isnull(b.ind_concediu_de_odihna-s.ind_ev,''), isnull(s.ind_ev,''), isnull(b.ore_concediu_medical-s.ore_bs,''), isnull(b.ind_c_medical_unitate,''), isnull(s.ore_bs,''), isnull(b.Ind_c_medical_CAS,''), isnull(s.ore_ba,''), isnull(b.spor_cond_9,''), isnull(b.ore_nemotivate,''), isnull(b.Ore_concediu_fara_salar,''), isnull(b.Ore_suplimentare_1,''), isnull(b.Indemnizatie_ore_supl_1,''), isnull(b.Ore_suplimentare_2,''), isnull(b.Indemnizatie_ore_supl_2,''), isnull(b.ore_spor_100,''), isnull(b.indemnizatie_ore_spor_100,''), isnull(b.Ore_de_noapte,''), isnull(b.Ind_ore_de_noapte,''), isnull(s.proc_sist_prg,''), isnull(s.proc_inloc,''), isnull(s.proc_inf,''), isnull(s.proc_mast,''), isnull(s.proc_op_calc,''), isnull(s.proc_mobil,''), isnull(s.sist_prg_ore,''), isnull(b.Spor_sistematic_peste_program,''), isnull(s.inloc_ore,''), isnull(b.Spor_cond_1,''), isnull(s.inf_ore,''), isnull(s.inf_suma,''), isnull(s.master_ore,''), isnull(b.Spor_cond_3,''), isnull(s.op_calc_ore,''), isnull(b.Spor_cond_4,''), isnull(s.mobil_ore,''), isnull(b.spor_cond_5,''), isnull(s.sp_vech_ore,''), isnull(b.spor_vechime,''), isnull(b.venit_total,''), isnull(s.ret_CAS,''), isnull(s.ret_somaj,''), isnull(s.CASS,''), isnull(s.deduceri,''), isnull(s.premii,''), isnull(s.diminuari,''), isnull(s.sind,''), isnull(s.corectii,''), isnull(s.impozit,''), isnull(s.avans,''), isnull(s.avans_co,''), isnull(s.car,''), isnull(s.apdp,''), isnull(s.cuvenit_net,''), isnull(s.pr_vac,''), isnull(s.pr_pens,''), isnull(s.profit,''), isnull(s.prop,''), isnull(s.garantii,''), isnull(s.echipamente,''), isnull(s.alte_ret,''), isnull(s.cor_prem,0),s.loc_de_munca_b
from #altstat s left join #brut b on b.loc_de_munca=s.loc_de_munca and ltrim(reverse(substring(reverse(rtrim(s.marca)),1,charindex(' ',ltrim(reverse(s.marca))))))=b.marca
	--where b.marca is not null
	--and b.data between @q_datajos and @q_datasus

--select b.total_ore_lucrate*b.salar_orar,b.total_ore_lucrate,b.salar_orar,* from #brut b where marca=@marci
drop table #altstat
drop table #brut
--*/
--/*
while @i>-1
begin
	insert into #stat (nume,nume_lm, nume_functie,nivel,cod_numeric_personal, regim_de_lucru, marca,parinte, cod, loc_de_munca, niv, 
	functia, proc_spor_vechime, suma_spor_vechime, salar_de_baza, sal_tarif, salar_orar, zi_lu, zi_co, zi_ev, zi_bo, zi_bs, 
	zi_ba, zi_cfs, zi_ne, salar_ore_lu, ore_lucrate,indice, sal_cuv, ind_cond, ind_cond_suma, total_salar, ore_neco, ind_co, ind_ev, ore_bo,suma_bo, 
	ore_bs, suma_bs, ore_ba, suma_ba, ore_ne, ore_cfs, suplCM_ore, suplCM_suma, suplM_ore, suplM_suma, sp100_ore, sp100_suma, 
	noapte_ore, noapte_suma, proc_sist_prg,proc_inloc,proc_inf,proc_mast,proc_op_calc,proc_mobil,
	sist_prg_ore, sist_prg_suma, inloc_ore, inloc_suma, inf_ore, inf_suma, master_ore, master_suma, op_calc_ore, 
	op_calc_suma, mobil_ore, mobil_suma, sp_vech_ore, sp_vech_suma, venit_brut, ret_CAS, ret_somaj, CASS, deduceri, premii, diminuari, sind, 
	corectii, impozit, avans, avans_co, car, apdp, cuvenit_net, pr_vac, pr_pens, profit, prop, garantii, echipamente, alte_ret,cor_prem,loc_de_munca_b
		)
	select '' as nume,max(lm.denumire) as nume_lm, '' as nume_functie,2 as nivel,max(cod_numeric_personal) as cod_numeric_personal,
		max(regim_de_lucru) as regim_de_lucru,'' as marca,
		max(isnull(lm.cod_parinte,'')) as parinte, max(isnull(lm.cod,'')) as cod, max(s.loc_de_munca) as loc_de_munca, 
		max(lm.nivel) as niv, max(isnull(functia,'')) as functia, max(isnull(proc_spor_vechime,0)) as proc_spor_vechime,
		max(isnull(suma_spor_vechime,0)) as suma_spor_vechime, max(salar_de_baza) as salar_de_baza, 
		max(isnull(sal_tarif,0)) as sal_tarif, max(s.salar_orar) as salar_orar, 
		sum(zi_lu) as zi_lu, sum(s.zi_co) as zi_co, sum(zi_ev) as zi_ev,sum(zi_bo) as zi_bo, sum(zi_bs) as zi_bs, 
		sum(zi_ba) as zi_ba, sum(zi_cfs) as zi_cfs, sum(zi_ne) as zi_ne, 
		sum(salar_ore_lu) as salar_ore_lu, sum(ore_lucrate) as ore_lucrate,
		avg(isnull(indice,1)) as indice, sum(isnull(round(sal_cuv,0),0)) as sal_cuv, max(isnull(ind_cond,0)) as ind_cond	--max(?) => ident =>sum(?)
		, sum(ind_cond_suma) as ind_cond_suma, sum(total_salar) as total_salar, sum(ore_neco) as ore_neco, 
		sum(ind_co) as ind_co,sum(ind_ev) as ind_ev, sum(ore_bo) as ore_bo, sum(suma_bo) as suma_bo, sum(ore_bs) as ore_bs, 
		sum(suma_bs) as suma_bs, 
		sum(ore_ba) as ore_ba, sum(suma_ba) as suma_ba, sum(ore_ne) as ore_ne, sum(ore_cfs) as ore_cfs, 
		sum(suplCM_ore) as suplCM_ore, sum(suplcm_suma) as suplCM_suma,
		sum(suplM_ore) as suplM_ore, sum(suplm_suma) as suplM_suma, 
		sum(sp100_ore) as sp100_ore, sum(sp100_suma) as sp100_suma, 
		sum(noapte_ore) as noapte_ore, sum(round(noapte_suma,0)) as noapte_suma,
		max(proc_sist_prg),max(proc_inloc),max(proc_inf),max(proc_mast),max(proc_op_calc),max(proc_mobil),
		sum(sist_prg_ore) as sist_prg_ore, sum(sist_prg_suma) as sist_prg_suma, sum(inloc_ore) as inloc_ore, sum(inloc_suma) as 
inloc_suma, 
		sum(inf_ore) as inf_ore, sum(inf_suma) as inf_suma, sum(master_ore) as master_ore, sum(round(master_suma,0)) as master_suma, 
sum(op_calc_ore) as op_calc_ore, 
		sum(round(op_calc_suma,0)) as op_calc_suma, sum(mobil_ore) as mobil_ore, sum(mobil_suma) as mobil_suma, sum(sp_vech_ore) as sp_vech_ore, 
sum(sp_vech_suma) as sp_vech_suma, 
		sum(venit_brut) as venit_brut, sum(ret_CAS) as ret_CAS, sum(ret_somaj) as ret_somaj, sum(cass) as CASS, sum(deduceri) as deduceri, 
	sum(premii) as premii, sum(s.diminuari) as diminuari, sum(sind) as sind, sum(corectii) as corectii, 
	sum(impozit) as impozit, sum(avans) as avans, sum(avans_co) as avans_co, sum(car) as car, sum(apdp) as apdp, sum(cuvenit_net) as 
cuvenit_net, 
	sum(pr_vac) as pr_vac, max(pr_pens) as pr_pens, sum(profit) as profit, sum(prop) as prop, sum(garantii) as garantii, sum(echipamente) as 
echipamente, 
	sum(alte_ret) as alte_ret,sum(cor_prem) as cor_prem,max(loc_de_munca_b)
	from #stat s
	left join lm on lm.cod=s.parinte 
	where @i=lm.nivel and lm.cod is not null and s.nivel>0
	group by isnull(lm.cod_parinte,''), s.parinte
	
	set @i=@i-1
end

--update #stat set nivel=nivel+1 where parinte=''

select
	nume, nume_lm, nume_functie, nivel as nivel,cod_numeric_personal as cnp,marca, parinte, cod, loc_de_munca,
	niv, functia, proc_spor_vechime, suma_spor_vechime, salar_de_baza, sal_tarif, salar_orar, zi_lu, zi_co,zi_ev, zi_bo, zi_bs, zi_ba, zi_cfs, 
	zi_ne, salar_ore_lu, ore_lucrate,indice, sal_cuv, ind_cond, ind_cond_suma, total_salar, ore_neco, ore_bo, suma_bo, ore_bs, suma_bs, 
	ore_ba, suma_ba, ore_ne, ore_cfs, suplCM_ore, suplCM_suma, suplM_ore, suplM_suma, sp100_ore, sp100_suma, noapte_ore, noapte_suma, 
	proc_sist_prg,proc_inloc,proc_inf,proc_mast,proc_op_calc,proc_mobil,
	sist_prg_ore, sist_prg_suma, inloc_ore, inloc_suma, inf_ore, inf_suma, master_ore, master_suma, op_calc_ore, op_calc_suma, mobil_ore, 
	mobil_suma, sp_vech_ore, sp_vech_suma, venit_brut, ret_CAS, ret_somaj, CASS, deduceri, premii, diminuari, sind, corectii, impozit, avans, 
	avans_co, car, apdp, cuvenit_net, pr_vac, pr_pens, profit, prop, garantii, echipamente, alte_ret,cor_prem,
	regim_de_lucru as RN,ind_co, ind_ev , p.val_numerica as nr_zile_lucr_luna
from #stat s, par_lunari p
	where p.data between @q_datajos and @q_datasus and p.parametru='ore_luna' and p.tip='PS' 
	order by nivel,functia asc

drop table #personal
drop table #stat--*/
