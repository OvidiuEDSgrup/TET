--***
create function EOM (@data datetime) 
returns datetime
as begin
	/*return dateadd(day,-1,dateadd(month, 1, dateadd(day,-day(@data)+1,@data)))*/
	return convert(datetime,convert(char(10),dateadd(day,-1,dateadd(month, 1, dateadd(day,-day(@data)+1,@data))),101),101)
end
