--***
/**	functie fcheltsal	*/
create 
function fcheltsal(@cMarca char(6),@cLocMunca varchar(9),@nSex int,@nNotecont int,@nOrdonare int,@dDataJos datetime,@dDataSus datetime) 
returns @cheltsal table
(data datetime,
marca char(6),
loc_de_munca char(9),
nume char(50),
denumire_lm char(50),
venit_total_brut float,
somaj_1_pers float,
locm_istpers char(9),
denumire_functie char (30),
salar_de_incadrare float,
grupa_de_munca char(1),
mod_angajare char(1),
venit_total float,
pensie_suplimentara_3 float,
somaj_1 float,
impozit float,
asig_sanatate_din_impozit float,
asig_sanatate_din_net float,
asig_sanatate_din_CAS float,
CAS float,
somaj_5 float,
fond_de_risc_1 float,
Camera_de_Munca_1 float,
asig_sanatate_pl_unitate float,
CCI float,
cm_cas float,
cm_FAMBP float,
cm_unitate float,
VENIT_NET float,
nr_tichete float,
valoare_tichete float,
ordonare char(100),
fond_garantare float)
as
begin
	declare @noptichm int, @TichetePersonalizate int, @nvaltichet float, @Remarul int
	set @noptichm = dbo.iauParL('PS','OPTICHINM')
	set @TichetePersonalizate=dbo.iauParL('PS','TICHPERS')
	set @nValTichet = dbo.iauParLN(@dDataSus,'PS','VALTICHET')
	set @Remarul=dbo.iauParL('SP','REMARUL')

	declare @utilizator varchar(20)
	SET @utilizator = dbo.fIaUtilizator('')

	insert @cheltsal
	select a.data as data, a.marca as marca, 
	(case when @nNotecont=1 and @nordonare<>2 then c.loc_de_munca when @nNotecont=0 and @nOrdonare<>2 then a.loc_de_munca else e.marca end) as loc_de_munca, b.nume, 
	(case when @nNotecont=1 and @nordonare<>2 then (select r.denumire from lm r where c.loc_de_munca=r.cod) when @nNotecont=0 and @nOrdonare<>2 then (select q.denumire from lm q where a.loc_de_munca=q.cod) else e.comanda end) as denumire_lm, 
	(case when @nNotecont=1 or @nOrdonare=2 then c.venit_total else 0 end) as venit_total_brut, 
	b.somaj_1 as somaj_1_pers, p.loc_de_munca as locm_istpers, f.denumire as denumire_functie, 
	p.salar_de_incadrare, p.grupa_de_munca, p.mod_angajare, a.venit_total, a.pensie_suplimentara_3, 
	a.somaj_1, a.impozit, a.asig_sanatate_din_impozit, a.asig_sanatate_din_net, 
	(case when year(a.data)<2006 then a.asig_sanatate_din_CAS else 0 end) as asig_sanatate_din_CAS, 
	a.CAS, a.somaj_5, a.fond_de_risc_1, a.Camera_de_Munca_1, a.asig_sanatate_pl_unitate, 
	(case when year(a.data)>=2006 then a.ded_suplim else 0 end) as CCI, 
	v.Ind_c_medical_CAS+v.CMCAS as cm_cas,v.spor_cond_9 as cm_FAMBP, v.Ind_c_medical_unitate+v.CMunitate as cm_unitate,
	a.VENIT_NET, 
	(case when @noptichm=0 then (select sum(ore__cond_6) from pontaj o where o.data between dbo.bom(a.Data) and a.Data and o.marca=a.marca) 
	else (select sum(nr_tichete) from tichete t where t.data_lunii=a.data and t.marca=a.marca 
	and (@TichetePersonalizate=1 and (t.Tip_operatie in ('C','S','R') or @Remarul=0 and t.Tip_operatie='P')
	or @TichetePersonalizate=0 and (t.Tip_operatie in ('P','S','C') or tip_operatie='R' and valoare_tichet<>0))) end) as nr_tichete, 
	(case when @noptichm=0 then (select sum(ore__cond_6)*dbo.iauParLN(a.data,'PS','VALTICHET') from pontaj o where o.data between dbo.bom(a.Data) and a.Data and o.marca=a.marca) 
	else (select sum(t.nr_tichete*t.valoare_tichet) from tichete t where t.data_lunii=a.data and t.marca=a.marca 
	and (@TichetePersonalizate=1 and (t.Tip_operatie in ('C','S','R') or @Remarul=0 and t.Tip_operatie='P')
	or @TichetePersonalizate=0 and (t.Tip_operatie in ('P','S','C') or tip_operatie='R' and valoare_tichet<>0))) end) as valoare_tichete,  
	(case when @nordonare=2 then e.marca else '' end)+(case when @nNotecont=1 or @nordonare=2 then c.loc_de_munca else a.loc_de_munca end) +(case when @nordonare=1 then b.nume else a.marca end) as ordonare,
	isnull(n.somaj_5,0) as fond_garantare
	from net a 
		left outer join personal b on a.marca=b.marca
		left outer join brut c on a.data=c.data and a.marca=c.marca 
		left outer join infopers d on a.marca=d.marca
		left outer join speciflm e on c.loc_de_munca=e.loc_de_munca
		left outer join functii f on b.cod_functie=f.cod_functie
		left outer join net n on dbo.bom(a.data) = n.data and a.marca=n.marca 
		left outer join istpers p on a.data=p.data and a.marca=p.marca 
		left outer join brut v on a.data=v.data and a.marca=v.marca and a.loc_de_munca=v.loc_de_munca 
	where a.data between @dDataJos and @dDataSus and a.data=dbo.eom(a.data) 
		and (@clocMunca is null or ( case when @nNotecont=1 then c.loc_de_munca else a.loc_de_munca end) like @cLocMunca)
		and (@nSex is null or b.sex=@nSex)
		and (@cMarca is null or a.marca=@cMarca )
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=( case when @nNotecont=1 then c.loc_de_munca else a.loc_de_munca end)))
	order by ordonare, a.data

	return
end
