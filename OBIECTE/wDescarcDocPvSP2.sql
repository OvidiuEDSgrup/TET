--***
if exists (select * from sysobjects where name ='wDescarcDocPvSP2')
	drop procedure wDescarcDocPvSP2
go
--***
create procedure wDescarcDocPvSP2 @sesiune varchar(50), @parXML xml, @idrulare int=0
as

set transaction isolation level read uncommitted

set nocount on
declare @UID varchar(50), @GestBon varchar(13),@factura varchar(20), @idAntetBon int,
	@Casa int,@Data datetime,@NrBon int,@Vanz varchar(10), @tert varchar(13), @dataScad datetime, @CategP varchar(5), @PctLiv varchar(20),
	@dataStart datetime, @msgEroare varchar(max), @eroareTimeout bit, @xml xml


begin try

--/*sp
declare @procid int=@@procid, @objname sysname
set @objname=object_name(@procid)
EXEC wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql=@objname
--sp*/

end try
begin catch
	set @msgEroare = ERROR_MESSAGE()+'. (idAntetBon='+convert(varchar,isnull(@idantetbon,0))+') (wDescarcDocPvSP2)'
	if @@trancount>0
		rollback tran
end catch

if len(@msgEroare)>0
	raiserror(@msgeroare,11,1)
go