/**	--	Procedura folosita la raportul CG\Financiar\Jurnal TVA la incasare

	--	Exemplu apel:
		declare @cFurnBenef varchar(1), @dataJos datetime, @dataSus datetime, @tert varchar(100), @factura varchar(100)
		select @cFurnBenef='B', @dataJos='2013-1-1', @dataSus='2013-1-31', @tert='10', @factura='1311Z'
		exec yso_rapJurnalTvaLaIncasare @cFurnBenef=@cFurnBenef, @dataJos=@dataJos, @dataSus=@dataSus, @tert=@tert, @factura=@factura
	
	Se recomanda inchiderea TLI inainte de extragerea acestui jurnal. Se bazeaza mult pe inregistrarile generate la TLI:
		--exec inchidTLI @dDataJos,@dDataSus
*/
--***
if exists (select 1 from sys.objects where name='yso_rapJurnalTvaLaIncasare')
	drop procedure yso_rapJurnalTvaLaIncasare
GO
--***
create procedure yso_rapJurnalTvaLaIncasare (@cFurnBenef varchar(1), @datajos datetime, @datasus datetime, @tert varchar(100)=null, @factura varchar(100)=null, @loc_de_munca varchar(100)=null,
			@cote_tva varchar(200)='' , @ordonare int=1,
			@dinInchidTLI int=0 --Parametru pentru faptul ca ar fi trimis din inchidere sau nu. Daca este trimis din inchidere va salva in tabela SoldFacturiTLI datele
			)
as
begin
set transaction isolation level read uncommitted
declare @eroare varchar(2000)
if object_id ('tempdb..##doctert') is not null drop table ##doctert
if object_id ('tempdb..##fTli') is not null drop table ##fTli
if object_id ('tempdb..#tCenInitBrut') is not null drop table #tCenInitBrut
if object_id ('tempdb..#tPlatit') is not null drop table #tPlatit
if object_id ('tempdb..##jurnalTLI') is not null drop table ##jurnalTLI
	
if @cote_tva is null
	set @cote_tva=''
begin try
	declare @GrTert int, @GrFact int, @cContFact char(13), @nSoldMin float, @nSemnSold int, @nStrictPerioada int, @locm varchar(20),@dDataInit datetime,
			@utilizator varchar(20), @filtrareUser bit
