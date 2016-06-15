
CREATE PROCEDURE formComTicheteEdenred @sesiune VARCHAR(50), @parXML XML, @numeTabelTemp VARCHAR(100)
OUTPUT AS

BEGIN TRY
	DECLARE 
		@mesaj VARCHAR(500), @banca VARCHAR(20), @cTextSelect NVARCHAR(max), @datalunii datetime, @datajos datetime, @datasus datetime, @zile_lucratoare int, 
		@asisplus int, @numeFisier varchar(1000), @xml xml

	SET @datalunii = @parXML.value('(/*/@data)[1]', 'datetime')
	SET @asisplus = isnull(@parXML.value('(/*/@asisplus)[1]', 'int'),0)
	select	@datajos=dbo.BOM(@datalunii),
			@datasus=dbo.EOM(@datalunii)
	set @zile_lucratoare=isnull((select max(val_numerica) from par_lunari where tip='PS' and Parametru='ORE_LUNA' and data=@datasus),dbo.zile_lucratoare(@datajos, @datasus))

	IF OBJECT_ID('tempdb..#tmptichete') is not null drop table #tmptichete
	IF OBJECT_ID('tempdb..#selectfinal') is not null drop table #selectfinal

	SELECT max(left(left(Nume,CHARINDEX(' ',Nume)-1),30)) as Nume, max(substring(Nume,CHARINDEX(' ',Nume)+1,30)) as Prenume, marca, cnp, 
		max(zile_lucrate) as zile_lucrate, @zile_lucratoare as zile_lucratoare, 1 as nr_carnete, sum(nr_tichete) as nr_tichete, convert(decimal(12,2),valoare_unitara_tichet) as val_nominala
	INTO #tmptichete
	FROM fTichete_de_masa (@datajos, @datasus, null, 'Tip_operatie', '1', 0, 0, null, null, 0, null, null, 'T', null, null, 0)
	group BY marca, cnp, convert(decimal(12,2),valoare_unitara_tichet)

	CREATE TABLE #selectfinal (nrcrt int, linie varchar(max))

	INSERT INTO #selectfinal
	SELECT 0 nrcrt, 
		'Nume' + char(44) + 'Prenume' + char(44) + 'CNP' + char(44) + 'Nr. de zile lucrate' + char(44) + 'Nr. de zile lucratoare' + char(44) + 'Nr. de carnete sau alte unitati de grapare' + char(44) + 'Nr. de tichete' + char(44) + 'Valoare nominala' [LINIE]

	INSERT INTO #selectfinal
	SELECT ROW_NUMBER() OVER (ORDER BY cnp) nrcrt, 
		rtrim(nume) + char(44) + rtrim(prenume) + char(44) + rtrim(cnp) + char(44) + rtrim(convert(CHAR(3), zile_lucrate)) + char(44) + rtrim(convert(CHAR(3), zile_lucratoare)) 
		+ char(44) + rtrim(convert(CHAR(3), nr_carnete)) + char(44) + rtrim(convert(CHAR(3), nr_tichete)) + char(44) + rtrim(convert(char(13),convert(decimal(10,2),val_nominala))) [LINIE]
	FROM #tmptichete

	SET @cTextSelect = '
		SELECT *
		into ' + @numeTabelTemp + '
		from #selectfinal
		order by NRCRT
		'

	EXEC sp_executesql @statement = @cTextSelect

	if @asisplus=0
	begin
		set @numeFisier='ComandaTichete_'+dbo.fDenumireLuna(@dataSus)+'_'+convert(char(4),year(@datasus))+'.xlsx'
	
		set @xml = (select 'sitTicheteEdenredExcel' procedura, 1 as faramesaje, @numeFisier numefisier for xml raw)
		exec wExportExcel @sesiune = '', @parXML = @xml output
	end
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE()+ ' ('+OBJECT_NAME(@@PROCID)+')'

	RAISERROR (@mesaj, 11, 1)
END CATCH
