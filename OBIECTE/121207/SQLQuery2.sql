declare @parxml xml=
'<row datajos="2012-11-01T00:00:00" datasus="2012-11-30T00:00:00" calcul="1" FFTVA0="0" FBTVA0="2" SFTVA0="0" IAFTVA0="0" CtPIScDed="                                                                                                                                                                                                        " CtVenScDed="                                                                                                                                                                                                        " CtNeimpoz="                                                                                                                                                                                                        " nr_evid="10301011012251112000022" bifa_cereale="N" solicit_ramb="N" data_scadentei="2012-11-25T00:00:00"/>'
/*
select * from dbo.fDeclaratia300Vanzdet(@parxml) v
where v.scutite_fara<>0
--*/

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
	--exec wJurnalizareOperatie '',@parxml,'fDeclaratia300Cumpdet'
	
	select d.numar, d.data, d.cod_tert, d.beneficiar, d.codfisc, convert(decimal(15,3),d.total) as total, 
		convert(decimal(15,3),d.baza_19) as baza_19, convert(decimal(15,3),d.tva_19) as tva_19,
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
	from dbo.jurnalTVAVanzari (@datajos, @datasus, '', 0, '', '', 0, '', '', 0, 0, @CtVenScDed, @CtPIScDed, 0, @FBTVA0, 0, 1, 0, 0, 0, 0, 0.05, '', '', 0, '', 0, @CtNeimpoz, 0) d
	where (baza_19<>0 or tva_19<>0 or baza_9<>0 or tva_9<>0 or baza_5<>0 or tva_5<>0 or baza_txinv<>0
			or tva_txinv<>0 or regim_spec<>0 or afara_ded<>0 or afara_fara<>0 or scutite_intra_ded_1<>0
			or scutite_intra_ded_2<>0 or scutite_ded_alte<>0 or scutite_fara<>0 or neimpozabile<>0)
	and d.scutite_fara<>0
--and d.cod_tert='IT08010000000'