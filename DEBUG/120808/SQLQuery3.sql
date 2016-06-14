select distinct convert(char(1),stare_sarcina) 
from sarcini 
where id_user='4     ' 
and ((tip_sarcina='I' and cinevalid='1            ') 
	or (1=1 and tip_sarcina<>'I')) 
and stare_sarcina between 1 and 2 
order by convert(char(1),stare_sarcina), data_sarcina