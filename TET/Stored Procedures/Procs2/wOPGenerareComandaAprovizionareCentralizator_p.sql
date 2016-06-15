CREATE procedure wOPGenerareComandaAprovizionareCentralizator_p @sesiune varchar(50), @parXML xml
as
BEGIN TRY
	declare
		@cod_furnizor varchar(20), @utilizator varchar(100),@cSubunitate varchar(20), @mesaj varchar(200), @formular varchar(50), @denformular varchar(200)

	select top 1 @cSubunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	select
		@cod_furnizor=ISNULL(@parXML.value('(/*/@cod_furnizor)[1]','varchar(20)'),'')

	-- Aduc default, pentru populare combo, primul formular de aprovizionare gasit
	select top 1
		@formular = rtrim(Numar_formular),
		@denformular = rtrim(Denumire_formular)
	from antform
	where denumire_formular like '%aprovizionare%'

	/** Prefiltram toate inregistrarile pt acest cod de furnizor din tabelul de calcul intr-unul tmp  */
	select a.*
	into #ac1
	from tmpArticoleCentralizator a
	where
		(@cod_furnizor='' OR a.furnizor=@cod_furnizor) and a.utilizator=@utilizator

	/** Populare antet -> doar furnizor momentan **/
	select
		 max(rtrim(t.denumire)) furnizor, convert(decimal(15,2),SUM(decomandat*pret)) valoare,
		 @formular as formular, @denformular as denformular
	from terti t
	JOIN #ac1 a on t.tert=a.furnizor and t.tert=@cod_furnizor
	for xml RAW, root('Date')

	if not exists(select 1 from #ac1 where decomandat<>0)
		raiserror('Nu sunt produse de comandat!',11,1)

	select
		(
			select
				ISNULL(c.numar, pl.cod) comanda,
				RTRIM(isnull(t.denumire,l.denumire)) dentert,
				convert(decimal(15,5),ISNULL(tp.cantitate-ISNULL(tp.cant_aprovizionare,0), a.decomandat)) cantitate,
				a.cod cod,	RTRIM(n.denumire) dencod,
				tp.idPozLansare,
				CONVERT(decimal(15,5),a.pret) pret,
				a.cod_specific cod_specific,
				tp.idPozContract idPozContractCoresp,
				convert(varchar(10),pc.termen,101) termen,
				(case	when tp.idPozLansare is not null then 'Comanda prod.'
						when tp.idPozLansare is null and tp.idPozContract is null then 'Stoc'
						when tp.idPozContract is not null and c.tip='CL' then 'Comanda livr.'
						when tp.idPozContract is not null AND c.tip='RN' then 'Referat'
				else '' end) tip_aprovizionare
			from #ac1 a
			INNER JOIN tmpPozArticoleCentralizator tp on tp.cod=a.cod and tp.utilizator=@utilizator
			LEFT JOIN PozLansari pozL on pozL.id=tp.idPozLansare
			LEFT JOIN pozLansari pl on pl.tip='L' and pl.id=pozL.parinteTop
			LEFT JOIN comenzi com on pl.cod=com.comanda
			LEFT JOIN pozContracte pc on pc.idPozContract=tp.idPozContract
			LEFT JOIN Contracte c on c.idContract=pc.idContract
			LEFT JOIN terti t on (t.tert=com.Beneficiar OR t.tert=c.tert)
			LEFT JOIN nomencl n ON n.cod=a.cod
			LEFT JOIN lm l on l.cod=c.loc_de_munca
			where a.decomandat>0.001
			ORDER by a.decomandat desc,a.cod, pl.cod
			for XML RAW, TYPE
		)
	FOR XML path('DateGrid'), root('Mesaje')
END TRY

BEGIN CATCH
	SET @mesaj = '(wOPGenerareComandaAprovizionareCentralizator_p) '+ERROR_MESSAGE()
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	RAISERROR (@mesaj, 11, 1)
END CATCH
