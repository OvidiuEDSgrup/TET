/**	Functie de calcul a soldului conturilor din planul contabil (conturi de forma @ccont;)
	@nivelPlanContabil=	0	=>	solduri doar pe conturi fara analitice
						1	=>	solduri calculate la toate nivelele
						2	=>	[2]+solduri pe clase si total general solduri
*/

create function soldconturi(@nivelPlanContabil varchar(1), @cCont varchar(13), @cValuta char(3), @dData datetime, @cJurnal char(3), @cLM char(9))
/*
	declare @cCont char(13), @cValuta char(3), @dData datetime, @cJurnal char(3), @cLM char(9)
	select @cCont='531', @cValuta='', @dData='2010-1-1'
--*/

returns @arbcnt1 table (Cont char(13) primary key, Cont_parinte char(13), sold_debit decimal(20,3), sold_credit decimal(20,3), 
					Are_analitice varchar(1), Tip_cont varchar(1), Denumire_cont varchar(100))
as
begin
		
	set @cCont=(case when ISNULL(@cCont,'')='' then '%' else @cCont end)
	--if @cCont is null set @cCont=''
	if @cValuta is null set @cValuta=''
	--if @dData is null set @dData=convert(datetime, convert(char(10), getdate(), 104), 104)
	if @cJurnal is null set @cJurnal=''
	if @cLM is null set @cLM=''

	declare @cSub char(9), @nAnulImpl int, @nLunaImpl int, @dDataImpl datetime, @dDataIncLuna datetime, @dDataIncAn datetime,
	 @dDataSusRulaje datetime, @dDataJosPozincon datetime, @cTipCont char(1), @nAreAnalitice int, @nDiferenta float, @nRulDeb float, @nRulCred float
