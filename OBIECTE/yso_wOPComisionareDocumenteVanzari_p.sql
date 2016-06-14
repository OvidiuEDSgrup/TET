IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'yso_wOPComisionareDocumenteVanzari_p')
	DROP PROCEDURE yso_wOPComisionareDocumenteVanzari_p
GO
CREATE PROCEDURE yso_wOPComisionareDocumenteVanzari_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @tert VARCHAR(20), @mesaj VARCHAR(400), @dataJos DATETIME, @dataSus DATETIME,
		@tip VARCHAR(2), @utilizator varchar(50), @suma float, @data datetime, @valuta varchar(3),
		@dentert varchar(200), @numar varchar(20), @cont varchar(13), @curs float, @sub varchar(9),
		@soldTert float, @lm varchar(13), @factura varchar(20), @gestiune varchar(13), @cod varchar(20), @flm int

	declare @numar_pozitie int, @idpozdoc int
	
	select 
		@numar_pozitie=@parXML.value('(/row/row/@numarpozitie)[1]','int'),
		@idpozdoc=@parXML.value('(/row/row/@idpozdoc)[1]','int')

	if @idpozdoc is null
	begin
		raiserror( 'Operatie de modificare date pozitie nepermisa pe antetul documentului, selectati o pozitie din document!',11,1)
	end  
			
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub OUTPUT --> citire subunitate din proprietati

	SELECT
		@tip = isnull(@parXML.value('(/*/@tip)[1]', 'varchar(2)'),''),
		@tert = isnull(@parXML.value('(//@tert)[1]', 'varchar(20)'),''),
		@numar = isnull(@parXML.value('(//@numar)[1]', 'varchar(20)'),''),
		@flm = isnull(@parXML.value('(//@flm)[1]', 'int'),0),
		@factura = isnull(@parXML.value('(//@factura)[1]', 'varchar(20)'),isnull(@parXML.value('(/*/*/@factura)[1]', 'varchar(20)'),'')),
		@valuta = isnull(isnull(@parXML.value('(//@valuta)[1]', 'varchar(3)'),@parXML.value('(/*/*/@valuta)[1]', 'varchar(3)')),''),
		@lm = isnull(@parXML.value('(/*/*/@lm)[1]', 'varchar(13)'),isnull(@parXML.value('(/*/@lm)[1]', 'varchar(13)'),'')),
		@cod = isnull(@parXML.value('(/*/*/@cod)[1]', 'varchar(20)'),''),
		@gestiune = isnull(@parXML.value('(//@gestiune)[1]', 'varchar(13)'),''),
		@suma = isnull(@parXML.value('(//@suma)[1]', 'float'),'0'),
		@curs = isnull(isnull(@parXML.value('(//@curs)[1]', 'float'),@parXML.value('(/*/*/@curs)[1]', 'float')),0) ,
		@data = isnull(@parXML.value('(//@data)[1]', 'datetime'),''),
		@dataJos = ISNULL(@parXML.value('(//@datajos)[1]', 'datetime'),'1901-01-01'),
		@dataSus = ISNULL(@parXML.value('(//@datasus)[1]', 'datetime'),'2901-01-01')

	if ISNULL(@valuta,'')<>'' and ISNULL(@curs,0)=0
		raiserror('Daca ati selectat o valuta, trebuie sa introduceti si cursul valutar!',11,1)

	if ISNULL(@tert,'')=''
		raiserror('Tert necompletat!',11,1)

	--calcul sold tert in 408
	set @soldTert=0
	
	select f.Subunitate as sub,rtrim(f.tip) as tip,f.Data as data, rtrim(f.Numar) as numar
		,convert(float,0) as cumulat,CONVERT(float,0) as suma,ROW_NUMBER() OVER (ORDER BY l.idLegDoc desc /*F.DATA_SCADENTEI,f.factura*/) as nrp,
		coalesce((case f.Tip when 'AP' then pa.Factura_stinga when 'AC' then b.Factura end),nullif(f.Factura,''),f.Numar) as factura, 
		isnull(nullif(nullif(isnull((case f.Tip when 'AP' then pa.Data_fact when 'AC' then b.Data_facturii end),f.Data_facturii),'1900-01-01'),'1900-01-01'),f.data) as data_factura,
		isnull(nullif(nullif(isnull((case f.Tip when 'AP' then pa.Data_scad when 'AC' then b.Data_scadentei end),f.Data_scadentei),'1900-01-01'),'1900-01-01'),f.Data_scadentei) as data_scadentei,
		rtrim(f.Cod_tert) as beneficiar, rtrim(t.Denumire) as denbeneficiar,
		f.loc_munca,f.comanda,f.valuta,f.curs,
		case when isnull(f.Valuta,'')<>'' then f.Valoare_valuta else f.Valoare end as valoare,
		f.TVA_22, 0 as selectat, 0 as factnoua,space(20) as cod,space(80) as denumire,convert(float,0.00) as cantitate,
		a.Valoare+a.Tva_22-a.Achitat AS sold
	into #doc
	from doc f 
		inner join yso_LegComisionVanzari l on l.subDoc=f.Subunitate and l.tipDoc=f.Tip and l.dataDoc=f.Data and l.nrDoc=f.Numar
		inner join terti t on t.Subunitate=f.Subunitate and t.Tert=f.Cod_tert 
		left join 
			(select b.Data_bon, b.yso_numar_in_pozdoc, b.Factura, b.Data_facturii,
				ROW_NUMBER() OVER(PARTITION BY b.data_bon, b.yso_numar_in_pozdoc ORDER BY b.factura DESC, b.data_facturii DESC) AS nrBonFact
			from antetbonuri b join antetBonuri ab on ab.Chitanta=0 and ab.Factura=b.Factura and ab.Data_facturii=b.Data_facturii
			where b.Chitanta=1 --and b.Data_bon<=@data 
			--group by b.Data_bon, b.yso_numar_in_pozdoc, b.Factura, b.Data_facturii
			) AS B
		ON b.Data_bon=f.Data and b.yso_numar_in_pozdoc=f.Numar  and b.nrBonFact=1
		left join 
			(select pa.Subunitate, pa.Factura_stinga, pa.Factura_dreapta, pa.Data_fact, pa.Tert,
				ROW_NUMBER() OVER(PARTITION BY pa.factura_dreapta, pa.tert ORDER BY pa.factura_stinga DESC, pa.data_fact DESC) AS nrIntocFact
			from pozadoc pa where pa.Tip='IF' and pa.Factura_stinga<>'' --and pa.Data>=@data
			--group by pa.Subunitate, pa.Factura_stinga, pa.Factura_dreapta, pa.Data_fact, pa.Tert
			) Pa 
		ON pa.Subunitate=f.Subunitate and pa.Factura_dreapta=f.Factura and pa.tert=f.cod_tert and pa.nrIntocFact=1
		left join facturi a ON a.Subunitate=f.Subunitate and a.Tip=0x46 and a.Tert=f.Cod_tert 
			and a.Factura=coalesce((case f.Tip when 'AP' then pa.Factura_stinga when 'AC' then f.Factura end),nullif(f.Factura,''),f.Numar)
	where l.idPozDoc=@idpozdoc 
	order by l.idLegDoc desc--f.data,f.factura

	set @dentert=(select RTRIM(denumire)from terti where tert=@tert and Subunitate=@sub)
	
	select --tert='', dentert='',
		rtrim(p.Numar) numar , rtrim(p.Tert) furnizor, RTRIM(t.Denumire) denfurnizor, convert(varchar(30),@data,101) data, p.numar_pozitie numarpozitie, 
		p.Tip tip, convert(decimal(12,2),p.TVA_deductibil) sumaTVA, convert(varchar(5),convert(decimal(5,2),p.cota_tva)) cotatva, convert(decimal(5, 2), p.discount) as discount,
		rtrim(p.gestiune) gestiune, rtrim(g.Denumire_gestiune) dengestiune, rtrim(p.Cod) cod, RTRIM(n.Denumire) dencod, rtrim(p.Cod_intrare) codintrare, 
		convert(decimal(12,2),p.Pret_cu_amanuntul) pamanunt, convert(decimal(17,5),p.Pret_valuta) pvaluta,
		rtrim(p.Cont_de_stoc) as contstoc, rtrim(p.Cont_de_stoc)+' - '+RTRIM(cs.Denumire_cont) as dencontstoc,
		rtrim(p.Cont_corespondent) as contcorespondent, rtrim(p.Cont_corespondent)+' - '+RTRIM(cc.Denumire_cont) as dencontcorespondent,
		rtrim(p.Cont_intermediar) as contintermediar, rtrim(p.Cont_intermediar)+' - '+RTRIM(ci.Denumire_cont) as dencontintermediar,
		rtrim(p.Cont_factura) as contfactura, rtrim(p.Cont_factura)+' - '+RTRIM(cf.Denumire_cont) as dencontfactura,
		rtrim(p.Cont_venituri) as contvenituri, rtrim(p.Cont_venituri)+' - '+RTRIM(cv.Denumire_cont) as dencontvenituri,
		rtrim(p.Comanda) as comanda, rtrim(p.Comanda)+' - '+RTRIM(cz.Descriere) as dencomanda,
		RTRIM(RIGHT(p.comanda,20)) as indbug, --indicatorul bugetar se tine in ultimele 20 de caractere ale campului comanda din pozdoc
		convert(char(1),p.Procent_vama) as tiptva, p.idpozdoc, 
		p.detalii
	from pozdoc p
		left join nomencl n on n.Cod=p.Cod 
		left join conturi cs on cs.Cont=p.Cont_de_stoc
		left join conturi cc on cc.Cont=p.Cont_corespondent
		left join conturi ci on ci.Cont=p.Cont_intermediar
		left join conturi cf on cf.Cont=p.Cont_factura
		left join conturi cv on cf.Cont=p.Cont_venituri
		left join terti t on t.Tert=p.Tert
		left join comenzi cz on cz.comanda=p.comanda
		left join gestiuni g on g.cod_gestiune=p.gestiune
	where p.idPozdoc=@idpozdoc
	for xml raw, root('Date')

	--date pentru grid
	SELECT --1 as areDetaliiXml,
		(SELECT
			row_number() over (order by p.nrp) as nrcrt,
			RTRIM(@tert) as furnizor,
			RTRIM(@factura) as factFurniz,
			RTRIM(p.sub) as sub,
			RTRIM(p.tip) as tip,
			CONVERT(varchar(10),p.data,101) as data,
			rtrim(p.numar) as numar,
			--@tip as subtip,
			rtrim(p.Factura) as factBenef,
			p.beneficiar , p.denbeneficiar,
			CONVERT(varchar(10),p.data_factura,101) as data_factura,
			CONVERT(varchar(10),p.Data_scadentei,101) as data_scadentei,
			convert(decimal(17,2),p.Valoare+p.TVA_22) as valoare,
			convert(decimal(17,2),p.Valoare) as valftva,
			convert(decimal(17,2),p.suma) as suma,
			convert(decimal(17,2),(CASE WHEN p.sold >=0.01 THEN p.sold END)) as sold,
			CONVERT(decimal(12,5),@curs) as curs,
			@valuta as valuta,
			case when ISNULL(@valuta,'')='' then 'RON' else @valuta end as denvaluta,
			convert(int,selectat) as selectat,
			convert(int,factnoua) as factnoua,
			convert(decimal(17,2),@suma) as sumaFixaPoz,
			ltrim(p.denumire) as denumire,
			convert(decimal(12,2),cantitate) as cantitate,
			@lm as lm
		FROM  #doc p 
		order by p.nrp
		FOR XML RAW, TYPE
		)
	FOR XML PATH('DateGrid'), ROOT('Mesaje')
	
	select 1 as areDetaliiXml for xml raw, root('Mesaje')
	
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (yso_wOPComisionareDocumenteVanzari_p)'
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	RAISERROR (@mesaj, 11, 1)
END CATCH