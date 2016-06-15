CREATE VIEW yso_vIaNomencl AS
SELECT --rtrim(n.cod) as _cheieunica
		rtrim(n.cod) as cod
		,rtrim(n.loc_de_munca) as note
		,rtrim(n.denumire) as denumire
		,n.tip
		, dbo.denTipNomenclator(n.tip) as dentip
		,rtrim(n.grupa) as grupa
		, rtrim(isnull(grupe.Denumire,n.grupa)) as dengrupa
		,rtrim(n.um) as um,isnull(RTRIM(um.Denumire),'') as denum,
		RTRIM(n.Furnizor) as furnizor, isnull(rtrim(terti.Denumire),'') as denfurnizor
		, rtrim(n.Tip_echipament) as codvamal, isnull(rtrim(codvama.denumire),'') as dencodvamal,
		convert(decimal(17,5),n.pret_cu_amanuntul) as pret,
		convert(decimal(17,5),n.pret_stoc) as pret_stocn,
		convert(decimal(12,3),isnull(isnull(pretCat.Pret_vanzare, isnull(PretImplicit.Pret_vanzare, n.Pret_vanzare)), 0)) as pretvanzare,
		convert(decimal(17,5),n.Pret_vanzare) as pretvanznom,
		rtrim(n.cont) as cont,rtrim(n.cont)+'-'+RTRIM(ISNULL(conturi.denumire_cont,'')) as dencont
		,n.cota_tva as cotatva,
		pozeria.fisier as poza, --rog lasati fara isnull
		(select top 1 rtrim(Cod_de_bare) from codbare where Cod_produs=n.cod) as codbare
		,CONVERT(decimal(15,3),n.greutate_specifica) greutate
		--,CONVERT(nvarchar(500),'') as _eroareimport		
	from nomencl n 
		left outer join grupe on n.grupa=grupe.grupa
		left outer join conturi on conturi.Subunitate = '1' and conturi.Cont = n.cont
		left outer join terti on terti.Subunitate = '1' and terti.tert = n.furnizor
		left outer join um on n.um=um.UM
		left join preturi pretCat on pretCat.Cod_produs=n.Cod and pretCat.um=4 and pretCat.Tip_pret=1 and pretCat.Data_superioara='2999-01-01' 
		left join preturi PretImplicit on PretImplicit.Cod_produs=n.Cod and PretImplicit.um=1 and PretImplicit.Tip_pret=1 and PretImplicit.Data_superioara='2999-01-01' 
		left outer join PozeRIA on pozeria.tip='N' and pozeria.cod=n.cod
		left outer join codvama on n.Tip_echipament=codvama.Cod
