-- 9810965 
select convert(char(15),convert(money,round(sum(convert(decimal(17,5),
	pozcon.pret/(1+pozcon.tva/100)*(1-pozcon.Discount/100)*(1-pozcon.DiscDoi/100)*(1-pozcon.DiscTrei/100)*(1+pozcon.tva/100)*pozcon.CursValuta)
	*pozcon.cantitate),2)),1)
from yso.pozconexp pozcon