--***
create procedure Declaratia300Cump (@parXML xml='<row />')
as
begin try
	declare @sub char(9), @datajos datetime, @datasus datetime, 
			@FFTVA0 varchar(1),	--> Facturi operate pe FF:	0=nu apar fara tva, 1=cu cota<>0, 2=apar fara tva
			@SFTVA0 varchar(1),	--> Facturi operate pe SF:	0=nu apar fara tva, 1=cu cota<>0, 2=apar fara tva
			@IAFTVA0 int,			--> Apar si IAF fara TVA
			@CtNeimpoz char(200),	--> conturi coresp. pentru neimpozabile
			@nTVAned int

	set @sub=dbo.iauParA('GE','SUBPRO')
	select	@datajos=@parXML.value('(row/@datajos)[1]','datetime'),	--> interval
			@datasus=@parXML.value('(row/@datasus)[1]','datetime'),
			@FFTVA0=isnull(@parXML.value('(row/@FFTVA0)[1]','varchar(1)'),'2'),
			@SFTVA0=isnull(@parXML.value('(row/@SFTVA0)[1]','varchar(1)'),'2'),
			@IAFTVA0=@parXML.value('(row/@IAFTVA0)[1]','int'),
			@CtNeimpoz=@parXML.value('(row/@CtNeimpoz)[1]','varchar(200)'),
			@nTVAned=isnull(@parXML.value('(row/@tvaned)[1]','int'),0)

--	creare tabela temporara ce va prelucra rezultatul adus din jurnalul de cumparari si care va putea fi modificata printr-o procedura specifica.
	if object_id('tempdb..#decontcump') is not null drop table #decontcump
	create table #decontcump
		(numar char(20), data datetime, cod_tert char(13), furnizor varchar(80), codfisc varchar(20)
		,total float, baza_19 float, tva_19 float, baza_9 float, tva_9 float, baza_5 float, tva_5 float, baza_19_9_reg float, tva_19_9_reg float, scutite float
		,baza_intra float, tva_intra float, baza_intra_reg float, tva_intra_reg float
		,baza_intra_serv float, tva_intra_serv float, baza_intra_serv_reg float, tva_intra_serv_reg float
		,scutite_intra float, scutite_intra_serv float, neimpoz_intra float
		,baza_oblig_1 float, tva_oblig_1 float, baza_oblig_1_serv float, tva_oblig_1_serv float, baza_oblig_2 float, tva_oblig_2 float 
		,explicatii char(50), cont_tva varchar(40), detal_doc int, care_jurnal int, tip_doc char(2), nr_doc char(10), data_doc datetime
		,valoare_doc float, cota_tva_doc int, suma_tva_doc float)

--	cumparari: inlocuit apelul procedurii Declaratia300Cumpdet cu continutul ei
--	exec Declaratia300Cumpdet @parXML
	if object_id('tempdb..#jtvacump') is not null drop table #jtvacump
	create table #jtvacump (numar char(20))
	exec CreazaDiezTVA '#jtvacump'
	
	declare @parXMLJ xml
	set @parXMLJ=(select 1 tipcump, '' tipfact, 0 tvanx, @IAFTVA0 IAFTVA0, 0 tvaeronat, @CtNeimpoz CtNeimpoz for xml raw)
