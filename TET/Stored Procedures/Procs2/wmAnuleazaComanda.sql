
create procedure wmAnuleazaComanda @sesiune varchar(50), @parXML xml  
as
set transaction isolation level read uncommitted

if exists(select * from sysobjects where name='wmAnuleazaComandaSP' and type='P')  
begin
	exec wmAnuleazaComandaSP @sesiune=@sesiune, @parXML=@parXML
	return 0
end

declare 
	@mesaj varchar(max), @comanda int, @confirmare xml, @da xml, @nu xml

begin try	
	select @comanda = @parXML.value('(/row/@comanda)[1]','int')

	if (select top 1 modificabil from JurnalContracte j inner join StariContracte s on s.stare=j.stare where idContract=@comanda order by data desc)<>1
	begin
		raiserror('Comanda este intr-o stare in care nu poate fi modificata.',16,1)
		select 'back(1)' as actiune for xml raw, Root('Mesaje')
	end

	select @confirmare = 
		(select 
			'' as cod, 
			'Sigur doriti sa stergeti aceasta comanda?' as denumire, 
			'0x004080' as culoare 
		for xml raw)

	select @da = 
		(select 
			1 as cod, 
			'Da' as denumire, 
			@comanda as comanda,
			'0xffffff' as culoare, 
			'wmConfirmareAnulareComanda' as procdetalii, 
			'server://assets/Imagini/Meniu/yes.png' as poza 
		for xml raw)

	select @nu = 
		(select 
			0 as cod, 
			'Nu' as denumire, 
			'0xffffff' as culoare, 
			'wmConfirmareAnulareComanda' as procdetalii, 
			'server://assets/Imagini/Meniu/no.png' as poza 
		for xml raw)

	select 
		@confirmare,@da,@nu
	for xml path('Date')

	select 0 as toateatr for xml raw,Root('Mesaje')  
end try

begin catch
	set @mesaj = error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 11, 1)
end catch
