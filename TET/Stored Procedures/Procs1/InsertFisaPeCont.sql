--***
create procedure InsertFisaPeCont @dDataJos datetime,@dDataSus datetime, @lm varchar(9)=null   
as  
begin  
declare @pas int,@pasmax int  
  
delete from FisaPeCont where data between @dDataJos and @dDataSus 
	and (@lm is null or lm like @lm+'%') 
  
insert into FisaPeCont (Data,Tip,LM,Comanda,Cont,Suma)
select @dDataSus,'D',lm_sup,comanda_sup,comanda_inf,sum(cantitate*valoare) 
from costtmp 
where parcurs=1 and lm_inf=''  
group by lm_sup,comanda_sup,comanda_inf  
  
set @pas=2  
set @pasmax=(select max(parcurs) from costtmp)  
while @pas<@pasmax  
begin  
 select lm_sup,comanda_sup,lm_inf,comanda_inf,sum(costtmp.cantitate*costtmp.valoare)/max(costuri.costuri) as pondere  
 into #pond  
 from costtmp   
 inner join costuri on lm_inf=lm and comanda_inf=comanda  
 where parcurs=@pas  
 and not (lm_sup='' and comanda_sup='' and art_sup in ('P','R','S','A','N'))  
 group by lm_sup,comanda_sup,lm_inf,comanda_inf  
  
 select p.lm_sup,p.comanda_sup,p.lm_inf,p.comanda_inf,p.pondere, f.cont,f.suma*p.pondere as 'SumaCont'  
 into #p1  
 from #pond p  
 inner join FisaPeCont f on p.lm_inf=f.lm and p.comanda_inf=f.comanda and f.data=@dDataSus and (@lm is null or f.lm like @lm+'%')
   
 insert into FisaPeCont (Data,Tip,LM,Comanda,Cont,Suma) 
 select distinct @dDataSus,'D',lm_sup,comanda_sup,cont,0  
 from #p1 p1  
 where not exists(select data from FisaPeCont f1 where f1.data=@dDataSus and (@lm is null or f1.lm like @lm+'%') and f1.lm=p1.lm_sup and f1.comanda=p1.comanda_sup and f1.cont=p1.cont)  
	and (@lm is null or p1.lm_sup<>'')
   
 update FisaPeCont  
 set suma=suma+isnull((select sum(#p1.sumacont) from #p1 where FisaPeCont.Data=@dDataSus and (@lm is null or fisaPeCont.lm like @lm+'%') and FisaPeCont.tip='D' and FisaPeCont.lm=#p1.lm_sup and FisaPeCont.comanda=#p1.comanda_sup and FisaPeCont.cont=#p1.cont),0)  
 where data=@dDataSus
	and (@lm is null or lm like @lm+'%') 
 
 insert into FisaPeCont (Data,Tip,LM,Comanda,Cont,Suma) 
 select distinct @dDataSus,'D',lm_sup,comanda_sup,cont,0  
 from #p1 p1  
 where not exists(select data from FisaPeCont f1 where f1.data=@dDataSus and (@lm is null or f1.lm like @lm+'%') and f1.tip='D' and f1.lm=p1.lm_sup and f1.comanda=p1.comanda_sup and f1.cont=p1.cont)  
	and (@lm is null or p1.lm_sup<>'')
  
 insert into FisaPeCont (Data,Tip,LM,Comanda,Cont,Suma) 
 select distinct @dDataSus,'C',lm_inf,comanda_inf,cont,0  
 from #p1 p1  
 where not exists(select data from FisaPeCont f1 where f1.data=@dDataSus and (@lm is null or f1.lm like @lm+'%') and f1.tip='C' and f1.lm=p1.lm_inf and f1.comanda=p1.comanda_inf and f1.cont=p1.cont)  
  
 update FisaPeCont  
 set suma=suma-isnull((select sum(#p1.sumacont)  
 from #p1 where FisaPeCont.Data=@dDataSus and (@lm is null or fisaPeCont.lm like @lm+'%') and FisaPeCont.tip='C' and FisaPeCont.lm=#p1.lm_inf and FisaPeCont.comanda=#p1.comanda_inf and FisaPeCont.cont=#p1.cont),0)  
 where data=@dDataSus
  
 drop table #pond  
 drop table #p1  
 set @pas=@pas+1  
end  
end
