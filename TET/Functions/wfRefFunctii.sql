--***
Create function  wfRefFunctii (@Cod_functie char(6)) returns int
as 
Begin
	if exists (select 1 from personal where Cod_functie=@Cod_functie)
		return 1
	if exists (select 1 from istpers where Cod_functie=@Cod_functie)
		return 2
	return 0
End
