--***
create procedure wVerificaFacturaSimplificata @sesiune varchar(50), @parXML XML
as
set nocount on
if exists(select * from sysobjects where name='wVerificaFacturaSimplificataSP' and type='P')      
begin
	exec wVerificaFacturaSimplificataSP @sesiune=@sesiune, @parXML=@parXML output
	if @parXML is null
		return 0 
end

set transaction isolation level read uncommitted
declare @ErrorMessage NVARCHAR(4000), @utilizator varchar(10), @subunitate varchar(9), 
		@tert varchar(50), @CasaDoc int, @vanzDoc varchar(50),@DataDoc datetime, @DataScad datetime, 
		@numarDoc int, @GESTPV varchar(20), @totaldocument float, @cursEur decimal(12,2),
		@facturaDinBon bit, @observatii varchar(8000), @UID varchar(50), @tipDoc varchar(2)
		
		
begin try

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	select	@UID = @parXML.value('(//document/@UID)[1]','varchar(50)'),
			@CasaDoc = @parXML.value('(//document/@casamarcat)[1]','int'),
			@DataDoc = @parXML.value('(/date/document/@data)[1]','datetime'),
			@numarDoc = @parXML.value('(//document/@numarDoc)[1]','int'),
			@tert = upper(@parXML.value('(//document/@tert)[1]','varchar(50)')),
			@tipDoc = @parXML.value('(//document/@tipdoc)[1]','varchar(2)'),
			@facturaDinBon = isnull(@parXML.value('(//document/@facturaDinBon)[1]','int'),0),
			@totaldocument = isnull(@parXML.value('(//document/@totaldocument)[1]','float'),0)
	
	-- daca nu e bon, sau nu e ales un tert, nu mai facem nimic
	if @tipDoc<>'AC' or ISNULL(@tert,'')=''
		return 0
	
	-- citesc ultimul curs euro pt data
	set @cursEur = isnull((select TOP 1 curs from curs where valuta='EUR' and data<=convert(datetime, convert(char(10), @DataDoc, 101), 101) order by data desc),1)
	
	-- verificam ca valoarea bonului sa nu depaseasca 100EUR
	if @totaldocument/@cursEur>100
		return 0
	
	-- stabilim daca tertul e platitor de tva. Daca nu e platitor de tva, nu emitem factura simplificata
	if ISNULL((
			select top 1 tipf 
			from TvaPeTerti t
			where t.tipf='B' and ISNULL(factura,'')=''
			and dela<=GETDATE() 
			and tert=@tert
			order by dela desc),'P') = 'N'
		return 0	
	
	-- alte validari specifice
	if exists(select * from sysobjects where name='wVerificaFacturaSimplificataSP1' and type='P')      
		exec wVerificaFacturaSimplificataSP1 @sesiune=@sesiune,@parXML=@parXML 
	
	select 1 as facturaSimplificata for xml raw('facturaSimplificata'), root('Mesaje')
	
end try
begin catch 
	SELECT @ErrorMessage = ERROR_MESSAGE()+' (wVerificaFacturaSimplificata)'
	RAISERROR (@ErrorMessage, 16, 1 )
end catch
	