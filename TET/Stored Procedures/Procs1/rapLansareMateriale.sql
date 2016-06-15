
CREATE procedure rapLansareMateriale @sesiune varchar(50), @datajos datetime, @datasus datetime, @comanda varchar(20)=null, @cod varchar(20) = null
as

	select
		rtrim(pLans.cod) comanda, com.data_lansarii data, rtrim(n.denumire) denumire, rtrim(n.cod) cod, 
		convert(decimal(15,2), pLans2.cantitate) cantitate_comanda
	from PozLansari pLans
	JOIN PozLansari pLans2 on pLans.id=pLans2.parinteTop and pLans.tip='L' and pLans2.tip='M'
	JOIN Comenzi com on pLans.cod=com.comanda 
	JOIN Nomencl n on n.cod=pLans2.cod
	where 
		convert(date,com.data_lansarii) between @datajos and @datasus and
		(@comanda is null or com.comanda=@comanda) and
		(@cod is null or pLans2.cod=@cod)

/*
	exec rapLansareMateriale '','01/01/2013','12/01/2013'
*/
