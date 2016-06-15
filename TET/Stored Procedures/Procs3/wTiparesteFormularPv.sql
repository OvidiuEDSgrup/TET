/* proc. apelata din PVria, pt tiparirea de formulare */
create procedure wTiparesteFormularPv @sesiune varchar(50), @parXML XML
as

set transaction isolation level read uncommitted
declare @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT, @debug bit, @utilizator varchar(10), @cDataDoc char(10),
		@factura varchar(20), @codFormular varchar(50), @tert varchar(50), @idAntetBon int, @eBon bit, @numar varchar(20),
		@tipDoc varchar(50)

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	-- pt. cazurile in care se doreste prelucrare inainte de apel wtipformular...
	declare @returnValue int
	if exists(select * from sysobjects where name='wTiparesteFormularPvSP' and type='P')      
	begin
		exec @returnValue = wTiparesteFormularPvSP @sesiune=@sesiune,@parXML=@parXML output
		if @parXML is null 
			return @returnValue 
	end

	select	@codFormular = upper(@parXML.value('(/row/@codFormular)[1]','varchar(50)')),
			@idAntetBon = upper(@parXML.value('(/row/@idAntetBon)[1]','int')),
			--@factura = upper(@parXML.value('(/row/@factura)[1]','varchar(20)')),
			--@DataDoc = @parXML.value('(/row/@data)[1]','datetime'),
			--@tert = upper(@parXML.value('(/row/@tert)[1]','varchar(50)')),
			@debug = @parXML.value('(/row/@debug)[1]','varchar(50)')

	select @factura=b.Factura, @cDataDoc=convert(char(10) ,isnull(b.Data_facturii, b.data_bon), 101), @tert=b.Tert, @eBon=b.Chitanta, @numar=convert(varchar(30),b.Numar_bon),
		@tipDoc = isnull(b.bon.value('(/date/document/@tipdoc)[1]','varchar(20)'),'AP')
	from antetBonuri b
	where b.idAntetBon=@idAntetBon
	
	if @factura is null and @eBon=1 -- formular pentru bonuri (se apeleaza aceasta proc. doar cand e pusa setarea respectiva).
		set @factura=@numar
	
	if @parXML.value('(/row/@tip)[1]','varchar(50)') is null
		set @parXML.modify ('insert attribute tip {sql:variable("@tipDoc")} into (/row)[1]')
	else
		set @parXML.modify('replace value of (/row/@tip)[1] with sql:variable("@tipDoc")')
	
	if @parXML.value('(/row/@nrform)[1]','varchar(50)') is null
		set @parXML.modify ('insert attribute nrform {sql:variable("@codFormular")} into (/row)[1]')
	else
		set @parXML.modify('replace value of (/row/@nrform)[1] with sql:variable("@codFormular")')
	
	if @parXML.value('(/row/@numar)[1]','varchar(50)') is null
		set @parXML.modify ('insert attribute numar {sql:variable("@factura")} into (/row)[1]')
	else
		set @parXML.modify('replace value of (/row/@numar)[1] with sql:variable("@factura")')
	
	if @factura is not null
		if @parXML.value('(/row/@factura)[1]','varchar(50)') is null
			set @parXML.modify ('insert attribute factura {sql:variable("@factura")} into (/row)[1]')
		else
			set @parXML.modify('replace value of (/row/@factura)[1] with sql:variable("@factura")')
	
	if @parXML.value('(/row/@data)[1]','varchar(50)') is null
		set @parXML.modify ('insert attribute data {sql:variable("@cDataDoc")} into (/row)[1]')
	else
		set @parXML.modify('replace value of (/row/@data)[1] with sql:variable("@cDataDoc")')
	
	if @parXML.value('(/row/@tert)[1]','varchar(50)') is null
		set @parXML.modify ('insert attribute tert {sql:variable("@tert")} into (/row)[1]')
	else
		set @parXML.modify('replace value of (/row/@tert)[1] with sql:variable("@tert")')
	
	if @parXML.value('(/row/@idantetbon)[1]','varchar(50)') is null
		set @parXML.modify ('insert attribute idantetbon {sql:variable("@idAntetBon")} into (/row)[1]')
	else
		set @parXML.modify('replace value of (/row/@idantetbon)[1] with sql:variable("@idAntetBon")')
	
	if @parXML.value('(/row/@debug)[1]','varchar(50)') is null
		set @parXML.modify ('insert attribute debug {sql:variable("@debug")} into (/row)[1]')
	else
		set @parXML.modify('replace value of (/row/@debug)[1] with sql:variable("@debug")')

	exec wTipFormular @sesiune=@sesiune, @parXML=@parXML

end try
begin catch 
	SELECT @ErrorMessage = ERROR_MESSAGE()+' (wTiparesteFormularPv)', @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )
end catch


