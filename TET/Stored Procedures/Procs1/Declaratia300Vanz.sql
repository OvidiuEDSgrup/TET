--***
create procedure Declaratia300Vanz (@parXML xml='<row />')
as
begin
	declare @sub char(9), @datajos datetime, @datasus datetime, 
			@FBTVA0 varchar(1),	--> Facturi operate pe FF:	0=nu apar fara tva, 1=cu cota<>0, 2=apar fara tva
			@CtPIScDed char(200),	--> conturi antet PI pt. scutire cu drept de deducere
			@CtVenScDed char(200),	--> conturi venituri pt. scutire cu drept de deducere
			@CtNeimpoz char(200)	--> conturi coresp. pentru neimpozabile

	set @sub=dbo.iauParA('GE','SUBPRO')
	select	@datajos=@parXML.value('(row/@datajos)[1]','datetime'),	--> interval
			@datasus=@parXML.value('(row/@datasus)[1]','datetime'),
			@FBTVA0=isnull(@parXML.value('(row/@FBTVA0)[1]','varchar(1)'),'2'),
			@CtPIScDed=@parXML.value('(row/@CtPIScDed)[1]','varchar(200)'),
			@CtVenScDed=@parXML.value('(row/@CtVenScDed)[1]','varchar(200)'),
			@CtNeimpoz=@parXML.value('(row/@CtNeimpoz)[1]','varchar(200)')

	if object_id('tempdb..#decontvanz') is not null drop table #decontvanz
	create table #decontvanz
		(numar char(20), data datetime, cod_tert char(13), beneficiar char(80), codfisc char(20)
		,total float, baza_19 float, tva_19 float, baza_9 float, tva_9 float, baza_5 float, tva_5 float
		,baza_txinv float, tva_txinv float, regim_spec float, afara_ded float, afara_ded_serv float, afara_fara float
		,scutite_intra_ded_1 float, scutite_intra_ded_2 float, scutite_ded_alte float, scutite_fara float, neimpozabile float
		,explicatii char(50), detal_doc int, care_jurnal int, tip_doc char(2), nr_doc char(10), data_doc datetime, valoare_doc float, suma_tva_doc float)

--	vanzari: inlocuit apelul procedurii Declaratia300Vanzdet cu continutul ei
--	exec Declaratia300Vanzdet @parXML
	if object_id('tempdb..#jtvavanz') is not null drop table #jtvavanz
	create table #jtvavanz (numar char(20))
	exec CreazaDiezTVA '#jtvavanz'

	declare @parXMLJ xml
	set @parXMLJ=(select 1 tipcump, 'V' tipfact, 0 tvanx, 0 tvaeronat for xml raw)
	exec rapJurnalTVAVanzari  @sesiune=null, @DataJ=@datajos, @DataS=@datasus, @RecalcBaza=0, @nTVAex=0	
		,@Provenienta='', @OrdDataDoc=0, @OrdDenTert=1, @DifIgnor=0.5, @TipTvaTert=0	
		,@ContF=null, @LM=null, @LMExcep=0, @ContCor=null, @ContFExcep=0	
		,@Tert=null, @Factura=null, @cotatvaptfiltr=null, @Gest=null, @Jurnal=null
		,@FFFBTVA0=@FBTVA0, @SiFactAnul=0, @TVAAlteCont=0, @DVITertExt=0		
		,@DetalDoc=0, @CtVenScDed=@CtVenScDed, @CtPIScDed=@CtPIScDed, @CtCorespNeimpoz=@CtNeimpoz	
		,@parXML=@parXMLJ
	
	insert into #decontvanz
		(numar, data, cod_tert, beneficiar, codfisc, total, baza_19, tva_19, baza_9, tva_9, baza_5, tva_5, baza_txinv, tva_txinv, regim_spec, afara_ded, afara_ded_serv, afara_fara,
		scutite_intra_ded_1, scutite_intra_ded_2, scutite_ded_alte, scutite_fara, neimpozabile, 
		explicatii, detal_doc, care_jurnal, tip_doc, nr_doc, data_doc, valoare_doc, suma_tva_doc)
	select d.numar, d.data, d.cod_tert, d.beneficiar, d.codfisc, convert(decimal(15,3),d.total) as total, 
		convert(decimal(15,3),d.baza_19+d.baza_txinv_cump) as baza_19, convert(decimal(15,3),d.tva_19+d.tva_txinv_cump) as tva_19,
		convert(decimal(15,3),d.baza_9) as baza_9, convert(decimal(15,3),d.tva_9) as tva_9,
		convert(decimal(15,3),d.baza_5) as baza_5, convert(decimal(15,3),d.tva_5) as tva_5,
		convert(decimal(15,3),d.baza_txinv) baza_txinv, convert(decimal(15,3),d.tva_txinv) tva_txinv, 
		convert(decimal(15,3),d.regim_spec) regim_spec, 
		convert(decimal(15,3),d.afara_ded) afara_ded, convert(decimal(15,3),afara_ded_serv) afara_ded_serv, convert(decimal(15,3),d.afara_fara) afara_fara, 
		convert(decimal(15,3),d.scutite_intra_ded_1) scutite_intra_ded_1, convert(decimal(15,3),d.scutite_intra_ded_2) scutite_intra_ded_2, 
		convert(decimal(15,3),d.scutite_ded_alte) as scutite_ded_alte, convert(decimal(15,3),d.scutite_fara) as scutite_fara,
		convert(decimal(15,3),d.neimpozabile) as neimpozabile, 
		d.explicatii, d.detal_doc, d.care_jurnal, d.tip_doc, d.nr_doc, d.data_doc, 
		convert(decimal(15,3),d.valoare_doc) as valoare_doc, convert(decimal(15,3),d.suma_tva_doc) as suma_tva_doc
	from #jtvavanz d
	where (baza_19<>0 or tva_19<>0 or baza_9<>0 or tva_9<>0 or baza_5<>0 or tva_5<>0 or baza_txinv<>0
			or tva_txinv<>0 or regim_spec<>0 or afara_ded<>0 or afara_fara<>0 or scutite_intra_ded_1<>0
			or scutite_intra_ded_2<>0 or scutite_ded_alte<>0 or scutite_fara<>0 or neimpozabile<>0 or baza_txinv_cump<>0 or tva_txinv_cump<>0)

