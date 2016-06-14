DECLARE @pachete nvarchar(2),@tert nvarchar(4000),@data1 datetime,@data2 datetime,@tip nvarchar(1)
SET @pachete='2'
SET @tert=NULL 
SET @data1='2012-01-01 00:00:00' 
SET @data2='2012-02-01 00:00:00' 
SET @tip='P'

select comenziPachete.*
,documente.cant_livrate,ISNULL(documente.cantLivrataTeh,0) as cantLivrataTeh,documente.datafact, 
comenziPachete.Specific-ISNULL(documente.cantLivrataTeh,0) 
from 
	(select docPachete.contract,docPachete.cod_pachet,docPachete.datafact,docPachete.cant_livrate,cm.cod as cod_material,cm.cantLivrataTeh from
		(select pd.Numar, pd.Data, pd.Cod, sum(cantitate) cantLivrataTeh 
		from pozdoc pd where tip='CM' and data>=@data1 and data<=@data2
		group by pd.Numar, pd.Data, pd.Cod) as cm 
	left join tehnpoz on tehnpoz.Cod=cm.Cod
	left join tehn on tehn.Cod_tehn=tehnpoz.Cod_tehn
		(select ap.contract,ap.cod as cod_pachet,max(ap.datafact) datafact,pp.numar,pp.data,sum(ap.cant_livrate) cant_livrate from
			(select pd.Contract,pd.Cod,pd.Cod_intrare,MAX(pd.Data_facturii) as datafact, SUM(cantitate) as cant_livrate 
			from pozdoc pd where tip='Ap' AND (@tert IS NULL OR tert=@tert)
			group by pd.Contract,pd.Cod,pd.Cod_intrare) as ap
		join
			(select  pd.numar, pd.data, pd.cod, pd.cod_intrare
			from pozdoc pd where tip='PP' and data>=@data1 and data<=@data2 
			group by pd.numar, pd.data, pd.cod, pd.cod_intrare) as pp on ap.Cod=pp.Cod and ap.Cod_intrare=pp.Cod_intrare
		group by ap.contract,ap.cod,pp.numar, pp.data) as docPachete on cm.numar=docPachete.numar and cm.data=docPachete.data) as documente
left join
	(select p.contract,
	p.tert, 
	max(tt.Denumire) Denumire,
	p.cod as teh,
	max(n.Denumire) as pachet,
	sum(p.cantitate) cantitate,
	max(p.pret) as pret,
	--(select SUM(cantitate) from pozdoc where tip='Ap' and comanda=p.contract and cod=p.cod AND (@tert IS NULL OR tert=@tert))  as cant_livrate,
	max(p.termen) as termen,
	max(p.factura) as factura
	--(select max(data) from pozdoc where tip='Ap' and factura=p.factura and (@tert IS NULL OR tert=@tert)) as datafact,
	--t.Cod,
	--(select denumire from nomencl where cod=t.cod) as denTeh,
	--t.Specific as cantTeh,
	--(select isnull(sum(cantitate),0) from pozdoc where tip='CM' and  numar=(select max(numar) from pozdoc where cod=p.cod  and tip='PP' and data>=@data1 and data<=@data2 ) and cod=t.cod and data>=@data1 and data<=@data2) as cantLivrataTeh,
	--t.Specific --(select isnull(sum(cantitate),0) from pozdoc where tip='CM'  and numar=(select max(numar) from pozdoc where cod=p.cod  and tip='PP' and data>=@data1 and data<=@data2 ) and cod=t.cod and data>=@data1 and data<=@data2) as dif
	from pozcon p,nomencl n, terti tt
	where p.Subunitate='1' and p.tip='BK' 
		and n.tip='P'
		and n.cod=p.cod
		and n.tip=@tip
		and tt.Tert=p.Tert
		and data>=@data1 and data<=@data2
		and (@tert IS NULL OR P.tert=@tert)
	group by p.Contract,p.Tert,p.Cod) as  comenziPachete
on documente.Contract=comenziPachete.Contract and documente.cod_pachet=comenziPachete.teh and documente.cod_material=comenziPachete.cod
where @pachete='' or comenziPachete.Specific-ISNULL(documente.cantLivrataTeh,0)!=0

