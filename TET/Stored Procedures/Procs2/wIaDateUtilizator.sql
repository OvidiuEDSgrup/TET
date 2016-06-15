--***
Create procedure wIaDateUtilizator @sesiune varchar(10)
as

declare @userASiS varchar(50)
/*Modificare pentru login utilizator sa */
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
IF @userASiS IS NULL
	RETURN -1

select top 1 rtrim(u.id) as id, rtrim(u.nume) as nume, rtrim(u.observatii) as winuser, ISNULL(p.Val_alfanumerica,'') as firma from utilizatori u 
left outer join par p on p.Tip_parametru='GE' and p.Parametru = 'NUME'
where u.ID = @userASiS
for xml raw
