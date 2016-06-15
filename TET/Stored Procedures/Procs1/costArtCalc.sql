--***
/*procedura defalca costurile pe loc de munca, comanda si articol de calculatie (cu spargere pana la ultimul nivel pentru articole de calculatie complexe)*/
create procedure costArtCalc
@LM char(13), @comanda char(20), @dataj datetime, @datas datetime,@tip_comanda char(1)
as
begin  
declare @subunitate char(9)
exec luare_date_par 'GE','SUBPRO',0,0,@subunitate output
truncate table tmpartc
insert into tmpartc (Numar_curent,Articol_de_calculatie,Ordinea_in_raport)
select distinct 0,cost.articol_de_calculatie,isnull(artcalc.ordinea_in_raport,98) from cost left outer join artcalc on cost.articol_de_calculatie=artcalc.articol_de_calculatie left outer join comenzi on comenzi.comanda=cost.comanda where  
cost.subunitate='1' and cost.data_lunii between @dataj and @datas and comenzi.subunitate = @subunitate 
and cost.loc_de_munca like  rtrim(@LM)+'%' 
and cost.comanda like (case when rtrim(@comanda)='' then '%' else rtrim(@comanda) end) 
and (rtrim(@tip_comanda)<>'' and comenzi.tip_comanda in (rtrim(@tip_comanda)) or rtrim(@tip_comanda)='')
and cost.tip_inregistrare in ('RD')

if exists (select * from sysobjects where name='#tempcost') drop table #tempcost
if exists (select * from sysobjects where name='tmp_costuri_artcalc') drop table tmp_costuri_artcalc

select subunitate,loc_de_munca,comanda,tip_comanda,cost.articol_de_calculatie,tip_inregistrare,(case 
when cost.articol_de_calculatie='N' 
then (select valoare from cost c where c.articol_de_calculatie='N' and c.comanda=cost.comanda and c.loc_de_munca=cost.loc_de_munca
and c.tip_inregistrare in ('RD') and c.data_lunii=@datas ) 
else sum(valoare) end) as valoare
into #tempcost
from cost,tmpartc 
where cost.articol_de_calculatie=tmpartc.articol_de_calculatie and cost.subunitate=@subunitate 
and cost.data_lunii between @dataj and @datas 
and cost.loc_de_munca like  rtrim(@LM)+'%' 
and cost.comanda like (case when rtrim(@comanda)='' then '%' else rtrim(@comanda) end) 
and (rtrim(@tip_comanda)<>'' and tip_comanda in (rtrim(@tip_comanda)) or rtrim(@tip_comanda)='')
and cost.tip_inregistrare in ('RD')
group by subunitate,loc_de_munca,comanda,tip_comanda,cost.articol_de_calculatie,tip_inregistrare  
union
select subunitate,loc_de_munca,comanda,tip_comanda,compartg.articol_grup,tip_inregistrare,sum(valoare) as valoare
from cost,compartg where 0=1 and cost.articol_de_calculatie=compartg.articol_componenta and 
cost.subunitate=@subunitate and cost.data_lunii between @dataj and @datas and 
cost.loc_de_munca like  rtrim(@LM)+'%' 
and cost.comanda like (case when rtrim(@comanda)='' then '%' else rtrim(@comanda) end) 
and (rtrim(@tip_comanda)<>'' and tip_comanda in (rtrim(@tip_comanda)) or rtrim(@tip_comanda)='')
AND cost.tip_inregistrare in ('RD') group by subunitate,loc_de_munca,comanda,tip_comanda,compartg.articol_grup,tip_inregistrare 
union
select subunitate,loc_de_munca,comanda,tip_comanda,'*',tip_inregistrare,sum(valoare)-isnull((select sum(valoare) from cost c where c.articol_de_calculatie='N' and c.comanda=cost.comanda and c.loc_de_munca=cost.loc_de_munca
and c.tip_inregistrare in ('RD') and c.data_lunii<>@datas and c.data_lunii between @dataj and @datas),0) as valoare
from cost where 
cost.subunitate=@subunitate and cost.data_lunii between @dataj and @datas and 
cost.loc_de_munca like  rtrim(@LM)+'%' 
and cost.comanda like (case when rtrim(@comanda)='' then '%' else rtrim(@comanda) end) 
and (rtrim(@tip_comanda)<>'' and tip_comanda in (rtrim(@tip_comanda)) or rtrim(@tip_comanda)='')
and cost.tip_inregistrare in ('RD')
and cost.articol_de_calculatie in (select articol_de_calculatie from tmpartc)
group by subunitate,loc_de_munca,comanda,tip_comanda,tip_inregistrare

--select * from #tempcost

select @datas as data,tc.loc_de_munca,tc.comanda,tc.tip_comanda,tc.articol_de_calculatie,tc.articol_de_calculatie as articol_de_calculatie_fiu,space(13) cont_fiu,tc.valoare 
into tmp_costuri_artcalc
from #tempcost tc
--left outer join conturi a on a.articol_de_calculatie=tc.articol_de_calculatie
where tc.articol_de_calculatie<>'*' and not exists 
(select DISTINCT lm_sup,comanda_sup,art_sup--,* 
from costsql where data between @dataj and @datas
and art_inf='T' and costsql.lm_sup=tc.loc_de_munca and 
costsql.comanda_sup=tc.comanda and costsql.art_sup=tc.articol_de_calculatie)

declare @tLM as char(9),@tCom as char(20),@tTipC char(2),@tArtC char(5)
declare @nFetch int
declare @artcalc_T cursor
set @artcalc_T = cursor for 
select distinct tc.loc_de_munca,tc.comanda,tc.tip_comanda,tc.articol_de_calculatie
from #tempcost tc
where tc.articol_de_calculatie<>'*' and exists 
(select DISTINCT lm_sup,comanda_sup,art_sup--,* 
from costsql where data between @dataj and @datas
and art_inf='T' and costsql.lm_sup=tc.loc_de_munca and 
costsql.comanda_sup=tc.comanda and costsql.art_sup=tc.articol_de_calculatie)

open @artcalc_T
fetch next from @artcalc_T into @tLM,@tCom,@tTipC,@tArtC 
set @nFetch=@@fetch_status
while @nFetch=0
	begin
--	select @tLM,@tCom,@tArtC 

	truncate table tmpartc
	insert into tmpartc (Numar_curent,Articol_de_calculatie,Ordinea_in_raport)
	select 0,@tArtC,isnull(ordinea_in_raport,98) 
		from artcalc where artcalc.articol_de_calculatie=@tArtC 
	execute insertfisa @tLM,@tCom,0,20,1,'*','', '','', 1, @subunitate,@dataj, @datas,0
	insert into tmp_costuri_artcalc (data,Loc_de_munca,comanda,tip_comanda,articol_de_calculatie,articol_de_calculatie_fiu,cont_fiu,valoare) 
	select @datas,@tLM,@tCom,@tTipC,@tArtC,c.articol_de_calculatie,c.cont,valoare 
		from fisacmdtmp 
		left outer join conturi c on c.cont=rtrim(ltrim(replace(descriere,'Cont:','')))
		where descriere like '%Cont:%'

	fetch next from @artcalc_T into @tLM,@tCom,@tTipC,@tArtC 
	set @nFetch=@@fetch_status
	end

end




