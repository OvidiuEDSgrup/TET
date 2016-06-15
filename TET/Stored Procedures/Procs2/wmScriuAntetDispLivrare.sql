--***
CREATE PROCEDURE wmScriuAntetDispLivrare @sesiune VARCHAR(50), @parXML XML output
as
DECLARE @eroare VARCHAR(1000), @utilizator VARCHAR(50), @tert VARCHAR(100), @idDisp int, @descriere VARCHAR(2000),
		@factura VARCHAR(20), @gestiune VARCHAR(13), @data_facturii DATETIME, @ptupdate int, @detalii xml, @msg varchar(20),
		@dentert varchar(100), @dengestiune varchar(100), @tipdisp varchar(50), @gestPrim varchar(50), @procdetalii varchar(500),
		@detaliiStd xml


BEGIN TRY
	if exists (select 1 from sysobjects where [type]='P' and [name]='wmScriuAntetDispLivrareSP')
	begin 
		declare @returnValue int
		exec @returnValue = wmScriuAntetDispLivrareSP @sesiune, @parXML output
		if @parXML is null
			return @returnValue
	end
	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT  
	IF @utilizator is null 
		RETURN -1

	SELECT	@tipdisp = @parXML.value('(/*/@tipdisp)[1]', 'varchar(50)'),
			@idDisp=@parXML.value('(row/@iddisp)[1]','int'),
			@tert=@parXML.value('(row/@tert)[1]','varchar(50)'),
			@gestiune=@parXML.value('(row/@gestiune)[1]','varchar(50)'),
			@gestPrim = @parXML.value('(/*/@gestprim)[1]', 'varchar(50)'),
			@procdetalii = isnull(@parXML.value('(/*/@wmScriuAntetDispLivrare.procdetalii)[1]', 'varchar(500)'),'wmIaPozDispLivrare')
			
	
	if @gestiune is null 
	begin 
		declare @gest table(gestiune varchar(50))
		insert into @gest(gestiune)
		select RTRIM(valoare) from proprietati p where p.tip='UTILIZATOR' and p.cod=@utilizator and p.Cod_proprietate='GESTIUNE' and p.Valoare<>''
		
		if (select COUNT(*) from @gest)=1 -- daca are drept doar pe o gestiune, o selectez direct
			select @gestiune = gestiune from @gest
		else
		begin
			set @parXML.modify ('insert attribute wmIaGestiuni.procdetalii {sql:variable("@procdetalii")} into (/row)[1]')
			set @parXML.modify ('insert attribute wmIaGestiuni.titlumacheta {"Gestiunea predatoare"} into (/row)[1]')
			set @parXML.modify ('insert attribute wmIaGestiuni.numeatr {"@gestiune"} into (/row)[1]')
			
			exec wmIaGestiuni @sesiune=@sesiune, @parXML=@parXML
			
			select '1' as _neimportant for xml raw,Root('Mesaje')
			return 0
		end
	end
	
	if @tipdisp='AP' and @tert is null 
	begin 
		set @parXML.modify ('insert attribute wmIaTerti.procdetalii {sql:variable("@procdetalii")} into (/row)[1]')
		
		exec wmIaTerti @sesiune=@sesiune, @parXML=@parXML
		select '1' as _neimportant for xml raw,Root('Mesaje')
		
		return 0
	end
	
	if @tipdisp='TE' and @gestprim is null 
	begin 
		set @parXML.modify ('insert attribute wmIaGestiuni.procdetalii {sql:variable("@procdetalii")} into (/row)[1]')
		set @parXML.modify ('insert attribute wmIaGestiuni.titlumacheta {"Gestiunea primitoare"} into (/row)[1]')
		set @parXML.modify ('insert attribute wmIaGestiuni.numeatr {"@gestprim"} into (/row)[1]')
		
		exec wmIaGestiuni @sesiune=@sesiune, @parXML=@parXML
		select '1' as _neimportant for xml raw,Root('Mesaje')
		
		return 0
	end
	
	declare @disp table(idDisp int)

	-- gestiune, tert si gestprim sunt atribute standard
	set @detaliiStd = (select @gestiune gestiune, @tert tert, @gestPrim gestprim for xml raw)
	-- preiau orice artibute specifice mai exista
	exec adaugaAtributeXml @xmlSursa=@parXML, @xmlDest = @detalii output, @extrageDetalii=1
	-- unific detalii standard cu cele specifice
	exec adaugaAtributeXml @xmlSursa=@detaliiStd, @xmlDest = @detalii output
	
	
	insert into AntDisp (tipDisp,descriere,stare,utilizator,dataUltimeiOperatii,detalii)
	output inserted.idDisp into @disp
	select @tipdisp, @descriere, 'In lucru', @utilizator, GETDATE(),@detalii
	
	set @idDisp=(select top 1 idDisp from @disp)
	
	-- de gasit o descriere mai buna, cum ar fi denumirea gestiunii destinatare... 
	update AntDisp set descriere = tipDisp + CONVERT(varchar, idDisp) where idDisp = @idDisp
	
	if @parXML.value('(/row/@iddisp)[1]', 'int') is not null                        
		set @parXML.modify('replace value of (/row/@iddisp)[1] with sql:variable("@iddisp")') 
	else
		set @parXML.modify ('insert attribute iddisp {sql:variable("@iddisp")} into (/row)[1]') 
	
	select @idDisp as iddisp for xml raw('atribute'), root('Mesaje')
	
END TRY
BEGIN CATCH	
	SET @eroare=ERROR_MESSAGE() + ' (wmScriuAntetDispLivrare)'
	RAISERROR (@eroare,16,1)
END CATCH
