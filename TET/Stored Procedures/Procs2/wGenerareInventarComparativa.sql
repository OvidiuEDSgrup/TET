--***
CREATE PROCEDURE wGenerareInventarComparativa (@parXML xml)
AS
if OBJECT_ID('wGenerareInventarComparativaSP') is not null
begin
	exec wGenerareInventarComparativaSP @parXML
	return
end
BEGIN TRY
/*
	Exemplu de apel
	exec wGenerareInventarComparativa '<row data="2013-08-02" gestiune="21" cod="0000275" faradocumentcorectie="1" variantaNoua="1"/>'
*/
	DECLARE 
			@data DATETIME, @gestiune VARCHAR(20), @variantaNoua bit,
			@tipg VARCHAR(1), @categatasata VARCHAR(10), @subunitate VARCHAR(13), @idInventar INT, @mesaj VARCHAR(500), @grupa varchar(13),@cod varchar(20),
			@cuCategorie bit,@faradocumentcorectie int, @locatie varchar(20), @grupare_cod_pret bit, @tip_stoc varchar(1), @cont varchar(20)

	select	@data=@parXML.value('(row/@data)[1]','datetime'),
			@gestiune=@parXML.value('(row/@gestiune)[1]','varchar(20)'),
			@grupa=@parXML.value('(row/@grupa)[1]','varchar(13)'),
			@cod=@parXML.value('(row/@cod)[1]','varchar(20)'),
			@variantaNoua=isnull(@parXML.value('(row/@variantaNoua)[1]','bit'),1),
			@categatasata=@parXML.value('(row/@categatasata)[1]','varchar(20)'),
			@cuCategorie=isnull(@parXML.value('(row/@cuCategorie)[1]','bit'),0),
			@faradocumentcorectie=isnull(@parXML.value('(row/@faradocumentcorectie)[1]','bit'),0),
			@locatie=@parXML.value('(row/@locatie)[1]','varchar(20)'),
			@grupare_cod_pret=isnull(@parXML.value('(row/@grupare_cod_pret)[1]','bit'),0),
			@tip_stoc=isnull(@parXML.value('(row/@tip_gestiune)[1]','varchar(1)'),'D'),
			@cont=@parXML.value('(row/@cont)[1]','varchar(20)')
	exec luare_date_par 'GE','SUBPRO',0,0,@subunitate OUTPUT
	--SET @faradocumentcorectie = 0

	SELECT TOP 1 @tipg = tip_gestiune
	FROM gestiuni
	WHERE Subunitate = @subunitate
		AND Cod_gestiune = @gestiune
	
	create table #inventar (cod varchar(20), stoc_faptic decimal(15,3))

-->	in acest punct se determina care structuri se folosesc (in mod normal cele noi;
	-->	in cazul in care se merge pe varianta veche datele sunt luate din tabela inventar):
	if (@variantaNoua=1)
	begin
		SELECT TOP 1 
			@idInventar = idInventar,
			@tip_stoc= (case when tip='G' then 'D' else 'F' end)
		FROM AntetInventar
		WHERE data = @data
			AND gestiune = @gestiune
			and (grupa=@grupa or isnull(@grupa,'')='')--daca sunt inventare deschise la nivel de grupa

		insert into #inventar(cod, stoc_faptic)
		SELECT cod AS cod, sum(stoc_faptic) AS stoc_faptic
		FROM PozInventar
		WHERE idInventar = @idInventar and 
			(@cod is null or cod=@cod)
			and (@locatie is null or @locatie=isnull(detalii.value('(row/@locatie)[1]','varchar(30)'),''))
		GROUP BY cod
		
		IF @idInventar IS NULL
			RAISERROR ('Nu s-a putut identifica inventarul', 11, 1)
	end
	else
		insert into #inventar(cod, stoc_faptic)
		SELECT Cod_produs AS cod, sum(stoc_faptic) AS stoc_faptic
			FROM inventar i
			WHERE i.Gestiunea=@gestiune and i.Data_inventarului=@data and (@cod is null or cod_produs=@cod)
			GROUP BY cod_produs

	declare @p xml
	select @p=(select @data dDataSus, @cod cCod, @gestiune cGestiune, @grupa cGrupa, @tip_stoc TipStoc, @cont cCont, 0 Corelatii, @locatie Locatie
	for xml raw)
	
		if object_id('tempdb..#docstoc') is not null drop table #docstoc
			create table #docstoc(subunitate varchar(9))
			exec pStocuri_tabela
		 
		exec pstoc @sesiune='', @parxml=@p

	SELECT subunitate, tip_document, numar_document, data, numar_pozitie, 
		cod, (case when tip_miscare='E' then -1 else 1 end)*cantitate stoc, pret_cu_amanuntul, pret,
		(case when @grupare_cod_pret=1 then pret else 0 end) gr_pret
	INTO #fstocuridet
	FROM #docstoc 

	if @faradocumentcorectie=1
	begin
		delete sd
		from #fstocuridet sd, pozdoc pd 
		where sd.subunitate=pd.subunitate and sd.tip_document=pd.tip and sd.numar_document=pd.numar and sd.data=pd.data and sd.numar_pozitie=pd.numar_pozitie and pd.detalii.value('(/row/@idInventar)[1]', 'int')=@idInventar 
	end

	SELECT cod, sum(stoc) AS stoc_scriptic, sum(stoc * (CASE WHEN @tipg = 'A' THEN pret_cu_amanuntul ELSE pret END)) AS 
		valstoc,sum(stoc * pret_cu_amanuntul) as valspretam, sum(stoc * pret) as valspretstoc, gr_pret
	INTO #fstocuri
	FROM #fstocuridet
	GROUP BY cod, gr_pret
