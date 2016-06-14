--declare @tip_doc nvarchar(2),@cLM nvarchar(4000),@pDinf datetime,@pDsup datetime,@nr_doc nvarchar(4000),@comanda nvarchar(4000),@factura nvarchar(4000),@tert nvarchar(4000),@ord nvarchar(1),@cod nvarchar(4000),@gestiune nvarchar(4000),@garantii bit
--select @tip_doc=N'AE',@cLM=NULL,@pDinf='2012-01-01 00:00:00',@pDsup='2012-04-02 00:00:00',@nr_doc=NULL,@comanda=NULL,@factura=NULL,@tert=NULL,@ord=N'0',@cod=NULL,@gestiune=NULL, @garantii=1

/*	Script Stocuri / Intrari isesiri pe terti
declare @cLM nvarchar(4000),@pDinf datetime,@pDsup datetime,@nr_doc nvarchar(4000),@comanda nvarchar(4000),@factura nvarchar(4000),@tert nvarchar(4000),@ord nvarchar(1),@cod nvarchar(4000),@gestiune nvarchar(4000)
		select @cLM=NULL,@pDinf='2010-11-01 00:00:00',@pDsup='2010-11-29 00:00:00',@nr_doc=NULL,@comanda=NULL,@factura=NULL,@tert=NULL,@ord=N'0',@cod=NULL,@gestiune=NULL
--*/

declare @nLm int
set @nLm=isnull((select max(lungime) from strlm where costuri=1), 9) 

/*declare @cLM char(9), @pDinf datetime,@pDsup datetime
set @pDinf='1/1/2006'	set @pDsup='1/1/2008'	set @cLM=''*/

select t.denumire,p.tert,CASE p.Tip WHEN 'TE' THEN p.Factura ELSE p.Contract END AS [contract],p.tip,p.numar,p.data,(case when p.tip in ('RM','RS','RP') then p.cont_factura else p.cont_corespondent end) as cont_corespondent ,p.cod_intrare,p.pret_de_stoc,
p.cantitate,(case when p.tip in ('AP','AS','AC') then p.pret_vanzare*p.cantitate
		  else p.pret_de_stoc*p.cantitate
	 end) as valoare,p.cod,
isnull(n.denumire,'') as n_denumire,p.comanda,rtrim(tp.explicatii) as explicatii, p.Factura,
(case	
				when @ord=1 then t.denumire
				when @ord=2 then p.tert
				when @ord=3 then p.numar
				when @ord=5 then (case when p.tip in ('RM','RS','RP') then p.cont_factura else p.cont_corespondent end)
				when @ord=6 then p.cod_intrare
				when @ord=10 then p.cod
				when @ord=11 then n.denumire
				when @ord=12 then p.comanda
			else '1' end) ord1
,(case	when @ord=4 then p.data
		when @ord=7 then p.pret_de_stoc
		when @ord=8 then p.cantitate
		when @ord=9 then (case when p.tip in ('AP','AS','AC') then p.pret_vanzare*p.cantitate
									else p.pret_de_stoc*p.cantitate
									end)
		else 1 end) ord2
into #tmp
from pozdoc p
--left outer join comenzi c on p.comanda=c.comanda and p.subunitate=c.subunitate
left outer join terti t on t.tert=p.tert and p.subunitate=t.subunitate 
left outer join nomencl n on n.cod=p.cod
left join textpozdoc tp on p.subunitate=tp.subunitate and p.tip=tp.tip and p.numar=tp.numar and p.data=tp.data and p.numar_pozitie=tp.numar_pozitie
where   
--c.tip_comanda='R' and 
p.tip in (@tip_doc) and p.tip not in ('AI','AE')
--and c.tip_comanda not in ('P','S')   
and 
left(p.loc_de_munca,@nLm) like isnull(rtrim(@cLM),'')+'%' 
and p.data between @pDinf and @pDsup
and p.numar like isnull(@nr_doc,'%') 
and p.comanda like '%'+isnull(@comanda,'')+'%'
and (@factura is null or p.factura=@factura)
and (@tert is null or t.tert=@tert or t.Denumire like '%'+@tert+'%')
and (@cod is null or p.cod=@cod)
and (@gestiune is null or p.gestiune=@gestiune)
and @garantii=0

union all

select coalesce(t.denumire,tae.Denumire,'') as denumire,coalesce(t.tert,tae.Tert,'') as tert,p.Grupa as Contract ,p.tip,p.numar,p.data,(case when p.tip in ('RM','RS','RP') then p.cont_factura else p.cont_corespondent end) as cont_corespondent ,p.cod_intrare,p.pret_de_stoc,
p.cantitate,(case when p.tip in ('AP','AS','AC') then p.pret_vanzare*p.cantitate
		  else p.pret_de_stoc*p.cantitate
	 end) as valoare,p.cod,
isnull(n.denumire,'') as n_denumire,p.comanda,rtrim(tp.explicatii) as explicatii, p.Factura,
(case	
				when @ord=1 then t.denumire
				when @ord=2 then p.tert
				when @ord=3 then p.numar
				when @ord=5 then (case when p.tip in ('RM','RS','RP') then p.cont_factura else p.cont_corespondent end)
				when @ord=6 then p.cod_intrare
				when @ord=10 then p.cod
				when @ord=11 then n.denumire
				when @ord=12 then p.comanda
			else '1' end) ord1
,(case	when @ord=4 then p.data
		when @ord=7 then p.pret_de_stoc
		when @ord=8 then p.cantitate
		when @ord=9 then (case when p.tip in ('AP','AS','AC') then p.pret_vanzare*p.cantitate
									else p.pret_de_stoc*p.cantitate
									end)
		else 1 end) ord2
from pozdoc p
--left outer join comenzi c on p.comanda=c.comanda and p.subunitate=c.subunitate
left outer join terti t on t.tert=p.Cont_venituri and p.subunitate=t.subunitate
left outer join con c on c.Subunitate=p.Subunitate and c.Tip='BK' and p.Tip='AE' and c.Contract=p.Grupa
left outer join terti tae on tae.tert=c.tert and c.subunitate=tae.subunitate
left outer join nomencl n on n.cod=p.cod
left join textpozdoc tp on p.subunitate=tp.subunitate and p.tip=tp.tip and p.numar=tp.numar and p.data=tp.data and p.numar_pozitie=tp.numar_pozitie
where   
--c.tip_comanda='R' and 
p.tip in (@tip_doc) and p.tip in ('AI','AE')
--and c.tip_comanda not in ('P','S')   
and 
left(p.loc_de_munca,@nLm) like isnull(rtrim(@cLM),'')+'%' 
and p.data between @pDinf and @pDsup
and p.numar like isnull(@nr_doc,'%') 
and p.comanda like '%'+isnull(@comanda,'')+'%'
and (@factura is null or p.factura=@factura)
and (@tert is null or t.tert=@tert or t.Denumire like '%'+@tert+'%')
and (@cod is null or p.cod=@cod)
and (@gestiune is null or p.gestiune=@gestiune)
and (@garantii=0 or c.Responsabil_tert='1')



select denumire, tert, [contract], tip, numar, data, cont_corespondent, cod_intrare, pret_de_stoc, cantitate, valoare, cod, n_denumire, comanda, explicatii, Factura
 from #tmp
order by ord1,ord2

drop table #tmp