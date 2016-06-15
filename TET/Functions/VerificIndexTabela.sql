--***
/**	functie pt. verificare camp tabela	*/
Create
function VerificIndexTabela (@Tabela char(50), @Index char(50))
Returns int
As
Begin
	declare @rezultat int
	set @rezultat=0
	if exists (select o.id from syscolumns c, sysobjects o, sysindexes i, sysindexkeys k 
	where o.type='U' and o.id=c.id and i.id=o.id and k.id=o.id and k.indid=i.indid 
	and k.colid=c.colorder and o.name=@Tabela and i.name=@Index)
		set @rezultat=1

	return @rezultat
End

/*
select dbo.VerificIndexTabela ('D112AngajatorA', 'Data')
*/
