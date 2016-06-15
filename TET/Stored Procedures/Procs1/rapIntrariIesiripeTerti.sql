--***

create procedure rapIntrariIesiripeTerti (@sesiune varchar(50)='',
		@pDinf datetime, @pDsup datetime,
		@tip_doc_str varchar(1000)=null, @cLM varchar(100)=null,
		@nr_doc varchar(1000)=null, @comanda varchar(1000)=null, @factura varchar(1000)=null,
		@tert varchar(100)=null, @ord varchar(100)=0, @cod varchar(1000)=null, @gestiune varchar(1000)=null)
as
set transaction isolation level read uncommitted
declare @eroare varchar(max)
select @eroare=''
begin try
	if object_id('tempdb..#tmp') is not null drop table #tmp
	declare @nLm int
	set @nLm=isnull((select max(lungime) from strlm where costuri=1), 9) 

	select @tip_doc_str=','+isnull(@tip_doc_str,'AC,AP,AS,RM,RS,AI,AE')+','
	/*declare @cLM char(9), @pDinf datetime,@pDsup datetime
	set @pDinf='1/1/2006'	set @pDsup='1/1/2008'	set @cLM=''*/

	select t.denumire,p.tert,p.tip,p.numar,p.data,(case when p.tip in ('RM','RS','RP') then p.cont_factura else p.cont_corespondent end) as cont_corespondent ,p.cod_intrare,p.pret_de_stoc,
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
		charindex(p.tip, @tip_doc_str)>0 and p.tip not in ('AI','AE')
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

	union all

	select t.denumire,p.Cont_venituri tert,p.tip,p.numar,p.data,(case when p.tip in ('RM','RS','RP') then p.cont_factura else p.cont_corespondent end) as cont_corespondent ,p.cod_intrare,p.pret_de_stoc,
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
		left outer join nomencl n on n.cod=p.cod
		left join textpozdoc tp on p.subunitate=tp.subunitate and p.tip=tp.tip and p.numar=tp.numar and p.data=tp.data and p.numar_pozitie=tp.numar_pozitie
	where   
	--c.tip_comanda='R' and 
		charindex(p.tip, @tip_doc_str)>0 and p.tip in ('AI','AE')
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



	select denumire, tert, tip, numar, data, cont_corespondent, cod_intrare, pret_de_stoc, cantitate, valoare, cod, n_denumire, comanda, explicatii, Factura
	 from #tmp
	order by ord1,ord2
end try
begin catch
	select @eroare=error_message()+' (' + OBJECT_NAME(@@PROCID) + ')'
end catch

if object_id('tempdb..#tmp') is not null drop table #tmp
if len(@eroare)>0
select @eroare as denumire, '<EROARE>' as tert
