--***
create procedure wIaMFpublice @sesiune varchar(50), @parXML xml
as
begin try
	declare @mesajeroare varchar(500)--, @subunitate varchar(9), @filtruGestiune varchar(9), @filtruDenumire varchar(30)

	select rtrim(Cod) as cod, rtrim(Denumire) as denumire
	from MFpublice --select * from MFpublice
	order by Cod
	for xml raw
end try

begin catch
	set @mesajeroare=ERROR_MESSAGE()
	raiserror(@mesajeroare,11,1)
end catch	
