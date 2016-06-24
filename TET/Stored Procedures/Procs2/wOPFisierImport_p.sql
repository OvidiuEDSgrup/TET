
Create procedure wOPFisierImport_p @sesiune varchar(50), @parXML xml
as

declare @mesaj varchar(500)
begin try
	declare @database varchar(50), @ignora_erori bit
	select @database = db_name(), @ignora_erori=0
	if @database in ('edlia') and @@SERVERNAME='aswdev' and @ignora_erori=0
		raiserror('Nu este permis importul de machete pe aceasta baza de date!',16,1)
	if exists (select 1 from sys.objects where name='webconfigmeniu' and type='V') and @ignora_erori=0
		raiserror('O tabela de configurari este view! Nu este permis importul de machete in aceasta situatie!',16,1)
	--select @parxml
end try

begin catch
	set @mesaj = error_message() + ' (wOPFisierImport_p)'
	select '1' as inchideFereastra for xml raw, root('Mesaje')
	raiserror(@mesaj, 16, 1)
end catch
