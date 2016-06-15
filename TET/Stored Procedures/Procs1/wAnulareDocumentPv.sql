/* proc. apelata din PVria, pt. anularea tuturor operatiilor efectuate asupra unui document, pt. ca eu fost erori.
(de ex. stergere din pozdoc/bonuri cand a fost eroare de tiparire la casa de marcat).
 */
create procedure wAnulareDocumentPv @sesiune varchar(50), @parXML XML
as
declare @returnValue int
if exists(select * from sysobjects where name='wAnulareDocumentPvSP' and type='P')      
begin
	exec @returnValue = wAnulareDocumentPvSP @sesiune,@parXML
	return @returnValue 
end

set transaction isolation level read uncommitted
declare @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT, @debug bit, @utilizator varchar(10), 
		@idAntetBon int, @numarDoc varchar(20), @tipDoc char(2), @dataDoc datetime, @UID varchar(50), @sub varchar(50)

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	select	@sub=(case when parametru='SUBPRO' then rtrim(val_alfanumerica) else @sub end)
	from par 
	where Tip_parametru='GE' and Parametru='SUBPRO'

	select	@idAntetBon = @parXML.value('(/row/@idAntetBon)[1]','int'),
			@UID = @parXML.value('(/row/@UID)[1]', 'varchar(50)')
	
	-- @idAntetBon poate fi null daca da timeout apelare wScriuDatePv
	if isnull(@idAntetBon,0)=0
		select @idAntetBon=idAntetBon
			from antetBonuri
			where [UID]=@UID
	
	-- citesc din xml numarul de document din pozdoc aferent acestuia. Se completeaza in XML in proc. wDescarcBon.
	select	@numarDoc = bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(50)'),
			@tipDoc=(case when Chitanta=1 then 'AC' else 'AP' end),
			@dataDoc=Data_bon
		from antetBonuri 
		where idAntetBon=@idAntetBon
	
	if @numarDoc is not null
	begin
		-- sterg pozitiile vandute
		delete from pozdoc where Subunitate=@sub and tip=@tipDoc and Numar=@numarDoc and data=@dataDoc and stare=5
		
		-- sterg tranferul aferent(daca s-a facut)
		if @tipDoc='AC'
			delete from pozdoc where Subunitate=@sub and tip='TE' and Numar=@numarDoc and data=@dataDoc and stare=5
	end
	
	delete from bp where idAntetBon=@idAntetBon
	delete from bt where idAntetBon=@idAntetBon
	delete from antetBonuri where idAntetBon=@idAntetBon

	-- pt. cazurile in care cineva ar mai vrea sa faca ceva cand se anuleaza un document - cum ar fi logarea faptului ca a esuat...
	if exists(select * from sysobjects where name='wAnulareDocumentPvSP1' and type='P')      
	begin
		exec @returnValue = wAnulareDocumentPvSP1 @sesiune=@sesiune,@parXML=@parXML output
		return @returnValue 
	end
	
end try
begin catch 
	SELECT @ErrorMessage = ERROR_MESSAGE()+' (wAnulareDocumentPv)', @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )
end catch


