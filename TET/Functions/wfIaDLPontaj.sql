--***
Create function wfIaDLPontaj (@parXML xml)
returns @wIaDLPontaj table (Data varchar(10), Marca varchar(6), Nume varchar(50), numar_pozitie int, subtip varchar(20), tip varchar(20), denumire varchar(40), nrdoc varchar(10), codac varchar(2), 
	explicatii varchar(30), cantitate decimal(12,2), valoare decimal(12,2), datasfarsit varchar(10), numar_curent int, lm varchar(9), denlm varchar(30), comanda char(20), dencomanda varchar(50), 
	tipsal char(1), oreregie int, oreacord int, oresupl1 int, oresupl2 int, oresupl3 int, oresupl4 int, orespor100 int, orenoapte int, orerealizate decimal(12,2), 
	realizat decimal(12,2), coefacord decimal(12,4), salcatl decimal(12,3), oredetasare int, oredelegatii int, orelucrate int, 
	oreco int, orecm int, oreintr1 int, oreintr2 int, oreobligatii int, oreinvoiri int, orenemotivate int, orecfs int, orenelucrate int, 
	sporspecific decimal(12,2), orepesteprogr int, sppesteprogr decimal(12,2), ore1 int, sp1 decimal(12,2), ore2 int, sp2 decimal(12,2), 
	ore3 int, sp3 decimal(12,2), ore4 int, sp4 decimal(12,2), ore5 int, sp5 decimal(12,2), ore6 int, sp6 decimal(12,2), 
	sp7 decimal(12,2), sp8 decimal(12,2), nrtichete decimal(5,2))
