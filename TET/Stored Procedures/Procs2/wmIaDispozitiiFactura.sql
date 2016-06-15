--***  
CREATE procedure [dbo].wmIaDispozitiiFactura @sesiune varchar(50), @parXML xml  
as  
if exists(select * from sysobjects where name='wmIaDispozitiiFacturaSP' and type='P')
begin
	exec wmIaDispozitiiFacturaSP @sesiune, @parXML output
	if @parXML is null
		return 0
end

set transaction isolation level READ UNCOMMITTED  
declare @tipdisp varchar(50)

begin try
	select	@tipdisp=@parXML.value('(/row/@tipdisp)[1]','varchar(200)')
	
	if @tipdisp is null 
	begin
		set @tipdisp='AP'
		set @parXML.modify('insert attribute tipdisp {sql:variable("@tipdisp")} into (/row)[1]')
		select @tipdisp as tipdisp for xml raw('atribute'), root('Mesaje')
	end
	
	exec wmIaDispozitiiLivrare @sesiune=@sesiune, @parXML=@parXML
end try
begin catch
	declare @eroare varchar(500)
	set @eroare=ERROR_MESSAGE()+'(wmIaDispozitiiFactura)'
	raiserror(@eroare,11,1)
end catch
