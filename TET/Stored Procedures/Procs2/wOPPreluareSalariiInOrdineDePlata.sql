
CREATE PROCEDURE wOPPreluareSalariiInOrdineDePlata @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @utilizator VARCHAR(20), @dreptConducere INT, @areDreptCond INT, @sursa VARCHAR(1), @docPozitii XML, @dataplatii DATETIME, @cont VARCHAR(20), @explicatiiOP VARCHAR(2000), 
		@luna INT, @an INT, @lunaalfa VARCHAR(15), @datajos DATETIME, @datasus DATETIME, @avans INT, @restdeplata INT, @corectii INT, 
		@tipplata CHAR(2), @tipcorectie VARCHAR(2), @dencorectie VARCHAR(30), @datacorectie DATETIME, @CumulareCorectieU INT, 
		@fltDataCorectie INT, @banca VARCHAR(30), @lm VARCHAR(9), @marca VARCHAR(6), @sirmarci VARCHAR(200), 
		@obanca INT, @tipcard VARCHAR(30), @untippers INT, @tippers VARCHAR(1), @dreptacces char(1), 
		@mesaj VARCHAR(500)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	SET @dreptConducere=dbo.iauParL('PS','DREPTCOND')
	SET @sursa = 'S'
	SET @cont = @parXML.value('(/*/@cont)[1]', 'varchar(20)')
	SET @dataplatii = isnull(@parXML.value('(/*/@dataplatii)[1]', 'datetime'),@parXML.value('(/*/@data)[1]', 'datetime'))
	SET @luna = @parXML.value('(/*/@luna)[1]', 'int')
	SET @an = @parXML.value('(/*/@an)[1]', 'int')
	SET @explicatiiOP = @parXML.value('(/*/@explicatii)[1]', 'varchar(2000)')
	SET @tipplata = @parXML.value('(/*/@tipplata)[1]', 'char(2)')
	SET @tipcorectie = isnull(@parXML.value('(/*/@tipcorectie)[1]', 'char(2)'),'')
	SET @datacorectie = @parXML.value('(/*/@datacorectie)[1]', 'datetime')
	SET @CumulareCorectieU=isnull(@parXML.value('(/*/@cumularecorU)[1]', 'int'),0)
	SET @banca = @parXML.value('(/*/@banca)[1]', 'varchar(30)')
	SET @lm = @parXML.value('(/*/@lm)[1]', 'varchar(9)')
	SET @marca = @parXML.value('(/*/@marca)[1]', 'varchar(6)')
	SET @sirmarci = @parXML.value('(/*/@sirmarci)[1]', 'varchar(200)')
	SET @tippers = @parXML.value('(/*/@tippers)[1]', 'varchar(1)')
	SET @dreptacces = @parXML.value('(/*/@dreptacces)[1]', 'varchar(1)')
	
	SET @datajos=convert(datetime,str(@luna,2)+'/01/'+str(@an,4))
	SET @datasus=dbo.EOM(@datajos)
	SELECT @lunaalfa=LunaAlfa from fCalendar(@datasus,@datasus)
	SET @avans=(case when @tipplata='AV' then 1 else 0 end)
	SET @restdeplata=(case when @tipplata='RP' then 1 else 0 end)
	SET @corectii=(case when @tipplata='CR' then 1 else 0 end)
	SET @obanca=(case when isnull(@banca,'')='' then 0 else 1 end)
	SET @untippers=(case when isnull(@tippers,'A')='A' then 0 else 1 end)
	SET @fltDataCorectie=(case when @corectii=1 and @tipcorectie<>'' then 1 else 0 end)
	IF @corectii=1
		SELECT @dencorectie=denumire from tipcor where Tip_corectie_venit=@tipcorectie

--	verific daca utilizatorul are/nu are dreptul de Salarii conducere (SALCOND)
	SET @areDreptCond=0
	IF @dreptConducere=1 
	BEGIN
		SET @areDreptCond=isnull((select dbo.verificDreptUtilizator(@utilizator,'SALCOND')),0)
		IF @areDreptCond=0
			SET @dreptacces='S'
	END

	IF OBJECT_ID('tempdb..#pozitiiPreluare') IS NOT NULL
		DROP TABLE #pozitiiPreluare

	CREATE TABLE #pozitiiPreluare (marca VARCHAR(20), suma FLOAT)

	/** Populare din salarii (avans, rest de plata)**/
	INSERT INTO #pozitiiPreluare (marca, suma)
	SELECT RTRIM(a.Marca) marca, sum(a.suma) as suma
	from dbo.fCarduri (@datajos, @datasus, @Avans, @RestDePlata, @corectii, 0, 0, @CumulareCorectieU, 0, 0, 0, 0, 0, 0, 0, @tipcorectie, 0, '', 0, 
				@obanca, @banca, 0, 0, 0, 0, '', 0, '', '', @fltDataCorectie, @datacorectie, @datacorectie, '', '', 0, '', 0, 0, '', '', @dataplatii, @untippers, @tippers, 0) a
		LEFT OUTER JOIN personal p on a.marca=p.marca
	where (@dreptConducere=0 or (@dreptConducere=1 and @areDreptCond=1 and (@dreptacces='T' or @dreptacces='C' and p.pensie_suplimentara=1 or @dreptacces='S' and p.pensie_suplimentara<>1)) 
			or (@dreptConducere=1 and @areDreptCond=0 and @dreptacces='S' and p.pensie_suplimentara<>1))
		and (isnull(@marca,'')='' or a.Marca=@marca)
		and (isnull(@lm,'')='' or a.Loc_de_munca like rtrim(@lm)+'%')
		and (isnull(@sirMarci,'')='' or charindex (','+rtrim (a.Marca)+',',rtrim(@sirMarci))<>0) 
	group by a.marca

	SET @docPozitii = (
			SELECT
				'1' AS preluare, @dataplatii data, @cont cont, 'S' sursa,'1' fara_luare_date,'SA' tip,'SA' tipOP,@explicatiiOP explicatii,
				(
					SELECT 
						rtrim(p.Cont_in_banca) AS iban, rtrim(p.Banca) AS banca, convert(DECIMAL(18, 5), pp.suma) suma, '1' stare, -- am pus stare implicita=1 la salarii
						(select p.Cod_numeric_personal cnp FOR XML RAW) detalii,p.Marca marca,
							isnull(rtrim(p.Nume), '') + (CASE @tipplata WHEN 'RP' THEN ' Rest de plata:' 
								WHEN 'AV' THEN 'Avans:' WHEN 'CR' THEN RTRIM(@dencorectie) END)+' '+RTRIM(@lunaalfa)+' - '+CONVERT(char(4),@an) AS explicatii
					FROM #pozitiiPreluare pp
					LEFT JOIN personal p
						ON p.Marca = pp.Marca
					FOR XML raw, type
				)
			FOR XML raw, type
			)

	EXEC wScriuPozOrdineDePlata @sesiune = @sesiune, @parXML = @docPozitii


END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPPreluareSalariiInOrdineDePlata)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