As
Begin
	declare @tip varchar(20), @subtip varchar(20), @data datetime, @datajos datetime, @datasus datetime, 
	@lmantet varchar(20), @Marca varchar(6), @Sub varchar(9), @OSNRN int, @O100NRN int, @ORegieFaraOS2 int, @SubtipSpor int

	select @data=xA.row.value('@data', 'datetime'), @tip=xA.row.value('@tip', 'varchar(20)'), @subtip=xA.row.value('@subtip', 'varchar(20)'), @lmantet=xA.row.value('@lmantet', 'varchar(9)')
	from @parXML.nodes('row') as xA(row)

	set @datajos=dbo.bom(@data)
	set @datasus=dbo.eom(@data)
	set @Sub=dbo.iauParA('GE','SUBPRO')
	set @OSNRN=dbo.iauParL('PS','OSNRN')
	set @O100NRN=dbo.iauParL('PS','O100NRN')
	set @ORegieFaraOS2=dbo.iauParL('PS','OREG-FOS2')
	select @SubtipSpor=(case when isnull((select vizibil from webConfigTipuri where Meniu='SL' and tip='PO' and subtip='S2'),0)=1
						and isnull((select vizibil from webConfigTipuri where Meniu='SL' and tip='SL' and subtip='S1'),0)=1 then 1 else 0 end)

	insert into @wIaDLPontaj
	select 
	convert(char(10),p.Data,101) as data, p.marca as marca, ps.nume as nume, 
	3 as numarpozitie, (case when @tip='SL' then 'P1' else 'P2' end) as subtip, @tip as tip,
	'Pontaj' as denumire, '' as nrdoc, '' as codac, 'Pontaj' as explicatii,
	convert(decimal(12,2),p.ore_regie+p.ore_acord+
	(case when @OSNRN=0 then p.ore_suplimentare_1+p.ore_suplimentare_2+p.ore_suplimentare_3+p.ore_suplimentare_4 else (case when @ORegieFaraOS2=1 then p.Ore_suplimentare_2 else 0 end) end)+
	(case when @O100NRN=0 then p.Ore_spor_100 else 0 end)) as cantitate, 
	dbo.wSLIauValoare(p.data,p.marca,p.loc_de_munca,(case when @tip='SL' then 'P1' else 'P2' end),p.numar_curent) as valoare, 
	convert(char(10),p.Data,101) as datasfarsit, p.Numar_curent as Numar_curent,
	rtrim(p.loc_de_munca) as lm, rtrim(lm.denumire) as denlm, r.comanda as comanda, c.descriere as dencomanda, 
	rtrim(p.Tip_salarizare) as tipsal,
	p.ore_regie as oreregie, p.ore_acord as oreacord, p.Ore_suplimentare_1 as oresupl1, p.Ore_suplimentare_2 as oresupl2, 
	p.Ore_suplimentare_3 as oresupl3, p.Ore_suplimentare_4 as oresupl4, p.Ore_spor_100 as orespor100, p.Ore_de_noapte as orenoapte, 
	p.Ore_realizate_acord as orerealizate, p.Realizat as realizat, p.Coeficient_acord as coefacord, p.Salar_categoria_lucrarii as salcatl, 
	p.Spor_cond_9 as oredetasare, p.Spor_cond_10 as oredelegatii, 
	convert(decimal(12,2),p.ore_regie+p.ore_acord+
	(case when @OSNRN=0 then p.ore_suplimentare_1+p.ore_suplimentare_2+p.ore_suplimentare_3+p.ore_suplimentare_4 else (case when @ORegieFaraOS2=1 then p.Ore_suplimentare_2 else 0 end) end)+
	(case when @O100NRN=0 then p.Ore_spor_100 else 0 end)) as orelucrate, 
	p.Ore_concediu_de_odihna as oreco, p.Ore_concediu_medical as orecm, p.Ore_intrerupere_tehnologica  as oreintr1, p.Ore as oreintr2, 
	p.Ore_obligatii_cetatenesti as oreobligatii, p.Ore_invoiri as oreinvoiri, p.Ore_nemotivate as orenemotivate, p.Ore_concediu_fara_salar as orecfs, 
	convert(decimal(12,2),p.Ore_concediu_de_odihna+p.Ore_concediu_medical+p.Ore_intrerupere_tehnologica+p.Ore+p.Ore_obligatii_cetatenesti+p.Ore_invoiri+p.Ore_nemotivate+ p.Ore_concediu_fara_salar) as orenelucrate, 
	(case when @SubtipSpor=1 and 1=0 then Null else p.spor_specific end) as sporspecific, 
	(case when @SubtipSpor=1 and 1=0 then Null else p.Ore_sistematic_peste_program end) as orepesteprogr, 
	(case when @SubtipSpor=1 and 1=0 then Null else p.Sistematic_peste_program end) as sppesteprogr, 
	(case when @SubtipSpor=1 and 1=0 then Null else p.Ore__cond_1 end) as ore1, (case when @SubtipSpor=1 and 1=0 then Null else p.Spor_conditii_1 end) as sp1, 
	(case when @SubtipSpor=1 and 1=0 then Null else p.Ore__cond_2 end) as ore2, (case when @SubtipSpor=1 and 1=0 then Null else p.Spor_conditii_2 end) as sp2, 
	(case when @SubtipSpor=1 and 1=0 then Null else p.Ore__cond_3 end) as ore3, (case when @SubtipSpor=1 and 1=0 then Null else p.Spor_conditii_3 end) as sp3, 
	(case when @SubtipSpor=1 and 1=0 then Null else p.Ore__cond_4 end) as ore4, (case when @SubtipSpor=1 and 1=0 then Null else p.Spor_conditii_4 end) as sp4, 
	(case when @SubtipSpor=1 and 1=0 then Null else p.Ore__cond_5 end) as ore5, (case when @SubtipSpor=1 and 1=0 then Null else p.Spor_conditii_5 end) as sp5, 
	(case when @SubtipSpor=1 and 1=0 then Null else p.Ore_donare_sange end) as ore6, (case when @SubtipSpor=1 and 1=0 then Null else p.Spor_conditii_6 end) as sp6, 
	(case when @SubtipSpor=1 and 1=0 then Null else p.Spor_cond_7 end) as sp7, (case when @SubtipSpor=1 and 1=0 then Null else p.Spor_cond_8 end) as sp8,
	convert(decimal(5,2),Ore__cond_6) as nrtichete
	from 
	pontaj p
		left outer join realcom r on r.data=p.data and r.marca=p.marca and r.numar_document='PS'+rtrim(convert(char(10),p.numar_curent)) and r.loc_de_munca=p.loc_de_munca
		left outer join lm on p.loc_de_munca=lm.cod
		left outer join comenzi c on c.subunitate=@Sub and r.comanda=c.comanda
		left outer join personal ps on ps.marca=p.marca
		left outer join istpers i on i.data=dbo.eom(p.data) and p.marca=i.marca
		,@parXML.nodes('row') as xA(row)
	where p.data between @datajos and @datasus and (p.Ore_regie+p.Ore_acord+p.Ore_suplimentare_1+p.Ore_suplimentare_2+p.Ore_suplimentare_3+p.Ore_suplimentare_4+p.Ore_spor_100+ p.Ore_de_noapte+p.Realizat<>0 
		or p.Ore_concediu_de_odihna+p.Ore_concediu_medical+p.Ore_intrerupere_tehnologica+p.Ore+p.Ore_obligatii_cetatenesti+p.Ore_invoiri+p.Ore_nemotivate+p.Ore_concediu_fara_salar<>0 or 1=1)
		and (@tip='PO' and (nullif(@lmantet,'') is null or i.loc_de_munca=@lmantet) or @tip='SL' and p.marca=xA.row.value('@marca','varchar(6)'))
	union all
	select 
	convert(char(10),p.Data,101) as data,p.marca as marca, ps.nume as nume, 
	6 as numarpozitie,
	(case when @tip='SL' then 'S1' else 'S2' end) as subtip, @tip as tip, 
	'Sporuri' as denumire, '' as nrdoc, '' as codac, 'Sporuri' as explicatii,
	convert(decimal(12,2),p.ore_sistematic_peste_program+
	+p.ore__cond_1+p.ore__cond_2+p.ore__cond_3+p.ore__cond_4+p.ore__cond_5+p.ore_donare_sange) as cantitate, 
	dbo.wSLIauValoaresp(p.data,p.marca,p.loc_de_munca,(case when @tip='SL' then 'S1' else 'S2' end),p.numar_curent) as valoare,
	convert(char(10),p.Data,101) as datasfarsit, p.Numar_curent as Numar_curent, 
	rtrim(p.loc_de_munca) as lm, rtrim(lm.denumire) as denlm, r.comanda as comanda, c.descriere as dencomanda,
	rtrim(p.Tip_salarizare) as tipsal,
	Null as oreregie, Null as oreacord, Null as oresupl1, Null as oresupl2, Null as oresupl3, Null as oresupl4, Null as orespor100, 
	Null as orenoapte, Null as orerealizate, Null as realizat, Null as coefacord, Null as salcatl, Null as oredetasare, Null as oredelegatii, Null as orelucrate,
	Null as oreco, Null as orecm, Null as oreintr1, Null as oreintr2, Null as oreobligatii, Null as oreinvoiri, Null as orenemotivate, Null as orecfs, Null as orenelucrate, 
	p.spor_specific as sporspecific, p.ore_sistematic_peste_program as orepesteprogr, p.sistematic_peste_program as sppesteprogr, p.ore__cond_1 as ore1,
	p.spor_conditii_1 as sp1, p.ore__cond_2 as ore2, p.spor_conditii_2 as sp2, p.ore__cond_3 as ore3, p.spor_conditii_3 as sp3, p.ore__cond_4 as ore4, p.spor_conditii_4 as sp4, p.ore__cond_5 as ore5, p.spor_conditii_5 as sp5, p.ore_donare_sange as ore6, p.spor_conditii_6 as sp6, p.spor_cond_7 as sp7, p.spor_cond_8 as sp8,
	Null as nrtichete
	from 
	pontaj p
		left outer join realcom r on r.data=p.data and r.marca=p.marca and r.numar_document='PS'+rtrim(convert(char(10),p.numar_curent)) and r.loc_de_munca=p.loc_de_munca
		left outer join lm on p.loc_de_munca=lm.cod
		left outer join comenzi c on c.subunitate=@Sub and r.comanda=c.comanda
		left outer join personal ps on ps.marca=p.marca
		left outer join istpers i on i.data=dbo.eom(p.data) and p.marca=i.marca
		,@parXML.nodes('row') as xA(row)
	where @SubtipSpor=1
		and p.data between @datajos and @datasus and p.spor_specific+p.ore_sistematic_peste_program+
		p.sistematic_peste_program+p.ore__cond_1+p.spor_conditii_1+p.ore__cond_2+
		p.spor_conditii_2+p.ore__cond_3+p.spor_conditii_3+p.ore__cond_4+p.spor_conditii_4+
		p.ore__cond_5+p.spor_conditii_5+p.ore_donare_sange+p.spor_conditii_6+p.spor_cond_7+p.spor_cond_8<>0
		and (@tip='PO' and (nullif(@lmantet,'') is null or i.loc_de_munca=@lmantet) or @tip='SL' and p.marca=xA.row.value('@marca','varchar(6)'))

	return
End
