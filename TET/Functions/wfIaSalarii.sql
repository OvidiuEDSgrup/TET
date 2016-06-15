--***
Create
function wfIaSalarii (@sesiune varchar(50), @parXML xml)
returns @wfIaSalarii table (data varchar(10), tip varchar(20), subtip varchar(20), densubtip varchar(50), 
	grupdoc varchar(20), denumire varchar(50), nrsal int, nrsalregie int, nrsalacord int, cantitate decimal(10,2), valoare decimal(12,2), 
	indunitate decimal(12,2), indcas decimal(12,2), orelucrate int, oresupl int, orenoapte int)
As
Begin
declare @userASiS varchar(20), @lista_lm int, @tip varchar(20), @subtip varchar(20), @data datetime, @datajos datetime, @datasus datetime, @dencorectie varchar(50), @denbeneficiar varchar(50), @grupdoc varchar(20), @subtipcor int
set @subtipcor=dbo.iauParL('PS','SUBTIPCOR')
Set @userASiS=dbo.fIaUtilizator(@sesiune)
select @lista_lm=dbo.f_arelmfiltru(@userASiS)

select @data=xA.row.value('@data', 'datetime'), @tip=xA.row.value('@tip', 'varchar(20)'), @subtip=xA.row.value('@subtip', 'varchar(20)'), 
	@datajos=isnull(xA.row.value('@datajos','datetime'),'01/01/1901'), @datasus=dbo.eom(isnull(xA.row.value('@datasus','datetime'),'12/31/2999')), 
	@dencorectie=xA.row.value('@dencorectie','varchar(50)'), @denbeneficiar=xA.row.value('@denbeneficiar','varchar(50)'), @grupdoc=xA.row.value('@grupdoc','varchar(20)') 
from @parXML.nodes('row') as xA(row)

insert into @wfIaSalarii
select isnull(convert(char(10),d.data,101),convert(char(10),@datasus,101)) as data, w.tip as tip, isnull(d.subtip,'') as subtip, 
	(case when w.tip='ME' and 1=0 then isnull(d.densubtip,'') else w.Nume end) as densubtip, 
	rtrim(isnull(d.grupdoc,'')) as grupdoc, rtrim(isnull(d.denumire,w.Nume)) as denumire, isnull(d.nrsal,0) as nrsal, isnull(d.nrsalregie,0) as nrsalregie, isnull(d.nrsalacord,0) as nrsalacord, isnull(d.cantitate,0) as cantitate, isnull(d.valoare,0) as valoare, isnull(d.indunitate,0), isnull(d.indcas,0), isnull(d.orelucrate,0), isnull(d.oresupl,0), isnull(d.orenoapte,0)
