
CREATE FUNCTION wfIaTipuriDocumente (@tip VARCHAR(20))
RETURNS @Tipuri TABLE (meniu varchar(20), tip VARCHAR(20),subtip varchar(20), nume VARCHAR(60))

BEGIN
	if exists (select 1 from sys.objects where name='webconfigtipuri')
	INSERT INTO @Tipuri (meniu, tip,subtip, nume)
	SELECT wt.meniu, wt.tip,wt.subtip, wt.nume
	FROM webConfigTipuri wt inner join webconfigmeniu w on wt.meniu=w.meniu
	WHERE w.TipMacheta = 'D'
		AND tip IS NOT NULL
		AND isnull(Fel, '') not in ('O','R')
		AND isnull(subtip, '') = '' -- la autocomplete sa nu aduca si subtipurile
	and (
			@tip IS NULL
			OR tip = @tip
			)
	ORDER BY w.meniu, tip

	RETURN
END