/**	Am inclus procedura de tratare a cazurilor specifice:
	Declaratia300VanzSP = procedura specifica;
			Procedura specifica care permite modificarea continutului tabelei #decontvanz 
	Procedura curenta va centraliza rezultatele (in tabela #dectvavanz) pentru declaratia 300
*/
	if exists (select 1 from sysobjects where name='Declaratia300VanzSP')
		exec Declaratia300VanzSP @parXML

	insert into #dectvavanz 
		(total, baza_19, tva_19, baza_9, tva_9, baza_5, tva_5, baza_txinv, tva_txinv, regim_spec, afara_ded, afara_ded_serv, afara_fara,
			scutite_intra_ded_1, scutite_intra_ded_2, scutite_ded_alte, scutite_fara, neimpozabile, valoare_doc, suma_tva_doc)
	select isnull(convert(decimal(15),sum(total)),0) as total, 
		isnull(convert(decimal(15),sum(baza_19)),0) as baza_19, isnull(convert(decimal(15),sum(tva_19)),0) as tva_19,
		isnull(convert(decimal(15),sum(baza_9)),0) as baza_9, isnull(convert(decimal(15),sum(tva_9)),0) as tva_9,
		isnull(convert(decimal(15),sum(baza_5)),0) as baza_5, isnull(convert(decimal(15),sum(tva_5)),0) as tva_5,
		isnull(convert(decimal(15),sum(baza_txinv)),0) baza_txinv, isnull(convert(decimal(15),sum(tva_txinv)),0) tva_txinv, 
		isnull(convert(decimal(15),sum(regim_spec)),0) regim_spec, 
		isnull(convert(decimal(15),sum(afara_ded)),0) afara_ded, isnull(convert(decimal(15),sum(afara_ded_serv)),0) afara_ded_serv, isnull(convert(decimal(15),sum(afara_fara)),0) afara_fara, 
		isnull(convert(decimal(15),sum(scutite_intra_ded_1)),0) scutite_intra_ded_1, isnull(convert(decimal(15),sum(scutite_intra_ded_2)),0) scutite_intra_ded_2, 
		isnull(convert(decimal(15),sum(scutite_ded_alte)),0) as scutite_ded_alte, isnull(convert(decimal(15),sum(scutite_fara)),0) as scutite_fara,
		isnull(convert(decimal(15),sum(neimpozabile)),0) as neimpozabile, 
		isnull(convert(decimal(15),sum(valoare_doc)),0) as valoare_doc, isnull(convert(decimal(15),sum(suma_tva_doc)),0) as suma_tva_doc
	from #decontvanz
	
	if object_id('tempdb..#jtvavanz') is not null drop table #jtvavanz
	if object_id('tempdb..#decontvanz') is not null drop table #decontvanz
end
