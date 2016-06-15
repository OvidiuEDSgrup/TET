
Create procedure wOPFisierImport_p @sesiune varchar(50), @parXML xml
as

declare @mesaj varchar(500), @database varchar(50)
begin try
	set @database = db_name()
	if @database in ('edlia') and @@SERVERNAME='aswdev'
		raiserror('Nu este permis importul de machete pe aceasta baza de date!',16,1)
	if exists (select 1 from sys.objects where name='webconfigmeniu' and type='V')
		raiserror('O tabela de configurari este view! Nu este permis importul de machete in aceasta situatie!',16,1)
	--select @parxml
end try

begin catch
	set @mesaj = error_message() + ' (wOPFisierImport_p)'
	select '1' as inchideFereastra for xml raw, root('Mesaje')
	raiserror(@mesaj, 16, 1)
end catch
