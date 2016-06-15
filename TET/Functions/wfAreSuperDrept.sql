--***
/* functia ia utilizatorul ASiS curent. Se cauta in sesiunea de lucru(daca se trimite), altfel din host_id (ASiS&ASiSplus), altfel prin SUSER_NAME() */
create function wfAreSuperDrept(@utilizator varchar(50))
returns bit
as
begin
	return ISNULL((select MAX(1) from asisria..parametriRIA p where p.cod=@utilizator and p.valoare='superuser'),0)
end
