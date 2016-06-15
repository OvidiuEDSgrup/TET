CREATE PROCEDURE wOPSFIFSelectiva_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @tert VARCHAR(20), @mesaj VARCHAR(400), @dataJos DATETIME, @dataSus DATETIME,
		@tip VARCHAR(2), @utilizator varchar(50), @suma float, @data datetime, @valuta varchar(3),
		@dentert varchar(200), @numar varchar(20), @cont varchar(13), @curs float, @sub varchar(9),
		@soldTert float, @lm varchar(13), @factura varchar(200), @gestiune varchar(13), @cod varchar(20), @flm int

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub OUTPUT --> citire subunitate din proprietati

	SELECT
		@tip = isnull(@parXML.value('(/*/*/@tip)[1]', 'varchar(2)'),''),
		@tert = isnull(@parXML.value('(//@tert)[1]', 'varchar(20)'),''),
		@numar = isnull(@parXML.value('(//@numar)[1]', 'varchar(20)'),''),
		@flm = isnull(@parXML.value('(//@flm)[1]', 'int'),0),
		@factura = isnull(@parXML.value('(//@factura)[1]', 'varchar(20)'),isnull(@parXML.value('(/*/*/@factura)[1]', 'varchar(20)'),'')),
		@valuta = isnull(isnull(@parXML.value('(//@valuta)[1]', 'varchar(3)'),@parXML.value('(/*/*/@valuta)[1]', 'varchar(3)')),''),
		@lm = isnull(@parXML.value('(/*/*/@lm)[1]', 'varchar(13)'),''),
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

	select f.tip,convert(float,0) as cumulat,CONVERT(float,0) as suma,ROW_NUMBER() OVER (ORDER BY F.DATA_SCADENTEI,f.factura) as nrp,
		f.factura,f.Data as data_factura,f.Data_scadentei,
		case when isnull(f.Valuta,'')<>'' then f.Sold_valuta else f.sold end as sold,f.loc_de_munca,
		f.comanda,f.valuta,f.curs,
		case when isnull(f.Valuta,'')<>'' then f.Valoare_valuta else f.Valoare end as valoare,
		f.TVA_22, 0 as selectat, 0 as factnoua,space(20) as cod,space(80) as denumire,convert(float,0.00) as cantitate
	into #facturi
	from facturi f
	where f.Subunitate=@sub
		and f.Tert=@tert
		and (f.Tip=0x54 and @tip in ('RM','RS') or f.Tip=0x46 and @tip in ('AP','AS'))
		and	(abs(f.Sold_valuta)>0.001 or (f.Valuta='' and abs(f.Sold)>0.001))
		and (f.Valuta=@valuta or (f.Valuta='' and isnull(@valuta,'')=''))
		and (f.Cont_de_tert like '408%' and @tip in ('RM','RS') or f.Cont_de_tert like '418%' and @tip in ('AP','AS'))
		and (f.loc_de_munca=@lm or @flm=0)
		and (f.data between @datajos and @datasus)
	order by f.data,f.factura

	update #facturi
	set cod=calcule.cod,cantitate=calcule.cantitate,denumire=calcule.denumire
	from 
		(select p.factura,sum(p.cantitate) as cantitate,max(p.cod) as cod,max(n.denumire) as denumire
		from #facturi f
		inner join pozdoc p on p.subunitate=@sub and p.Tert=@tert and p.factura=f.factura
		inner join nomencl n on p.cod=n.cod
		and (f.Tip=0x54 and p.tip in ('RM','RS') or f.Tip=0x46 and @tip in ('AP','AS'))
		and (f.loc_de_munca=@lm or @flm=0)
		group by p.factura
		) calcule where #facturi.factura=calcule.factura

	IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'wOPSFIFSelectivaSP_p')
		exec wOPSFIFSelectivaSP_p @sesiune=@sesiune, @parXML=@parXML

	select @soldTert=@soldTert + f.sold
	from #facturi f

	if @soldTert=0
	begin
		set @mesaj='Tertul introdus nu are sold in '+case when @tip in ('RM','RS') then '408' else '418' end+'!'
		raiserror(@mesaj,11,1)
	end
	
	--daca nu se primeste suma, se va repartiza intreg soldul tertului
	if @suma=0 and ABS(@soldTert)>0.001
		set @suma=@soldTert
			
	if @suma>@soldTert
	begin
		set @mesaj='Suma introdusa este mai mare decat soldul pe care il are tertul in '+case when @tip in ('RM','RS') then '408' else '418' end+'!'
		raiserror(@mesaj,11,1)
	end

	--calculam cumulatul la fiecare pozitie, bazat pe numarul de ordine primit de fiecare factura
	update #facturi set
		cumulat=facturicalculate.cumulat
	from (select p2.nrp,sum(p1.sold) as cumulat
		from #facturi p1,#facturi p2
		where p1.nrp<p2.nrp
		group by p2.nrp) facturicalculate
	where facturicalculate.nrp=#facturi.nrp

	--calculam suma pentru fiecare factura
	update #facturi set suma=case when cumulat+sold<=@suma then sold else dbo.valoare_maxima(0,convert(float,@suma)-convert(float,cumulat),0) end

	--updatam campul selectat in functie de sumele repartizate pe facturi
	update #facturi set selectat=1 where isnull(abs(suma),0)>0.001
	--update #facturi set selectat=0 

	set @dentert=(select RTRIM(denumire)from terti where tert=@tert and Subunitate=@sub)
	--date pentru form
	select convert(varchar(10),@data,101) as data, rtrim(@valuta) as valuta, rtrim(@tert) as tert, rtrim(@tert)+' - '+rtrim(@dentert) as dentert, convert(decimal(17,2),@suma) as suma,
		rtrim(@numar) as numar, CONVERT(decimal(12,5),@curs) as curs,-- CONVERT(decimal(17,2),@soldTert) as soldTert,
		convert(decimal(17,2),@suma) as sumaFixa, 0 as diferenta, @tip as tip,@tip as tipDoc,
		@lm as lm,@gestiune as gestiune, @cod cod
	for xml raw, root('Date')

	--date pentru grid
	SELECT (
		SELECT
			row_number() over (order by p.nrp) as nrcrt,
			rtrim(@numar) as numar,
			RTRIM(@tert) as tert,
			@tip as tip,
			@tip as subtip,
			rtrim(p.Factura) as factura,
			rtrim(p.Factura) as facturaInit,
			CONVERT(varchar(10),p.data_factura,101) as data_factura,
			CONVERT(varchar(10),p.Data_scadentei,101) as data_scadentei,
			convert(decimal(17,2),p.sold) as sold,
			convert(decimal(17,2),p.Valoare+p.TVA_22) as valoare,
			convert(decimal(17,2),p.Valoare) as valftva,
			convert(decimal(17,2),p.suma) as suma,
			CONVERT(decimal(12,5),@curs) as curs,
			@valuta as valuta,
			case when ISNULL(@valuta,'')='' then 'RON' else @valuta end as denvaluta,
			convert(int,selectat) as selectat,
			convert(int,factnoua) as factnoua,
			convert(decimal(17,2),@suma) as sumaFixaPoz,
			ltrim(denumire) as denumire,
			convert(decimal(12,2),cantitate) as cantitate,
			@lm as lm
		FROM  #facturi p
		order by p.nrp
		FOR XML RAW, TYPE
		)
	FOR XML PATH('DateGrid'), ROOT('Mesaje')
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPSFIFSelectiva_p)'
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	RAISERROR (@mesaj, 11, 1)
END CATCH
