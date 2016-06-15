CREATE PROCEDURE  wOPGenerareFacturaAvans_p @sesiune VARCHAR(50), @parXML XML OUTPUT
AS
BEGIN TRY
	declare
		@codAvans varchar(20), @idContract int

	exec luare_date_par 'PV','CODAVBEN',0,0,@codAvans OUTPUT

	IF ISNULL(@codAvans,'')=''
		RAISERROR('Nu este configurat lucrul cu facturi de avans. Verificati parametri (CODAVBEN)!',15,1)
	
	select
		@idContract = @parXML.value('(/*/@idContract)[1]','int')

	IF EXISTS(select 1 from JurnalContracte jc JOIN LegaturiContracte lc on jc.idJurnal=lc.idJurnal and lc.idPozContract IS NULL JOIN PozDoc pd on pd.idPozDoc=lc.idPozDoc and pd.cod=@codAvans and jc.idContract=@idContract)
		RAISERROR('Pentru contractul/comanda selectata s-a generat deja o factura de avans!',15,1)
			
END TRY
BEGIN CATCH
	select 1 as inchideFereastra for xml raw, root('Mesaje')
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
