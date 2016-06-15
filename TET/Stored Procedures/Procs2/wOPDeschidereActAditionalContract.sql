
CREATE PROCEDURE wOPDeschidereActAditionalContract @sesiune VARCHAR(50), @parXML XML
AS
begin try

	declare 
		@idContract int, @docJurnal xml, @contract_actual xml, @stare_act int, @tip_contract varchar(2), @numar_act varchar(50)

	select 
		@idContract = @parXML.value('(/*/@idContract)[1]', 'int'),
		@tip_contract = @parXML.value('(/*/@tip)[1]', 'varchar(50)'),
		@numar_act = @parXML.value('(/*/@numar_act)[1]', 'varchar(50)')


	select top 1 @stare_act=stare from StariContracte where tipContract=@tip_contract and ISNULL(actaditional,0)=1

	IF ISNUll(@stare_act,0)=0
		raiserror('Nu exista definita starea de act aditional! Verificati macheta de configurare stari.',16,1)

	/* Pregatim XML-ul cu forma actuala (tot) a contractului pt. a-l scrie in Jurnal */
	set @contract_actual=(select *,@numar_act numar_act, (select * from PozContracte where idContract=@idContract for xml raw, type ) from Contracte where idContract=@idContract for xml raw,type)

	SET @docJurnal = (SELECT @idContract idContract, @stare_act stare, GETDATE() AS data, 'ACT ADITIONAL '+ISNULL('NR '+@numar_act,'')  AS explicatii, @contract_actual detalii FOR XML raw )

	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnal
end try
begin catch
	declare @mesaj varchar(1000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch
