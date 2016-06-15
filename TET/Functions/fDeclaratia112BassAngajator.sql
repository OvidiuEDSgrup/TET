--***
Create
function [dbo].[fDeclaratia112BassAngajator] 
	(@DataJ datetime, @DataS datetime, @oMarca int, @Marca char(6), @Lm char(9), @Strict int)
returns @BassAngajator table 
	(Data datetime, VenitCN decimal(10), BassCN decimal(10), ScutireCN decimal(10), 
	VenitCD decimal(10), BassCD decimal(10), ScutireCD decimal(10), 
	VenitCS decimal(10), BassCS decimal(10), ScutireCS decimal(10), 
	TotalVenit decimal(10), TotalBass decimal(10), TotalScutire decimal(10), CASAngajator decimal(10), BazaST decimal(10), 
	DeRecuperatBass decimal(10), DeRecuperatFambp decimal(10))
as
Begin
	declare @STOUG28 int, @OreLuna int, @SalarMinim decimal(7)
	set @STOUG28=dbo.iauParLL(@DataS,'PS','STOUG28')
	set @OreLuna=dbo.iauParLN(@DataS,'PS','ORE_LUNA')
	set @SalarMinim=dbo.iauParLN(@DataS,'PS','S-MIN-BR')

	insert into @BassAngajator
	select n.Data, sum(v.TVN), sum(isnull(n1.Baza_CAS_cond_norm,0)), sum(isnull(s.Scutire_angajator_CN,0)), 
		sum(v.TVD), sum(isnull(n1.Baza_CAS_cond_deoseb,0)), sum(isnull(s.Scutire_angajator_CD,0)), 
		sum(v.TVS), sum(isnull(n1.Baza_CAS_cond_spec,0)), sum(isnull(s.Scutire_angajator_CS,0)), 
		sum(v.TVN+v.TVD+v.TVS), 
		sum(isnull(n1.Baza_CAS_cond_norm,0)+isnull(n1.Baza_CAS_cond_deoseb,0)+isnull(n1.Baza_CAS_cond_spec,0)), 
		sum(isnull(s.Scutire_angajator_CN,0)+isnull(s.Scutire_angajator_CD,0)+isnull(s.Scutire_angajator_CS,0)) as Scutire, 
		sum(n.CAS+n1.CAS), (case when @STOUG28=1 then sum(isnull(round(@SalarMinim*(p.OreST/p.regim_de_lucru)/(@OreLuna/8),0),0)) else 0 end) as BazaST, 
		(case when sum(b.AjDeces)>sum(n.CAS+n1.CAS) then sum(b.AjDeces)-sum(n.CAS+n1.CAS) else 0 end), 
		(case when sum(b.CMFambp+n1.Ded_suplim+n.Asig_sanatate_din_impozit)>sum(n.Fond_de_risc_1) then 
		sum(b.CMFambp+n1.Ded_suplim+n.Asig_sanatate_din_impozit)-sum(n.Fond_de_risc_1) else 0 end)
	from net n
		left outer join net n1 on n1.data=dbo.bom(n.data) and n1.marca=n.marca
		left outer join (select data, marca, Sum(Spor_cond_9) as CMFambp, Sum(Compensatie) as AjDeces from brut
		where data=@DataS group by data, marca) b on b.data=n.data and b.marca=n.marca
		left outer join fDeclaratia112 (@DataJ, @DataS, 0, '', '', 0, 0, '', '') v on v.Data=n.Data and v.Marca=n.Marca
		left outer join (select marca, sum(Ore) as OreST, max(Regim_de_lucru) as Regim_de_lucru from pontaj 
		where data between @DataJ and @DataS group by marca) p on @STOUG28=1 and n.Marca=p.Marca
		left outer join dbo.fDeclaratia112Scutiri (@DataJ, @DataS, 1) s on s.data=n.data and s.marca=n.marca
	where n.data=@DataS
	group by n.data

	if isnull((select count(1) from @BassAngajator),0)=0
		insert into @BassAngajator
		values (@DataS, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	return
End

/*
	select * from fDeclaratia112BassAngajator ('01/01/2011', '01/31/2011', 0, '', '', 0)
	select * from fPSScutiriOUG13 ('01/01/2011', '01/31/2011', 0, '', '', 0)
*/
