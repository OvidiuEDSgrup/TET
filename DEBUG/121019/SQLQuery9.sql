select 
	(case when b.tip in ('11','21') and b.cod_produs<>'' then 0 else 1 end) as incasare ,
	b.numar_linie,
	cod_produs=rtrim(b.cod_produs),
	(CASE WHEN 0 = 1 AND left(isnull(n.UM_2, ''), 1) = 'Y' THEN 1 ELSE 0 END) AS areSerii,
	rtrim(b.numar_document_incasare) AS serie,
	(CASE b.um WHEN 2 THEN isnull(n.coeficient_conversie_1, 0) WHEN 3 THEN isnull(n.coeficient_conversie_2, 0) ELSE 1 END) AS coef_conv,
	b.total,
	b.cantitate,
	b.cota_tva,
	b.tva,
	b.pret,
	b.discount,
	b.codplu,
	isnull(n.tip, '') tipnomencl,
	rtrim(isnull(b.lm_real, isnull(a.Loc_de_munca, isnull(gestcor.loc_de_munca, '')))) lm,
	rtrim(isnull(b.Comanda_asis, isnull(a.comanda, ''))) comanda_asis,
	rtrim(isnull(b.[contract], isnull(a.contract, ''))) [contract],
	b.tip,
	-- tipul de TVA conteaza doar la tertii platitori de TVA, si depinde de marcajul din Nomenclator
	(CASE WHEN 0=0 THEN 0 ELSE convert(INT, left(n.tip_echipament, 1)) END) AS tipTVA,
	rtrim(b.Gestiune) as gestiune_pozitie
from bt b
inner join antetBonuri a on a.idAntetBon=b.idAntetBon
left outer join gestcor on gestcor.gestiune=b.Gestiune
left outer join nomencl n on n.cod=b.cod_produs
where a.idAntetBon=1440 