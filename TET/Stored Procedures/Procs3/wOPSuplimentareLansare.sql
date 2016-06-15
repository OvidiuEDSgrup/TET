
CREATE PROCEDURE wOPSuplimentareLansare @sesiune VARCHAR(50), @parXML XML
as
BEGIN TRY
	declare 
		@comanda varchar(20), @idLansare int, @doc_jurnal xml, @explicatii varchar(200), 
		@cantitate_comanda float, @cantitate_supliment float, @cantitate_noua float
		

	select 
		@comanda = @parXML.value('(/*/@comanda)[1]','varchar(20)'),
		@idLansare = @parXML.value('(/*/@idLansare)[1]','int'),
		@cantitate_comanda = @parXML.value('(/*/@cantitate)[1]','float'),
		@cantitate_supliment = @parXML.value('(/*/@cantitate_sup)[1]','float'),
		@explicatii = @parXML.value('(/*/@explicatii)[1]','varchar(200)')

	IF ISNULL(@cantitate_supliment,0)=0
		raiserror ('Este necesara completarea cantitatii pt. suplimentare!',16,1)

	select @cantitate_noua=@cantitate_comanda+@cantitate_supliment

	IF @cantitate_noua<=0
		raiserror('Cantitatea totala comanda (cantitate initiala + cantitate supliment) nu poate fi negativa!',16,1)

	update PozLansari set cantitate=@cantitate_noua where id=@idLansare
	update pozLansari set cantitate=@cantitate_noua*cantitate/@cantitate_comanda where parinteTop=@idLansare
	update PozCom set cantitate=@cantitate_noua where comanda=@comanda

	SET @doc_jurnal= (select @idLansare idComanda, GETDATE() data, ISNULL('[Suplimentare]'+@explicatii,'Suplimentare lansare') explicatii for xml raw, type)
	exec wScriuJurnalComenzi @sesiune=@sesiune, @ParXML=@doc_jurnal

	select 'S-a realizat suplimentarea comenzii de productie cu cantitatea introdusa!' textMesaj, 'Notificare' as titluMesaj for xml raw,root('Mesaje')
	
end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
