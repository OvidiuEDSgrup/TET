--select * from webconfigmeniu
if exists (select 1 from sys.objects where name='webconfigmeniu_tr')
	drop trigger webconfigmeniu_tr
	GO
--***
create trigger webconfigmeniu_tr
	on webconfigmeniu
	after insert, update, delete
as

	--> pentru a detecta mai usor tipul operatiei, in caz de update se adauga '/update' la sfarsit:
declare @insert varchar(100),
		@delete varchar(100)
select @insert='insert',
		@delete='delete'
if (select count(1) from inserted)>0 and (select count(1) from deleted)>0
	select @insert=@insert+'/update', @delete=@delete+'/update'

	--> jurnalizarea:
insert into syssWebConfigMeniu
(user_name, host_name, program_name, tip_operatie, data_modificarii, Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil, publicabil)
select suser_name(), host_name(), program_name(), @delete, getdate(), Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil, publicabil
	from deleted
union all
select suser_name(), host_name(), program_name(), @insert, getdate(), Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil, publicabil
	from inserted

if exists (select top (1) 1 from inserted i where i.Nume like '%trust%' or i.Nume like '% tet%' or i.Nume like '%tet %' )
begin
	exec yso_raiserror 'Duplicate index in table WebConfigMeniu.'
end
