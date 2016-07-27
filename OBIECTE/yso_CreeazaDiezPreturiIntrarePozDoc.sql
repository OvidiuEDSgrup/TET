IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'yso_CreeazaDiezPreturiIntrarePozDoc')
	DROP PROCEDURE yso_CreeazaDiezPreturiIntrarePozDoc
GO

CREATE PROCEDURE yso_CreeazaDiezPreturiIntrarePozDoc 
AS
BEGIN TRY
	alter table #PreturiIntrarePozDoc
		add pret_stoc decimal(12,5), valuta varchar(6), curs decimal(12,5), tipPret char(1), calculat int default 0	
END TRY
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH