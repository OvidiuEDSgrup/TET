
create procedure wIaRetetaCod @sesiune varchar(50), @parXML xml
as
	declare
		@cod varchar(20), @cod_tehnologie varchar(20), @cautare varchar(1000)

	set @cautare = '%'+ isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(200)'), '%') +'%'
	set @cod=@parXML.value('(/*/@cod)[1]','varchar(20)')

	select top 1
		@cod_tehnologie=cod
	from tehnologii where codNomencl=@cod

	select
		RTRIM(ptehn.cod) cod, rtrim(n.Denumire) denumire, rtrim(n.UM) um, convert(decimal(17,5), ptehn.cantitate) cantitate,
		pTehn.id as id, ptehn.parinteTop parinteTop
	from pozTehnologii tehn
	JOIN pozTehnologii ptehn ON tehn.cod=@cod_tehnologie and tehn.tip='T' and tehn.id=ptehn.idp and ptehn.tip='M'
	JOIN nomencl n ON n.cod=ptehn.cod
	where n.cod like @cautare or n.Denumire like @cautare
	for xml raw, root('Date')
