/*	tratam pentru inceput in operatia de modificare date pozitie la Note contabile, doar atribute din XML (indicator bugetar exceptie si fara_indicator) 
	Atributul fara_indicator indica faptul ca pentru acea pozitie nu se va lua in considerare indicatorul din dreptul conturilor/indicatorul exceptie. Acea pozitie va avea inregistrare fara indicator bugetar.
	Atributul va fi folosit in procedura indbugPozitieDocument	*/
create procedure wOPModificareDateNC @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModificareDateNCSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPModificareDateNCSP @sesiune, @parXML
	return @returnValue
end

begin try
	declare @sub varchar(9), @tip varchar(2), @numar varchar(30), @data datetime, @idPozncon int, 
		@parXMLDetalii xml, @detalii xml, @indbug varchar(20), @o_indbug varchar(20), @fara_indicator varchar(20), @o_fara_indicator varchar(20)
	
	select @tip=@parXML.value('(/parametri/@tip)[1]','varchar(2)'),
		@numar=@parXML.value('(/parametri/@numar)[1]','varchar(30)'),
		@data=@parXML.value('(/parametri/@data)[1]','datetime'),
		@idPozncon=@parXML.value('(/parametri/row/@idpozncon)[1]','int'),
		@indbug = isnull(@parXML.value('(/parametri[1]/detalii/row/@indicator)[1]','varchar(20)'),''),
		@o_indbug = isnull(@parXML.value('(/parametri[1]/o_detalii/row/@indicator)[1]','varchar(20)'),''),
		@fara_indicator = isnull(@parXML.value('(/parametri[1]/detalii/row/@fara_indicator)[1]','int'),0),
		@o_fara_indicator = isnull(@parXML.value('(/parametri[1]/o_detalii/row/@fara_indicator)[1]','int'),0)

	exec luare_date_par 'GE','SUBPRO',0,0,@sub output
	
	select @detalii=detalii from pozncon
	where idPozncon=@idPozncon

	/*	completare in pozplin.detalii a indicatorului bugetar modificat */
	if @indbug<>@o_indbug
	begin
		set @parXMLDetalii=(select 'indicator' as atribut, rtrim(@indbug) as valoare for xml raw)
		exec ActualizareInXml @parXMLDetalii, @detalii output
	end

	/*	completare in pozplin.detalii a atributului fara_indicator */
	if @fara_indicator<>@o_fara_indicator
	begin
		set @parXMLDetalii=(select 'fara_indicator' as atribut, rtrim(@fara_indicator) as valoare for xml raw)
		exec ActualizareInXml @parXMLDetalii, @detalii output
	end

	update pozncon set detalii=@detalii
	where idPozncon=@idPozncon
end try 
begin catch
	declare @error varchar(500)
	set @error=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@error,16,1)
end catch

/* 
select * from pozncon
sp_help pozncon
*/
