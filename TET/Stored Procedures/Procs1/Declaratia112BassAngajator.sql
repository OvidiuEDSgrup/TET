--***
Create procedure Declaratia112BassAngajator 
	(@dataJos datetime, @dataSus datetime, @Marca char(6)=null, @Lm char(9), @Strict int)
as
Begin
	declare @STOUG28 int, @OreLuna int, @SalarMinim decimal(7)
	set @STOUG28=dbo.iauParLL(@dataSus,'PS','STOUG28')
	set @OreLuna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
	set @SalarMinim=dbo.iauParLN(@dataSus,'PS','S-MIN-BR')

	if object_id('tempdb..#BassAngajator') is not null drop table #BassAngajator

	create table #BassAngajator 
	(Data datetime, VenitCN decimal(10), BassCN decimal(10), ScutireCN decimal(10), 
		VenitCD decimal(10), BassCD decimal(10), ScutireCD decimal(10), VenitCS decimal(10), BassCS decimal(10), ScutireCS decimal(10), 
		TotalVenit decimal(10), TotalBass decimal(10), TotalScutire decimal(10), CASAngajator decimal(10), BazaST decimal(10), 
		DeRecuperatBass decimal(10), DeRecuperatFambp decimal(10))

	insert into #BassAngajator
	select n.Data, sum(v.TVN), sum(isnull(n1.Baza_CAS_cond_norm,0)), sum(isnull(s.Scutire_angajator_CN,0)), 
		sum(v.TVD), sum(isnull(n1.Baza_CAS_cond_deoseb,0)), sum(isnull(s.Scutire_angajator_CD,0)), 
		sum(v.TVS), sum(isnull(n1.Baza_CAS_cond_spec,0)), sum(isnull(s.Scutire_angajator_CS,0)), 
		sum(v.TVN+v.TVD+v.TVS), 
		sum(isnull(n1.Baza_CAS_cond_norm,0)+isnull(n1.Baza_CAS_cond_deoseb,0)+isnull(n1.Baza_CAS_cond_spec,0)), 
		sum(isnull(s.Scutire_angajator_CN,0)+isnull(s.Scutire_angajator_CD,0)+isnull(s.Scutire_angajator_CS,0)) as Scutire, 
		sum(n.CAS+n1.CAS), (case when @STOUG28=1 then sum(isnull(round(@SalarMinim*(p.OreST/p.regim_de_lucru)/(@OreLuna/8),0),0)) else 0 end) as BazaST, 
		(case when sum(bm.Compensatie)>sum(n.CAS+n1.CAS) then sum(bm.Compensatie)-sum(n.CAS+n1.CAS) else 0 end), 
		(case when sum(bm.Spor_cond_9+n1.Ded_suplim+n.Asig_sanatate_din_impozit)>sum(n.Fond_de_risc_1) then 
		sum(bm.Spor_cond_9+n1.Ded_suplim+n.Asig_sanatate_din_impozit)-sum(n.Fond_de_risc_1) else 0 end)
	from #net n
		left outer join #net n1 on n1.data=dbo.bom(n.data) and n1.marca=n.marca
		left outer join istPers i on i.Data=n.Data and i.Marca=n.Marca
		left outer join #brutMarca bm on bm.data=n.data and bm.marca=n.marca
		left outer join #D112Asigurati v on v.Data=n.Data and v.Marca=n.Marca and v.Tip_personal='S'
		left outer join (select marca, sum(Ore) as OreST, max(Regim_de_lucru) as Regim_de_lucru from pontaj 
			where data between @dataJos and @dataSus group by marca) p on @STOUG28=1 and n.Marca=p.Marca
		left outer join dbo.fDeclaratia112Scutiri (@dataJos, @dataSus, 1, @lm) s on s.data=n.data and s.marca=n.marca
	where n.data=@dataSus and (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')
	group by n.data

	if isnull((select count(1) from #BassAngajator),0)=0
		insert into #BassAngajator values (@dataSus, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

	select Data, VenitCN, BassCN, ScutireCN, VenitCD, BassCD, ScutireCD, VenitCS, BassCS, ScutireCS, 
		TotalVenit, TotalBass, TotalScutire, CASAngajator, BazaST, DeRecuperatBass, DeRecuperatFambp
	from #BassAngajator
	
	return
End

/*
	exec Declaratia112BassAngajator '11/01/2012', '11/30/2012', null, '', 0
	select * from fPSScutiriOUG13 ('01/01/2011', '01/31/2011', 0, '', '', 0)
*/
