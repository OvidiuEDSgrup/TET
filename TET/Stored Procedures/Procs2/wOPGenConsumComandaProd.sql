
CREATE PROCEDURE wOPGenConsumComandaProd @sesiune VARCHAR(50), @parXML XML
as
BEGIN TRY

	IF EXISTS (select 1 from sysobjects where name='wOPGenConsumComandaProdSP')
	begin
		exec wOPGenConsumComandaProdSP @sesiune=@sesiune, @parXML=@parXML
		return
	end

	declare 
		@comanda varchar(20),  @sub varchar(9), @idLansare int, @doc_cm xml, @doc_jurnal xml, @explicatii varchar(200),
		@gestiune varchar(20), @lm varchar(20), @numarPozDoc varchar(20), @idPozDoc int, @data datetime

	exec luare_date_par 'GE','SUBPRO',0,0, @sub OUTPUT
	select 
		@comanda = @parXML.value('(/*/@comanda)[1]','varchar(20)'),
		@idLansare = @parXML.value('(/*/@idLansare)[1]','int'),
		@explicatii = @parXML.value('(/*/@explicatii)[1]','varchar(200)'),
		@gestiune = @parXML.value('(/*/@gestiune)[1]','varchar(20)'),
		@lm = @parXML.value('(/*/@lm)[1]','varchar(20)'),
		@data = ISNULL(@parXML.value('(/*/@data)[1]','datetime'), GETDATE())

	select
		D.c.value('(@cod)[1]', 'varchar(20)') cod,
		D.c.value('(@cant)[1]', 'decimal(15,2)') cantitate
	into #date_cm
	FROM @parXML.nodes('*/DateGrid/row') D(c)
	where D.c.value('(@cant)[1]', 'decimal(15,2)')>0.01
	
	alter table #date_cm add idLinie int identity

	set @doc_cm=
	(
		select 
			@gestiune gestiune, convert(varchar(10), @data, 101) data, @lm lm, 'CM' as tip, '1' fara_luare_date, '1' returneaza_inserate, @comanda comanda,
			(select cod, cantitate, idLinie idlinie from #date_cm for xml raw, type)
		for xml raw, type
	)

	exec wScriuPozDoc @sesiune=@sesiune, @parXML=@doc_cm OUTPUT
	
	select top 1 @numarPozDoc=RTRIM(NUMAR) from PozDoc where tip='CM' and idPozDoc=@doc_cm.value('(/row/docInserate/row/@idPozDoc)[1]','int')

	set @doc_jurnal= (select @idLansare idComanda, GETDATE() data, @explicatii explicatii for xml raw, type)
	exec wScriuJurnalComenzi @sesiune=@sesiune, @ParXML=@doc_jurnal

	select 'S-a generat documentul de consum pentru cantitatile selectate. (numar document consum: '+ISNULL(@numarPozDoc,'-')+')' textMesaj, 'Notificare' as titluMesaj for xml raw,root('Mesaje')
	
end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
