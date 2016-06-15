--***
create function bordMM(@masina varchar(20), @data datetime)
returns table --@bord table(ordine int, element varchar(20), masina varchar(20), valoare decimal(15,3))
as 
return
(	/**	ar trebui sa se tina cont de tip activitate sau e bine asa? (acum se presupune ca tipul masinii (parcurs/lucru) nu se poate schimba)*/
	select max(ea.valoare) valoare,
		ea.element, a.masina
	from elemactivitati ea
		inner join activitati a on a.Tip=ea.Tip and a.Fisa=ea.Fisa and a.Data=ea.Data 
	where (ea.Element in ('KmBord','OreBord','OreNou'))
		and (@masina is null or a.Masina=@masina)
		and (@data is null or a.Data<=@data)
	group by ea.element, a.masina
)
