

create procedure wStergSituatieRezervari @sesiune varchar(50),@parXML XML      
as

declare
	@mesaj varchar(max), @idPozDoc int

begin try
	select
		@idPozDoc = @parXML.value('(/row/@idPozDoc)[1]','int')

	if isnull(@idPozDoc,0)<>0
	begin
		delete from LegaturiContracte where idPozDoc=@idPozDoc
		delete from pozdoc where idPozDoc=@idPozDoc
	end
end try

begin catch
	set @mesaj = error_message() + ' (' + object_name(@@procid) + ')'
	raiserror (@mesaj,16,1)
end catch
