--***
create procedure wStergConfigMachete_Grid (@sesiune varchar(50), @parXML xml)
as

declare @mesaj varchar(500), @g_meniu varchar(20), @g_tip varchar(20), @g_subtip varchar(20), @g_data_field varchar(50), @g_in_pozitii bit
		
begin try
	set @g_meniu = @parXML.value('(/row/@g_meniu)[1]','varchar(20)')
	set @g_tip = isnull(@parXML.value('(/row/@g_tip)[1]','varchar(20)'),'')
	set @g_subtip = isnull(@parXML.value('(/row/@g_subtip)[1]','varchar(20)'),'')
	set @g_data_field = isnull(@parXML.value('(/row/@g_data_field)[1]','varchar(50)'),'')
	set @g_in_pozitii = isnull(@parXML.value('(/row/@g_in_pozitii)[1]','bit'),0)

	delete from webConfigGrid
	where Meniu=@g_meniu
		and (isnull(Tip,'')=@g_tip)
		and (isnull(Subtip,'')=@g_subtip)
		and (isnull(Datafield,'')=@g_data_field)
		and isnull(InPozitii,0)=@g_in_pozitii

	/* Se renumeroteaza campurile ramase:*/
	select meniu,tip,subtip,datafield, isnull(g.inpozitii,0) inpozitii, row_number() over (order by ordine,g.numecol) ordine
		into #ptOrdine
		from webConfigGrid g
			where Meniu=@g_meniu
			and isnull(Tip,'')=isnull(@g_tip,'') 
			and isnull(Subtip,'')=isnull(@g_subtip,'')
			and isnull(InPozitii,0)=isnull(@g_in_pozitii,0)

	update v set v.ordine=n.ordine
	from webConfigGrid v
	inner join #ptOrdine n on v.meniu=n.meniu and isnull(v.tip,'')=isnull(n.tip,'') and isnull(v.Subtip,'')=isnull(n.Subtip,'') and v.DataField=n.DataField and isnull(n.InPozitii,0)=isnull(v.inpozitii,0)

	exec wIaConfigMachete_Grid @sesiune=@sesiune, @parXML=@parXML
end try

begin catch
	set @mesaj = error_message() + ' (wStergConfigMachete_Grid)'
	raiserror(@mesaj, 11, 1)
end catch