--	exec wIaUtilizator @sesiune='',@utilizator=@utilizator output
	
	select @GrTert=null, @GrFact=null, @cContFact=null, @nSoldMin=0, @nSemnSold=0,
		@loc_de_munca=(case when @loc_de_munca is null then @loc_de_munca else @loc_de_munca+'%' end),
		@filtrareUser=dbo.f_areLMFiltru(@utilizator)
	create table ##fTli(tert varchar(20),factura varchar(20),tip char(2),suma float,baza float)

	declare @cSub varchar(20),@CtTvaNeexPlati varchar(20),@CtTvaNeexIncasari varchar(20),@TLI int,@dataTLI datetime
	select @cSub=val_alfanumerica from par where Tip_parametru='GE' and Parametru='SUBPRO'
	select @CtTvaNeexPlati=Val_alfanumerica from par where Tip_parametru='GE' and Parametru='CNTLIFURN'
	select @CtTvaNeexIncasari=Val_alfanumerica from par where Tip_parametru='GE' and Parametru='CNTLIBEN'

	declare @tipDocPI char(2),@cont4428 varchar(20),@tipFact binary(1)
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
	/*-------------------------------------------
		Sold Initial
	*/-------------------------------------------
	--select @dDataInit,@cFurnBenef,@tert,@factura

	if exists(select 1 from SoldFacturiTLI where tipf=@cFurnBenef)--Inseamna ca iau soldul initial din tabela SoldFacturiTLI
	begin
		insert into ##fTli(tert,factura,tip,suma,baza)
		select tert,factura,'SI',sold,baza
		from SoldFacturiTLI 
		where datalunii=@dDataInit and tipf=@cFurnBenef	
			and (@tert is null or tert=@tert) and (@factura is null or factura=@factura)
	end
	else --Iau soldul initial din fTerti, lent si poate fi rau
	begin

		select data,tert,factura ,valoare+tva as valcutva,achitat,valoare,tva,(case when valoare<>0 then tva/valoare else 0 end) as prorata
		into #tCenInitBrut
		from dbo.fTertCen(@cFurnBenef, @dDataInit,@dDataInit, @tert, @factura, @GrTert, @GrFact, @cContFact, @nSoldMin, @nSemnSold) f
			left join lmfiltrare l on f.loc_de_munca=l.cod and l.utilizator=@utilizator
		where abs(sold)>0.001 --and data>='01/01/2013'
			and (@loc_de_munca is null or f.loc_de_munca like @loc_de_munca)
			and (@filtrareUser=0 or l.cod is not null)


		--declare @datajos datetime='01/01/2013'
		select p.tert,p.factura,sum(p.suma) as suma
		into #tPlatit
		from pozplin p
		inner join #tCenInitBrut t on p.subunitate=@cSub and p.tert=t.tert and p.factura=t.factura and p.plata_incasare=@tipDocPI
		where p.subunitate=@cSub and cont=@cont4428 and p.Data<=@dDataInit
		group by p.tert,p.factura


		insert into ##fTli
		select tf.tert,tf.factura,'SI',sum(tf.tva-isnull(tp.suma,0)) as S4428init,sum(tf.tva-(case when tf.prorata=0 then 0 else isnull(tp.suma,0)/tf.prorata end))  as S4428bazaInitial
		from #tCenInitBrut tf
		left outer join #tPlatit tp on tf.tert=tp.tert and tf.factura=tp.Factura
		group by tf.tert,tf.factura
	end

	select ft.data as data,tert,factura ,ft.valoare+ft.tva as valcutva,ft.valoare as valoare,ft.tva as tva,ft.achitat as achitat,ft.numar
	into ##doctert
	from fTert(@cFurnBenef,@datajos, @datasus, @tert,@factura,@cContFact,@nSoldMin,@nSemnSold,1,@loc_de_munca) ft
		left join lmfiltrare l on ft.loc_de_munca=l.cod and l.utilizator=@utilizator
	where (@filtrareUser=0 or l.cod is not null)
		and (@loc_de_munca is null or ft.loc_De_munca like @loc_de_munca)

	insert into ##fTli
	select f.tert,f.factura,'RD' as tip,sum(f.tva) as suma,sum(f.valoare) as baza
	from ##doctert f
	group by f.tert,f.factura
	having /*sum(f.valoare)<>0 or*/ sum(f.tva)<>0

	if @cFurnBenef='F'/*Doar la furnizori tratam TVA Nedeductibil pe care il scadem din DocTert pentru Rulaj Debit*/
	begin	
			update ##fTli 
			set suma=suma-pd.tvad
			from 
				(select p.tert,p.factura,sum(p.tva_deductibil) as tvad
				from pozdoc p
				where p.Subunitate=@cSub and p.tip in ('RM','RS','RP') and p.data between @datajos and @datasus and (p.Procent_vama>0 or p.Cont_factura like '408%')
				group by p.tert,p.factura) pd where ##fTli.tip='RD' and ##fTli.tert=pd.tert and ##fTli.factura=pd.Factura

			update ##fTli 
			set suma=suma-pd.tvad
			from 
				(select p.tert,p.factura_dreapta as factura,sum(p.tva22) as tvad
				from pozadoc p
				where p.Subunitate=@cSub and p.tip in ('FF') and p.data between @datajos and @datasus and (p.Stare>0 or p.Cont_cred like '408%')
				group by p.tert,p.factura_dreapta) pd where ##fTli.tip='RD' and ##fTli.tert=pd.tert and ##fTli.factura=pd.Factura
	end

	insert into ##fTli
	select tert,factura,'RC',sum(suma) as rulajc,0 as baza
	from pozplin p
		left join lmfiltrare l on p.loc_de_munca=l.cod and l.utilizator=@utilizator
	where Subunitate=@cSub and cont=@cont4428 and p.Plata_incasare=@tipDocPI 
		and data between @datajos and @datasus and (@tert is null or tert=@tert) and (@factura is null or factura=@factura)
		and (@loc_de_munca is null or p.loc_De_munca like @loc_de_munca)
		and (@filtrareUser=0 or l.cod is not null)
	group by tert,factura


	create table ##jurnalTLI(nrcrt int, Factura varchar(20),data datetime,denTert varchar(80),cod_fiscal varchar(20),Total_factura float,baza float,tva float,doc_incasare varchar(20),data_incasare datetime,
		suma_incasata decimal(12,2),sold_initial_tli decimal(12,2),rulaj_debit_tli decimal(12,2),rulaj_credit_tli decimal(12,2),baza_sold_tli decimal(12,2),sold_tli decimal(12,2),tert varchar(20))
	
	select f.tert,f.factura,isnull(tvatf.tip_tva,isnull(tvat.tip_tva,isnull(tvatb.tip_tva,'P'))) as tip_tva,
	row_number() over (partition by fct.data,f.tert,f.factura order by isnull(tvatf.dela,isnull(tvat.dela,isnull(tvatb.dela,'01/01/1901'))) desc) as ranc
	into #facturiOk
	from ##fTli f
	inner join facturi fct on f.tert=fct.tert and f.factura=fct.factura
	left outer join TvaPeTerti tvatb on tvatb.tipf='B' and tvatb.tert is null and fct.data>=tvatb.dela
	left outer join TvaPeTerti tvat on tvat.tipf=@cFurnBenef and tvat.tert=f.tert and isnull(tvat.factura,'')='' and fct.data>=tvat.dela
	left outer join TvaPeTerti tvatf on tvatf.tipf=@cFurnBenef and tvatf.Tert=f.tert and tvatf.factura=f.factura
	where fct.data>'2012-12-31'

	delete from #facturiOK where not (ranc=1 and tip_tva='I')

	insert into ##jurnalTLI(nrcrt,factura,data,denTert,cod_fiscal,total_factura,baza,tva,tert)
		select row_number() over (order by fct.data,f.tert,f.factura),f.factura,fct.Data,t.Denumire,t.Cod_fiscal,max(fct.valoare+fct.tva_11+fct.tva_22),max(fct.valoare),max(fct.tva_11+fct.tva_22),f.tert
		from facturi fct 
		inner join #facturiOk f on fct.tert=f.tert and fct.Factura=f.factura
		left outer join terti t on t.subunitate=@cSub and t.tert=f.tert
		where fct.tip=@tipFact 
		group by f.tert,f.factura,fct.data,t.denumire,t.cod_fiscal

	update ##jurnalTLI 
		set rulaj_debit_tli=f.rd, sold_initial_tli=f.si
	from 
		(select tert,factura,sum(case when tip='RD' then suma else 0 end) as rd,
			sum(case when tip='SI' then suma else 0 end) as si 
		from ##fTli group by tert,factura) f 
	where ##jurnalTLI.tert=f.tert and ##jurnalTLI.Factura=f.factura

	-- tratare achitari cu efecte, pentru citirea numarului de document de achitare
	insert ##doctert
	select p.data,p.tert,efInitiale.factura,0, 0, 0, p.suma as achitat, efInitiale.decont as numar
	from pozplin p 
	inner join conturi contpplin on contpplin.Subunitate=@cSub and contpplin.cont=p.Cont_corespondent and contpplin.sold_credit=8
	inner join 
		(select p1.Subunitate,p1.cont,p1.tert,isnull(ep1.decont,p1.numar) as decont,max(p1.Factura) as factura
		from pozplin p1 
		inner join conturi contpplin on contpplin.Subunitate=@cSub and contpplin.cont=p1.Cont and contpplin.sold_credit=8
		left outer join extpozplin ep1 on p1.Subunitate=ep1.Subunitate and p1.Cont=ep1.Cont and p1.Data=ep1.Data and p1.Numar_pozitie=ep1.Numar_pozitie
		group by p1.Subunitate,p1.cont,p1.tert,isnull(ep1.decont,p1.numar)) efInitiale
		on efInitiale.Subunitate=p.Subunitate and p.Tert=efInitiale.Tert and p.cont_corespondent=efInitiale.cont and p.numar=efInitiale.Decont
	where p.subunitate=@cSub and p.plata_incasare in ('PD','ID') and p.data between @datajos and @datasus
	-- end tratare efecte

	update ##jurnalTLI
	set doc_incasare=a.numar,data_incasare=a.data,rulaj_credit_tli=a.suma,suma_incasata=a.achitat
	from 
		(select f.tert,f.factura,max(isnull(d.numar,f.factura)) as numar,max(isnull(d.data,'1901-01-01')) as data,
				max(f.suma) as suma,sum(isnull(d.achitat,f.baza)) as achitat
			from ##fTli f
			left outer join ##doctert d on f.tert=d.tert and f.factura=d.factura and abs(d.achitat)>0.01
			where f.tip='RC' group by f.tert,f.factura) a where a.tert=##jurnalTLI.tert and a.factura=##jurnalTLI.Factura

	/*Stergem liniile cu valoare zero*/
	delete from ##jurnalTLI where abs(isnull(sold_initial_tli,0))<0.01 and abs(isnull(rulaj_debit_tli,0))<0.01 and abs(isnull(rulaj_credit_tli,0))<0.01

	/*Calculam soldul final*/
	update ##jurnalTLI
	set sold_tli=isnull(sold_initial_tli,0)+isnull(rulaj_debit_tli,0)-isnull(rulaj_credit_tli,0),
		baza_sold_tli=(isnull(sold_initial_tli,0)+isnull(rulaj_debit_tli,0)-isnull(rulaj_credit_tli,0))*
			(case when tva=0 then 0 else baza/tva end)
	where abs(isnull(sold_initial_tli,0)+isnull(rulaj_debit_tli,0)-isnull(rulaj_credit_tli,0))>0.01

	if @dinInchidTLI=1 /*Doar salvam datele in tabela*/
	begin
		delete from SoldFacturiTLI where datalunii=@dataSus and tipf=@cFurnBenef

		insert into SoldFacturiTLI(datalunii,tipf,tert,factura,sold,baza)
		select @dataSus,@cFurnBenef,tert,factura,sold_tli,baza_sold_tli
		from ##jurnalTLI 
		where abs(isnull(sold_tli,0))>0.01
		/*Aici mai urmeaza niste corectii pentru date necorelate*/
		--exec DepanareNecorelatiiTLI @dataJos,@dataSus
		
	end
	else --Pentru RAPORT
	begin
		--facturi din UA
		if exists (select * from sysobjects o where o.name='rapUAJurnalTvaLaIncasare' and o.type='P' ) and @cFurnBenef='B' 
			insert into ##jurnalTLI
			exec rapUAJurnalTvaLaIncasare @datajos=@datajos, @datasus=@datasus, @tert=@tert, @factura=@factura, @loc_de_munca=@loc_de_munca

		--select * into ##j2 from ##jurnalTLI where abs(isnull(sold_tli,0))>0.01  --Pentru Depanare pentru cunoscatori
		
		select nrcrt, isnull(Factura,'') factura,data, isnull(denTert,'') as denumireTert, isnull(cod_fiscal,'') codFiscal,
			isnull(Total_factura,0) totalFactura, isnull(baza,0) baza, isnull(tva,0) tva,
			isnull(doc_incasare,'') docIncasare, data_incasare dataDocInc, isnull(suma_incasata,0) sumaIncasata,
			isnull(sold_initial_tli,0) soldInitTLI,
			isnull(rulaj_debit_tli,0) rulajDebitTLI, isnull(rulaj_credit_tli,0) rulajCreditTLI, isnull(baza_sold_tli,0) bazaSoldTLI, isnull(sold_tli,0) soldTLI,
			(case when @ordonare=1 then convert(char(10),data,102) else denTert end) as ordonare,
			convert(decimal(3),(case when isnull(baza,0)=0 then 24 else isnull(tva,0)/isnull(baza,0)*100 end)) as cota_tva
		from ##jurnalTLI --where denTert like 'TLI%'
		where (@cote_tva='' 
			or convert(decimal(3),isnull(tva,0)/(case when isnull(baza,0)=0 then 1 else baza end)*100) in (select string from dbo.fSplit(@cote_tva,',')))
			and baza_sold_tli<0
		order by ordonare
	end
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (yso_rapJurnalTvaLaIncasare '+convert(varchar(20),ERROR_LINE())+')'
end catch
	
	--if object_id ('tempdb..##doctert') is not null drop table ##doctert
	--if object_id ('tempdb..##fTli') is not null drop table ##fTli
	if object_id ('tempdb..#tCenInitBrut') is not null drop table #tCenInitBrut
	if object_id ('tempdb..#tPlatit') is not null drop table #tPlatit
	--if object_id ('tempdb..##jurnalTLI') is not null drop table ##jurnalTLI
	if object_id ('tempdb..#facturiOk') is not null drop table #facturiOk
	
if len(@eroare)>0 raiserror(@eroare, 16,1)
end