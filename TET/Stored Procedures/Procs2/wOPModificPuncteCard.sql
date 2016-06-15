
create procedure wOPModificPuncteCard(@sesiune varchar(50), @parXML xml)
as

declare
	@mesaj varchar(500), @uid varchar(36), @data datetime, @puncteacordate decimal(17,2), @puncte decimal(17,2)

begin try

	select
		@uid = @parXML.value('(/row/@uid)[1]','varchar(36)'),
		@data = @parXML.value('(/row/@data_modificarii)[1]','datetime'),
		@puncte = @parXML.value('(/row/@puncte)[1]','decimal(17,2)'),
		@puncteacordate = @parXML.value('(/row/@puncteacordate)[1]','decimal(17,2)')
	
	declare @insertedAntetBonuri table(idNou int)

	insert into antetBonuri(Casa_de_marcat, Chitanta, Numar_bon, Data_bon, Vinzator,Observatii,UID)
	output inserted.IdAntetBon 
	into @insertedAntetBonuri(idNou)	
	select -1,0, ident_current('antetbonuri')+1, @data,'job', 'Modificare manuala ' + @uid, NEWID()

	if (@puncteacordate<0) and (@puncte-abs(@puncteacordate) < 0)
	begin
		set @mesaj = 'Numarul de puncte diminuate nu poate depasi numarul total de puncte disponibile (' + convert(varchar(20),@puncte) + ')!'
		raiserror(@mesaj,16,1)
	end

	insert into PvPuncte(idAntetBon,UID_card,Tip,Puncte)
	select (select idNou from @insertedAntetBonuri),@uid,(case when @puncteacordate<0 then 'C' else 'D' end),abs(@puncteacordate)

end try

begin catch
	select @mesaj = ERROR_MESSAGE() + ' (wOPModificPuncteCard)'
	raiserror(@mesaj,11,1)
end catch
