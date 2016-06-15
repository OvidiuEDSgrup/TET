
CREATE PROCEDURE wIaDateCentralizatorAprovizionare @sesiune VARCHAR(50), @parXML XML
AS

	DECLARE 
		@f_client VARCHAR(50), @f_comanda VARCHAR(200), @f_furnizor varchar(100), @f_cod varchar(100), @utilizator varchar(100),@f_grupa varchar(200), 
		@f_denarticol varchar(200), @cuRezervari int, @gestiuneRezervari varchar(100), @refresh varchar(5), @cod varchar(20)

	SELECT	
		@f_client = '%'+replace(@parXML.value('(/*/@f_client)[1]', 'varchar(80)'), ' ', '%')+'%',
		@f_comanda = '%'+replace(@parXML.value('(/*/@f_comanda)[1]', 'varchar(80)'), ' ', '%')+'%',
		@f_furnizor = '%'+replace(@parXML.value('(/*/@f_furnizor)[1]', 'varchar(80)'), ' ', '%')+'%',
		@f_cod = '%'+replace(@parXML.value('(/*/@f_cod)[1]', 'varchar(80)'), ' ', '%')+'%',
		@f_denarticol = '%'+replace(@parXML.value('(/*/@f_denarticol)[1]', 'varchar(200)'), ' ', '%')+'%',
		@f_grupa = '%'+replace(@parXML.value('(/*/@f_grupa)[1]', 'varchar(200)'), ' ', '%')+'%',
		@refresh = isnull(@parXML.value('(/row/@_refresh)[1]', 'varchar(5)'), '1'), 
		@cod=@parXML.value('(/*/@cod)[1]', 'varchar(20)')

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	EXEC luare_date_par 'GE', 'REZSTOCBK', @cuRezervari OUTPUT, 0, @gestiuneRezervari OUTPUT

	/** La prima intrare in macheta (refresh=0) sterg datele pt utilizatorul curent si deschid macheta de PREFILTRARE care va popula tabelul **/
	if @refresh='0'
	BEGIN		
		delete tmpArticoleCentralizator where utilizator=@utilizator

		SELECT 
			'Prefiltrare date centralizator aprovizionare' nume, 'FC' codmeniu, 'O' tipmacheta, (SELECT @parXML ) dateInitializare
		FOR XML RAW('deschideMacheta'), ROOT('Mesaje')
	END

	/* Altfel, avem datele calculate*/
	IF OBJECT_ID('tempdb..#ArticoleInScopCen') is not null
		drop table #ArticoleInScopCen

	/** Centralizare date pt. a usura ... **/	
	select
		RTRIM(a.cod) cod,		
		MAX(a.furnizor) furnizor,
		MAX(curs) curs, 
		MAX(a.valuta) valuta,
		SUM(a.cantitate) cantitate, 
		SUM(a.cant_rezervata) cant_rezervata,  
		SUM(a.cant_aprovizionare) cant_aprovizionare,
		SUM(a.decomandat) decomandat,
		SUM(a.stoc) stoc		
	into #ArticoleInScopCen
	from tmpArticoleCentralizator a
	JOIN nomencl n ON a.cod = n.cod	
	where utilizator=@utilizator 		
	GROUP BY a.cod


	/** Selectul cu datele formatate pentru GRID din macheta Centralizator aprovizionare */
	select top 100
		rtrim(n.Cod) cod, rtrim(n.denumire) dencod, rtrim(n.um) um,
		rtrim(furn.denumire) furnizor, rtrim(a.furnizor) as cod_furnizor,
		convert(decimal(15,2), a.curs) curs, rtrim(a.valuta) valuta,
		convert(decimal(15,2),a.cantitate) cant_necesara, 
		convert(decimal(15,2),isnull(a.stoc,0)) cant_stoc,
		convert(decimal(15,2),isnull(a.cant_rezervata,0)) cant_rezervata,
		convert(decimal(15,2),isnull(a.cant_aprovizionare,0)) as cant_aprovizionare,		
		convert(decimal(15,2),sl.stoc_min) as stocmin,
		convert(decimal(15,2),sl.stoc_max) as stocmax,
		convert(decimal(15,2),a.decomandat) as decomandat,
		n.detalii 	
	from #ArticoleInScopCen a
	INNER JOIN nomencl n on a.cod=n.cod
	LEFT JOIN grupe g on g.Grupa=n.Grupa 
	LEFT  join terti furn on a.furnizor=furn.tert	
	LEFT JOIN stoclim sl on a.cod=sl.cod and sl.cod_gestiune=''
	where 
		(isnull(@f_furnizor,'')=''OR furn.denumire like @f_furnizor) and
		(isnull(@f_cod,'')='' OR a.cod like @f_cod) and
		(isnull(@f_denarticol,'')='' or n.Denumire like @f_denarticol) and
		(isnull(@f_grupa,'')='' OR g.Denumire like @f_grupa or n.Grupa like @f_grupa OR g.grupa IS NULL) and 
		(@cod is null OR a.cod=@cod)
	order by a.decomandat desc
	for xml RAW, ROOT('Date')

	select '1' as areDetaliiXml for xml raw, root('Mesaje')
