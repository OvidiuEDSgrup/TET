CREATE PROCEDURE wOPGenPFdinGP @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @nrdoc VARCHAR(20), @stare INT, @factura VARCHAR(20), @tert VARCHAR(20), @data VARCHAR(20), @cont VARCHAR(20)

BEGIN TRY
	SELECT	@nrdoc=@parXML.value('(/parametri/@numar)[1]','varchar(20)'),
			@data=@parXML.value('(/parametri/@data)[1]','varchar(20)'),
			@cont=@parXML.value('(/parametri/@cont)[1]','varchar(20)')
	--- validari
	IF @cont IS NULL OR @data IS NULL OR @nrdoc IS NULL 
		RAISERROR ('wOPGenPFdinGP: Macheta corespunzatoare operatiei de generare Plati Furnizor nu este configurata complet!',16,1)
	IF @cont=''
		RAISERROR('wOPGenPFdinGP: Alegeti un cont pentru a inregistra facturile in Plati Incasari',16,1)
	--IF (SELECT DISTINCT stare FROM dbo.generareplati WHERE Numar_document=@nrdoc AND Data=@data)<>1
	--	RAISERROR('wOPGenPFinGP: Nu se poate genera Plata Furnizor deoarece documentul nu este in starea OP Generat!',16,1)
	
    ---
	DECLARE @input xml
	SELECT @input=(SELECT 1 AS '@subunitate', @cont AS '@cont',  @data AS '@data',
					(SELECT @cont AS '@cont', @data AS '@data', @nrdoc AS '@numar', 'PF' AS '@subtip',
							RTRIM(gp.Tert) AS '@tert', RTRIM(gp.Factura) AS '@factura', RTRIM(f.cont_de_Tert) AS '@contcorespondent', 
							CONVERT(DECIMAL(15,2),gp.Val1) AS '@suma'
						FROM dbo.generareplati gp 
						LEFT JOIN facturi f ON f.Factura=gp.Factura AND f.Tip='T'
						WHERE	gp.Numar_document=@nrdoc and gp.Data=@data AND 
								gp.Stare='1' AND gp.Banca_beneficiar<>'' AND gp.IBAN_beneficiar<>'' and gp.val3='1'
						for XML PATH, TYPE) 
				FOR XML PATH, TYPE) 
			EXEC dbo.wScriuPozplin @sesiune = @sesiune, @parXML = @INPUT 
			
	UPDATE g SET stare='2' FROM dbo.generareplati g, pozplin pz WHERE pz.numar=g.numar_document and pz.data=g.data and pz.factura=g.factura and 
																		g.Numar_document=@nrdoc and g.Data=@data and g.val3='1'
			
END TRY
BEGIN CATCH
	DECLARE @eroare VARCHAR(500)
	SET @eroare=ERROR_MESSAGE()
	RAISERROR(@eroare,16,1)
END CATCH


/*
					
					
SELECT * FROM pozplin WHERE Plata_incasare='PF' AND cont='5113' AND Numar='REMAT3'
SELECT * FROM plin WHERE  cont='5113' AND  Data='2007-02-23'
SELECT * FROM dbo.generareplati  WHERE Numar_document='REMAT3'


declare @p2 xml
set @p2=convert(xml,N'<parametri numar="REMAT3" tip="GP" subtip="PF" data="05/31/2011" pozitii="2" stare="Generat" cont="5113"
								 denstare="Generat" culoare="#808080" _nemodificabil="1" _cautare="" nrdoc="REMAT3" tipMacheta="D" 
								 codMeniu="GO" TipDetaliere="GP"/>')
exec wOPGenPFdinGP @sesiune='EE1C07C359654',@parXML=@p2


*/