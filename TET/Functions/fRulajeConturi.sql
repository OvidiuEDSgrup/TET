--***
create function fRulajeConturi(@nivelPlanContabil varchar(1), @cCont varchar(40), @cValuta varchar(20), @dData datetime, @cJurnal char(3), @cLM char(9), @datajos datetime ='1901-1-1'
	,@parxml xml =null	-->pentru filtre suplimentare
	)
/*
	declare @cCont varchar(40), @cValuta char(3), @dData datetime, @cJurnal char(3), @cLM char(9)
	select @cCont='531', @cValuta='', @dData='2010-1-1'
--*/

returns @arbcnt1 table (Cont char(40) primary key, Cont_parinte char(40), suma_debit decimal(20,3), suma_credit decimal(20,3), 
					Are_analitice varchar(1), Tip_cont varchar(1), Denumire_cont varchar(100))
as
begin
	select @datajos=isnull(@datajos, '1901-1-1')
	declare @solduri bit	--> flag de indicare daca se calculeaza solduri
		,@indicator varchar(100)	--> filtru pe indicator
	select @solduri=0
		,@indicator=@parxml.value('(row/@indicator)[1]','varchar(100)')+'%'
	if not (@datajos>'1902-1-1') set @solduri=1
	set @cCont=(case when ISNULL(@cCont,'')='' then '%' else @cCont end)
	--if @cCont is null set @cCont=''
	if @cValuta is null set @cValuta=''
	--if @dData is null set @dData=convert(datetime, convert(char(10), getdate(), 104), 104)
	if @cJurnal is null set @cJurnal=''
	if @cLM is null set @cLM=''
	
	declare @arbcnt table (Cont varchar(40) primary key, Cont_parinte varchar(40), suma_debit decimal(20,3), suma_credit decimal(20,3), 
					Are_analitice varchar(1), Tip_cont varchar(1), calculat varchar(1), Denumire_cont varchar(100))
	;with x(cont, cont_parinte, suma_debit, suma_credit, Are_analitice, Tip_cont, calculat, Denumire_cont) as 
	(
	select cont,cont_parinte,0,0,c.Are_analitice,c.Tip_cont,0,rtrim(c.Denumire_cont) from conturi c where c.cont like @cCont union all
	select c.cont,c.cont_parinte,0,0,c.Are_analitice,c.Tip_cont,0,rtrim(c.Denumire_cont) from conturi c, x where x.Cont=c.Cont_parinte
	) 
	insert into @arbcnt
	select distinct * from x
	--/*
	declare @eLmUtiliz int, @utilizator varchar(20)
	select @utilizator=dbo.fIaUtilizator('')
	declare @LmUtiliz table(valoare varchar(200))
	if (isnull((select val_logica from par where tip_parametru='GE' and parametru='rulajelm'),0)=1)
	begin		/**	doar daca avem setarea pe locuri de munca se iau rulajele feliate pe locuri de munca*/
		insert into @LmUtiliz(valoare)
		select cod from lmfiltrare l where l.utilizator=@utilizator
	end
	set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)--*/

	declare @cSub char(9), @nAnulImpl int, @nLunaImpl int, @dDataImpl datetime, @dDataIncLuna datetime, @dDataIncAn datetime,
	 @dDataSusRulaje datetime, @dDataJosPozincon datetime, @cTipCont char(1), @nAreAnalitice int, @nDiferenta float, @nRulDeb float, @nRulCred float
,@nr int

	set @cSub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')
	set @nAnulImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULIMPL'), '1901')
	set @nLunaImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAIMPL'), '')
	set @dDataImpl=dateadd(month, @nLunaImpl, dateadd(year, @nAnulImpl-1901, '01/01/1901'))
	if @dDataImpl>@dData set @dData=@dDataImpl

	set @dDataIncLuna=dbo.bom(@dData)
	set @dDataIncAn=dateadd(month, 1-month(@dDataIncLuna), @dDataIncLuna)

	set @dDataSusRulaje=@dData-(case when @dData>@dDataIncAn then 1 else 0 end)
	if @solduri=0 set @dDataSusRulaje=@datajos-1 --(case when @datajos>@dDataIncAn then 1 else 0 end)
	set @dDataJosPozincon=dbo.bom(@dDataSusRulaje+1)

	set @cTipCont='B'
	set @nAreAnalitice=0
	select @cTipCont=tip_cont, @nAreAnalitice=are_analitice 
	from conturi where subunitate=@cSub and cont=@cCont

		/**	O verificare a planului contabil (pentru a nu intra in bucla functia)	*/
	insert into @arbcnt1(cont, cont_parinte, suma_debit, suma_credit, Are_analitice, Tip_cont, c.Denumire_cont)
	select cont, cont_parinte, 0 suma_debit, 0 suma_credit, Are_analitice, Tip_cont, 'Cont configurat gresit! (Nu are analitice!)' Denumire_cont
		from @arbcnt c where not exists (select 1 from @arbcnt cc where cc.Cont_parinte=c.Cont) and c.Are_analitice=1

	if exists(select 1 from @arbcnt1) return
