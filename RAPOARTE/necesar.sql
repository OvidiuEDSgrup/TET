DECLARE @gest101 nvarchar(9),@coef nvarchar(1),@data11 nvarchar(4000),@data12 nvarchar(4000),@data21 nvarchar(4000),@data22 nvarchar(4000),@data31 nvarchar(4000),@data32 nvarchar(4000),@data1 datetime,@data2 datetime,@Tert nvarchar(4000),@cod nvarchar(4000),@grupa nvarchar(4000)
select @gest101=N'101      ',@coef=N'1',@data11=NULL,@data12=NULL,@data21=NULL,@data22=NULL,@data31=NULL,@data32=NULL,@data1='2012-03-31 00:00:00',@data2='2012-03-31 00:00:00',@Tert=NULL,@cod=NULL,@grupa=NULL

select * from
(select distinct s.cod as cod,n.Denumire as denumire,
(select isnull(sum(stoc_min),0) from stoclim where cod=s.cod) as stoc_siguranta,
(select sum(stoc) from stocuri where cod=s.cod) as stocTET,
(select sum(stoc) from stocuri where cod=s.cod and cod_gestiune=@gest101) as stoc101,
(select sum(stoc) from stocuri where cod=s.cod and cod_gestiune='300') as rezerv,
(select sum(cantitate) from pozdoc where cod=s.cod and tip='AP' and data>=@data11 and data<=@data12) as vanz1,
(select sum(cantitate) from pozdoc where cod=s.cod and tip='AP' and data>=@data21 and data<=@data22) as vanz2,
(select sum(cantitate) from pozdoc where cod=s.cod and tip='AP' and data>=@data31 and data<=@data32) as vanz3,
(select sum(cantitate) from pozdoc where cod=s.cod and tip='AP' and data>=@data1 and data<=@data2) as vanz,
0 as necesatAprovizionat,
(select SUM(cantitate) from pozcon where tip='FC' and Contract in (select contract from con where  tip='FC'and stare='1' and DATA=@data1 and DATA>=@data2 and  (isnull(@Tert, '') = '' OR  tert = rtrim(rtrim(@Tert))))
and DATA=@data1 and DATA>=@data2 and cod=s.cod and  (isnull(@Tert, '') = '' OR  tert = rtrim(rtrim(@Tert)))) as comenziIncurs
from stocuri s, nomencl n
where s.Cod=n.cod
 and (isnull(@cod, '') = '' OR  s.cod= rtrim(rtrim(@cod)))
and  (isnull(@grupa, '') = '' OR  n.grupa = rtrim(rtrim(@grupa)))
)r
where   (isnull(@Bifa, '') = '' OR r. stoc_siguranta>0)