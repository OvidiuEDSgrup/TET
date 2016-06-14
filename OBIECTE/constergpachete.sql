drop trigger [dbo].[yso_constergpachete]
go
CREATE trigger [dbo].[yso_constergpachete] on [dbo].[pozcon] for delete as 
if 0<(select count(*) from deleted d where exists
		(select 1 from pozcon p 
		inner join con c on c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Data=p.Data and c.Tert=p.Tert
		where c.Subunitate=d.Subunitate and c.Tip=d.Tip and c.Data=d.Data and c.Tert=d.Tert
			and c.Contract=RTRIM(d.Contract)+'.'+REPLICATE('0',3-LEN(d.numar_pozitie))+RTRIM(d.numar_pozitie) 
			--and c.Contract_coresp=d.Cod and c.Mod_plata='1'
		)) 
begin RAISERROR ('Violare integritate date. Incercare de stergere pozitie pachet cu comanda speciala pentru componente. Stergeti mai intai comanda speciala asociata pachetului!', 16, 1) 
rollback transaction end 