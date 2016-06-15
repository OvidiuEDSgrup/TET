
create procedure wIaDoc @sesiune varchar(50), @parXML xml
as

begin try
	set transaction isolation level read uncommitted
	declare 
		@Sub char(9), @userASiS varchar(10), @facturiDefinitive int, @mesaj varchar(2000), 
		@tip varchar(2), @numar varchar(50), @data datetime, @f_data_jos datetime, @f_data_sus datetime, @f_numar varchar(50), 
		@f_gestiune varchar(50), @f_denumire_gestiune varchar(50), @f_gestiune_primitoare varchar(50), @f_denumire_gestiune_primitoare varchar(50), 
		@f_tert varchar(50), @f_denumire_tert varchar(50), @f_dencontvenituri varchar(50),
		@f_comanda varchar(50), @f_denumire_comanda varchar(50), @f_lm varchar(50), @f_denumire_lm varchar(50), 
		@f_valoare_minima float, @f_valoare_maxima float, @f_factura varchar(50), @f_data_fact_citit_jos varchar(50), @f_data_fact_citit_sus varchar(50), @f_data_facturii_jos datetime, @f_data_facturii_sus datetime, 
		@f_contractcor varchar(50), @f_stare varchar(50), @tip_doc varchar(2),
		@lista_gestiuni bit, @lista_clienti bit, @lista_lm bit,@ContAvizNefacturat varchar(40),@ContReceptieFactNesosita varchar(40),
		@gestTransport varchar(50), @f_stare_nou varchar(50), @f_contract varchar(40), @f_contfactura varchar(40), @lista_jurnale bit,
		@f_jurnal varchar(20)


	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output
	exec luare_date_par 'GE','FACTDEF',@facturiDefinitive output,0,''
	exec luare_date_par 'GE','GEST_TP', 0, 0, @gestTransport output
	exec luare_date_par 'GE', 'CTCLAVRT ', 0, 0, @ContAvizNefacturat output
	exec luare_date_par 'GE', 'CTFURECNE ', 0, 0, @ContReceptieFactNesosita output

	select @gestTransport=isnull(@gestTransport,'')

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	
	------------------------------------------------> filtrare specifica	<------------------------------------------------------------------------
	/**	Prin procedura wIaDocSP1 se filtreaza luarea documentelor pe date care nu sunt relevante pentru cazul general
		(de exemplu, pt Orto, este necesara filtrarea pe doc.detalii.row.@idFisa, daca exista in parXML parametrul @idFisa).
	*/
	declare @filtrareSP int	--> parametru prin care se semnaleaza existenta a cel putin unuia din filtrele specifice, deci a filtrarii specifice;
	select @filtrareSP=0	-->	daca nu exista filtrarea de tip specific nu se va aplica mai jos
	
		--> in #docsp se completeaza identificatorii unici ai documentelor care se incadreaza in filtrarea specifica; ramane necompletata daca nu exista filtrele;
		-->	va contine TOATE documentele filtrate din pozdoc, nu doar primele 100, pentru a nu se pierde ulterior documente prin filtrarea pe caz general.
	create table #docsp(subunitate varchar(9) default '1', tip varchar(2), data datetime, numar varchar(20))
	if exists (select 1 from sys.objects where name='wIaDocSP1')
	begin
		exec wIaDocSP1 @sesiune=@sesiune, @parxml=@parxml output	--> procedura specifica; va completa tabela #docsp si va stabili valoarea lui @filtrareSP
		select @filtrareSP=isnull(@parxml.value('(row/@filtrareSP)[1]','int'),0)
	end
	-------------------------------------------------------------------------------------------------------------------------------------------------
	
	select	
		@tip = rtrim(@parXML.value('(/row/@tip)[1]', 'varchar(2)')),
		@numar = rtrim(ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'),'')),
		@data = @parXML.value('(/row/@data)[1]', 'datetime'),
		@f_data_jos = ISNULL(@parXML.value('(/row/@datajos)[1]', 'datetime'),'01/01/1901'),
		@f_data_sus = ISNULL(@parXML.value('(/row/@datasus)[1]', 'datetime'),'12/31/2999'),
		@f_numar = ISNULL(@parXML.value('(/row/@f_numar)[1]', 'varchar(20)'),''),
		@f_gestiune = ISNULL(@parXML.value('(/row/@f_gestiune)[1]', 'varchar(9)'),''),
		@f_denumire_gestiune = ISNULL(@parXML.value('(/row/@f_dengestiune)[1]', 'varchar(30)'),''),
		@f_gestiune_primitoare = ISNULL(@parXML.value('(/row/@f_gestprim)[1]', 'varchar(9)'),''),
		@f_denumire_gestiune_primitoare = ISNULL(@parXML.value('(/row/@f_dengestprim)[1]', 'varchar(30)'),''),
		@f_tert = ISNULL(@parXML.value('(/row/@f_tert)[1]', 'varchar(13)'),''),
		@f_denumire_tert = ISNULL(@parXML.value('(/row/@f_dentert)[1]', 'varchar(80)'),''),
		@f_dencontvenituri = ISNULL(@parXML.value('(/row/@f_dencontvenituri)[1]', 'varchar(80)'),''),
		@f_comanda = ISNULL(@parXML.value('(/row/@f_comanda)[1]', 'varchar(20)'),''),
		@f_denumire_comanda = ISNULL(@parXML.value('(/row/@f_dencomanda)[1]', 'varchar(80)'),''),
		@f_lm = ISNULL(@parXML.value('(/row/@f_lm)[1]', 'varchar(9)'),''),
		@f_denumire_lm = ISNULL(@parXML.value('(/row/@f_denlm)[1]', 'varchar(30)'),''),
		@f_valoare_minima = ISNULL(@parXML.value('(/row/@f_valoarejos)[1]', 'float'),-99999999999),
		@f_valoare_maxima = ISNULL(@parXML.value('(/row/@f_valoaresus)[1]', 'float'),99999999999),
		@f_factura = ISNULL(@parXML.value('(/row/@f_factura)[1]', 'varchar(20)'),''),
		@f_data_fact_citit_jos = @parXML.value('(/row/@f_datafacturiijos)[1]', 'varchar(50)'),
		@f_data_fact_citit_sus = @parXML.value('(/row/@f_datafacturiisus)[1]', 'varchar(50)'),
		@f_contractcor = ISNULL(@parXML.value('(/row/@f_contractcor)[1]', 'varchar(20)'),''),
		@f_stare = ISNULL(@parXML.value('(/row/@f_stare)[1]', 'varchar(20)'),''),
		@f_stare_nou = @parXML.value('(/row/@f_stare_nou)[1]', 'varchar(50)'),
		@f_contract = ISNULL(@parXML.value('(/row/@f_contract)[1]', 'varchar(20)'),''),
		@f_contfactura = ISNULL(@parXML.value('(/row/@f_contfactura)[1]', 'varchar(20)'),''),
		@f_jurnal = ISNULL(@parXML.value('(/row/@f_jurnal)[1]', 'varchar(20)'),'')

	/* Variabila folosita pt. filtrarea tipului de document in tabelele doc/pozdoc, pentru ca sa nu facem multe case-uri */
	select @tip_doc=(case when @tip in ('RC','RA','RF') then 'RM' when @tip in ('AA','AB') then 'AP' else @tip end)

	select @f_data_facturii_jos= (case when len(@f_data_fact_citit_jos)>4 and ISDATE(dbo.fSchimbaZiLuna (@f_data_fact_citit_jos))=1 then convert(datetime, dbo.fSchimbaZiLuna (@f_data_fact_citit_jos)) end)
	select @f_data_facturii_sus= (case when len(@f_data_fact_citit_sus)>4 and ISDATE(dbo.fSchimbaZiLuna (@f_data_fact_citit_sus))=1 then convert(datetime, dbo.fSchimbaZiLuna (@f_data_fact_citit_sus)) end)

	select 
		'G' as tip_gestiune, cod_gestiune, left(Denumire_gestiune,30) as Denumire_gestiune 
	into #gest 
	from gestiuni where Subunitate=@Sub 
	union all 
	select 'F', marca, nume from personal
	CREATE UNIQUE CLUSTERED INDEX Idx1 ON #gest (tip_gestiune, cod_gestiune)


	declare @GestiuniUser table(valoare varchar(20))
	declare @ClientiUser table(valoare varchar(20))
	insert @GestiuniUser(valoare)
	select RTRIM(valoare) from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='GESTIUNE' and Valoare<>'' and valoare<>@gestTransport

	insert @ClientiUser(valoare)
	select RTRIM(valoare) from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='CLIENT' and Valoare<>''

	select @lista_gestiuni=0, @lista_clienti=0, @lista_lm=0
	if exists (select * from @GestiuniUser)
		set @lista_gestiuni=1
	if exists (select * from @ClientiUser)
		set @lista_clienti=1
	if exists (select * from LMFiltrare l where l.utilizator=@userASiS)
		set @lista_lm=1
	IF EXISTS (select * from PropUtiliz where utilizator=@userASiS and proprietate='JURNAL')
		select @lista_jurnale = 1


	/*Pentru filtrare pe folosinta sau gestiune*/
	declare @tipGestFiltrare char(1) /*Predator*/
		,@tipGestFiltrareP char(1) /*Primitor*/

	select
		@tipGestFiltrare=(case when @tip_doc in ('PF','CI','AF') then 'F' else 'G' end),
		@tipGestFiltrareP=(case when @tip_doc='TE' then 'G' else 'F' end)
	
	create table #d100(subunitate varchar(10), tip varchar(2), numar varchar(50), data datetime, facturanesosita bit, aviznefacturat bit)
	
	insert into #d100(subunitate, tip, numar, data, facturanesosita, aviznefacturat)
	select top 100 
		d.subunitate,d.tip,d.numar,d.data, --d.tva_11, d.tva_22  
		---in functie de contul facturi se aduce bifa de factura nesosita,pentru receptii
		(case when @tip_doc in ('RM','RS') and d.Cont_factura=@ContReceptieFactNesosita then 1 else 0 end ) as facturanesosita,
		---in functie de contul facturi se aduce bifa de aviz nefacturat, pentru avize
		(case when d.Tip in ('AP','AS') and d.Cont_factura =@ContAvizNefacturat then 1 else 0 end ) as aviznefacturat 
	from doc d
		left outer join terti t on t.subunitate = d.subunitate and t.tert = d.cod_tert 
		left outer join #gest gPred on gPred.cod_gestiune = d.cod_gestiune and gPred.tip_gestiune=@tipGestFiltrare
		left outer join #gest gPrim on gPrim.cod_gestiune = d.gestiune_primitoare and gPrim.tip_gestiune=@tipGestFiltrareP
		left outer join lm on lm.cod = d.loc_munca
		left outer join comenzi com on com.subunitate = @sub and com.comanda = left(d.comanda,20)  
		left outer join @GestiuniUser gu on gu.valoare=d.Cod_gestiune
		left outer join @GestiuniUser gpu on @tip_doc='TE' and gpu.valoare=d.Gestiune_primitoare
		left outer join con on d.Contractul=con.Contract and d.Data=con.Data and con.Tip='BK' and con.Subunitate=@Sub and d.Cod_tert=con.tert
		outer apply (select top 1 sd.stare,sd.denumire from JurnalDocumente jd JOIN StariDocumente sd on jd.stare=sd.stare and d.tip=sd.tipDocument	
					where tip=d.tip and numar=d.numar and data=d.data order by idJurnal desc) stari
	where d.subunitate=@Sub --and d.Jurnal<>'MFX' 
		and d.tip = @tip_doc 
		and (@tip='RC' and d.jurnal='RC' or @tip<>'RC' and (d.tip<>'RM' or d.jurnal<>'RC'))
		-- urmatoarele 2 elemente trebuie sa fie tratate in wIaDocSP1 la ARL sau cine va folosi aceste tipuri de doc. 
		and (@tip not in ('RA','RF') or @tip='RA' and d.Cont_factura=@ContReceptieFactNesosita or @tip='RF' and d.Cont_factura<>@ContReceptieFactNesosita)
		and (@tip not in ('AA','AB') OR @tip='AA' and d.Cont_factura=@ContAvizNefacturat OR @tip='AB' and d.Cont_factura<>@ContAvizNefacturat)
		and (@numar='' or d.numar like @numar)
		and (@f_numar='' or d.numar like @f_numar + '%' )
		and d.data between @f_data_jos and @f_data_sus
		and (@data is null or d.data=@data)
		and (@f_gestiune='' or d.cod_gestiune like @f_gestiune + '%' )
		and (@f_denumire_gestiune='' or left(isnull(gPred.denumire_gestiune, ''), 30) like '%' + replace(@f_denumire_gestiune,' ','%') + '%')
		and (@tip_doc not in ('TE', 'DF', 'PF') or @f_gestiune_primitoare='' or d.gestiune_primitoare like isnull(@f_gestiune_primitoare, '') + '%') 
		and (@f_denumire_gestiune_primitoare='' or left(isnull(gPrim.denumire_gestiune, ''), 30) like '%' + @f_denumire_gestiune_primitoare + '%')
		and (@f_tert='' or d.cod_tert like @f_tert + '%')
		and (@f_denumire_tert='' or isnull(t.denumire, '') like '%' + replace(@f_denumire_tert,' ','%') + '%' )
		and (@f_comanda='' or d.comanda like @f_comanda + '%')
		and (@f_denumire_comanda='' or isnull(com.descriere, '') like '%' + @f_denumire_comanda + '%')
		and (@f_lm='' or d.loc_munca like @f_lm + '%')
		and (@f_denumire_lm='' or isnull(lm.denumire, '') like '%' + @f_denumire_lm + '%')
		/*and (@f_valoare_minima=-99999999999 or (d.valoare+d.Tva_22) >= @f_valoare_minima)	Mutat filtrarea pe valori mai jos, dupa stabilirea lor prin procedura valoriDocument
		and (@f_valoare_maxima=99999999999 or (d.valoare+d.Tva_22) <= @f_valoare_maxima)*/
		and (@tip_doc in ('AS', 'RS','PF','CI','AF') or @lista_gestiuni=0 or gu.valoare is not null or gpu.Valoare is not null
			or @gestTransport is not null and d.gestiune_primitoare=@gesttransport and exists(select 1 from @GestiuniUser gpd where @tip_doc='TE' and gpd.valoare=d.Contractul)
			)	--> daca este desemnata o gestiune de tip transport atunci autofiltrarea pe gestiuni se va aplica si pe gestiune destinatara - daca gest prim e transport
		and (@tip_doc not in ('AP', 'AS','AF') or @lista_clienti=0 or /*cu.valoare is not null*/ exists (select * from @ClientiUser cu where cu.valoare=d.cod_tert))
		and (@lista_lm=0 or  exists (select * from LMFiltrare lu where lu.utilizator=@userASiS and (lu.cod=d.Loc_munca OR lu.cod=d.detalii.value('(/*/@lmdest)[1]','varchar(20)')))
			or gu.valoare is null and gpu.Valoare is not null) -- TI-urile sa nu tina cont de locul de munca, nefiind modificabile
		and (@f_factura='' or (case when @tip_doc in ('AI', 'AE', 'DF') then left(d.factura, 8)+left(d.Contractul, 8) else d.Factura end) like '%'+@f_factura + '%')
		and (@f_data_facturii_jos is null or d.data_facturii>=@f_data_facturii_jos)
		and (@f_data_facturii_sus is null or d.data_facturii<=@f_data_facturii_sus)
		and (@f_contractcor='' or isnull(con.contract_coresp, '') like @f_contractcor+'%')
		and (@f_contract='' OR d.Contractul like '%' +@f_contract+'%')
		and (@f_contfactura='' or d.Cont_factura like @f_contfactura + '%')
		and (@f_jurnal='' or d.jurnal like @f_jurnal+'%')
		and (@f_stare='' OR (stari.stare IS NOT NULL and stari.denumire like @f_stare+'%') OR (stari.stare is NULL and (isnull(d.stare,'') like @f_stare+'%' or (case when d.stare in (2,6) then 'Definitiv' when d.stare = 1 then 'Anulat' when d.stare = 4 then 'Stornat' else 'Operat' end) like  @f_stare+'%')))
			--> filtrare specifica; daca exista wIaDocSP1 si s-a folosit pentru filtrare se va tine cont de documentele returnate
		and (@filtrareSP=0 or exists (select 1 from #docsp df where df.subunitate=d.subunitate and df.tip=d.tip and df.data=d.data and df.numar=d.numar))
		and ( ISNULL(@lista_jurnale,0) = 0 OR EXISTS (select 1 from PropUtiliz pu where pu.utilizator=@userASIS and pu.proprietate='JURNAL' and pu.valoare=d.jurnal))
	order by d.data desc 

--select * from #d100
	alter table #d100 add cont_corespondent varchar(40),dencontcorespondent varchar(80),cont_venituri varchar(40),dencontvenituri varchar(80),
		cantitate decimal(17,3), valoare decimal(17,2), tva_11 decimal(17,2), tva_22 decimal(17,2), valoare_valuta decimal(17,2), valoare_pret_amanunt decimal(15,2),Numar_pozitii int,
		valoare_valuta_tert decimal(17,2)

	/* apelam procedura unica de stabilire a valorilor unui document */
	if exists (select * from sysobjects where name ='valoriDocument' and xtype='P')
	begin
		if object_id('tempdb..#valdoc') is not null drop table #valdoc
		create table #valdoc (subunitate varchar(9))
		exec valoriDocument_tabela
		insert into #valdoc (subunitate, tip, numar, data)
		select subunitate, tip, numar, data
		from #d100

		exec valoriDocument
		update d set d.Cont_corespondent=v.Cont_corespondent, d.Cont_venituri=v.Cont_venituri, 
			d.dencontcorespondent=rtrim(cc.Denumire_cont), d.dencontvenituri=rtrim(cv.denumire_cont),
			d.cantitate=v.cantitate, d.valoare=v.valoare, d.Tva_11=v.Tva_11, d.Tva_22=v.Tva_22, d.Valoare_valuta=v.Valoare_valuta, d.Valoare_valuta_tert=v.Valoare_valuta_tert, 
			d.Valoare_pret_amanunt=v.Valoare_pret_amanunt, 
			d.Numar_pozitii=v.Numar_pozitii
		from #d100 d
			left outer join #valdoc v on v.Subunitate=d.Subunitate and v.Tip=d.Tip and v.Numar=d.Numar and v.Data=d.Data
			left outer join conturi cc on cc.subunitate=v.subunitate and cc.cont=v.cont_corespondent
			left outer join conturi cv on cv.subunitate=v.subunitate and cv.cont=v.cont_venituri
	end
	/*	Aici se face filtrarea dupa valori, intrucat nu se mai scriu valorile in tabela doc si mai sus au fost determinate.*/
	delete from #d100 where @f_valoare_minima<>-99999999999 and (valoare+Tva_22)<@f_valoare_minima or @f_valoare_maxima<>99999999999 and (valoare+Tva_22)>@f_valoare_maxima

	select jd.tip,jd.numar,max(jd.idJurnal) as idJurnal
	into #j100
	from #d100
	inner join JurnalDocumente jd on #d100.tip=jd.tip and jd.numar=#d100.Numar
	group by jd.tip,jd.numar

	select 
		rtrim(d.subunitate) as subunitate, 
		@tip tip,
		rtrim(d.numar) as numar, rtrim(d.numar) as numarf, -- @numarf este numarul folosit ca manevra pentru schimbare in procedura specifica 
		convert(char(10),d.data,101) as data, convert(char(10),d.data,101) as dataf, -- idem
		rtrim(isnull(gPred.denumire_gestiune,'')) as dengestiune, rtrim(d.cod_gestiune) as gestiune, 
		rtrim(isnull(t.denumire,'')) as dentert, rtrim(d.cod_tert) as tert, rtrim(d.factura) as factura, 
		rtrim(d.contractul) as contract, rtrim(isnull(lm.denumire,'')) as denlm, rtrim(d.loc_munca) as lm, 
		isnull(rtrim(com.descriere),'') as dencomanda, 

		---despartire camp comanda in comanda(primele 20 caractere) si indicator bugetar(ultimele 20 caractere)----
		rtrim(left(d.comanda,20)) as comanda,  
		rtrim(substring(d.comanda,21,20)) as indbug,
		isnull(substring(indb.indbug,1,2),'  ')+'.'+isnull(substring(indb.indbug,3,2),'  ')+'.'+isnull(substring(indb.indbug,5,2),'  ')+'.'+isnull(substring(indb.indbug,7,2),'  ')+'.'
			+isnull(substring(indb.indbug,9,2),'  ')+'.'+isnull(substring(indb.indbug,11,2),'  ')+'.'+isnull(substring(indb.indbug,13,2),'  ')+' - '+rtrim(ltrim(indb.denumire)) as denbug,

		---daca documentul este transfer atunci campul gestiune_primitoare din doc este gestiunea primitoare, altfel in acest camp se salveaza punctul de livrare----
		---daca documentul este dare in folosinta campul gestiune_primitoare din doc este folosit pt salvarea marcii catre care se face darea in folosinta-----
		(case when d.tip in ('TE','DF','PF') then isnull(rtrim(d.gestiune_primitoare),'') else '' end) as gestprim,isnull(rtrim(gPrim.denumire_gestiune),'') as dengestprim, 
		(case when d.tip in ('AP', 'AS', 'AC') then isnull(rtrim(d.gestiune_primitoare),'') else '' end) as punctlivrare,rtrim(isnull(tpctliv.descriere, '')) as denpunctlivrare, 

		rtrim(d.valuta) as valuta,rtrim(v.Denumire_valuta) as denvaluta, convert(decimal(13,4), d.curs) as curs, 

		convert(decimal(17,3), d1.cantitate) as tcantitate, 
		convert(decimal(17,2), d1.valoare) as valoare, 
		convert(decimal(15,2), d1.tva_11) as tva11, convert(decimal(15,2),d1.tva_22) as tva22, 
		convert(decimal(15,2), d1.tva_11+d1.tva_22) as tvatotala, 
		(case when d.tip='TE' then convert(decimal(17,2),d1.valoare)/*+ convert(decimal(15,2),d1.valoare*0.24)*/ 
			else convert(decimal(17,2),d1.valoare)+ convert(decimal(15,2),isnull(d1.tva_11,0)+isnull(d1.tva_22,0)) end) as valtotala, 
		convert(decimal(15,2),d1.valoare_valuta) as valoarevaluta, 
		(case when d.Valuta='' then convert(decimal(15,2),d1.valoare)+convert(decimal(15,2),isnull(d1.tva_11,0)+isnull(d1.tva_22,0)) 
			else convert(decimal(15,2),d1.valoare_valuta) end) as totalvaloare, 
		convert(decimal(17,2), isnull(d1.valoare,0)+isnull(d1.tva_11,0)+isnull(d1.tva_22,0)) as valvalutacutva, -- variabila ciudata
		convert(decimal(17,2), isnull(d1.valoare_valuta,0)) as valvaluta,
		convert(decimal(17,2), isnull(d1.valoare_valuta_tert,0)) as valoare_valuta_tert,
		convert(decimal(17,2), isnull(d1.valoare_pret_amanunt,0)) as valinpamanunt,
		---in campul discount_suma, se salveaza categoria de pret 
		convert(int,d.Discount_suma) as categpret, rtrim(cpret.denumire)as dencatpret,
	
		facturanesosita, aviznefacturat, 

		convert(decimal(15,2), d.cota_tva) as cotatva,  convert(decimal(15,2), d.discount_p) as discount, convert(decimal(15,2), d.discount_suma) as sumadiscount,

		---campul cota_tva din doc se foloseste pentru tipul TVA-ului-------
		convert(varchar,convert(int,d.cota_tva)) as tiptva,
		(case when @tip_doc in ('RM','RS') and d.cota_tva=0 then '0-TVA Deductibil'
			when @tip_doc in ('RM','RS') and d.cota_tva=1 then '1-TVA Compensat'
			when @tip_doc in ('RM','RS') and d.cota_tva=2 then '2-TVA Nedeductibil'
			when @tip in ('AP', 'AS', 'AC') and d.cota_tva=0 then '0-TVA Colectat' 
			when @tip in ('AP', 'AS', 'AC') and d.cota_tva=1 then '1-TVA Compensat' 
			when @tip in ('AP', 'AS', 'AC') and d.cota_tva=2 then '2-TVA Neinregistrat' else '' end ) as denTiptva,

		---in cazul AP si AS campul numar_dvi este refolosit pentru salvarea explicatiilor de pe antet
		rtrim(case when d.tip in ('AI', 'AE', 'DF','AF') then left(d.factura, 8)+left(d.Contractul, 8) 
			when d.tip in ('AS','AP','RS') then rtrim(d.Numar_DVI) else '' end) as explicatii,
		rtrim(d.numar_dvi) as numardvi, 		
	 
		cast(cast(d.pro_forma as bit) as int) as proforma, 
		rtrim(d.tip_miscare) as tipmiscare,
		rtrim(d.cont_factura) as contfactura, 
		rtrim(d.cont_factura)+'-'+rtrim(isnull(cf.Denumire_cont, '')) as dencontfactura, 
		rtrim(d1.cont_corespondent) as contcorespondent, 
		d1.dencontcorespondent as dencontcorespondent, 
		rtrim(d1.cont_venituri) as contvenituri, 
		d1.dencontvenituri as dencontvenituri, 
		convert(char(10),d.Data_facturii,101) as datafacturii, convert(char(10),d.Data_scadentei,101) as datascadentei,
		datediff(DAY,d.Data_facturii,d.Data_scadentei) as zilescadenta, --zilele de scadenta se calculeaza din data scadentei 
		rtrim(d.jurnal) as jurnal, 
		--sum(case when p.Numar is null then 0 else 1 end) as numarpozitii, 
		d1.Numar_pozitii as numarpozitii, 
		rtrim(isnull(ad.numele_delegatului,'')) as numedelegat,  
		rtrim(isnull(ad.seria_buletin,'')) as seriabuletin,
		rtrim(isnull(ad.numar_buletin,'')) as numarbuletin,
		rtrim(isnull(ad.eliberat,'')) as eliberat,
		rtrim(isnull(ad.mijloc_de_transport,'')) as mijloctp,
		rtrim(isnull(ad.numarul_mijlocului,'')) as nrmijloctp,
		convert(char(10), isnull(ad.data_expedierii, ''), 101) as dataexpedierii, 
		isnull(ad.ora_expedierii, '') as oraexpedierii,
		rtrim(isnull(ad.observatii,'')) as observatii,
		rtrim(isnull(ad.punct_livrare,'')) as punctlivareexped,
		rtrim(isnull(con.Contract_coresp,'')) as contractcor,
		rtrim(d.stare) as stare, 
		(case when d.stare in (2,6) or d.jurnal='MFX' or inf.mod_tp='D' or 
			(d.tip='TE' and @lista_gestiuni=1 and gu.valoare is null and gpu.Valoare is not null) then 'Definitiv' 
			when d.stare = 1 then 'Anulat' when d.stare = 4 then 'Stornat' else 'Operat' end)  as denStare,
		--(case when d.stare = 2 then '#0B0B61' 
		(case when d.stare = 1 then '#660066'--starea anulat din doc trebuie sa fie mai tare decat starea din jurnaldocumente
		else
			(CASE when sd.culoare is not null then sd.culoare 
			else
				(case when d.stare in (2,6) or d.jurnal='MFX' or inf.mod_tp='D' or 
					(d.tip='TE' and @lista_gestiuni=1 and gu.valoare is null and gpu.Valoare is not null) then '#808080' 
						when d.stare = 1 then '#660066'/*'#FF8040'*/ when d.stare = 4 then '#0B3B24' 
					--when d.stare = 5 then '#408080' -- stare=3 inseamna operat direct, stare=5 inseamna generat din PV sau din alta aplicatie 
					when isnull(d1.Valoare,0) <= 0 then'#FF0000' else '#000000' end) end) end) as culoare,
		--cele care vin din PVria trebuie sa fie definitive.
		(case when d.Stare in (2,6) or d.jurnal='MFX' or inf.mod_tp='D' or (d.tip='TE' and @lista_gestiuni=1 and gu.valoare is null and gpu.Valoare is not null) then 1 else 0 end) as _nemodificabil
		--pentru tabul de inregitrari contabile
		,RTRIM(d.tip) tipdocument,RTRIM(d.numar) nrdocument,
		jd.stare as Stare1
	into #doc
	from #d100 d1 
		inner join doc d on d1.subunitate=d.subunitate and d1.tip=d.tip and d1.numar=d.numar and d1.data=d.data
		left outer join terti t on t.subunitate = @sub and t.tert = d.cod_tert 
		left outer join #gest gPred on gPred.cod_gestiune = d.cod_gestiune and gPred.tip_gestiune=(case when @tip_doc in ('PF','CI','AF') then 'F' else 'G' end)
		left outer join #gest gPrim on gPrim.cod_gestiune = d.gestiune_primitoare and gPrim.tip_gestiune=(case when @tip_doc='TE' then 'G' else 'F' end)
		left outer join lm on lm.cod = d.loc_munca
		left outer join comenzi com on com.subunitate = @sub and com.comanda = left(d.comanda,20)  
		left outer join indbug indb on indb.Indbug = substring(d.comanda,21,20)
		left outer join @GestiuniUser gu on gu.valoare=d.Cod_gestiune
		left outer join @GestiuniUser gpu on @tip_doc='TE' and gpu.valoare=d.Gestiune_primitoare
		left outer join conturi cf on @tip_doc not in ('PP', 'CM', 'PF', 'CI', 'AF') and cf.Subunitate=@sub and cf.Cont=d.Cont_factura
		left outer join infotert tpctliv on @tip_doc in ('AP','AS','AC') and tpctliv.Subunitate=@sub and tpctliv.Tert=d.cod_tert 
			and tpctliv.identificator=d.gestiune_primitoare and tpctliv.Identificator<>''
		left outer join categpret cpret on cpret.Categorie=d.Discount_suma
		left outer join anexadoc ad on ad.Subunitate=@sub and ad.Tip=@tip_doc and ad.Numar=d.Numar and ad.Data=d.Data and ad.Tip_anexa=''
		left outer join con on d.Contractul=con.Contract and d.Data=con.Data and con.Tip='BK' and con.Subunitate=@Sub and d.Cod_tert=con.tert
		left outer join incfact inf on @facturiDefinitive=1 and @tip_doc='AP' and inf.subunitate=@sub and inf.Numar_factura=d.factura and inf.Numar_pozitie=1
		left outer join valuta v on v.Valuta=d.Valuta
		left outer join #j100 on d1.tip=#j100.tip and d1.numar=#j100.numar
		left outer join JurnalDocumente jd on jd.idJurnal=#j100.idJurnal
		LEFT OUTER JOIN StariDocumente sd on jd.tip=sd.tipDocument and jd.stare=sd.stare
	order by d.data desc 

	IF EXISTS (
			SELECT 1
			FROM syscolumns sc, sysobjects so
			WHERE so.id = sc.id
				AND so.NAME = 'doc'
				AND sc.NAME = 'detalii'
			)
	BEGIN
		ALTER TABLE #doc ADD detalii XML
		update dd set detalii=d.detalii
		from #doc dd inner join doc d on dd.subunitate=d.subunitate and dd.tip=d.tip and dd.data=d.data and dd.numar=d.numar
	end

	if exists (select * from sysobjects where name ='wIaDocSP')
		exec wIaDocSP @sesiune=@sesiune, @parXML=@parXML

	select * from #doc order by convert(datetime,data) desc, numar desc for xml raw, root('Date')
	select 1 areDetaliiXml for xml raw, root('Mesaje')

	if object_id('tempdb..#doc') is not null drop table #doc
	if object_id('tempdb..#gest') is not null drop table #gest
	
	if object_id('tempdb..#docsp') is not null drop table #docsp
	if object_id('tempdb..#d100') is not null drop table #d100
	if object_id('tempdb..#j100') is not null drop table #j100

end try
begin catch
	set @mesaj =ERROR_MESSAGE()+' (wIaDoc)'
	raiserror(@mesaj,11,1)
end catch