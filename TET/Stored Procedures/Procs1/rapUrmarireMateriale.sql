
CREATE PROCEDURE rapUrmarireMateriale @comanda VARCHAR(20)=null, @datajos DATETIME, @datasus DATETIME,@cod VARCHAR(20)=null,@detaliat bit = 0, @siInchise bit = 0
AS

	declare
		@subunitate varchar(9), @cmd nvarchar(4000)

	exec luare_date_par 'GE','SUBPRO',0,0,@subunitate output

	IF OBJECT_ID('tempdb..#comenzi_filtrate') IS NOT NULL
		drop table #comenzi_filtrate

	select
		*
	into #comenzi_filtrate
	from Comenzi
	where 
		convert(date,data_lansarii) between @datajos and @datasus and
		(@comanda IS null or comanda=@comanda) and
		(@siInchise=1 OR starea_comenzii<>'I')

	
	IF OBJECT_ID('tempdb..##cm_filtrate') IS NOT NULL
		drop table ##cm_filtrate

	create table ##cm_filtrate(tip varchar(20), numar varchar(20), data datetime, cod varchar(20) , cantitate float, comanda varchar(20) )

	select @cmd='
		insert into ##cm_filtrate(tip, numar, data,cod, cantitate, comanda)
		select '
			+(case when @detaliat=0 then 'max(pd.tip),' else 'pd.tip,' end)
			+(case when @detaliat=0 then 'max(pd.numar),' else 'pd.numar,' end)
			+(case when @detaliat=0 then 'max(pd.data),' else 'pd.data,' end)
			+ 'pd.cod,'
			+(case when @detaliat=0 then 'sum(pd.cantitate),' else 'pd.cantitate,' end) 
			+'pd.comanda
		from PozDoc pd
		JOIN #comenzi_filtrate cf on cf.comanda=pd.comanda and pd.subunitate=''1'' and pd.tip=''CM''' + (case when @detaliat=0 then 'group by pd.comanda, pd.cod' else '' end)
	
	exec sp_executesql @statement=@cmd

	SELECT 
		rtrim(cf.comanda) comanda, convert(decimal(15,2), pl.cantitate) cantitate_produs,convert(decimal(17,2), poz.cantitate) cantitate_comanda,
		cf.Data_lansarii data_lansarii, poz.cod cod, rtrim(n.denumire) denumire, rtrim(n.um) um,
		convert(decimal(15,2), cm.cantitate) cantitate_eliberata, rtrim(cm.tip) tip_document, rtrim(cm.numar) numar_document, cm.data data_document,
		NULLIF(CONVERT(datetime, cf.Numar_de_inventar), '01/01/1900') termen, convert(decimal(15,2), pl.cantitate) cantitate_produs,
		rtrim(prod.denumire) denprodus, rtrim(prod.cod) codprodus 

	from #comenzi_filtrate cf
	JOIN PozLansari pl on cf.comanda=pl.cod and pl.tip='L'
	JOIN pozTehnologii pt on pt.id=pl.idp and pt.tip='T'
	JOIN nomencl prod on prod.cod=pt.cod
	JOIN PozLansari poz on poz.parinteTop=pl.id and poz.tip='M'
	JOIN nomencl n on n.cod=poz.cod
	LEFT JOIN ##cm_filtrate cm on cm.cod=poz.cod and cm.comanda=cf.comanda
	where
		(@cod is null or poz.cod=@cod)
	order by data_lansarii



/*
exec rapUrmarireMateriale @datajos='01/01/2008',@datasus= '01/01/2014', @detaliat=0
*/
