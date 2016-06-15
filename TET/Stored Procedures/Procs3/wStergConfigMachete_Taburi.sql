--***
create procedure wStergConfigMachete_Taburi (@sesiune varchar(50), @parXML xml)
as

declare @mesaj varchar(500), @b_meniu_sursa varchar(50), @b_tip_sursa varchar(50), @b_nume_tab varchar(100)
		
begin try
	set @b_meniu_sursa = @parXML.value('(/row/@b_meniu_sursa)[1]','varchar(50)')
	set @b_tip_sursa = @parXML.value('(/row/@b_tip_sursa)[1]','varchar(50)')
	set @b_nume_tab = @parXML.value('(/row/@b_nume_tab)[1]','varchar(100)')

	delete from webConfigTaburi
	where MeniuSursa=@b_meniu_sursa
		and (TipSursa=@b_tip_sursa)
		and (NumeTab=@b_nume_tab)

	exec wIaConfigMachete_Taburi @sesiune=@sesiune, @parXML=@parXML
end try

begin catch
	set @mesaj = error_message() + ' (wStergConfigMachete_Taburi)'
	raiserror(@mesaj, 11, 1)
end catch
