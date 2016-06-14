/*           Avize 2008
declare @datajos datetime,@datasus datetime,@tert nvarchar(4000),@cod nvarchar(4000),@gestiune nvarchar(4000),@lm nvarchar(4000),@factura nvarchar(4000),@comanda nvarchar(4000)
		,@Nivel1 varchar(2) ,@Nivel2 varchar(2) ,@Nivel3 varchar(2) ,@Nivel4 varchar(2), @Nivel5 varchar(2), @alfabetic int
select @datajos='2000-01-1 00:00:00',@datasus='2010-06-30 00:00:00',@tert=null,@cod=NULL,@gestiune=NULL,@lm=NULL,@factura=NULL,@comanda=NULL
		,@Nivel1='TE', @Nivel2='CO', @Nivel3='LU', @Nivel4='TE', @Nivel5=null, @alfabetic=1	--*/

--declare @datajos datetime,@datasus datetime,@tert nvarchar(4000),@cod nvarchar(4000),@gestiune nvarchar(4000),@lm nvarchar(4000),@factura nvarchar(4000),@comanda nvarchar(4000),@Nivel1 nvarchar(2),@Nivel2 nvarchar(2),@Nivel3 nvarchar(4000),@Nivel4 nvarchar(4000),@Nivel5 nvarchar(4000),@alfabetic bit, @contfact nvarchar(4000), @tipdoc varchar(4000)
--select @datajos='2009-01-01 00:00:00',@datasus='2012-05-08 00:00:00',@tert=NULL,@cod=NULL,@gestiune=NULL,@lm=NULL,@factura=NULL,@comanda=NULL,@Nivel1=N'GE',@Nivel2=N'CO',@Nivel3=NULL,@Nivel4=NULL,@Nivel5=NULL,@alfabetic=0,@contfact=null,@tipdoc=null
		
		
select p.data,isnull(p.tip,'') as tip ,isnull(p.tert,'') as tert, isnull(p.cod,'') as cod, isnull(p.gestiune,'') as gestiune,
		isnull(p.numar,'') as numar,isnull(p.cantitate,0) as cantitate,
		isnull(p.cantitate*p.pret_vanzare,0) as pfTVA,
		isnull(p.cantitate*p.pret_vanzare+p.tva_deductibil,0) as pcuTVA,
		isnull(p.cantitate*p.pret_de_stoc,0) as valCost, 
		(case when p.adaos=0 then 0 else isnull(p.cantitate*(p.pret_vanzare-p.pret_de_stoc),0)  end)as adaos,
		p.loc_De_munca
	into #filtrate from pozdoc p
	where (p.data between @datajos and @datasus) and (p.gestiune=@gestiune or @gestiune is null) and (p.Loc_de_munca=@lm or @lm is null) 
			and (p.factura = @factura or @factura is null) and (p.comanda = @comanda or @comanda is null)
			and p.tip in ('AP','AC','AS') 
			and (@contfact is null or p.Cont_factura like rtrim(@contfact)+'%') 
			and (@tipdoc is null or p.Tip=@tipdoc)

create nonclustered index cod on #filtrate (cod)
create nonclustered index tert on #filtrate (tert)
create nonclustered index gestiune on #filtrate (gestiune)
create nonclustered index loc_De_munca on #filtrate (loc_De_munca)

select isnull(month(p.data),0) as luna, isnull(p.data,'1/1/1901') as data, 
(select rtrim(MAX(c.LunaAlfa)) from CalStd c where c.Luna=month(p.data))+' '+convert(varchar(4),YEAR(p.data)) as denluna, p.tip, p.tert,
p.cod, isnull(rtrim(n.denumire),'') as denumire, isnull(rtrim(g.denumire),'') as grupa, 
isnull(lm.cod ,'') as loc,
isnull(rtrim(lm.denumire),'') as locm, isnull(rtrim(t.denumire),'') as client, 
isnull(rtrim(ge.denumire_gestiune),'') as DenGes,
p.gestiune, p.numar,p.cantitate, p.pfTVA, p.pcuTVA, p.valCost, p.adaos,
greutate_specifica as greutate
/*,isnull(p.factura,'') as factura, isnull(p.comanda,'') as comanda*/
into #date_brute
from #filtrate p
left outer join nomencl n on p.cod=n.cod
left outer join grupe g on n.grupa=g.grupa
left outer join terti t on p.tert=t.tert
left outer join gestiuni ge on p.gestiune=ge.cod_gestiune
left outer join lm on p.loc_De_munca=lm.cod
where (p.tert=@tert or t.denumire like '%'+replace(isnull(@tert,' '),' ','%')+'%') 
and (p.cod=@cod or n.denumire like '%'+replace(isnull(@cod,' '),' ','%')+'%')
--order by luna--,tert,denumire

