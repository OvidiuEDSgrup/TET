--***
CREATE procedure [dbo].[postcalcul] @sesiune varchar(50)=null,
	@ddatajos datetime,@ddatasus datetime,@comanda varchar(20),@cLM varchar(20), 
	@RepartizareCost varchar(1), -- daca 'N' <=> se iau costurile aferente valorii neterminate de pe comenzi
	@tipcomanda varchar(20), -- daca '_' se iau toate
	@stare varchar(1), @beneficiar varchar(20), @grupacom varchar(20), 
	@complet varchar(1), -- @complet='1' <=> cost complet, adica include si administratie si desfacere
	@Grupare varchar(1), 
	@sursa varchar(1)='C' -- daca C atunci articole din calcul, daca F atunci din fisa pe conturi, daca 
as
	set transaction isolation level read uncommitted
	declare @ddataluniisus datetime,@ddataluniijos datetime
	select	@ddataluniisus=dateadd(day,-day(@ddatasus)+1,@ddatasus), @ddataluniijos=dateadd(day,-day(@ddatajos)+1,@ddatajos),
			@tipcomanda=(case when charindex(isnull(@tipcomanda,'_'),'_')>0 then 'RPXTCSVALGD#' else @tipcomanda end)

	--declare @sp_rem bit  set @sp_rem=0 -- pe aceste doua linii se stabileste regula de specific Remarul:
	--select @sp_rem=1 from par where tip_parametru='GE' and parametru='NUME' and val_alfanumerica like '%Remar%'
	declare @subunitate char(9)
	set @subunitate = (select val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO') 
	declare @art711 varchar(20)
	set @art711=isnull((select Val_alfanumerica from par where Tip_parametru='PC' and parametru='ARTCALS'),'')

	--> pregatire auto-filtrare pe loc de munca	
		declare @utilizator varchar(20), @eLmUtiliz int
		exec wiautilizator @sesiune=@sesiune, @utilizator=@utilizator output
		select @eLmUtiliz=0
		select @eLmUtiliz=1 from lmfiltrare where utilizator=@utilizator

		declare @LmUtiliz table(valoare varchar(200))
		insert into @LmUtiliz(valoare)
		select cod from lmfiltrare where utilizator=@utilizator
		
	--Pentru procente
	create table #tmpcost (comanda_inf char(20), art_sup char(20), costuri float, procent float)
	insert into #tmpcost 
	select comanda_inf,art_sup,sum(cantitate*valoare) as costuri,1.00/3 as procent from costsql
		where lm_sup='' and comanda_sup='' and art_sup <>'T' and (@comanda is null or comanda_inf=@comanda) and 
			(@cLM is null or lm_inf like rtrim(@cLM)+'%') and data between @ddatajos and @ddatasus
			and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=lm_inf))
		group by comanda_inf,art_sup
	union all
	select comanda_inf,'T',sum(cantitate*valoare) as costuri, 0.000000 from costsql
		where lm_sup='' and comanda_sup='' and art_sup <>'T' and (@comanda is null or comanda_inf=@comanda) and
			(@cLM is null or lm_inf like rtrim(@cLM)+'%') and data between @ddatajos and @ddatasus
			and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=lm_inf))
		group by comanda_inf order by comanda_inf

	delete from #tmpcost where costuri=0

	update #tmpcost set procent=costuri/(select sum(costuri) from #tmpcost t1 where #tmpcost.comanda_inf=t1.comanda_inf and t1.art_sup='T')

	select lm_sup,comanda_sup,comanda_inf,sum(cantitate*valoare) as valoare,art_inf,art_sup,data,1.0 as sursa 
		into #c 
		from costsql 
		where data between @ddatajos and @ddatasus and ((art_inf='N' and data=@ddataluniijos) or art_inf<>'N') and @sursa='C'
		group by lm_sup,comanda_sup,comanda_inf,art_inf,art_sup,data
	union all
	select loc_de_munca as lm_sup,comanda,comanda_sursa,sum(valoare),articol_de_calculatie ,articole_de_calculatie_sursa ,data_lunii ,2 
		from cost c 
		where @complet=1 and data_lunii between @ddatajos and @ddatasus and tip_inregistrare='PE' and 
			exists (select 1 from par where tip_parametru='PC' and parametru in ('CHADMIN','CHDESFAC') and 
						c.articol_de_calculatie=par.val_alfanumerica)
			and @sursa='C'
		group by loc_de_munca ,comanda,comanda_sursa,articol_de_calculatie ,articole_de_calculatie_sursa ,data_lunii
	union all
	select LM as lm_sup, Comanda as comanda_sup,'',SUM(suma) as valoare,(case when f.cont like '711%' then @art711 else Articol_de_calculatie end)
			,'',data,1
		from FisaPeCont f 
		left join conturi c on f.Cont=c.Cont
		where f.Data between @ddatajos and @ddatasus and (@comanda is null or Comanda=@comanda) and (@cLM is null or LM=@cLM) and @sursa='F'
			and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=lm))
		group by LM ,Comanda,Data,(case when f.cont like '711%' then @art711 else Articol_de_calculatie end)
	union all
	select LM as lm_sup, Comanda as comanda_sup,'T',SUM(suma) as valoare,rtrim(f.Cont)
			,'',data,1
		from FisaPeCont f 
		left join conturi c on f.Cont=c.Cont
		where f.Data between @ddatajos and @ddatasus and (@comanda is null or Comanda=@comanda) and (@cLM is null or LM=@cLM) and @sursa='G'
			and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=lm))
		group by LM ,Comanda,Data,f.cont

	select s.lm_sup as lm,s.comanda_sup as comanda,isnull(sum(s.valoare*(case @RepartizareCost when '' then 1 when 'N' then isnull(pr.procent,0) 
		else 1-isnull(pr.procent,0) end)),0) as valoare, isnull(a.articol_de_calculatie,(case when s.art_inf='T' then s.art_sup else s.art_inf end )) 
		as articol, max(coalesce(cc.denumire_cont,a.denumire,'<inexistent>')) as denart, max(isnull(a.ordinea_in_raport,55)) as ordinea_in_raport, s.sursa,s.data, 
		isnull(c.tip_comanda,'#') as tip_comanda, 0 as excludval,(select max(marca) from speciflm where Loc_de_munca=s.lm_sup) as centru 
	into #general
	from #c s 
		left join #tmpcost pr on @RepartizareCost<>'' and s.comanda_sup=pr.comanda_inf and pr.art_sup='N'
		left join artcalc a on (case when s.art_inf='T' then s.art_sup else s.art_inf end )=a.articol_de_calculatie 
		left join comenzi c on s.comanda_sup=c.comanda
		left join conturi cc on @sursa='G' and cc.cont=s.art_inf
	where c.subunitate = @subunitate and isnull(a.ordinea_in_raport,55)>0
	group by s.lm_sup,s.comanda_sup,s.data,isnull(c.tip_comanda,'#'),
	isnull(a.articol_de_calculatie,(case when s.art_inf='T' then s.art_sup else s.art_inf end )), s.sursa

	--if (@si_grupe=1) -- pentru grupe de indicatori; pentru a nu aparea in totaluri sumele grupelor s-a folosit o parte fractionara la campul sursa
	insert into #general select g.lm,g.comanda,sum(g.valoare), cg.articol_grup as articol, max(isnull(a.denumire,'<inexistent>')) as denart, 
		max(isnull(a.ordinea_in_raport,0)) as ordinea_in_raport, (convert(float,g.sursa/1.01))+0.1 as sursa,g.data, g.tip_comanda, max(excludval),
		max(centru)
	from #general g 
		inner join compartg cg on g.articol=cg.articol_componenta 
		left join artcalc a on cg.articol_grup=a.articol_de_calculatie
	group by g.lm,g.comanda,g.data,g.tip_comanda,cg.articol_grup, g.sursa

	--------------------

	if exists (select 1 from sysobjects where type='P' and name='PostcalculSP')
		exec PostcalculSP @ddatajos, @ddatasus, @comanda, @cLM, @RepartizareCost, @tipcomanda, @stare, @beneficiar, @grupacom, @complet, @Grupare, @sursa
	--------------------

	select f.lm as Loc_munca, max(f.tip_comanda) as tip_comanda, rtrim(f.Comanda) Comanda, 
		max(isnull(c.descriere,'<inexistenta>')) as Denumire,sum(f.valoare) as valoare, f.articol, max(f.DenArt) as denart, 
		max(f.ordinea_in_raport) as ordinea_in_raport, isnull(rtrim(p.cod_produs)+'-'+g.denumire_grupa,'') as grupa, 
		left(f.data,3) as luna,convert(varchar(4),year(f.data)) as anul, f.sursa, max(f.excludval) as excludval, max(f.centru) as centru,
		max(MONTH(f.data)) as luna_numerica, max(l.denumire) as nume_lm,
		rtrim(case when @Grupare='L' or @Grupare='D' then f.lm when @Grupare='G' then
			isnull(rtrim(p.cod_produs)+'-'+g.denumire_grupa,'') else f.comanda end) as grupa_mare,
		max(rtrim(case @Grupare when 'L' then 'Loc de munca: '+rtrim(f.lm)+' ('+rtrim(l.denumire)+')'
							when 'G' then 'Grupa: '+isnull(rtrim(p.cod_produs)+'-'+rtrim(g.denumire_grupa),'')
							when 'D' then 'Centru: '+rtrim(f.lm)+' ('+rtrim(l.denumire)+')'
							else 'Comanda: '+rtrim(f.comanda)+' ('+isnull(rtrim(c.descriere),'<inexistenta>')+')' end)) as denumire_mare,
		rtrim(case when @Grupare='C' then left(f.data,3)+'|'+convert(varchar(4),year(f.data))
					when @Grupare='M' then rtrim(f.lm)
					else f.comanda end) as grupa_mica,
		max(rtrim(case	when @Grupare='C' then left(f.data,3)+' '+convert(varchar(4),year(f.data))
						when @Grupare='M' then 'Loc de munca: '+rtrim(f.lm)+' ('+rtrim(l.denumire)+')'
				else rtrim(f.comanda)+' ('+isnull(rtrim(c.descriere),'<inexistenta>')+')' end)) as denumire_mica
		
	from
		(select lm,comanda,valoare,articol, denart, ordinea_in_raport+1 as ordinea_in_raport,floor(sursa) as sursa,data,tip_comanda, excludval, centru
			from #general where floor(sursa)=1 
		union all
		select lm,comanda,valoare,'Total#1' as articol, 'Cost productie' as denart, ordinea_in_raport,2 as sursa,data,tip_comanda, excludval, centru
			from #general where sursa=1 
		union all
		select lm,comanda,valoare,articol, denart, ordinea_in_raport,floor(sursa),data,tip_comanda, excludval, centru 
			from #general where floor(sursa)=2 
		union all
		select lm,comanda,valoare,'Total#2' as articol, 'Cost complet' as denart, ordinea_in_raport+1 as ordinea_in_raport, 2.1 as sursa,
			data,tip_comanda, excludval, centru 
			from #general where @complet=1 and floor(sursa)=sursa
		union all
		select lm,comanda,valoare,articol, denart, ordinea_in_raport,floor(sursa),data,tip_comanda, excludval, centru 
			from #general where floor(sursa)=3 
		--union all
		--select lm,comanda,valoare,articol, denart, ordinea_in_raport,sursa,data,tip_comanda, 0, '' from #sp_rem  
		) f 
		left join comenzi c on f.comanda=c.comanda 
		left join pozcom p on p.subunitate='GR' and c.comanda=p.comanda
		left join grcom g on p.cod_produs=g.grupa
		left join lm l on l.Cod=f.lm
	where c.subunitate = @subunitate 
		and (@cLM is null or f.lm like rtrim(@cLM)+'%')
		and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=f.lm))
		and charindex(isnull(c.tip_comanda,'#'),@tipcomanda)<>0
		and (@comanda is null or f.comanda=@comanda) and 
		(@stare='F' and (f.comanda not in (select comanda_inf from costsql where data=@ddatasus and lm_sup='' and comanda_sup='' and art_sup='N')
			or data between @ddatajos and isnull((select max(data_lunii) from calstd left outer join costsql c1 on c1.lm_sup='' and 
			c1.comanda_sup='' and c1.art_sup='N' and c1.comanda_inf=f.comanda and c1.data=calstd.data_lunii 
			where calstd.data_lunii=calstd.data and calstd.data_lunii between @ddatajos and @ddatasus and c1.comanda_inf is null),'01/01/1901'))
			or (@stare='N' and not((f.comanda not in (select comanda_inf from costsql where data=@ddatasus and lm_sup='' and comanda_sup='' and art_sup='N')
			or data between @ddatajos and isnull((select max(data_lunii) from calstd left outer join costsql c1 on c1.lm_sup='' and 
					c1.comanda_sup='' and c1.art_sup='N' and c1.comanda_inf=f.comanda and c1.data=calstd.data_lunii 
			where calstd.data_lunii=calstd.data and calstd.data_lunii between @ddatajos and @ddatasus and c1.comanda_inf is null),'01/01/1901'))))
			or @stare='')
	and (@beneficiar is null or exists (select 1 from comenzi cc where cc.beneficiar=@beneficiar and f.comanda=cc.comanda
	and cc.subunitate = @subunitate))
	and (@grupacom is null or exists (select 1 from pozcom p where p.subunitate='GR' and p.cod_produs=@grupacom and f.comanda=p.comanda))
	group by f.lm, f.comanda, isnull(rtrim(p.cod_produs)+'-'+g.denumire_grupa,''), f.articol,left(data,3),year(data),sursa
	order by case when @Grupare='C' then f.comanda when @Grupare in ('L','D') then 'f.lm, f.comanda' else f.comanda end

	--drop table #sp_rem
	drop table #general
	drop table #c
	drop table #tmpcost
