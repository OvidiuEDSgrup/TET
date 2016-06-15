
CREATE PROCEDURE wOPSFIFSelectivaAD_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @tert VARCHAR(20), @mesaj VARCHAR(400), @dataJos DATETIME, @dataSus DATETIME,
		@tip VARCHAR(2), @utilizator varchar(50), @suma float, @data datetime, @valuta varchar(3),
		@dentert varchar(200), @numar varchar(13), @cont varchar(13), @contcred varchar(40), @curs float, @sub varchar(9),
		@soldTert float, @lm varchar(13), @factura varchar(200), @facturadreapta varchar(20), @gestiune varchar(13), @facturastinga varchar(20), 
		@cotatva decimal(12,2), @tiptva int, @date xml

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub OUTPUT --> citire subunitate din proprietati

	SET @tip = isnull(@parXML.value('(/*/*/@tip)[1]', 'varchar(2)'),'')
	SET @tert = isnull(@parXML.value('(/*/*/@tert)[1]', 'varchar(20)'),'')
	SET @data = isnull(@parXML.value('(/*/*/@data)[1]', 'datetime'),'')
	SET @lm = isnull(@parXML.value('(/*/*/@lm)[1]', 'varchar(13)'),'')
	SET @suma = isnull(@parXML.value('(/*/*/@suma)[1]', 'float'),'')
	SET @numar = isnull(@parXML.value('(/*/*/@numar)[1]', 'varchar(13)'),'')
	SET @factura = isnull(@parXML.value('(/*/@factura)[1]', 'varchar(20)'),'')
	SET @valuta = isnull(@parXML.value('(/*/*/@valuta)[1]', 'varchar(20)'),'')
	SET @curs = isnull(@parXML.value('(/*/*/@curs)[1]', 'float'),'')
	SET @facturadreapta = isnull(@parXML.value('(/*/*/@facturadreapta)[1]', 'varchar(20)'),'')
	SET @contcred = isnull(@parXML.value('(/*/*/@contcred)[1]', 'varchar(40)'),'')
	SET @cotatva = isnull(@parXML.value('(/*/*/@cotatva)[1]', 'decimal(12,2)'),24)
	SET @tiptva = isnull(@parXML.value('(/*/*/@tiptva)[1]', 'int'),0)

	if ISNULL(@tert,'')=''
		raiserror('Tert necompletat!',11,1)

	--calcul sold tert in 408
	set @soldTert=0
	select @soldTert=@soldTert + case when isnull(f.Valuta,'')<>'' then f.Sold_valuta else f.sold end
	from facturi f
	where f.subunitate=@sub and f.tert=@Tert
--		and (f.Tip=0x54 and @tip in ('RM','RS') or f.Tip=0x46 and @tip in ('AP','AS'))
		and (f.Tip=0x54 and @tip in ('SF'))
		and abs(f.Sold)>0.001
		and ((f.Valuta=@valuta and ISNULL(@valuta,'')<>'') or (f.Valuta='' and isnull(@valuta,'')=''))
		and (f.Cont_de_tert like '408%' and @tip in ('SF'))

	if @soldTert=0
	begin
		set @mesaj='Tertul introdus nu are sold in'+case when @tip='SF' then '408' else '418' end+'!'
		raiserror(@mesaj,11,1)
	end

	--daca nu se primeste suma, se va repartiza intreg soldul tertului
	--if ISNULL(@suma,0)=0 and @soldTert>0.001
	--	set @suma=@soldTert

	if @suma>@soldTert
	begin
		set @mesaj='Suma introdusa este mai mare decat soldul pe care il are tertul in '+case when @tip in ('SF') then '408' else '418' end+'!'
		raiserror(@mesaj,11,1)
	end


	select convert(float,0) as cumulat,CONVERT(float,0) as suma,ROW_NUMBER() OVER (ORDER BY F.DATA_SCADENTEI,f.factura) as nrp,
		f.factura,f.Data as data_factura,f.Data_scadentei,
		case when isnull(f.Valuta,'')<>'' then f.Sold_valuta else f.sold end as sold,f.loc_de_munca,
		f.comanda,f.valuta,f.curs,
		case when isnull(f.Valuta,'')<>'' then f.Valoare_valuta else f.Valoare end as valoare,
		f.TVA_22, 0 as selectat, 0 as factnoua
	into #facturi
	from facturi f
	where f.Subunitate=@sub
		and f.Tert=@tert
		and (f.Tip=0x54 and @tip in ('SF') or f.Tip=0x46 and @tip in ('IF'))
		and	(f.Sold_valuta>0.001 or (f.Valuta='' and f.Sold>0.001))
		and (f.Valuta=@valuta or (f.Valuta='' and isnull(@valuta,'')=''))
		and (f.Cont_de_tert like '408%' and @tip in ('SF') or f.Cont_de_tert like '418%' and @tip in ('IF'))

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
	update #facturi set selectat=1 where isnull(suma,0)>0.001

	set @dentert=(select RTRIM(denumire)from terti where tert=@tert and Subunitate=@sub)

	--date pentru form
	select @date = 
	(
		select convert(varchar(10),@data,101) as data, @valuta as valuta, rtrim(@tert) as tert, rtrim(@tert)+' - '+rtrim(@dentert) as dentert,
			convert(decimal(17,2),@suma) as suma,
			@numar as numar, CONVERT(decimal(12,5),@curs) as curs,-- CONVERT(decimal(17,2),@soldTert) as soldTert,
			convert(decimal(17,2),@suma) as sumaFixa, 0 as diferenta, @tip as tip,@tip as tipDoc,
			@lm as lm, @facturadreapta as facturadreapta, @contcred as contcred, @cotatva as cotatva, @tiptva as tiptva
		for xml raw, root('Date')
	)

	if exists (select 1 from sysobjects where type='P' and name='wOPSFIFSelectivaAD_pSP')
		exec wOPSFIFSelectivaAD_pSP @parXML, @date output

	select @date

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
			convert(decimal(17,2),p.suma) as suma,
			CONVERT(decimal(12,5),@curs) as curs,
			@valuta as valuta,
			case when ISNULL(@valuta,'')='' then 'RON' else @valuta end as denvaluta,
			convert(int,selectat) as selectat,
			convert(int,factnoua) as factnoua,
			convert(decimal(17,2),@soldTert) as sumaFixaPoz,
			@lm as lm
		FROM  #facturi p
		FOR XML RAW, TYPE
		)
	FOR XML PATH('DateGrid'), ROOT('Mesaje')
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPSFIFSelectivaAD_p)'
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	RAISERROR (@mesaj, 11, 1)
END CATCH


