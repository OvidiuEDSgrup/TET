--***
/**	functie pt. verificare camp tabela	*/
Create
function VerificCampTabela (@Tabela char(50), @Camp char(50))
Returns int
As
Begin
	declare @DimensiuneCamp int
	set @DimensiuneCamp=1
	if exists (select * from sysobjects where name = @Tabela) 
		select @DimensiuneCamp=isnull((select syscolumns.length from syscolumns,sysobjects 
			where sysobjects.name=@Tabela and sysobjects.id=syscolumns.id and syscolumns.name=@Camp),0)

	return @DimensiuneCamp
End
