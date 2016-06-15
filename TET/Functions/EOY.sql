--***
create function EOY (@data datetime) 
returns datetime
as begin
	return convert(datetime, convert(char(10), dateadd(day, -1, dateadd(year, 1, dateadd(month, -month(@data) + 1, dateadd(day, -day(@data) + 1, @data)))), 101), 101)
end
