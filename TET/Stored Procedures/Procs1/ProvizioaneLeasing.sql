--***
create procedure ProvizioaneLeasing @datas datetime, @centr int, @CodTert varchar(20), @DenTert varchar(30),  @pValuta varchar(3) = null    
as      
      
if @datas is null      
 set @datas=convert(datetime, convert(char(10), getdate(), 104), 104)      
if @centr is null       
 set @centr=0      
---------      
declare @conturi_capital varchar(500),@conturi_dobanda varchar(500),@cont varchar(20)    
set @conturi_capital='|'  set @conturi_dobanda='|'        
    
declare cr cursor for select distinct rtrim(substring(val_alfanumerica,3,13)) as cont from par where     
    parametru in ('LEASBL_R','LEASBL_XR','LEASBL_YR')    
open cr    
fetch next from cr into @cont    
while @@fetch_status=0    
begin    
 set @conturi_capital=@conturi_capital+rtrim(@cont)+'|'    
 fetch next from cr into @cont    
end    
close cr    
deallocate cr    
    
declare cr cursor for select distinct rtrim(substring(val_alfanumerica,3,13)) as cont from par where     
    parametru in ('LEASBL_D','LEASBL_XD','LEASBL_YD')    
open cr    
fetch next from cr into @cont    
while @@fetch_status=0    
begin    
 set @conturi_dobanda=@conturi_dobanda+rtrim(@cont)+'|'    
 fetch next from cr into @cont    
end    
close cr    
deallocate cr    
--set @conturi_capital='|4712.1|4712.2|4811.1|4821.2|'  set @conturi_dobanda='|4717.1|4812|4822|'      
      
select cont,tip into #cont_prov from      
(select cont,'c' as tip from conturi where charindex('|'+rtrim(cont_parinte)+'|',@conturi_capital)<>0      
union all select 'restante.r','c'      
union all select cont,'d' as tip from conturi where charindex('|'+rtrim(cont_parinte)+'|',@conturi_dobanda)<>0      
union all select 'restante.d','d'      
) a      
      
insert into #cont_prov select c.cont,(case when charindex('|'+rtrim(c.cont)+'|',@conturi_capital)<>0 then 'c' else 'd' end) as tip       
 from conturi c where not (charindex('|'+rtrim(c.cont_parinte)+'|',@conturi_capital)<>0 or charindex('|'+rtrim(c.cont_parinte)+'|',@conturi_dobanda)<>0)      
 and charindex('|'+rtrim(c.cont)+'|',@conturi_capital)<>0 or charindex('|'+rtrim(c.cont)+'|',@conturi_dobanda)<>0      
 and (are_analitice=0)      
------    
select f.subunitate,max(f.comanda) as comanda, f.tert, f.factura,min(data_facturii) as data_facturii,min(data_scadentei) as data_scadentei,      
(case when cont_de_tert in (select cp.cont from #cont_prov cp where cp.tip='c') then sum(valoare) else 0 end) as rata,       
(case when cont_de_tert in (select cp.cont from #cont_prov cp where cp.tip='d') then sum(valoare) else 0 end) as dobanda,      
sum(achitat) as achitat, sum(valoare+tva) as total_factura,
case when len(ltrim(rtrim(t.cod_fiscal))) between 1 and 12 then 'J' else 'F' end as tipc, max(cc.valuta ) as valuta    
into #f1      
from fFacturi ('B', null, @DATAS, null, null, null, null, null, 0, null, null) f    
 left join con cc on cc.subunitate='1' and cc.tip='BL' and cc.tert=f.tert and cc.contract=f.comanda    
 , terti t    
where t.tert=f.tert and f.subunitate='1' and (@pValuta is null or cc.valuta=@pValuta) and (isnull(@CodTert, '')='' or f.tert=@CodTert) 
group by f.subunitate,f.tert,f.factura,t.cod_fiscal,f.cont_de_tert--f.valoare,f.achitat,f.tva, ,cc.valuta    
having exists (select 1 from con c where c.subunitate='1' and c.tip='BL' and c.tert=f.tert and c.contract=max(f.comanda))      
create index f1 on #f1 (subunitate,comanda,tert,factura)      
---------    
select f.subunitate,max(f.comanda) as comanda, f.tert,       
(case when upper(right(rtrim(f.factura), 1)) between 'A' and 'Z' then left(f.factura, len(rtrim(f.factura))-(case when upper(substring(reverse(rtrim(f.factura)), 2, 1)) between 'A' and 'Z' then 2 when upper(right(rtrim(f.factura), 1)) between 'A' and 'Z' 
  
    
then 1 else 0 end)) else f.factura end) as factura,       
min(data_facturii) as data_facturii,min(data_scadentei) as data_scadentei,      
round(sum(rata),4) as rata,       
round(sum(dobanda),4) as dobanda,      
round(sum(achitat),4) as achitat, round(sum(total_factura),2) as total_factura,f.tipc , f.valuta    
into #f      
from #f1 f      
group by f.subunitate,f.tert,f.factura,f.tipc,f.valuta    
create index f on #f (subunitate,comanda,tert,factura)      
      
update #f      
set rata=(case when rata>total_factura then total_factura else rata end),      
 dobanda=(case when rata>total_factura then 0 when dobanda>total_factura-rata then total_factura-rata else dobanda end)      
      
update #f       
set rata=(case when rata<0 then 0 else rata end),      
 dobanda=(case when dobanda<0 then 0 else dobanda end)      
      
update #f set achitat=0 where achitat<0      
      
select f.subunitate, f.comanda, f.tert, f.factura, f.rata, f.dobanda,  f.achitat, f.tipc,      
datediff(day,isnull(f.data_scadentei,dateadd(day,10,f.data_facturii)),@datas) as zscadenta, valuta    
INTO #sold_4111      
from #f f     
where round(f.rata+f.dobanda,2)-round(f.achitat,2)>=0.01      
drop table #f      
    
declare @tert varchar(20),@contract varchar(20), @factura varchar(20),@rata float ,@dobanda float ,@achitat float      
declare @fetchstat int, @dif float, @zscadenta int, @tipc char, @incadrare varchar(50) , @valuta varchar(3)    
      
create table #s4111 (tert varchar(13), [contract] varchar(20), factura varchar(20),rata float, dobanda float,       
zscadenta int,tipc char, incadrare varchar (50),valuta varchar(3))      
      
declare s4111 cursor for      
select tert,comanda,factura,rata,dobanda,achitat,zscadenta,tipc,      
(case       
 when zscadenta <= 15 then '1-Sub 15 zile'       
 when zscadenta > 15 and zscadenta <= 30 then '2-Intre 15 si 30 de zile'      
 when zscadenta > 30 and zscadenta <= 60 then '3-Intre 30 si 60 de zile'      
 when zscadenta > 60 and zscadenta <= 90 then '4-Intre 60 si 90 de zile'      
 when zscadenta > 90 then '5-Peste 90 de zile'      
end) as incadrare, valuta    
from #sold_4111 where zscadenta>=0      
open s4111      
fetch next from s4111 into @tert,@contract,@factura,@rata,@dobanda,@achitat, @zscadenta,@tipc, @incadrare, @valuta    
set @fetchstat=@@fetch_status      
while @fetchstat=0      
begin      
      
      
if abs(@achitat)<=abs(@rata) --and @rata<> 0      
insert into #s4111 values (@tert,@contract,@factura,round(@rata-@achitat,4),@dobanda,@zscadenta,@tipc,@incadrare,@valuta)      
else       
begin      
 set @dif=@achitat-@rata      
 if abs(@dif)<=abs(@dobanda)-- and @dobanda <> 0      
 insert into #s4111 values (@tert,@contract,@factura,0,round(@dobanda-@dif,4),@zscadenta,@tipc,@incadrare,@valuta)      
       
end      
      
fetch next from s4111 into @tert,@contract,@factura,@rata,@dobanda,@achitat, @zscadenta,@tipc, @incadrare, @valuta     
set @fetchstat=@@fetch_status      
      
end      
close s4111      
deallocate s4111      
drop table #sold_4111      
    
if @centr=1      
begin      
      
 select round(sum(case when (tipc='F' and zscadenta<=15) then rata else 0 end),2) as R_PF_15,      
 round(sum(case when (tipc='F' and zscadenta between 16 and 30) then rata else 0 end),2) as R_PF_30,       
 round(sum(case when (tipc='F' and zscadenta between 31 and 60) then rata else 0 end),2) as R_PF_60,       
 round(sum(case when (tipc='F' and zscadenta between 61 and 90) then rata else 0 end),2) as R_PF_90,      
 round(sum(case when (tipc='F' and zscadenta >= 91) then rata else 0 end),2) as R_PF_91,      
      
 round(sum(case when (tipc='J' and zscadenta<=15) then rata else 0 end),2) as R_PJ_15,      
 round(sum(case when (tipc='J' and zscadenta between 16 and 30) then rata else 0 end),2) as R_PJ_30,       
 round(sum(case when (tipc='J' and zscadenta between 31 and 60) then rata else 0 end),2) as R_PJ_60,       
 round(sum(case when (tipc='J' and zscadenta between 61 and 90) then rata else 0 end),2) as R_PJ_90,      
 round(sum(case when (tipc='J' and zscadenta >= 91) then rata else 0 end),2) as R_PJ_91,      
      
 round(sum(case when (tipc='F' and zscadenta<=15) then dobanda else 0 end),2) as D_PF_15,      
 round(sum(case when (tipc='F' and zscadenta between 16 and 30) then dobanda else 0 end),2) as D_PF_30,       
 round(sum(case when (tipc='F' and zscadenta between 31 and 60) then dobanda else 0 end),2) as D_PF_60,       
 round(sum(case when (tipc='F' and zscadenta between 61 and 90) then dobanda else 0 end),2) as D_PF_90,      
 round(sum(case when (tipc='F' and zscadenta >= 91) then dobanda else 0 end),2) as D_PF_91,      
      
 round(sum(case when (tipc='J' and zscadenta<=15) then dobanda else 0 end),2) as D_PJ_15,      
 round(sum(case when (tipc='J' and zscadenta between 16 and 30) then dobanda else 0 end),2) as D_PJ_30,       
 round(sum(case when (tipc='J' and zscadenta between 31 and 60) then dobanda else 0 end),2) as D_PJ_60,       
 round(sum(case when (tipc='J' and zscadenta between 61 and 90) then dobanda else 0 end),2) as D_PJ_90,      
 round(sum(case when (tipc='J' and zscadenta >= 91) then dobanda else 0 end),2) as D_PJ_91      
    
  ,valuta    
 into #rezultat      
 from #s4111  group by valuta    
      
 select * from #rezultat      
 drop table #rezultat      
end      
else       
begin      
 select b.denumire, b.grupa, a.*       
 from #s4111 a left outer join terti b on a.tert = b.tert       
 where (isnull(@DenTert,'')='' or b.denumire=@DenTert)      
end      
      
drop table #cont_prov      
drop table #s4111
