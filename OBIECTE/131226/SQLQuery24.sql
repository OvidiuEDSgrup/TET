select * from sys.triggers t join sys.objects o on o.object_id=t.object_id
where t.is_disabled=1
--alter table facturi enable trigger yso_tr_validFacturi