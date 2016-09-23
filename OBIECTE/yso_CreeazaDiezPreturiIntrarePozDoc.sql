IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'yso_CreeazaDiezPreturiIntrarePozDoc')
	DROP PROCEDURE yso_CreeazaDiezPreturiIntrarePozDoc
GO

CREATE PROCEDURE yso_CreeazaDiezPreturiIntrarePozDoc 
AS
BEGIN TRY

	IF OBJECT_ID('tempdb..#yso_PreturiIntrarePozDoc') IS NOT NULL
		AND NOT EXISTS (SELECT 1 FROM tempdb.sys.columns c WHERE c.name='yso_pret_intrare' and c.object_id=object_id('tempdb..#yso_PreturiIntrarePozDoc'))
			ALTER TABLE #yso_PreturiIntrarePozDoc ADD yso_pret_intrare float NULL
	ELSE 
		PRINT '#yso_PreturiIntrarePozDoc (idPozDoc, subunitate, tip, data, cod, gestiune, cod_intrare, yso_pret_intrare)'
			
END TRY
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH