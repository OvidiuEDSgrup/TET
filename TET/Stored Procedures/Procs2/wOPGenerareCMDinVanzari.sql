CREATE PROCEDURE wOPGenerareCMDinVanzari @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	SET NOCOUNT ON

	/**
		Procedura generarea consumuri aferente vanzarilor (bonuri, facturi, ac-uri) dupa cum urmeaza:
			- parcurge BP/AntetBonuri si pentru codurile rezultate
				- cauta tehnologiile lor (retetele)
				- genereaza din retete "necesarul" de materiale pt. care se va genera CM
				- pt fiecare AC genereaza un CM cu acelasi numar

			- gestiunea din care se genereaza CM este luata din proprietatea GESTCM a gestiunii AC-ului
			- inainte de rulare a scrierii in pozdoc se sterg documentele CM din aceasi data cu acelasi numar
			- pentru o identificare mai buna se mai scrie in pozdoc.detalii faptul ca provin din generare (ca si explicatii) si idPozDoc-ul din AC

		Exemplu apel 
			EXEC wOPGenerareCMDinVanzari '','<row data="2013-05-30" />'
	*/
	DECLARE 
		@mesaj VARCHAR(500), @data DATETIME, @numar varchar(20), @gestiune VARCHAR(20), @cons XML, @crcm cursor, @ft int, @sub varchar(9),
		@datajos datetime, @datasus datetime

	/** Parametru data **/
	SELECT
		@data = @parXML.value('(/*/@data)[1]', 'datetime'),
		@datajos = @parXML.value('(/*/@datajos)[1]', 'datetime'),
		@datasus = @parXML.value('(/*/@datasus)[1]', 'datetime')

	IF @data is not null
		select @datajos=@data, @datasus=@data

	exec luare_date_par 'GE','SUBPRO',0,0,@sub OUTPUT

	/** Se iau vanzarile pe data respectiva **/
	SELECT 
		a.idAntetBon idAntetBon, a.bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(20)') numar, a.data_bon data, a.gestiune gestiune,
		b.cod_produs cod_produs, b.cantitate cant_produs, 0 idTehnologie
	into #coduriconsum
	FROM AntetBonuri a
	JOIN Bp b on a.idAntetBon=b.idAntetBon and b.tip='21'
	JOIN pozTehnologii pt on pt.tip='T' and b.Cod_produs=pt.cod
	WHERE a.Data_bon between @datajos and @datasus

	alter table #coduriconsum add gestiune_cm varchar(20)

	update d
		set d.gestiune_cm=rtrim(p.Valoare)
	from #coduriconsum d
	JOIN proprietati p on p.Tip='GESTIUNE' and p.Cod=d.gestiune and p.Cod_proprietate='GESTCM'

	IF EXISTS(select 1 from #coduriconsum where gestiune_cm IS NULL)
		raiserror('Nu este setata gestiune de consum aferenta gestiunii din vanzari (verificati proprietatea GESTCM a gestiunii)',16,1)

	if OBJECT_ID ('tempdb..#deGenerat') is not null
		drop table #deGenerat

	select
		cc.*, pm.cod cod_articol, pm.cantitate*cc.cant_produs cant_reteta
	into #deGenerat
	from #coduriconsum cc
	JOIN Tehnologii t on t.codNomencl=cc.cod_produs
	JOIN PozTehnologii pt on pt.cod=t.cod and pt.tip='T'
	JOIN PozTehnologii pm on pm.parinteTop=pt.id and pm.tip='M'

	/** Daca s-au generat alte CM-uri pe aceasi data, se sterg pentru a le putea regenera **/
	DELETE
		p
	FROM pozdoc p
	JOIN #deGenerat d on p.Subunitate = @sub AND p.tip = 'CM' AND p.data = d.data AND p.Numar = d.numar

	DELETE p
	FROM doc p
	JOIN #deGenerat d on p.Subunitate = @sub AND p.tip = 'CM' AND p.data = d.data AND p.Numar = d.numar

	select
		distinct numar,data 
	into #deGeneratAntet
	from #deGenerat

	/** XML-ul pentru scriere in pozdoc **/
	SET @cons = 
	(
		SELECT rtrim(@sub) AS subunitate,'CM' AS tip, rtrim(dga.numar) AS numar,  data AS data, 1 fara_luare_date,
				(
				SELECT
						rtrim(dg.gestiune_cm) AS gestiune, rtrim(dg.cod_articol) AS cod, convert(DECIMAL(16, 5), dg.cant_reteta) AS  cantitate,
						(select 'Gen. wOPGenerareCMDinVanzari' explicatii  for xml raw, type) detalii
				FROM #deGenerat dg where dg.numar=dga.numar
				FOR XML raw, type
				)
		FROM #deGeneratAntet dga
		FOR XML raw, type
		)

	set @cons=(select @cons for xml path('Date'), type)


	EXEC wScriuPozdoc @sesiune = @sesiune, @parXML = @cons

end try
begin catch
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
