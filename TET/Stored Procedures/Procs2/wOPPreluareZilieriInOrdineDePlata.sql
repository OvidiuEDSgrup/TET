
CREATE PROCEDURE wOPPreluareZilieriInOrdineDePlata @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @utilizator varchar(20), @docPozitii XML, @dataplatii DATETIME, @cont VARCHAR(20), @explicatiiOP VARCHAR(2000), 
		@datajos DATETIME, @datasus DATETIME, @lunaalfa VARCHAR(15), @an int, 
		@lm VARCHAR(9), @marca VARCHAR(6), @sirmarci VARCHAR(200), @obanca INT, @banca VARCHAR(30), @mesaj VARCHAR(500)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	SET @cont = @parXML.value('(/*/@cont)[1]', 'varchar(20)')
	SET @datajos = @parXML.value('(/*/@datajos)[1]', 'datetime')
	SET @datasus = @parXML.value('(/*/@datasus)[1]', 'datetime')
	SET @dataplatii = @parXML.value('(/*/@data)[1]', 'datetime')
	SET @explicatiiOP = @parXML.value('(/*/@explicatii)[1]', 'varchar(2000)')
	SET @banca = @parXML.value('(/*/@banca)[1]', 'varchar(30)')
	SET @lm = @parXML.value('(/*/@lm)[1]', 'varchar(9)')
	SET @marca = @parXML.value('(/*/@marca)[1]', 'varchar(6)')
	SET @sirmarci = @parXML.value('(/*/@sirmarci)[1]', 'varchar(200)')
	
	SELECT @lunaalfa=LunaAlfa, @an=year(@datasus) from fCalendar(@datasus,@datasus)
	SET @obanca=(case when isnull(@banca,'')='' then 0 else 1 end)

	IF OBJECT_ID('tempdb..#pozitiiPreluare') IS NOT NULL
		DROP TABLE #pozitiiPreluare

	CREATE TABLE #pozitiiPreluare (marca VARCHAR(20), suma FLOAT)

	/** Populare din salariiZilieri **/
	INSERT INTO #pozitiiPreluare (marca, suma)
	SELECT RTRIM(s.Marca) marca, sum(s.Rest_de_plata)
	from SalariiZilieri s
		left outer join zilieri z on z.marca=s.marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=s.Loc_de_munca
	where s.data between @dataJos and @dataSus 
		and (@marca is null or s.Marca=@marca)
		and (@lm is null or s.loc_de_munca like rtrim(@lm)+'%')
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
		and (@obanca=0 or z.Banca=@banca)
		and (@sirmarci='' or charindex (','+rtrim (s.Marca)+',',rtrim(@sirmarci))<>0) 
	Group By s.Marca

	SET @docPozitii = (
			SELECT
				'1' AS preluare, @dataplatii data, @cont cont, 'S' sursa, '1' fara_luare_date, 'SA' tip, 'SA' tipOP, @explicatiiOP explicatii,
				(
					SELECT 
						rtrim(z.Cont_in_banca) AS iban, rtrim(z.Banca) AS banca, convert(DECIMAL(18, 5), pp.suma) suma, '1' stare, -- am pus stare implicita=1 si la zilier
						(select z.Cod_numeric_personal cnp FOR XML RAW) detalii, pp.Marca marca,
							isnull(rtrim(z.Nume), '') + ' Plata zilieri:' +' '+RTRIM(@lunaalfa)+' - '+CONVERT(char(4),@an) AS explicatii
					FROM #pozitiiPreluare pp
						left outer join zilieri z on z.Marca=pp.Marca
					FOR XML raw, type
				)
			FOR XML raw, type
			)

	EXEC wScriuPozOrdineDePlata @sesiune = @sesiune, @parXML = @docPozitii

END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'

	RAISERROR (@mesaj, 11, 1)
END CATCH
