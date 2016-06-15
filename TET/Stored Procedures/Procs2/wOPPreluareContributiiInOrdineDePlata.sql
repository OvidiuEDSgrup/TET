
CREATE PROCEDURE wOPPreluareContributiiInOrdineDePlata @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @sursa VARCHAR(1), @docPozitii XML, @nrop varchar(20), @data DATETIME, @cont VARCHAR(20), @explicatiiOP VARCHAR(2000), 
		@datajos DATETIME, @datasus DATETIME, @tertImpozit varchar(20), @tertCAS varchar(20), 
		@banca VARCHAR(30), @lm VARCHAR(9), @mesaj VARCHAR(500), @explicatii varchar(100), @codFiscal varchar(20), @nrPozImpozit int

	set @sursa = 'S'
	set @cont = @parXML.value('(/*/@cont)[1]', 'varchar(20)')
	set @nrop = @parXML.value('(/*/@nrop)[1]', 'varchar(20)')
	if isnull(@nrop,'')=''
		set @nrop='1'
	set @data = @parXML.value('(/*/@data)[1]', 'datetime')
	set @explicatiiOP = @parXML.value('(/*/@explicatii)[1]', 'varchar(2000)')
	set @datajos = @parXML.value('(/*/@datajos)[1]', 'datetime')
	set @datasus = @parXML.value('(/*/@datasus)[1]', 'datetime')
	set @banca = @parXML.value('(/*/@banca)[1]', 'varchar(30)')
	set @lm = @parXML.value('(/*/@lm)[1]', 'varchar(9)')
	set @tertImpozit = @parXML.value('(/*/@tertimp)[1]', 'varchar(20)')
	set @tertCAS = @parXML.value('(/*/@tertcas)[1]', 'varchar(20)')

	set @explicatii=(case when dbo.eom(@dataJos)=@dataSus then substring(convert(char(10),@dataSus,104),4,7) 
			else substring(convert(char(10),@dataJos,104),4,2)+' - '+substring(convert(char(10),@dataSus,104),4,7) end)
	IF ISNULL(@explicatiiOP,'')=''
		SET @explicatiiOP='Contributii salarii, perioada '+@explicatii

	IF OBJECT_ID('tempdb..#impozitSedii') IS NOT NULL 
		DROP TABLE impozitSedii
	IF OBJECT_ID('tempdb..#contribsal') IS NOT NULL 
		DROP TABLE #contribsal
	IF OBJECT_ID('tempdb..#pozitiiPreluare') IS NOT NULL
		DROP TABLE #pozitiiPreluare

	create table #impozitSedii
		(Data datetime, CodFiscal char(13), idCodFiscal int, Sediu char(2), Impozit decimal(10))
	insert into #impozitSedii
	exec Declaratia112Impozit @dataJos=@dataJos, @dataSus=@dataSus, @ImpozitPL=1

	CREATE TABLE #contribsal
		(grupa decimal(2), dengrupa varchar(100), ordered decimal(2), data datetime, contributie varchar(200), baza_de_calcul float, procent float, valoare_contributie float, nr_salariati int)
	exec ContributiiSalarii @datajos=@dataJos, @datasus=@dataSus, @scriu_diez=1
	CREATE TABLE #pozitiiPreluare (nrop varchar(20), tert varchar(20), explicatii VARCHAR(200), suma FLOAT, tip_suma VARCHAR(20))
	select @nrPozImpozit=count(1) from #impozitSedii

	/** Populare cu contributii salarii **/
	INSERT INTO #pozitiiPreluare (nrop, tert, explicatii, suma, tip_suma)
	select convert(int,@nrop)+row_number() over (order by sediu, idCodFiscal)-1 as nrop, 
		(case when Sediu='P' then @tertimpozit else i.CodFiscal end) as tert, 
		'BUGETUL DE STAT '+@explicatii as explicatii, i.Impozit+(case when Sediu='P' then cs.valoare_contributie else 0 end) as suma, 
		(case when Sediu='P' then 'Impozit' else 'ImpozitPL' end) as tip_suma
	from #impozitSedii i
		left outer join #contribsal cs on cs.grupa=13
	union all
	select convert(int,@nrop)+@nrPozImpozit as nrop, @tertCAS as tert, 'BUGETELE ASIG. SOC. SI FD.SPEC.'+@explicatii as explicatii, sum(valoare_contributie) as suma, 'CAS' as tip_suma
	from #contribsal where grupa=2

	set @docPozitii = (
			SELECT
				'1' AS preluare, @data data, @cont cont, 'S' sursa,'1' fara_luare_date, 'CS' tip, 'CS' tipOP, @explicatiiOP explicatii,
					(SELECT convert(char(10),@datajos,101) datajos, convert(char(10),@datasus,101) datasus for XML raw, type) detalii,
				(
					SELECT 
						rtrim(pp.tert) as tert, rtrim(t.banca) banca, rtrim(t.cont_in_banca) iban, convert(DECIMAL(18, 5), pp.suma) suma, '1' stare, -- am pus stare implicita=1 la salarii
						(SELECT nrop nrop, rtrim(tip_suma) tipsuma for XML raw, type) detalii, explicatii AS explicatii
					FROM #pozitiiPreluare pp
						LEFT JOIN terti t ON t.Tert = pp.tert
					FOR XML raw, type
				)
			FOR XML raw, type
			)

	EXEC wScriuPozOrdineDePlata @sesiune = @sesiune, @parXML = @docPozitii

END TRY

BEGIN CATCH
	set @mesaj = ERROR_MESSAGE() + ' (wOPPreluareContributiiInOrdineDePlata)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
