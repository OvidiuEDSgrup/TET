/*

*/
CREATE PROCEDURE wmImportComandaDispLivrare @sesiune varchar(50), @parXML xml
AS
begin try
	-- apelare procedura specifica daca aceasta exista.
	if exists (select 1 from sysobjects where [type]='P' and [name]='wmImportComandaDispLivrareSP')
	begin 
		declare @returnValue int
		exec @returnValue = wmImportComandaDispLivrareSP @sesiune, @parXML output
		if @parXML is null
			return @returnValue
	end

	declare @tip varchar(50), @utilizator varchar(50), @mesaj varchar(1000), @xmlDisp xml, @xmlNou xml, @xmlPreluare xml, @comanda varchar(50), @denTip varchar(50),
			@idDisp int, @gestiune varchar(50), @tert varchar(50), @gestprim varchar(50)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	
	--raiserror('lucrez wmImportComandaDispLivrare.', 16, 1)
	
	select	@tip = @parXML.value('(/*/@tipdisp)[1]', 'varchar(50)'),
			@denTip = (case @tip when 'AP' then 'Factura' when 'TE' then 'Transfer' else @tip end),
			@comanda = @parXML.value('(/*/@comanda)[1]', 'varchar(50)'),
			@idDisp = isnull(@parXML.value('(/*/@iddisp)[1]', 'int'),0)
	
	if ISNULL(@comanda,'')='' 
		raiserror('Comanda invalida', 16,1)
	
	if @idDisp=0
	begin
		-- iau date de pe comanda aleasa... ma bazez ca wmIaComenzi afisaza comenzi valide
		select @gestiune = c.gestiune, @tert = c.tert, @gestprim = c.gestiune_primitoare
		from Contracte c 
		where c.idContract = @comanda
		
		if @tert is not null
			if @parXML.value('(row/@tert)[1]','varchar(50)') is not null                        
				set @parXML.modify('replace value of (/row/@tert)[1] with sql:variable("@tert")') 
			else
				set @parXML.modify ('insert attribute tert {sql:variable("@tert")} into (/row)[1]') 
		
		if @gestiune is not null
			if @parXML.value('(row/@gestiune)[1]','varchar(50)') is not null                        
				set @parXML.modify('replace value of (/row/@gestiune)[1] with sql:variable("@gestiune")') 
			else
				set @parXML.modify ('insert attribute gestiune {sql:variable("@gestiune")} into (/row)[1]') 
		
		if @gestPrim is not null
			if @parXML.value('(row/@gestprim)[1]','varchar(50)') is not null                        
				set @parXML.modify('replace value of (/row/@gestprim)[1] with sql:variable("@gestprim")') 
			else
				set @parXML.modify ('insert attribute gestprim {sql:variable("@gestprim")} into (/row)[1]') 
		
		-- in cazul in care e nevoie de alti pasi pt completare antet...
		if @parXML.value('(row/@wmScriuAntetDispLivrare.procdetalii)[1]','varchar(50)') is not null                        
			set @parXML.modify('replace value of (/row/@wmScriuAntetDispLivrare.procdetalii)[1] with "wmImportComandaDispLivrare"') 
		else
			set @parXML.modify ('insert attribute wmScriuAntetDispLivrare.procdetalii {"wmImportComandaDispLivrare"} into (/row)[1]') 
	
		exec wmScriuAntetDispLivrare @sesiune=@sesiune, @parXML=@parXML output
		set @idDisp = isnull(@parXML.value('(/*/@iddisp)[1]', 'int'),0)
		
		if @iddisp=0
			return 0
	end
	
	insert into PozDispOp(idDisp, cod, cantitate, pret, utilizator, data_operarii)
	select @idDisp, pc.cod, pc.cantitate, pc.pret, @utilizator, GETDATE()
	from PozContracte pc
	where pc.idContract=@comanda
	group by pc.cod, pc.cantitate, pc.pret
	
	exec wmIaPozDispLivrare @sesiune=@sesiune, @parXML=@parXML
	
end try
BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wmImportComandaDispLivrare)'
END CATCH

IF LEN(@mesaj) > 0
	RAISERROR (@mesaj, 16, 1)
