--	Intrari iesiri 2008
--declare @cod nvarchar(4000),@gestiune nvarchar(4000),@codintrare nvarchar(4000),@ctstoc nvarchar(4000),@datajos datetime,@datasus datetime,
--		@tip_doc varchar(2),@Nivel1 varchar(2) ,@Nivel2 varchar(2) ,@Nivel3 varchar(2) ,@Nivel4 varchar(2), @Nivel5 varchar(2), @alfabetic int
--		,@tip_doc_str varchar(1000),@gestprim nvarchar(4000)
--select @cod=NULL,@gestiune=NULL,@codintrare=NULL,@ctstoc=NULL,@datajos='2012-01-01 00:00:00',@datasus='2012-01-31 00:00:00',
--		@tip_doc='AS'--,@Nivel1='CM', @Nivel2='CO', @Nivel3='LU', @Nivel4='LO', @Nivel5='GE'
--		, @alfabetic=1,
--		@tip_doc_str='TE',@gestprim=null

select isnull(month(p.data),0) as luna, 
isnull(p.data,'1/1/1901') as data, 
isnull(rtrim(c.lunaalfa),'') as denluna, 
isnull(p.tip,'') as tip ,
isnull(p.tert,'') as tert,
isnull(p.cod,'') as cod, 
isnull(rtrim(n.denumire),'') as denumire, 
isnull(rtrim(g.denumire),'') as grupa, 
isnull(lm.cod ,'') as loc,
isnull(rtrim(lm.denumire),'') as locm, 
--isnull(rtrim(t.denumire),'') as client, 
isnull(rtrim(ge.denumire_gestiune),'') as DenGes,
isnull(p.gestiune,'') as gestiune, 
isnull(p.numar,'') as numar,
isnull(p.cantitate,0) as cantitate, 
isnull(p.comanda,'') as comanda,
isnull(cm.descriere,'') as descrCM,
isnull(p.cod_intrare,'') as codintrare,
isnull(p.cont_de_stoc,'') as cont_stoc,
isnull((case when p.tip in('RS','RM','RP') then p.cont_factura else p.cont_corespondent end),'') as cont_factura,
isnull(p.cantitate*p.pret_de_stoc,0) as valCost
into #date_brute
from 
--#filtrate 
pozdoc
p
left outer join nomencl n on p.cod=n.cod
left outer join grupe g on n.grupa=g.grupa
left outer join terti t on p.tert=t.tert
left outer join gestiuni ge on p.gestiune=ge.cod_gestiune
left outer join lm on p.loc_De_munca=lm.cod
left outer join comenzi cm on p.comanda=cm.comanda
left join calstd c on p.data= c.data

where --charindex(p.tip,','+@tip_doc_str+',')>0 and
p.tip in (@tip_doc) and 
--p.tip in ('AC','AE','AF','AI','AP','AS','CI','CM','DF','PF','PP','RM','RS','TE') and 
--p.tip =@tip_doc and
(isnull(@codintrare,'')='' or p.cod=rtrim(ltrim(@codintrare))) 
and (isnull(@ctstoc,'')='' or p.cont_de_stoc=rtrim(ltrim(@ctstoc))) 
and (isnull(@gestiune,'')='' or p.gestiune=rtrim(ltrim(@gestiune)))
and (isnull(@gestprim,'')='' or p.Gestiune_primitoare=rtrim(ltrim(@gestprim)))
and (isnull(@cod,'')='' or p.cod=rtrim(ltrim(@cod)))
and p.data between @datajos and @datasus

select	-- construiesc recursiv gruparile pentru a nu mai avea probleme pe Rep 2008
	rtrim(case @Nivel1 when 'CM' then comanda when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(2),luna) when 'LO' then loc end) as niv1,
	rtrim(case @Nivel2 when 'CM' then comanda when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(2),luna) when 'LO' then loc end) as niv2,
	rtrim(case @Nivel3 when 'CM' then comanda when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(2),luna) when 'LO' then loc end) as niv3,
	rtrim(case @Nivel4 when 'CM' then comanda when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(2),luna) when 'LO' then loc end) as niv4,
	rtrim(case @Nivel5 when 'CM' then comanda when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(2),luna) when 'LO' then loc end) as niv5,
	tip+' '+rtrim(numar)+' '+convert(varchar(10),data,103) as niv6,	
	cantitate, valCost, cont_stoc, cont_factura, codintrare,
	rtrim(case @Nivel1 when 'CM' then descrcm when 'CO' then denumire when 'GE' then denges when 'LU' then denluna when 'LO' then locm end) as nume1,
	rtrim(case @Nivel2 when 'CM' then descrcm when 'CO' then denumire when 'GE' then denges when 'LU' then denluna when 'LO' then locm end) as nume2,
	rtrim(case @Nivel3 when 'CM' then descrcm when 'CO' then denumire when 'GE' then denges when 'LU' then denluna when 'LO' then locm end) as nume3,
	rtrim(case @Nivel4 when 'CM' then descrcm when 'CO' then denumire when 'GE' then denges when 'LU' then denluna when 'LO' then locm end) as nume4,
	rtrim(case @Nivel5 when 'CM' then descrcm when 'CO' then denumire when 'GE' then denges when 'LU' then denluna when 'LO' then locm end) as nume5
	into #1
from #date_brute

select niv1 as cod,'' as parinte,0 as cantitate, 0 as valCost, '' as cont_stoc, '' as cont_factura, '' as codintrare,1 as nivel, 
		max(nume1) as nume into #f 
			from #1 where niv1 is not null group by niv1 union all
select niv2, niv1+'|' as parinte,0, 0 , '' , '' , '' , 2, max(nume2) from #1 where niv2 is not null group by niv2,niv1 union all
select niv3, niv2+'|'+niv1+'|' as parinte,0, 0 , '' , '' , '' ,3,max(nume3) from #1 where niv3 is not null group by niv3,niv2,niv1 union all
select niv4, niv3+'|'+niv2+'|'+niv1+'|' as parinte,0, 0 , '' , '' , '' , 4,MAX(nume4) from #1 where niv4 is not null group by niv4,niv3,niv2,niv1 union all
select niv5, niv4+'|'+niv3+'|'+niv2+'|'+niv1+'|' as parinte,0, 0 , '' , '' , '' , 5,MAX(nume5) from #1 where niv5 is not null group by niv5,niv4,niv3,niv2,niv1 union all
select niv6, isnull(niv5+'|','')+isnull(niv4+'|','')+isnull(niv3+'|','')+isnull(niv2+'|','')+niv1+'|' as parinte, 
			cantitate, valCost, cont_stoc, cont_factura, codintrare,6,niv6 from #1

select cod, parinte, cantitate, valCost, cont_stoc, cont_factura, codintrare, nivel, isnull(nume,'')+(case when nivel<6 then isnull(' ('+cod+')' ,'') else '' end) as nume
		--into tmpluci 
		from #f 
	order by (case when @alfabetic=0 then cod else nume end)

--select * from #date_brute
drop table #f
drop table #1
drop table #date_brute