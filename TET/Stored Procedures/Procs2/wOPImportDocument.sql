
create procedure wOPImportDocument @sesiune varchar(50),@parXML XML      
as

declare
	@mesaj varchar(max), @sql nvarchar(max), @cale varchar(max), @document varchar(500)

begin try

	exec luare_date_par @tip='AR', @par='CALEFORM', @val_l=NULL, @val_n=NULL, @val_a=@cale output

	if object_id('tempdb..##impdoc') is not null drop table ##impdoc

	select @document = @parXML.value('(/*/@document)[1]','varchar(500)')
	select @cale = rtrim(@cale) + 'uploads\' + @document
	select @sql =  'select * into ##impdoc from openrowset(''Microsoft.ACE.OLEDB.12.0'',
					''Excel 8.0;Database='+ @cale +';HDR=YES;IMEX=1'',
					''SELECT * FROM [Sheet1$]'')'

	exec sp_executesql @sql

	if not exists (select * from sysobjects where name='wOPImportDocumentSP')
		raiserror('Nu exista definita o procedura care sa proceseze documentul importat.',16,1)
	else
		exec wOPImportDocumentSP @sesiune=@sesiune, @parXML=@parXML

	if object_id('tempdb..##impdoc') is not null drop table ##impdoc

end try

begin catch
	set @mesaj = error_message() + ' (' + object_name(@@procid)+')'
	raiserror(@mesaj, 16, 1)
end catch