--	populare tabela #jtvacump prin apelul procedurii rapJurnalTVACumparari 
	exec rapJurnalTVACumparari 
		@sesiune=null, @DataJ=@datajos, @DataS=@datasus
		,@nTVAex=0, @FFFBTVA0=@FFTVA0, @SFTVA0=@SFTVA0, @OrdDataDoc=0, @Provenienta='', @DifIgnor=0.5
		,@UnifFact=0, @nTVAneded=@nTVAned, @cotatvaptfiltr=null
		,@ContF=null, @LM =null, @ContCor=null, @Tert=null, @Factura=null
		,@marcaj=0, @DVITertExt=0, @RPTVACompPeRM=0, @Gest=null, @LMExcep=0, @Jurnal=null, @RecalcBaza=0
		,@TVAAlteCont=0, @OrdDenTert=0, @DetalDoc=0, @TipTvaTert=0, @parXML=@parXMLJ

	insert into #decontcump
		(numar, data, cod_tert, furnizor, codfisc, total, baza_19, tva_19, baza_9, tva_9, baza_5, tva_5, baza_19_9_reg, tva_19_9_reg, scutite, 
			baza_intra, tva_intra, baza_intra_reg, tva_intra_reg, baza_intra_serv, tva_intra_serv, baza_intra_serv_reg, tva_intra_serv_reg, 
			scutite_intra, scutite_intra_serv, neimpoz_intra, baza_oblig_1, tva_oblig_1, baza_oblig_1_serv, tva_oblig_1_serv, baza_oblig_2, tva_oblig_2, 
			explicatii, cont_tva, detal_doc, care_jurnal, tip_doc, nr_doc, data_doc, valoare_doc, cota_tva_doc, suma_tva_doc)
	select numar, data, cod_tert, furnizor, codfisc, convert(decimal(15,3),d.total) as total, 
		(case when d.tip_doc='PI' or d.data between @datajos and @datasus then convert(decimal(15,3),d.baza_19) else 0.000 end) as baza_19, 
		(case when d.tip_doc='PI' or d.data between @datajos and @datasus then convert(decimal(15,3),d.tva_19) else 0.000 end) as tva_19,
		(case when d.tip_doc='PI' or d.data between @datajos and @datasus then convert(decimal(15,3),d.baza_9) else 0.000 end) as baza_9, 
		(case when d.tip_doc='PI' or d.data between @datajos and @datasus then convert(decimal(15,3),d.tva_9) else 0.000 end) as tva_9,
		(case when cota_tva_doc=5 then convert(decimal(15,3),d.baza_19) else 0 end) as baza_5, (case when cota_tva_doc=5 then convert(decimal(15,3),d.tva_9) else 0 end) as tva_5,
		(case when d.data<@datajos and d.tip_doc!='PI' then convert(decimal(15,3),d.baza_19) + convert(decimal(15,3),d.baza_9) else 0.000 end) as baza_19_9_reg, 
		(case when d.data<@datajos and d.tip_doc!='PI' then convert(decimal(15,3),d.tva_19) + convert(decimal(15,3),d.tva_9) else 0.000 end) as tva_19_9_reg,
		convert(decimal(15,3),d.scutite) scutite, 
		(case when d.data between @datajos and @datasus then convert(decimal(15,3),d.baza_intra) else 0.000 end) baza_intra, 
		(case when d.data between @datajos and @datasus then convert(decimal(15,3),d.tva_intra) else 0.000 end) tva_intra, 
		(case when d.data<@datajos then convert(decimal(15,3),d.baza_intra) else 0.000 end) baza_intra_reg, 
		(case when d.data<@datajos then convert(decimal(15,3),d.tva_intra) else 0.000 end) tva_intra_reg, 
		(case when d.data between @datajos and @datasus then convert(decimal(15,3),d.baza_intra_serv) else 0.000 end) baza_intra_serv, 
		(case when d.data between @datajos and @datasus then convert(decimal(15,3),d.tva_intra_serv) else 0.000 end) tva_intra_serv, 
		(case when d.data<@datajos then convert(decimal(15,3),d.baza_intra_serv) else 0.000 end) as baza_intra_serv_reg, 
		(case when d.data<@datajos then convert(decimal(15,3),d.tva_intra_serv) else 0.000 end) as tva_intra_serv_reg,
		convert(decimal(15,3),d.scutite_intra) scutite_intra, convert(decimal(15,3),d.scutite_intra_serv) scutite_intra_serv, convert(decimal(15,3),d.neimpoz_intra) neimpoz_intra, 
		convert(decimal(15,3),d.baza_oblig_1) as baza_oblig_1, convert(decimal(15,3),d.tva_oblig_1) as tva_oblig_1,
		convert(decimal(15,3),d.baza_oblig_1_serv) as baza_oblig_1_serv, convert(decimal(15,3),d.tva_oblig_1_serv) as tva_oblig_1_serv,
		convert(decimal(15,3),d.baza_oblig_2) as baza_oblig_2, convert(decimal(15,3),d.tva_oblig_2) as tva_oblig_2,
		explicatii, cont_tva, detal_doc, care_jurnal, tip_doc, nr_doc, data_doc, 
		convert(decimal(15,3),d.valoare_doc) as valoare_doc, cota_tva_doc, convert(decimal(15,3),d.suma_tva_doc) as suma_tva_doc
	from #jtvacump d
	where (baza_19<>0 or tva_19<>0 or baza_9<>0 or tva_9<>0 or scutite<>0
			or baza_intra<>0 or tva_intra<>0 or scutite_intra<>0 or neimpoz_intra<>0
			or baza_oblig_1<>0 or tva_oblig_1<>0 or baza_oblig_2<>0 or tva_oblig_2<>0)

