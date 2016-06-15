--***
CREATE PROCEDURE wmScriuAntetDispReceptie @sesiune VARCHAR(50), @parXML XML output
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wmScriuAntetDispReceptieSP')
begin 
	declare @returnValue int
	exec @returnValue = wmScriuAntetDispReceptieSP @sesiune, @parXML output
	return @returnValue
end
DECLARE @eroare VARCHAR(1000), @utilizator VARCHAR(50), @tert VARCHAR(100), @idDisp int, @descriere VARCHAR(2000)
	,@factura VARCHAR(20), @gestiune VARCHAR(13), @data_facturii varchar(10), @ptupdate int,@detalii xml,@msg varchar(20)
	,@dentert varchar(100),@dengestiune varchar(100)

--sp_help antdisp
BEGIN TRY
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT  
	IF @utilizator is null 
		RETURN -1

	SELECT	@idDisp=@parXML.value('(row/@iddisp)[1]','int')
		,@descriere=@parXML.value('(row/@descriere)[1]','VARCHAR(2000)')
		,@factura=@parXML.value('(row/@factura)[1]','VARCHAR(20)')
		,@tert=@parXML.value('(row/@tert)[1]','VARCHAR(13)')
		,@gestiune=@parXML.value('(row/@gestiune)[1]','VARCHAR(13)')
		,@msg=isnull(@parXML.value('(row/@msg)[1]','VARCHAR(20)'),'')
		,@data_facturii=@parXML.value('(row/@data_facturii)[1]','varchar(10)')	
---------- scriere propriu-zisa:
	
	------formare xml detalii------------
	SET @detalii=isnull((select detalii from AntDisp where idDisp=@idDisp),'<row />')
	
	if ISNULL(@tert,'')<>''  
	begin
		if @detalii.value('(/row/@tert)[1]', 'varchar(13)') is not null                        
			set @detalii.modify('replace value of (/row/@tert)[1] with sql:variable("@tert")') 
		else
			set @detalii.modify ('insert attribute tert {sql:variable("@tert")} into (/row)[1]') 
		
	end
	if ISNULL(@factura,'')<>''
		if @detalii.value('(/row/@factura)[1]', 'varchar(20)') is not null 
			set @detalii.modify('replace value of (/row/@factura)[1] with sql:variable("@factura")') 
		else
			set @detalii.modify ('insert attribute factura {sql:variable("@factura")} into (/row)[1]') 
	
	if ISNULL(@gestiune,'')<>''
	begin
		if @detalii.value('(/row/@gestiune)[1]', 'varchar(13)') is not null                         
			set @detalii.modify('replace value of (/row/@gestiune)[1] with sql:variable("@gestiune")') 
		else
			set @detalii.modify ('insert attribute gestiune {sql:variable("@gestiune")} into (/row)[1]')
		
	end
	
	if ISNULL(@data_facturii,'')<>''	
	begin
		-- de convertit data facturii daca trebuie (de verificat cum vine din mobile)
		-- set @data_facturii=CONVERT(varchar(10),@data_facturii,101)
		if @detalii.value('(/row/@data_facturii)[1]', 'char(10)') is not null                         
			set @detalii.modify('replace value of (/row/@data_facturii)[1] with sql:variable("@data_facturii")') 
		else
			set @detalii.modify ('insert attribute data_facturii {sql:variable("@data_facturii")} into (/row)[1]')		
	end
	
	-- cazul in care nu exista setat deja numarul de receptie care se va genera din aceasta dispozitie, il setam acum,
	--(solutie temporara, pana la rezolvarea problemelor de refresh)
	if @detalii.value('(/row/@numar_receptie)[1]', 'varchar(8)') is null                         
	begin
		declare @NrDocPrimit varchar(20), @idPlajaPrimit int, @xmlTemp xml, @lm varchar(13)
		
		set @lm = ISNULL(@detalii.value('(/row/@lm)[1]', 'varchar(13)'),'')
		set @xmlTemp=(select 'RM' tip, @utilizator utilizator, @lm lm for xml raw)
		exec wIauNrDocFiscale @parXML=@xmlTemp, @NrDoc=@NrDocPrimit output,@Numar= @NrDocPrimit output,@idPlaja=@idPlajaPrimit output
		
		set @detalii.modify ('insert attribute numar_receptie {sql:variable("@NrDocPrimit")} into (/row)[1]')		
	end
	
	if @detalii.value('(/row/@data_receptie)[1]', 'datetime') is null                         
	begin
		declare @data_receptie varchar(10)
		set @data_receptie= CONVERT(char(10),getdate(),101)
		set @detalii.modify ('insert attribute data_receptie {sql:variable("@data_receptie")} into (/row)[1]')		
	end
	
	SET @ptupdate=(CASE WHEN @idDisp is null THEN 0 ELSE 1 END)

	IF @ptupdate=1--daca se face update
	BEGIN
		UPDATE AntDisp SET descriere=@descriere, detalii=@detalii
		WHERE idDisp=@idDisp
	ENd
	else
	begin
		IF OBJECT_ID('tempdb..#idDisp') IS NOT NULL
			DROP TABLE #idDisp
		
		CREATE TABLE #idDisp (idDisp INT)
		
		--inserare antet cu returnarea id-ului nou inserat	
		insert into AntDisp (tipDisp,descriere,stare,utilizator,dataUltimeiOperatii,detalii)
		output inserted.idDisp into #idDisp
		select 'FC',@descriere,'In lucru',@utilizator,GETDATE(),@detalii
		
		set @idDisp=(select top 1 idDisp from #idDisp)
		
		if @parXML.value('(/row/@iddisp)[1]', 'int') is not null                        
			set @parXML.modify('replace value of (/row/@iddisp)[1] with sql:variable("@iddisp")') 
		else
			set @parXML.modify ('insert attribute iddisp {sql:variable("@iddisp")} into (/row)[1]') 
	end

	SELECT case when isnull(@msg,'')<>'' then  'back(2)' else 'back(1)' end AS actiune
	FOR XML RAW,ROOT('Mesaje')

END TRY
BEGIN CATCH	
	SET @eroare='(wmScriuAntetDispReceptie:) '+ERROR_MESSAGE()
	RAISERROR (@eroare,16,1)
END CATCH
