select c.Contract_coresp,
(select top 1 d.Discount from pozcon d where d.Subunitate= '1' AND d.tip= 'BF' AND d.Contract=c.Contract_coresp 
		AND d.Tert= i.Tert and d.Mod_de_plata='G' and n.Grupa like RTRIM(d.Cod)+'%' order by d.Cod desc, d.Discount desc) as disc
,* from insertpozcontmp i
	LEFT JOIN pozcon p ON p.Subunitate= 'EXPAND' AND p.tip= i.Tip AND p.Contract=i.Contract AND p.Tert= i.Tert AND p.Data= i.Data 
		and p.Cod= i.Cod and p.Numar_pozitie= i.Numar_pozitie
	LEFT JOIN con c on c.Subunitate=i.Subunitate and c.Tip=i.Tip and c.Contract=i.Contract and c.Data=i.Data and c.Tert=i.Tert
	left JOIN nomencl n ON  n.Cod=i.Cod
where i.Subunitate='1'

select * from con c where c.Contract='6117'