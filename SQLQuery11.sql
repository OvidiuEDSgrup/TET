declare crspozdoc cursor for
	select tip, upper(numar), data, 
	upper((case when isnull(gestiune_pozitii, '')<>'' then gestiune_pozitii when isnull(gestiune_antet, '')<>'' then gestiune_antet else @gestProprietate end)) as gestiune, 
	(case when isnull(gestiune_primitoare_pozitii, '')<>'' then gestiune_primitoare_pozitii else isnull(gestiune_primitoare_antet, '') end) as gestiune_primitoare, 
	upper((case when isnull(tert, '')<>'' then tert when tip in ('AP', 'AS') then @clientProprietate else '' end)) as tert, 
	upper(isnull(factura_pozitii, isnull(factura_antet, ''))) as factura, 
	isnull(datafact, isnull(data, '01/01/1901')) as datafact, isnull(datascad, isnull(datafact, isnull(data, '01/01/1901'))) as datascad, 
	(case when isnull(lm_pozitii, '')<>'' then lm_pozitii when isnull(lm_antet, '')<>'' then lm_antet else @lmProprietate end) as lm, 
	isnull(lmprim_antet, '') as lmprim, 
	isnull(numar_pozitie, 0) as numar_pozitie, upper(isnull(cod, '')) as cod,
	upper(isnull(codcodi,isnull(cod,''))) as codcodi,
	isnull(cantitate, 0) as cantitate, pret_valuta, isnull(tip_TVA,0) as tipTVA, 
	
	zilescadenta as zilescadenta,--zilele de scadenta, data_scadenta se va calcula din zilele de scadenta
	isnull(facturanesosita,0),--bifa de factura nesosita
	isnull(aviznefacturat,0),--bifa de aviz nefacturat
	
	upper(isnull(cod_intrare, '')) as cod_intrare, isnull(pret_amanunt, 0) as pret_amanunt, cota_TVA, suma_TVA, TVA_valuta, 
	upper(case when isnull(comanda_pozitii, '')<>'' then comanda_pozitii else isnull(comanda_antet, '') end) as comanda, 
	(case when isnull(indbug_pozitii, '')<>'' then indbug_pozitii else isnull(indbug_antet, '') end) as indbug, 
	isnull(cont_de_stoc, '') as cont_stoc, isnull(pret_de_stoc, 0) as pret_stoc, 
	
	---datele, curs si valuta, completate in pozitii sunt mai tari decat cele din antet
	---(totusi recomandat configurare pentru introducere curs si valuta din antet)
	upper(isnull(isnull(valuta,valuta_antet),'')) as valuta,
	convert(decimal(12,4),isnull(isnull(curs,curs_antet),0)) as curs,	

	upper(isnull(locatie, '')) as locatie,
	upper((case when isnull(contract_pozitii, '')<>'' then contract_pozitii else isnull(contract_antet, '') end)) as [contract], 
	upper(isnull(lot, '')) as lot, isnull(data_expirarii, '01/01/1901'), 
	(case when isnull(explicatii_pozitii, '')<>'' then explicatii_pozitii else isnull(explicatii_antet, '') end) as explicatii, 
	(case when isnull(isnull(jurnal, jurnalantet),'')<>'' then isnull(jurnal, jurnalantet) else @jurnalProprietate end) as jurnal,
	(case when isnull(cont_factura_pozitii, '')<>'' then cont_factura_pozitii else /*isnull(*/cont_factura_antet/*, '')*/ end) as cont_factura, 
	discount, 
	(case when isnull(punct_livrare_pozitii, '')<>'' then punct_livrare_pozitii else isnull(punct_livrare_antet, '') end) as punct_livrare, 
	isnull(barcod, '') as barcod, 
	(case when isnull(cont_corespondent_pozitii, '')<>'' then cont_corespondent_pozitii when tip in ('AI', 'AE', 'AF') then /*isnull(*/cont_corespondent_antet/*, '')*/ else '' end) as cont_corespondent, 
	isnull(dvi, '') as dvi, isnull(categ_pozitii, isnull(categ_antet, 0)) as categ_pret, 
	/*isnull(*/cont_intermediar/*, '')*/ as cont_intermediar, 
	isnull((case when isnull(cont_venituri_pozitii, '')<>'' then cont_venituri_pozitii else /*isnull(*/cont_venituri_antet/*, '')*/ end),'') as cont_venituri, 
	isnull(tva_neexigibil_pozitii, tva_neexigibil_antet) as tva_neexigibil, 
	isnull(accizecump, 0) as accizecump, 
	upper(isnull(nume_delegat, '')) as nume_delegat, upper(isnull(serie_buletin, '')) as serie_buletin, 
	isnull(numar_buletin, '') as numar_buletin, upper(isnull(eliberat_buletin, '')) as eliberat_buletin, 
	upper(isnull(mijloc_transport, '')) as mijloc_transport, upper(isnull(nr_mijloc_transport, '')) as nr_mijloc_transport, 
	isnull(data_expedierii, data) as data_expedierii, isnull(ora_expedierii, '000000') as ora_expedierii, 
	isnull(observatii, '') as observatii, isnull(punct_livrare_expeditie, '') as punct_livrare_expeditie, 
	isnull(ptupdate,0) as ptupdate ,
	stare as stare,
	
	--campuri din tabela textpozdoc
	rtrim(ltrim(text_alfa2)) as text_alfa2,
	
	--proprietati pt serii
	isnull(prop1,'') as prop1,
	isnull(prop2,'') as prop2,
	isnull(serie,'') as serie,
	isnull(subtip,'') as subtip,
	o_suma_TVA,o_pret_valuta,o_pret_amanunt,adaos
	
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		tip char(2) '../@tip', 
		numar char(8) '../@numar',
		data datetime '../@data',
		gestiune_antet char(9) '../@gestiune',
		gestiune_primitoare_antet char(13) '../@gestprim', 
		tert char(13) '../@tert',
		factura_antet char(20) '../@factura',
		datafact datetime '../@datafacturii',
		datascad datetime '../@datascadentei',
		lm_antet char(9) '../@lm',
		lmprim_antet char(9) '../@lmprim',
		comanda_antet char(20) '../@comanda', 
		indbug_antet char(20) '../@indbug', 
		cont_factura_antet char(13) '../@contfactura', 
		cont_corespondent_antet char(13) '../@contcorespondent', 
		cont_venituri_antet char(13) '../@contvenituri', 
		explicatii_antet char(30) '../@explicatii', 
		punct_livrare_antet char(5) '../@punctlivrare',
		categ_antet char(5) '../@categpret',
		tva_neexigibil_antet float '../@tvaneexigibil',
		contract_antet char(20) '../@contract', 
		nume_delegat char(30) '../@numedelegat', 
		serie_buletin char(10) '../@seriabuletin', 
		numar_buletin char(10) '../@numarbuletin', 
		eliberat_buletin char(30) '../@eliberat', 
		mijloc_transport char(30) '../@mijloctp', 
		nr_mijloc_transport char(20) '../@nrmijloctp', 
		data_expedierii datetime '../@dataexpedierii', 
		ora_expedierii char(6) '../@oraexpedierii', 
		observatii char(200) '../@observatii', 
		punct_livrare_expeditie char(5) '../@punctlivrareexped', 
		tip_TVA int '../@tiptva',
		zilescadenta int '../@zilescadenta',--zilele de scadenta->data_scadentei se va calcula din zilele de scadenta
		facturanesosita bit '../@facturanesosita',--bifa pentru facturi nesosite, dc este pusa atunci contul facturii va fi 408(furnizori-facturi nesosite)
		aviznefacturat bit '../@aviznefacturat',--bifa pentru avize nefacturate, dc este pusa atunci contul facturii va fi luat din parametrii(cont beneficiari avize nefacturate)
		jurnalantet char(3) '../@jurnal', 
		---cursul si valuta din antet
		valuta_antet varchar(3) '../@valuta' , 
		curs_antet varchar(14) '../@curs',
		
		stare smallint '../@stare',
		
		---pozitii-----
		numar_pozitie int '@numarpozitie',
		cod char(20) '@cod',
		codcodi char(20) '@codcodi',
		factura_pozitii char(20) '@factura',
		cantitate decimal(17, 5) '@cantitate',
		pret_valuta decimal(14, 5) '@pvaluta', 
		pret_amanunt decimal(14, 5) '@pamanunt', 
		cod_intrare char(13) '@codintrare',		
		cota_TVA decimal(5, 2) '@cotatva', 
		suma_TVA decimal(15, 2) '@sumatva', 
		TVA_valuta decimal(15, 2) '@tvavaluta', 
		gestiune_pozitii char(9) '@gestiune', 
		gestiune_primitoare_pozitii char(13) '@gestprim', 
		lm_pozitii char(9) '@lm', 
		comanda_pozitii char(20) '@comanda', 
		indbug_pozitii char(20) '@indbug', 
		cont_de_stoc char(13) '@contstoc', 
		pret_de_stoc float '@pstoc', 
		valuta char(3) '@valuta', 
		curs float '@curs', 
		locatie char(30) '@locatie', 
		contract_pozitii char(20) '@contract', 
		lot char(13) '@lot', 
		data_expirarii datetime '@dataexpirarii', 
		explicatii_pozitii char(30) '@explicatii', 
		jurnal char(3) '@jurnal', 
		cont_factura_pozitii char(13) '@contfactura', 
		discount float '@discount', 
		punct_livrare_pozitii char(5) '@punctlivrare', 
		barcod char(30) '@barcod', 
		cont_corespondent_pozitii char(13) '@contcorespondent', 
		DVI char(25) '@dvi', 
		categ_pozitii int '@categpret', 
		cont_intermediar char(13) '@contintermediar', 
		cont_venituri_pozitii char(13) '@contvenituri',
		tva_neexigibil_pozitii float '@tvaneexigibil',
		accizecump float '@accizecump', 
		ptupdate int '@update' ,
		adaos decimal(12,2) '@adaos',
		
		--campuri din tabela textpozdoc
		text_alfa2 varchar(30) '@text_alfa2',
		
		---proprietati pt serii
		prop1 char(20) '@prop1',
		prop2 char(20) '@prop2',
		serie char(20) '@serie',
		subtip char(20) '@subtip', 
		
		o_suma_TVA decimal(15, 2) '@o_sumatva' ,
		o_pret_amanunt decimal(14, 5) '@o_pamanunt',
		o_pret_valuta decimal(14, 5) '@o_pvaluta'
	)

	