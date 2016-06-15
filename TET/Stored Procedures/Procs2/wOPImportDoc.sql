
create procedure wOPImportDoc @sesiune varchar(50), @parXML xml
as

declare @mesaj varchar(500)

begin try
	declare @calefisier varchar(255), @caleform varchar(1000), @comanda nvarchar(4000), @importXML xml
	set @calefisier = @parXML.value('(/parametri/@calefisier)[1]','varchar(255)')

	if isnull(@calefisier,'') = ''
	begin
		set @mesaj = 'Nu s-a ales niciun fisier pentru import.'
		raiserror(@mesaj,16,1)
	end

	select @caleform=rtrim(val_alfanumerica)+(case when left(reverse(rtrim(val_alfanumerica)),1)='\' then '' else '\' end)+'uploads\'
		from par where tip_parametru='AR' and parametru='caleform'

	select @comanda='SELECT @importXML = convert(XML,x)
	FROM OPENROWSET
     (BULK '''+@caleform+@calefisier+''',
      SINGLE_BLOB) AS T(X)'

    exec sp_executesql @comanda, N'@importXML XML OUTPUT', @importXML OUTPUT;

	select 'Antet document' nume, 'DO' codmeniu, 'AD' tip, 'AD' subtip, 'O' tipmacheta, (select @importXML for xml raw, type) dateInitializare
	for xml raw('deschideMacheta'), root('Mesaje')

end try

begin catch
	set @mesaj = error_message() + ' (wOPImportDoc)'
	raiserror(@mesaj, 11, 1)
end catch
