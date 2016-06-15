--***
create procedure balanta_contabila @ContJos char(13), @ContSus char(13), @pLuna int, @pAn int ,@limba char(2) = '', @valuta varchar(20)='', @curs float, @cLM char(9), @tipb varchar(20)=null
as   
if not exists (select 1 from par where Tip_parametru='GE' and Parametru='rulajelm' and Val_logica=1) set @cLM=null
CREATE TABLE #balanta(
	Subunitate char(9) NOT NULL,
	Cont char(13) NOT NULL,
	Denumire_cont char(300) NOT NULL,
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
	Nivel int not null
)
/*******************	sectiunea de calcul balanta*/
declare @lCentralizata bit, @lContCor bit, @lInValuta bit, @lIn_val_ref bit, @cValuta char(3), @nCurs float
	select @lCentralizata=0, @lContCor=0, @lInValuta=(case when rtrim(@valuta)<>'' then 0 else 1 end), @lIn_val_ref=0, @cValuta=@valuta, @nCurs=@curs
/*	-- codul original:
if rtrim(@valuta)<>'' 
insert into #balanta exec calcul_balanta @pLuna, @pAn, 0, 0, 1, 0, @valuta, @curs, @cLM
else insert into #balanta exec calcul_balanta @pLuna, @pAn, 0, 0, 0, 0, @valuta, @curs, @cLM
*/

Declare @cSubunitate char(9), @IFN int, @dData_inc_an datetime, @dData_sf_luna datetime, @dData_lunii datetime, @cHostID char(8)
exec luare_date_par 'GE','SUBPRO',0,0,@cSubunitate OUTPUT
exec luare_date_par 'GE', 'IFN', @IFN output, 0, ''
Set @dData_lunii = cast(@pAn as char(4))+'/'+rtrim(cast(@pLuna as char(2))) +'/01'
Set @dData_inc_an = Dateadd(month,-(@pLuna-1),@dData_lunii)
Set @dData_sf_luna = dateadd(day,-1,Dateadd(month,1,@dData_lunii))
Set @cHostID =  isnull((select convert(char(8), abs(convert(int, host_id())))),'')
set @cLM=isnull(@cLM,'')

Declare @utilizator varchar(20), @curSub char(9), @curBD char(13), @nFetch int, @eLmUtiliz int
	-- Filtrare pe locuri de munca pe utilizatori
select @utilizator=dbo.fIaUtilizator('')
declare @LmUtiliz table(valoare varchar(200))
set @eLmUtiliz=0
if isnull((select top 1 val_logica from par where Parametru='rulajelm'),0)=1
begin
	insert into @LmUtiliz(valoare)
	select cod from lmfiltrare l where l.utilizator=@utilizator
	set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)
end

Declare cur_sub cursor for
Select subunitate,nume_baza_de_date from sub where @lCentralizata = 1
Union all
Select @cSubunitate,'' 
Open cur_sub
Fetch next from cur_sub into @curSub, @curBD
Set @nFetch = @@fetch_status
While @nFetch = 0
 Begin
  
  If (@lCentralizata = 0 or (@lCentralizata = 1 and @curSub <> @cSubunitate and @curBD <> '' ))
  Begin
   /* Insert si tot sume (doar 3x2 sume sunt relevante, restul de 5x2 sunt calculate pe baza acestora, mai tarziu)*/
   insert into #balanta (Subunitate, Cont, Denumire_cont, Sold_inc_an_debit, Sold_inc_an_credit, Rul_prec_debit, Rul_prec_credit, Sold_prec_debit, Sold_prec_credit, Total_sume_prec_debit, Total_sume_prec_credit, Rul_curent_debit, Rul_curent_credit, Rul_cum_debit, Rul_cum_credit, Total_sume_debit, Total_sume_credit, Sold_cur_debit, Sold_cur_credit, Cont_corespondent,Nivel)
   select r.subunitate,r.cont, max(c.denumire_cont),
   sum(round(convert(decimal(15,3), round((case when r.Data=@dData_inc_an then r.rulaj_debit else 0 end),2)), 2)) as sold_inc_an_debit, 
   sum(round(convert(decimal(15,3), round((case when r.Data=@dData_inc_an then r.rulaj_credit else 0 end),2)), 2)) as sold_inc_an_credit,
   sum(round(convert(decimal(15,3), round((case when r.Data<>@dData_inc_an and r.Data<>@dData_sf_luna then r.rulaj_debit else 0 end),2)), 2)) as rul_prec_debit,
   sum(round(convert(decimal(15,3), round((case when r.Data<>@dData_inc_an and r.Data<>@dData_sf_luna then r.rulaj_credit else 0 end),2)), 2)) as rul_prec_credit,
   0 as sold_prec_debit, 0 as sold_prec_credit,0 as total_sume_prec_debit,0 as total_sume_prec_credit,
   sum(round(convert(decimal(15,3), round((case when r.Data=@dData_sf_luna then r.rulaj_debit else 0 end),2)), 2)) as rul_curent_debit,
   sum(round(convert(decimal(15,3), round((case when r.Data=@dData_sf_luna then r.rulaj_credit else 0 end),2)), 2)) as rul_curent_credit,
   0 as rul_cum_debit,0 as rul_cum_credit, 0 as total_sume_debit, 0 as total_sume_credit,
   0 as sold_cur_debit,0 as sold_cur_credit, space(13) as cont_corespondent, max(c.Nivel)
   from rulaje r -- aici se mai modifica pentru centralizare din mai multe BD
   inner join conturi c on r.cont = c.cont and r.subunitate=c.subunitate
   left outer join curs on @IFN=1 and @lInValuta=1 and @nCurs=0 and curs.valuta=r.valuta and curs.data=(case when r.data=@dData_inc_an then r.data-1 else r.data end)
   where r.subunitate=@curSub and r.data<=@dData_sf_luna and r.data>=@dData_inc_an and r.loc_de_munca like RTrim(@cLM)+'%' 
	and ((@IFN=0 or @lInValuta=0) and r.valuta='' or @IFN=1 and @lInValuta=1 and r.valuta=@cValuta)
	and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=r.Loc_de_munca)) 
	--and c.Are_analitice=0 -- se iau aici toare rulajele si atunci nu se calculeaza mai jos 
	and (@tipb is null or exists(select 1 from proprietati p where p.Cod_proprietate='TIPBALANTA' and p.Tip='LM' and 
							valoare=@tipb and rtrim(r.Loc_de_munca) like rtrim(p.cod)+'%'))
	and c.cont between RTrim(@ContJos) and RTrim(@ContSus)
   group by r.subunitate, r.cont

  End
  Fetch next from cur_sub into @curSub, @curBD
  Set @nFetch = @@fetch_status
 End

