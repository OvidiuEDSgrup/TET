CREATE PROCEDURE [dbo].[yso_wIaAvizBon_p] @sesiune VARCHAR(50), @parXML XML
AS

DECLARE @id INT, @cautare VARCHAR(20), @tip varchar(20), @aviz xml
	,@idPozContract int, @tipContract varchar(2), @nrContract varchar(20), @comanda varchar(20), @dencomanda varchar(100) --,@idPozLansare int
	,@nrDoc varchar(20), @tipDoc varchar(20), @dataDoc datetime

SET @id = @parXML.value('(*/@idantetbon)[1]', 'int')
SET @tip= @parXML.value('(/*/@tip)[1]', 'varchar(2)')
set @idPozContract = @parXML.value('(/*/@idPozContract)[1]','int')
set @tipContract = @parXML.value('(/*/@tipContract)[1]','varchar(20)')
set @nrContract = @parXML.value('(/*/@contract)[1]','varchar(20)')
set @comanda = @parXML.value('(/*/@comanda)[1]','varchar(20)')
set @dencomanda = @parXML.value('(/*/@dencomanda)[1]','varchar(100)')
set @tipDoc = rtrim(@parXML.value('(/*/@tipdoc)[1]','varchar(20)'))
set @nrDoc = rtrim(@parXML.value('(/*/@nrdoc)[1]','varchar(20)'))
set @dataDoc = @parXML.value('(/*/@datadoc)[1]','datetime')

set @aviz=(SELECT top 1
			tip, CONVERT(varchar(10), Data,101) data, RTRIM(subunitate) subunitate, rtrim(Numar) numar
		from doc where subunitate='1' and Tip=@tipDoc and data=@dataDoc and numar=@nrDoc
		for xml raw)

	if @aviz is not null
		exec wIaDoc @sesiune=@sesiune, @parXML=@aviz
	else
	begin
		select subunitate='1', tip=@tipDoc, numar=@nrDoc, data=CONVERT(varchar(10), @dataDoc,101)
			--, gestiune=rtrim(g.Cod_gestiune), dengestiune=RTRIM(g.Denumire_gestiune)
			--, gestprim=rtrim(gp.Cod_gestiune), dengestprim=RTRIM(gp.Denumire_gestiune), f_gestprim=rtrim(gp.Cod_gestiune)
			--, comanda=@comanda, dencomanda=@dencomanda, f_comanda=@comanda
			--, factura=rtrim(@tipContract)+'-'+ltrim(@nrContract), f_factura=rtrim(@tipContract)+'-'+ltrim(@nrContract)
			--, stare='8', f_stare='8'
			--,detalii=(select idRealizare=@id--, idPozContract=@idPozContract
			--				, explicatii='Stornare rezervare materiale productie la realizare comanda' for xml raw,type)
		--FROM gestiuni g, gestiuni gp
		--WHERE g.Cod_gestiune='1' and gp.Cod_gestiune='1.2' 
		for xml raw
		
		select 1 areDetaliiXml for xml raw, root('Mesaje')
	end