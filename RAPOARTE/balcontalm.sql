/*	Script principal pt raportul CG\Contabilitate\Balanta contabila pe locuri de munca
declare @ContJos nvarchar(4000),@ContSus nvarchar(14),@data datetime,@valuta nvarchar(4000),@curs nvarchar(4000),@locm nvarchar(4000), @tipBalanta int, @tipb varchar(20)
select @ContJos=N'4',@ContSus=N'4zzzzzzzzzzzzz',@data='2010-4-8 00:00:00',@valuta=N'',@curs=NULL,@locm='1',@tipBalanta=1, @tipb='3'
--*/
declare @q_ContJos varchar(13),@q_ContSus varchar(13),@q_pLuna int,@q_pAn int,@q_lb_den varchar(2),@q_valuta varchar(20), @q_curs float, @q_tipb varchar(20)
select @q_ContJos=@ContJos, @q_ContSus=@ContSus, @q_pLuna=MONTH(@data), @q_pAn=year(@data), @q_lb_den=null, @q_valuta=@valuta, @q_tipb=@tipb
, @q_curs=isnull((case when @curs=0 then 1 else @curs end),1)



declare @p_ContJos char(13), @p_ContSus char(13), @p_pLuna int, @p_pAn int ,@limba char(2), @p_valuta varchar(20), @p_curs float, @p_cLM char(9),
		@eLmUtiliz int
if not exists (select 1 from par where Tip_parametru='GE' and Parametru='rulajelm' and Val_logica=1) 
	set @p_cLM=''
	else set @p_cLM=@locm

select @p_ContJos=@q_ContJos, @p_ContSus=@q_ContSus, @p_pLuna=@q_pLuna, @p_pAn=@q_pAn, @limba=@q_lb_den, @p_valuta=@q_valuta
, @p_curs=@q_curs
/*
select @pLuna, @pAn, 0, 0, 0, 0, @valuta, @curs, @cLM
if rtrim(@valuta)<>'' exec calcul_balanta @pLuna, @pAn, 0, 0, 1, 0, @valuta, @curs, @cLM
else exec calcul_balanta @pLuna, @pAn, 0, 0, 0, 0, @valuta, @curs, @cLM
*/
select * into #LmUtiliz from fPropUtiliz() where valoare<>'' and cod_proprietate='LOCMUNCA'
set @eLmUtiliz=isnull((select max(1) from #LmUtiliz),0)

select cont,Cont_parinte as prec,c.Apare_in_balanta_sintetica,c.Are_analitice,
		(case when c.Sold_debit=1 or c.Apare_in_balanta_sintetica=1 then 1 else 0 end) as raportare into #conturi from conturi c --where cont between RTrim(@q_ContJos) and RTrim(@q_ContSus)
declare @nr int
set @nr=0
while @nr<>(select COUNT(1) from #conturi)
begin
	insert into #conturi(cont, prec, Apare_in_balanta_sintetica, Are_analitice,raportare)
	select c2.cont,c1.prec,c2.Apare_in_balanta_sintetica,c2.Are_analitice,
			c2.raportare
	from #conturi c1, #conturi c2 where c1.cont=c2.prec and c1.prec<>''
	set @nr=(select COUNT(1) from #conturi)
end

/*************************** calcul #balanta */
declare --@pLuna int, @pAn int, @cLM char(9), @valuta char(3), @curs float
@p_lCentralizata bit, @p_lContCor bit, @p_lInValuta bit, @p_lIn_val_ref bit
select @p_lCentralizata=0, @p_lContCor=0, @p_lInValuta=(case when rtrim(@p_valuta)<>'' then 1 else 0 end), @p_lIn_val_ref=0


/* Parametri generali */
Declare @p_cSubunitate char(9), @p_IFN int, @p_dData_inc_an datetime, @p_dData_sf_luna datetime, @p_dData_lunii datetime, @p_cHostID char(8)
exec luare_date_par 'GE','SUBPRO',0,0,@p_cSubunitate OUTPUT
exec luare_date_par 'GE', 'IFN', @p_IFN output, 0, ''
Set @p_dData_lunii = cast(@p_pAn as char(4))+'/'+rtrim(cast(@p_pLuna as char(2))) +'/01'
Set @p_dData_inc_an = Dateadd(month,-(@p_pLuna-1),@p_dData_lunii)
Set @p_dData_sf_luna = dateadd(day,-1,Dateadd(month,1,@p_dData_lunii))
Set @p_cHostID =  isnull((select convert(char(8), abs(convert(int, host_id())))),'')
set @p_cLM=isnull(@p_cLM,'')

CREATE TABLE #balanta(
	Subunitate char(9) NOT NULL,
	Cont char(13) NOT NULL,
	are_analitice int not null,
	Denumire_cont char(80) NOT NULL,
	Sold_inc_an_debit float NOT NULL,
	Sold_inc_an_credit float NOT NULL,
	Rul_prec_debit float NOT NULL,
	Rul_prec_credit float NOT NULL,
	Sold_prec_debit float NOT NULL,
	Sold_prec_credit float NOT NULL,
	Total_sume_prec_debit float NOT NULL,
	Total_sume_prec_credit float NOT NULL,
	Rul_curent_debit float NOT NULL,
	Rul_curent_credit float NOT NULL,
	Rul_cum_debit float NOT NULL,
	Rul_cum_credit float NOT NULL,
	Total_sume_debit float NOT NULL,
	Total_sume_credit float NOT NULL,
	Sold_cur_debit float NOT NULL,
	Sold_cur_credit float NOT NULL,
	Cont_corespondent char(20) NOT NULL,
	locm char(9)
)

CREATE UNIQUE CLUSTERED INDEX Sub_Cont ON #balanta 
(
	Subunitate ASC,
	Cont ASC,
	locm asc
)
	
-- Se va face cursor pe subunitati pentru centralizata

Declare @p_curSub char(9), @p_curBD char(13), @p_nFetch int

Declare cur_sub cursor for
Select subunitate,nume_baza_de_date from sub where @p_lCentralizata = 1
Union all
Select @p_cSubunitate,'' 
Open cur_sub
Fetch next from cur_sub into @p_curSub, @p_curBD
Set @p_nFetch = @@fetch_status
While @p_nFetch = 0
 Begin
  
  If (@p_lCentralizata = 0 or (@p_lCentralizata = 1 and @p_curSub <> @p_cSubunitate and @p_curBD <> '' ))
  Begin
   /* Insert si tot sume (doar 3x2 sume sunt relevante, restul de 5x2 sunt calculate pe baza acestora, mai tarziu)*/
   insert into #balanta (Subunitate, Cont, are_analitice, Denumire_cont, Sold_inc_an_debit, Sold_inc_an_credit, Rul_prec_debit, Rul_prec_credit, Sold_prec_debit, Sold_prec_credit, Total_sume_prec_debit, Total_sume_prec_credit, Rul_curent_debit, Rul_curent_credit, Rul_cum_debit, Rul_cum_credit, Total_sume_debit, Total_sume_credit, Sold_cur_debit, Sold_cur_credit, Cont_corespondent, locm)
   select r.subunitate,r.cont,c.are_analitice, max(c.denumire_cont),
   sum(round(convert(decimal(15,3), round((case when tip_suma='sold' then r.rulaj_debit else 0 end),2)), 2)) as sold_inc_an_debit, 
   sum(round(convert(decimal(15,3), round((case when tip_suma='sold' then r.rulaj_credit else 0 end),2)), 2)) as sold_inc_an_credit,
   sum(round(convert(decimal(15,3), round((case when tip_suma='rp' then r.rulaj_debit else 0 end),2)), 2)) as rul_prec_debit,
   sum(round(convert(decimal(15,3), round((case when tip_suma='rp' then r.rulaj_credit else 0 end),2)), 2)) as rul_prec_credit,
   0 as sold_prec_debit, 0 as sold_prec_credit,0 as total_sume_prec_debit,0 as total_sume_prec_credit,
   sum(round(convert(decimal(15,3), round((case when tip_suma='rc' then r.rulaj_debit else 0 end),2)), 2)) as rul_curent_debit,
   sum(round(convert(decimal(15,3), round((case when tip_suma='rc' then r.rulaj_credit else 0 end),2)), 2)) as rul_curent_credit,
   0 as rul_cum_debit,0 as rul_cum_credit, 0 as total_sume_debit, 0 as total_sume_credit,
   0 as sold_cur_debit,0 as sold_cur_credit, space(13) as cont_corespondent, r.Loc_de_munca
   from 
	(select (case r.data when @p_dData_inc_an then 'sold' when @p_dData_sf_luna then 'rc' else 'rp' end) as tip_suma,
			r.subunitate,r.cont, round(r.rulaj_debit,2)*isnull(curs.curs,1) rulaj_debit,round(r.rulaj_credit,2)*isnull(curs.curs,1) rulaj_credit,
			r.Loc_de_munca,r.Data,r.Valuta from rulaje r 
			left outer join curs on @p_IFN=1 and @p_lInValuta=1 and @p_curs=0 and curs.valuta=r.valuta and curs.data=(case when r.data=@p_dData_inc_an then r.data-1 else r.data end)
		where	r.subunitate=@p_curSub and r.data<=@p_dData_sf_luna and r.data>=@p_dData_inc_an and r.loc_de_munca like RTrim(@p_cLM)+'%' 
				and ((@p_IFN=0 or @p_lInValuta=0) and r.valuta='' or @p_IFN=1 and @p_lInValuta=1 and r.valuta=@p_valuta)
				and (@eLmUtiliz=0 or exists (select 1 from #LmUtiliz u where u.valoare=r.Loc_de_munca))
				--/*
				and (@q_tipb is null or exists(select 1 from proprietati p where p.Cod_proprietate='TIPBALANTA' and p.Tip='LM' and 
							valoare=@q_tipb and rtrim(r.Loc_de_munca) like rtrim(p.cod)+'%'))	--*/
		union all
	 select 'rc', r.subunitate,r.cont, 0,0,'Total LM',MAX(r.data),r.Valuta from rulaje r 
			left outer join curs on @p_IFN=1 and @p_lInValuta=1 and @p_curs=0 and curs.valuta=r.valuta and curs.data=(case when r.data=@p_dData_inc_an then r.data-1 else r.data end)
		where	r.subunitate=@p_curSub and r.data<=@p_dData_sf_luna and r.data>=@p_dData_inc_an --and r.loc_de_munca like RTrim(@p_cLM)+'%' 
				and ((@p_IFN=0 or @p_lInValuta=0) and r.valuta='' or @p_IFN=1 and @p_lInValuta=1 and r.valuta=@p_valuta)
		group by r.subunitate,r.cont, r.Valuta)
	 r
		-- aici se mai modifica pentru centralizare din mai multe BD
   inner join conturi c on r.cont = c.cont and r.subunitate=c.subunitate
   where r.subunitate=@p_curSub and r.data<=@p_dData_sf_luna and r.data>=@p_dData_inc_an --and r.loc_de_munca like RTrim(@p_cLM)+'%' 
   and ((@p_IFN=0 or @p_lInValuta=0) and r.valuta='' or @p_IFN=1 and @p_lInValuta=1 and r.valuta=@p_valuta)
   and r.cont between RTrim(@q_ContJos)  and RTrim(@q_ContSus) --and c.are_analitice=0
   group by r.subunitate, r.cont, r.Loc_de_munca, c.are_analitice

  End
  Fetch next from cur_sub into @p_curSub, @p_curBD
  Set @p_nFetch = @@fetch_status
 End

Close cur_sub
Deallocate cur_sub
/**			Calculez totaluri pe conturile cu analitice:	*/ -- nu mai facem asa!
/*insert into #balanta( Subunitate, Cont, are_analitice, Denumire_cont, Sold_inc_an_debit, Sold_inc_an_credit, Rul_prec_debit, Rul_prec_credit, Sold_prec_debit, Sold_prec_credit, Total_sume_prec_debit, Total_sume_prec_credit, Rul_curent_debit, Rul_curent_credit, Rul_cum_debit, Rul_cum_credit, Total_sume_debit, Total_sume_credit, Sold_cur_debit, Sold_cur_credit, Cont_corespondent, locm)
 select 
 b.Subunitate, c.Cont, 1 are_analitice, rtrim(max(c.Denumire_cont)), sum(b.Sold_inc_an_debit), sum(b.Sold_inc_an_credit), 
	sum(b.Rul_prec_debit), sum(b.Rul_prec_credit), sum(b.Sold_prec_debit), sum(b.Sold_prec_credit), sum(b.Total_sume_prec_debit), 
	sum(b.Total_sume_prec_credit), sum(b.Rul_curent_debit), sum(b.Rul_curent_credit), sum(b.Rul_cum_debit), sum(b.Rul_cum_credit), 
	sum(b.Total_sume_debit), sum(b.Total_sume_credit), sum(b.Sold_cur_debit), sum(b.Sold_cur_credit), max(b.Cont_corespondent), 'Total LM'
 from #balanta b inner join conturi c on rtrim(b.cont) like rtrim(c.cont)+'%'
 where b.are_analitice=0 and c.are_analitice=1
 group by b.subunitate, c.cont*/

--/*	Calculez totaluri in dreptul conturilor
update b set Sold_inc_an_credit=s.sold_inc_an_credit,Sold_inc_an_debit=s.Sold_inc_an_debit,
			 Rul_prec_credit=s.Rul_prec_credit, Rul_prec_debit=s.Rul_prec_debit,
			 Rul_curent_credit=s.Rul_curent_credit, Rul_curent_debit=s.Rul_curent_debit
from #balanta b,
(select b.Cont, sum(Rul_prec_debit) as Rul_prec_debit, sum(Rul_prec_credit) as Rul_prec_credit,
		sum(rul_curent_debit) rul_curent_debit, SUM(rul_curent_credit) as rul_curent_credit,
		SUM(sold_inc_an_debit) as sold_inc_an_debit,SUM(sold_inc_an_credit) as sold_inc_an_credit
		from #balanta b --where b.are_analitice=1 and b.locm<>'Total LM'
		group by b.Cont) s where s.Cont=b.Cont and b.locm='Total LM'
		--*/

delete b from #balanta b where b.locm<>'Total LM' /**	sterg liniile cu locuri de munca din dreptul conturilor de nivel superior*/
	and  b.are_analitice=1

/*------------------------------------------
select *  from #balanta where cont like '451%'*/


If @p_lInValuta = 1 and @p_IFN=0
 Update #balanta set	Sold_inc_an_debit=Sold_inc_an_debit/@p_curs, Sold_inc_an_credit=Sold_inc_an_credit/@p_curs, 
						Rul_prec_debit=Rul_prec_debit/@p_curs, Rul_prec_credit=Rul_prec_credit/@p_curs, 
						Rul_curent_debit=Rul_curent_debit/@p_curs, Rul_curent_credit=Rul_curent_credit/@p_curs
						/*,Sold_prec_debit=Sold_prec_debit/@p_curs, Sold_prec_credit=Sold_prec_credit/@p_curs, 
						Total_sume_prec_debit=Total_sume_prec_debit/@p_curs, Total_sume_prec_credit=Total_sume_prec_credit/@p_curs, 
						Rul_cum_debit=Rul_cum_debit/@p_curs, Rul_cum_credit=Rul_cum_credit/@p_curs, 
						Total_sume_debit=Total_sume_debit/@p_curs, Total_sume_credit=Total_sume_credit/@p_curs, 
						Sold_cur_debit=Sold_cur_debit/@p_curs, Sold_cur_credit=Sold_cur_credit/@p_curs*/


If @p_lContCor = 1
 Begin
  select b.subunitate,isnull(c.cont_strain,'') as cont_strain,max(isnull(c.dens,'')) as denumire_cont,sum(b.sold_inc_an_debit) as sold_inc_an_debit,sum(b.sold_inc_an_credit) as sold_inc_an_credit,
  sum(b.rul_prec_debit) as rul_prec_debit,sum(b.rul_prec_credit) as rul_prec_credit,sum(b.sold_prec_debit) as sold_prec_debit ,
  sum(b.sold_prec_credit) as sold_prec_credit, sum(b.total_sume_prec_debit) as total_sume_prec_debit, sum (b.total_sume_prec_credit) as total_sume_prec_credit,
  sum(b.rul_curent_debit) as rul_curent_debit,sum(b.rul_curent_credit) as rul_curent_credit,sum(b.rul_cum_debit) as rul_cum_debit, 
  sum(b.rul_cum_credit) as rul_cum_credit, sum(b.total_sume_debit) total_sume_debit, sum (b.total_sume_credit) as total_sume_credit, 
  sum(b.sold_cur_debit) as sold_cur_debit, sum(b.sold_cur_credit) as sold_cur_credit, max(b.cont_corespondent) as cont_corespondent
  into #tmp_bal_contcor
  from contcor c
  full outer join #balanta b on b.cont = c.contcg
  inner join conturi a on c.contCG = a.cont
  where a.are_analitice = 0 and left(c.contcg,1) not in  ('8','9')
  group by b.subunitate,isnull(c.cont_strain,'')

  Delete from #balanta

  Update #tmp_bal_contcor set cont_strain = 'Negasite' where cont_strain = ''

  insert into #balanta(Subunitate, Cont, are_analitice, Denumire_cont, Sold_inc_an_debit, Sold_inc_an_credit, Rul_prec_debit, Rul_prec_credit, Sold_prec_debit, Sold_prec_credit, Total_sume_prec_debit, Total_sume_prec_credit, Rul_curent_debit, Rul_curent_credit, Rul_cum_debit, Rul_cum_credit, Total_sume_debit, Total_sume_credit, Sold_cur_debit, Sold_cur_credit, Cont_corespondent, locm)
  select Subunitate, Cont, are_analitice, Denumire_cont, Sold_inc_an_debit, Sold_inc_an_credit, Rul_prec_debit, Rul_prec_credit, Sold_prec_debit, Sold_prec_credit, Total_sume_prec_debit, Total_sume_prec_credit, Rul_curent_debit, Rul_curent_credit, Rul_cum_debit, Rul_cum_credit, Total_sume_debit, Total_sume_credit, Sold_cur_debit, Sold_cur_credit, Cont_corespondent, locm from #tmp_bal_contcor

  update #balanta set 
  Sold_prec_debit=(case when Total_sume_prec_debit-Total_sume_prec_credit>0 then Total_sume_prec_debit-Total_sume_prec_credit else 0 end), 
  Sold_prec_credit=(case when Total_sume_prec_debit-Total_sume_prec_credit<0 then Total_sume_prec_credit-Total_sume_prec_debit else 0 end),
  Sold_cur_debit=(case when Total_sume_debit-Total_sume_credit>0 then Total_sume_debit-Total_sume_credit else 0 end),
  Sold_cur_credit=(case when Total_sume_debit-Total_sume_credit<0 then Total_sume_credit-Total_sume_debit else 0 end)
 end
 
/***************************		Urmeaza calculul celorlalte 5 coloane */
	update b set Sold_inc_an_debit=(case isnull(c.tip_cont,'B') when 'A' then b.Sold_inc_an_debit-b.Sold_inc_an_credit when 'P' then 0 
				else (case when b.Sold_inc_an_debit>b.Sold_inc_an_credit then Sold_inc_an_debit-b.Sold_inc_an_credit else 0 end)
		 end),
			Sold_inc_an_credit=(case isnull(c.tip_cont,'B') when 'A' then 0 when 'P' then b.Sold_inc_an_credit-b.Sold_inc_an_debit 
				else (case when b.Sold_inc_an_credit>b.Sold_inc_an_debit then Sold_inc_an_credit-b.Sold_inc_an_debit else 0 end)
		 end)
	from #balanta b left join conturi c on b.cont=c.cont
	
	
	update b set 
	Total_sume_prec_debit=b.Sold_inc_an_debit+b.Rul_prec_debit, Total_sume_prec_credit=b.Sold_inc_an_credit+b.Rul_prec_credit,
	Rul_cum_debit=Rul_prec_debit+Rul_curent_debit, Rul_cum_credit=Rul_prec_credit+Rul_curent_credit,
	Total_sume_debit=Rul_prec_debit+Rul_curent_debit+Sold_inc_an_debit,Total_sume_credit=Rul_prec_credit+Rul_curent_credit+Sold_inc_an_credit
	from #balanta b
	
	update b set 
			b.Sold_prec_debit=
		(case isnull(c.tip_cont,'B') when 'A' then b.total_sume_prec_debit-b.total_sume_prec_credit when 'P' then 0 
				else (case when b.total_sume_prec_debit>b.total_sume_prec_credit then total_sume_prec_debit-b.total_sume_prec_credit else 0 end)
		 end),
			 b.Sold_prec_credit=(case isnull(c.tip_cont,'B') when 'A' then 0 when 'P' then b.Total_sume_prec_credit-b.Total_sume_prec_debit 
				else (case when b.Total_sume_prec_credit>b.Total_sume_prec_debit then Total_sume_prec_credit-b.Total_sume_prec_debit else 0 end)
		 end),
			b.Sold_cur_debit=(case isnull(c.tip_cont,'B') when 'A' then b.Total_sume_debit-b.Total_sume_credit when 'P' then 0 
				else (case when b.Total_sume_debit>b.Total_sume_credit then Total_sume_debit-b.Total_sume_credit else 0 end)
		 end),
			 b.Sold_cur_credit=(case isnull(c.tip_cont,'B') when 'A' then 0 when 'P' then b.Total_sume_credit-b.Total_sume_debit
				else (case when b.Total_sume_credit>b.Total_sume_debit then Total_sume_credit-b.Total_sume_debit else 0 end)
		 end)
	from #balanta b left join conturi c on b.cont=c.cont
/***************************		Calcularea celor doua totaluri	*/
	insert into #balanta(Subunitate, Cont, are_analitice, Denumire_cont, Sold_inc_an_debit, Sold_inc_an_credit, Rul_prec_debit, Rul_prec_credit, 
						Sold_prec_debit, Sold_prec_credit, Total_sume_prec_debit, Total_sume_prec_credit, Rul_curent_debit, Rul_curent_credit, 
						Rul_cum_debit, Rul_cum_credit, Total_sume_debit, Total_sume_credit, Sold_cur_debit, Sold_cur_credit, Cont_corespondent, 
						locm)
	select '1' Subunitate, 'Total1' Cont, 1 are_analitice, 'Total *' Denumire_cont, 0, 0, 
							0, 0, 0, 0, 
							0, 0, 0, 0, 
							0, 0, 0, 0,
							0, 0, '' cont_corespondent,
							'Total LM' locm union all
	select '1' Subunitate, 'Total2' Cont, 1 are_analitice, 'Total' Denumire_cont, 0, 0, 
							0, 0, 0, 0, 
							0, 0, 0, 0, 
							0, 0, 0, 0,
							0, 0, '' cont_corespondent,
							'Total LM' locm 
	update b set Sold_inc_an_debit=isnull(c.Sold_inc_an_debit,0),Sold_inc_an_credit=isnull(c.Sold_inc_an_credit,0), 
					Rul_prec_debit=isnull(c.Rul_prec_debit,0),Rul_prec_credit=isnull(c.Rul_prec_credit,0),
					Sold_prec_debit=isnull(c.Sold_prec_debit,0), Sold_prec_credit=isnull(c.Sold_prec_credit,0),
					Total_sume_prec_debit=isnull(c.Total_sume_prec_debit,0), Total_sume_prec_credit=isnull(c.Total_sume_prec_credit,0),
					Rul_curent_debit=isnull(c.Rul_curent_debit,0),Rul_curent_credit=isnull(c.Rul_curent_credit,0),
					Rul_cum_debit=isnull(c.Rul_cum_debit,0),Rul_cum_credit=isnull(c.Rul_cum_credit,0), 
					Total_sume_debit=isnull(c.Total_sume_debit,0), Total_sume_credit=isnull(c.Total_sume_credit,0),
					Sold_cur_debit=isnull(c.Sold_cur_debit,0), Sold_cur_credit=isnull(c.Sold_cur_credit,0)
	from #balanta b,
	(select count(1) as nr, sum(Sold_inc_an_debit) Sold_inc_an_debit, sum(Sold_inc_an_credit)Sold_inc_an_credit, 
							sum(Rul_prec_debit) Rul_prec_debit, sum(Rul_prec_credit) Rul_prec_credit, SUM(Sold_prec_debit) Sold_prec_debit,
							sum(Sold_prec_credit) Sold_prec_credit,
							sum(Total_sume_prec_debit) Total_sume_prec_debit, sum(Total_sume_prec_credit) Total_sume_prec_credit, 
							sum(Rul_curent_debit) Rul_curent_debit, sum(Rul_curent_credit) Rul_curent_credit, 
							sum(Rul_cum_debit) Rul_cum_debit, sum(Rul_cum_credit) Rul_cum_credit, 
							sum(Total_sume_debit) Total_sume_debit, sum(Total_sume_credit) Total_sume_credit,
							sum(Sold_cur_debit) Sold_cur_debit, sum(Sold_cur_credit) Sold_cur_credit from #balanta
							where are_analitice=0 and locm='total lm'
							--and cont between RTrim(@q_ContJos) and RTrim(@q_ContSus)
							) c
	where b.Cont='Total1' and c.nr is not null

	update b set Sold_inc_an_debit=isnull(c.Sold_inc_an_debit,0),Sold_inc_an_credit=isnull(c.Sold_inc_an_credit,0), 
					Rul_prec_debit=isnull(c.Rul_prec_debit,0),Rul_prec_credit=isnull(c.Rul_prec_credit,0),
					Sold_prec_debit=isnull(c.Sold_prec_debit,0), Sold_prec_credit=isnull(c.Sold_prec_credit,0),
					Total_sume_prec_debit=isnull(c.Total_sume_prec_debit,0), Total_sume_prec_credit=isnull(c.Total_sume_prec_credit,0),
					Rul_curent_debit=isnull(c.Rul_curent_debit,0),Rul_curent_credit=isnull(c.Rul_curent_credit,0),
					Rul_cum_debit=isnull(c.Rul_cum_debit,0),Rul_cum_credit=isnull(c.Rul_cum_credit,0), 
					Total_sume_debit=isnull(c.Total_sume_debit,0), Total_sume_credit=isnull(c.Total_sume_credit,0),
					Sold_cur_debit=isnull(c.Sold_cur_debit,0), Sold_cur_credit=isnull(c.Sold_cur_credit,0)
		from #balanta b,
	(select count(1) as nr, sum(Sold_inc_an_debit) Sold_inc_an_debit, sum(Sold_inc_an_credit)Sold_inc_an_credit, 
							sum(Rul_prec_debit) Rul_prec_debit, sum(Rul_prec_credit) Rul_prec_credit, SUM(Sold_prec_debit) Sold_prec_debit,
							sum(Sold_prec_credit) Sold_prec_credit,
							sum(Total_sume_prec_debit) Total_sume_prec_debit, sum(Total_sume_prec_credit) Total_sume_prec_credit, 
							sum(Rul_curent_debit) Rul_curent_debit, sum(Rul_curent_credit) Rul_curent_credit, 
							sum(Rul_cum_debit) Rul_cum_debit, sum(Rul_cum_credit) Rul_cum_credit, 
							sum(Total_sume_debit) Total_sume_debit, sum(Total_sume_credit) Total_sume_credit,
							sum(Sold_cur_debit) Sold_cur_debit, sum(Sold_cur_credit) Sold_cur_credit from #balanta b
							where b.cont between RTrim(@q_ContJos)  and RTrim(@q_ContSus) and
								exists (select 1 from #conturi c where c.cont=b.Cont and c.prec='') 
								and b.locm='Total LM' and b.Cont<>'Total1') c
	where b.Cont='Total2' and c.nr is not null
	
/***************************	Se elimina randurile care nu corespund tipului raportului	*/
		delete b from #balanta b where --b.locm<>'Total LM' --and b.locm is not null 
			exists (select 1 from #conturi c where c.cont=b.Cont and 
												(@tipBalanta=2 and c.Apare_in_balanta_sintetica=0
													or @tipBalanta=3 and c.raportare=0))

		delete c from #conturi c where (@tipBalanta=2 and c.Apare_in_balanta_sintetica=0
													or @tipBalanta=3 and c.raportare=0)

/*********************	Select-ul final, cu traduceri daca sunt */

set @limba=isnull(@limba,'')

select
isnull(c.cont,b.cont) cont, rtrim(isnull(pr.valoare,isnull(c.denumire_cont,b.Denumire_cont))) as denumire_cont,
c.tip_cont, c.are_analitice, 
(case when exists (select 1 from #conturi cc where cc.cont=c.Cont_parinte) then c.cont_parinte else '' end) as cont_parinte
, c.Apare_in_balanta_sintetica, (case when c.Sold_debit=1 then 1 else 0 end) as apare_in_balanta_de_raportare,   
isnull(b.Cont, '') as ContBal, isnull(b.Denumire_cont, '') as DenContBal, isnull(b.Sold_inc_an_debit, 0) as Sold_inc_an_debit, isnull(b.Sold_inc_an_credit, 0) as Sold_inc_an_credit, 
isnull(b.Rul_prec_debit, 0) as Rul_prec_debit, isnull(b.Rul_prec_credit, 0) as Rul_prec_credit, isnull(b.Sold_prec_debit, 0) as Sold_prec_debit, isnull(b.Sold_prec_credit, 0) as Sold_prec_credit, isnull(b.Total_sume_prec_debit, 0) as Total_sume_prec_debit, isnull(b.Total_sume_prec_credit, 0) as Total_sume_prec_credit, 
isnull(b.Rul_curent_debit, 0) as Rul_curent_debit, isnull(b.Rul_curent_credit, 0) as Rul_curent_credit, isnull(b.Rul_cum_debit, 0) as Rul_cum_debit, isnull(b.Rul_cum_credit, 0) as Rul_cum_credit, isnull(b.Total_sume_debit, 0) as Total_sume_debit, isnull(b.Total_sume_credit, 0) as Total_sume_credit, isnull(b.Sold_cur_debit, 0) as Sold_cur_debit, isnull(b.Sold_cur_credit, 0) as Sold_cur_credit, isnull(b.Cont_corespondent, '') as Cont_corespondent 
, locm, lm.Denumire as nume_lm --,b.Cont as ordine
--into #brut
from #balanta b
left outer join conturi c on c.subunitate=b.subunitate and c.cont=b.cont
left join lm on lm.Cod=b.locm
left join proprietati pr on pr.tip='cont' and cod_proprietate='DEN_'+@limba and rtrim(pr.cod)=rtrim(c.cont) 
where --c.cont between RTrim(@q_ContJos) and RTrim(@q_ContSus) --and (b.locm is null or b.locm='')	and 
	(isnull(b.Sold_inc_an_debit, 0) <>0 or isnull(b.Sold_inc_an_credit, 0) <>0 or 
	isnull(b.Rul_prec_debit, 0)<>0 or isnull(b.Rul_prec_credit, 0) <>0 or 
	isnull(b.Sold_prec_debit, 0)<>0 or isnull(b.Sold_prec_credit, 0)<>0 or
	isnull(b.Total_sume_prec_debit, 0)<>0 or isnull(b.Total_sume_prec_credit, 0)<>0 or
	isnull(b.Rul_curent_debit, 0)<>0 or isnull(b.Rul_curent_credit, 0)<>0 or
	isnull(b.Rul_cum_debit, 0)<>0 or isnull(b.Rul_cum_credit, 0)<>0 or
	isnull(b.Total_sume_debit, 0)<>0 or isnull(b.Total_sume_credit, 0)<>0 or
	isnull(b.Sold_cur_debit, 0)<>0 or isnull(b.Sold_cur_credit, 0)<>0)
	or left(b.Cont,5)='Total'
--and b.locm=''
order by c.cont, locm
/*
select * from conturi c where exists (select 1 from #brut b where rtrim(b.Cont) like rtrim(c.cont)+'%')
	and not exists (select 1 from #brut b where b.Cont=c.cont)
*/	
--select * from #brut

--drop table #brut
drop table #balanta
drop table #conturi
drop table #LmUtiliz