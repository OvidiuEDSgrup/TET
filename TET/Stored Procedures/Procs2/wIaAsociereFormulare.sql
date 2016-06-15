
CREATE PROCEDURE wIaAsociereFormulare @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @f_tip VARCHAR(100), @f_formular VARCHAR(100), @f_meniu VARCHAR(100), @denumire_formular varchar(100),
	@formular varchar(100)	--> identificator formular provenit din macheta de configurare
declare @flt_formular bit

SET @formular =rtrim(@parxml.value('(/*/@formular)[1]', 'varchar(20)'))
SET @f_meniu = '%' + @parXML.value('(/*/@f_meniu)[1]', 'varchar(20)') + '%'
SET @f_tip = '%' + @parXML.value('(/*/@f_tip)[1]', 'varchar(20)') + '%'
SET @f_formular = '%' + rtrim(@parXML.value('(/*/@f_formular)[1]', 'varchar(60)')) + '%'

if (@formular is not null) set @f_formular=@formular
	else set @denumire_formular=@f_formular

select	@flt_formular=(case when isnull(@f_formular,'')='' then 0 else 1 end)

select t.meniu, t.tip, max(rtrim(t.nume)) nume into #tmp from dbo.wfIaTipuriDocumente(NULL) t where isnull(subtip,'')='' group by t.meniu, t.tip

SELECT wcf.idAsociere AS idAsociere, RTRIM(wcf.meniu) meniu, RTRIM(wcf.tip) AS tipDoc, RTRIM(wcf.cod_formular) AS formular,
	RTRIM(af.Denumire_formular) AS denformular, RTRIM(isnull(wcm.Nume,wcf.meniu)) AS denmeniu, RTRIM(wft.nume) AS dentip
FROM webConfigFormulare wcf
INNER JOIN antform af
	ON af.Numar_formular = wcf.cod_formular
left JOIN #tmp wft
	ON wft.tip = wcf.tip
		AND wcf.meniu = wft.meniu
left JOIN webConfigMeniu wcm
	ON wcm.Meniu = wft.meniu
WHERE (
		isnull(@f_tip, '') = ''
		OR wcf.tip LIKE @f_tip
		OR wft.nume LIKE @f_tip
		)
	AND (@flt_formular=0 OR wcf.cod_formular LIKE @f_formular OR af.Denumire_formular LIKE @denumire_formular)
	AND (
		ISNULL(@f_meniu, '') = ''
		OR wcm.Nume LIKE @f_meniu
		OR wcf.meniu LIKE @f_meniu
		)
	order by wcm.nrordine
FOR XML raw, root('Date')

if object_id('tempdb..#tmp') is not null drop table #tmp
