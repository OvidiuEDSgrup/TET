--exec yso.predariPachete '5048'
CREATE PROC yso.predariPachete @cHostId char(25) AS 
--DECLARE @cHostId char(10) SET @cHostId='4468'

set @cHostId=isnull((select top 1 s.utilizator from asisria..sesiuniria s where s.token=@cHostId),@cHostId)

DECLARE @cTextSelect nvarchar(max)

IF OBJECT_ID('tempdb..#codIntrarePachete') IS NOT NULL
DROP TABLE	#codIntrarePachete

SELECT DISTINCT av.Subunitate, max(CASE av.Tip WHEN 'AP' THEN av.Contract WHEN 'TE' THEN av.Factura WHEN 'AE' THEN isnull(nullif(av.Grupa,''),av.contract) ELSE '' END) as Contract
	, max(CASE av.Tip WHEN 'AP' THEN av.Tert WHEN 'TE' THEN pc.Tert WHEN 'AE' THEN pc1.Tert ELSE av.Tert END) as Tert
	, Tip=max(av.Tip), Numar=max(av.Numar), Data=max(av.Data), av.Cod, COALESCE(pp.Cod_intrare,te.Cod_intrare, av.Cod_intrare) as cod_intrare
	, Numar_pozitie=MIN(av.Numar_pozitie)
INTO #codIntrarePachete
FROM pozdoc av
	LEFT JOIN doc d on d.Subunitate=av.Subunitate and d.Tip=av.Tip and d.Numar=av.Numar and d.Data=av.Data
	LEFT JOIN avnefac a ON a.Terminal=@cHostId AND a.Subunitate=d.Subunitate AND a.Tip=d.Tip AND a.Data=d.Data AND a.Numar=d.Numar --AND a.Cod_gestiune='' AND a.Contractul=''
	LEFT JOIN con pc ON pc.Subunitate=av.Subunitate and pc.Tip='BK' and av.Tip='TE' and pc.Contract=av.Factura
	LEFT JOIN con pc1 ON pc1.Subunitate=av.Subunitate and pc1.Tip='BK' and av.Tip='AE' and pc1.Contract=isnull(nullif(av.Grupa,''),av.contract)
	outer apply (select top (1) * from pozdoc te WHERE te.subunitate=av.Subunitate and te.tip='TE' and te.cod=av.cod and te.grupa=av.cod_intrare and te.Gestiune_primitoare=av.gestiune
		order by te.Data, te.idPozDoc) te
	left join pozdoc pp on pp.idPozDoc=av.idIntrareFirma
WHERE a.Tip IN ('AP','AC','TE','AE')
GROUP BY av.Subunitate, av.cod, COALESCE(pp.Cod_intrare,te.Cod_intrare, av.Cod_intrare)

CREATE UNIQUE NONCLUSTERED INDEX Unic ON #codIntrarePachete (Subunitate, cod, cod_intrare)
CREATE NONCLUSTERED INDEX NumarAviz ON #codIntrarePachete (Subunitate, Numar, Data)

--drop table yso.predariPacheteTmp 
IF OBJECT_ID('yso.predariPacheteTmp') IS NULL
BEGIN
	--SET @cTextSelect=''		
	CREATE TABLE yso.predariPacheteTmp 
		(Terminal char(10),
		Subunitate char(9),
		Contract char(20),
		Tert char(13),
		TipAviz char(2),
		NumarAviz char(8),
		DataAviz datetime,
		Numar_pozitieAviz int,
		CodPachet char(20),
		Cod_intrarePachet char(20),
		Tip char(2),
		Numar char(8),
		Data datetime,
		Numar_pozitie int,
		Cod_intrare char(20),
		Cantitate float,
		ordine varchar(1))
	CREATE UNIQUE NONCLUSTERED INDEX Unic ON yso.predariPacheteTmp (Terminal, Subunitate, Tip, Numar, Data, Numar_pozitie)
	CREATE NONCLUSTERED INDEX Aviz ON yso.predariPacheteTmp (Terminal, Subunitate, TipAviz, NumarAviz, DataAviz, CodPachet, Cod_intrarePachet)
	CREATE NONCLUSTERED INDEX Contract ON yso.predariPacheteTmp (Terminal, Subunitate, Contract, Tert, CodPachet)
END
-- select * from yso.predariPacheteTmp
DELETE yso.predariPacheteTmp
WHERE Terminal=@cHostId

INSERT yso.predariPacheteTmp
SELECT DISTINCT @cHostId,pa.Subunitate,pa.Contract,pa.Tert,pa.Tip,pa.Numar,pa.Data,pa.Numar_pozitie,pa.Cod
	, pa.cod_intrare,cm.Tip,cm.numar,cm.data,cm.Numar_pozitie
	, CASE pr.Valoare WHEN 'DA' THEN cm.Cod_intrare ELSE cm.Cod END 
	, cm.Cantitate, '2'
FROM pozdoc cm
	INNER JOIN pozdoc pp ON pp.Subunitate=cm.Subunitate and pp.Tip='PP' and pp.Numar=cm.Numar and pp.Data=cm.Data
	INNER JOIN #codIntrarePachete pa ON pp.Subunitate=pa.Subunitate AND pa.Cod=pp.Cod AND pa.Cod_intrare=pp.Cod_intrare
	LEFT JOIN proprietati pr on pr.Tip='NOMENCL' and pr.Cod_proprietate='ARESERII' and pr.Cod=cm.Cod and pr.Valoare='DA' and pr.Valoare_tupla=''
