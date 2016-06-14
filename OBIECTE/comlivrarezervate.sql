DECLARE @data1 datetime, @data2 datetime,@tert varchar(max),@comanda varchar(max), @stare varchar(max),@bifa varchar(max)
SET @data1=null
SET @data2=null
SET @tert=null
SET @comanda=null
SET @stare=''
SET @bifa='1'

DECLARE	@lRezStocBK bit, @cListaGestRezStocBK CHAR(200),@Subunitate CHAR(9), @Tip CHAR(2),@cUtilizator char(10)
SET @cUtilizator=LEFT(dbo.fIaUtilizator(null),10)
SET @Subunitate='1'
SET @Tip='BK'

EXEC luare_date_par 'GE', 'REZSTOCBK', @lRezStocBK OUTPUT, 0, @cListaGestRezStocBK OUTPUT


select ltrim(rtrim(p.tert))+' - '+(select ltrim(rtrim(denumire)) from terti where tert=p.tert) as tert,c.stare,p.Contract,p.Data,p.Cod, p.cantitate as cantComandata,
p.Cant_realizata as cantRealizata, p.cantitate-p.Cant_realizata as diferenta,
 a.contract as comanda,a.Data as dataComAprov,
 ROW_NUMBER() OVER(ORDER BY p.numar_pozitie) as nr,
 (select sum(stoc) from stocuri where Gestiune in ('101','900') and cod=p.cod) as stocCurent 
from pozcon p
left join pozaprov a on p.contract=a.comanda_livrare and p.Cod=a.Cod
inner join con c on p.Contract=c.Contract and p.Tert=c.Tert and p.Tip=c.Tip and p.Data=c.Data
 where p.tip='BK'
 and p.Subunitate='1'
and p.DATA>=@data1 and p.DATA<=@data2
and (isnull(@tert, '') = '' OR  p.Tert= rtrim(rtrim(@tert)))
and (isnull(@comanda, '') = '' OR  p.Contract= rtrim(rtrim(@comanda)))
and (isnull(@Bifa, '') = '' OR p.cantitate-p.Cant_realizata >0)
and c.Stare in (@stare)
order by p.tert,p.contract