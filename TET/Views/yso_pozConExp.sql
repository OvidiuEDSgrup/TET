CREATE VIEW yso_pozConExp AS 
--drop table tmp_proforma
--;with x as (
SELECT pozcon.*
	,Listare=ISNULL(pozconexp2.Explicatii,'')
	,p0.DiscDoi,p0.DiscTrei,p0.cursValuta,p0.tva,p0.CotaTVA
	,p1.*,p2.*,p3.*,p4.*,p5.*
/*
	,Cant_rezervata=ISNULL((SELECT SUM(Stoc) AS Cant_rezervata
		FROM dbo.stocuri s LEFT JOIN par ON par.Tip_parametru='GE' AND par.Parametru='REZSTOCBK'
		WHERE s.Subunitate=pozcon.subunitate and s.Tip_gestiune NOT IN ('F','T') and s.Contract=pozcon.Contract and s.Cod=pozcon.Cod
			AND par.Val_logica=1 AND CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(par.Val_alfanumerica)+';')>0 
			AND s.Stoc>0.001) ,0) 
			
	,Cant_comandata=isnull((select sum(pa.cant_comandata-pa.cant_realizata) from pozaprov pa where pa.tip='BK' and pa.comanda_livrare=pozcon.contract 
		and pa.data_comenzii=pozcon.data and pa.beneficiar=pozcon.tert and pa.cod=pozcon.cod /*and abs(pa.cant_realizata)<0.001*/),0) 
	
	,Cant_stoc_gest=ISNULL((SELECT SUM(Stoc)
		FROM dbo.stocuri s 
		WHERE s.Subunitate=pozcon.Subunitate AND s.Tip_gestiune NOT IN ('F','T') AND s.Stoc>0.001 AND pozcon.Cod=s.Cod
			AND (s.Cod_gestiune=ISNULL(NULLIF(pozcon.Punct_livrare,''), pozcon.Factura) AND s.Contract=pozcon.Contract
				OR s.Cod_gestiune=ISNULL(NULLIF(pozcon.Punct_livrare,''), pozcon.Factura) AND s.Contract=''
				OR CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(par.Val_alfanumerica)+';')>0 AND s.Contract=''
				OR s.Contract=pozcon.Contract)),0) 
	
	,Transferuri=ISNULL((select SUM(p.cantitate)
		from pozdoc p 
		WHERE p.Subunitate=pozcon.Subunitate and p.Tip='TE' and p.Factura=pozcon.Contract 
			and p.Gestiune=ISNULL(NULLIF(pozcon.Punct_livrare,''), pozcon.Factura) AND p.Cod=pozcon.Cod 
			AND par.Val_logica=1 AND CHARINDEX(';'+RTRIM(p.Gestiune_primitoare)+';',';'+RTRIM(par.Val_alfanumerica)+';')>0 
			AND p.cantitate>0 and p.stare not in ('4', '6')),0) 
	
	,Avize=ISNULL((select SUM(p.cantitate)
		from pozdoc p where p.Subunitate=pozcon.Subunitate and p.Tip='AP' and p.Contract=pozcon.Contract 
			--and p.Gestiune=ISNULL(NULLIF(pozcon.Punct_livrare,''), pozcon.Factura)
			and p.Cod=pozcon.cod and p.cantitate>0),0) 
	,AlteIesiri=ISNULL((select SUM(p.cantitate)
		from pozdoc p where p.Subunitate=pozcon.Subunitate and p.Tip='AE' and p.grupa=pozcon.Contract 
			--and p.Gestiune=ISNULL(NULLIF(pozcon.Punct_livrare,''), pozcon.Factura)
			and p.Cod=pozcon.cod and p.cantitate>0),0) 
