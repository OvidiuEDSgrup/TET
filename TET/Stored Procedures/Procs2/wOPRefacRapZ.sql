-- reface IC in in tabela pozplin, din tabela bp.
CREATE PROCEDURE wOPRefacRapZ @sesiune VARCHAR(50), @parXML XML
AS
/* 
	Exemplu apel
		exec wOPRefacRapZ '', '<row dataj="2014-09-01" datas="2014-09-30" lm="0VPET" vanzator="pop80"/>'
*/

declare @utilizator varchar(20), @dataj datetime, @datas datetime, @gfetch int, @RapZxml xml, @vanzator varchar(20), @lm varchar(9)
BEGIN TRY
	select	
		@dataj = @parXML.value('(/*/@dataj)[1]', 'datetime'),
		@datas = @parXML.value('(/*/@datas)[1]', 'datetime'),
		@lm = NULLIF(@parXML.value('(/*/@lm)[1]', 'varchar(10)'),''), 
		@vanzator = NULLIF(@parXML.value('(/*/@vanzator)[1]', 'varchar(100)'),'')

	declare tmpRRZ cursor for select distinct a.vinzator 
		from bp 
		inner join antetBonuri a on a.idAntetBon=bp.idAntetBon
		where data between @dataj and @datas
			and (@lm is null or a.loc_de_munca like @lm+'%')
			and (@vanzator is null or a.vinzator=@vanzator)
	open tmpRRZ
	fetch next from tmpRRZ into @utilizator
	set @gfetch=@@fetch_status
	while @gfetch=0
	begin
		set @RapZxml = (select @dataj dataj, @datas datas, @utilizator utilizator for xml raw)	
		exec wOPRaportZGeneralSP '', @RapZxml
		fetch next from tmpRRZ into @utilizator
		set @gfetch=@@fetch_status
	end
	close tmpRRZ
	deallocate tmpRRZ

	SELECT 'Refacere IC (raport Z) efectuata cu succes!' AS textMesaj
		FOR XML raw, root('Mesaje')
END TRY

BEGIN CATCH
	DECLARE @eroare VARCHAR(200)
	SET @eroare = ERROR_MESSAGE() + '(wOPRefacRapZ)'
	RAISERROR (@eroare, 16, 1)
END CATCH

