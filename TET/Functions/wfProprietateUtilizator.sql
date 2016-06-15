--***
/* functia returneaza valoarea proprietatii atasate utilizatorului trimis ca parametru
Trebuie trimis si utilizatorul pt ca sa se poata lucra si cand utilizatorul se determina din sesiune */
create function wfProprietateUtilizator(@cod_proprietate varchar(20), @utilizator varchar(255))
returns varchar(200)
as begin
return isnull((select top 1 rtrim(valoare) from proprietati where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate=@cod_proprietate order by Valoare_tupla),'')
end