,@nr int

	set @cSub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')
	set @nAnulImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULIMPL'), '')
	set @nLunaImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAIMPL'), '')
	set @dDataImpl=dateadd(month, @nLunaImpl, dateadd(year, @nAnulImpl-1901, '01/01/1901'))
	if @dDataImpl>@dData set @dData=@dDataImpl

	set @dDataIncLuna=dbo.bom(@dData)
	set @dDataIncAn=dateadd(month, 1-month(@dDataIncLuna), @dDataIncLuna)

	set @dDataSusRulaje=@dData-(case when @dData>@dDataIncAn then 1 else 0 end)
	set @dDataJosPozincon=dbo.bom(@dDataSusRulaje+1)

	set @cTipCont='B'
	set @nAreAnalitice=0
	select @cTipCont=tip_cont, @nAreAnalitice=are_analitice 
	from conturi where subunitate=@cSub and cont=@cCont
	
	declare @arbcnt table (Cont char(13) primary key, Cont_parinte char(13), sold_debit decimal(20,3), sold_credit decimal(20,3), 
					Are_analitice varchar(1), Tip_cont varchar(1), calculat varchar(1), Denumire_cont varchar(100))
	;with x(cont, cont_parinte, sold_debit, sold_credit, Are_analitice, Tip_cont, calculat, Denumire_cont) as 
	(
	select cont,cont_parinte,0,0,c.Are_analitice,c.Tip_cont,0,rtrim(c.Denumire_cont) from conturi c where c.cont like @cCont union all
	select c.cont,c.cont_parinte,0,0,c.Are_analitice,c.Tip_cont,0,rtrim(c.Denumire_cont) from conturi c, x where x.Cont=c.Cont_parinte
	) 
	insert into @arbcnt
	select distinct * from x
	
	update a set a.sold_credit=suma_credit,
			a.sold_debit=suma_debit
	from @arbcnt a,
	(	select	sum(case when Are_analitice=0 and (Tip_cont='A' or Tip_cont='B' and suma_debit-suma_credit>0) then suma_debit-suma_credit else 0 end) as suma_debit,
				sum(case when Are_analitice=0 and (Tip_cont='P' or Tip_cont='B' and suma_debit-suma_credit<0) then -(suma_debit-suma_credit) else 0 end) as suma_credit,
						cont from
		(
		 select sum(round(convert(decimal(15, 3), r.rulaj_debit), 2)) suma_debit,sum(round(convert(decimal(15, 3), r.rulaj_credit), 2)) as suma_credit,r.cont,
			MAX(a.Are_analitice) as Are_analitice,a.Tip_cont
		 from rulaje r, @arbcnt a
		 where 
		 r.subunitate=@cSub and r.cont=a.cont and r.valuta=@cValuta
		 and r.data between @dDataIncAn and @dDataSusRulaje and r.loc_de_munca like RTrim(@cLM)+'%' group by r.Cont, a.Tip_cont
		 union all
		 select sum(
		 round(convert(decimal(15, 3), (case when @cValuta='' then p.suma else p.suma_valuta end)), 2)
		 ) suma_debit,0 suma_credit, p.Cont_debitor cont,MAX(a.Are_analitice) as Are_analitice,a.Tip_cont
		 from pozincon p, @arbcnt a
		 where 
		 p.subunitate=@cSub and p.data between @dDataJosPozincon and @dData-1
		 and p.loc_de_munca like RTrim(@cLM)+'%' and p.cont_debitor=a.cont
		 and (@cValuta='' or p.valuta=@cValuta) and (@cJurnal='' or p.jurnal=@cJurnal) group by p.Cont_debitor,a.Tip_cont
		 union all
		 select 0,sum(
		 round(convert(decimal(15, 3), (case when @cValuta='' then p.suma else p.suma_valuta end)), 2)) suma_credit,p.Cont_creditor
		 ,MAX(a.Are_analitice) as Are_analitice,a.Tip_cont
		 from pozincon p, @arbcnt a
		 where 
		 p.subunitate=@cSub and p.data between @dDataJosPozincon and @dData-1
		 and p.loc_de_munca like RTrim(@cLM)+'%' and p.cont_creditor=a.cont
		 and (@cValuta='' or p.valuta=@cValuta) and (@cJurnal='' or p.jurnal=@cJurnal) group by p.Cont_creditor,a.Tip_cont
		) x group by cont	
	) c
	where a.Cont=c.Cont
	
	if (@nivelPlanContabil=2)
	begin
		insert into @arbcnt(cont, cont_parinte, sold_debit, sold_credit, Are_analitice, Tip_cont, calculat,c.Denumire_cont)
			select LEFT(cont,1),' T',0,0,1,'B',0,'Clasa '+LEFT(cont,1) from @arbcnt group by LEFT(cont,1)
		update @arbcnt set Cont_parinte=LEFT(cont,1) where Cont_parinte =''
		insert into @arbcnt(cont, cont_parinte, sold_debit, sold_credit, Are_analitice, Tip_cont, calculat,c.Denumire_cont)
			select ' T','',0,0,1,'B',0,'Total'
	end

	if (@nivelPlanContabil>0)
	begin
		update @arbcnt set calculat=1 where Are_analitice=0
		while exists(select 1 from @arbcnt where calculat=0)
		begin
			update a set	sold_debit=(case when Tip_cont='A' then x.sold_debit + x.sold_credit else x.sold_debit end),
							sold_credit=(case when Tip_cont='P' then x.sold_debit + x.sold_credit else x.sold_credit end),
					calculat=3
			from	@arbcnt a, 
					(select cont_parinte as cont, sum(x.sold_credit) sold_credit, SUM(x.sold_debit) sold_debit
						from @arbcnt x where calculat=1 group by cont_parinte)x
					where x.cont=a.Cont 
						and a.calculat=0
						and not exists (select 1 from @arbcnt c where a.Cont=c.cont_parinte and c.calculat=0)
			update a set calculat=2 from @arbcnt a where calculat=1 and not exists 
					(select 1 from @arbcnt c where c.Cont=a.cont_parinte and c.calculat=0)
			update @arbcnt set calculat=1 where calculat=3
		end
	end

	insert into @arbcnt1(Cont, Cont_parinte, sold_debit, sold_credit, Are_analitice, Tip_cont, Denumire_cont) 
	select Cont, Cont_parinte, sold_debit, sold_credit, Are_analitice, Tip_cont, Denumire_cont from @arbcnt order by cont
	return
end