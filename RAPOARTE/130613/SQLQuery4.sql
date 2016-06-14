--V_TOTcuTOT --dupa 12 apr 2013 - am adaugata pret catalog la momntul vanzarii=pret_distrib_fTva , am eliminat pret stoc
SELECT (SELECT TOP 1 RTRIM(Denumire) AS Expr1 FROM terti AS t1 WHERE (p.Tert = Tert)) AS nume_client
      ,(SELECT TOP 1 rtrim(Judet) FROM terti AS t2 WHERE (p.Tert = Tert)) AS judet
--      ,rtrim(it.loc_munca) loc_munca_tert

	  ,(select lm.Denumire from lm lm where  it.Loc_munca=lm.Cod ) AGV_tert
 ,(select lm.cod from lm lm where  it.Loc_munca=lm.Cod ) loc_munca_tert
,(select lm.Cod_parinte from lm lm where  it.Loc_munca=lm.Cod ) locm_tert_parinte
	  ,SM = CASE 
			WHEN (SELECT TOP 1 t2.Judet FROM terti t2 WHERE p.Tert = t2.Tert) IN ('TM', 'BH', 'AR', 'CS', 'SM', 'MM', 'SJ', 'BN', 'CJ','CLU', 'MS', 'HR', 'HD', 'AB', 'SB', 'SV', 'BT', 'NT', 'IS','MD','FR','CH') 
				  THEN 'CD' 
			WHEN (SELECT TOP 1 t2.Judet FROM terti t2 WHERE p.Tert = t2.Tert) IN ('MH', 'GJ', 'DJ', 'VL', 'OT', 'AG', 'TR', 'DB', 'PH', 'GR', 'IL', 'IF','B', 'CL', 'CT', 'TL', 'BR', 'BZ', 'BV', 'CV', 'VN', 'GL', 'BC', 'VS','BG','CY') 
                  THEN 'MFI' ELSE ' ' END --SM
      ,(SELECT TOP 1 rtrim(Denumire) FROM gterti AS g WHERE ((SELECT TOP 1 Grupa FROM terti AS t WHERE (p.Tert = Tert)) = Grupa)) AS den_grupa_tert
      ,(SELECT TOP 1 rtrim(Valoare)  FROM proprietati AS pt WHERE (Tip = 'TERT') AND (Cod_proprietate = 'SUBCONTRACTANT') AND
                     ((SELECT TOP 1 Tert FROM terti AS t WHERE (p.Tert = Tert)) = RTRIM(Cod))) AS subcontractant
      , YEAR(p.Data) AS 'An', MONTH(p.Data) AS 'Luna', DAY(p.Data) AS 'Zi'
      ,(SELECT TOP 1 rtrim(Denumire) FROM terti AS t3 WHERE (n.Furnizor = Tert)) AS furnizor
      ,rtrim(n.Loc_de_munca) AS cod_note, RTRIM(n.Denumire) AS denumire_articol, p.Cantitate
      , ROUND(p.Pret_vanzare * p.Cantitate, 2) AS val_vanzare_RON_fTVA
      ,p.Factura, p.Loc_de_munca   loc_munca_doc
      ,(SELECT TOP 1 rtrim(Denumire) FROM lm AS l WHERE (p.Loc_de_munca = Cod)) AS den_locm_doc 
,(SELECT TOP 1 rtrim(l.Cod_parinte) FROM lm AS l WHERE (p.Loc_de_munca = Cod)) AS locm_doc_parinte 
,(SELECT TOP 1 Pret_vanzare FROM preturi AS p WHERE (n.Cod = Cod_produs) AND (UM = '1')) AS pret_catalog_acum_fTva --pretul 
      ,(SELECT TOP 1 Sold_maxim_ca_beneficiar FROM terti AS t1 WHERE (p.Tert = Tert)) AS limita_credit
      ,(SELECT TOP 1 Discount FROM infotert AS it WHERE (Identificator NOT IN ('1')) AND (p.Tert = Tert)) AS Termen_plata
      ,(SELECT TOP 1 Comision_suplimentar FROM targetag AS tg WHERE  (p.Tert = Client)) AS target_val
  
	  ,MKT = CASE 
			WHEN (SELECT TOP 1 t2.Judet FROM terti t2 WHERE p.Tert = t2.Tert) IN ('SV', 'BT', 'NT', 'IS', 'BR', 'BZ', 'BV', 'CV', 'VN', 'GL', 'BC', 'VS','MD') 
				  THEN 'AGR' 
		    WHEN (SELECT TOP 1 t2.Judet FROM terti t2 WHERE p.Tert = t2.Tert) IN ('MH', 'GJ', 'DJ', 'VL', 'OT', 'AG', 'TR', 'DB', 'PH', 'GR', 'IL','IF', 'B', 'CL', 'CT', 'TL' ,'BG','CY') 
				  THEN 'CIV' 
		    WHEN (SELECT TOP 1 t2.Judet FROM terti t2 WHERE p.Tert = t2.Tert) IN ('TM', 'BH', 'AR', 'CS', 'SM', 'MM', 'SJ', 'BN', 'CJ', 'MS', 'HR', 'HD', 'AB', 'SB','FR','CH') 
				  THEN 'APO' ELSE ' ' END --MKT
	 ,n.Grupa
     ,(SELECT TOP 1 rtrim(Denumire) FROM grupe AS g WHERE (n.Grupa = Grupa)) AS den_grupa
                       
                     
      , n.tip as status_NOM,p.Tip, p.Numar ,RTRIM(p.Cod) AS cod_articol               
      ,(SELECT TOP 1 RTRIM(Valoare) AS Expr1 FROM proprietati AS pr WHERE (Tip = 'TERT') AND (Cod_proprietate = 'ECHIPA') AND
                     ((SELECT TOP 1 Tert FROM terti AS t WHERE (p.Tert = Tert)) = RTRIM(Cod))) AS echipa    
      ,(SELECT TOP 1 Grupa FROM terti AS t WHERE (p.Tert = Tert)) AS grupa_tert
      , p.Tip_miscare , n.Tip AS Expr1, n.Cont                            
                     
 FROM pozdoc AS p 
 INNER JOIN nomencl AS n ON p.Cod = n.Cod
 INNER JOIN terti t on  p.Tert=t.Tert
 INNER JOIN infotert it on it.Subunitate=t.Subunitate and t.tert=it.tert and it.Identificator=''
 WHERE     (p.Tip IN ('AC', 'AP')) AND (p.Tip_miscare NOT IN ('V')) AND (p.Jurnal <> 'MFX') AND (p.Data BETWEEN @datai AND @dataf)

	