--*/
FROM pozcon	
	LEFT JOIN gestiuni gprim on gprim.Subunitate=pozcon.Subunitate and gprim.Cod_gestiune=pozcon.Punct_livrare
	LEFT JOIN pozcon pozconexp ON pozconexp.Subunitate='EXPAND' and pozconexp.Tip=pozcon.Tip and pozconexp.Data=pozcon.Data 
		and pozconexp.Tert=pozcon.Tert and pozconexp.Contract=pozcon.Contract and pozconexp.Cod=pozcon.Cod and pozconexp.Numar_pozitie=pozcon.Numar_pozitie 
	LEFT JOIN pozcon pozconexp2 ON pozconexp2.Subunitate='EXPAND2' and pozconexp2.Tip=pozcon.Tip and pozconexp2.Data=pozcon.Data 
		and pozconexp2.Tert=pozcon.Tert and pozconexp2.Contract=pozcon.Contract and pozconexp2.Cod=pozcon.Cod and pozconexp2.Numar_pozitie=pozcon.Numar_pozitie 
	LEFT JOIN con ON con.Subunitate=pozcon.Subunitate and con.Tip=pozcon.Tip and con.Data=pozcon.Data and con.Tert=pozcon.Tert and con.Contract=pozcon.Contract
	LEFT JOIN nomencl on nomencl.Cod=pozcon.Cod
	cross apply 
		(select Cantitate=convert(decimal(15,3),pozcon.Cantitate)
			,Pret=convert(decimal(12,5),pozcon.Pret)
			,Cant_aprobata=convert(decimal(15,3),pozcon.Cant_aprobata)
			,Discount=convert(decimal(12,2),pozcon.Discount)
			,DiscDoi=convert(decimal(12,2),ISNULL(pozconexp.Pret,0))
			,DiscTrei=convert(decimal(12,2),ISNULL(pozconexp.Cantitate,0)) 
			,CotaTVA=convert(decimal(12,2),pozcon.Cota_TVA)
			,tva=convert(decimal(12,2),CASE when gprim.tip_gestiune IN ('A') then pozcon.Cota_TVA else 0 end)
			,cursValuta=convert(decimal(17,5),(CASE pozcon.valuta WHEN '' THEN 1 ELSE 
				CASE con.curs WHEN 0 THEN (SELECT TOP 1 curs FROM curs WHERE Valuta=pozcon.valuta and data<=pozcon.data ORDER BY Data DESC) 
				ELSE con.curs END END))	  
		) p0
	cross apply 
		(select pretFrTva=round(p0.pret/(1+p0.tva/100.00),5)
			,discTot=(1-p0.Discount/100.00)*(1-p0.DiscDoi/100.00)*(1-p0.DiscTrei/100.00)
		) as p1 
	cross apply 
		(select pretFrTvaCuDiscFact=round(p1.pretFrTva*p1.discTot,5)
			,pretCuTvaBon=round(p1.pretFrTva*(1+p0.CotaTVA/100.00),2)
		) as p2
	cross apply 
		(select valTvaFact=round(p2.pretFrTvaCuDiscFact*(p0.CotaTVA/100.00)*p0.Cantitate,2)
			,valFrTvaCuDiscFact=round(p2.pretFrTvaCuDiscFact*p0.Cantitate,2)
			,valDiscFact=ROUND((p1.pretFrTva-p2.pretFrTvaCuDiscFact)*p0.Cantitate,2)
			,pretCuTvaCuDiscBon=round(p2.pretCuTvaBon*p1.discTot,2)
			,pretDisc=p2.pretFrTvaCuDiscFact
		) as p3 
	cross apply 
		(select valCuTvaCuDiscBon=round(p3.pretCuTvaCuDiscBon*p0.CursValuta*p0.cantitate,2)
			,valDiscBon=round((p2.pretCuTvaBon-p3.pretCuTvaCuDiscBon)*p0.Cantitate,2)
			,valDisc=p3.valDiscFact
			,valCuDisc=p3.valFrTvaCuDiscFact
			,valFrTva=p3.valFrTvaCuDiscFact
			,valTva=p3.valTvaFact
		) as p4
	cross apply 
		(select valTvaBon=round(p4.valCuTvaCuDiscBon*p0.CotaTVA/(100+p0.CotaTVA),2)
			,valCuTva=p4.valCuTvaCuDiscBon
		) as p5 
	--LEFT JOIN par ON par.Tip_parametru='GE' AND par.Parametru='REZSTOCBK'
WHERE pozcon.Subunitate NOT LIKE 'EXPAND%' AND pozcon.Tip='BK'
--and pozcon.Contract='GL980022'
