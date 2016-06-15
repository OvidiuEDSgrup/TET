--***
CREATE PROCEDURE yso_wOPGolireGestPrinTEStorno_p @sesiune VARCHAR(50), @parXML XML 
AS  
BEGIN TRY
	DECLARE /*date de identificare document:*/@sub VARCHAR(9),@tip VARCHAR(2),@data DATETIME,@contract VARCHAR(20),@numar VARCHAR(13),
		/*alte variabile necesare:*/@utilizator VARCHAR(20), @eroare VARCHAR(250),@factura VARCHAR(20),@numardoc VARCHAR(8),
		@NrAvizeUnitar INT, @lm VARCHAR(13),@idPozDoc INT, @gestiune varchar(20), @gestprim varchar(20)
		, @dengestiune varchar(200), @dengestprim varchar(200)

	SELECT
		--date pt identificare document care se storneaza 
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), GETDATE()),
		@numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(8)'), ''),
		@factura=ISNULL(@parXML.value('(/row/@factura)[1]', 'varchar(20)'), ''),
		@idPozDoc=ISNULL(@parXML.value('(/row/@idPozDoc)[1]', 'INT'), ''),
		@lm=ISNULL(@parXML.value('(/row/@lm)[1]', 'varchar(13)'), '')
		,@gestiune=ISNULL(@parXML.value('(/row/@gestiune)[1]', 'varchar(20)'),'' )
		,@gestprim=ISNULL(@parXML.value('(/row/@gestprim)[1]', 'varchar(20)'), '')
	
		

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT-->identificare utilizator pe baza sesiunii
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub OUTPUT --> citire subunitate din proprietati    

	if ISNULL(@gestprim,'')=''
		select top 1 @gestprim=valoare from proprietati r where r.Tip='UTILIZATOR' AND r.Cod_proprietate='GESTREZBK' and r.cod=@utilizator 
			and r.Valoare<>'' and r.Valoare_tupla=''
	if ISNULL(@gestprim,'')=''
		set @gestprim='700'		
	set @dengestprim=ISNULL((select top 1 rtrim(g.Denumire_gestiune) from gestiuni g where g.Cod_gestiune=@gestprim),@gestprim)
			
	set @numardoc=@numar
	SELECT @numardoc AS numardoc, CONVERT(CHAR(10),@data,101) AS datadoc, @gestprim as gestprim, @dengestprim as dengestprim
	,@gestiune as gestiune, @dengestiune as dengestiune
	FOR XML RAW, ROOT('Date')

	if OBJECT_ID('tempdb..#pozitiiDoc') is not null
		drop table #pozitiiDoc

	SELECT RTRIM(s.subunitate) AS subunitate
		,rtrim(s.Tip_gestiune) AS tip
		,RTRIM(s.Cod_gestiune) as gestiune
		,RTRIM(s.cod) AS cod
		,RTRIM(s.Cod_intrare) AS codintrare
		,RTRIM(n.Denumire) AS dencod
		,CONVERT(CHAR(10),s.data,101) AS data
		,RTRIM(s.Loc_de_munca) AS lm
		,RTRIM(lm.Denumire) AS denlm
		,RTRIM(s.Comanda) AS comanda
		,RTRIM(c.Descriere) AS dencomanda
		,RTRIM(s.Contract) AS contract
		,RTRIM(s.Locatie) AS locatie
		,RTRIM(pd.gestiune) AS gestsursa
		,RTRIM(g.Denumire_gestiune) AS dengestsursa
		,RTRIM(pd.numar) AS numar
		,RTRIM(isnull(pd.Numar_pozitie,0)) AS numar_pozitie
		,CONVERT(int,isnull(pd.idpozdoc,0)) as idpozdoc
		,CONVERT(DECIMAL(17,5),pd.Cantitate) AS cant_transferata
		,CONVERT(DECIMAL(17,5),s.Stoc) AS cant_storno
		,CONVERT(DECIMAL(17,3), s.Stoc) AS cant_disponibila--cantitatea maxima care poate fi stornata
		,CONVERT(DECIMAL(17, 5), s.pret_vanzare) AS pvanzare   
		,CONVERT(DECIMAL(17, 3), s.Stoc*s.Pret_vanzare) AS valvanzare
		,CONVERT(DECIMAL(17, 3), s.Stoc*s.Pret) AS valstoc 
		,CONVERT(DECIMAL(17, 5), s.Pret) AS pstoc
		,CONVERT(DECIMAL(17, 5), s.pret_cu_amanuntul) AS pamanunt
		,CONVERT(DECIMAL(17, 3), s.Stoc*s.Pret_cu_amanuntul) AS valamanunt
		,CONVERT(DECIMAL(5, 2), s.TVA_neexigibil) AS cotatva   
	INTO #pozitiiDoc		
	FROM stocuri s 
		OUTER APPLY (select top 1 * from pozdoc p where p.Subunitate=s.Subunitate and p.Tip='TE' and p.Gestiune_primitoare=s.Cod_gestiune 
						and p.Cod=s.Cod and p.Grupa=s.Cod_intrare and p.Factura=s.Contract order by p.idPozDoc desc) pd
		LEFT JOIN nomencl n ON n.Cod=s.Cod
		LEFT JOIN gestiuni g ON g.Cod_gestiune=pd.Gestiune
		LEFT JOIN lm on lm.Cod=s.Loc_de_munca
		LEFT JOIN con o on o.Subunitate=s.Subunitate and o.Tip='BK' and o.Contract=s.Contract
		LEFT JOIN comenzi c on c.Subunitate=s.Subunitate and c.Comanda=s.Comanda
		LEFT JOIN proprietati r on r.Tip='UTILIZATOR' AND r.Cod_proprietate='GESTREZBK' and r.cod=@utilizator and r.Valoare_tupla=''
			and r.Valoare=s.cod_gestiune
		--LEFT JOIN proprietati pp on pp.Tip='UTILIZATOR' AND pp.Cod_proprietate='LOCMUNCA' and pp.cod=@utilizator and pp.Valoare_tupla=''
		--	and pp.Valoare=coalesce(nullif(s.Loc_de_munca,''),nullif(o.loc_de_munca,''),nullif(c.loc_de_munca,''))
	WHERE s.Subunitate=@sub and s.Stoc>=0.001--AND s.Tip_gestiune='A' 
		and r.Valoare is not null
		--and s.Cod_gestiune=@gestprim 
		--and pp.Valoare_tupla is not null
	
	SELECT (   
		SELECT * 
		FROM  #pozitiiDoc		
		FOR XML RAW, TYPE  
	  )  
	FOR XML PATH('DateGrid'), ROOT('Mesaje')

END TRY	
BEGIN CATCH
	SET @eroare = ERROR_MESSAGE()
	RAISERROR(@eroare, 11, 1)	
END CATCH

/*select * from pozdoc*/