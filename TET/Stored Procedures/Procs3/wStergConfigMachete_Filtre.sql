--***
create procedure wStergConfigMachete_Filtre (@sesiune varchar(50), @parXML xml)
as

declare @mesaj varchar(500), @t_meniu varchar(20), @t_tip varchar(20), @t_subtip varchar(20), @t_datafield1 varchar(50)
		
begin try
	set @t_meniu = @parXML.value('(/row/@t_meniu)[1]','varchar(20)')
	set @t_tip = @parXML.value('(/row/@t_tip)[1]','varchar(20)')
	set @t_datafield1 = isnull(@parXML.value('(/row/@t_datafield1)[1]','varchar(50)'),'')

	delete from webConfigFiltre
	where Meniu=@t_meniu
		and (Tip=@t_tip)
		and (isnull(Datafield1,'')=@t_datafield1)

	exec wIaConfigMachete_Filtre @sesiune=@sesiune, @parXML=@parXML
end try

begin catch
	set @mesaj = error_message() + ' (wStergConfigMachete_Filtre)'
	raiserror(@mesaj, 11, 1)
end catch
