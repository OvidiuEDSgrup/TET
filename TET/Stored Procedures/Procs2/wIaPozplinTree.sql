
--***
CREATE PROCEDURE wIaPozplinTree @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @userASiS VARCHAR(10), @lista_lm BIT, @lista_conturi BIT, @DecGrCont INT, @CtAvFurn VARCHAR(40), @CtAvBen VARCHAR(40), @subunitate CHAR(9), @Bugetari INT, 
	@tip VARCHAR(2), @cont VARCHAR(40), @data DATETIME, @cautare VARCHAR(50), @marca VARCHAR(6), @decont VARCHAR(40), @tert CHAR(13), @efect VARCHAR(20), 
	@numere_pozitii VARCHAR(max), @areDetalii BIT, @tipefect varchar(1)

--select @userASiS=id from utilizatori where observatii=SUSER_NAME()
/*Modificare pentru login utilizator sa */
EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @userASiS OUTPUT

SELECT @lista_lm = dbo.f_arelmfiltru(@userASiS), @lista_conturi = 0
EXEC luare_date_par 'GE','BUGETARI',@bugetari output,0,''

SELECT @lista_conturi = 1
FROM proprietati
WHERE tip = 'UTILIZATOR'
	AND cod = @userASiS
	AND cod_proprietate='CONTPLIN'
	AND valoare <> ''

EXEC luare_date_par 'GE', 'DECMARCT', @DecGrCont OUTPUT, 0, ''

EXEC luare_date_par 'GE', 'CFURNAV', 0, 0, @CtAvFurn OUTPUT

EXEC luare_date_par 'GE', 'CBENEFAV', 0, 0, @CtAvBen OUTPUT

IF @CtAvFurn = ''
	SET @CtAvFurn = '409'

IF @CtAvBen = ''
	SET @CtAvBen = '419'

SELECT @subunitate = ISNULL(@parXML.value('(/row/@subunitate)[1]', 'varchar(9)'), '1'), 
	@tip = ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
	@cont = ISNULL(@parXML.value('(/row/@cont)[1]', 'varchar(40)'), ''), 
	@data = ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '01/01/1901'), 
	@marca = ISNULL(@parXML.value('(/row/@marca)[1]', 'varchar(6)'), ''), 
	@decont = ISNULL(@parXML.value('(/row/@decont)[1]', 'varchar(40)'), ''), 
	@tert = ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), ''), 
	@tipefect = ISNULL(@parXML.value('(/row/@tipefect)[1]','varchar(1)'), ''), 
	@efect = ISNULL(@parXML.value('(/row/@efect)[1]','varchar(20)'), ''), 
	@numere_pozitii = ISNULL(@parXML.value('(/row/@numerepozitii)[1]', 'varchar(max)'), ''), 
	@cautare = ISNULL(@parXML.value('(/row/@_cautare)[1]', 'varchar(100)'), '')

IF OBJECT_ID('tempdb..#wPozPlin') IS NOT NULL
	DROP TABLE #wPozPlin

