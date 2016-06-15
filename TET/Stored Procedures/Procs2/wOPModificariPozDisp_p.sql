create procedure wOPModificariPozDisp_p @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModificariPozDisp_pSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPModificariPozDisp_pSP @sesiune, @parXML
	return @returnValue
end

declare @iddisp int, @idpoz int, @cantitate_diferenta float, @explicatii_diferenta varchar(250), @detalii xml
begin try
	select @iddisp	= @parXML.value('(/*/@iddisp)[1]', 'int'),
		@idpoz	= @parXML.value('(/*/*/@idpoz)[1]', 'int')
		
	SET @detalii=isnull((select detalii from PozDispOp where idDisp=@idDisp and idPoz=@idpoz),'<row> </row>')
	
	select	@cantitate_diferenta =@detalii.value('(/row/@cantitate_diferenta)[1]', 'float'),
		@explicatii_diferenta =@detalii.value('(/row/@explicatii_diferenta)[1]', 'varchar(250)')	

	select convert(decimal(12,5),@cantitate_diferenta) cantitate_diferenta, @explicatii_diferenta as explicatii_diferenta
	for xml raw
end try 

begin catch
	declare @error varchar(500)
	set @error=ERROR_MESSAGE()
	raiserror(@error,16,1)
end catch
