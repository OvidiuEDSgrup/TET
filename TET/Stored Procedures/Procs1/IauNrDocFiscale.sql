--***
create procedure IauNrDocFiscale @Id int, @Numar int output
as

set @Numar = 0

update docfiscale
set UltimulNr = UltimulNr + (case when UltimulNr >= NumarSup then 0 else 1 end), 
	@Numar = (case when UltimulNr >= NumarSup then @Numar else UltimulNr + 1 end)
where Id=@Id
