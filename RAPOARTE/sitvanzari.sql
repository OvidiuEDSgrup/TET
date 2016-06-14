--declare @data1 datetime,@data2 datetime,@lm nvarchar(4000),@tert nvarchar(4000),@grupa nvarchar(4000),@cod nvarchar(4000),@pachete bit,@echipa nvarchar(4000)
--select @data1='2012-01-01 00:00:00',@data2='2012-04-30 00:00:00',@lm=NULL,@tert=NULL,@grupa=NULL,@cod=NULL,@pachete=0,@echipa=NULL

select * 
--into ##sitvanz2tet1
from
(
select ltrim(rtrim(p.Loc_de_munca)) +' - '+LTRIM(RTRIM(lm.denumire)) as agent,
ltrim(rtrim(p.Tert))+' - '+LTRIM(RTRIM(t.denumire)) as client,
ltrim(rtrim(n.Grupa))+' - '+ltrim(rtrim(g.Denumire)) as grupa,
p.Cod as articol,
n.Denumire as descriere,
sum(p.Cantitate) as cantitate,
sum(p.Cantitate*pr.Pret_vanzare) as pretCatalog,
sum(p.Cantitate*p.Pret_vanzare) as pretVanzare,
sum(p.Cantitate*pr.Pret_vanzare -p.Cantitate*p.Pret_vanzare) as discount,
(case when sum(p.Cantitate*p.Pret_vanzare)!=0 then  1-round((sum(p.Cantitate*pr.Pret_vanzare)/sum(p.Cantitate*p.Pret_vanzare)),2) else 0 end) as discountProcent,
/*
--sum(p.Cantitate*p.Pret_de_stoc) as pretIntrare,
sum(p.Cantitate*p.Pret_vanzare-p.Cantitate*p.Pret_de_stoc) as marja,
round((sum(p.Cantitate*p.Pret_vanzare)/sum(p.Cantitate*p.Pret_de_stoc))*100,2) as marjaProcent,*/
isnull(
--(case when n.tip!='P' then sum(p.Cantitate*p.Pret_de_stoc) else 
(case when isnull((select max(grupa) from pozdoc where tip='TE' and cod=p.cod and p.cod_intrare=grupa),'')='' 
then isnull((select SUM(cm.cantitate*cm.Pret_de_stoc) from pozdoc pp,pozdoc cm where pp.cod=p.Cod and pp.Cod_intrare=p.Cod_intrare and pp.tip='PP' and cm.Tip='CM' and pp.Numar=cm.Numar and pp.Data=cm.data),sum(p.Cantitate*p.Pret_de_stoc))
else isnull((select SUM(cm.cantitate*cm.Pret_de_stoc) from pozdoc pp,pozdoc cm, pozdoc te where te.tip='TE' and pp.cod=p.Cod and p.cod=te.Cod and p.Cod_intrare=te.grupa and pp.Cod_intrare=te.Cod_intrare and pp.tip='PP' and cm.Tip='CM' and pp.Numar=cm.Numar and pp.Data=cm.data),sum(p.Cantitate*p.Pret_de_stoc))
end) 
--end )
,0)as pretIntrare,
(select valoare from proprietati where Cod_proprietate='ECHIPA' and tip='TERT' and cod=p.tert) as echipa
 from   pozdoc p left join doc d on  p.Data=d.Data and p.Numar=d.Numar and p.Tip=d.Tip
 left join (select cod_produs,um,max(tip_pret) as tip_pret,MAX(Pret_vanzare) as Pret_vanzare,MAX(Pret_cu_amanuntul) as Pret_cu_amanuntul 
 from preturi group by cod_produs,um) pr on  pr.cod_produs=p.cod and pr.um=d.discount_suma
  left join nomencl n on  n.Cod=p.Cod and n.Cod=p.Cod 
    left join grupe g on  n.Grupa=g.Grupa
  left join lm on  lm.Cod=p.Loc_de_munca
   left join  terti t on  p.Tert=t.Tert
where p.tip in ('AP','AC')
 and p.data>=@data1 and p.data<=@data2
 and p.Cont_venituri='707.1'
and p.Cantitate!=0
AND (isnull(@lm,  '') = '' OR p.Loc_de_munca = rtrim(rtrim(@lm)))
AND (isnull(@tert,  '') = '' OR p.tert = rtrim(rtrim(@tert)))
AND (isnull(@grupa,  '') = '' OR n.grupa = rtrim(rtrim(@grupa)))
AND (isnull(@cod,  '') = '' OR p.cod = rtrim(rtrim(@cod)))
and (@pachete=0 or n.tip='P')
group by p.Loc_de_munca,lm.Denumire,p.Tert,t.Denumire,n.Grupa,g.Denumire,p.Cod,n.Denumire,p.Cod_intrare,n.Tip
having  SUM(p.cantitate)!=0
)r
where (isnull(@echipa,  '') = '' OR r.echipa = rtrim(rtrim(@echipa)))
order by r.echipa