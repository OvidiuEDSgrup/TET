
CREATE PROCEDURE wOPFacturareComandaTransport_p @sesiune VARCHAR(50), @parXML XML
as
begin try
	declare @comanda int, @stare_comanda int
	set @comanda=@parXML.value('(/*/@idContract)[1]','int')


	select top 1 @stare_comanda=stare from JurnalContracte where idContract=@comanda order by idJurnal desc

	if EXISTS (select 1 from StariContracte where tipContract='CT' and stare=@stare_comanda and inchisa=1 )
		raiserror('Comanda este intr-o stare inchisa!',16,1)
end try
begin catch
	select '1' as inchideFerestra, '1' as 'close' for xml raw, root('Mesaje')
	
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
	
	
end catch