SELECT rtrim(p.subunitate) AS subunitate, @tip AS tip, rtrim(p.cont) AS cont, rtrim(isnull(ca.denumire_cont, '')) AS dencont, 
	convert(CHAR(10), p.data, 101) AS data, 
	ISNULL(NULLIF(p.subtip,''),
		(CASE WHEN @tip in ('RE' ,'RV')
				AND ISNULL(cc.Sold_credit, 0) = 9 AND p.Plata_incasare = 'PD' THEN 'PA' 
				WHEN @tip = 'RE' AND ISNULL(cc.Sold_credit, 0) = 9 AND p.Plata_incasare = 'ID' THEN 'IA' 
				WHEN @tip = 'RE' AND ISNULL(cc.Sold_credit, 0) = 8 AND p.Plata_incasare = 'PD' THEN 'PE' 
				WHEN @tip = 'RE' AND ISNULL(cc.Sold_credit, 0) = 8 AND p.Plata_incasare = 'ID' THEN 'IE' 
				WHEN p.plata_incasare = 'PF' AND p.valuta <> '' THEN 'PV' 
				WHEN @tip = 'DE' AND p.plata_incasare = 'PD' AND p.valuta <> '' THEN 'PG' 
				WHEN @tip = 'DE' AND p.plata_incasare = 'PC' AND p.valuta <> '' THEN 'PT' 
				WHEN p.plata_incasare = 'IB' AND p.valuta <> '' THEN 'IV' 
				WHEN p.plata_incasare = 'PF' AND left(p.explicatii,2)='PX' THEN 'PX' 
				WHEN p.plata_incasare = 'IB' AND left(p.explicatii,2)='IX' THEN 'IX' 
				ELSE p.plata_incasare END)) AS subtip, 
	rtrim(p.numar) AS numar, p.plata_incasare AS plataincasare, rtrim(p.tert) AS tert, rtrim(isnull(t.denumire, '')) AS dentert, 
	rtrim(p.factura) AS factura, rtrim(p.cont_corespondent) AS contcorespondent, rtrim(isnull(cc.Denumire_cont, '')) AS dencontcorespondent, 
	convert(DECIMAL(15, 2), p.suma) AS suma, 
	convert(DECIMAL(15, 2), CASE WHEN p.plata_incasare like 'I%' then p.suma else 0 end) as incasari, convert(DECIMAL(15, 2), CASE WHEN p.plata_incasare like 'P%' then p.suma else 0 end) as plati, 
	rtrim(p.valuta) AS valuta, rtrim(isnull(v.denumire_valuta, '')) AS denvaluta, 
	convert(DECIMAL(10, 4), p.curs) AS curs, 
	convert(DECIMAL(15, 2), p.suma_valuta) AS sumavaluta, 
	convert(DECIMAL(15, 2), CASE WHEN p.plata_incasare like 'I%' then p.suma_valuta else 0 end) as incasarivaluta, convert(DECIMAL(15, 2), CASE WHEN p.plata_incasare like 'P%' then p.suma_valuta else 0 end) as plativaluta, 
	convert(varchar(3), p.TVA11) AS cotatva, convert(DECIMAL(15, 2), p.TVA22) AS sumatva, rtrim(p.explicatii) AS explicatii, 
	rtrim(p.loc_de_munca) AS lm, rtrim(left(p.comanda, 20)) AS comanda, -->comanda este stocata in primele 20 de caractere ale campului comanda
	space(20) AS indbug, 
	rtrim(isnull(l.Denumire, '')) AS denlm, rtrim(isnull(co.Descriere, '')) AS dencomanda, p.numar_pozitie AS numarpozitie, 
	(CASE WHEN isnull(ca.sold_credit, 0) IN (9) 
				OR isnull(cc.sold_credit, 0) IN (8, 9)
				OR p.valuta = '' THEN '' ELSE p.cont_dif END) AS contdifcurs, rtrim(isnull(cd.denumire_cont, '')) AS dencontdifcurs, 
	(CASE WHEN isnull(ca.sold_credit, 0) IN (9)
				OR isnull(cc.sold_credit, 0) IN (8, 9)
				OR p.valuta = '' THEN 0 ELSE convert(DECIMAL(15, 2), p.suma_dif) END) AS sumadifcurs, 
	rtrim(p.jurnal) AS jurnal, 
-->	mai jos am lasat Null la marca, decont, efect	
	rtrim(CASE WHEN isnull(ca.sold_credit, 0) = 9
				OR isnull(cc.sold_credit, 0) = 9 THEN p.marca /*ELSE ''*/ END) AS marca, rtrim(isnull(pers.nume, '')) AS denmarca, 
	rtrim(CASE WHEN isnull(ca.sold_credit, 0) = 9 AND @DecGrCont = 1 THEN p.cont 
				WHEN isnull(cc.sold_credit, 0) = 9 AND @DecGrCont = 1 THEN p.cont_corespondent 
				WHEN isnull(ca.sold_credit, 0) = 9 OR isnull(cc.sold_credit, 0) = 9 THEN p.decont /*ELSE ''*/ END) AS decont, 
	rtrim(CASE WHEN isnull(ca.sold_credit, 0) = 8
				OR isnull(cc.sold_credit, 0) = 8 THEN p.efect /*ELSE ''*/ END) AS efect, 
	isnull(convert(CHAR(10), p.detalii.value('(/row/@datascad)[1]','datetime'), 101), '01/01/1901') AS datascadentei,
	--data la care beneficiarul a facut plata,(se ia in calcul la calculul penalitatilor), dc nu este specificata se ia data din pozplin
/*		isnull(isnull(convert(CHAR(10), e.Data_document, 101), convert(CHAR(10), p.data, 101)), '01/01/1901') AS ext_datadocument, 
	isnull(e.Cont_in_banca, '') AS ext_cont_in_banca, rtrim(isnull(e.Serie_CEC,'')) as ext_serie_CEC, rtrim(isnull(e.Numar_CEC,'')) as ext_numar_CEC,
	rtrim(isnull(e.Cont_in_banca_tert,'')) as ext_cont_in_banca_tert, rtrim(ISNULL(e.Banca_tert,'')) as ext_banca_tert, */
	rtrim(ISNULL(ban.Denumire,''))+' - ' +rtrim(ISNULL(ban.filiala,'')) as denbancatert,
	rtrim(p.utilizator) as utilizator, convert (char(10),p.data_operarii,103) as data_operarii, 
	(CASE WHEN p.plata_incasare IN ('IC', 'PC') THEN convert(VARCHAR, p.tip_tva) 
			ELSE '' END) AS tipTVA, 
	(CASE WHEN p.plata_incasare = 'PC' AND p.tip_tva = 0 THEN '0-TVA Deductibil' 
				WHEN p.plata_incasare = 'PC' AND p.tip_tva = 1 THEN '1-TVA Compensat' 
				WHEN p.plata_incasare = 'PC' AND p.tip_tva = 2 THEN '2-TVA Nedeductibil' 
				WHEN p.plata_incasare = 'IC' AND p.tip_tva = 0 THEN '0-TVA Colectat' 
				WHEN p.plata_incasare = 'IC' AND p.tip_tva = 1 THEN '1-TVA Compensat' 
				WHEN p.plata_incasare = 'IC' AND p.tip_tva = 2 THEN '2-TVA Neinregistrat' ELSE '' END) AS denTiptva, 
	(CASE WHEN p.Plata_incasare IN ('PF', 'IB', 'IS', 'PS')
				AND p.Cont_corespondent IN (@CtAvFurn, @CtAvBen)
				AND p.Factura = ''
				OR ca.Cont IS NULL
				OR ISNULL(ca.are_analitice, 0) = 1
				OR cc.Cont IS NULL
				OR ISNULL(cc.are_analitice, 0) = 1 THEN '#FF0000' ELSE '#000000' END) AS culoare,
	p.idPozPlin,
	rank() OVER (PARTITION BY p.plata_incasare,p.numar,p.tert ORDER BY p.numar_pozitie) rk, 1 AS pozitii
INTO #wPozPlin
FROM pozplin p
	LEFT OUTER JOIN lm l ON p.Loc_de_munca = l.Cod
	LEFT OUTER JOIN comenzi co ON co.subunitate = p.subunitate
		AND co.Comanda = p.Comanda
	LEFT OUTER JOIN conturi ca ON ca.subunitate = p.subunitate
		AND ca.cont = p.cont
	LEFT OUTER JOIN conturi cc ON cc.subunitate = p.subunitate
		AND cc.cont = p.cont_corespondent
	LEFT OUTER JOIN conturi cd ON isnull(ca.sold_credit, 0) NOT IN (9)
		AND isnull(cc.sold_credit, 0) NOT IN (8, 9)
		AND p.valuta <> ''
		AND cd.subunitate = p.subunitate
		AND cd.cont = p.cont_dif
	LEFT OUTER JOIN personal pers ON (isnull(ca.sold_credit, 0) = 9
			OR isnull(cc.sold_credit, 0) = 9)
		AND pers.marca = p.marca
	LEFT OUTER JOIN terti t ON t.subunitate = p.subunitate
		AND t.tert = p.tert 
	LEFT OUTER JOIN valuta v ON v.valuta = p.valuta
	LEFT OUTER JOIN bancibnr ban on p.detalii.value('(/row/@bancatert)[1]','varchar(20)')= ban.Cod
