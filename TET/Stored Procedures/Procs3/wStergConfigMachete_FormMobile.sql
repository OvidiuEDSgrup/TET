--***
create procedure wStergConfigMachete_FormMobile (@sesiune varchar(50), @parXML xml)
as
	declare @eroare varchar(max)
		,@Identificator varchar(100)
		,@DataField varchar(100)
begin try
	select @Identificator = @parXML.value('(/row/@identificator)[1]','varchar(100)')
		,@DataField = @parXML.value('(/row/@datafield)[1]','varchar(50)')
	
	if @identificator is null or @datafield is null
		raiserror('Nu a fost identificata linia!',16,1)
	
	delete w from webconfigformmobile w where w.identificator=@identificator and w.datafield=@datafield
end try
begin catch
	set @eroare = error_message() + ' Nu a fost stearsa configurarea! ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@eroare, 11, 1)
end catch
