--***
if exists (select * from sysobjects where name ='tr_validConturi' and xtype='TR')
	drop trigger tr_validConturi
go
--***
create  trigger tr_validConturi on conturi for insert,update, delete NOT FOR REPLICATION as
DECLARE @nrRanduri int,@mesaj varchar(255)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN

begin try
	if (select max(case when i.cont is null and(p.Cont_creditor is not null or p.Cont_debitor is not null) then '' else 'corect' end)
		from deleted d
		left outer join inserted i on d.Cont=i.Cont and d.Subunitate=i.Subunitate and d.Are_analitice=i.Are_analitice and d.Cont_parinte=i.Cont_parinte
		left outer join pozincon p on d.Cont=p.Cont_creditor or d.Cont=p.Cont_debitor)=''
		raiserror('Eroare operare (pozdoc.tr_validConturi): Acest cont are inregistrari contabile!',16,1)	
		
end try
begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
	RETURN
end catch
--select * from conturi
--sp_help conturi