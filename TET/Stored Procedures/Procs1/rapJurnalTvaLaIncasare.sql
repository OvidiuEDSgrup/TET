--***
create procedure rapJurnalTvaLaIncasare (@cFurnBenef varchar(1), @datajos datetime, @datasus datetime, @tert varchar(100)=null, @factura varchar(100)=null, @loc_de_munca varchar(100)=null,
			@cote_tva varchar(200)='' , @ordonare int=1,
			@dinInchidTLI int=0 --Parametru pentru faptul ca ar fi trimis din inchidere sau nu. Daca este trimis din inchidere va salva in tabela SoldFacturiTLI datele
			)
as
set transaction isolation level read uncommitted
declare @eroare varchar(2000)
if object_id ('tempdb..#docTert') is not null drop table #docTert
if object_id ('tempdb..#fTLI') is not null drop table #fTLI
if object_id ('tempdb..#facturi_cu_TLI') is not null drop table #facturi_cu_TLI
if object_id ('tempdb..#tCenInitBrut') is not null drop table #tCenInitBrut
if object_id ('tempdb..#tPlatit') is not null drop table #tPlatit
if object_id ('tempdb..#jurnalTLI') is not null drop table #jurnalTLI
	
if @cote_tva is null
	set @cote_tva=''
begin try
	declare @GrTert int, @GrFact int, @cContFact varchar(40), @nSoldMin float, @nSemnSold int, @nStrictPerioada int, @locm varchar(20),@dDataInit datetime,
			@utilizator varchar(20), @filtrareUser bit, @parXMLFact xml
	exec wIaUtilizator @sesiune='',@utilizator=@utilizator output
	
	select @GrTert=null, @GrFact=null, @cContFact=null, @nSoldMin=0, @nSemnSold=0,
		@loc_de_munca=(case when @loc_de_munca is null then @loc_de_munca else @loc_de_munca+'%' end),
		@filtrareUser=dbo.f_areLMFiltru(@utilizator)

	declare @cSub varchar(20),@CtTvaNeexPlati varchar(40),@CtTvaNeexIncasari varchar(40),@TLI int,@dataTLI datetime
	select @cSub=val_alfanumerica from par where Tip_parametru='GE' and Parametru='SUBPRO'
	select @CtTvaNeexPlati=Val_alfanumerica from par where Tip_parametru='GE' and Parametru='CNTLIFURN'
	select @CtTvaNeexIncasari=Val_alfanumerica from par where Tip_parametru='GE' and Parametru='CNTLIBEN'
	
	declare @dDImpl datetime, @nAnImpl int, @nLunaImpl int
	select 
	@nAnImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULIMPL'),0),
	@nLunaImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAIMPL'),0),
	@dDImpl=dateadd(day,-1,dateadd(month,@nLunaImpl,dateadd(year,@nAnImpl-1901,'01/01/1901')))

	declare @tipDocPI char(2),@cont4428 varchar(40),@tipFact binary(1)
	if @cFurnBenef='F'
		begin
			set @tipDocPI='PC'
			set @cont4428=@CtTvaNeexPlati
			set @tipFact=0x54
		end
	else
		begin
			set @tipDocPI='IC'
			set @cont4428=@CtTvaNeexIncasari
			set @tipFact=0x46
		end

	set @dDataInit=DATEADD(day,-1,@datajos)

	create table #fTLI(tert varchar(20),factura varchar(20),tip char(2),suma float,baza float,TVA float)
	/*-------------------------------------------
		Sold Initial
	*/-------------------------------------------
	if not exists(select 1 from SoldFacturiTLI where tipf=@cFurnBenef and datalunii=@dDataInit) and @dDataInit=@dDImpl 
	begin
		/*
			Pe aceasta ramura vor intra doar datele de la implementare citite cu fFacturiCen.
			In caz contrar (pe cealalta ramura) datele initiale vor fi luate din tabela SoldFacturiTLI
			Se preiau datele in tabela #pfacturi prin procedura pFacturi, in locul functiei fFacturiCen
		*/
		if object_id('tempdb..#pfacturi') is not null 
			drop table #pfacturi
		create table #pfacturi (subunitate varchar(9))
		exec CreazaDiezFacturi @numeTabela='#pfacturi'
		set @parXMLFact=(select @cFurnBenef as furnbenef, @dDataInit as datajos, @dDataInit as datasus, 1 as cen, 
			rtrim(@tert) as tert, rtrim(@factura) as factura, rtrim(@cContFact) as contfactura, @nSoldMin as soldmin, @nSemnSold as semnsold, @loc_de_munca as locm for xml raw)
		exec pFacturi @sesiune=null, @parXML=@parXMLFact

		insert into #fTLI
		select f.tert,f.factura,'SI',sum(f.sold*f.tva/(f.valoare+f.tva)) as S4428init,sum(f.sold*f.valoare/(f.valoare+f.tva))  as S4428bazaInitial, sum(f.sold*f.tva/(f.valoare+f.tva)) as S4428TVAinit
		from #pfacturi f
		--from dbo.fFacturiCen(@cFurnBenef, @dDataInit, @dDataInit, @tert, @factura, @GrTert, @GrFact, @cContFact, @nSoldMin, @nSemnSold, null) f
		where abs(sold)>0.001 --and data>='01/01/2013'
			and (@cFurnBenef='F' or @datasus>='01/01/2014' or data>dateadd(d,-90,@dDImpl))
			and f.valoare+f.tva<>0
		group by f.tert,f.factura
	end
	else --Inseamna ca iau soldul initial din tabela SoldFacturiTLI
	begin
		insert into #fTLI(tert,factura,tip,suma,baza,TVA)
		select tert,factura,'SI',sold,baza,sold
		from SoldFacturiTLI 
		where datalunii=@dDataInit and tipf=@cFurnBenef	
			and (@tert is null or tert=@tert) 
			and (@factura is null or factura=@factura)
	end

	/* se preiau datele in tabela #docfacturi prin procedura pFacturi (in locul functiei fFacturi) */
	if object_id('tempdb..#docfacturi') is not null 
		drop table #docfacturi
	create table #docfacturi (furn_benef char(1))
	exec CreazaDiezFacturi @numeTabela='#docfacturi'
	set @parXMLFact=(select @cFurnBenef as furnbenef, @datajos as datajos, @datasus as datasus, rtrim(@tert) as tert, rtrim(@factura) as factura, rtrim(@cContFact) as contfactura, 
		@nSoldMin as soldmin, @nSemnSold as semnsold, 1 as strictperioada, @loc_de_munca as locm for xml raw)
	exec pFacturi @sesiune=null, @parXML=@parXMLFact

	select ft.data as data,tert, ltrim(factura) as factura, ft.valoare+ft.tva as valcutva,ft.valoare as baza,ft.tva as tva,ft.achitat as achitat,ft.numar
	into #docTert
	from #docfacturi ft
	--from fFacturi(@cFurnBenef,@datajos,@datasus, @tert,@factura,@cContFact,@nSoldMin,@nSemnSold,1,null, null) ft
	where ft.cont_coresp not in (select cont from conturi where Sold_credit=8)

	insert into #fTLI
	select f.tert,f.factura,'RD' as tip,sum(f.tva) as suma,sum(f.baza) as baza,sum(f.tva) as TVA
	from #doctert f
	group by f.tert,f.factura
	having /*sum(f.valoare)<>0 or*/ sum(f.tva)<>0

	if @cFurnBenef='F'/*Doar la furnizori tratam TVA Nedeductibil pe care il scadem din DocTert pentru Rulaj Debit*/
	begin	
			update #fTLI 
			set suma=suma-pd.tvad, baza=baza-pd.bazad, tva=tva-pd.tvad
			from 
				(select p.tert,p.factura,sum(case when p.Procent_vama<>1 then p.tva_deductibil else 0 end) as tvad,sum(round(p.cantitate*round(p.pret_valuta*(case when valuta='' or p.tip='RP' then 1 else p.curs end)*(1+p.discount/100),5),2)) as bazad
				from pozdoc p 
				left join lmfiltrare l on p.loc_de_munca=l.cod and l.utilizator=@utilizator
				where p.Subunitate=@cSub and p.tip in ('RM','RS','RP') and p.data between @datajos and @datasus and (p.cota_tva=0 or p.Procent_vama>0 or p.Cont_factura like '408%')
					and (@loc_de_munca is null or p.loc_de_munca like rtrim(@loc_de_munca)+'%')
					and (@filtrareUser=0 or l.cod is not null)
				group by p.tert,p.factura) pd 
			where #fTLI.tip='RD' and #fTLI.tert=pd.tert and #fTLI.factura=pd.Factura

			update #fTLI 
			set suma=suma-pd.tvad, baza=baza-pd.bazad, tva=tva-pd.tvad
			from 
				(select p.tert,p.factura_dreapta as factura,sum(p.tva22) as tvad,sum(p.suma) as bazad
				from pozadoc p 
				left join lmfiltrare l on p.loc_munca=l.cod and l.utilizator=@utilizator
				where p.Subunitate=@cSub and p.tip in ('FF','SF') and p.data between @datajos and @datasus and (p.stare>0 or p.tva11=0 or p.Cont_cred like '408%')
					and (@loc_de_munca is null or p.loc_munca like rtrim(@loc_de_munca)+'%')
					and (@filtrareUser=0 or l.cod is not null)
				group by p.tert,p.factura_dreapta) pd 
			where #fTLI.tip='RD' and #fTLI.tert=pd.tert and #fTLI.factura=pd.Factura
	end
	
	insert into #fTLI
	select tert,ltrim(factura),'RC',sum(suma) as rulajc,0 as baza, 0 as tva 
	from pozplin p
	left join lmfiltrare l on p.loc_de_munca=l.cod and l.utilizator=@utilizator
	where Subunitate=@cSub and cont=@cont4428 and p.Plata_incasare=@tipDocPI 
		and data between @datajos and @datasus 
		and (@tert is null or tert=@tert) 
		and (@factura is null or factura=@factura)
		and (@loc_de_munca is null or p.loc_de_munca like rtrim(@loc_de_munca)+'%')
		and (@filtrareUser=0 or l.cod is not null)
	group by tert,ltrim(factura)

	create table #jurnalTLI(Factura varchar(20),data datetime,denTert varchar(80),cod_fiscal varchar(20),baza float,TVA float,doc_incasare varchar(20),data_incasare datetime,
		suma_incasata decimal(12,2),sold_initial_tli decimal(12,2),rulaj_debit_tli decimal(12,2),rulaj_credit_tli decimal(12,2),baza_sold_tli decimal(12,2),sold_tli decimal(12,2),tert varchar(20))

	--Lucian: utilizam procedura tipTVAFacturi (in locul selectului de mai sus) care stabileste tipul de TVA al facturii
	select '' as tip,@cFurnBenef as tipf,f.tert,f.factura,convert(datetime,null) as data, convert(varchar(40),null) as cont,'' as tip_tva, baza, TVA 
	into #facturi_cu_TLI
	from #fTLI f
	exec tipTVAFacturi @dataJos=@dataJos, @dataSus=@dataSus, @TLI=@TLI

	delete from #facturi_cu_TLI where not (tip_tva='I')

	insert into #jurnalTLI(factura,data,denTert,cod_fiscal,baza,TVA,tert)
		select f.factura,f.Data,t.Denumire,t.Cod_fiscal,sum(f.baza), sum(f.TVA), 
		--max(fct.valoare),max(fct.tva_11+fct.tva_22),
		f.tert
		from #facturi_cu_TLI f 
		left outer join terti t on t.subunitate=@cSub and t.tert=f.tert
		where f.tipf=@cFurnBenef
		group by f.tert,f.factura,f.data,t.denumire,t.cod_fiscal

	update #jurnalTLI 
		set rulaj_debit_tli=f.rd, sold_initial_tli=f.si
	from 
		(select tert,factura,sum(case when tip='RD' then suma else 0 end) as rd,
			sum(case when tip='SI' then suma else 0 end) as si 
		from #fTLI group by tert,factura) f 
	where #jurnalTLI.tert=f.tert and #jurnalTLI.Factura=f.factura

	-- tratare achitari cu efecte, pentru citirea numarului de document de achitare
	select p.plata_incasare as tip, p.data, 
			p.Cont_corespondent as Cont, (case when p.plata_incasare='ID' then 'B' else 'F' end) as tipf, 
			p.tert, isnull(p.efect,p.numar) as Efect, p.Suma 
		into #efAchitateJ
		from pozplin p 
		inner join conturi contpplin on contpplin.Subunitate=@cSub and contpplin.cont=p.Cont_corespondent and contpplin.sold_credit=8
		left join lmfiltrare l on p.loc_de_munca=l.cod and l.utilizator=@utilizator
		where p.subunitate=@cSub and p.plata_incasare in ('PD','ID') and p.data between @datajos and @datasus
			and (@loc_de_munca is null or p.loc_de_munca like rtrim(@loc_de_munca)+'%')
			and (@filtrareUser=0 or l.cod is not null)
	--	comentat intrucat tipul de tva se stabileste la nivel de factura (mai ales in cazurile in care se modifica tipul de TVA in cursul lunii). In aceasta procedura nici nu se citea @TLI la inceput.
			--and not (@TLI=0 and p.plata_incasare='ID') 

	select p1.Subunitate,p1.cont,p1.tert,p1.Factura,isnull(p1.efect,p1.numar) as Efect, sum(p1.suma) suma
	into #efInitialeJ
	from pozplin p1 
	inner join conturi contpplin on contpplin.Subunitate=@cSub and contpplin.cont=p1.Cont and contpplin.sold_credit=8
	inner join #efAchitateJ a on p1.Tert=a.Tert and p1.cont=a.cont and isnull(p1.efect,p1.numar)=a.Efect -- filtrare doar cele atinse in perioada curenta 
	left join lmfiltrare l on p1.loc_de_munca=l.cod and l.utilizator=@utilizator
	where p1.subunitate=@cSub and p1.plata_incasare in ('PF','IB') 
		and (@loc_de_munca is null or p1.loc_de_munca like rtrim(@loc_de_munca)+'%')
		and (@filtrareUser=0 or l.cod is not null)
	group by p1.Subunitate,p1.cont,p1.tert,p1.Factura,isnull(p1.efect,p1.numar)
	
	insert #docTert
	select p.data,p.tert,ei.factura,0, 0, 0, ei.suma*(p.suma/eis.suma) as achitat, ei.Efect as numar
	from #efAchitateJ p 
		inner join #efInitialeJ ei on p.Tert=ei.Tert and p.cont=ei.cont and p.Efect=ei.Efect
		inner join 
			(select Subunitate,cont,tert,efect, sum(suma) suma
			from #efInitialeJ 
			group by Subunitate,cont,tert,efect) eis
			on p.Tert=eis.Tert and p.cont=eis.cont and p.Efect=eis.Efect and abs(eis.suma)>=0.01
		inner join #facturi_cu_TLI f on f.tipf=p.tipf and f.tert=p.tert and f.factura=ei.factura
		where (p.tip='PD' or @datasus>='01/01/2014' or datediff(day,f.data,p.data)<=90)	
	-- end tratare efecte 

	update #jurnalTLI
	set doc_incasare=a.numar,data_incasare=a.data,rulaj_credit_tli=a.suma,suma_incasata=a.achitat
	from 
		(select f.tert,f.factura,max(isnull(d.numar,f.factura)) as numar,max(isnull(d.data,'1901-01-01')) as data,
				max(f.suma) as suma,sum(isnull(d.achitat,f.baza)) as achitat
			from #fTli f
			left outer join #doctert d on f.tert=d.tert and f.factura=d.factura and abs(d.achitat)>0.01
			where f.tip='RC' group by f.tert,f.factura) a where a.tert=#jurnalTLI.tert and a.factura=#jurnalTLI.Factura

	/*Stergem liniile cu valoare zero*/
	delete from #jurnalTLI where abs(isnull(sold_initial_tli,0))<0.01 and abs(isnull(rulaj_debit_tli,0))<0.01 and abs(isnull(rulaj_credit_tli,0))<0.01
	/*Stergem liniile de avize fara factura*/
	-- se stabileste in tipTVAFacturi tiptva=P pt. facturile cu cont 408,418 si aceste facturi se sterg mai sus
	/*	delete j from #jurnalTLI j, facturi f
	where f.tip=(case when @cFurnBenef='F' then 0x54 else 0x46 end) and j.tert=f.tert and j.factura=f.Factura and left(f.Cont_de_tert,3) in ('408','418')*/

	/*Calculam soldul final*/
	update #jurnalTLI
	set sold_tli=isnull(sold_initial_tli,0)+isnull(rulaj_debit_tli,0)-isnull(rulaj_credit_tli,0),
		baza_sold_tli=(isnull(sold_initial_tli,0)+isnull(rulaj_debit_tli,0)-isnull(rulaj_credit_tli,0))*
			(case when tva=0 then 0 else baza/tva end)
	where abs(isnull(sold_initial_tli,0)+isnull(rulaj_debit_tli,0)-isnull(rulaj_credit_tli,0))>0.01

	if @dinInchidTLI=1 /*Doar salvam datele in tabela*/
	begin
		delete from SoldFacturiTLI where datalunii=@dataSus and tipf=@cFurnBenef

		insert into SoldFacturiTLI(datalunii,tipf,tert,factura,sold,baza)
		select @dataSus,@cFurnBenef,tert,factura,sold_tli,baza_sold_tli
		from #jurnalTLI 
		where abs(isnull(sold_tli,0))>0.01
		/*Aici mai urmeaza niste corectii pentru date necorelate*/
		--exec DepanareNecorelatiiTLI @dataJos,@dataSus
		
	end
	else --Pentru RAPORT
	begin
		--facturi din UA
		if exists (select * from sysobjects o where o.name='rapUAJurnalTvaLaIncasare' and o.type='P') and @cFurnBenef='B' 
	--		insert into #jurnalTLI
				exec rapUAJurnalTvaLaIncasare @datajos=@datajos, @datasus=@datasus, @tert=@tert, @factura=@factura, @loc_de_munca=null

		--select * into ##j2 from #jurnalTLI where abs(isnull(sold_tli,0))>0.01  --Pentru Depanare pentru cunoscatori

		select row_number() over (order by (case when @ordonare=1 then convert(char(10),j.data,102) else denTert end)), 
			isnull(j.Factura,'') factura, j.data, isnull(denTert,'') as denumireTert, isnull(cod_fiscal,'') codFiscal,
			(case when isnull(f.valuta,'')<>'' then isnull(baza,0)+isnull(tva,0) else isnull(f.valoare+f.tva_11+f.tva_22,0) end) totalFactura, isnull(baza,0) baza, isnull(tva,0) tva,
			(case when data_incasare='1901-01-01' then 'Inch.90 zile' else doc_incasare end) docIncasare, 
			(case when data_incasare='1901-01-01' then null else data_incasare end) dataDocInc, isnull(suma_incasata,0) sumaIncasata,
			isnull(sold_initial_tli,0) soldInitTLI,
			isnull(rulaj_debit_tli,0) rulajDebitTLI, isnull(rulaj_credit_tli,0) rulajCreditTLI, isnull(baza_sold_tli,0) bazaSoldTLI, isnull(sold_tli,0) soldTLI,
			(case when @ordonare=1 then convert(char(10),j.data,102) else denTert end) as ordonare,
			convert(decimal(12,3),(case when baza is null or abs(baza)<0.009 or abs(isnull(tva,0)/baza*100-24)<0.05 then 24 
				when abs(isnull(tva,0)/baza*100-9)<0.05 then 9 else isnull(tva,0)/baza*100 end)) as cota_tva
		from #jurnalTLI j --where denTert like 'TLI%'
			left outer join facturi f on f.Subunitate=@cSub and f.Tip=@tipFact and f.tert=j.tert and f.factura=j.factura
			left join lmfiltrare l on f.loc_de_munca=l.cod and l.utilizator=@utilizator
		where (@loc_de_munca is null or f.loc_de_munca like @loc_de_munca)
			and (@filtrareUser=0 or l.cod is not null)
			and (@cote_tva='' 
				or convert(decimal(12,3),isnull(tva,0)/(case when baza is null or abs(baza)<0.009 then 1 else baza end)*100) in (select string from dbo.fSplit(@cote_tva,',')))
		order by ordonare
	end
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (rapJurnalTvaLaIncasare '+convert(varchar(20),ERROR_LINE())+')'
end catch
	
if object_id ('tempdb..#docTert') is not null drop table #docTert
if object_id ('tempdb..#fTLI') is not null drop table #fTLI
if object_id ('tempdb..#tCenInitBrut') is not null drop table #tCenInitBrut
if object_id ('tempdb..#tPlatit') is not null drop table #tPlatit
if object_id ('tempdb..#jurnalTLI') is not null drop table #jurnalTLI
if object_id ('tempdb..#facturi_cu_TLI') is not null drop table #facturi_cu_TLI
if object_id ('tempdb..#efInitialeJ') is not null drop table #efInitialeJ
if object_id ('tempdb..#efAchitateJ') is not null drop table #efAchitateJ

if len(@eroare)>0 raiserror(@eroare, 16,1)
