--***
create function BOM(@data datetime) 
returns datetime
as
Begin
	/*return dateadd(day,-day(@data)+1,@data)*/
	return convert(datetime,convert(char(10),dateadd(day,-day(@data)+1,@data),101),101)
end
