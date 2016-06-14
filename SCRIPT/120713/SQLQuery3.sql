select isnull((select top 1 p.Discount from pozcon p where p.Subunitate= '1' AND p.tip= 'BF' AND p.Contract=c.Contract_coresp 
		AND p.Tert= i.Tert and p.Mod_de_plata='G' and n.Grupa like RTRIM(p.Cod)+'%' order by p.Cod desc, p.Discount desc)
	,i.Discount)
	,*
from pozcon i
LEFT JOIN con c on c.Subunitate=i.Subunitate and c.Tip=i.Tip and c.Contract=i.Contract and c.Data=i.Data and c.Tert=i.Tert
left JOIN nomencl n ON  n.Cod=i.Cod
where i.Contract='6116'
