--drop trigger yso_testpozdoc
--go
--create trigger yso_testpozdoc on pozdoc for insert,update as 
--if exists (select 1 from inserted i where  not exists 
--	(select 1 from doc d where d.Subunitate=i.Subunitate and d.Tip=i.Tip and d.Numar=i.Numar and d.Data=i.Data))
--raiserror('nu exista antet',11,1)
--go
--declare @triggername nvarchar(1034)
select * from sys.trigger_events e 
inner join sys.triggers t on t.object_id=e.object_id 
inner join sys.objects o on o.object_id=t.parent_id
where o.name='pozdoc' and e.type_desc='INSERT' and e.is_last=1

--sp_settriggerorder @triggername= 'tr_ValidPozdoc', @order='None', @stmttype = 'INSERT'
--go
