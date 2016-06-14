select 
isnull(nullif(bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(50)'),'')
,left((case when b.Factura_chitanta=1 then rtrim(convert(varchar(4),b.Casa_de_marcat))+right(replace(str(b.Numar_bon),' ','0'),4)
 else ltrim(a.Factura) end),8)) 
as nrpozdoc,
			(case when b.factura_chitanta =1 then 'AC' else 'AP' end)
			,left(RTrim(CONVERT(varchar(4),b.Casa_de_marcat))+right(replace(str(a.Numar_bon),' ','0'),4), 8)
,* 
from bonuri b
left join antetBonuri a on a.IdAntetBon=b.idAntetBon
--where a.Numar_bon=1 and a.Data_bon='2012-04-30' 
where not exists
(select 1 from pozdoc p where p.Tip=(case when b.Factura_chitanta=1 then 'AC' else 'AP' end) 
and p.Numar=isnull(nullif(bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(50)'),''),left((case when b.Factura_chitanta=1 then rtrim(convert(varchar(4),b.Casa_de_marcat))+right(replace(str(b.Numar_bon),' ','0'),4) else ltrim(a.Factura) end),8))
and p.data=b.data
)
order by a.Data_bon desc
select * from pozdoc p where p.Tip='AC' 
and p.Numar='10003   ' 
and p.Data='2012-03-15'

select * from POZDOC p where 
--p.Tip='AP' 
--and p.Numar='10003' 
p.Data='2012-03-15'
AND COD='01263062'