from webConfigTipuri w
	left outer join (
	select @tip as tip, '' as subtip, 'Avans' as densubtip, convert(char(10),i.data,101) as data, isnull(i.loc_de_munca,'') as grupdoc, rtrim(max(isnull(lm.denumire,''))) as denumire,
		count(a.marca) as nrsal, 0 as nrsalregie, 0 as nrsalacord, sum(isnull(a.Ore_lucrate_la_avans,0)) as cantitate, sum(convert(decimal(12,2),isnull(a.Suma_avans,0))) as valoare, 0 as indunitate,
		0 as indcas, 0 as orelucrate, 0 as oresupl, 0 as orenoapte 
	from istpers as i
		left outer join (select data, marca, Ore_lucrate_la_avans, Suma_avans from avexcep where data between @datajos and @datasus) a on a.data=i.data and a.marca=i.marca
		left outer join lm on i.loc_de_munca=lm.cod
	where @tip='AV' and (@grupdoc is null or i.Loc_de_munca=@grupdoc)
		and i.data between @datajos and @datasus and (@data is null or a.data=@data)
	group by i.data,isnull(i.loc_de_munca,'') 
   union all
	select @tip as tip, 'M2' as subtip, 'Concedii medicale' as densubtip, convert(char(10),cm.data,101) as data, '' as grupdoc, 
		'Concedii medicale' as denumire,
		count(distinct cm.marca) as nrsal, 0 as nrsalregie, 0 as nrsalacord, sum(cm.Zile_lucratoare) as cantitate, sum(convert(decimal(12,2),cm.Indemnizatie_unitate+Indemnizatie_CAS)) as valoare,
		sum(convert(decimal(12,2),cm.Indemnizatie_unitate)), sum(convert(decimal(12,2),Indemnizatie_CAS)), 0 orelucrate, 0 oresupl, 0 orenoapte
	from conmed as cm
	where @tip='ME' and cm.data between @datajos and @datasus and (@data is null or cm.data=@data) 
	group by cm.data
   union all
	select @tip as tip, '' as subtip, 'Concedii de odihna' as densubtip, convert(char(10),co.data,101) as data, '' as grupdoc, 
		'Concedii de odihna' as denumire, count(distinct co.marca) as nrsal, 0 as nrsalregie, 0 as nrsalacord, sum(co.Zile_CO) as cantitate,
		sum(convert(decimal(12,2),Indemnizatie_CO)) as valoare, 0 indunitate, 0 indcas, 0 orelucrate, 0 oresupl, 0 orenoapte 
	from concodih as co
	where @tip='OD'
		and co.data between @datajos and @datasus and (@data is null or co.data=@data) and co.tip_concediu not in ('9','C','P','V')
	group by co.data
   union all
	select @tip as tip, '' as subtip, '' as densubtip, convert(char(10),dbo.eom(p.data),101) as data, isnull(i.loc_de_munca,'') as grupdoc, 
		rtrim(max(isnull(lm.denumire,''))) as denumire, count(distinct p.marca) as nrsal,
		isnull((select count(distinct i1.marca) from istpers i1 where i1.data=dbo.eom(p.data) and i1.loc_de_munca=i.loc_de_munca and i1.tip_salarizare in ('1','3','6')),0) as nrsalregie,
		isnull((select count(distinct i2.marca) from istpers i2 where i2.data=dbo.eom(p.data) and i2.loc_de_munca=i.loc_de_munca and i2.tip_salarizare in ('2','4','5','7')),0) as nrsalacord,
		Null as cantitate, Null as valoare, 0 indunitate, 0 indcas, sum(p.Ore_regie+p.Ore_acord) as orelucrate,
		sum(p.Ore_suplimentare_1+p.Ore_suplimentare_2+Ore_suplimentare_3+Ore_suplimentare_4) as oresupl, sum(Ore_de_noapte) as orenoapte 
	from pontaj as p
		left outer join istpers i on i.data=dbo.eom(p.data) and p.marca=i.marca
		left outer join lm on i.loc_de_munca=lm.cod
	where @tip='PO' and (@grupdoc is null or i.loc_de_munca=@grupdoc)
		and p.data between @datajos and @datasus and (@data is null or p.data=@data)
	group by dbo.eom(p.data), i.loc_de_munca
   union all
	select @tip as tip, (case when @tip='CT' then 'C2' else 'C4' end) as subtip, (case when @tip='CT' then 'Corectii' else 'Corectii nete' end) as densubtip,
		convert(char(10),dbo.eom(c.data),101) as data, c.tip_corectie_venit as grupdoc, 
		(case when @subtipcor=1 then max(isnull(s.denumire,'')) else max(isnull(t.denumire,'')) end) as denumire, 
		isnull(count(distinct c.marca),0) as nrsal, 0 as nrsalregie, 0 as nrsalacord, 
		sum(convert(decimal(12,2),isnull((case when @tip='CN' then c.Suma_neta else 0 end),0))) as Cantitate, 
		sum(convert(decimal(12,2),isnull((case when @tip='CT' then c.Suma_corectie else 0 end),0))) as valoare, 
		0 indunitate, 0 indcas, 0 orelucrate, 0 oresupl, 0 orenoapte
	from corectii c 
		left outer join subtipcor s on c.tip_corectie_venit=s.subtip
		left outer join tipcor t on c.tip_corectie_venit=t.tip_corectie_venit
	where @tip in ('CT','CN') and (@grupdoc is null or c.tip_corectie_venit=@grupdoc) 
		and c.data between @datajos and @datasus and (@data is null or c.data=@data)
		and (@dencorectie is null or (case when @subtipcor=1 then s.denumire else t.denumire end) like '%'+@dencorectie+'%') 
		and (@tip='CT' and c.suma_neta=0 or @tip='CN' and c.suma_neta<>0)
	group by dbo.eom(c.data), c.tip_corectie_venit 
   union all
	select @tip as tip, (case when @tip='CT' then 'C2' else 'C4' end) as subtip, 
		(case when @tip='CT' then 'Corectii' else 'Corectii nete' end) as densubtip, 
		convert(char(10),@datasus,101) as data, t.tip_corectie_venit as grupdoc, 
		max(t.denumire) as denumire, 0 nrsal, 0 nrsalregie, 0 nrsalacord, 0 Cantitate, 0 valoare, 0 indunitate, 0 indcas, 0 orelucrate, 
		0 oresupl, 0 orenoapte
	from tipcor t 
	where @tip in ('CT','CN') and @subtipcor=0 and (@grupdoc is null or t.tip_corectie_venit=@grupdoc) 
		and not exists (
			select 1 from corectii c 
			where c.data between @datajos and @datasus and (@data is null or c.data=@data)
				and (@tip='CT' and c.suma_neta=0 or @tip='CN' and c.suma_neta<>0)
				and t.tip_corectie_venit=c.tip_corectie_venit
		)
		and (@dencorectie is null or t.denumire like '%'+@dencorectie+'%')
	group by t.tip_corectie_venit  
   union all
	select @tip as tip, (case when @tip='CT' then 'C2' else 'C4' end) as subtip, 
		(case when @tip='CT' then 'Corectii' else 'Corectii nete' end) as densubtip, convert(char(10),@datasus,101) as data, s.subtip as grupdoc, 
		max(s.denumire) as denumire, 0 nrsal, 0 nrsalregie, 0 nrsalacord, 0 cantitate, 0 valoare, 0 indunitate, 0 indcas, 0 orelucrate, 
		0 oresupl, 0 orenoapte
	from subtipcor s 
	where @tip in ('CT','CN') and @subtipcor=1 and (@grupdoc is null or s.subtip=@grupdoc) 
		and not exists (
			select 1 from corectii c 
			where c.data between @datajos and @datasus and (@data is null or c.data=@data)
			and (@tip='CT' and c.suma_neta=0 or @tip='CN' and c.suma_neta<>0)
			and s.tip_corectie_venit=c.tip_corectie_venit
		)
		and (@dencorectie is null or s.denumire like '%'+@dencorectie+'%')
	group by s.subtip  
   union all
	select @tip as tip, '' as subtip, '' as densubtip, convert(char(10),isnull(r.data,@datasus),101) as data, r.cod_beneficiar as grupdoc, 
		max(b.denumire_beneficiar) as denumire, isnull(count(distinct r.marca),0) as nrsal, 0 nrsalregie, 0 nrsalacord,
		sum(convert(decimal(12,2),isnull(r.Retinere_progr_la_lichidare,0))) as Cantitate, 
		sum(convert(decimal(12,2),isnull(r.Retinut_la_lichidare,0))) as valoare, 0 indunitate, 0 indcas, 0 orelucrate, 0 oresupl, 0 orenoapte
	from resal r
		left outer join benret b on b.cod_beneficiar=r.cod_beneficiar
	where @tip='RE' and (@grupdoc is null or r.Cod_beneficiar=@grupdoc)  
		and r.data between @datajos and @datasus and (@data is null or isnull(r.data,@datasus)=@data)
		and (@denbeneficiar is null or b.denumire_beneficiar like '%'+@denbeneficiar+'%')
	group by r.data, r.cod_beneficiar 
   union all
	select @tip as tip, '' as subtip, '' as densubtip, convert(char(10),@datasus,101) as data, b.cod_beneficiar as grupdoc, 
		max(b.denumire_beneficiar) as denumire, 0 nrsal, 0 nrsalregie, 0 nrsalacord, 0 Cantitate, 0 valoare, 0 indunitate, 0 indcas, 0 orelucrate, 
		0 oresupl, 0 orenoapte
	from benret b 
	where @tip='RE' and (@grupdoc is null or b.Cod_beneficiar=@grupdoc) 
		and not exists (
			select 1 from resal r where r.data between @datajos and @datasus
			and (@data is null or r.data=@data)
			and b.cod_beneficiar=cod_beneficiar
		) and (@denbeneficiar is null or b.denumire_beneficiar like '%'+'denbeneficiar'+'%')
	group by b.cod_beneficiar) as d on w.tip=d.tip
where Meniu='SL' and w.tip=@tip and isnull(w.Subtip,'')='' and (d.data is null or d.data between @datajos and @datasus)
order by ordine, nrsal desc
return
End
