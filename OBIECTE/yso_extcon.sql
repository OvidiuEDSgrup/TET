drop trigger yso_extcon 
go
create trigger yso_extcon on extcon after insert,update as

if exists (select 1 from inserted i inner join con c on c.Subunitate=i.Subunitate and c.Tip=i.Tip and c.Contract=i.Contract
			and c.Tert=i.Tert and c.Data=i.Data and c.Contract_coresp<>i.Camp_3
		where i.Subunitate='1' and i.Tip='BK' and i.Camp_3<>'')
	update con
	set Contract_coresp=i.Camp_3
	from inserted i inner join con c on c.Subunitate=i.Subunitate and c.Tip=i.Tip and c.Contract=i.Contract
			and c.Tert=i.Tert and c.Data=i.Data and c.Contract_coresp<>i.Camp_3
	where i.Subunitate='1' and i.Tip='BK' and i.Camp_3<>''