	
create procedure wmTiparesteFormularDocument @sesiune varchar(50), @parXML xml as
begin try

	exec wTipFormular @sesiune=@sesiune, @parXML=@parXML
	select 'back(1)' as actiune for xml raw, root('Mesaje')

end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch
