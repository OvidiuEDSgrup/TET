select  
--convert(decimal(15,3),b.Pret)-convert(decimal(15,3),p.Pret_amanunt_predator) as diferenta
p.Pret_vanzare,p.Pret_cu_amanuntul,p.Pret_amanunt_predator ,b.Pret
--SUM(b.Pret*b.Cantitate) as valbon
--,sum(p.Pret_cu_amanuntul*p.Cantitate) as valpozdoc
,* 
-- update p set pret_
from bonuri b
	left join antetBonuri a on a.casa_de_marcat=b.casa_de_marcat and a.Numar_bon=b.Numar_bon and a.Data_bon=b.data and a.Vinzator=b.Vinzator
	left outer join pozdoc p on p.Tip='AC' and p.Numar=isnull(nullif(bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(50)'),'')
		,left((case when b.Factura_chitanta=1 then rtrim(convert(varchar(4),b.Casa_de_marcat))+right(replace(str(b.Numar_bon),' ','0'),4)
		else ltrim(a.Factura) end),8)) and p.Data=b.Data and p.Cod=b.Cod_produs
where b.Factura_chitanta=1 and b.Tip='21' and (b.Pret<>p.Pret_amanunt_predator)
--and convert(decimal(15,3),p.Pret_amanunt_predator)<>convert(decimal(15,3),b.Pret)
--order by convert(decimal(15,3),b.Pret)-convert(decimal(15,3),p.Pret_amanunt_predator) desc
--and p.Pret_cu_amanuntul=0

select cod,SUM(cantitate*Pret_amanunt_predator) as cantitate from pozdoc te where te.tip='AC' and te.numar='10003' and te.Data='2012-04-30'
group by cod
except
select cod,SUM(cantitate) as cantitate from pozdoc ac where ac.tip='TE' and ac.numar='10003' and ac.Data='2012-04-30'
group by cod
except
select cod,SUM(cantitate) as cantitate from pozdoc te where te.tip='TE' and te.numar='10003' and te.Data='2012-04-30'
group by cod
except
select Cod_produs,SUM(b.Cantitate) as cantitate from bonuri b
	left join antetBonuri a on a.casa_de_marcat=b.casa_de_marcat and a.Numar_bon=b.Numar_bon and a.Data_bon=b.data and a.Vinzator=b.Vinzator
where b.Numar_bon=3 and b.Casa_de_marcat=1 and b.Data='2012-04-30' and b.Tip='21' 
group by b.Cod_produs
except
select cod,SUM(cantitate) as cantitate from pozdoc te where te.tip='TE' and te.numar='10003' and te.Data='2012-04-30'
group by cod


select  p.*,
b.Cod_produs
from bonuri b
	left join antetBonuri a on a.casa_de_marcat=b.casa_de_marcat and a.Numar_bon=b.Numar_bon and a.Data_bon=b.data and a.Vinzator=b.Vinzator
	left join pozdoc p on p.Tip='AC' and p.Numar=isnull(nullif(bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(50)'),'')
		,left((case when b.Factura_chitanta=1 then rtrim(convert(varchar(4),b.Casa_de_marcat))+right(replace(str(b.Numar_bon),' ','0'),4)
		else ltrim(a.Factura) end),8)) and p.Data=b.Data and p.Cod=b.Cod_produs
	left join pozdoc t on t.Tip='TE' and t.Numar=p.Numar and t.Data=p.Data and t.Cod=p.Cod 
where b.Factura_chitanta=1 and b.Tip='21' 
--and (b.Pret<>p.Pret_amanunt_predator 
--or b.Pret<>t.Pret_cu_amanuntul
--)
and b.Numar_bon=3 and b.Casa_de_marcat=1 and b.Data='2012-04-30' and b.Tip='21' 

select cod,* from pozdoc te where te.tip='AC' and te.numar='10003' and te.Data='2012-04-30'
order by 1

select cod,* from pozdoc te where te.tip='TE' and te.numar='10003' and te.Data='2012-04-30'
order by 1

-- pret diferit
select  
--convert(decimal(15,3),b.Pret)-convert(decimal(15,3),p.Pret_amanunt_predator) as diferenta
p.Pret_vanzare,p.Pret_cu_amanuntul,p.Pret_amanunt_predator ,b.Pret
--SUM(b.Pret*b.Cantitate) as valbon
--,sum(p.Pret_cu_amanuntul*p.Cantitate) as valpozdoc
,* 
-- update p set pret_
from bonuri b
	left join antetBonuri a on a.casa_de_marcat=b.casa_de_marcat and a.Numar_bon=b.Numar_bon and a.Data_bon=b.data and a.Vinzator=b.Vinzator
	left outer join pozdoc p on p.Tip='AC' and p.Numar=isnull(nullif(bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(50)'),'')
		,left((case when b.Factura_chitanta=1 then rtrim(convert(varchar(4),b.Casa_de_marcat))+right(replace(str(b.Numar_bon),' ','0'),4)
		else ltrim(a.Factura) end),8)) and p.Data=b.Data and p.Cod=b.Cod_produs
where 
b.Factura_chitanta=1 
and b.Tip='21' 
--and (b.Pret<>p.Pret_amanunt_predator)
and b.Numar_bon=2
--and b.Casa_de_marcat=1 
and b.Data='2012-05-21' and b.Cod_produs='4300102500221'


-- valori/coduri diferite intre bonuri si ac-uri
select  ISNULL(CONVERT(varchar,b.Numar_bon),'NUEXISTA') as Numar_bon,ISNULL(CONVERT(varchar,b.Data,121),'NUEXISTA') as Data_bon,ISNULL(b.Cod_produs,'NUEXISTA') as Cod_produs_bon
	,ISNULL(p.Numar,'NUEXISTA') as Numar_ac,ISNULL(CONVERT(varchar,p.Data,121),'NUEXISTA') as Data_ac,ISNULL(p.Cod,'NUEXISTA') as Cod_produs_ac
	,b.Cantitate as Cantitate_bon,p.cantitate as Cantitate_ac,b.Valoare as Valoare_bon,p.Valoare as Valoare_ac
,*
from (select max(case b.Factura_chitanta when 1 then 1 else 0 end) as Factura_chitanta,b.Casa_de_marcat,b.Numar_bon,b.Data, b.Cod_produs
		, max(a.Factura) as Factura
		, Sum(Cantitate) as Cantitate, MAX(Pret) as Pret 
		, SUM(convert(decimal(15,2),b.Cantitate*b.Pret)) as Valoare
		,(select top 1 a.bon from antetBonuri a where a.casa_de_marcat=b.casa_de_marcat and a.Numar_bon=b.Numar_bon and a.Data_bon=b.data and a.Vinzator=b.Vinzator) as bon
		from bonuri b
			left join antetBonuri a on a.casa_de_marcat=b.casa_de_marcat and a.Numar_bon=b.Numar_bon and a.Data_bon=b.data and a.Vinzator=b.Vinzator
		where b.Factura_chitanta=1 and b.Tip='21'
		group by b.Casa_de_marcat,b.Numar_bon,b.Data,b.Vinzator, b.Cod_produs) b
	full outer join 
	(select p.Numar,p.Data,p.Cod,SUM(p.Cantitate) as cantitate
		,max(p.Pret_cu_amanuntul) as Pret_cu_amanuntul,max(p.Pret_amanunt_predator) as Pret_amanunt_predator,max(p.Pret_vanzare) as Pret_vanzare 
		,SUM(convert(decimal(15,2),p.Cantitate*p.Pret_amanunt_predator)) as Valoare
	from pozdoc p where p.Subunitate='1' and p.Tip='AC'
	group by p.Numar,p.Data,p.Cod) p
	on p.Numar=isnull(nullif(bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(50)'),'')
		,left((case when b.Factura_chitanta=1 then rtrim(convert(varchar(4),b.Casa_de_marcat))+right(replace(str(b.Numar_bon),' ','0'),4)
		else ltrim(b.Factura) end),8)) and p.Data=b.Data and p.Cod=b.Cod_produs
where b.Cod_produs is null or p.Cod is null  
	or isnull(b.Cantitate,0)<>isnull(p.cantitate,0) or abs(isnull(b.Valoare,0)-isnull(p.Valoare,0))>0.1

