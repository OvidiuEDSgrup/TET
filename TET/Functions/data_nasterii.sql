--***
/**	functie data nasterii din CNP	*/
create 
	function data_nasterii (@cnp char(13)) 
returns datetime
as
Begin
	Declare @DataN datetime
	Set @DataN = convert(datetime, (case when left(@cnp,1)<'3' then '19' else '20' end)+
	(substring(@cnp,2,6)),101)
	return(@DataN)
end
