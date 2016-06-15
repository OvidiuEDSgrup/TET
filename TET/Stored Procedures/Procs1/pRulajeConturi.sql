--***
create procedure pRulajeConturi(
	@nivelPlanContabil varchar(1)	/*	0	=>	rulaje/solduri doar pe conturi fara analitice
										1	=>	rulaje/solduri calculate la toate nivelele
										2	=>	[2]+rulaje/solduri pe clase si total general solduri	*/
	,@dData datetime				-->	daca se doreste soldul se va lasa @datajos cu default sau se va trimite @datajos<'1902-1-1', altfel 
	,@datajos datetime ='1901-1-1'	-->	procedura se va comporta ca si cum s-ar cere rulajul din intervalul @datajos si @dData
	,@cCont varchar(40) = null, @cValuta varchar(20)=null, @cJurnal char(3)=null, @cLM char(9)=null
	,@grlm bit=0, @grindbug bit=0	--> grupare pe loc de munca sau indicator bugetar
	,@parxml xml =null	-->pentru filtre suplimentare
	,@sesiune varchar(50) = NULL
	)
/*
	declare @cCont varchar(40), @cValuta char(3), @dData datetime, @cJurnal char(3), @cLM char(9)
	select @cCont='531', @cValuta='', @dData='2010-1-1'
--*/

