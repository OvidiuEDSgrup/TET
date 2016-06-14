
--***
CREATE trigger [dbo].[yso_delpozconexp] on [dbo].[pozcon] for delete not for replication as
begin
	delete from pozcon where pozcon.Subunitate  like 'EXPAND%' and exists (select 1 from deleted 
		where deleted.tip=pozcon.tip and deleted.contract=pozcon.contract and deleted.tert=pozcon.tert and deleted.data=pozcon.data and deleted.cod=pozcon.cod and deleted.Numar_pozitie=pozcon.Numar_pozitie)

end