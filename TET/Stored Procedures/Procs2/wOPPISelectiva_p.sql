CREATE PROCEDURE wOPPISelectiva_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @tert VARCHAR(20), @mesaj VARCHAR(400), @dataJos DATETIME, @dataSus DATETIME, 
		@tipOperatiune VARCHAR(2), @utilizator varchar(50), @suma float, @data datetime, @valuta varchar(3), @factura VARCHAR(20), 
		@marca varchar(6), @decont varchar(40), @dentert varchar(200), @numar varchar(13), @cont varchar(40), @curs float, @jurnal varchar(20), 
		@sub varchar(9), @bugetari int, @rulajelm int, @facturiPeConturi int, 
		@soldTert float, @efect_antet varchar(20), @tipED varchar(2), @lm varchar(13), @detalii_antet xml, @detalii_pozitii xml, @filtrulm int, @locmImplicit varchar(9),
		@date xml
	
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	set @filtrulm=0
	if exists (select 1 from lmfiltrare where utilizator=@utilizator) -- daca are filtrare pe loc munca
	begin
		select top 1 @locmImplicit=cod from lmfiltrare l where l.utilizator=@utilizator 
		set @filtrulm=1
	end

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub OUTPUT --> citire subunitate din proprietati 
	EXEC luare_date_par 'GE', 'BUGETARI', @bugetari OUTPUT, 0, '' --> citire specific bugetari din parametrii
	EXEC luare_date_par 'GE', 'RULAJELM', @rulajelm OUTPUT, 0, '' --> citire rulaje pe locuri de munca

	SET @tipOperatiune = isnull(@parXML.value('(/*/*/@tipOperatiune)[1]', 'varchar(2)'),'') 
	SET @tert = isnull(@parXML.value('(/*/*/@tert)[1]', 'varchar(20)'),'')
	SET @numar = isnull(@parXML.value('(/*/*/@numar)[1]', 'varchar(13)'),'')
	SET @cont = isnull(@parXML.value('(/*/*/@cont)[1]', 'varchar(40)'),'')
	SET @valuta = isnull(@parXML.value('(/*/*/@valuta)[1]', 'varchar(3)'),'')
	SET @factura = nullif(@parXML.value('(/*/*/@factura)[1]', 'varchar(20)'),'')
	SET @lm = isnull(@parXML.value('(/*/*/@lm)[1]', 'varchar(13)'),'')
	SET @suma = isnull(@parXML.value('(/*/*/@suma)[1]', 'float'),'') 
	SET @curs = isnull(@parXML.value('(/*/*/@curs)[1]', 'float'),'') 
	SET @data = isnull(@parXML.value('(/*/*/@data)[1]', 'datetime'),'') 
	SET @jurnal = isnull(@parXML.value('(/*/*/@jurnal)[1]', 'varchar(20)'),'')
-->	pentru deconturi
	SET @marca = @parXML.value('(/*/*/@marca)[1]', 'varchar(6)')
	SET @decont = @parXML.value('(/*/*/@decont)[1]', 'varchar(40)')
-->	pentru efecte
	SET @efect_antet = isnull(@parXML.value('(/*/*/@efect_antet)[1]', 'varchar(20)'),'')
	SET @tipED = isnull(@parXML.value('(/*/*/@tipEd)[1]', 'varchar(2)'),'')
-->	formez contul pentru cazul in care nu s-a completat in antet	
	if @tipED='EF' and @cont=''
		set @cont=(case when @tipOperatiune='PF' then '403' when @tipOperatiune='IB' then '413' end)

-->	detalii antet (unde se pastreaza la efecte datele acestora)
	IF @parXML.exist('(/*/*/detalii_antet/row)[1]') = 1
		SET @detalii_antet = @parXML.query('(/*/*/detalii_antet/row)[1]')
