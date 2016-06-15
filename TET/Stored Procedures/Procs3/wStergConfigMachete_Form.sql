--***
create procedure wStergConfigMachete_Form (@sesiune varchar(50), @parXML xml)
as

declare @mesaj varchar(500), @r_meniu varchar(20), @r_tip varchar(2), @r_subtip varchar(2), @r_datafield varchar(50),
		@r_ordine int
		
begin try
	set @r_meniu = @parXML.value('(/row/@r_meniu)[1]','varchar(20)')
	set @r_tip = isnull(@parXML.value('(/row/@r_tip)[1]','varchar(2)'),'')
	set @r_subtip = isnull(@parXML.value('(/row/@r_subtip)[1]','varchar(2)'),'')
	set @r_datafield = isnull(@parXML.value('(/row/@r_datafield)[1]','varchar(50)'),'')
	set @r_ordine = isnull(@parXML.value('(/row/@r_ordine)[1]','int'),0)

	delete from webConfigForm
	where Meniu=@r_meniu
		and (isnull(Tip,'')=@r_tip)
		and (isnull(Subtip,'')=@r_subtip)
		and (isnull(Datafield,'')=@r_datafield)

	/* Se renumeroteaza campurile ramase:*/
	select meniu,tip,subtip,datafield,row_number() over (order by ordine,nume) ordine
		into #ptOrdine
		from webconfigform 
			where Meniu=@r_meniu
			and isnull(Tip,'')=isnull(@r_tip,'') 
			and isnull(Subtip,'')=isnull(@r_subtip,'')

	update v set v.ordine=n.ordine
	from webConfigForm v
	inner join #ptOrdine n on v.meniu=n.meniu and isnull(v.tip,'')=isnull(n.tip,'') and isnull(v.Subtip,'')=isnull(n.Subtip,'') and v.DataField=n.DataField
			
	exec wIaConfigMachete_Form @sesiune=@sesiune, @parXML=@parXML
end try

begin catch
	set @mesaj = error_message() + ' (wStergConfigMachete_Form)'
	raiserror(@mesaj, 11, 1)
end catch
