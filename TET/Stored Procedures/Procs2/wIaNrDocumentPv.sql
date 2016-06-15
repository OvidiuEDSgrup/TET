--***
/* Cere si rezerva numar de document din plaja */
create procedure wIaNrDocumentPv @sesiune varchar(50), @parXML xml
as
declare @returnValue int
if exists(select * from sysobjects where name='wIaNrDocumentPvSP' and type='P')
begin
	exec @returnValue = wIaNrDocumentPvSP @sesiune,@parXML
	return @returnValue 
end

set nocount on

DECLARE @tipDoc VARCHAR(50), @utilizator VARCHAR(50), @msgEroare VARCHAR(8000), @xml xml, @NrDoc varchar(20), @idPlaja INT,
	@dataExpirarii DATETIME, @secundeValabilitate bigint

BEGIN TRY
	select	@tipDoc = @parXML.value('(/*/@tipdoc)[1]', 'varchar(50)'),
			@secundeValabilitate = 15*60, -- 15 minute
			@dataExpirarii=DATEADD(second, @secundeValabilitate, getdate())
	
	set @xml = ( select 'PV' as codMeniu, @utilizator as utilizator, @tipDoc as tip for xml raw )
	exec wIauNrDocFiscale @parXML=@xml, @NrDoc=@NrDoc output, @idPlaja=@idPlaja output
	
	IF ISNULL(@NrDoc,'') IN ('', '0')
		RAISERROR('Eroare la identicare numar document din plaja.',11,1)
	
	insert into docfiscalerezervate(idPlaja,numar,expirala) 
	values (@idPlaja, @NrDoc, @dataExpirarii)
	
	-- se va trimite tot timpul @numar, @idplaja si @dataexpirarii 
	SELECT @nrDoc numar, @idPlaja idplaja, convert(varchar, @dataExpirarii, 21) dataexpirarii, @secundeValabilitate secundevalabilitate
	FOR XML raw('numardocument'), root('Date')
END TRY
BEGIN CATCH
	SELECT @msgEroare = ERROR_MESSAGE()+' (wIaNrDocumentPv)'		
	RAISERROR (@msgEroare, 11, 1 )
END CATCH

