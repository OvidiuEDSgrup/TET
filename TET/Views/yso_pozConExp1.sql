CREATE VIEW yso_pozConExp1 AS 
--drop table tmp_proforma
--;with x as (
SELECT pozcon.*
	,Listare=ISNULL(pozconexp2.Explicatii,'')
	,p0.DiscDoi,p0.DiscTrei,p0.cursValuta,p0.tva,p0.CotaTVA
	,p1.*,p2.*,p3.*,p4.*
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
			,Pret=convert(decimal(12,2),pozcon.Pret)
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
		(select valFrDisc=round(p0.pret*p0.cantitate,2)
			,pretDisc=round(p0.pret*p1.discTot,2)
			,pretCuTva=round(p1.pretFrTva*(1+p0.CotaTVA/100.00),3)
			,tvaPret=round(p1.pretFrTva*(p0.CotaTVA/100.00),2)
		) as p2
	cross apply 
		(select valCuDisc=round(p2.pretDisc*pozcon.cantitate,2)
			,pretDiscFrTva=round(p2.pretDisc/(1+p0.tva/100.00),2)
			,tvaPretDisc=round(p2.tvaPret*p1.discTot,2)
			,pretCuTvaDisc=round(p2.pretCuTva*p1.discTot,2)
		) as p3 
	cross apply 
		(select valDisc=round(p2.valFrDisc-p3.valCuDisc,2)
			,valFrTva=round(p3.pretDiscFrTva*p0.CursValuta*p0.cantitate,2)
			,valTva=round(p3.tvaPretDisc*p0.CursValuta*p0.cantitate,2)
			,valCuTva=round(p3.pretCuTvaDisc*p0.CursValuta*p0.cantitate,2)
		) as p4 
	--LEFT JOIN par ON par.Tip_parametru='GE' AND par.Parametru='REZSTOCBK'
WHERE pozcon.Subunitate NOT LIKE 'EXPAND%' AND pozcon.Tip='BK'
--and pozcon.Contract='GL980022'
--)
--select pret2=max(p.pret),discTot1=max(p.discTot)--,pretDisc=max(p.pretDisc)
--,cotva=max(1+p.CotaTVA/100.00),pretdiscoritva=MAX(p.pretdisc*(1+p.CotaTVA/100.00))
----,pretCuTvaDisc=max(p.pretCuTvaDisc)
--,pretCuTvaDisc2=max(p.pretCuTva*p.discTot)
--,discTot2=MAX(p.discTot)
--,pretCuTva=MAX(pretCuTva)
--,pretCuTva2=max(p.pretFrTva*(1+p.CotaTVA/100.00))
--,CotaTVA=max(1+p.CotaTVA/100.00)
--,pretFrTva=MAX(p.pretFrTva)
--,Discount=MAX(p.Discount),DiscDoi=MAX(p.DiscDoi),DiscTrei=MAX(p.DiscTrei)
--,[TOTALCTVAC]=round(sum(p.cantitate*convert(decimal(12,2),p.pretdisc*1.24)),2)
--, rtrim(convert(char(16),convert(money,max(p.valcutva)),1)) as [TOTALCTVA]
--, rtrim(convert(char(15),convert(money,max(p.valdisc)),1)) as [DISCPOZ]
--,rtrim(left(convert(char(16),convert(money,round(sum(p.cantitate*p.pretdisc),2))),16)) as [TOTAL]
--,valFrTva=MAX(valFrTva)
--,rtrim((select val_alfanumerica as nume from par where tip_parametru='GE' and parametru='NUME')) as [UNITATE], rtrim((select val_alfanumerica as cif from par where tip_parametru = 'GE' and parametru = 'CODFISC')) as [CUI], rtrim((select val_alfanumerica from par where tip_parametru = 'GE' and parametru = 'ORDREG')) as [ORDREG], rtrim((select val_alfanumerica from par where tip_parametru='GE' and parametru = 'ADRESA')) as [ADR], rtrim((select val_alfanumerica from par where tip_parametru='GE' and parametru = 'CONTBC')) as [CONT], rtrim((select val_alfanumerica from par where tip_parametru='GE' and parametru = 'BANCA')) as [BANCA], rtrim(ltrim(max(con.contract))) as [NUMAR], rtrim(max(terti.cod_fiscal)) as [CODFISC], rtrim(max(terti.judet)) as [JUDETTERT], rtrim(max(terti.localitate)) as [LOCTERT], rtrim(max(terti.banca)) as [BANCATERT], rtrim(max(terti.cont_in_banca)) as [CONTTERT], rtrim(max(terti.denumire)) as [TERT], rtrim(max(terti.adresa)) as [ADRESATERT], rtrim(max(convert(char(12),con.data,104))) as [DATA], rtrim(ltrim(max(con.contract))) as [COMANDA], rtrim(rtrim(max(con.valuta))) as [VALUTA], rtrim((Select max(gestiuni.denumire_gestiune) from gestiuni where gestiuni.cod_gestiune=max(con.gestiune))) as [PCLUCRU], rtrim(ltrim(rtrim(CASE max(p.valuta) WHEN '' THEN '' ELSE convert(char(16),convert(money,MAX(CON.CURS))) END))) as [CURS], rtrim(ROW_NUMBER() OVER(ORDER BY MIN(P.NUMAR_POZITIE))) as [NUMARRAND], rtrim(ROW_NUMBER() OVER(ORDER BY MIN(P.NUMAR_POZITIE))) as [NR], rtrim(left(convert(char(16),convert(money,round(max(p.Suma_TVA),2)),2),15)) as [TVALINIE], rtrim((case when max(p.tip)='FC' and exists (select codfurn from ppreturi where p.cod=ppreturi.cod_resursa and max(p.tert)=ppreturi.tert) then (select codfurn from ppreturi where p.cod=ppreturi.cod_resursa and max(p.tert)=ppreturi.tert) else p.cod end)) as [COD], rtrim(left(convert(char(16),convert(money,round(max(p.discount),2)),2),15)) as [DISC], rtrim(max(rtrim(ltrim(nomencl.cod)))+'-'+ max(rtrim(ltrim(nomencl.denumire)))) as [DENUMIRE], rtrim(max(nomencl.um)) as [UM], rtrim(left(convert(char(16),convert(money,round(sum(p.cantitate),2)),2),15)) as [CANT], rtrim(left(convert(char(16),convert(money,round(max(convert(decimal(17,5),p.pret)),2)),2),15)) as [PRETBAZA], rtrim(left(convert(char(16),convert(money,round(max(p.pret*(1-p.Discount/100.00)),2)),2),15)) as [PRETDISCUNU], rtrim(left(convert(char(16),convert(money,round(max(p.pret*(1-p.Discount/100.00)*(1-p.DiscDoi/100.00)),2)),2),15)) as [PRETDISCDOI], rtrim(convert(char(16),convert(money,max(p.pretdisc)),1)) as [PRET]
--, rtrim(convert(char(15),convert(money,sum(sum(round(p.valcudisc*(con.val_reziduala/100),2))) over(partition by p.contract)),1)) as [AVANS], rtrim( (select Max(Nume) from utilizatori where ID= max(p.utilizator))) as [DELEGAT], rtrim( (select rtrim(Max(valoare)) from proprietati where TIP='UTILIZATOR' and cod_proprietate='EMAIL' and cod= max(p.utilizator))) as [EMAIL], rtrim(convert(char(15),convert(money,sum(sum(p.valdisc)) over(partition by p.contract)),1)) as [DISCTOT], rtrim(convert(char(16),convert(money,sum(sum(p.valfrtva)) over(partition by p.contract)),1)) as [TOTRONFARATVA], rtrim(convert(char(16),convert(money,sum(sum(p.valtva)) over(partition by p.contract)),1)) as [TOTRONTVA], rtrim(convert(char(16),convert(money,sum(sum(p.valcutva)) over(partition by p.contract)),1)) as [TOTRONCUTVA]  
----into ##raspASIS  
--into tmp_proforma
--FROM avnefac JOIN con ON avnefac.subunitate=con.subunitate and avnefac.tip=con.tip and avnefac.contractul=con.contract and avnefac.cod_tert=con.tert and avnefac.data=con.data JOIN x p ON p.subunitate=con.subunitate and p.tip=con.tip and p.contract=con.contract and p.data=con.data and p.tert=con.tert LEFT JOIN terti ON terti.subunitate=con.subunitate and terti.tert=con.tert LEFT JOIN nomencl ON nomencl.cod=p.cod 
--WHERE p.cantitate=364 and p.Listare='' and avnefac.terminal='ASIS'  GROUP BY avnefac.tip, avnefac.numar, avnefac.data, p.cod,con.loc_de_munca, P.TERT, TERTI.TERT, p.CONTRACT ORDER BY min(p.numar_pozitie)  

--select * from tmp_proforma

--drop table tmp_expr
--select 2.7	*0.900000	*1.24000000	as 'pretdiscoritva',	[pretCuTvaDisc2]=	0.900000	*1.24000000	*2.70000000000000000000
--,'pret'=2.7	,'disctot1'=0.900000	,1.24000000	as 'cotva',	[discTot2]=	0.900000	,1.24000000 as'cotaTva',	2.70000000000000000000 as 'pretFrTva'
--into tmp_expr
--select * from tmp_expr

--exec sp_help tmp_proforma
--exec sp_help tmp_expr
