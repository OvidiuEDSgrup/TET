--***
create function fDeclaratia300Cumpdet (@parXML xml='<row />')
returns @rdeccump table 
	(numar char(20), data datetime, cod_tert char(13), furnizor varchar(80), codfisc varchar(20)
	,total float, baza_19 float, tva_19 float, baza_9 float, tva_9 float, baza_5 float, tva_5 float, scutite float
	,baza_intra float, tva_intra float, baza_intra_serv float, tva_intra_serv float, scutite_intra float, scutite_intra_serv float, neimpoz_intra float
	,baza_oblig_1 float, tva_oblig_1 float, baza_oblig_1_serv float, tva_oblig_1_serv float, baza_oblig_2 float, tva_oblig_2 float 
	,explicatii char(50), cont_tva char(13), detal_doc int, care_jurnal int, tip_doc char(2), nr_doc char(10), data_doc datetime
	,valoare_doc float, cota_tva_doc int, suma_tva_doc float)
as
begin
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

--	cumparari
	insert into @rdeccump
		(numar, data, cod_tert, furnizor, codfisc, total, baza_19, tva_19, baza_9, tva_9, baza_5, tva_5, scutite, baza_intra, tva_intra, baza_intra_serv, tva_intra_serv, 
			scutite_intra, scutite_intra_serv, neimpoz_intra, baza_oblig_1, tva_oblig_1, baza_oblig_1_serv, tva_oblig_1_serv, baza_oblig_2, tva_oblig_2, 
			explicatii, cont_tva, detal_doc, care_jurnal, tip_doc, nr_doc, data_doc, valoare_doc, cota_tva_doc, suma_tva_doc)
	select numar, data, cod_tert, furnizor, codfisc, convert(decimal(15,3),d.total) as total, 
		convert(decimal(15,3),d.baza_19) as baza_19, convert(decimal(15,3),d.tva_19) as tva_19,
		convert(decimal(15,3),d.baza_9) as baza_9, convert(decimal(15,3),d.tva_9) as tva_9,
		(case when cota_tva_doc=5 then convert(decimal(15,3),d.baza_19) else 0 end) as baza_5, (case when cota_tva_doc=5 then convert(decimal(15,3),d.tva_9) else 0 end) as tva_5,
		convert(decimal(15,3),d.scutite) scutite, 
		convert(decimal(15,3),d.baza_intra) baza_intra, convert(decimal(15,3),d.tva_intra) tva_intra, 
		convert(decimal(15,3),d.baza_intra_serv) baza_intra_serv, convert(decimal(15,3),d.tva_intra_serv) tva_intra_serv, 
		convert(decimal(15,3),d.scutite_intra) scutite_intra, convert(decimal(15,3),d.scutite_intra_serv) scutite_intra_serv, convert(decimal(15,3),d.neimpoz_intra) neimpoz_intra, 
		convert(decimal(15,3),d.baza_oblig_1) as baza_oblig_1, convert(decimal(15,3),d.tva_oblig_1) as tva_oblig_1,
		convert(decimal(15,3),d.baza_oblig_1_serv) as baza_oblig_1_serv, convert(decimal(15,3),d.tva_oblig_1_serv) as tva_oblig_1_serv,
		convert(decimal(15,3),d.baza_oblig_2) as baza_oblig_2, convert(decimal(15,3),d.tva_oblig_2) as tva_oblig_2,
		explicatii, cont_tva, detal_doc, care_jurnal, tip_doc, nr_doc, data_doc, 
		convert(decimal(15,3),d.valoare_doc) as valoare_doc, cota_tva_doc, convert(decimal(15,3),d.suma_tva_doc) as suma_tva_doc
	from dbo.jurnalTVACumparari (@datajos, @datasus, '', '', '', 0, '', '', 0, 0, 0, @FFTVA0, @SFTVA0, @IAFTVA0, 1, 0, 0, 0, 0, '', 0.05, '', '', 0, '', 0, 0, @CtNeimpoz, @nTVAned, 0, '<row />') d
	where (baza_19<>0 or tva_19<>0 or baza_9<>0 or tva_9<>0 or scutite<>0
			or baza_intra<>0 or tva_intra<>0 or scutite_intra<>0 or neimpoz_intra<>0
			or baza_oblig_1<>0 or tva_oblig_1<>0 or baza_oblig_2<>0 or tva_oblig_2<>0)

	return
end