WHERE p.subunitate = @subunitate
	AND (
		p.Numar LIKE @cautare + '%'
		OR p.Cont_corespondent LIKE @cautare + '%'
		OR ISNULL(@cautare, '') = ''
		)
	/* (oarecare) reduntanta intre tip si cont (ca tip vine din cont...)*/
	--and @tip=(case isnull(ca.sold_credit, 0) when 9 then 'DE' when 8 then 'EF' else 'RE' end)
	AND (
		isnull(ca.sold_credit, 0) = 9
		AND @tip IN ('DE', 'DR')
		OR /*isnull(ca.sold_credit, 0) = 8
		AND*/ @tip = 'EF'
		OR isnull(ca.sold_credit, 0) NOT IN (9)--, 8)
		AND @tip in ('RE' ,'RV')
		)
	AND p.cont = @cont
	AND p.data = @data	
		
	AND (
		(@tip in ('RE' ,'RV', 'DR') 
		OR @tip = 'DE'
			AND p.marca = @marca
			AND (CASE WHEN @DecGrCont = 1 THEN p.cont ELSE p.decont END) = @decont)
		OR @tip = 'EF'
			AND p.tert = @tert
			--and LEFT(p.Plata_incasare,1)=@tipefect
			AND rtrim(ltrim(p.efect)) = ltrim(rtrim(@efect))
		)
	AND (
		isnull(@numere_pozitii, '') = ''
		OR charindex(';' + ltrim(str(p.numar_pozitie)) + ';', ';' + @numere_pozitii + ';') > 0
		)
	AND (
		@lista_lm = 0
		OR EXISTS (
			select 1
			from lmfiltrare lu
			where lu.utilizator=@userASiS
				and lu.cod=p.loc_de_munca
			)
		)
	AND (
		@lista_conturi = 0
		OR EXISTS (
			SELECT 1
			FROM proprietati lc
			WHERE RTrim(p.cont) LIKE RTrim(lc.valoare) + '%'
				AND lc.tip = 'UTILIZATOR'
				AND lc.cod = @userASiS
				AND lc.cod_proprietate = 'CONTPLIN'
			)
		)
ORDER BY p.numar_pozitie DESC


IF EXISTS (
		SELECT 1
		FROM syscolumns sc, sysobjects so
		WHERE so.id = sc.id
			AND so.NAME = 'pozplin'
			AND sc.NAME = 'detalii'
		)
BEGIN
	SET @areDetalii = 1

	ALTER TABLE #wPozPlin ADD detalii XML

	UPDATE #wPozPlin
	SET detalii = pl.detalii
	FROM pozplin pl
	WHERE #wPozPlin.idPozplin = pl.idPozplin
END
ELSE
	SET @areDetalii = 0

IF @Bugetari=1 and exists (select * from sysobjects where name ='indbugPozitieDocument' and xtype='P')
BEGIN
	SELECT '' as furn_benef, 'pozplin' as tabela, idPozPlin as idPozitieDoc, indbug into #indbugPozitieDoc 
	FROM #wPozPlin
	EXEC indbugPozitieDocument @sesiune=@sesiune, @parXML=@parXML
	UPDATE p set p.indbug=ib.indbug
	FROM #wPozPlin p
		left outer join #indbugPozitieDoc ib on ib.idPozitieDoc=p.idPozPlin
END

UPDATE p
	SET pozitii = ISNULL(pc.nrpoz,0) 
