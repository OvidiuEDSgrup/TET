
create procedure wOPGenerareComandaProductieContract @sesiune varchar(50), @parXML XML  
as
begin try
	declare 
		@idContract int, @idPozContract int, @cod varchar(20), @tert varchar(20), @cantitate decimal(15,2), @termen datetime, @denumire varchar(100),
		@xml_lansare xml, @xml_jurnal xml, @lm varchar(20), @detalii XML

	select 
		@cod =  @parXML.value('(/*/@cod)[1]','varchar(20)'),
		@tert =  @parXML.value('(/*/@tert)[1]','varchar(20)'),
		@idContract =  @parXML.value('(/*/@idContract)[1]','int'),
		@idPozContract =  @parXML.value('(/*/@idPozContract)[1]','int'),
		@cantitate =  @parXML.value('(/*/@cantitate)[1]','decimal(15,2)'),
		@termen =  @parXML.value('(/*/@termen)[1]','datetime')
	
	if @parXML.exist('(/*/detalii)[1]')=1
		SET @detalii = @parXML.query('(/*/detalii/row)[1]')

	select @denumire=rtrim(denumire) from nomencl where cod=@cod
	select top 1 @lm= loc_de_munca from Contracte where idContract=@idContract

	set @xml_lansare=(select @tert tert, @cod cod, @cantitate cantitate, @termen termen, @idPozContract idPozContract,'P' stareComanda, @lm lm, @detalii   for xml raw, type)	
	set @xml_jurnal=(select @idContract idContract,  LEFT('Gen. comanda productie articol '+@cod+'( '+@denumire+' )',60) explicatii, GETDATE() data for xml raw, type)

	exec wScriuPozLansari @sesiune=@sesiune, @parXML=@xml_lansare
	exec wScriuJurnalContracte @sesiune=@sesiune, @parXML=@xml_jurnal

	
end try
begin catch
	select 1 as inchideFereastra for xml raw, root('Mesaje')
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
