--***
create function fSchimbaZiLuna (@data varchar(10))
returns varchar(10) as
	/** Se primeste o data formatata astfel: ZZ/LL/AAAA, Z/L/AAAA, ZZ/L/AAAA sau Z/LL/AAAA 
	Ex.
		select dbo.fSchimbaZiLuna ('1/14/2014')
	*/
begin
	declare
		@ziua varchar(2), @luna varchar(2), @an varchar(4), @delim varchar(1),
		@dataRezultata varchar(10)

		set @delim = '/'
		set @an = right(@data, 4) -- separam anul
		set @data = left(@data, len(@data) - 4) -- punem in variabila tot, fara an
		set @luna = substring(@data, (patindex('%' + @delim + '%', @data) + 1), ((len(@data) - (patindex('%' + @delim + '%', reverse(@data))) + 1)
			- (patindex('%' + @delim + '%', @data) + 1))) -- aici separam luna (luna fiind string-ul dintre delimitatori)
		set @ziua = substring(@data, 0, charindex(@delim, @data)) -- separam ziua (primele caractere pana la prima aparitie a delimitatorului)

		set @dataRezultata = @luna + @delim + @ziua + @delim + @an

		return @dataRezultata
	/** Returneaza data primita (se schimba luna cu ziua la afisare) */
end