--/*
	update a set a.suma_credit=c.suma_credit,
			a.suma_debit=c.suma_debit
	from @arbcnt a,
	(	select	sum(case when Are_analitice=0 and (Tip_cont='A' or Tip_cont='B' and suma_debit-suma_credit>0) then suma_debit-suma_credit else 0 end) as suma_debit,
				sum(case when Are_analitice=0 and (Tip_cont='P' or Tip_cont='B' and suma_debit-suma_credit<0) then -(suma_debit-suma_credit) else 0 end) as suma_credit,
						cont from
		(
		 select sum(round(convert(decimal(15, 3), r.rulaj_debit), 2)) suma_debit,sum(round(convert(decimal(15, 3), r.rulaj_credit), 2)) as suma_credit,r.cont,
			MAX(a.Are_analitice) as Are_analitice,a.Tip_cont
		 from rulaje r, @arbcnt a
		 where 
			r.subunitate=@cSub and r.cont=a.cont and (r.valuta=@cValuta or @cValuta='valuta' and isnull(r.valuta,'')<>'')
			and r.data between @dDataIncAn and @dDataSusRulaje and r.data>=@datajos 
			and r.loc_de_munca like RTrim(@cLM)+'%'
			and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=r.Loc_de_munca))
			and (@indicator is null or r.indbug like @indicator)
		group by r.Cont, a.Tip_cont
		 union all
		 select sum(
		 round(convert(decimal(15, 3), (case when @cValuta='' then p.suma else p.suma_valuta end)), 2)
		 ) suma_debit,0 suma_credit, p.Cont_debitor cont,MAX(a.Are_analitice) as Are_analitice,a.Tip_cont
		 from pozincon p, @arbcnt a
		 where 
			 p.subunitate=@cSub and p.data between @dDataJosPozincon and @dData-1 and p.data>=@datajos
			 and p.loc_de_munca like RTrim(@cLM)+'%' and p.cont_debitor=a.cont
			 and (@cValuta='' or p.valuta=@cValuta or @cValuta='valuta' and isnull(p.valuta,'')<>'') and (@cJurnal='' or p.jurnal=@cJurnal)
			 and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=p.Loc_de_munca))
			 and (@indicator is null or p.indbug like @indicator)
		 group by p.Cont_debitor,a.Tip_cont
		 union all
		 select 0,sum(
		 round(convert(decimal(15, 3), (case when @cValuta='' then p.suma else p.suma_valuta end)), 2)) suma_credit,p.Cont_creditor
		 ,MAX(a.Are_analitice) as Are_analitice,a.Tip_cont
		 from pozincon p, @arbcnt a
		 where 
			 p.subunitate=@cSub and p.data between @dDataJosPozincon and @dData-1 and p.data>=@datajos
			 and p.loc_de_munca like RTrim(@cLM)+'%' and p.cont_creditor=a.cont
			 and (@cValuta='' or p.valuta=@cValuta or @cValuta='valuta' and isnull(p.valuta,'')<>'') and (@cJurnal='' or p.jurnal=@cJurnal) 
			 and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=p.Loc_de_munca))
			 and (@indicator is null or p.indbug like @indicator)
		 group by p.Cont_creditor,a.Tip_cont
		) x group by cont	
	) c
	where a.Cont=c.Cont
--*/	
	if (@nivelPlanContabil=2)
	begin
		insert into @arbcnt(cont, cont_parinte, suma_debit, suma_credit, Are_analitice, Tip_cont, calculat,c.Denumire_cont)
			select LEFT(cont,1),' T',0,0,1,'B',0,'Clasa '+LEFT(cont,1) from @arbcnt group by LEFT(cont,1)
		update c set Cont_parinte=LEFT(cont,1) from  @arbcnt c 
			where not exists (select 1 from @arbcnt cc where c.Cont_parinte=cc.Cont) and c.Cont_parinte<>' T' --Cont_parinte =''
		insert into @arbcnt(cont, cont_parinte, suma_debit, suma_credit, Are_analitice, Tip_cont, calculat,c.Denumire_cont)
			select ' T','',0,0,1,'B',0,'Total'
	end
	--> update de pe analitice pe sintetice;
	--> calculat: 0=de calculat, 1=calculat dar cont_parinte necalculat, 2=calculat si cont_parinte calculat, 3=in curs de calcul
	if (@nivelPlanContabil>0)
	begin
		update @arbcnt set calculat=1 where Are_analitice=0
		while exists(select 1 from @arbcnt where calculat=0)
		begin
			update a set	suma_debit=x.suma_debit--(case when Tip_cont='A' then x.suma_debit + x.suma_credit else x.suma_debit end)
							,
							suma_credit=x.suma_credit--(case when Tip_cont='P' then x.suma_debit + x.suma_credit else x.suma_credit end)
							,
					calculat=3
			from	@arbcnt a, 
					(select cont_parinte as cont, sum(x.suma_credit) suma_credit, SUM(x.suma_debit) suma_debit
						from @arbcnt x where calculat=1 group by cont_parinte)x
					where x.cont=a.Cont 
						and a.calculat=0
						and not exists (select 1 from @arbcnt c where a.Cont=c.cont_parinte and c.calculat=0)
			update a set calculat=2 from @arbcnt a where calculat=1 and not exists 
					(select 1 from @arbcnt c where c.Cont=a.cont_parinte and c.calculat=0)
			update @arbcnt set calculat=1 where calculat=3
		end
	end

	if (@solduri=1)
		update a set
			suma_debit=(case a.Tip_cont when 'A' then a.suma_debit-a.suma_credit when 'B' then
				(case when a.suma_debit-a.suma_credit>0 then a.suma_debit-a.suma_credit else 0 end) else 0 end),
			suma_credit=(case a.Tip_cont when 'P' then a.suma_credit-a.suma_debit when 'B' then
				(case when a.suma_credit-a.suma_debit>0 then a.suma_credit-a.suma_debit else 0 end) else 0 end)
		from @arbcnt a

	insert into @arbcnt1(Cont, Cont_parinte, suma_debit, suma_credit, Are_analitice, Tip_cont, Denumire_cont) 
	select Cont, Cont_parinte, suma_debit, suma_credit, Are_analitice, Tip_cont, Denumire_cont from @arbcnt order by cont
	return
end
