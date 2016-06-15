
CREATE PROCEDURE rapUrmarireProductie 
	@sesiune varchar(50), @datajos datetime, @datasus datetime, @comanda varchar(20) = NULL, @cod varchar(20)=NULL,
	@locMunca varchar(20) = NULL, @beneficiar varchar(20) = NULL, @grupare_1 varchar(100), @grupare_2 varchar(100)
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
/*	
	exec rapUrmarireProductie 
	@sesiune= '' , @datajos= '2014-01-01', @datasus ='2015-01-01', @comanda =NULL, @cod =NULL, @locMunca =NULL, @beneficiar =NULL,
	@grupare_1 = 'PRODUS', @grupare_2 = '<Fara>'
*/

	IF OBJECT_ID('tempdb.dbo.#stariComenzi') IS NOT NULL
		drop table #stariComenzi

	create table #stariComenzi (cod varchar(10), denumire varchar(500), ordine int)
	insert into #stariComenzi  (cod, denumire, ordine)
	select 'S', 'Simulare',1 UNION
	select 'P', 'Pregatire',2 UNION
	select 'L', 'Lansata',3 UNION
	select 'A', 'Alocata',4 UNION
	select 'I', 'Inchisa',5  UNION
	select 'N', 'Anulata',6  UNION
	select 'B', 'Blocata',7

	IF @grupare_1 = @grupare_2
		RAISERROR('Alegeti grupari diferite!', 16, 1)

	IF @grupare_2 = '<Fara>'
	BEGIN
		SELECT @grupare_2 = @grupare_1, @grupare_1 = ''
	END

	select
		c.*, pc.Cod_produs cod, pc.cantitate cantitate
	into #com_filtr
	from Comenzi c
	JOIN PozCom pc on c.Comanda=pc.Comanda
	where 
		(@comanda IS NULL or c.comanda=@comanda) and
		(@cod is null or pc.Cod_produs = @cod) and
		(@beneficiar is null or c.Beneficiar=@beneficiar) and
		(@locMunca is null or c.Loc_de_munca=@locMunca) and
		(c.data_lansarii between @datajos and @datasus)
		
	select
		(CASE @grupare_1 WHEN 'PRODUS' THEN n.Cod WHEN 'COMANDA' THEN cf.comanda ELSE '' END) AS grupare1,
		(CASE @grupare_1 WHEN 'PRODUS' THEN 'Produs' WHEN 'COMANDA' THEN 'Comanda' ELSE '' END) AS dengrupare1,
		(CASE @grupare_2 WHEN 'PRODUS' THEN n.cod WHEN 'COMANDA' THEN cf.comanda ELSE '' END) AS grupare2,
		(CASE @grupare_2 WHEN 'PRODUS' THEN 'Produs' WHEN 'COMANDA' THEN 'Comanda' ELSE '' END) AS dengrupare2,
		@grupare_1 AS gr1, @grupare_2 AS gr2,

		rtrim(n.cod) cod, rtrim(n.denumire) denumire, convert(decimal(15,2),cf.cantitate) cantitate_lansata,
		rtrim(cf.comanda) comanda, convert(varchar(10), cf.data_lansarii, 103) as data_lansarii,
		convert(varchar(10), convert(datetime, (case when ISDATE(cf.numar_de_inventar)=1 then numar_de_inventar else null end)), 103) as data_inchiderii, 
		sc.denumire stare, rtrim(cf.Beneficiar) as beneficiar, rtrim(lm.Denumire) as denlm, rtrim(g.Denumire_gestiune) as dengestiune,
		rtrim(t.denumire) denbeneficiar, rtrim(n.um) as um, rtrim(n.cont) as cont_stoc,
		rtrim(pd.numar) numar, convert(varchar(10), pd.data, 103) as data, convert(decimal(15,2),ISNULL(pd.cantitate,0)) cantitate_predata			
	from #com_filtr cf
	INNER JOIN #stariComenzi sc on sc.cod=cf.Starea_comenzii
	LEFT JOIN terti t on t.tert=cf.Beneficiar
	LEFT JOIN nomencl n on n.cod=cf.cod
	LEFT JOIN PozDoc pd on cf.comanda=pd.comanda and pd.tip='PP' and pd.data>=cf.data_lansarii
	LEFT JOIN lm on lm.Cod = pd.Loc_de_munca
	LEFT JOIN gestiuni g on g.Cod_gestiune = pd.Gestiune
	order by cf.data_lansarii
