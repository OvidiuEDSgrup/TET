--***
create procedure wStergConfigMachete_Tipuri (@sesiune varchar(50), @parXML xml)
as

declare @mesaj varchar(500), @p_meniu varchar(20), @p_tip varchar(20), @p_subtip varchar(20), @p_ordine int
		
begin try
	set @p_meniu = @parXML.value('(/row/@p_meniu)[1]','varchar(20)')
	set @p_tip = isnull(@parXML.value('(/row/@p_tip)[1]','varchar(20)'),'')
	set @p_subtip = isnull(@parXML.value('(/row/@p_subtip)[1]','varchar(20)'),'')
	set @p_ordine = isnull(@parXML.value('(/row/@p_ordine)[1]','int'),0)

	delete from webConfigTipuri
	where Meniu=@p_meniu
		and (isnull(Tip,'')=@p_tip)
		and (isnull(Subtip,'')=@p_subtip)
		and (isnull(Ordine,0)=@p_ordine)

	exec wIaConfigMachete_Tipuri @sesiune=@sesiune, @parXML=@parXML
end try

begin catch
	set @mesaj = error_message() + ' (wStergConfigMachete_Tipuri)'
	raiserror(@mesaj, 11, 1)
end catch