select	-- construiesc recursiv gruparile pentru a nu mai avea probleme pe Rep 2008
	(case @Nivel1 when 'TE' then tert when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(2),luna) when 'LO' then loc end) as niv1,
	(case @Nivel2 when 'TE' then tert when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(2),luna) when 'LO' then loc end) as niv2,
	(case @Nivel3 when 'TE' then tert when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(2),luna) when 'LO' then loc end) as niv3,
	(case @Nivel4 when 'TE' then tert when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(2),luna) when 'LO' then loc end) as niv4,
	(case @Nivel5 when 'TE' then tert when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(2),luna) when 'LO' then loc end) as niv5,
	tip+' '+rtrim(numar)+' '+convert(varchar(10),data,103) as niv6,	
	cantitate, greutate, pfTVA, pcuTVA, valCost, adaos,
	(case @Nivel1 when 'TE' then client when 'CO' then denumire when 'GE' then denges when 'LU' then denluna when 'LO' then locm end) as nume1,
	(case @Nivel2 when 'TE' then client when 'CO' then denumire when 'GE' then denges when 'LU' then denluna when 'LO' then locm end) as nume2,
	(case @Nivel3 when 'TE' then client when 'CO' then denumire when 'GE' then denges when 'LU' then denluna when 'LO' then locm end) as nume3,
	(case @Nivel4 when 'TE' then client when 'CO' then denumire when 'GE' then denges when 'LU' then denluna when 'LO' then locm end) as nume4,
	(case @Nivel5 when 'TE' then client when 'CO' then denumire when 'GE' then denges when 'LU' then denluna when 'LO' then locm end) as nume5
	into #1
from #date_brute

select niv1 as cod,'' as parinte,0 as cantitate, 0 as greutate, 0 as pfTVA, 0 as pcuTVA, 0 as valCost, 0 as adaos,1 as nivel, 
		max(nume1) as nume into #f 
			from #1 where niv1 is not null group by niv1 union all
select niv2, niv1+'|' as parinte,0, 0 , 0 , 0 , 0 , 0 ,2, max(nume2) from #1 where niv2 is not null group by niv2,niv1 union all
select niv3, niv2+'|'+niv1+'|' as parinte,0, 0 , 0 , 0 , 0 , 0 ,3,max(nume3) from #1 where niv3 is not null group by niv3,niv2,niv1 union all
select niv4, niv3+'|'+niv2+'|'+niv1+'|' as parinte,0, 0 , 0 , 0 , 0 , 0 ,4,MAX(nume4) from #1 where niv4 is not null group by niv4,niv3,niv2,niv1 union all
select niv5, niv4+'|'+niv3+'|'+niv2+'|'+niv1+'|' as parinte,0, 0 , 0 , 0 , 0 , 0 ,5,MAX(nume5) from #1 where niv5 is not null group by niv5,niv4,niv3,niv2,niv1 union all
select niv6, isnull(niv5+'|','')+isnull(niv4+'|','')+isnull(niv3+'|','')+isnull(niv2+'|','')+niv1+'|' as parinte, 
			cantitate, greutate, pfTVA, pcuTVA, valCost, adaos,6,niv6 from #1
--order by (case when @alfabetic=1 then cod else nume end)

create nonclustered index cod on #f (cod)
create nonclustered index nume on #f (nume)
create nonclustered index nivel on #f (nivel)
create nonclustered index parinte on #f (parinte)

select cod, parinte, cantitate, greutate, pfTVA, pcuTVA, valCost, adaos, nivel, nume from #f 
	order by (case when @alfabetic=0 then cod else nume end)

drop table #filtrate
drop table #f
drop table #1
drop table #date_brute