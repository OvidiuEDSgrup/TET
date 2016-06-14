DECLARE @pachete nvarchar(2),@tert nvarchar(4000),@data1 datetime,@data2 datetime,@tip nvarchar(1)
SET @pachete=''
SET @tert=NULL 
SET @data1='2012-01-01 00:00:00' 
SET @data2='2012-02-01 00:00:00' 
SET @tip='P'


IF @pachete='2'
begin
select * from (select p.contract,
p.tert, tt.Denumire,
p.cod,
n.Denumire as pachet,
p.cantitate,
p.pret as pret,
(select SUM(cantitate) from pozdoc where tip='Ap' and comanda=p.contract and cod=p.cod AND (@tert IS NULL OR tert=@tert))  as cant_livrate,
p.termen as termen,
p.factura as factura,
(select max(data) from pozdoc where tip='Ap' and factura=p.factura and (@tert IS NULL OR tert=@tert)) as datafact,
contract as comanda,
t.Cod as teh,
(select denumire from nomencl where cod=t.cod) as denTeh,
t.Specific as cantTeh,
(select isnull(sum(cantitate),0) from pozdoc where tip='CM' and  numar=(select max(numar) from pozdoc where cod=p.cod  and tip='PP' and data>=@data1 and data<=@data2 )
and cod=t.cod and data>=@data1 and data<=@data2) as cantLivrataTeh,
t.Specific-(select isnull(sum(cantitate),0) from pozdoc where tip='CM'  and numar=(select max(numar) from pozdoc where cod=p.cod  and tip='PP' and data>=@data1 and data<=@data2 )
and cod=t.cod and data>=@data1 and data<=@data2) as dif
from pozcon p, tehnpoz t,nomencl n, terti tt
where p.tip='BK' 
and n.tip='P'
and n.cod=p.cod
and n.tip=@tip
and p.Cod=t.cod_tehn
and tt.Tert=p.Tert
and data>=@data1 and data<=@data2
and (@tert IS NULL OR P.tert=@tert))r
where r.dif!=0
end

else

begin
select * from (select p.contract,
p.tert, tt.Denumire,
p.cod,
n.Denumire as pachet,
p.cantitate,
p.pret as pret,
(select SUM(cantitate) from pozdoc where tip='Ap' and comanda=p.contract and cod=p.cod and (@tert IS NULL OR tert=@tert))  as cant_livrate,
p.termen as termen,
p.factura as factura,
(select max(data) from pozdoc where tip='Ap' and factura=p.factura and (@tert IS NULL OR tert=@tert)) as datafact,
contract as comanda,
t.Cod as teh,
(select denumire from nomencl where cod=t.cod) as denTeh,
t.Specific as cantTeh,
(select isnull(sum(cantitate),0) from pozdoc where tip='CM' and  numar=(select max(numar) from pozdoc where cod=p.cod  and tip='PP' and data>=@data1 and data<=@data2 )
and cod=t.cod and data>=@data1 and data<=@data2) as cantLivrataTeh,
t.Specific-(select isnull(sum(cantitate),0) from pozdoc where tip='CM'  and numar=(select max(numar) from pozdoc where cod=p.cod  and tip='PP' and data>=@data1 and data<=@data2 )
and cod=t.cod and data>=@data1 and data<=@data2) as dif
from pozcon p, tehnpoz t,nomencl n, terti tt
where p.Subunitate='1' and p.tip='BK' 
and n.tip='P' 
and n.cod=p.cod
and n.tip=@tip
and p.Cod=t.cod_tehn and t.Tip='M'
and tt.Tert=p.Tert
and data>=@data1 and data<=@data2
and (@tert IS NULL OR P.tert=@tert))r
end