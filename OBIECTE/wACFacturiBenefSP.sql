
ALTER procedure [dbo].[wACFacturiBenefSP] @sesiune varchar(50), @parXML XML OUTPUT 
as  

declare @mesaj varchar(200), @furnbenef varchar(1), @contfact varchar(13)

select @furnbenef=isnull(@parXML.value('(/row/@furnbenef)[1]', 'varchar(1)'),
		ISNULL(@parXML.value('(/row/@cFurnBenef)[1]', 'varchar(1)'), '')),
	@contfact=isnull(@parXML.value('(/row/@contfact)[1]', 'varchar(13)'),'')

begin try
	set @furnbenef='B'
	set @parXML.modify ('insert attribute furnbenef{sql:variable("@furnbenef")} into (/row)[1]')
	
	IF @contfact=''
		set @contfact='418.0'
	set @parXML.modify ('insert attribute contfact{sql:variable("@contfact")} into (/row)[1]')
	
	exec wACFacturi @sesiune=@sesiune,@parXML=@parXML
end try
begin catch
	set @mesaj = '(wACFacturiBenefSP)'+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
else
	return 0