
CREATE PROCEDURE wIaPreturiAntecalcul @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	update p
		set p.pret_vanzare=n.pret_stoc
	from #preturi p		
	JOIN nomencl n on p.cod=n.cod

	IF EXISTS (select 1 from sysobjects where name='wIaPreturiAntecalculSP')
		exec wIaPreturiAntecalculSP @sesiune=@sesiune, @parXML=@parXML

END TRY
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
