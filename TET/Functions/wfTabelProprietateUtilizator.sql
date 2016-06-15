--***
/* functia returneaza valoarea proprietatii atasate utilizatorului trimis ca parametru
Trebuie trimis si utilizatorul pt ca sa se poata lucra si cand utilizatorul se determina din sesiune */
create function wfTabelProprietateUtilizator(@cod_proprietate varchar(20), @utilizator varchar(255))
returns table --@valori table(valoare varchar(200))
as
return 
	(select rtrim(valoare) as valoare 
		from proprietati 
		where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate=@cod_proprietate and Valoare<>'')
