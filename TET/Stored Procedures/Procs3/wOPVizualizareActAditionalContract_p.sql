
CREATE PROCEDURE wOPVizualizareActAditionalContract_p @sesiune VARCHAR(50), @parXML XML
AS
begin try
	declare 
		@idJurnal int, @stare_act int, @tip_contract varchar(2), @idContract int, @contract_vechi xml

	select 
		@idJurnal = @parXML.value('(/*/@idJurnal)[1]', 'int'),
		@tip_contract = @parXML.value('(/*/@tip)[1]', 'varchar(2)')

	select top 1 @tip_contract=c.tip, @idContract=c.idContract, @contract_vechi=jc.detalii from Contracte c JOIN JurnalContracte jc on c.idContract=jc.idContract and jc.idJurnal=@idJurnal
	select top 1 @stare_act=stare from StariContracte where tipContract=@tip_contract and ISNULL(actaditional,0)=1
	

	IF (select stare from JurnalContracte where idJurnal=@idJurnal)<> @stare_act
		raiserror('Starea selectata din Jurnal nu marcheaza introducerea unui act aditional!',16,1)
	
	select 
		rtrim(numar) numar, convert(varchar(10), data, 101) data
	from Contracte where idContract=@idContract
	for xml raw, root('Date')

	select 
		D.cod.value('(@idPozContract)[1]', 'int') idPozContract,
		D.cod.value('(@cod)[1]', 'varchar(20)') cod,
		convert(decimal(15,2),D.cod.value('(@cantitate)[1]', 'float')) cantitate,
		convert(decimal(15,2),D.cod.value('(@pret)[1]', 'float')) pret,
		convert(decimal(15,2),D.cod.value('(@discount)[1]', 'float')) discount
	into #pozitii_contract
	from @contract_vechi.nodes('/row/row')	D(cod)


	SELECT (
			SELECT 
				p.cod, p.cantitate, p.pret, p.discount, rtrim(n.denumire) dencod
			from #pozitii_contract p 
			JOIN nomencl n on n.cod=p.cod
			FOR XML raw, type
			)
	FOR XML path('DateGrid'), root('Mesaje')


end try
begin catch
	declare @mesaj varchar(1000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	select '1' as inchideFereastra for xml raw, root('Mesaje')
	raiserror(@mesaj, 16,1)
end catch
