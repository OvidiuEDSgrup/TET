--***
create procedure wDownloadSablonFormular_p @sesiune varchar(50)=null, @parXML xml='<row />'
as
begin
	declare @formular varchar(max), @fisier varchar(max), @exml bit
	select @formular=@parxml.value('(row/@formular)[1]','varchar(max)')
	--> extrag ultimul nume al fisierului din antform:
		select @exml=exml, @fisier=reverse(rtrim(transformare))+'\' from antform where numar_formular=@formular
		if not(@exml=1)
			raiserror('Formularul e fara sablon!',16,1)

		select @fisier=reverse(left(@fisier,charindex('\', @fisier)-1))
		select @fisier=(case when len(isnull(@fisier,''))=0 then 'sablonFormular.xml' else @fisier end)
		select @formular formular, @fisier fisier for xml raw
end
