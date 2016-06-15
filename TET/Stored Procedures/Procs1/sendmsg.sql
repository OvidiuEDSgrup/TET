--***
create procedure sendmsg @destinatar char(15), @mesaj varchar(255) as
	declare @cmd varchar(255)
	set @cmd='net send '+rtrim(@destinatar)+' '+rtrim(@mesaj)
	exec master..xp_cmdshell @cmd
