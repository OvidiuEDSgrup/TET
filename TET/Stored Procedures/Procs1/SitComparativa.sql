--***
create procedure SitComparativa(@sesiune varchar(50)=null, @dDataJos datetime, @dDataSus datetime, @cLM char(9), @cComanda char(20),@Terminate int, @Facturate int, 
	@GrupaCom char(20), @ArtCalc varchar(300), @ArtCalcExcep varchar(300),@lExact int,@beneficiar char(20) =null, 
	@siSemif bit, @cu_tab_tmp bit=0, @datajfacturare datetime, @datasfacturare datetime,@Tip_comanda char(1)='T') 
as 
begin 
	set transaction isolation level read uncommitted
	if @cLM is null set @cLM=''
	if @ArtCalcExcep is null set @ArtCalcExcep=''
	declare @nLm int,@subunitate char(9), @cContVenExcept char(20)
	set @subunitate = (select val_alfanumerica from par where tip_parametru = 'GE' and parametru = 'SUBPRO')
	set @cContVenExcept=isnull((select val_alfanumerica from par where tip_parametru='PC' and parametru='CVENEXCEP'),'')

	if @datajfacturare is null set @datajfacturare='01/01/1901' 
	if @datasfacturare is null set @datasfacturare='12/31/2999' 
	set @cComanda=ISNULL(@cComanda,'')
	set @nLm=isnull((select max(lungime) from strlm where costuri=1), 9) 

	--> pregatire auto-filtrare pe loc de munca	
		declare @utilizator varchar(20), @eLmUtiliz int
		exec wiautilizator @sesiune=@sesiune, @utilizator=@utilizator output
		select @eLmUtiliz=0
		select @eLmUtiliz=1 from lmfiltrare where utilizator=@utilizator

		declare @LmUtiliz table(valoare varchar(200))
		insert into @LmUtiliz(valoare)
		select cod from lmfiltrare where utilizator=@utilizator
	
	select 'P' as tip, 1 as CO 
		into #tccpc 
	union all 
	select 'R', 0 
	if @siSemif=1 insert into #tccpc select 'S',1 
	
	select left(p.loc_de_munca,@nLm) as loc_de_munca, (case when c.tip_comanda='C' then p.cod else p.comanda end) as comanda, 
		max(isnull(c.descriere,'')) as descriere, p.cod, p.cod_intrare, sum(p.cantitate) as cantitate, sum(p.cantitate*p.pret_de_stoc) as valoare 
	into #pr from pozdoc p 
		left join comenzi c on p.subunitate=c.subunitate and p.comanda=c.comanda and c.tip_comanda<>'A' 
	where c.subunitate = @subunitate and p.data between @dDataJos and @dDataSus and p.loc_de_munca like rtrim(@cLM)+'%' and 
		(@cComanda='' or p.comanda=@cComanda) and p.tip='PP' 
		and (@lExact=1 or exists (select * from costsql sq where sq.data between @dDataJos and @dDataSus 
		and lm_sup='' and comanda_sup='' and exists (select 1 from #tccpc tc where tc.CO=1 and art_sup=tc.tip) 
		and p.comanda=comanda_inf and left(p.loc_de_munca,@nLm)=lm_inf))
		and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=p.loc_de_munca))
	group by p.loc_de_munca, (case when c.tip_comanda='C' then p.cod else p.comanda end), p.cod, p.cod_intrare 
	
	select 'FA' as tip,pp.loc_de_munca,max(isnull(c.tip_comanda,'')) as tip_comanda,pp.comanda,max(isnull(c.descriere,'')) as descriere, 
		sum(po.cantitate) as cantitativ, sum(po.cantitate*po.pret_vanzare) as valoric 
	into #sitcom from pozdoc po
		inner join #pr pp on po.cod=pp.cod and po.cod_intrare=pp.cod_intrare 
		left outer join comenzi c on po.subunitate=c.subunitate and pp.comanda=c.comanda 
	where c.subunitate = @subunitate and po.tip='AP' and pp.loc_de_munca like rtrim(@cLM)+'%' and (@cComanda='' or pp.comanda=@cComanda) and 
		exists (select 1 from #tccpc tc where tc.CO=1 and c.tip_comanda=tc.tip) 
		and po.data between @datajfacturare and @datasfacturare
		and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=pp.loc_de_munca))
	group by pp.loc_de_munca,pp.comanda 
	union all 
	--TE catre gest V
	select 'FA' as tip,pp.loc_de_munca,max(isnull(c.tip_comanda,'')) as tip_comanda,pp.comanda,max(isnull(c.descriere,'')) as descriere, 
		sum(po.cantitate) as cantitativ, sum(po.cantitate*(po.pret_cu_amanuntul * 100 /119)) as valoric 
	from pozdoc po
		inner join #pr pp on po.cod=pp.cod and po.cod_intrare=pp.cod_intrare 
		left outer join comenzi c on po.subunitate=c.subunitate and pp.comanda=c.comanda 
		inner join gestiuni g on po.gestiune = g.cod_gestiune 
	where c.subunitate = @subunitate and po.tip = 'TE' and pp.loc_de_munca like rtrim(@cLM)+'%' and (@cComanda='' or pp.comanda=@cComanda) and 
		exists (select 1 from #tccpc tc where tc.CO=1 and c.tip_comanda=tc.tip) 
		and po.data between @datajfacturare and @datasfacturare and g.tip_gestiune = 'V' 
		and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=pp.loc_de_munca))
	group by pp.loc_de_munca,pp.comanda 
	union all 
	--Fact:Serv sau comert 
	select 'FA',left(po.loc_de_munca,@nLm),max(isnull(c.tip_comanda,'')),po.comanda,max(isnull(c.descriere,'')), 
		sum(po.cantitate) as cantitativ, sum(po.cantitate*po.pret_vanzare) as valoric 
	from pozdoc po 
		left outer join comenzi c on po.subunitate=c.subunitate and po.comanda=c.comanda 
	where c.subunitate = @subunitate and po.data between @datajfacturare and @datasfacturare 
		and po.cont_venituri like '70%' and po.cont_venituri not like rtrim(@cContVenExcept)+'%' 
		and c.tip_comanda='R' 
		and po.tip in ('AP','AS') 
		and left(po.loc_de_munca,@nLm) like rtrim(@cLM)+'%' and (@cComanda='' or po.comanda=@cComanda) 
		and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=left(po.loc_de_munca,@nLm)))
	group by left(po.loc_de_munca,@nLm),po.comanda 
	union all 
	--Fact FB 
	select 'FA', left(p.loc_munca,@nLm), max(isnull(c.tip_comanda,'')), p.comanda, max(isnull(c.descriere,'')), 1, sum(p.suma) 
	from pozadoc p left outer join comenzi c on c.subunitate=p.subunitate and c.comanda=p.comanda 
	where c.subunitate = @subunitate and p.tip='FB' and p.data between @datajfacturare and @datasfacturare 
		and left(p.loc_munca,@nLm) like rtrim(@cLM)+'%' and (@cComanda='' or p.comanda=@cComanda) 
		and p.Cont_cred like '70%' and p.Cont_cred not like rtrim(@cContVenExcept)+'%' 
	group by left(p.loc_munca,@nLm), p.comanda 
	union all 
	--Pentru UA
	select 'FA', left(p.Loc_de_munca,@nLm), max(isnull(c.tip_comanda,'')), p.comanda, max(isnull(c.descriere,'')), 1, sum(p.suma) 
	from pozincon p left outer join comenzi c on c.subunitate=p.subunitate and c.comanda=p.comanda 
	where c.subunitate = @subunitate and p.Tip_document in ('NC','UA') 
		and p.Cont_creditor like '70%' and p.Cont_creditor not like rtrim(@cContVenExcept)+'%' 
		and p.data between @datajfacturare and @datasfacturare and 
		left(p.Loc_de_munca,@nLm) like rtrim(@cLM)+'%' and (@cComanda='' or p.comanda=@cComanda) 
	group by left(p.Loc_de_munca,@nLm), p.comanda 
	union all
	--Inc IC 
	select 'FA', left(p.loc_de_munca,@nLm), max(isnull(c.tip_comanda,'')), (case when p.comanda='' then sp.comanda else p.comanda end), 
		max(isnull(c.descriere,'')), 1, sum(p.suma-p.TVA22) 
	from pozplin p left outer join speciflm sp on sp.loc_de_munca=left(p.loc_de_munca,@nLm) 
		left outer join comenzi c on c.subunitate=p.subunitate and c.comanda=p.comanda 
	where c.subunitate = @subunitate and p.plata_incasare='IC' and p.data between @datajfacturare and @datasfacturare and 
		left(p.loc_de_munca,@nLm) like rtrim(@cLM)+'%' and (@cComanda='' or (case when p.comanda='' then sp.comanda else p.comanda end)=@cComanda)
		and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=left(p.loc_de_munca,@nLm)))
	group by left(p.loc_de_munca,@nLm), (case when p.comanda='' then sp.comanda else p.comanda end) 
	union all 
	--cost marfa 
	select 'CA',left(p.loc_de_munca,@nLm), max(isnull(c.tip_comanda,'')),(case when p.comanda='' then sp.comanda else p.comanda end),
		max(isnull(c.descriere,'')), 1 as cantitativ, sum(p.suma) as valoric 
	from pozincon p 
		left outer join speciflm sp on sp.loc_de_munca=left(p.loc_de_munca,@nLm) 
		left outer join comenzi c on p.subunitate=c.subunitate and (case when p.comanda='' then sp.comanda else p.comanda end)=c.comanda 
	where c.subunitate = @subunitate and p.cont_debitor like '607%' and left(p.loc_de_munca,@nLm) like rtrim(@cLM)+'%' 
		and (@cComanda='' or (case when p.comanda='' then sp.comanda else p.comanda end)=@cComanda) 
		and p.data between @ddatajos and @ddatasus 
		and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=left(p.loc_de_munca,@nLm)))
	group by left(p.loc_de_munca,@nLm),(case when p.comanda='' then sp.comanda else p.comanda end) 
	union all 
	--pp
	select 'PP',left(p.loc_de_munca,@nLm), max(isnull(c.tip_comanda,'')),(case when c.tip_comanda='C' then p.cod else p.comanda end),
		max(isnull(c.descriere,'')),sum(p.cantitate) as cantitativ, sum(p.cantitate*p.pret_de_stoc) as valoric 
	from pozdoc p 
		left outer join comenzi c on p.subunitate = c.subunitate and p.comanda=c.comanda and c.tip_comanda<>'A' 
	where c.subunitate = @subunitate and p.tip='PP' and left(p.loc_de_munca,@nLm) like rtrim(@cLM)+'%' and (@cComanda='' or p.comanda=@cComanda)
		and p.data between @ddatajos and @ddatasus 
		and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=left(p.loc_de_munca,@nLm)))
	group by left(p.loc_de_munca,@nLm), (case when c.tip_comanda='C' then p.cod else p.comanda end)
	union all 
	select 'PP','C', 'R','Sia345','Sold inceput de an 345', 1 as cantitativ, rulaj_debit as valoric 
	from rulaje 
	where data = '01/01/2007' and valuta = '' and cont = '345' and @dDataJos='01/01/2007' 
	union all 
	-- dec comR 
	select 'PP', left(s.lm_inf, @nLm), max(isnull(c.tip_comanda,'')), s.comanda_inf, max(isnull(c.descriere,'')), sum(cantitate) as cantitativ,
		sum(s.cantitate*s.valoare) as valoric 
	from costsql s 
		left outer join comenzi c on s.comanda_inf=c.comanda 
	where c.subunitate = @subunitate and s.lm_inf like rtrim(@cLM)+'%' and (@cComanda='' or s.comanda_inf=@cComanda) 
		and s.data between @dDataJos and @dDataSus 
		and exists (select 1 from #tccpc tc where c.tip_comanda=tc.tip) 
		and lm_sup='' and comanda_sup='' and art_sup='R' and s.tip not in ('PP' ,'PX') 
		and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=s.lm_inf))
	group by lm_inf, comanda_inf 
	union all 
	--cm 
	select 'CM',left(pp.loc_de_munca, @nLm),max(isnull(c.tip_comanda,'')),pp.comanda,max(isnull(c.descriere,'')), 
		sum(po.cantitate) as cantitativ, sum(po.cantitate*po.pret_de_stoc) as valoric 
	from pozdoc po
		left outer join #pr pp on po.cod=pp.cod and po.cod_intrare=pp.cod_intrare 
		left outer join comenzi c on po.subunitate=c.subunitate and pp.comanda=c.comanda 
	where c.subunitate = @subunitate and po.tip in ('CM','AE') and pp.loc_de_munca like rtrim(@cLM)+'%'
		and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=pp.loc_de_munca))
	group by left(pp.loc_de_munca, @nLm),pp.comanda 
	
	Begin	-- <sectiunea pt fosta sitcompcalc>
		/*	exec SitCompCalc @dDataJos, @dDataSus, @cLM,@cComanda ,@Terminate, @Facturate, @GrupaCom, @ArtCalc, 
								@ArtCalcExcep,@lExact, @beneficiar, @siSemif */
		insert into #sitcom 
		--cost efectiv 
		select 'CO', left(s.lm_sup, @nLm), max(isnull(c.tip_comanda,'')), s.comanda_sup, max(isnull(c.descriere,'')),0 as cantitativ, 
				sum(s.cantitate*s.valoare) as valoric 
		from costsql s left outer join comenzi c on s.comanda_sup=c.comanda 
		where c.subunitate = @subunitate and s.lm_sup like rtrim(@cLM)+'%' and (@cComanda='' or s.comanda_sup=@cComanda) and 
				s.data between @dDataJos and @dDataSus and exists (select 1 from #tccpc tc where tc.tip=c.tip_comanda) 
			and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=s.lm_sup))
			and not (s.tip in ('IT','IE')) 
			and (isnull(@ArtCalc,'')='' or charindex(','+rtrim((case when s.art_sup='T' then s.art_inf else s.art_sup end))+',',','+@ArtCalc+',')>0)
			and (isnull(@ArtCalcExcep,'')='' or charindex(','+rtrim((case when s.art_sup='T' then s.art_inf else s.art_sup end))+',',','+@ArtCalcExcep+',')=0) 
			and exists (select 1 from #tccpc tc where c.tip_comanda=tc.tip) 
			and (s.art_inf<>'N' or s.data=(case when @Terminate=2 then dbo.bom(@dDataSus) else dbo.bom(@dDataJos) end)) 
			and (@Terminate=1 and ( 
		 --s.comanda_sup not in (select comanda_inf from costsql where data=@ddatasus and lm_sup='' and comanda_sup='' and art_sup='N') 
				not exists (select 1 from costsql tq where s.comanda_sup=tq.comanda_inf and data=@ddatasus and lm_sup='' and comanda_sup=''
						and art_sup='N') 
				or data between @ddatajos and isnull((select max(data_lunii) from calstd left outer join costsql c1 on c1.lm_sup='' and c1.comanda_sup='' 
						and c1.art_sup='N' and c1.comanda_inf=s.comanda_sup and c1.data=calstd.data_lunii 
					where calstd.data_lunii=calstd.data and calstd.data_lunii between @ddatajos and @ddatasus and c1.comanda_inf is null)
				,'01/01/1901'))
			or (@Terminate=2 and not ( 
		 --s.comanda_sup not in (select comanda_inf from costsql where data=@ddatasus and lm_sup='' and comanda_sup='' and art_sup='N') 
			 not exists (select 1 from costsql tq where s.comanda_sup=tq.comanda_inf and data=@ddatasus and lm_sup='' and comanda_sup='' 
						and art_sup='N') 
			or data between @ddatajos and isnull((select max(data_lunii) from calstd left outer join costsql c1 on c1.lm_sup='' and 
						c1.comanda_sup='' and c1.art_sup='N' and c1.comanda_inf=s.comanda_sup and c1.data=calstd.data_lunii 
						where calstd.data_lunii=calstd.data and calstd.data_lunii between @ddatajos and @ddatasus and c1.comanda_inf is null)
				,'01/01/1901')))
			or @Terminate=0) 
		group by left(s.lm_sup, @nLm), s.comanda_sup 
		union all 
		--neterminata 
		select 'NE', left(s.lm_inf, @nLm), max(isnull(c.tip_comanda,'')), s.comanda_inf, max(isnull(c.descriere,'')), 
			sum(cantitate) as cantitativ, sum(s.cantitate*s.valoare) as valoric 
		from costsql s left outer join comenzi c on s.comanda_inf=c.comanda 
		where c.subunitate = @subunitate and s.lm_inf like rtrim(@cLM)+'%' and (@cComanda='' or s.comanda_inf=@cComanda) 
			--and s.data between @dDataJos and @dDataSus 
			and s.data=(case when @Terminate=2 then dbo.eom(@dDataSus) else dbo.eom(@dDataJos) end) 
			and --c.tip_comanda in (select tip from #tccpc) 
			exists (select 1 from #tccpc tc where c.tip_comanda=tc.tip) 
			and not (s.tip in ('IT','IE')) 
			and lm_sup='' and comanda_sup='' and art_sup='N' 
			and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=s.lm_inf))
		group by lm_inf,comanda_inf 
		--marja = FA (facturat) - CA (cost marfa)
		insert into #sitcom 
		select 'MA',isnull(s1.loc_de_munca,s2.loc_de_munca),isnull(s1.tip_comanda,isnull(s2.tip_comanda,'')),
			isnull(s1.comanda,isnull(s2.comanda,'')), isnull(s1.descriere, isnull(s2.descriere,'')), 
			isnull(s1.cantitativ,0)-isnull(s2.cantitativ,0),isnull(s1.valoric,0)-isnull(s2.valoric,0) 
		from (select distinct loc_de_munca,comanda from #sitcom where tip in ('CA','FA') and loc_de_munca<>'' and comanda<>'') as cm 
			left outer join #sitcom s1 on s1.comanda=cm.comanda and s1.loc_de_munca=cm.loc_de_munca and s1.tip='FA' 
			left outer join #sitcom s2 on s2.comanda=cm.comanda and s2.loc_de_munca=cm.loc_de_munca and s2.tip='CA' 
		--profit brut = FA (facturat) - CO (cost efectiv)
		insert into #sitcom 
		select 'PB',isnull(s1.loc_de_munca,isnull(s2.loc_de_munca,'')),isnull(s1.tip_comanda,isnull(s2.tip_comanda,'')),
			isnull(s1.comanda,isnull(s2.comanda,'')), isnull(s1.descriere, isnull(s2.descriere,'')), 
			isnull(s1.cantitativ,0),isnull(s1.valoric,0)-isnull(s2.valoric,0) 
		from (select distinct loc_de_munca,comanda from #sitcom where tip in ('FA','CO') and loc_de_munca<>'' and comanda<>'') as cm 
			left outer join (select loc_de_munca,comanda,tip_comanda,descriere,sum(cantitativ) as cantitativ, sum(valoric)as valoric 
					from #sitcom where tip='FA' group by loc_de_munca,comanda,tip_comanda,descriere) s1 
				on s1.comanda=cm.comanda and s1.loc_de_munca=cm.loc_de_munca 
		left outer join (select loc_de_munca,comanda,tip_comanda,descriere,sum(cantitativ) as cantitativ, sum(valoric)as valoric 
					from #sitcom where tip='CO' group by loc_de_munca,comanda,tip_comanda,descriere) s2 
				on s2.comanda=cm.comanda and s2.loc_de_munca=cm.loc_de_munca 
		--diferenta pret = PP+NE - CO
		insert into #sitcom 
		select 'DP',isnull(s1.loc_de_munca,isnull(s2.loc_de_munca,'')),isnull(s1.tip_comanda,isnull(s2.tip_comanda,'')),
			isnull(s1.comanda,isnull(s2.comanda,'')), isnull(s1.descriere, isnull(s2.descriere,'')),
			isnull(s1.cantitativ,0),isnull(s1.valoric,0)-isnull(s2.valoric,0) 
		from (select distinct loc_de_munca,comanda from #sitcom  where tip in ('PP','CO','NE') and loc_de_munca<>'' and comanda<>'') as cm 
			left outer join (select s1.loc_de_munca,s1.comanda,s1.tip_comanda,s1.descriere,sum(s1.cantitativ) as cantitativ, 
					sum(s1.valoric)as valoric 
					from #sitcom  s1 where s1.tip in ('PP','NE') 
					group by s1.loc_de_munca,s1.comanda,s1.tip_comanda,s1.descriere) s1 
				on s1.comanda=cm.comanda and s1.loc_de_munca=cm.loc_de_munca
		left outer join #sitcom  s2 on s2.comanda=cm.comanda and s2.loc_de_munca=cm.loc_de_munca and s2.tip='CO'
	End	-- </sectiunea pt fosta sitcompcalc>

	drop table #tccpc 
	delete from #sitcom where @Facturate=1 
		and not exists (select 1 from #sitcom s1 where #sitcom.comanda=s1.comanda and tip='FA' 
							group by s1.comanda having abs(sum(s1.cantitativ))>=0.01) 
	delete from #sitcom where @Facturate=2 
	and exists (select 1 from #sitcom s1 where #sitcom.comanda=s1.comanda and tip='FA'
					group by s1.comanda having abs(sum(s1.cantitativ))>=0.01) 
	delete from #sitcom where 
	@lExact=1 and not exists (select 1 from #sitcom s1 where s1.comanda=#sitcom.comanda and s1.tip='CO') 
	select p.val_numerica as ordine,p.denumire_parametru as dencoloana,substring(p.parametru,6,3) as tip,sd.loc_de_munca,
			sd.tip_comanda,sd.comanda, sd.descriere,c.data_inchiderii,c.beneficiar as tert,t.denumire as den_tert, 
		(case when substring(p.parametru,8,1)='C' then sd.cantitativ else sd.valoric end) as val,
		isnull(rtrim(pz.cod_produs)+'-'+grupe.denumire,'') as 'grupa' 
	into ##tmp 
	from #sitcom sd
		inner join par p on p.tip_parametru='PC' and left(p.parametru,5)='SITCO' and VAL_LOGICA=1 and substring(p.parametru,6,2)=tip 
		left outer join pozcom pz on pz.subunitate='GR' and pz.comanda=sd.comanda 
		left outer join grupe on pz.cod_produs=grupe.grupa 
		left outer join comenzi c on c.comanda=sd.comanda 
		left outer join terti t on c.beneficiar=t.tert 
	where c.subunitate = @subunitate and isnull(c.tip_comanda,'') <>'A' and (isnull(@GrupaCom, '')='' or 
			exists (select 1 from pozcom p where sd.comanda=p.comanda and p.subunitate='GR' and p.cod_produs=isnull(@GrupaCom,'')) 
		) and (isnull(@beneficiar,'')='' or c.beneficiar=@beneficiar) 
		and (@Tip_comanda='T' or sd.tip_comanda=@Tip_comanda or @Tip_comanda='A' and sd.tip_comanda not in ('R','S','P')) 
	if (@cu_tab_tmp=0) 
	begin 
		select * from ##tmp 
		drop table ##tmp 
	end 
end
