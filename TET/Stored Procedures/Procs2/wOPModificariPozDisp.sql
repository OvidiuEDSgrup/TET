create procedure wOPModificariPozDisp @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModificariPozDispSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPModificariPozDispSP @sesiune, @parXML
	return @returnValue
end

declare @iddisp int, @idpoz int, @cantitate_diferenta float, @explicatii_diferenta varchar(250), @detalii xml
begin try
	select @iddisp	= @parXML.value('(/*/@iddisp)[1]', 'int'),
		@idpoz	= @parXML.value('(/*/*/@idpoz)[1]', 'int'),
		@cantitate_diferenta =isnull(@parXML.value('(/parametri/@cantitate_diferenta)[1]', 'float'),0),
		@explicatii_diferenta =isnull(@parXML.value('(/parametri/@explicatii_diferenta)[1]', 'varchar(250)'),'')
	
	SET @detalii=isnull((select detalii from PozDispOp where idDisp=@idDisp and idPoz=@idpoz),'<row> </row>')
	
	if @detalii.value('(/row/@cantitate_diferenta)[1]', 'float') is not null                         
		set @detalii.modify('replace value of (/row/@cantitate_diferenta)[1] with sql:variable("@cantitate_diferenta")') 
	else
		set @detalii.modify ('insert attribute cantitate_diferenta {sql:variable("@cantitate_diferenta")} into (/row)[1]')	
		
	if @detalii.value('(/row/@explicatii_diferenta)[1]', 'varchar(250)') is not null                         
		set @detalii.modify('replace value of (/row/@explicatii_diferenta)[1] with sql:variable("@explicatii_diferenta")') 
	else
		set @detalii.modify ('insert attribute explicatii_diferenta {sql:variable("@explicatii_diferenta")} into (/row)[1]')		


	update PozDispOp set detalii=@detalii
	where idDisp=@iddisp
		and idPoz=@idpoz
end try
begin catch
	declare @error varchar(500)
	set @error=ERROR_MESSAGE()
	raiserror(@error,16,1)
end catch
--select * from PozDispOp
