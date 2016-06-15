--***
create function formularFluturasi ()
returns @fluturas table(
	marca varchar(10),
	nume varchar(200), nume_lm varchar(200), locm varchar(20), nume_functie varchar(200), functie varchar(20), salar_de_incadrare decimal(20,2),
	indice_ac varchar(20), indice_r varchar(20), ore_acord decimal(20,4), ore_regie decimal(20,4),
	ore_supl1 int,  val_ore_supl1 decimal(20,2), ore_supl2 int, Val_ore_supl2 decimal(20,2),
	ore_supl3 int,  val_ore_supl3 decimal(20,2), ore_supl4 int, Val_ore_supl4 decimal(20,2),
	conc_med int, val_conc_med decimal(20,2), conc_odihna int, val_conc_odihna decimal(20,2),
	noapte int, val_noapte decimal(20,2), invoiri int,
	proc_urgente varchar(20), val_urgente decimal(20,2), proc_cond_grele varchar(20), val_cond_grele decimal(20,2),
	proc_vechime varchar(20), val_vechime decimal(20,2), cfs int, lucrat int,
	av_natura decimal(20,2), Diurna decimal(20,2), Sal_calc decimal(20,2), Premii decimal(20,2), Sume_neimp decimal(20,2),
	Venit_brut decimal(20,2), CAS decimal(20,2), Somaj decimal(20,2), CASS decimal(20,2), V_neimpoz decimal(20,2),
	Venit_net decimal(20,2), Ded_pers  decimal(20,2), Sindicat decimal(20,2), Ded_facult decimal(20,2), Tich_mc decimal(20,2),
	Venit_bc decimal(20,2), Impozit decimal(20,2), Salar_net decimal(20,2), Avans decimal(20,2), Alte_av decimal(20,2),
	--Alte_sume decimal(20,2), 
	Imputatii decimal(20,2), Popriri decimal(20,2), Garantii decimal(20,2), Chirii decimal(20,2),
	Rate decimal(20,2), Ret_p_fac decimal(20,2), CEC decimal(20,2), CAR decimal(20,2), Pens_al decimal(20,2), Penaliz decimal(20,2),
	Sal_comp decimal(20,2), S_tehnic decimal(20,2), Virat decimal(20,2), Rest_pl decimal(20,2), regim_de_lucru decimal(20,2),
	val_tichete decimal(20,3), asume decimal(20,2),
	Ore_spor_100 decimal(20), Indemnizatie_ore_spor_100 decimal(20,2)
	)
as
begin
/*		PS/Fluturasi.rdl
declare @datasus datetime, @locm char(20),@tip_stat char(10), --@marci_str varchar(20),
	@marci varchar(30),@functii varchar(30),@str_nivel varchar(40)
select @datasus='2011-1-1', @marci='215'
--*/
	declare @q_datajos datetime,@q_datasus datetime, @q_locm varchar(20),
		@q_marci varchar(300),@q_functii varchar(300),@q_grupare int, @q_centru varchar(1)
	declare @q_utilizator varchar(50)
	select @q_utilizator=--dbo.fIaUtilizator(null)
						replace(dbo.fIaUtilizator(null),'.','')
	
	select @q_datajos=a.Data_facturii, @q_datasus=a.Data, @q_locm=isnull(a.Loc_munca,''), @q_marci=isnull(a.Numar,''), 
		@q_functii=isnull(a.Cod_gestiune,'')
		from avnefac a where 
		(isnumeric(a.terminal)=1 and a.terminal=host_id() or isnumeric(a.terminal)=0 and a.terminal=@q_utilizator) 
		and a.tip in ('FS','SL')
	set @q_datajos=dateadd(d,1-day(@q_datasus),@q_datasus)
	
insert into @fluturas(marca, nume, nume_lm, locm, nume_functie, functie, salar_de_incadrare, indice_ac, indice_r, 
	ore_acord, ore_regie, ore_supl1, val_ore_supl1, ore_supl2, Val_ore_supl2, ore_supl3, val_ore_supl3, ore_supl4, Val_ore_supl4, 
	conc_med, val_conc_med, conc_odihna, val_conc_odihna, noapte, val_noapte, invoiri, proc_urgente, val_urgente, 
	proc_cond_grele, val_cond_grele, proc_vechime, val_vechime, cfs, lucrat, av_natura, Diurna, Sal_calc, Premii, Sume_neimp, 
	Venit_brut, CAS, Somaj, CASS, V_neimpoz, Venit_net, Ded_pers, Sindicat, Ded_facult, Tich_mc, Venit_bc, Impozit, Salar_net, 
	Avans, Alte_av, --Alte_sume, 
	Imputatii, Popriri, Garantii, Chirii, Rate, Ret_p_fac, CEC, CAR, Pens_al, Penaliz, --tot_ret, 
	Sal_comp, S_tehnic, Virat, Rest_pl, regim_de_lucru, val_tichete, asume--, Total_incl_tich
	,Ore_spor_100, Indemnizatie_ore_spor_100
	)
select
	rtrim(isnull(e.marca,'')) marca, 
	rtrim(isnull(e.nume,'')) nume,
	rtrim(isnull(lm.denumire,'')) nume_lm,
	rtrim(isnull(e.loc_de_munca,'')) locm,
	rtrim(isnull(f.denumire,'')) nume_functie,
	rtrim(isnull(e.cod_functie,'')) functie,
	isnull(e.salar_de_incadrare,0) salar_de_incadrare,
	'100.00%' as indice_ac, '100.00%' as indice_r,
	isnull(b.Ore_lucrate_acord,0) ore_acord,
	isnull(b.Ore_lucrate__regie,0) ore_regie,
	isnull(b.ore_suplimentare_1,0) ore_supl_1,
	isnull(b.Indemnizatie_ore_supl_1,0) val_ore_supl_1,
	isnull(b.ore_suplimentare_2,0) ore_supl_2,
	isnull(b.Indemnizatie_ore_supl_2,0) val_ore_supl_2,
	isnull(b.ore_suplimentare_3,0) ore_supl_3,
	isnull(b.Indemnizatie_ore_supl_3,0) val_ore_supl_3,
	isnull(b.ore_suplimentare_4,0) ore_supl_4,
	isnull(b.Indemnizatie_ore_supl_4,0) val_ore_supl_4,
	isnull(b.cmunitate,0) conc_med,
	isnull(b.Ind_c_medical_unitate,0)+isnull(b.Ind_c_medical_CAS,0) val_conc_med,
	isnull(b.Ore_concediu_de_odihna,0)+isnull(co.Zile_CO_neefectuate*p.regim_de_lucru,0) conc_odihna,
	isnull(b.ind_concediu_de_odihna,0) val_conc_odihna,
	isnull(b.ore_de_noapte,0) noapte,
	isnull(b.Ind_ore_de_noapte,0) val_noapte,
	isnull(r.invoiri,0) invoiri,
	'0' as proc_urgente, 0 as val_urgente, 
	isnull(p.Spor_specific,0) proc_cond_grele, 
	isnull(b.Spor_specific,0) val_cond_grele,
	isnull(e.spor_vechime,0) proc_vechime,
	isnull(b.Spor_vechime,0) val_vechime,
	isnull(b.ore_concediu_fara_salar,0) cfs_luc,
	0 as cfs_cal,
	isnull(r.av_natura,0) av_natura,
	isnull(b.diurna,0) Diurna,
	--isnull(b.diurna,0) isnull(b.suma_impozabila,0) 
	isnull(b.sal_calc,0) as Sal_calc,
	isnull(b.Premiu,0) Premii,
	isnull(n.Suma_neimpozabila,0) Sume_neimp, 
	isnull(b.venit_total,0) Venit_brut,
	isnull(n.ret_CAS,0) CAS,
	isnull(n.somaj_1,0) Somaj,
	isnull(n.CASS,0) CASS,
	(case when e.grad_invalid>0 then isnull(n.VEN_NET_IN_IMP,0) else 0 end)+ isnull(n.Suma_neimpozabila,0) V_neimpoz,
	(case when e.grad_invalid>0 then 0 else isnull(n.VEN_NET_IN_IMP,0) end) Venit_net,
	isnull(n.Ded_baza,0) Ded_pers,
	isnull(r.Sindicat,0) Sindicat, 
	isnull(r.ded_facult,0) Ded_facult, 
	isnull(t.nr_tichete,0) Tich_mc, 
	0 as Venit_bc, 
	isnull(n.impozit,0) Impozit,
	isnull(n.VENIT_NET,0) Salar_net, 
	isnull(n.Avans,0) Avans,
	isnull(n.suma_incasata,0) Alte_av, 
	--0 as Alte_sume,	--isnull(b.suma_impozabila,0)
	isnull(r.Imputatii,0) Imputatii, 
	isnull(r.Popriri,0) Popriri, 
	isnull(r.Garantii,0) Garantii, 
	isnull(r.Chirii,0) Chirii, 
	isnull(r.Rate,0) Rate, isnull(r.Ret_p_fac,0) Ret_p_fac, isnull(r.CEC,0) CEC,
	isnull(r.CAR,0) CAR, 
	isnull(r.Pens_al,0) Pens_al, 
	isnull(r.Penaliz,0) Penaliz, --0 as tot_ret, 
	0 as Sal_comp, 
	isnull(b.Ind_intrerupere_tehnologica,0) S_tehnic, 0 as Virat, 
	isnull(n.rest_de_plata,0) Rest_pl,-- Total_incl_tich
	isnull(p.regim_de_lucru,8) regim_de_lucru,
	isnull(t.valt_tichete,0) val_tichete,
	isnull(b.asume,0),
	isnull(b.Ore_spor_100,0), isnull(b.Indemnizatie_ore_spor_100,0)