WHERE cm.Tip='CM'

INSERT yso.predariPacheteTmp
SELECT DISTINCT @cHostId,ap.Subunitate
	, CASE ap.Tip WHEN 'AP' THEN ap.Contract WHEN 'TE' THEN ap.Factura WHEN 'AE' THEN ISNULL(NULLIF(ap.Grupa,''),ap.[contract]) ELSE '' END 
	, CASE ap.Tip WHEN 'AP' THEN ap.Tert WHEN 'TE' THEN pc.Tert WHEN 'AE' THEN pc1.Tert ELSE ap.Tert END 
	,ap.Tip,ap.Numar,ap.Data,ap.Numar_pozitie,ap.Cod,ap.Cod_intrare,ap.Tip,ap.numar,ap.data,ap.Numar_pozitie 
	,CASE pr.Valoare WHEN 'DA' THEN ap.Cod_intrare ELSE ap.Cod END
	,Cantitate=0,'1'
--*/ select *
FROM pozdoc ap 
	INNER JOIN avnefac a ON a.Terminal=@cHostId AND a.Subunitate=ap.Subunitate AND a.Tip=ap.Tip AND a.Data=ap.Data
		AND a.Numar=ap.Numar --AND a.Cod_gestiune='' AND a.Contractul=''
	outer apply (select top (1) * from con pc where pc.Subunitate=ap.Subunitate and pc.Tip='BK' and ap.Tip='TE' and pc.Contract=ap.Factura
		order by pc.Data desc) pc
	outer apply (select top (1) * from con pc1 where pc1.Subunitate=ap.Subunitate and pc1.Tip='BK' and ap.Tip='AE' and pc1.Contract=NULLIF(ISNULL(NULLIF(ap.Grupa,''),ap.[contract]),'')
		order by pc1.data desc) pc1
	LEFT JOIN proprietati pr on pr.Tip='NOMENCL' and pr.Cod_proprietate='ARESERII' and pr.Cod=ap.Cod and pr.Valoare='DA' and pr.Valoare_tupla=''
WHERE exists (SELECT 1 FROM yso.predariPacheteTmp pp WHERE Terminal=@cHostId and pp.Subunitate=ap.Subunitate 
	and pp.NumarAviz=ap.Numar and pp.DataAviz=ap.Data and pp.Numar_pozitieAviz=ap.Numar_pozitie)--and pp.CodPachet=ap.Cod and pp.Cod_intrarePachet=ap.Cod_intrare)

--/*
INSERT yso.predariPacheteTmp
SELECT DISTINCT @cHostId,ap.Subunitate
	, CASE ap.Tip WHEN 'AP' THEN ap.Contract WHEN 'TE' THEN ap.Factura WHEN 'AE' THEN ISNULL(NULLIF(ap.Grupa,''),ap.[contract]) ELSE '' END 
	, CASE ap.Tip WHEN 'AP' THEN ap.Tert WHEN 'TE' THEN pc.Tert WHEN 'AE' THEN pc1.Tert ELSE ap.Tert END 
	,ap.Tip,ap.Numar,ap.Data,ap.Numar_pozitie,ap.Cod,ap.Cod_intrare,ap.Tip,ap.numar,ap.data,ap.Numar_pozitie 
	,(CASE pr.Valoare WHEN 'DA' THEN ap.Cod_intrare ELSE ap.Cod END)
	,ap.Cantitate, '3'
--*/ select *
FROM pozdoc ap 
	INNER JOIN avnefac a ON a.Terminal=@cHostId AND a.Subunitate=ap.Subunitate AND a.Tip=ap.Tip AND a.Data=ap.Data
		AND a.Numar=ap.Numar --AND a.Cod_gestiune='' AND a.Contractul=''
	outer apply (select top (1) * from con pc where pc.Subunitate=ap.Subunitate and pc.Tip='BK' and ap.Tip='TE' and pc.Contract=ap.Factura
		order by pc.Data desc) pc
	outer apply (select top (1) * from con pc1 where pc1.Subunitate=ap.Subunitate and pc1.Tip='BK' and ap.Tip='AE' and pc1.Contract=NULLIF(ISNULL(NULLIF(ap.Grupa,''),ap.[contract]),'')
		order by pc1.data desc) pc1
	LEFT JOIN proprietati pr on pr.Tip='NOMENCL' and pr.Cod_proprietate='ARESERII' and pr.Cod=ap.Cod and pr.Valoare='DA' and pr.Valoare_tupla=''
WHERE NOT exists (SELECT 1 FROM yso.predariPacheteTmp pp WHERE Terminal=@cHostId and pp.Subunitate=ap.Subunitate 
	and pp.NumarAviz=ap.Numar and pp.DataAviz=ap.Data and pp.Numar_pozitieAviz=ap.Numar_pozitie)
	--and pp.CodPachet=ap.Cod and pp.Cod_intrarePachet=ap.Cod_intrare)

select * from yso.predariPacheteTmp where Terminal=@cHostId


