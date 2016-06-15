--***
create function plitera_mare(@sursa varchar(2000),@exceptii varchar(2000)) returns varchar(2000)
as begin
 declare @rez varchar(2000),@cuvant varchar(200),@index int
 set @rez=''	set @index=3
 set @exceptii='|'+@exceptii+'|'
 set @sursa=' '+@sursa+' '
 while(@index-1<len('|'+@sursa+'|')-2)
 begin
 	if (charindex('  ',@sursa,@index-2)<>@index-2)
 	begin
 		set @cuvant=substring(@sursa,@index-1,charindex(' ',@sursa,@index-1)+1-(@index+' '))
 		if charindex(' '+@cuvant+' ',@exceptii)<>0
 			set @rez=@rez+left(@cuvant,len('|'+@cuvant+'|')-2)+' '
            else set @rez=@rez+upper(left(@cuvant,1))+lower(substring(@cuvant,2,len(@cuvant)))+' '
 		set @index=@index+len(left(@cuvant,len('|'+@cuvant+'|')-2)+'|')
 	end
 	else 
 	begin
 		set @rez=@rez+' '
 		set @index=@index+1
 	end
 end
return
	substring(@rez,1,len(@rez))
end