from istpers e --inner join #stat s on s.marca=e.marca and isnull(rtrim(s.marca),'')<>'' and e.data=@q_datasus
	-- brut (alias b):
	left join (select marca,
			sum(isnull(b.Indemnizatie_ore_supl_1,0)) Indemnizatie_ore_supl_1,
			sum(isnull(b.Indemnizatie_ore_supl_2,0)) Indemnizatie_ore_supl_2,
			sum(isnull(b.Indemnizatie_ore_supl_3,0)) Indemnizatie_ore_supl_3,
			sum(isnull(b.Indemnizatie_ore_supl_4,0)) Indemnizatie_ore_supl_4,
			sum(isnull(cmunitate,0)) cmunitate,
			sum(isnull(Ind_c_medical_unitate,0)) Ind_c_medical_unitate,
			sum(isnull(Ind_c_medical_CAS,0)) Ind_c_medical_CAS,
			sum(isnull(ind_concediu_de_odihna,0)) ind_concediu_de_odihna,
			sum(isnull(Ind_ore_de_noapte,0)) Ind_ore_de_noapte,
			sum(isnull(Spor_specific,0)) Spor_specific,
			sum(isnull(Spor_vechime,0)) Spor_vechime,
			sum(isnull(Premiu,0)) Premiu,
			sum(isnull(venit_total,0)) venit_total,
			---- Luci Maier: urmatoarele inlocuiesc datele pe care le luam din pontaj:
			sum(isnull(Ore_lucrate_acord,0)) Ore_lucrate_acord,
			sum(isnull(Ore_lucrate__regie,0)) Ore_lucrate__regie,
			sum(isnull(b.ore_suplimentare_1,0)) ore_suplimentare_1,
			sum(isnull(b.ore_suplimentare_2,0)) ore_suplimentare_2,
			sum(isnull(b.ore_suplimentare_3,0)) ore_suplimentare_3,
			sum(isnull(b.ore_suplimentare_4,0)) ore_suplimentare_4,
			sum(isnull(b.Ore_concediu_de_odihna,0)) Ore_concediu_de_odihna,
			sum(isnull(b.ore_de_noapte,0)) ore_de_noapte,
			sum(isnull(b.ore_concediu_fara_salar,0)) ore_concediu_fara_salar,
			sum(isnull(b.diurna,0)) diurna,
			sum(isnull(b.Ind_intrerupere_tehnologica,0)) Ind_intrerupere_tehnologica,
			--sum(isnull(b.suma_impozabila,0)) suma_impozabila,
			sum(isnull(b.suma_impozabila,0)+isnull(b.CMCAS,0)-isnull(b.Diminuari,0)+isnull(b.Sp_salar_realizat,0)+isnull(b.Compensatie,0)) as asume,
			sum(isnull(b.total_ore_lucrate,0)*isnull((case when 
				isnull(b.salar_categoria_lucrarii,0)<>0 then b.salar_categoria_lucrarii else b.salar_orar end),0)) as sal_calc
			,sum(isnull(b.ore_suplimentare_3,0)) Ore_spor_100, sum(isnull(b.indemnizatie_ore_supl_3,0)) Indemnizatie_ore_spor_100
	from brut b where data between @q_datajos and @q_datasus group by b.marca) b on b.marca=e.marca	
	-- concedii de odihna platite si neefectuate (alias co): 
	left join (select co.marca, 
		sum(Zile_CO) as Zile_CO_neefectuate from concodih co where co.data between @q_datajos and @q_datasus and tip_concediu in ('3','6') group by Marca) co on co.marca=e.marca	
	-- net (alias n): 
	left join (select n.marca,
					max(isnull(n.Suma_neimpozabila,0)) Suma_neimpozabila,
					max(isnull(n.pensie_suplimentara_3,0)) ret_CAS,
					max(isnull(n.somaj_1,0)) somaj_1,
					max(isnull(case when day(n.data)=1 then 0 else n.Asig_sanatate_din_net end,0)) CASS,
					max(isnull(n.VEN_NET_IN_IMP,0)) VEN_NET_IN_IMP,
					max(isnull(n.Ded_baza,0)) Ded_baza,
					max(isnull(n.impozit,0)) impozit,
					max(isnull(n.VENIT_NET,0)) VENIT_NET,
					max(isnull(n.Avans,0)) Avans,
					max(isnull(n.rest_de_plata,0)) rest_de_plata,
					sum(isnull(n.suma_incasata,0)) suma_incasata
					from net n where n.data between @q_datajos and @q_datasus and n.data=dateadd(d,-day(dateadd(M,1,n.data)),dateadd(M,1,n.data))
					group by n.marca) as n on n.marca=e.marca	
	left join functii f on e.cod_functie=f.cod_functie left join lm on lm.cod=e.loc_de_munca
	-- pontaj (alias p): 
	left join ( select p.marca,
						/*sum(isnull(p.ore_acord,0)) ore_acord,
						sum(isnull(p.ore_regie,0)) ore_regie,
						sum(isnull(p.ore_suplimentare_1,0)) ore_suplimentare_1,
						sum(isnull(p.ore_suplimentare_2,0)) ore_suplimentare_2,
						sum(isnull(p.Ore_concediu_de_odihna,0)) Ore_concediu_de_odihna,
						sum(isnull(p.ore_de_noapte,0)) ore_de_noapte,*/
						sum(isnull(p.Spor_specific,0)) Spor_specific,
						--sum(isnull(p.ore_concediu_fara_salar,0)) ore_concediu_fara_salar,
						max(isnull(p.regim_de_lucru,0)) regim_de_lucru	/*,
						sum(isnull(p.ore_lucrate,0)*isnull((case when 
							isnull(p.salar_categoria_lucrarii,0)<>0 then p.salar_categoria_lucrarii else p.salar_orar end),0)) as sal_calc*/
				from pontaj p where p.data between @q_datajos and @q_datasus group by p.marca) as p on p.marca=e.marca 
	-- retinerile (alias r): 
	
	--Lucian: Am preluat textul din scriptul trimis de Dorin Rus: "DORIN: AM INTRODUS SI SINDICAT CU COD 9!!!"
	left join	(select marca,
					max(isnull([1],0)+isnull([8],0)+isnull([9],0)) Sindicat, -- codurile de beneficiari vor fi variate aici
					max(isnull([2],0)) Popriri,
					max(isnull([3],0)) Imputatii,
					max(isnull([4],0)) Pens_al,
					max(isnull([5],0)) Garantii,
					max(isnull([7],0)) Penaliz, 
					max(isnull(CAR,0)) CAR,
					max(isnull(INV,0)) invoiri,
					max(isnull(AVN,0)) av_natura,
					max(isnull(DDF,0)) ded_facult,
					max(isnull(CHI,0)) Chirii,
					max(isnull(RT,0))  Rate,
					max(isnull(RPF,0)) Ret_p_fac,
					max(isnull(CEC,0)) CEC					
			from
			(select marca, retinut_la_lichidare, res.cod_beneficiar from resal res where data between @q_datajos and @q_datasus) as c
			pivot
			(sum(retinut_la_lichidare)
				for cod_beneficiar in ([1],[2],[3],[4],[5],[7],[8],[9],CAR, INV, AVN, DDF, CHI, RT, RPF, CEC)
			) as pvt
			group by marca) r on r.marca=e.marca
	-- tichete (alias t): 
	left join (select Marca, SUM(convert(decimal(12,2),
			(case when t.Tip_operatie='C' or t.Tip_operatie='P' or t.Tip_operatie='S' then Nr_tichete*Valoare_tichet else -Nr_tichete*Valoare_tichet end)
			)) as valt_tichete,
			sum((case when t.Tip_operatie='C' or t.Tip_operatie='P' or t.Tip_operatie='S' then Nr_tichete else -Nr_tichete end)
			) as nr_tichete from tichete t where Data_lunii between @q_datajos and @q_datasus
				group by marca) t on t.marca=e.marca
	where (e.marca=@q_marci or @q_marci='') and (e.cod_functie=@q_functii or @q_functii='')
	and (isnull(e.loc_de_munca,lm.cod) like rtrim(@q_locm)+'%' or @q_locm='') --and (e.data_plec>@q_datajos)
	and (dbo.f_areLMFiltru(@q_utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@q_utilizator and l.cod=isnull(e.loc_de_munca,lm.cod)))
	and e.data between @q_datajos and @q_datasus
	return 
end
