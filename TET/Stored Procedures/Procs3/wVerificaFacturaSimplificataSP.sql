--***
create procedure wVerificaFacturaSimplificataSP @sesiune varchar(50), @parXML XML OUTPUT
as
set nocount on
set transaction isolation level read uncommitted

declare @ErrorMessage NVARCHAR(4000), @utilizator varchar(10), @subunitate varchar(9), 
		@tert varchar(50), @CasaDoc int, @vanzDoc varchar(50),@DataDoc datetime, @DataScad datetime, 
		@numarDoc int, @GESTPV varchar(20), @totaldocument float, @cursEur decimal(12,2),
		@facturaDinBon bit, @observatii varchar(8000), @UID varchar(50), @tipDoc varchar(2)
		
		
begin try
	SET @parXML = null
	return 0 
end try
begin catch 
	SELECT @ErrorMessage = ERROR_MESSAGE()+' (wVerificaFacturaSimplificataSP)'
	RAISERROR (@ErrorMessage, 16, 1 )
end catch
	