create view yso_vIaPozcon as
select	
		--rtrim(p.subunitate) as subunitate
		rtrim(p.tip) as tip
		, rtrim(p.tip) as subtip
		, CASE p.Tip WHEN 'BF' THEN 'Contract beneficiar' WHEN 'BK' THEN 'Comanda livrare' 
			WHEN 'FA' THEN 'Contract furnizor' WHEN 'FC' THEN 'Comanda aprovizionare' ELSE '' END AS dentip
		, rtrim(p.contract) as numar
		,convert(varchar(10),p.data,101) as data
		,rtrim(p.tert) as tert,
		isnull(rtrim(t.denumire), '') as dentert --/*sp
		, rtrim(contract_coresp) as contractcor--,rtrim(d.Punct_livrare) as punctlivrare,rtrim(inft.Descriere) as denpunctlivrare
		, isnull(rtrim(lm.denumire),'') as denlm, rtrim(d.loc_de_munca) as lm 
		, rtrim(isnull(d.Scadenta,'')) as scadenta--sp*/
		, rtrim(p.cod ) as cod, 
		rtrim(p.cod)+' - '+ rtrim(coalesce(n.denumire,g.denumire, '')) as dencod,  
		rtrim(coalesce(n.denumire,g.denumire, '')) as denumire,    
		rtrim(p.factura) as gestiune
		,isnull(rtrim(left(gest.denumire_gestiune, 30)), '') as dengestiune 
		,  convert(decimal(17, 5), p.cantitate) as cantitate
		,  rtrim(isnull(p.valuta, '')) as valuta,  
		convert(varchar(10),p.termen,101) as termene
		, convert(decimal(14, 4), p.pret) as Tpret
		, convert(decimal(17, 5), p.cantitate) as Tcantitate
		, convert(decimal(17, 5), p.cant_realizata) as Tcant_realizata,  
		rtrim(isnull(n.um, '')) as um1, convert(decimal(17, 5), p.cantitate-(case when isnull(n.UM_1, '')<>'' and isnull(n.Coeficient_conversie_1, 0)<>0 then floor((p.cantitate-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end))/n.Coeficient_conversie_1) else 0 end)-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end)) as cantitateum1,    
		RTRIM(isnull(n.UM_1, '')) as um2, CONVERT(decimal(10,5), isnull(n.coeficient_conversie_1, 0)) as coefconvum2,     
		convert(decimal(17, 5), (case when isnull(n.UM_1, '')<>'' and isnull(n.Coeficient_conversie_1, 0)<>0 then floor((p.cantitate-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end))/n.Coeficient_conversie_1) else 0 end)) as cantitateum2,    
		RTRIM(isnull(n.UM_2, '')) as um3, CONVERT(decimal(10,5), isnull(n.coeficient_conversie_2, 0)) as coefconvum3,     
		convert(decimal(17, 5), (case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end)) as cantitateum3,     
		convert(decimal(17, 5), p.pret) as pret, convert(decimal(10, 4), p.pret_promotional) as cant_transferata,     
		convert(decimal(12, 5), p.discount) as discount, 
		convert(decimal(12, 5), isnull(pe.pret, 0)) as info1,
		convert(decimal(12, 5), isnull(pe.cantitate, 0)) as info3,
		convert(decimal(5, 2), p.cota_tva) as cotatva,     
		rtrim(p.punct_livrare) as punctlivrare, rtrim(d.Mod_plata) as modplata,  --/*sp
		CASE d.Mod_plata WHEN '0' THEN 'OP' WHEN '1' THEN 'CEC' 
			WHEN '2' THEN 'Numerar' ELSE '' END AS denmodplata,
		--sp*/'('+rtrim(p.mod_de_plata)+')'+rtrim(s.denumire) as denmodplata,           
		isnull(rtrim(gest.tip_gestiune), '') as tipgestiune,         
		convert(decimal(17, 5),p.cant_realizata) as cant_realizata,       
		convert(decimal(17, 5),p.cant_aprobata) as cant_aprobata, convert(varchar(10),p.termen,101) as termen_poz,       
		rtrim(p.Explicatii) as explicatii, p.numar_pozitie as numarpozitie, RTrim(ISNULL(pe.Explicatii, '')) as atp,    
		convert(char(10), isnull(pe.termen, '01/01/1901'), 101) as dataexpirarii,       
		rtrim(isnull(dp.Obiect, '')) as obiect, 
		rtrim(isnull(obiecteds.denumire, '')) as denobiect
		, rtrim(isnull(pe.punct_livrare, '')) as info2       
		,rtrim(isnull(pe2.explicatii, '')) as info4,    rtrim(isnull(pe2.punct_livrare, '')) as info5,      
		convert(char(10), isnull(dp.data1, '01/01/1901')) as info6, convert(char(10), isnull(dp.data2, '01/01/1901')) as info7,       
		convert(decimal(17, 5), isnull(dp.val1, 0)) as info8,  convert(decimal(17, 5), isnull(dp.val2, 0)) as info9,       
		convert(decimal(17, 5), isnull(dp1.val1, 0)) as info10,   convert(decimal(17, 5), isnull(dp1.val2, 0)) as info11,       
		rtrim(isnull(dp.observatii, '')) as info12,  rtrim(isnull(dp.info1, '')) as info13, rtrim(isnull(dp.info2, '')) as info14,       
		rtrim(isnull(dp1.observatii, '')) as info15,  rtrim(isnull(dp1.info1, '')) as info16,    
		rtrim(isnull(dp1.info2, '')) as info17,   
		convert(decimal(15,2),(p.cant_realizata)*p.pret) as Tfacturat 
from pozcon p --/*sp
left outer join con d on d.Subunitate=p.Subunitate and d.Tip=p.Tip and d.Contract=p.Contract and d.Tert=p.Tert and d.Data=p.Data 
left outer join lm on lm.cod = d.loc_de_munca --sp*/
left outer join nomencl n on (p.tip not in ('BF','FA') or p.Mod_de_plata='') and n.cod = p.Cod       
left outer join grupe g on p.Mod_de_plata='G' and g.Grupa=p.cod
left outer join surse s on s.Cod=p.Mod_de_plata      
left outer join terti t on t.subunitate = p.subunitate and t.tert = p.Tert      
left outer join gestiuni gest on gest.cod_gestiune = p.factura      
left outer join pozcon pe on pe.Subunitate='EXPAND' and pe.Tip=p.Tip and pe.Contract=p.Contract and pe.Tert=p.Tert and pe.Data=p.Data and pe.Cod=p.Cod      
left outer join pozcon pe2 on pe2.Subunitate='EXPAND2' and pe2.Tip=p.Tip and pe2.Contract=p.Contract and pe2.Tert=p.Tert and pe2.Data=p.Data and pe2.Cod=p.Cod      
left outer join detpozcon dp on dp.subunitate=p.subunitate and dp.tip=p.tip and dp.contract=p.contract and dp.tert=p.tert and dp.data=p.data and dp.numar_pozitie=p.numar_pozitie and dp.numar_ordine=0      
left outer join obiecteds on obiecteds.cod_obiect=dp.obiect      
left outer join detpozcon dp1 on dp1.subunitate=p.subunitate and dp1.tip=p.tip and dp1.contract=p.contract and dp1.tert=p.tert and dp1.data=p.data and dp1.numar_pozitie=p.numar_pozitie and dp1.numar_ordine=1           
where p.Subunitate='1' 