Close cur_sub
Deallocate cur_sub
-- nu mai calculam aici rulajele pe sintetice din analitice (oricum, nu pe like%, ci ar trebui cu arbore)
--insert into #balanta( Subunitate, Cont, Denumire_cont, Sold_inc_an_debit, Sold_inc_an_credit, Rul_prec_debit, Rul_prec_credit, Sold_prec_debit, Sold_prec_credit, Total_sume_prec_debit, Total_sume_prec_credit, Rul_curent_debit, Rul_curent_credit, Rul_cum_debit, Rul_cum_credit, Total_sume_debit, Total_sume_credit, Sold_cur_debit, Sold_cur_credit, Cont_corespondent, nivel)
-- select 
-- b.Subunitate, c.Cont, rtrim(max(c.Denumire_cont)), sum(b.Sold_inc_an_debit), sum(b.Sold_inc_an_credit), 
--	sum(b.Rul_prec_debit), sum(b.Rul_prec_credit), sum(b.Sold_prec_debit), sum(b.Sold_prec_credit), sum(b.Total_sume_prec_debit), 
--	sum(b.Total_sume_prec_credit), sum(b.Rul_curent_debit), sum(b.Rul_curent_credit), sum(b.Rul_cum_debit), sum(b.Rul_cum_credit), 
--	sum(b.Total_sume_debit), sum(b.Total_sume_credit), sum(b.Sold_cur_debit), sum(b.Sold_cur_credit), max(b.Cont_corespondent), max(c.Nivel)
-- from #balanta b inner join conturi c on rtrim(b.cont) like rtrim(c.cont)+'%'
-- where c.are_analitice=1
-- group by b.subunitate, c.cont
 /***************************		Urmeaza calculul celorlalte 5x2 coloane */
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
	
If @lInValuta = 1 and @IFN=0
 Update #balanta set Sold_inc_an_debit=Sold_inc_an_debit/@nCurs, Sold_inc_an_credit=Sold_inc_an_credit/@nCurs, Rul_prec_debit=Rul_prec_debit/@nCurs, Rul_prec_credit=Rul_prec_credit/@nCurs, Sold_prec_debit=Sold_prec_debit/@nCurs, Sold_prec_credit=Sold_prec_credit/@nCurs, Total_sume_prec_debit=Total_sume_prec_debit/@nCurs, Total_sume_prec_credit=Total_sume_prec_credit/@nCurs, Rul_curent_debit=Rul_curent_debit/@nCurs, Rul_curent_credit=Rul_curent_credit/@nCurs, Rul_cum_debit=Rul_cum_debit/@nCurs, Rul_cum_credit=Rul_cum_credit/@nCurs, Total_sume_debit=Total_sume_debit/@nCurs, Total_sume_credit=Total_sume_credit/@nCurs, Sold_cur_debit=Sold_cur_debit/@nCurs, Sold_cur_credit=Sold_cur_credit/@nCurs

