/*	tratam pentru inceput in operatia de modificare date pozitie la Alte documente, doar atribute din XML (indicator bugetar exceptie) */
create procedure wOPModificareDateAD @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModificareDateADSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPModificareDateADSP @sesiune, @parXML
	return @returnValue
end

begin try
	declare @sub varchar(9), @tip varchar(2), @numar varchar(30), @data datetime, @idPozadoc int, 
		@parXMLDetalii xml, @detalii xml, @indbug varchar(20), @o_indbug varchar(20)
	
	select @tip=@parXML.value('(/parametri/@tip)[1]','varchar(2)'),
		@numar=@parXML.value('(/parametri/@numar)[1]','varchar(30)'),
		@data=@parXML.value('(/parametri/@data)[1]','datetime'),
		@idPozadoc=@parXML.value('(/parametri/row/@idpozadoc)[1]','int'),
		@indbug = isnull(@parXML.value('(/parametri[1]/detalii/row/@indicator)[1]','varchar(20)'),''),
		@o_indbug = isnull(@parXML.value('(/parametri[1]/o_detalii/row/@indicator)[1]','varchar(20)'),'')

	exec luare_date_par 'GE','SUBPRO',0,0,@sub output
	
	select @detalii=detalii from pozadoc
	where idPozadoc=@idPozadoc

	/*	completare in pozplin.detalii a indicatorului bugetar modificat */
	if @indbug<>@o_indbug
	begin
		set @parXMLDetalii=(select 'indicator' as atribut, rtrim(@indbug) as valoare for xml raw)
		exec ActualizareInXml @parXMLDetalii, @detalii output
	end

	update pozadoc set detalii=@detalii
	where idPozadoc=@idPozadoc
end try 
begin catch
	declare @error varchar(500)
	set @error=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@error,16,1)
end catch

/* 
select * from pozadoc
sp_help pozadoc
*/
