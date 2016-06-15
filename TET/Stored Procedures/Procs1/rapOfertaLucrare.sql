
CREATE PROCEDURE  rapOfertaLucrare @sesiune VARCHAR(50), @id_antecalculatie int
AS
/*
	exec rapOfertaLucrare '','18'
*/
	declare 
		@prestator varchar(100), @explicatii varchar(1000), @denreprezentant varchar(5000), @utilizator varchar(100)

	set @utilizator=dbo.fIaUtilizator(null)
	
	select @utilizator=rtrim(nume) from utilizatori where id=@utilizator
	select @explicatii='Decontarea se va face dupa cantitatile reale realizate'
	select top 1 @prestator=rtrim(val_alfanumerica) from par where tip_parametru='GE' and parametru='nume'

	
	select
		row_number() over (order by newid()) nr_crt,pa.detalii.value('(/*/@tert)[1]','varchar(20)') tert,pa.detalii.value('(/*/@dentert)[1]','varchar(100)') dentert, UPPER(@utilizator) denreprezentant,
		@prestator denprestator, rtrim(t.denumire) denlucrare, UPPER((case pa2.tip when 'O' then rtrim(c.denumire) else rtrim(n.denumire) end)) denarticol,pa2.cod cod,
		convert(decimal(15,2), pa2.cantitate) cantitate, (case pa2.tip when 'O' then rtrim(c.um) else rtrim(n.um) end) um,
		convert(decimal(15,2), pa2.pret) pret, convert(decimal(15,2), pa2.cantitate*pa2.pret) valoare, a.data data,
		pa2.tip tip

	from Antecalculatii a
	JOIN PozAntecalculatii pa on a.idPoz=pa.id and pa.tip='A'
	JOIN PozTehnologii pt on pt.cod=a.cod and pt.tip='T'
	JOIN tehnologii t on t.cod=pt.cod 
	JOIN PozAntecalculatii pa2 on pa2.idp=pa.id and pa2.tip in ('O','M')
	LEFT JOIN nomencl n on n.cod=pa2.cod and pa2.tip='M'
	LEFT JOIN catop c on c.cod=pa2.cod and pa2.tip='O'
	where a.idAntec=@id_antecalculatie
