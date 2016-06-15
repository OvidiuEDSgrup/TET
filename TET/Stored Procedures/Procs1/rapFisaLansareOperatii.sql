
CREATE procedure rapFisaLansareOperatii @comanda varchar(20)
as

	declare 
		@sesiune varchar(200)
	select top 1 @sesiune=token from asisria..sesiuniRIA

	select
		rtrim(pl.cod) comanda, rtrim(pl.cod) as barcod_comanda,rtrim(n.denumire) as denprodus, rtrim(n.cod) as codprodus,
		rtrim(t.denumire) as dentert, convert(decimal(15,2), pl.cantitate) as cantitate_produs, convert(varchar(10), c.Data_lansarii,103) data_lansare,
		rtrim(ct.denumire) as denoperatie, op.detalii.value('(/*/@denlm)[1]','varchar(20)') as denlm,
		op.id as barcod_operatie, @sesiune sesiune,op.cantitate timp
	from
		PozLansari pl
		JOIN Comenzi c on c.comanda=pl.cod and pl.tip='L' and pl.cod=@comanda
		JOIN pozLansari op on pl.id=op.parinteTop and op.tip='O'
		JOIN PozTehnologii pz on pz.id=pl.idp and pz.tip='T'
		LEFT JOIN nomencl n on n.cod=pz.cod
		LEFT JOIN terti t on t.tert=c.Beneficiar
		JOIN catop ct on ct.cod=op.cod
