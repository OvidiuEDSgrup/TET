create procedure wOPRefacereInregistrariContabile_p @sesiune varchar(50), @parXML xml
as

begin try
	declare @tip varchar(2)
	
	Set @tip = ISNULL(@parXML.value('(/row/@tip)[1]', 'char(2)'), '')
	
	select null RM, null PP, null CM, null AP, null [AS], null AC, null TE, null DF, null PF, 
		null CI, null AF, null AI, null AE, 
		(case when @tip not in ('RE','EF','DE','DR') then null else 1 end) PI, null AD, null NC
	for xml raw
end try 

begin catch
	declare @error varchar(500)
	set @error='(wOPRefacereInregistrariContabile_p): ' +ERROR_MESSAGE()
	raiserror(@error,16,1)
end catch
