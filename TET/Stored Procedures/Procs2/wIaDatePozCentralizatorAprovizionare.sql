CREATE PROCEDURE  wIaDatePozCentralizatorAprovizionare @sesiune VARCHAR(50), @parXML XML
AS
	declare
		 @cod varchar(20), @utilizator varchar(100), @cautare varchar(1000)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	SELECT
		@cod = @parXML.value('(/*/@cod)[1]', 'varchar(20)'),
		@cautare='%'+isnull(@parXML.value('(/*/@_cautare)[1]','varchar(1000)'),'%')+ '%'

	/** Datele din tabelul temporar calculat la intrare in macheta **/
	select
		(case	when tp.idpozLansare is not null then 'Comanda prod.' 
				when tp.idpozLansare is null and tp.idPozContract is null then 'Stoc' 
				when tp.idPozContract is not null  and c.tip='CL' then 'Comanda livr.' 
				when tp.idPozContract is not null  and c.tip='RN' then 'Referat' 
		else '' end) tip_necesar,
		COALESCE(com.comanda,c.numar,'') comanda,
		RTRIM(isnull(t.denumire,l.denumire)) client, 		
		convert(decimal(15,2),ISNULL(tp.cantitate-ISNULL(tp.cant_aprovizionare,0), at.cantitate)) cant_comanda,
		convert(varchar(10),pc.termen,101) termen,
		tp.idTmp idTmp, 
		at.idTmp idTmpParinte, 
		NULL subtip		
	from tmpArticoleCentralizator at
	INNER JOIN tmpPozArticoleCentralizator tp on at.cod=tp.cod and tp.utilizator=@utilizator
	LEFT JOIN PozLansari pozL on pozL.id=tp.idPozLansare
	LEFT JOIN pozLansari pcom on pcom.id=pozl.parinteTop and pcom.tip='L'
	LEFT JOIN comenzi com on com.comanda=pcom.cod
	LEFT JOIN POzContracte pc on pc.idPozContract=tp.idPozContract
	LEFT JOIN Contracte c on c.idContract=pc.idContract
	LEFT JOIN terti t on (t.tert=com.Beneficiar OR t.tert=c.tert)
	LEFT JOIN lm l on l.Cod=c.loc_de_munca
	where
		(isnull(com.Comanda,'') like @cautare OR isnull(t.Denumire,'') like @cautare) and 
		(at.cod=@cod and at.utilizator=@utilizator)
	for xml RAW, ROOT('Date')
