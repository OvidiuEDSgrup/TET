CREATE PROCEDURE yso_wOPCompletareDetaliiCorectii_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @tert VARCHAR(20), @mesaj VARCHAR(400), @dataJos DATETIME, @dataSus DATETIME,
		@tip VARCHAR(2), @utilizator varchar(50), @suma float, @data datetime, @valuta varchar(3),
		@dentert varchar(200), @numar varchar(20), @cont varchar(13), @curs float, @sub varchar(9),
		@soldTert float, @lm varchar(13), @factura varchar(20), @gestiune varchar(13), @cod varchar(20), @flm int

	declare @numar_pozitie int, @idpozadoc int
	
	select 
		@numar_pozitie=@parXML.value('(/row/row/@numarpozitie)[1]','int'),
		@idpozadoc=@parXML.value('(/row/row/@idpozadoc)[1]','int')

	if @idpozadoc is null
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
	
	select l.subunit as sub, 
		ROW_NUMBER() OVER (ORDER BY l.idPozCor) as nrp,
		RTRIM(p.Factura_dreapta) as factura, 
		p.Data_fact as data_factura,
		p.Data_scad as data_scadentei,
		--rtrim(l.tert) as furnizor, rtrim(t.Denumire) as denfurnizor,
		p.loc_munca,p.comanda,p.valuta,p.curs,
		p.suma as valoare,
		p.TVA22, 0 as selectat, 0 as factnoua,
		l.cod_articol, rtrim(f.denumire) as denumire,l.cantitate as cantitate
		--a.Valoare+a.Tva_22-a.Achitat AS sold
	into #coduri
	from yso_Articole_corectii l 
		inner join pozadoc p on p.idPozadoc = l.idPozADoc
		inner join nomencl f on l.cod_articol = f.Cod
		--inner join terti t on t.Subunitate=l.subunit and t.Tert=l.tert 
	where l.idPozADoc=@idpozadoc 
	order by l.idPozCor

	set @dentert=(select RTRIM(denumire)from terti where tert=@tert and Subunitate=@sub)
	
	select p.Tip tip, rtrim(p.numar_document) numar, rtrim(p.Tert) tert, RTRIM(t.Denumire) dentert, convert(varchar(30),@data,101) data, p.numar_pozitie numarpozitie, 
		p.factura_stinga as facturastinga, p.factura_dreapta as facturadreapta, 
		p.valuta as valuta, p.curs as curs, p.suma_valuta as sumavaluta, 
		convert(decimal(12,2),p.suma) as suma, convert(decimal(12,2),p.TVA11) as cotatva, convert(decimal(12,2),p.TVA22) as sumatva, 
		rtrim(p.Cont_deb) as contdeb, rtrim(p.Cont_deb)+' - '+RTRIM(cd.Denumire_cont) as dencontdeb,
		rtrim(p.Cont_cred) as contcred, rtrim(p.Cont_cred)+' - '+RTRIM(cc.Denumire_cont) as dencontcred,
		p.Tert_beneficiar as tertbenef, p.Dif_TVA as diftva, p.Achit_fact as achitfact, 
		(case when p.valuta='' then '' else p.cont_dif end) as contdifcurs, 
		(case when p.valuta='' then 0 else convert(decimal(15, 2), p.suma_dif) end) as sumadifcurs, 
		left(p.comanda,20) as comanda, ISNULL(c.descriere, '') as dencomanda, 
		p.loc_munca as lm, ISNULL(lm.denumire, '') as denlm, 
		p.Data_fact as datafacturii, p.Data_scad as datascadentei, 
		p.explicatii as explicatii, 
		p.Stare as tiptva, p.idpozadoc, p.detalii
	from pozadoc p
		left outer join conturi cd on cd.subunitate = p.subunitate and cd.cont = p.cont_deb
		left outer join conturi cc on cc.subunitate = p.subunitate and cc.cont = p.Cont_cred
		left join terti t on t.subunitate = p.subunitate and t.Tert=p.Tert
		left outer join lm on lm.Cod=p.Loc_munca
		left outer join comenzi c on c.Subunitate=p.Subunitate and c.Comanda=rtrim(left(p.comanda,20))
	where p.idPozadoc=@idpozadoc
	for xml raw, root('Date')

	--date pentru grid
	SELECT --1 as areDetaliiXml,
		(SELECT
			row_number() over (order by p.nrp) as nrcrt,
			cod_articol , denumire,
			convert(decimal(17,2),p.cantitate) as cantitate,
			convert(decimal(17,2),p.pret) as pret,
			convert(decimal(17,4),p.pret_valuta) as pret_valuta,
			convert(int,selectat) as selectat
		FROM  #coduri p 
		order by p.nrp
		FOR XML RAW, TYPE
		)
	FOR XML PATH('DateGrid'), ROOT('Mesaje')
	
	select 1 as areDetaliiXml for xml raw, root('Mesaje')
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (yso_wOPCompletareDetaliiCorectii_p)'
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	RAISERROR (@mesaj, 11, 1)
END CATCH