--***
create procedure rapCosturiPeConturi @sesiune varchar(50), @datajos datetime, @datasus datetime
as
declare @eroare varchar(1000)
set @eroare=''
begin try
	set transaction isolation level read uncommitted
/*	declare @userASiS varchar(50)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output*/
	SELECT * FROM dbo.fRapCosturiPeConturi(@sesiune, @datajos, @datasus) c
		order by cont, ordine
end try
begin catch
	set @eroare=error_message()
	raiserror(@eroare,16,1)
end catch