--	apelul procedurii specifice care permite modificarea continutului tabelei #decontcump
	if exists (select 1 from sysobjects where name='Declaratia300CumpSP')
		exec Declaratia300CumpSP @parXML

	insert into #dectvacump (total, baza_19, tva_19, baza_9, tva_9, baza_5, tva_5, baza_19_9_reg, tva_19_9_reg, scutite, baza_intra, tva_intra, baza_intra_reg, tva_intra_reg, 
			baza_intra_serv, tva_intra_serv, baza_intra_serv_reg, tva_intra_serv_reg, 
			scutite_intra, scutite_intra_serv, neimpoz_intra, baza_oblig_1,tva_oblig_1, baza_oblig_1_serv, tva_oblig_1_serv, 
			baza_oblig_2, tva_oblig_2, valoare_doc, suma_tva_doc)
	select isnull(convert(decimal(15),sum(total)),0) as total, 
		isnull(convert(decimal(15),sum(baza_19)),0) as baza_19, isnull(convert(decimal(15),sum(tva_19)),0) as tva_19,
		isnull(convert(decimal(15),sum(baza_9)),0) as baza_9, isnull(convert(decimal(15),sum(tva_9)),0) as tva_9,
		isnull(convert(decimal(15),sum(baza_5)),0) as baza_5, isnull(convert(decimal(15),sum(tva_5)),0) as tva_5,
		isnull(convert(decimal(15),sum(baza_19_9_reg)),0) as baza_19_9_reg, isnull(convert(decimal(15),sum(tva_19_9_reg)),0) as tva_19_9_reg,
		isnull(convert(decimal(15),sum(scutite)),0) scutite, 
		isnull(convert(decimal(15),sum(baza_intra)),0) baza_intra, isnull(convert(decimal(15),sum(tva_intra)),0) tva_intra, 
		isnull(convert(decimal(15),sum(baza_intra_reg)),0) baza_intra_reg, isnull(convert(decimal(15),sum(tva_intra_reg)),0) tva_intra_reg, 
		isnull(convert(decimal(15),sum(baza_intra_serv)),0) baza_intra_serv, isnull(convert(decimal(15),sum(tva_intra_serv)),0) tva_intra_serv,
		isnull(convert(decimal(15),sum(baza_intra_serv_reg)),0) baza_intra_serv_reg, isnull(convert(decimal(15),sum(tva_intra_serv_reg)),0) tva_intra_serv_reg,
		isnull(convert(decimal(15),sum(scutite_intra)),0) scutite_intra, isnull(convert(decimal(15),sum(scutite_intra_serv)),0) scutite_intra_serv, 
		isnull(convert(decimal(15),sum(neimpoz_intra)),0) neimpoz_intra, 
		isnull(convert(decimal(15),sum(baza_oblig_1)),0) as baza_oblig_1, isnull(convert(decimal(15),sum(tva_oblig_1)),0) as tva_oblig_1,
		isnull(convert(decimal(15),sum(baza_oblig_1_serv)),0) as baza_oblig_1_serv, isnull(convert(decimal(15),sum(tva_oblig_1_serv)),0) as tva_oblig_1_serv,
		isnull(convert(decimal(15),sum(baza_oblig_2)),0) as baza_oblig_2, isnull(convert(decimal(15),sum(tva_oblig_2)),0) as tva_oblig_2,
		isnull(convert(decimal(15),sum(valoare_doc)),0) as valoare_doc, isnull(convert(decimal(15),sum(suma_tva_doc)),0) as suma_tva_doc
	from #decontcump

	if object_id('tempdb..#decontcump') is not null drop table #decontcump
	if object_id('tempdb..#jtvacump') is not null drop table #jtvacump
end try

begin catch
	declare @eroare varchar(8000)
	set @eroare=ERROR_MESSAGE() + ' ('+object_name(@@procid)+', linia '+convert(varchar(20),ERROR_LINE())+')'
	raiserror(@eroare, 16, 1)
end catch
