
create procedure wOPExportMachete @sesiune varchar(50), @parXML xml
as

declare @mesaj varchar(500), @fisier varchar(255), @database varchar(50)

begin try
	set @database = db_name()
	set @fisier = isnull(@parXML.value('(/*/@fisier)[1]','varchar(255)'),'')

	if @fisier = ''
	begin
		set @mesaj = 'Nu a fost selectat un nume pentru fisier.'
		raiserror(@mesaj, 16, 11)
	end

	set @parXML.modify('insert (attribute database {sql:variable("@database")}) into (/parametri[1])')

	exec wScriuFisierExport @sesiune=@sesiune, @parXML=@parXML

end try

begin catch
	set @mesaj = error_message() + ' (wOPExportMachete)'
	raiserror(@mesaj, 11, 1)
end catch