If @lContCor = 1
 Begin
  select b.subunitate,isnull(c.cont_strain,'') as cont_strain,max(isnull(c.dens,'')) as denumire_cont,sum(b.sold_inc_an_debit) as sold_inc_an_debit,sum(b.sold_inc_an_credit) as sold_inc_an_credit,
  sum(b.rul_prec_debit) as rul_prec_debit,sum(b.rul_prec_credit) as rul_prec_credit,sum(b.sold_prec_debit) as sold_prec_debit ,
  sum(b.sold_prec_credit) as sold_prec_credit, sum(b.total_sume_prec_debit) as total_sume_prec_debit, sum (b.total_sume_prec_credit) as total_sume_prec_credit,
  sum(b.rul_curent_debit) as rul_curent_debit,sum(b.rul_curent_credit) as rul_curent_credit,sum(b.rul_cum_debit) as rul_cum_debit, 
  sum(b.rul_cum_credit) as rul_cum_credit, sum(b.total_sume_debit) total_sume_debit, sum (b.total_sume_credit) as total_sume_credit, 
  sum(b.sold_cur_debit) as sold_cur_debit, sum(b.sold_cur_credit) as sold_cur_credit, max(b.cont_corespondent) as cont_corespondent, MAX(b.Nivel) as nivel
  into #tmp_bal_contcor
  from contcor c
  full outer join #balanta b on b.cont = c.contcg
  inner join conturi a on c.contCG = a.cont
  where a.are_analitice = 0 and left(c.contcg,1) not in  ('8','9')
  group by b.subunitate,isnull(c.cont_strain,'')

  Delete from #balanta

  Update #tmp_bal_contcor set cont_strain = 'Negasite' where cont_strain = ''

  insert into #balanta select * from #tmp_bal_contcor

  update #balanta set 
  Sold_prec_debit=(case when Total_sume_prec_debit-Total_sume_prec_credit>0 then Total_sume_prec_debit-Total_sume_prec_credit else 0 end), 
  Sold_prec_credit=(case when Total_sume_prec_debit-Total_sume_prec_credit<0 then Total_sume_prec_credit-Total_sume_prec_debit else 0 end),
  Sold_cur_debit=(case when Total_sume_debit-Total_sume_credit>0 then Total_sume_debit-Total_sume_credit else 0 end),
  Sold_cur_credit=(case when Total_sume_debit-Total_sume_credit<0 then Total_sume_credit-Total_sume_debit else 0 end)
 End
 
/*******************	sectiunea de calcul balanta e gata*/
set @limba=isnull(@limba,'')  
select   
c.subunitate,c.cont, rtrim(isnull(pr.valoare,c.denumire_cont)) as denumire_cont, c.tip_cont, c.are_analitice, c.cont_parinte, c.Apare_in_balanta_sintetica, (case when c.Sold_debit=1 then 1 else 0 end) as apare_in_balanta_de_raportare,   
isnull(b.Cont, '') as ContBal, isnull(b.Denumire_cont, '') as DenContBal, isnull(b.Sold_inc_an_debit, 0) as Sold_inc_an_debit, isnull(b.Sold_inc_an_credit, 0) as Sold_inc_an_credit, isnull(b.Rul_prec_debit, 0) as Rul_prec_debit, isnull(b.Rul_prec_credit, 0) as Rul_prec_credit, isnull(b.Sold_prec_debit, 0) as Sold_prec_debit, isnull(b.Sold_prec_credit, 0) as Sold_prec_credit, isnull(b.Total_sume_prec_debit, 0) as Total_sume_prec_debit, isnull(b.Total_sume_prec_credit, 0) as Total_sume_prec_credit, isnull(b.Rul_curent_debit, 0) as Rul_curent_debit, isnull(b.Rul_curent_credit, 0) as Rul_curent_credit, isnull(b.Rul_cum_debit, 0) as Rul_cum_debit, isnull(b.Rul_cum_credit, 0) as Rul_cum_credit, isnull(b.Total_sume_debit, 0) as Total_sume_debit, isnull(b.Total_sume_credit, 0) as Total_sume_credit, isnull(b.Sold_cur_debit, 0) as Sold_cur_debit, isnull(b.Sold_cur_credit, 0) as Sold_cur_credit, isnull(b.Cont_corespondent, '') as Cont_corespondent
, c.nivel

from #balanta b 
left outer join conturi c on c.subunitate=b.subunitate and c.cont=b.cont
left join proprietati pr on pr.tip='cont' and cod_proprietate='DEN_'+@limba and rtrim(pr.cod)=rtrim(c.cont)  
--where c.cont between RTrim(@ContJos) and RTrim(@ContSus)   
order by c.Cont

drop table #balanta
