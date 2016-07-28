IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'yso_CreeazaDiezPreturiIntrarePozDoc')
	DROP PROCEDURE yso_CreeazaDiezPreturiIntrarePozDoc
GO

CREATE PROCEDURE yso_CreeazaDiezPreturiIntrarePozDoc 
AS
BEGIN TRY

	if not exists (select 1 from tempdb.sys.columns c where c.name='yso_pret_intrare' and c.object_id=object_id('tempdb..#yso_PreturiIntrarePozDoc'))
			alter table #yso_PreturiIntrarePozDoc add yso_pret_intrare float NULL
			
END TRY
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH