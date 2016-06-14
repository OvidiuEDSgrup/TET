
LTER procedure [dbo].[wACFacturiBenefSP] @sesiune varchar(50), @parXML XML OUTPUT 
as  

declare @mesaj varchar(200), @furnbenef varchar(1), @cont varchar(13)

select @furnbenef=isnull(@parXML.value('(/row/@furnbenef)[1]', 'varchar(1)'),
		ISNULL(@parXML.value('(/row/@cFurnBenef)[1]', 'varchar(1)'), '')),
	@cont=isnull(@parXML.value('(/row/@contbenef)[1]', 'varchar(1)'),'')

begin try
	set @furnbenef='B'
	set @parXML.modify ('insert attribute furnbenef{sql:variable("@furnbenef")} into (/row)[1]')
	
	IF @cont=''
		set @cont='418.0'
	set @parXML.modify ('insert attribute cont{sql:variable("@cont")} into (/row)[1]')
	
	exec yso.wACFacturi @sesiune=@sesiune,@parXML=@parXML
end try
begin catch
	set @mesaj = '(wACFacturiBenefSP)'+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
else
	return 0