/*	
	if exists (select 1 from sys.objects where name ='test_luci')
		drop table test_luci
	select @cont cont into test_luci-- from #fstocuri
--*/
	delete from #fstocuri where abs(stoc_scriptic)<0.01
	delete from #inventar where abs(stoc_faptic)<0.01

	CREATE TABLE #comparativa (
		cod VARCHAR(20), stoc_scriptic FLOAT, stoc_faptic FLOAT, pret FLOAT, plusinv FLOAT, minusinv FLOAT, valplusinv FLOAT, 
		valminusinv FLOAT,pretstoc float,pretam float
		)

	INSERT INTO #comparativa (cod, stoc_scriptic, stoc_faptic, pret)
	SELECT DISTINCT isnull(fs.cod, inv.cod), isnull(fs.stoc_scriptic, 0), isnull(inv.stoc_faptic, 0), gr_pret
	FROM #fstocuri fs
	FULL JOIN #inventar inv
		ON inv.cod = fs.cod
	--where (@locatie is null or fs.cod is not null)
	--Se incearca prima data cu pretul din tabela de stocuri
	UPDATE #comparativa
	SET pret = fs.valstoc / fs.stoc_scriptic,pretam=fs.valspretam / fs.stoc_scriptic,pretstoc=fs.valspretstoc/fs.stoc_scriptic
	FROM #fstocuri fs
	WHERE #comparativa.cod = fs.cod
		AND abs(fs.stoc_scriptic) > 0.01 and fs.gr_pret=#comparativa.pret

	if (@categatasata is null)
	--In cazul in care pretul ramane null se va incerca din tabela de preturi (daca exista o proprietate)
	SELECT @categatasata = valoare
	FROM proprietati
	WHERE tip = 'GESTIUNE'
		AND Cod_proprietate = 'CATEGPRET'
		AND cod = @gestiune

	if isnull(@categatasata,'')=''
		set @categatasata='1'

	create table #preturi(cod varchar(20),nestlevel int)
	IF @categatasata IS NOT NULL
	BEGIN
		insert into #preturi
		select cod,@@NESTLEVEL
		from #comparativa
		group by cod
		
		exec CreazaDiezPreturi
		declare @px xml
		select @px=(select @categatasata as categoriePret, @data as data, @gestiune as gestiune for xml raw)
		exec wIaPreturi @sesiune=null,@parXML=@px

		UPDATE #comparativa
		SET pret = p.Pret_amanunt, pretam=p.Pret_amanunt
		FROM #preturi p
		WHERE #comparativa.cod = p.cod
		
		--select * into testluci from #comparativa
		--select * into testluci from #preturi
	END

	--Inca o sansa, luam preturile din nomenclator
	UPDATE #comparativa
	SET pret = (case when #comparativa.pret IS NULL then (CASE WHEN @tipg = 'A' THEN nomencl.pret_cu_amanuntul ELSE nomencl.Pret_stoc END) else #comparativa.pret end),
	pretstoc = (case when #comparativa.pretstoc is null then nomencl.pret_stoc else #comparativa.pretstoc end),
	pretam = (case when #comparativa.pretam is null then nomencl.pret_cu_amanuntul else #comparativa.pretam end)
	FROM nomencl
	WHERE #comparativa.cod = nomencl.cod and 
		(#comparativa.pret is null or #comparativa.pretstoc is null or #comparativa.pretam is null)
	

	--Ultima sansa cautam in receptiile ultimelor 12 luni
	if exists (select * from #comparativa where pretstoc=0)
	begin
		select cod 
		into #nepretuite
		from #comparativa where pretstoc=0
		group by cod

		select n.cod,p.pret_de_stoc,rank() over (partition by n.cod order by p.data desc) as ranc
		into #nepretuite1
		from #nepretuite n
		inner join pozdoc p on p.subunitate='1' and p.tip in ('RM','AI') and p.cod=n.cod and p.data>dateadd(m,-12,@data)
	

		delete from #nepretuite1 where ranc>1
		
		update #comparativa set pretstoc=#nepretuite1.Pret_de_stoc
			from #nepretuite1 where #comparativa.pretstoc=0 and #comparativa.cod=#nepretuite1.cod
	end
	--Completam celelate coloane

	UPDATE #comparativa
	SET plusinv = (CASE WHEN stoc_faptic > stoc_scriptic THEN stoc_faptic - stoc_scriptic ELSE 0 END), minusinv = (CASE WHEN stoc_scriptic > stoc_faptic THEN stoc_scriptic - stoc_faptic ELSE 0 END
			)

	UPDATE #comparativa
	SET valplusinv = plusinv * pret, valminusinv = minusinv * pret

	UPDATE #comparativa
	SET pretstoc = pret -- daca am pret si n-am pretstoc
	where pretstoc=0 and @tipg != 'A'
	
	UPDATE #comparativa
	SET pretam = pret -- daca am pret si n-am pretam
	where pretam=0 and @tipg = 'A'
	
	SELECT cod,stoc_scriptic,stoc_faptic,pret,plusinv,minusinv,valplusinv,valminusinv,pretstoc,pretam
	FROM #comparativa
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wGenerareInventarComparativa)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
