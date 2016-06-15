create procedure yso_raiserror @mesajEroare varchar(1000)='Error.' as
rollback tran
raiserror(@mesajEroare,11,1)