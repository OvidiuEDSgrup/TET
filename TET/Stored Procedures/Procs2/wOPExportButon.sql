
create procedure wOPExportButon @sesiune varchar(50), @parXML xml
as

declare
	@mesaj varchar(max), @codButon varchar(100)

begin try
	select '1' as inchideFereastra for xml raw, root('Mesaje')
	
	select @codButon = @parXML.value('(/row/@codButon)[1]','varchar(100)')

	if isnull(@codButon,'')=''
		raiserror('Selectati butonul care se exporta.',16,1)

	if object_id('tempdb..##butoanePV') is not null 
		drop table ##butoanePV
	
	create table ##butoanePV(butonXML xml)

	insert into ##butoanePV(butonXML)
	select 
		(select
			codButon,activ,ordine,label,culoare,tipButon,ctrlKey,tasta,procesarePeServer,apareInPV,apareInOperatii,tipIncasare,meniu,tip,subtip,utilizator
		for xml raw)
	from butoanePV where codButon=@codButon

	declare @cmdShellCommand varchar(3000), @caleform varchar(1000), @fisier varchar(100) = 'Buton_' + @codButon
	select @caleform=rtrim(val_alfanumerica)+(case when left(reverse(rtrim(val_alfanumerica)),1)='\' then '' else '\' end)
		from par where tip_parametru='AR' and parametru='caleform'
	set @cmdShellCommand = 'bcp "select replace(convert(varchar(max),butonXML),''>'',''>''+char(10)) from ##butoanePV" queryout '+@caleform + @fisier + '.xml -c -T -r \n -S ' + convert(varchar(1000),serverproperty('ServerName'))
	exec xp_cmdshell @cmdShellCommand
	
	SELECT @fisier + '.xml' AS fisier, 'wTipFormular' AS numeProcedura
		FOR XML raw, root('Mesaje')

	if object_id('tempdb..##butoanePV') is not null 
		drop table ##butoanePV

end try

begin catch
	set @mesaj=error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 11, 1)
end catch
