SELECT TOP 100 
	ct.idContract idContract, 
	rtrim(ct.tip) AS tip, 
	rtrim(ct.numar) AS numar, 
	convert(VARCHAR(10), ct.data, 101) data, 
	rtrim(ct.tert) AS tert, 
	rtrim(t.denumire) AS dentert, 
	rtrim(ct.punct_livrare) AS punct_livrare, 
	rtrim(it.Descriere) AS denpunct_livrare, 
	rtrim(gestiune) AS gestiune, 
	rtrim(gest.denumire_gestiune) AS dengestiune, 
	rtrim(ct.gestiune_primitoare) AS gestiune_primitoare, 
	rtrim(gestPrim.denumire_gestiune) AS dengestiune_primitoare, 
	rtrim(ct.loc_de_munca) AS lm, 
	rtrim(lm.denumire) AS denlm, 
	rtrim(ct.valuta) AS valuta, 
	rtrim(isnull(isnull(v.Denumire_valuta,ct.valuta),'RON')) AS denvaluta, 
	convert(DECIMAL(15, 4), ct.curs) AS curs, 
	convert(VARCHAR(10), ct.valabilitate, 101) valabilitate, 
	rtrim(ct.explicatii) AS explicatii, 
	pozitii.nr AS pozitii, 
	rtrim(st.stare) AS stare, 
	ct.detalii AS detalii, 
	st.culoare AS culoare, 
	rtrim(st.denstare) AS denstare, 
	convert(DECIMAL(15, 2), pozitii.valoare) AS valoare,
	convert(DECIMAL(15, 2), pozitii.valoare*(case when isnull(ct.valuta,'')<>'' then ct.curs else 1 end)) AS valoareRON,
	cc.idContract as idContractCorespondent,
	cc.dencontract as denidContractCorespondent,
	convert(DECIMAL(15, 2), pozitii.valoarecutva*1.24) AS valoarecutva
FROM Contracte ct
left outer join @GestiuniUser gu on gu.valoare=ct.gestiune
LEFT JOIN terti t ON t.tert = ct.tert AND t.subunitate=@sub
LEFT JOIN infotert it ON it.subunitate = t.subunitate AND it.tert = t.tert AND ct.punct_livrare = it.Identificator
LEFT JOIN gestiuni gest ON gest.cod_gestiune = ct.gestiune and gest.subunitate = @sub
LEFT JOIN gestiuni gestPrim ON gestPrim.cod_gestiune = ct.gestiune_primitoare and gestPrim.Subunitate = @sub
LEFT JOIN lm ON lm.cod = ct.loc_de_munca
LEFT JOIN valuta v ON v.Valuta = ct.valuta
OUTER APPLY (select idContract, cc.numar+'-'+convert(char(10),cc.data,103) dencontract from contracte cc where ct.idContractCorespondent = cc.idContract) cc
OUTER APPLY 
(
	SELECT 
		isnull(count(1), 0) nr, sum(cantitate * (pret*(1.00-ISNULL(p.discount,0)/100.00))) AS valoare, sum(cantitate * (pret*(1.00-ISNULL(p.discount,0)/100.00))) AS valoarecutva
	FROM PozContracte p
	where p.idContract=ct.idContract
) pozitii 
CROSS APPLY 
(
	select top 1 j.stare stare, s.denumire denstare, s.culoare culoare from JurnalContracte j JOIN StariContracte s on j.stare=s.stare and s.tipContract=ct.tip and j.idContract=ct.idContract order by j.data desc
) st
WHERE (@idContract IS NULL OR ct.idContract = @idContract)
	AND ct.data BETWEEN @f_datajos AND @f_datasus
	AND (@f_numar IS NULL OR ct.numar LIKE @f_numar)
	AND (@f_gestiune IS NULL OR ct.gestiune LIKE @f_gestiune)
	AND (@f_dengestiune IS NULL OR gest.denumire_gestiune LIKE @f_dengestiune)
	AND (@f_gestiune_primitoare IS NULL OR ct.gestiune_primitoare LIKE @f_gestiune_primitoare)
	AND (@f_dengestiune_primitoare IS NULL OR gestPrim.denumire_gestiune LIKE @f_dengestiune_primitoare)
	AND (@f_tert IS NULL OR ct.tert LIKE @f_tert)
	AND (@f_dentert IS NULL OR t.tert+t.denumire LIKE @f_dentert)
	AND (@f_lm IS NULL OR ct.loc_de_munca LIKE @f_lm)
	AND (@f_denlm IS NULL OR lm.denumire LIKE @f_denlm)
	AND (@tip IS NULL OR ct.tip = @tip)
	AND (@f_stare IS NULL OR st.denstare LIKE @f_stare)
	AND (@idContractCorespondent=0 or ct.idContractCorespondent=@idContractCorespondent)
	and (@lista_lm=0 or ct.Loc_de_munca IS null or ct.Loc_de_munca is not null and exists (select 1 from lmfiltrare lu where lu.utilizator=@utilizator and lu.cod=ct.Loc_de_munca))
	and (@lista_gestiuni=0 or gu.valoare is not null)
	and (@areFiltruClient=0 or exists (select * from @clienti c where c.tert=ct.tert))
order by ct.data desc,idContract desc
FOR XML raw, root('Date')

