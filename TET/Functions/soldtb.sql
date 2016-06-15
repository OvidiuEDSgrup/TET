--***
create function soldtb (
	@conturi varchar(4000),		--> lista de conturi, separate prin virgule
	@tipint int,				--> tip interval - obligatoriu;
									--		1=luna
									--		2=decada
									--		3=saptamana
									--		4=zi
	@datajos datetime,			--> inceput interval; daca e necompletat (null) va incepe cu 1 ianuarie a anului de la @datasus
	@datasus datetime,			-->	sfarsit interval; daca e necompletat se foloseste configurarea par.(TB & LUNA.IND)
	@valuta varchar(3)			--> filtru pe o valuta
	)
returns @rez table (suma float, data datetime, locmunca varchar(20))
as  
begin
	insert into @rez(suma, data, locmunca)
	select suma, data, locmunca from dbo.rulaj_sold_tb(@conturi,'',@tipint,@datajos,@datasus,@valuta,0)
return  
end
