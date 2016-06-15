--***  
CREATE procedure [dbo].wmIaDispozitiiTransfer @sesiune varchar(50), @parXML xml  
as  
if exists(select * from sysobjects where name='wmIaDispozitiiTransferSP' and type='P')
begin
	exec wmIaDispozitiiTransferSP @sesiune, @parXML output
	if @parXML is null
		return 0
end

set transaction isolation level READ UNCOMMITTED  
declare @tipdisp varchar(50)

begin try
	select	@tipdisp=@parXML.value('(/row/@tipdisp)[1]','varchar(200)')
	
	if @tipdisp is null 
	begin
		set @tipdisp='TE'
		set @parXML.modify('insert attribute tipdisp {sql:variable("@tipdisp")} into (/row)[1]')
		select @tipdisp as tipdisp for xml raw('atribute'), root('Mesaje')
	end
	
	exec wmIaDispozitiiLivrare @sesiune=@sesiune, @parXML=@parXML
end try
begin catch
	declare @eroare varchar(500)
	set @eroare=ERROR_MESSAGE()+'(wmIaDispozitiiTransfer)'
	raiserror(@eroare,11,1)
end catch
