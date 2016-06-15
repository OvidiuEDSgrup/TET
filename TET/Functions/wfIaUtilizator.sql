--***
/* functia ia utilizatorul ASiS curent. Se cauta in sesiunea de lucru(daca se trimite), altfel din host_id (ASiS&ASiSplus), altfel prin SUSER_NAME() */
create function wfIaUtilizator (@sesiune varchar(50))
returns varchar(254)
as
begin
	return dbo.fIaUtilizator(@sesiune) 
end
