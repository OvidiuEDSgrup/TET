CREATE PROCEDURE wOPGenerareProforma_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	declare @idContract int, @mesaj varchar(500), @valoare_proforme_generate float, @valoare float, @procent_proforma float,
		@valuta varchar(3), @curs float
	
	set @idContract=@parXML.value('(/row/@idContract)[1]',' int')
	set @valoare=@parXML.value('(/row/@valoare)[1]',' float')
	set @curs = isnull(@parXML.value('(/*/@curs)[1]','float'),0)
	set @valuta = isnull(@parXML.value('(/*/@valuta)[1]','varchar(3)'),'')
	
	--calculez valoarea proformelor generate pe comanda de livrare
	select @valoare_proforme_generate=sum((pc.cantitate*pc.pret)/ case when @valuta<>'' and isnull(c.valuta,'')='' then isnull(c.curs,1) else 1 end)
	from pozcontracte pc
		inner join contracte c on c.idcontract=pc.idcontract and c.idContractCorespondent=@idContract
	
	--calculez procentul valorii pentru care inca nu s-a generat proforme
	set @procent_proforma=100-(isnull(@valoare_proforme_generate,0)*100/@valoare)
	
	if convert(decimal(17,2),@valoare-isnull(@valoare_proforme_generate,0))<0.001
		raiserror('Au fost generate deja proforme pentru intreaga valoare a comenzii de livrare!',11,1)

	--trimit datele pentru afisare pe macheta
	select convert(decimal(17,2),@valoare-isnull(@valoare_proforme_generate,0)) as valoare_proforma,
		convert(decimal(17,2),@procent_proforma) as procent_proforma 
	for xml raw,root('Date')
	
END TRY
BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPGenerareProforma_p)'
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	RAISERROR (@mesaj, 11, 1)
END CATCH
