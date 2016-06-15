CREATE  PROCEDURE wAnulezBonPV @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	if exists (select 1 from sysobjects where [type]='P' and [name]='wAnulezBonPVSP1')
		exec wAnulezBonPVSP1 @sesiune=@sesiune, @parXML=@parXML output

	if @parxml is null
		return 0

	declare 
		@idComandaHrc int
	select 
		@idComandaHrc=@parXML.value('(//@idComandaHrc)[1]','int')

	delete from ct where idComanda=@idComandaHrc
	delete ComenziHRC where idComanda=@idComandaHrc
	

END TRY
begin catch
	declare @mesaj varchar(4000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch


