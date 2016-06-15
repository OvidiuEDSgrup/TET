
create procedure wOPAntetDoc @sesiune varchar(50), @parXML xml
as

declare @mesaj varchar(500)

begin try
	declare @GUID varchar(100), @CUIfurnizor varchar(20)
	set @GUID = @parXML.value('(/parametri/factura/@GUID)[1]','varchar(100)')
	set @CUIfurnizor = @parXML.value('(/parametri/factura/@CUIfurnizor)[1]','varchar(20)')

	set @parXML.modify('insert (attribute GUID {sql:variable("@GUID")}, attribute CUIfurnizor {sql:variable("@CUIfurnizor")}) into (/parametri[1])')

	select 'Pozitii document' nume, 'DO' codmeniu, 'PD' tip, 'PD' subtip, 'O' tipmacheta, (select @parXML for xml raw, type) dateInitializare
	for xml raw('deschideMacheta'), root('Mesaje')
end try

begin catch
	set @mesaj = error_message() + ' (wOPAntetDoc)'
	raiserror(@mesaj, 11, 1)
end catch