as
declare @eroare varchar(max)
begin try
	if object_id('tempdb..#sume') is not null drop table #sume
	if object_id('tempdb..#arbcnt') is not null drop table #arbcnt
	
		select @datajos=isnull(@datajos, '1901-1-1')
	declare @solduri bit	--> flag de indicare daca se calculeaza solduri
		,@indicator varchar(100)	--> filtru pe indicator
		,@initancont int		--> flag de indicare calcul soldul de inceput de an dinspre operatia de initializare an conturi
	select @solduri=0
		,@indicator=@parxml.value('(row/@indicator)[1]','varchar(100)')+'%'
		,@initancont=@parxml.value('(row/@initancont)[1]','int')
	if not (@datajos>'1902-1-1') set @solduri=1
	set @cCont=ISNULL(@cCont,'')
	--if @cCont is null set @cCont=''
	if @cValuta is null set @cValuta=''
	--if @dData is null set @dData=convert(datetime, convert(char(10), getdate(), 104), 104)
	if @cJurnal is null set @cJurnal=''
	if @cLM is null set @cLM=''
	
	create table #arbcnt(Cont varchar(40), Cont_parinte varchar(40), suma_debit decimal(20,3), suma_credit decimal(20,3), 
					Are_analitice varchar(1), Tip_cont varchar(1), calculat varchar(1), Denumire_cont varchar(100),
					nivel int default 1,	--> nivel=1 <=> conturi sau mai sus; nivel>1 <=> detalii pe loc de munca, indicator,...
					loc_de_munca varchar(1000) default '',
					indbug varchar(1000) default '', valuta varchar(100) default '')
	
	--> daca nu exista contul se va bloca; evit situatia:
		if not exists (select 1 from conturi c where c.cont like rtrim(@cCont)+'%')
			select @eroare='Nu exista conturi de forma '+@cCont+'% in planul de conturi!'
		if len(@eroare)>0
			raiserror(@eroare,16,1)

	--> se filtreaza pe @cCont:
	declare @n int, @n_anterior int
	select @n=0, @n_anterior=-1

	insert into #arbcnt (Cont, Cont_parinte, suma_debit, suma_credit, 
						Are_analitice, Tip_cont, calculat, Denumire_cont)
	select cont,cont_parinte,0,0,c.Are_analitice,c.Tip_cont,0,rtrim(c.Denumire_cont) from conturi c where c.cont like rtrim(@cCont)+'%'

	while @n>@n_anterior
	begin
		select @n_anterior=@n
		insert into #arbcnt (Cont, Cont_parinte, suma_debit, suma_credit,
						Are_analitice, Tip_cont, calculat, Denumire_cont)
		select c.cont,c.cont_parinte,0,0,c.Are_analitice,c.Tip_cont,0,rtrim(c.Denumire_cont)
			from conturi c
			where exists (select 1 from #arbcnt p where p.cont=c.Cont_parinte)
				and not exists (select 1 from #arbcnt a where a.cont=c.cont)
				--and c.cont<>c.cont_parinte
		select @n=count(1) from #arbcnt
	end

	declare @cSub char(9), @nAnulImpl int, @nLunaImpl int, @dDataImpl datetime, @dDataIncLuna datetime, @dDataIncAn datetime,
	 @dDataSusRulaje datetime, @dDataJosPozincon datetime, @cTipCont char(1), @nAreAnalitice int, @nDiferenta float, @nRulDeb float, @nRulCred float, @nr int

	set @cSub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')
	set @nAnulImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULIMPL'), '1901')
	set @nLunaImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAIMPL'), '')
	set @dDataImpl=dateadd(month, @nLunaImpl, dateadd(year, @nAnulImpl-1901, '01/01/1901'))
	--if @dDataImpl>@dData set @dData=@dDataImpl

	set @dDataIncLuna=dbo.bom(@dData)
	set @dDataIncAn=(case when @initancont=1 then dbo.boy(DateADD(day,-1,@dData)) --daca initalizare an cont conturi, data inceput de an=data inceput an anterior celui initializat.
		else dbo.boy(@dData) end)--dateadd(month, 1-month(@dDataIncLuna), @dDataIncLuna)

	set @dDataSusRulaje=@dData-(case when @dData>@dDataIncAn then 1 else 0 end)
	if @solduri=0 set @dDataSusRulaje=@datajos-1 --(case when @datajos>@dDataIncAn then 1 else 0 end)
	set @dDataJosPozincon=dbo.bom(@dDataSusRulaje+1)

	set @cTipCont='B'
	set @nAreAnalitice=0
	select @cTipCont=tip_cont, @nAreAnalitice=are_analitice 
		from conturi where subunitate=@cSub and cont=@cCont

		/**	O verificare a planului contabil (pentru a nu intra in bucla functia)	*/
	select @eroare='Contul "'+rtrim(c.cont)+'" este configurat gresit! Este declarat cu analitice dar nu are nici unul!'
		from #arbcnt c where not exists (select 1 from #arbcnt cc where cc.Cont_parinte=c.Cont) and c.Are_analitice=1
	select @eroare='Contul "'+rtrim(c.cont)+'" este configurat gresit! Este declarat fara analitice desi acestea exista!'
		from #arbcnt c where exists (select 1 from #arbcnt cc where cc.Cont_parinte=c.Cont) and c.Are_analitice=0
	if len(@eroare)>0
		raiserror(@eroare,16,1)
--/*
	declare @comanda_str varchar(max)
	--> se culeg sumele din rulaje si pozincon:
		create table #sume (suma_debit decimal(20,4), suma_credit decimal(20,4), cont varchar(100), loc_de_munca varchar(100) default null, indbug varchar(100) default null, valuta varchar(100) default null)
	select @comanda_str='
		declare @cSub char(9)
			,@cValuta varchar(20)
			,@dDataIncAn datetime
			,@dDataSusRulaje datetime
			,@datajos datetime
			,@cLM varchar(100)
			,@indicator varchar(100)
			,@dDataJosPozincon datetime
			,@dData	datetime
			,@cJurnal varchar(100)
		
		select @cSub='+rtrim(@cSub)+'
			,@cValuta="'+rtrim(@cValuta)+'"
			,@dDataIncAn="'+convert(varchar(20),@dDataIncAn,102)+'"
			,@dDataSusRulaje="'+convert(varchar(20),@dDataSusRulaje,102)+'"
			,@datajos="'+convert(varchar(20),@datajos,102)+'"
			,@cLM="'+rtrim(@cLM)+'"
			,@indicator='+isnull('"'+rtrim(@indicator)+'"','null')+'
			,@dDataJosPozincon="'+convert(varchar(20),@dDataJosPozincon,102)+'"
			,@dData="'+convert(varchar(20),@dData,102)+'"
			,@cJurnal="'+rtrim(@cJurnal)+'"
		
		-->	autofiltrare pe locuri de munca:
		declare @eLmUtiliz int, @utilizator varchar(20)
		select @utilizator=dbo.fIaUtilizator("'+ISNULL(@sesiune,'')+'")
		declare @LmUtiliz table(valoare varchar(200))
		if (isnull((select val_logica from par where tip_parametru="GE" and parametru="rulajelm"),0)=1)
		begin		/**	doar daca avem setarea pe locuri de munca se iau rulajele feliate pe locuri de munca*/
			insert into @LmUtiliz(valoare)
			select cod from lmfiltrare l where l.utilizator=@utilizator
		end
		set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)--*/
		
		insert into #sume (suma_debit, suma_credit, cont, loc_de_munca, indbug, valuta)
		select	sum(case when Are_analitice=0 and (Tip_cont="A" or Tip_cont="B" and suma_debit-suma_credit>0) then suma_debit-suma_credit else 0 end) as suma_debit,
				sum(case when Are_analitice=0 and (Tip_cont="P" or Tip_cont="B" and suma_debit-suma_credit<0) then -(suma_debit-suma_credit) else 0 end) as suma_credit,
						cont'
			+(case when @grlm=1 then ',loc_de_munca' else ',""' end)
			+(case when @grindbug=1 then ',indbug' else ',""' end)+'
			, max(valuta) from
		(
		 select sum(round(convert(decimal(15, 3), r.rulaj_debit), 2)) suma_debit,sum(round(convert(decimal(15, 3), r.rulaj_credit), 2)) as suma_credit,r.cont,
			MAX(a.Are_analitice) as Are_analitice,a.Tip_cont'
			+(case when @grlm=1 then ',r.loc_de_munca' else '' end)
			+(case when @grindbug=1 then ',r.indbug' else '' end)+'
			, max(r.valuta) valuta
		 from rulaje r, #arbcnt a
		 where 
			r.subunitate=@cSub and r.cont=a.cont and (r.valuta=@cValuta or @cValuta="valuta" and isnull(r.valuta,"")<>"")
			and r.data between @dDataIncAn and @dDataSusRulaje and r.data>=@datajos 
			and r.loc_de_munca like RTrim(@cLM)+"%"
			and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=r.Loc_de_munca))
			and (@indicator is null or r.indbug like @indicator)
		group by r.Cont, a.Tip_cont'
			+(case when @grlm=1 then ',r.loc_de_munca' else '' end)
			+(case when @grindbug=1 then ',r.indbug' else '' end)+'
		 union all
		 select sum(
		 round(convert(decimal(15, 3), (case when @cValuta="" then p.suma else p.suma_valuta end)), 2)
		 ) suma_debit,0 suma_credit, p.Cont_debitor cont,MAX(a.Are_analitice) as Are_analitice,a.Tip_cont'
			+(case when @grlm=1 then ',p.loc_de_munca' else '' end)
			+(case when @grindbug=1 then ',p.indbug' else '' end)+'
			, max(p.valuta) valuta
		 from pozincon p, #arbcnt a
		 where 
			 p.subunitate=@cSub and p.data between @dDataJosPozincon and @dData-1 and p.data>=@datajos
			 and p.loc_de_munca like RTrim(@cLM)+"%" and p.cont_debitor=a.cont
			 and (@cValuta="" or p.valuta=@cValuta or @cValuta="valuta" and isnull(p.valuta,"")<>"") and (@cJurnal="" or p.jurnal=@cJurnal)
			 and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=p.Loc_de_munca))
			 and (@indicator is null or p.indbug like @indicator)
		 group by p.Cont_debitor,a.Tip_cont'
			+(case when @grlm=1 then ',p.loc_de_munca' else '' end)
			+(case when @grindbug=1 then ',p.indbug' else '' end)+'
		 union all
		 select 0,sum(
		 round(convert(decimal(15, 3), (case when @cValuta="" then p.suma else p.suma_valuta end)), 2)) suma_credit,p.Cont_creditor
		 ,MAX(a.Are_analitice) as Are_analitice,a.Tip_cont'
			+(case when @grlm=1 then ',p.loc_de_munca' else '' end)
			+(case when @grindbug=1 then ',p.indbug' else '' end)+'
			, max(p.valuta) valuta
		 from pozincon p, #arbcnt a
		 where 
			 p.subunitate=@cSub and p.data between @dDataJosPozincon and @dData-1 and p.data>=@datajos
			 and p.loc_de_munca like RTrim(@cLM)+"%" and p.cont_creditor=a.cont
			 and (@cValuta="" or p.valuta=@cValuta or @cValuta="valuta" and isnull(p.valuta,"")<>"") and (@cJurnal="" or p.jurnal=@cJurnal) 
			 and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=p.Loc_de_munca))
			 and (@indicator is null or p.indbug like @indicator)
		 group by p.Cont_creditor,a.Tip_cont'
			+(case when @grlm=1 then ',p.loc_de_munca' else '' end)
			+(case when @grindbug=1 then ',p.indbug' else '' end)+'
		) x group by cont'
			+(case when @grlm=1 then ',loc_de_munca' else '' end)
			+(case when @grindbug=1 then ',indbug' else '' end)

	select @comanda_str=replace(@comanda_str,'"','''')
	exec (@comanda_str)
	--select * from #sume
	--> se completeaza in #arbcnt:
		--> partea de detalii, daca este cazul:
			if @grlm=1 or @grindbug=1
			insert into #arbcnt (Cont, Cont_parinte, suma_debit, suma_credit, 
					Are_analitice, Tip_cont, calculat, Denumire_cont, nivel, loc_de_munca, indbug, valuta)
			select a.cont, a.cont_parinte, s.suma_debit, s.suma_credit, a.are_analitice, a.tip_cont, a.calculat, a.denumire_cont,
					2 nivel, s.loc_de_munca, s.indbug, s.valuta
			from #arbcnt a inner join #sume s on a.cont=s.cont
		--> partea centralizata pe conturi:
			update a set a.suma_credit=c.suma_credit,
					a.suma_debit=c.suma_debit
			from #arbcnt a,
					(select sum(suma_credit) suma_credit, sum(suma_debit) suma_debit, cont from #sume group by cont) c
			where a.Cont=c.Cont and a.nivel=1
--*/	

	--> se adauga sintetice "artificiale" pentru clasa si total, daca e cazul:
		if (@nivelPlanContabil=2)
		begin
			insert into #arbcnt(cont, cont_parinte, suma_debit, suma_credit, Are_analitice, Tip_cont, calculat,c.Denumire_cont)
				select LEFT(cont,1),' T',0,0,1,'B',0,'Clasa '+LEFT(cont,1) from #arbcnt a where a.nivel=1 group by LEFT(cont,1)
			update c set Cont_parinte=LEFT(cont,1) from  #arbcnt c 
				where not exists (select 1 from #arbcnt cc where c.Cont_parinte=cc.Cont and cc.nivel=1) and c.Cont_parinte<>' T' --Cont_parinte =''
			insert into #arbcnt(cont, cont_parinte, suma_debit, suma_credit, Are_analitice, Tip_cont, calculat,c.Denumire_cont)
				select ' T','',0,0,1,'B',0,'Total'
		end
	--> update de pe analitice pe sintetice;
	--> calculat: 0=de calculat, 1=calculat dar cont_parinte necalculat, 2=calculat si cont_parinte calculat, 3=in curs de calcul
	if (@nivelPlanContabil>0)
	begin
		--> initializez datele care nu au nici un subaltern:
		update a set calculat=1 from #arbcnt a
			where not exists (select 1 from #arbcnt c where a.cont=c.cont_parinte and a.nivel=c.nivel and a.loc_de_munca=c.loc_de_munca and a.indbug=c.indbug)
			--Are_analitice=0
		select @n=0	--> cu @n evit blocarea in bucla, in caz de exceptie "exceptionala" de plan contabil... scris gresit... in bucla...
		while exists(select 1 from #arbcnt where calculat=0) and @n<1000
		begin
			select @n=@n+1
			update a set	suma_debit=x.suma_debit--(case when Tip_cont='A' then x.suma_debit + x.suma_credit else x.suma_debit end)
							,
							suma_credit=x.suma_credit--(case when Tip_cont='P' then x.suma_debit + x.suma_credit else x.suma_credit end)
							,
					calculat=3
			from	#arbcnt a, 
					(select cont_parinte as cont, x.nivel, loc_de_munca, indbug, sum(x.suma_credit) suma_credit, SUM(x.suma_debit) suma_debit
						from #arbcnt x where calculat=1 group by cont_parinte, x.nivel, loc_de_munca, indbug)x
					where a.nivel=x.nivel and x.cont=a.Cont and a.loc_de_munca=x.loc_de_munca and a.indbug=x.indbug
						and a.calculat=0
						and not exists (select 1 from #arbcnt c where a.Cont=c.cont_parinte and c.calculat=0 and c.nivel=a.nivel and c.loc_de_munca=a.loc_de_munca and c.indbug=a.indbug)
			update a set calculat=2 from #arbcnt a where calculat=1 and not exists 
					(select 1 from #arbcnt c where c.nivel=a.nivel and c.Cont=a.cont_parinte and c.calculat=0 and c.loc_de_munca=a.loc_de_munca and c.indbug=a.indbug)
			update #arbcnt set calculat=1 where calculat=3
		end
		if @n=1000
		begin
			select @eroare='Eroare la calculul soldurilor (poate fi o problema de configurare plan contabil)! - cel putin linia contului '+a.cont+' avand cont parinte '+a.cont_parinte+' a ramas necalculata' from #arbcnt a where a.calculat=0
			raiserror(@eroare,16,1)
		end
	end

	--> organizare sume rulaje in solduri, daca este cazul:
	if (@solduri=1)
		update a set
			suma_debit=(case a.Tip_cont when 'A' then a.suma_debit-a.suma_credit when 'B' then
				(case when a.suma_debit-a.suma_credit>0 then a.suma_debit-a.suma_credit else 0 end) else 0 end),
			suma_credit=(case a.Tip_cont when 'P' then a.suma_credit-a.suma_debit when 'B' then
				(case when a.suma_credit-a.suma_debit>0 then a.suma_credit-a.suma_debit else 0 end) else 0 end)
		from #arbcnt a

	if object_id('tempdb..#pRulajeConturi_t') is null
	begin
		create table #pRulajeConturi_t (Subunitate varchar(10) default 1)
		exec pRulajeConturi_tabela
	end

	insert into #pRulajeConturi_t(Cont, Cont_parinte, suma_debit, suma_credit, Are_analitice, Tip_cont, Denumire_cont, loc_de_munca, indbug, nivel, valuta)
	select Cont, Cont_parinte, suma_debit, suma_credit, Are_analitice, Tip_cont, Denumire_cont, loc_de_munca, indbug, nivel, @cValuta valuta from #arbcnt order by cont
end try
begin catch
	set @eroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
end catch

	if object_id('tempdb..#sume') is not null drop table #sume
	if object_id('tempdb..#arbcnt') is not null drop table #arbcnt
if len(@eroare)>0
	raiserror(@eroare,16,1)
