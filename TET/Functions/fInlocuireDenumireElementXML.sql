--***
create function fInlocuireDenumireElementXML (@parXML xml, @denumireNoua varchar(2000))
returns xml --	varchar(max)
begin
	declare @string varchar(max), @carFinal varchar(1), @denumireVeche varchar(2000),
		@simplu bit	--> prin simplu=1 inteleg ca e xml de forma '<row [...]/>' si nu '<row> ... </row>'
	select @string=convert(varchar(max),@parXML)

	select @simplu=(case when --charindex('<', substring(@string,2,len(@string)))>0 
							not left(reverse(@string),2)='>/'
						then 0 else 1 end)

	select @carFinal=(case when @simplu=0 then '>' else
		(case when charindex(' ',@string)=0 or charindex(' ',@string)>charindex('/',@string) then '/' else ' ' end) end)
	
	if (@simplu=1)
		select @parXML=convert(xml,'<'+@denumireNoua+' '+substring(@string,charindex(@carFinal,@string),len(@string)))
	else
	begin
		declare @rootNou varchar(max), @indSfRoot int
		select @indSfRoot=charindex('>',@string)
		select @rootNou=left(@string,@indSfRoot)
		if charindex(' ',@rootNou)>0	--> daca root are atribute nu se va inlocui in intregime ci doar eticheta:
			select @indSfRoot=charindex(' ',@rootNou)
		select @rootNou='<'+@denumireNoua+substring(@rootNou, @indSfRoot,len(@rootNou))
		
		select @string=reverse(substring(@string,charindex(@carFinal,@string)+1,len(@string)))
		select @string=reverse(substring(@string,charindex('/<',@string)+2,len(@string)))
		
		select @parXML=@rootNou+
				@string
				+'</'+@denumireNoua+'>'
	end
	return @parXML
end