from #wPozPlin p
outer apply (select max(pc.rk) nrpoz from #wPozPlin pc where pc.subtip=p.subtip and pc.numar = p.numar and pc.plataincasare=p.plataincasare) pc
--where p.rk = 1


declare @docXML xml
set @docXML = (
	SELECT max(numarpozitie) numarpozitie, 
	poz.tip,
	(CASE WHEN poz.pozitii > 1 THEN '<'+subtip+'>' else subtip end) subtip, 
	numar, plataincasare, tert, max(dentert) dentert, 
	(CASE WHEN poz.pozitii = 1 THEN max(factura) END) factura, 
	(CASE WHEN poz.pozitii = 1 THEN max(contcorespondent) END) contcorespondent, 
	(CASE WHEN poz.pozitii = 1 THEN max(dencontcorespondent) END) dencontcorespondent, 
	sum(suma) suma, sum(incasari) incasari, sum(plati) plati, 
	/*valuta, denvaluta, curs,*/ 
	(CASE WHEN poz.pozitii = 1 THEN sum(sumavaluta) END) sumavaluta, 
	/*incasarivaluta, plativaluta, */
	(CASE WHEN poz.pozitii = 1 THEN max(cotatva) END) cotatva, 
	(CASE WHEN poz.pozitii = 1 THEN sum(sumatva) END) sumatva, 
	(CASE WHEN poz.pozitii = 1 THEN rtrim(max(poz.explicatii)) END) explicatii,  
	(CASE WHEN poz.pozitii = 1 THEN max(lm) END) lm, 
	(CASE WHEN poz.pozitii = 1 THEN max(comanda) END) comanda, 
	--indbug, 
	(CASE WHEN poz.pozitii = 1 THEN max(denlm) END) denlm, 
	(CASE WHEN poz.pozitii = 1 THEN max(dencomanda) END) dencomanda, 
	(CASE WHEN poz.pozitii = 1 THEN max(contdifcurs) END) contdifcurs, 
	(CASE WHEN poz.pozitii = 1 THEN max(dencontdifcurs) END) dencontdifcurs, 
	(CASE WHEN poz.pozitii = 1 THEN max(sumadifcurs) END) sumadifcurs, 
	/*jurnal, 
	marca, denmarca, 
	decont, 
	efect, 
	datascadentei,
	denbancatert,
	utilizator, data_operarii,*/ 
	(CASE WHEN poz.pozitii = 1 THEN max(tipTVA) END) tipTVA, 
	(CASE WHEN poz.pozitii = 1 THEN max(denTiptva) END) denTiptva, 
	(CASE WHEN poz.pozitii = 1 THEN max(idPozPlin) END) idPozPlin, 
	--culoare,
	(
		SELECT 
			tip,
			subtip, 
			numar, 
			plataincasare, 
			tert, 
			dentert, 
			factura, contcorespondent, dencontcorespondent, 
			suma, incasari, plati, 
			valuta, denvaluta, curs, sumavaluta, incasarivaluta, plativaluta, 
			cotatva, sumatva, explicatii, 
			lm, comanda, indbug, 
			denlm, dencomanda, numarpozitie, 
			contdifcurs, dencontdifcurs, 
			sumadifcurs, 
			jurnal, 
			marca, denmarca, 
			decont, 
			efect, 
			datascadentei,
			denbancatert,
			utilizator, data_operarii, 
			tipTVA, 
			denTiptva, 
			(case when poz.pozitii=1 then culoare else '#0000FF' end) culoare, 
			idPozPlin,
			detalii
		FROM #wPozPlin det
		WHERE det.subtip=poz.subtip and det.numar = poz.numar and det.plataincasare=poz.plataincasare and det.tert=poz.tert 
			AND (poz.pozitii > 1 or poz.pozitii = 1 AND det.rk > 1)
		--order by 3, art.idPozContract
		FOR XML raw,type
	)
	FROM #wPozPlin poz
	--WHERE poz.rk = 1
	GROUP BY tip, subtip, numar, plataincasare, tert, pozitii
	order by 1 desc
FOR XML raw,
	root('Ierarhie')
			)

--IF @docXML IS NOT NULL
	--SET @docXML.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')

SELECT @docXML
FOR XML path('Date')

SELECT '1' AS areDetaliiXml
FOR XML raw, root('Mesaje')
