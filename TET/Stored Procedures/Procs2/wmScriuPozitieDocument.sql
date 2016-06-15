
CREATE procedure wmScriuPozitieDocument @sesiune varchar(50), @parXML xml
as
begin try
if exists(select * from sysobjects where name='wmScriuPozitieDocumentSP' and type='P')
begin
	exec wmScriuPozitieDocumentSP @sesiune=@sesiune, @parXML=@parXML
	return 0
end

	declare
		@subunitate varchar(10), @numar varchar(20), @tip varchar(2), @data datetime, @cod varchar(20), @cantitate decimal(15,2), @gestiune varchar(20), @lm varchar(20),
		@utilizator varchar(100),@update bit, @numarpozitie int, @tert varchar(20),@gestiune_primitoare varchar(20),@cont_coresp varchar(20),
		@doc XML, @pstoc decimal(15,5), @pvaluta decimal(15,5), @factura varchar(20), @data_factura datetime, @idpozdoc int, @codgs1 varchar(1000),
		@actiune varchar(50), @scanat int, @tva_deductibil float, @detalii xml, @valuta varchar(20), @curs float, @comanda varchar(20), @discount float,
		@um varchar(30), @coeficient float, @tiptva int

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	exec luare_date_par 'GE','SUBPRO',null,null,@subunitate output

	select 
		@numar=@parXML.value('(/*/@numar)[1]','varchar(20)'),
		@data=@parXML.value('(/*/@data)[1]','datetime'),
		@data_factura=@parXML.value('(/*/@data_factura)[1]','datetime'),
		@tip=@parXML.value('(/*/@tip)[1]','varchar(2)'),
		
		@cod=@parXML.value('(/*/@cod)[1]','varchar(20)'),
		@um=@parXML.value('(/*/@um)[1]','varchar(20)'),
		@codgs1=@parXML.value('(/*/@codgs1)[1]','varchar(1000)'),
		
		@tert=@parXML.value('(/*/@tert)[1]','varchar(20)'),
		@numarpozitie=@parXML.value('(/*/@numarpozitie)[1]','int'),
		@idpozdoc=@parXML.value('(/*/@idpozdoc)[1]','int'),
		@cantitate=@parXML.value('(/*/@cantitate)[1]','decimal(15,2)'),
		@pstoc=@parXML.value('(/*/@pstoc)[1]','decimal(15,5)'),
		@pvaluta=@parXML.value('(/*/@pvaluta)[1]','decimal(15,5)'),
		@update=ISNULL(@parXML.value('(/*/@update)[1]','bit'),0),
		@gestiune = @parXML.value('(/*/@gestiune)[1]','varchar(20)'),
		@gestiune_primitoare = @parXML.value('(/*/@gestiune_primitoare)[1]','varchar(20)'),
		@cont_coresp = @parXML.value('(/*/@contcoresp)[1]','varchar(20)'),
		@factura = UPPER(@parXML.value('(/*/@factura)[1]','varchar(20)')),
		@actiune = @parXML.value('(/*/@wmScriuPozitieDocument.actiune)[1]','varchar(50)')
		
	if @actiune is null and ISNULL(@codgs1,'')=''
		set @actiune='back(1)'

	select top 1 @coeficient=coeficient from umprodus where cod=@cod and um=@um

	if @cantitate is null -- asta inseamna ca este apelata din scanare simpla, fara form de cantitate
		if exists(select 1 from pozdoc where subunitate='1' and tip=@tip and numar=@numar and data=@data and cod=@cod)
		begin
			select 
				@update=1,
				@idpozdoc=idPozDoc, 
				@cantitate=convert(decimal(15,2),cantitate+isnull(@coeficient,1))
			from pozdoc
			where subunitate=@subunitate and tip=@tip and numar=@numar and data=@data and cod=@cod
		end
		else
			set @cantitate=isnull(@coeficient,1)

	select top 1 
		@pvaluta=pret_valuta,
		@tva_deductibil=tva_deductibil,
		@valuta=valuta,
		@curs=curs,
		@lm=loc_de_munca,
		@comanda=comanda,
		@discount=discount,
		@detalii=detalii
	from pozdoc
	where subunitate=@subunitate and tip=@tip and numar=@numar and data=@data and cod=@cod

	-- Se foloseste atributul scanat pentru ordonarea codurilor scanate (ultimul cod scanat apare primul in lista)
	select @scanat=max(isnull(detalii.value('(/*/@scanat)[1]','int'),0))+1 from pozdoc where tip=@tip and numar=@numar and data=@data
	if @detalii is null
		set @detalii = (select @scanat as scanat for xml raw)
	else
	begin
		if @detalii.value('count(/row/@scanat)','int')=0
			set @detalii.modify('insert attribute scanat {sql:variable("@scanat")} into (/row)[1]')
		else
			set @detalii.modify('replace value of (/row/@scanat)[1] with sql:variable("@scanat")')
	end

	select top 1 
		@tert=rtrim(cod_tert), @gestiune=rtrim(Cod_gestiune), @gestiune_primitoare=rtrim(Gestiune_primitoare), 
		@factura=RTRIM(factura), @data_factura=data_facturii, @tiptva=cota_tva
	FROM Doc where tip=@tip and numar=@numar and data=@data

	if @cantitate=0 and @idpozdoc>0 and @update=1 and @detalii.exist('(/row/@cant_scriptica)')=0
		delete from pozdoc where idpozdoc=@idpozdoc
	else
	begin 
		set @doc=
		(
			select 
				@tip tip, @numar numar, convert(varchar(10),@data,101) data, '1' subunitate, @lm lm, @gestiune gestiune,'1' fara_luare_date,@update [update],
				@tert tert,@gestiune_primitoare gestprim,@cont_coresp contcorespondent,@factura factura, convert(varchar(10),@data_factura,101) datafacturii,
				rtrim(@valuta) valuta, convert(decimal(15,4),@curs) curs, @tiptva as tiptva,
				(
					SELECT
						@cod cod, @cantitate cantitate, @update [update], @numarpozitie numarpozitie,@idpozdoc idpozdoc,(case when @pstoc IS NOT NULL then @pstoc end) pstoc, 
						(case when @pvaluta IS NOT NULL then convert(decimal(14,4),@pvaluta) end) pvaluta, rtrim(@comanda) comanda, @discount discount,
						@codgs1 codgs1, (case when @tva_deductibil is not null then convert(decimal(15,2),@tva_deductibil) end) sumatva, @detalii detalii
					for xml raw, TYPE
				)
			for xml raw
		)
		
		if exists (select * from sysobjects where name ='wScriuDoc')
			exec wScriuDoc @sesiune=@sesiune, @parXML=@doc
		else 
		if exists (select * from sysobjects where name ='wScriuDocBeta')
			exec wScriuDocBeta @sesiune=@sesiune, @parXML=@doc
		else 
			raiserror('Eroare configurare: aceasta procedura necesita folosirea procedurii wScriuDoc.', 16, 1)
	end
	
	select @actiune as actiune
	for xml RAW, ROOT('Mesaje')

end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch
