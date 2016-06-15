--***
create function fIauUtilizatorCurent()
returns char(10)
as -- utilizatorul se identifica folosind fIaUtilizator. Nu mai folositi aceasta functie in procedurile noi.
begin 
	return dbo.fIaUtilizator(null)
end
