
CREATE PROCEDURE rapUrmarireOperatii @comanda VARCHAR(20)=null, @datajos DATETIME, @datasus DATETIME,@cod VARCHAR(20)=null, @siInchise bit = 0
AS

	declare
		@subunitate varchar(9)

	exec luare_date_par 'GE','SUBPRO',0,0,@subunitate output

	IF OBJECT_ID('tempdb..#comenzi_filtrate') IS NOT NULL
		drop table #comenzi_filtrate

	select
		*
	into #comenzi_filtrate
	from Comenzi
	where 
		convert(date, data_lansarii) between @datajos and @datasus and
		(@comanda IS null or comanda=@comanda) and
		(@siInchise=1 OR starea_comenzii<>'I')

	SELECT 
		rtrim(cf.comanda) comanda, rtrim(c.cod) as cod, rtrim(c.denumire) as denumire,rtrim(c.um) as um, convert(decimal(15,2), ISNULL(c.tarif,0)) pret,
		convert(decimal(17,2), ISNULL(poz.cantitate,0)) cantitate_lansata, convert(decimal(17,2), ISNULL(poz.cantitate,0)*ISNULL(c.tarif,0)) valoare_lansata,
		convert(decimal(15,2), ISNULL(pr.cantitate,0)) cantitate_realizata, convert(decimal(15,2), ISNULL(pr.cantitate,0)*ISNULL(c.tarif,0)) valoare_realizata,
		cf.Data_lansarii data_lansarii, NULLIF(convert(datetime, cf.numar_de_inventar),'01/01/1900') termen, convert(decimal(15,2), pl.cantitate) cantitate_produs,
		rtrim(n.denumire) denprodus, rtrim(n.cod) codprodus
	from #comenzi_filtrate cf
	JOIN PozLansari pl on cf.comanda=pl.cod and pl.tip='L'
	JOIN pozTehnologii pt on pt.id=pl.idp and pt.tip='T'
	JOIN nomencl n on n.cod=pt.cod 
	JOIN PozLansari poz on poz.parinteTop=pl.id and poz.tip='O'
	JOIN catop c on c.cod=poz.cod
	OUTER APPLY
	(
		select	
			sum(cantitate) cantitate
		from PozRealizari 
		where idPozLansare=poz.id
	) pr
	where
		(@cod is null or poz.cod=@cod)
	order by comanda,data_lansarii desc



/*
exec rapUrmarireOperatii @datajos='01/01/2008',@datasus= '01/01/2014'

*/