-->	detalii pozitii (pentru eventualele informatii de introdus in pozplin.detalii)
	IF @parXML.exist('(/*/*/detalii/row)[1]') = 1
		SET @detalii_pozitii = @parXML.query('(/*/*/detalii/row)[1]')

	if ISNULL(@valuta,'')<>'' and ISNULL(@curs,0)=0
		raiserror('Pentru plati/incasari in valuta trebuie sa introduceti cursul valutar!',11,1)

	set @facturiPeConturi=0

	-- facturi de selectat 
	select 
		f.tert,f.factura,f.Data,f.Data_scadentei,
		f.Sold_valuta, f.sold,
		f.loc_de_munca,f.comanda,
		f.valuta,f.curs, f.Valoare_valuta, f.Valoare,
		f.TVA_22, f.cont_de_tert
	into #facturideselectat 
	from facturi f  
		left join LMFiltrare l on l.cod=f.loc_de_munca and l.utilizator=@utilizator
	where f.Subunitate=@sub
		and f.Tert=@tert
		and (@factura is null or f.factura=@factura)
		and (@tipOperatiune='IB' and f.Tip=0x46 or @tipOperatiune='PF' and f.Tip=0x54)
		and	(abs(f.Sold_valuta)>0.001 or (f.Valuta='' and abs(f.Sold)>0.001))   
		and ((f.Valuta=@valuta and ISNULL(@valuta,'')<>'') or (f.Valuta='' and isnull(@valuta,'')='')) 
		and not (@tipOperatiune='IB' and f.cont_de_tert like '418%') 
		and not (@tipOperatiune='PF' and f.cont_de_tert like '408%')
		and (@filtrulm=0 or l.cod is not null) -- filtrare pe locul de munca al utilizatorului, ca la autocomplete - daca se va dori sa fie aduse si altele, vom folosi SP1, unde vom pune locm implicit 

	if exists (select 1 from sysobjects where [type]='P' and [name]='wOPPISelectiva_pSP1')
		exec wOPPISelectiva_pSP1 @sesiune=@sesiune, @parXML=@parXML output

	--calcul sold tert
	set @soldTert=0
	select @soldTert=@soldTert + case when isnull(f.Valuta,'')<>'' then f.Sold_valuta else f.sold end
	from #facturideselectat f

	--daca nu se primeste suma, se va repartiza intreg soldul tertului pe valuta ceruta
	if ISNULL(@suma,0)=0 and @soldTert>0.001
		set @suma=@soldTert	
	
	/*	Daca bugetari, verificam daca exista mai multe conturi/mai multi indicatori bugetari pe o factura. 
		Si nu doar bugetari: la PF nu ar trebui sa dureze, iar pe partea de beneficiari doar daca s-a ales o factura.*/
	if @bugetari=1 or @tipOperatiune='PF' or @tipOperatiune='IB' --and @factura is not null	--Permis si la IB chiar daca nu s-a ales o factura (SNC are cazuri).
	begin
		if object_id('tempdb..#facturiPeConturi') is null
		Begin
			create table #facturiPeConturi (tert varchar(13))
			exec CreazaDiezFacturi @numeTabela='#facturiPeConturi'
		End

		exec FacturiPeConturi @sesiune=@sesiune, @parXML=@parXML output
		if exists (select 1 from #facturiPeConturi where nr_cont_fact>1)
			set @facturiPeConturi=1
	end

	select convert(float,0) as cumulat,CONVERT(float,0) as suma,ROW_NUMBER() OVER (ORDER BY (case when f.sold<0 then 0 else 1 end),F.DATA_SCADENTEI,f.factura) as nrp,  
		f.tert,f.factura,f.Data as data_factura,f.Data_scadentei,
		case when isnull(f.Valuta,'')<>'' then f.Sold_valuta else f.sold end as sold,
		rtrim(case when @filtrulm=1 and l.cod is null then @locmImplicit else f.loc_de_munca end) as loc_de_munca, -- tentativa de a prelua facturi de pe alte locuri de munca 
		f.comanda,
		f.valuta,f.curs, case when isnull(f.Valuta,'')<>'' then f.Valoare_valuta else f.Valoare end as valoare,
		f.TVA_22, 0 as selectat, 0 as factnoua, f.cont_de_tert, convert(varchar(20),'') as indicator
	into #facturi  
		from #facturideselectat f  
		left join LMFiltrare l on l.cod=f.loc_de_munca and l.utilizator=@utilizator
		where @facturiPeConturi=0 
	union all 
	select 999999999 as cumulat,CONVERT(float,0) as suma,999999999 as nrp,  
		@tert,'AVANS',@data,@data,999999999,'','',@valuta,0 as curs,0,0,0, 1 as factnoua, '' as cont_de_tert, convert(varchar(20),'') as indicator

	if @facturiPeConturi=1
		insert into #facturi
		select convert(float,0) as cumulat,CONVERT(float,0) as suma,ROW_NUMBER() OVER (ORDER BY (case when sum(f.sold)<0 then 0 else 1 end),max(f.DATA_SCADENTEI),f.factura) as nrp,  
			f.tert,f.factura,max(f.data_factura),max(f.Data_scadentei) as Data_scadentei,
			sum(f.sold) as sold,rtrim(isnull(p.cod,f.loc_de_munca)) as loc_de_munca,max(f.comanda) as comanda,max(f.valuta) as valuta,max(f.curs) as curs,sum(f.valoare) as valoare,
			sum(f.tva_22) as tva_22, 0 as selectat, 0 as factnoua, f.cont_de_tert, f.indbug as indicator
		from #facturiPeConturi f  
			left join proprietati p	on p.tip='LM' and p.cod_proprietate ='LMINCHCONT' 
				and p.valoare=1 and f.Loc_de_munca like rtrim(p.cod)+'%'
				and not exists (select 1 from proprietati pp where pp.tip='LM' and pp.cod_proprietate='LMINCHCONT' and pp.valoare=1 
				and f.Loc_de_munca like rtrim(pp.cod)+'%' and len(pp.cod)>len(p.cod))
				and @bugetari=1 and @rulajelm=1
		group by f.tert, f.factura, f.cont_de_tert, f.indbug, rtrim(isnull(p.cod,f.loc_de_munca))
	
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
	
	--daca nu exista facturi pe sold toata suma va merge pe avans
	if not exists (select 1 from #facturi where Factura<>'AVANS')
		update #facturi set suma=@suma where factura='AVANS'
	
	--stergem avansul daca nu e cazul
	delete from #facturi 
		where factura='AVANS' and suma=0	
			and exists (select 1 from #facturi where Factura<>'AVANS')
	
	--updatam campul selectat in functie de sumele repartizate pe facturi
	update #facturi set selectat=1 where abs(isnull(suma,0))>0.001

	set @dentert=(select RTRIM(denumire)from terti where tert=@tert and Subunitate=@sub)

	--date pentru form
	select @date =
	(
		select convert(varchar(10),@data,101) as data, @valuta as valuta, rtrim(@tert) as tert, rtrim(@tert)+' - '+rtrim(@dentert) as dentert, convert(decimal(17,2),@suma) as suma,
			@cont as cont, @numar as numar, CONVERT(decimal(12,5),@curs) as curs, CONVERT(decimal(17,2),@soldTert) as soldTert,
			convert(decimal(17,2),@suma) as sumaFixa, 0 as diferenta, @tipOperatiune as tipOperatiune, @detalii_antet as detalii, 
			--date necesare pentru efecte
			@tipED as tipEd, rtrim(@efect_antet) as efect/*, @ext_cont_in_banca as ext_cont_in_banca, @ext_serie_CEC as ext_serie_CEC, @ext_numar_CEC as ext_numar_CEC,
			@ext_cont_in_banca_tert as ext_cont_in_banca_tert, @ext_banca_tert ext_banca_tert, convert(char(10),@ext_datadocument,101) as ext_datadocument*/
		for xml raw, root('Date')	
	)
	/*
	--inserare 5 pozitii pentru eventualitatea in care se doreste plata/incasarea de facturi care nu sunt inca in asis(numai in cazul cont de casa)
	if @cont like '5311%'
	begin
		declare @nrp int
		select @nrp= max(nrp)
		from #facturi
		 
		insert into #facturi
		select 0 as cumulat,0 as suma, @nrp+1 as nrp,'' as factura,convert(char(10),@data,101) as data_factura,convert(char(10),@data,101) as data_scadentei,
			0 as sold,'' as loc_de_munca,'' as comanda,@valuta as valuta,@curs as curs, 0 as valoare, 0 as TVA_22, 0 as selectat, 1 as factnoua	
		union all
		select 0 as cumulat,0 as suma, @nrp+2 as nrp,'' as factura,convert(char(10),@data,101) as data_factura,convert(char(10),@data,101) as data_scadentei,
			0 as sold,'' as loc_de_munca,'' as comanda,@valuta as valuta,@curs as curs, 0 as valoare, 0 as TVA_22, 0 as selectat, 1 as factnoua		
		union all
		select 0 as cumulat,0 as suma, @nrp+3 as nrp,'' as factura,convert(char(10),@data,101) as data_factura,convert(char(10),@data,101) as data_scadentei,
			0 as sold,'' as loc_de_munca,'' as comanda,@valuta as valuta,@curs as curs, 0 as valoare, 0 as TVA_22, 0 as selectat, 1 as factnoua	
		union all
		select 0 as cumulat,0 as suma, @nrp+4 as nrp,'' as factura,convert(char(10),@data,101) as data_factura,convert(char(10),@data,101) as data_scadentei,
			0 as sold,'' as loc_de_munca,'' as comanda,@valuta as valuta,@curs as curs, 0 as valoare, 0 as TVA_22, 0 as selectat, 1 as factnoua			
		union all
		select 0 as cumulat,0 as suma, @nrp+5 as nrp,'' as factura,convert(char(10),@data,101) as data_factura,convert(char(10),@data,101) as data_scadentei,
			0 as sold,'' as loc_de_munca,'' as comanda,@valuta as valuta,@curs as curs, 0 as valoare, 0 as TVA_22, 0 as selectat, 1 as factnoua				
	end	
	*/

	alter table #facturi add detalii xml
	update #facturi set detalii=@detalii_pozitii
	update #facturi set detalii='<row />' where detalii is null
	update #facturi set detalii.modify('insert attribute indicator {sql:column("indicator")} into (/row)[1]')
	where indicator<>''
	update #facturi set detalii.modify('insert attribute lmdoc {sql:column("loc_de_munca")} into (/row)[1]') where @lm<>'' and Loc_de_munca not like rtrim(@lm)+'%' and loc_de_munca<>''

	/* am creat posibilitatea apelarii SP, pentru a putea altera (la nevoie) continutul tabelei #facturi. De ex. la ANAR (Jiu) se doreste sa nu fie bifat implicit campul Selectat */
	if exists (select 1 from sysobjects where [type]='P' and [name]='wOPPISelectiva_pSP')
		exec wOPPISelectiva_pSP @sesiune=@sesiune, @parXML=@parXML output

	/* 
		am creat posibilitatea apelarii SP, pentru a altera (la nevoie) si datele din antet si pozitiile
		am lasat wOPPISelectiva_pSP pentru compatibilitate cu programele mai vechi
	*/
	if exists (select 1 from sysobjects where [type]='P' and [name]='wOPPISelectiva_pSP2')
		exec wOPPISelectiva_pSP2 @sesiune=@sesiune, @date=@date output

	-- Trimit datele de antet
	select @date

	--date pentru grid
	SELECT (   
		SELECT
			row_number() over (order by p.nrp) as nrcrt,
			rtrim(@numar) as numar,
			RTRIM(@tert) as tert,
			RTRIM(@marca) as marca,
			RTRIM(@decont) as decont,
			@tipOperatiune as subtip,
			rtrim(p.Factura) as factura,
			rtrim(p.Factura) as facturaInit,
			CONVERT(varchar(10),p.data_factura,101) as data_factura,
			CONVERT(varchar(10),p.Data_scadentei,101) as data_scadentei,
			convert(decimal(17,2),case when p.Factura='AVANS' then 0 else p.sold end) as sold,
			convert(decimal(17,2),p.Valoare+p.TVA_22) as valoare,
			convert(decimal(17,2),p.suma) as suma,
			CONVERT(decimal(12,5),@curs) as curs,
			rtrim(@valuta) as valuta,
			(case when ISNULL(@valuta,'')='' then 'RON' else @valuta end) as denvaluta,
			convert(int,selectat) as selectat,
			convert(int,factnoua) as factnoua,
			convert(decimal(17,2),@suma) as sumaFixaPoz,
			rtrim(case when p.Loc_de_munca like rtrim(@lm)+'%' then p.Loc_de_munca else isnull(nullif(@lm,''),p.Loc_de_munca) end) as lm, 
			rtrim(p.Loc_de_munca) as lmfact, rtrim(p.cont_de_tert) as cont, rtrim(p.indicator) as indicator,
			rtrim(@jurnal) as jurnal, 
			p.detalii,
			rtrim(l.denumire) denlm
			--@detalii_pozitii as detalii
		FROM  #facturi p
		LEFT JOIN Lm l on l.cod=rtrim(case when p.Loc_de_munca like rtrim(@lm)+'%' then p.Loc_de_munca else isnull(nullif(@lm,''),p.Loc_de_munca) end)
		order by p.nrp
		FOR XML RAW, TYPE  
		)  
	FOR XML PATH('DateGrid'), ROOT('Mesaje')

	IF @tipED='EF'
		SELECT '1' AS areDetaliiXml FOR XML raw, root('Mesaje')
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPPISelectiva_p)'
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	RAISERROR (@mesaj, 11, 1)
END CATCH
/*
select * from facturi
*/
