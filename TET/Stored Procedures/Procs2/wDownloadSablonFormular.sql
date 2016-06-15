--***
create procedure wDownloadSablonFormular @sesiune varchar(50)=null, @parxml xml=null
as
declare @eroare varchar(5000)
select @eroare=''
begin try
	declare @rez varchar(max), @formular varchar(max), @fisier varchar(max)
	select @formular=@parxml.value('(row/@formular)[1]','varchar(max)'),
			@fisier=@parxml.value('(row/@fisier)[1]','varchar(max)')
	if @formular is null
		raiserror ('Numarul formularului este necompletat!',16,1)
	
		declare @database varchar(2000)
		select @database=db_name(), @sesiune=isnull(@sesiune,'export')
		
		declare @cmdShellCommand varchar(3000), @caleform varchar(1000), @exml bit
	--> extrag ultimul nume al fisierului din antform:
		select @exml=exml from antform where numar_formular=@formular
		if not(@exml=1)
			raiserror('Formularul e fara sablon!',16,1)

		select @fisier=(case when len(isnull(@fisier,''))=0 then 'sablonFormular.xml' else @fisier end)

		select @caleform=rtrim(val_alfanumerica)+(case when left(reverse(rtrim(val_alfanumerica)),1)='\' then '' else '\' end)
			from par where tip_parametru='AR' and parametru='caleform'	--*/

		set @cmdShellCommand = 
			'bcp "SET QUOTED_IDENTIFIER ON select continut from ' + @database + '.dbo.xmlformular where numar_formular='''+rtrim(@formular)+'''" queryout "'
					+@caleform + @fisier + '" -C raw -c -T -r \n -S ' + convert(varchar(1000),serverproperty('ServerName'))
		select @cmdShellCommand
		exec xp_cmdshell @cmdShellCommand
		
		SELECT @fisier AS fisier, 'wTipFormular' AS numeProcedura
		FOR XML raw, root('Mesaje')

		delete tabelXML where sesiune=@sesiune
end try
begin catch
	select @eroare=error_message()+' (wDownloadSablonFormular)'
end catch
if len(@eroare)>0 raiserror(@eroare,16,1)
