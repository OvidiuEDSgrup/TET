--***
Create function fDataNasterii (@cnp char(13))
returns datetime
as
Begin
	Declare @primele2cifre char(2), @DataCNP datetime
		
	Select @DataCNP='01/01/1901'

	Set @primele2cifre='19'
	Select @primele2cifre='18' where left(@cnp,1) in ('3','4')
	Select @primele2cifre='20' where left(@cnp,1) in ('5','6')

	Set @DataCNP=convert(datetime,@primele2cifre+substring(@cnp,2,2)+'/'+substring(@cnp,4,2)+'/'+substring(@cnp,6,2),101)
	return @DataCNP
end
