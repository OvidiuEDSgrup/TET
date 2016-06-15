
create procedure  wOPTrateazaPromotie @sesiune varchar(30), @parXML XML OUTPUT
as
begin try
	declare 
		@tip_document_generat varchar(100), @idPromotie int, @cantitate_promotie decimal(15,2), @cod_serviciu_promo varchar(20), @cod varchar(20), @cantitate_cod decimal(15,2),
		@pozitii xml, @pret decimal(15,2), @fara_luare_date bit, @detalii XML, @update bit, @idPozDoc int, @sterg bit

	select
		@tip_document_generat = @parXml.value('(//@_document)[1]','varchar(100)'),
		@idPromotie = @parXml.value('(//@idpromotie)[1]','int'),
		@cantitate_promotie = @parXml.value('(//@cantitatepromotie)[1]','varchar(100)'),
		@update = ISNULL(@parXml.value('(//@update)[1]','bit'),0),
		@sterg = ISNULL(@parXml.value('(//@sterg)[1]','bit'),0)

	if @parXML.exist('(/row/row/detalii)[1]')=1
		SET @detalii = @parXML.query('(/row/row/detalii/row)[1]')
	
	select
		@cod_serviciu_promo = 'PRODISC'

	IF @idPromotie IS NULL
		raiserror('Nu s-a identiticat promotia!',16,1)

	IF ISNULL(@cantitate_promotie,0)=0
		raiserror ('Cantitatea trebuie sa fie pozitiva',16,1)
		
	select	
		top 1 @cod=cod, @cantitate_cod=convert(decimal(15,2),@cantitate_promotie* (cantitate+cantitate_promo)), @cantitate_promotie=convert(decimal(15,2),cantitate_promo*@cantitate_promotie)
	From Promotii where idPromotie=@idPromotie	
	
	create table #preturi(cod varchar(20), umprodus varchar(3), nestlevel int)
	exec CreazaDiezPreturi
	insert into #preturi (cod, nestlevel)
	select @cod, @@NESTLEVEL

	exec wIaPreturi @sesiune=@sesiune, @parXML=@parXML
	select top 1 @pret=pret_vanzare from #preturi where cod=@cod

	IF OBJECT_ID('tempdb.dbo.#promo') is not null
		drop table #promo

	create table #promo (cod varchar(20), cantitate decimal(15,2), idlinie int, subtip varchar(2), detalii xml)
	IF @tip_document_generat='aviz'
		alter table #promo add pvaluta decimal(17,5)
	IF @tip_document_generat='comanda'
		alter table #promo add pret decimal(17,5)

	/* Nu se specifica coloanele la insert din cauza de SHMEN*/
	insert into #promo
	select @cod_serviciu_promo, convert(decimal(15,2),-@cantitate_promotie),1,'PR',@detalii, convert(decimal(17,5),@pret) UNION all
	select @cod cod, convert(decimal(15,2),@cantitate_cod),2,'PR',@detalii, convert(decimal(17,5),@pret)
	
	set @pozitii=(select * from #promo for xml raw, type)

	set @parXML.modify('delete /row/row')
	set @parXML.modify('insert sql:variable("@pozitii") into /row[1]')

	IF @tip_document_generat='aviz'
	begin
		set @parXML.modify('insert attribute returneaza_inserate {"1"} into /row[1]')

		select
			@idPozDoc = @parXML.value('(//@idpozdoc)[1]','int')
		
		IF @update = 1 OR @sterg = 1
		begin
	
			CREATE TABLE #legsters (idpozdoc1 int, idpozdoc2 int) 
			delete LegaturiPozDoc OUTPUT deleted.idPozDoc1, deleted.idPozDoc2 into #legsters (idpozdoc1, idpozdoc2) where idPozDoc1=@idPozDoc
			
			delete p
			from pozdoc p
			JOIN #legsters lp on lp.idPozDoc1=@idPozDoc and p.idPozDoc in (lp.idPozDoc1, lp.idPozDoc2)		

		end

		IF @sterg <> 1
		begin
			exec wScriuDoc @sesiune=@sesiune, @parXML=@parXML OUTPUT

			declare 
				@ddoc int, @numar varchar(20), @data datetime

			EXEC sp_xml_preparedocument @ddoc OUTPUT, @parXML
			IF OBJECT_ID('tempdb..#xmlPozitiiReturnate') IS NOT NULL
				DROP TABLE #xmlPozitiiReturnate
	
			SELECT
				idlinie, idPozDoc
			INTO #xmlPozitiiReturnate
			FROM OPENXML(@ddoc, '/row/docInserate/row')
			WITH
			(
				idLinie  int '@idlinie',
				idPozDoc int '@idPozDoc'

			)
			EXEC sp_xml_removedocument @ddoc 
		
			insert into LegaturiPozDoc (idPozDoc1, idPozDoc2)
			select
				x1.idPozdoc, x2.idPozDoc
			from #xmlPozitiiReturnate x1
			JOIN #xmlPozitiiReturnate x2 on x1.idlinie=1 and x2.idLinie=2

			set @parXML= (select top 1 subunitate, tip, numar, data from pozdoc p join #xmlPozitiiReturnate x on p.idPozDoc=x.idPozDoc for xml raw, type)
		end
		
	end

	IF @tip_document_generat='comanda'
	begin
		exec wScriuPozContracte @sesiune=@sesiune, @parXML=@parXML OUTPUT
	end

end try
begin catch
	declare @mesaj varchar(1000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
