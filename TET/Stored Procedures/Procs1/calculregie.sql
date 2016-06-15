--***
create procedure [dbo].[calculregie] @dDataJos datetime,@dDataSus datetime, @lm varchar(9)=null  
as
begin
declare @nDecReg int,@nLm int,  @subunitate char(9)
set @nDecReg=isnull((select val_numerica from par where tip_parametru='PC' and parametru='DECREG'),0)
set @nLm=isnull((select max(lungime) from strlm where costuri=1),0) 
set @subunitate = (select val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO') 

if @nDecReg=1 or @nDecReg=2 or @nDecReg=3
begin
if (select rezolvat from costuri where lm='' and comanda='')=1
	begin 
		if @nDecReg=1
			update costuri set cantitate=
			(select isnull(sum(t1.cantitate*(case when nomencl.greutate_specifica=0 then 1 else nomencl.greutate_specifica end)),0) 
			from costtmp t1,nomencl,comenzi,pozcom
			where comenzi.subunitate = @subunitate and t1.comanda_inf=comenzi.comanda and pozcom.comanda=comenzi.comanda and pozcom.cod_produs=nomencl.cod
			and t1.lm_sup='' and t1.comanda_sup='' and t1.art_sup in ('P','R'))
			where lm='' and comanda=''
		else if @nDecReg=2
		begin
			update costuri set cantitate=
			(select isnull(sum(suma),0) 
			from pozincon p1
			where p1.cont_creditor like '7%' and p1.cont_debitor not like '121%' and data between @dDataJos and @dDataSus 
				and exists (select * from costtmp t2 where t2.art_sup='G' and left(p1.loc_de_munca,@nLm)=t2.lm_sup and p1.comanda=t2.comanda_sup )
				and (@lm is null or p1.loc_de_munca like @lm+'%')
				)
			where lm='' and comanda=''
			
			update costuri set cantitate=cantitate-
			(select isnull(sum(suma),0) 
			from pozincon p1
			where p1.cont_debitor like '711%' and p1.cont_creditor not like '121%' and data between @dDataJos and @dDataSus 
				and exists (select * from costtmp t2 where t2.art_sup='G' and left(p1.loc_de_munca,@nLM)=t2.lm_sup and p1.comanda=t2.comanda_sup )
				and (@lm is null or p1.loc_de_munca like @lm+'%')
				)
			where lm='' and comanda='' and lm not in (select distinct lm_sup from costtmp 
			where parcurs=0 and art_sup not in ('L','G') and art_sup in (select articol_de_calculatie from artcalc where baza_pt_regia_generala=1))
		end
		else if @nDecReg=3 -- Pentru REMARUL - dupa zile imobilizare comanda
		begin
			
			--stergem pe cele de rank>1 a.i. o locomotiva primeste o singura data regie generala
			select 
			lm_sup,comanda_sup,dense_rank() over (partition by comanda_sup order by lm_sup,comanda_sup) as ranc
			into #comreg
			from costtmp where art_sup='G'

			--stergem pe cele de rank>1 a.i. o locomotiva primeste o singura data regie generala
			delete costtmp 
			from costtmp ct,#comreg cr where ct.art_sup='G' and 
			ct.lm_sup=cr.lm_sup and ct.comanda_sup=cr.comanda_sup and cr.ranc>1

			--stergem regie generala pentru comenzile a caror data_lansarii este mai mare decat @dDataSus
			
			delete costtmp 
			from costtmp ct,comenzi c where ct.art_sup='G' and 
			ct.comanda_sup=c.comanda and 
			((c.data_inchiderii>'01-01-1980' and c.data_inchiderii<@dDataJos) 
				or c.data_lansarii>@dDataSus)
			drop table #comreg

			update costtmp set cantitate=
			day((case when year(@dDataSus)=year(c.data_inchiderii) and month(@dDataSus)=month(c.data_inchiderii) and @dDataSus>c.data_inchiderii then c.data_inchiderii else @dDataSus end))
			-day((case when year(@dDataJos)=year(c.data_lansarii) and month(@dDataJos)=month(c.data_lansarii) and @dDataJos<c.data_lansarii then c.data_lansarii else @dDataJos end))+1
			from costtmp
			inner join comenzi c on costtmp.comanda_sup=c.comanda 
			where costtmp.art_sup='G'		

			update costuri set cantitate=
			(select sum(cantitate) from costtmp where art_sup='G')
			where lm='' and comanda=''

			
		end
		update costuri set pret=costuri/cantitate
		where costuri*cantitate<>0 and rezolvat=1 and lm='' and comanda=''

		update costtmp set valoare=costuri.pret 
		from costuri 
		where costtmp.lm_inf=costuri.lm and costtmp.art_sup='G' and costtmp.comanda_inf=costuri.comanda and costuri.pret<>0
		if @nDecReg=1
			update costtmp set cantitate=(select isnull(sum(tmp1.cantitate*(case when nomencl.greutate_specifica=0 then 1 else nomencl.greutate_specifica end)),0) 
			from costtmp tmp1,nomencl,comenzi,pozcom
			where comenzi.subunitate = @subunitate and tmp1.comanda_inf=comenzi.comanda and pozcom.comanda=comenzi.comanda and pozcom.cod_produs=nomencl.cod 
				and tmp1.lm_sup='' and tmp1.comanda_sup='' and tmp1.lm_inf=costtmp.lm_sup and tmp1.comanda_inf=costtmp.comanda_sup)
			where art_sup='G' and parcurs=0 and valoare<>0 and costtmp.comanda_inf='' and costtmp.lm_inf=''
		else if @nDecReg=2
		begin
			update costtmp set
			cantitate=(select isnull(sum(suma),0) from pozincon p1 where p1.cont_creditor like '7%' and p1.cont_debitor not like '121%' and data between @dDataJos and @dDataSus 
				and left(p1.loc_de_munca,@nLm)=costtmp.lm_sup and p1.comanda=costtmp.comanda_sup
				and (@lm is null or p1.loc_de_munca like @lm+'%')
				)
			where art_sup='G' and parcurs=0 and costtmp.comanda_inf='' and costtmp.lm_inf=''
			
			update costtmp set cantitate=cantitate-(select isnull(sum(suma),0) from pozincon p1 where p1.cont_debitor like '7%' and p1.cont_creditor not like '121%' and data between @dDataJos and @dDataSus 
				and left(p1.loc_de_munca,@nLm)=costtmp.lm_sup and p1.comanda=costtmp.comanda_sup
				and (@lm is null or p1.loc_de_munca like @lm+'%')
				)
			where art_sup='G' and parcurs=0 and valoare<>0 and costtmp.comanda_inf='' and costtmp.lm_inf=''
		end
		else if @nDecReg=3
		begin
			print 's-a facut la primul if'
		end
		update costuri set rezolvat=3 where lm='' and comanda=''
		delete from costtmp where art_sup in ('G','D') and cantitate=0
		end
end
else
begin
	/*Daca se poate se rezolva, altfel mai incolo*/
	if (select rezolvat from costuri where lm='' and comanda='')=1 
		and not exists(select * from costtmp t1 where t1.art_sup<>'G' and exists (select lm_inf,comanda_inf from costtmp t2 where t1.parcurs=0 and t2.art_sup in ('P','N','R')
		and t1.lm_sup=t2.lm_inf and t1.comanda_sup=t2.comanda_inf and (t1.art_inf in (select articol_de_calculatie from artcalc where baza_pt_regia_generala=1) 
			or t1.art_sup in (select articol_de_calculatie from artcalc where baza_pt_regia_generala=1))))
	begin 
		update costuri set cantitate=(select isnull(sum(cantitate*valoare),0) from costtmp t1
				where exists (select t1.lm_sup,t1.comanda_sup,t1.art_sup,t1.cantitate from costtmp t2 where t2.art_sup='G' and t1.lm_sup=t2.lm_sup and t1.comanda_sup=t2.comanda_sup 
						and (t1.art_inf in (select articol_de_calculatie from artcalc where baza_pt_regia_generala=1)
					or t1.art_sup in (select articol_de_calculatie from artcalc where baza_pt_regia_generala=1))))
			where lm='' and comanda='' and lm not in (select distinct lm_sup from costtmp 
		where parcurs=0 and art_sup not in ('L','G') and art_sup in (select articol_de_calculatie from artcalc where baza_pt_regia_generala=1))

		update costuri set pret=costuri/cantitate
			where costuri*cantitate<>0 and rezolvat=1 and lm='' and comanda=''
		update costtmp set valoare=costuri.pret from costuri 
			where costtmp.lm_inf=costuri.lm and costtmp.art_sup='G' and costtmp.comanda_inf=costuri.comanda and costuri.pret<>0
		update costtmp set cantitate=(select isnull(sum(cantitate*valoare),0) from costtmp tmp1 
			where tmp1.lm_sup=costtmp.lm_sup and tmp1.comanda_sup=costtmp.comanda_sup and tmp1.parcurs>0 and (tmp1.art_inf in 
			(select articol_de_calculatie from artcalc where baza_pt_regia_generala=1)
			or tmp1.art_sup in (select articol_de_calculatie from artcalc where baza_pt_regia_generala=1)))
			where art_sup='G' and parcurs=0 and valoare<>0 and costtmp.comanda_inf='' and costtmp.lm_inf=''
		update costtmp set cantitate=(select isnull(sum(cantitate*valoare),0) from costtmp tmp1 where tmp1.lm_sup=costtmp.lm_sup and tmp1.comanda_sup=costtmp.comanda_sup and tmp1.parcurs>0
				and (tmp1.art_inf in (select articol_de_calculatie from artcalc where baza_pt_regia_generala=1)	or tmp1.art_sup in (select articol_de_calculatie from artcalc where baza_pt_regia_generala=1)))
			where art_sup='D' and parcurs=0
		update costuri set rezolvat=3
			where lm='' and comanda=''
		delete from costtmp where art_sup in ('G','D') and cantitate=0
	end
end
end
