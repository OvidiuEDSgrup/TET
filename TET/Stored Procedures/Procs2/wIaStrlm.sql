--***
CREATE procedure wIaStrlm @sesiune varchar(50), @fltNivel varchar(30)    
as    
select nivel,rtrim(denumire) as denumire,lungime  
from strlm  
where rtrim(left(denumire,30))+'('+rtrim(nivel)+')' like '%'+isnull(@fltNivel,'')+'%'    
order by nivel  
for xml raw
