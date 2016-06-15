
Create PROCEDURE [wScriuDocBeta] @sesiune varchar(50), @parXML xml OUTPUT --am inlocuit cu ALTER va da eroare in cazul in care nu exista
AS
begin try
	DECLARE @iDoc INT

	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXml


	declare @subunitate varchar(13),@userASiS varchar(20), @gestProprietate varchar(20), @clientProprietate varchar(13), @lmProprietate varchar(20), @jurnalProprietate varchar(20),
			@returneaza_inserate bit, @rootDoc varchar(20),@multiDoc int, @rootDocAntet varchar(20),@StocuriNoi int, @cuRezervari bit, @bugetari int, @data_document datetime
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
	exec luare_date_par 'AR', 'NSTOC', @StocuriNoi output, 0, ''
	exec luare_date_par 'GE','REZSTOCBK',@cuRezervari OUTPUT, 0,''
	exec luare_date_par 'GE','BUGETARI',@bugetari OUTPUT, 0,''

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT

	select 
		@gestProprietate='', @clientProprietate='', @lmProprietate='', @jurnalProprietate=''
	select 
		@gestProprietate=(case when cod_proprietate='GESTIUNE' then valoare else @gestProprietate end), 
		@clientProprietate=(case when cod_proprietate='CLIENT' then valoare else @clientProprietate end), 
		@lmProprietate=(case when cod_proprietate='LOCMUNCA' then valoare else @lmProprietate end), 
		@jurnalProprietate=(case when Cod_proprietate='JURNAL' then Valoare else @jurnalProprietate end)
	from proprietati 
	where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate in ('GESTIUNE', 'CLIENT', 'LOCMUNCA', 'JURNAL') and valoare<>''

	if @parXML.exist('(/Date)')=1 --Daca exista parametrul Date inseamna ca avem date multiple de introdus in tabela  
	begin  
		set @rootDoc='/Date/row/row'  
		set @rootDocAntet='/Date/row'
		set @multiDoc=1  
	end  
	else  
	begin  
		set @rootDoc='/row/row'  
		set @rootDocAntet='/row'
		set @multiDoc=0  
	end  

	
	set @returneaza_inserate=ISNULL(@parXML.value('(//@returneaza_inserate)[1]', 'bit'), 0) -- citim cu // pt. ca sa luam si Date/row/@ret.. si row/@ret...

create table #documente(tip varchar(2),numar varchar(20),data datetime,gestiune varchar(13),gestiune_primitoare varchar(40),tert varchar(13),factura varchar(20),
data_facturii datetime,data_scadentei datetime,loc_de_munca varchar(13),numar_pozitie int,cod varchar(20),barcod varchar(20),codcodi varchar(50),cantitate float,pret_valuta float,pret_vanzare float,
tip_tva int,zilescadenta int,facturanesosita int,aviznefacturat int,cod_intrare varchar(20),codiPrim varchar(20),pret_cu_amanuntul float,cota_tva int,tva_deductibil decimal(12,2),
tva_valuta float,comanda varchar(20),indbug varchar(20),pret_de_stoc float,pret_amanunt_predator float,valuta varchar(3),curs float,locatie varchar(30),[contract] varchar(20),
lot varchar(20),data_expirarii datetime,discount decimal(12,3),punctlivrare varchar(13),numar_dvi varchar(20),categ_pret int,
cont_de_stoc varchar(40),cont_corespondent varchar(40),cont_intermediar varchar(40),cont_factura varchar(40),cont_venituri varchar(40),
tva_neexigibil decimal(5,2),idJurnalContract int,idPozContract int,stare int,jurnal varchar(20),detalii xml,detalii_antet xml,subtip varchar(2),tip_miscare varchar(1),
cumulat float,nrordmin int,nrordmax int,tvaunit float,nrpe int,nrpozmax int,updatabile int,cerecumulare int,idlinie int,idIntrareFirma int,idIntrare int,ptUpdate int,idpozdoc int,pid int,tva_deductibil_i decimal(12,2), idPtAntet int,colet varchar(500),
codgs1 varchar(1000), idPozDocRezervare int,idplaja int, nrp int identity, asociereconf varchar(20))

insert into #documente(tip,numar,data,gestiune,gestiune_primitoare,tert,factura,
data_facturii,data_scadentei,loc_de_munca,numar_pozitie,cod,barcod,codcodi,cantitate,pret_valuta,pret_vanzare,
tip_tva,zilescadenta,facturanesosita,aviznefacturat,cod_intrare,codiPrim,pret_cu_amanuntul,cota_tva,tva_deductibil,
tva_valuta,comanda,indbug,pret_de_stoc,pret_amanunt_predator,valuta,curs,locatie,contract,
lot,data_expirarii,discount,punctlivrare,numar_dvi,categ_pret,
cont_de_stoc,cont_corespondent,cont_intermediar,cont_factura,cont_venituri,
tva_neexigibil,idJurnalContract,idPozContract,stare,jurnal,detalii,detalii_antet,subtip,tip_miscare,updatabile,cerecumulare, idlinie,ptUpdate,idpozdoc,pid, tva_deductibil_i, idPtAntet,colet, codgs1, idPozDocRezervare, idIntrare)
select 

	NULL tip,
	NULL numar,
	data,
	upper(nullif(gestiune_pozitii, '')) as gestiune,
	upper(nullif(gestiune_primitoare_pozitii, '')) as gestiune_primitoare, 
	NULL as tert, 
	upper(nullif(factura_pozitii,'')) as factura, 
	datafact datafact, 
	NULL datascad, 
	nullif(lm_pozitii, '') as lm, 
	isnull(numar_pozitie,0) as numar_pozitie, 
	upper(isnull(cod, '')) as cod,
	isnull(barcod, '') as barcod, 
	upper(isnull(codcodi,isnull(cod,''))) as codcodi,
	isnull(cantitate, 0) as cantitate, 
	isnull(pret_valuta,0), 
	isnull(pret_vanzare,0) as pret_vanzare,
	tip_tva,	
	NULL as zilescadenta,--zilele de scadenta, data_scadenta se va calcula din zilele de scadenta
	NULL,--bifa de factura nesosita
	NULL,--bifa de aviz nefacturat
	upper(isnull(cod_intrare, '')) as cod_intrare, 
	upper(isnull(codiPrim, '')) as codiPrim,
	isnull(pret_amanunt, 0) as pret_amanunt, 
	cota_TVA, 
	isnull(suma_TVA,0), 
	TVA_valuta, 
	upper(nullif(comanda_pozitii, '')) as comanda, 
	isnull(indbug_pozitii, '') as indbug, 
	isnull(pret_de_stoc,0) as pret_stoc, 
	0 as pret_amanunt_predator,
	upper(NULLIF(valuta,'')) as valuta,
	convert(decimal(12,4),NULLIF(curs,0)) as curs,
	upper(isnull(locatie, '')) as locatie,
	upper(NULLIF(contract_pozitii,'')) as [contract], 
	upper(isnull(lot, '')) as lot, 
	isnull(data_expirarii, '01/01/1901') as dataexpirarii, 
	isnull(discount,0), 
	NULLIF(punct_livrare_pozitii,'') as punct_livrare, 
	NULLIF(dvi, '') as dvi,
	NULLIF(categ_pozitii,0) as categ_pret, 
	cont_de_stoc as cont_stoc, 
	nullif(cont_corespondent_pozitii, '') as cont_corespondent, 
	isnull(cont_intermediar, '') as cont_intermediar, 
	upper(nullif(cont_factura_pozitii, '')) as cont_factura, 
	NULLIF(cont_venituri_pozitii, '') as cont_venituri, 
	NULLIF(tva_neexigibil_pozitii,'') as tva_neexigibil, 
	isnull(idJurnalContract,0) as idJurnalContract,
	isnull(idPozContract,0) as idPozContract,
	NULL as stare,
	NULLIF(jurnal,'') as jurnal,
	detalii as detalii,
	NULL as detalii_antet,
	subtip,
	'' as tip_miscare,
	0 as updatabile, /*de regula sunt inserabile*/
	isnull(cerecumulare,0) as cerecumulare,
	idline as idline,
	isnull(ptUpdate,0) as ptUpdate,
	idPozDoc,
	dense_rank() over (order by pid),
	suma_TVA_i,
	pid as idPtAntet,
	colet,
	codgs1,
	idPozDocRezervare,
	idIntrare
from OPENXML(@iDoc, @rootDoc)
WITH 
(
	pid int '@mp:parentid',
			
	---pozitii-----
	detalii xml 'detalii/row',
	numar_pozitie int '@numarpozitie',
	data datetime '@data', 
	cod varchar(20) '@cod',
	codcodi varchar(33) '@codcodi',
	factura_pozitii char(20) '@factura',
	datafact datetime '@datafacturii', 
	cantitate decimal(17, 5) '@cantitate',
	pret_vanzare decimal(14,5) '@pret_vanzare',
	pret_valuta decimal(14, 5) '@pvaluta', 
	pret_amanunt decimal(14, 5) '@pamanunt', 
	cod_intrare varchar(20) '@codintrare',	
	codiPrim varchar(13) '@codiprimitor',		
	cota_TVA decimal(5, 2) '@cotatva', 
	suma_TVA decimal(15, 2) '@sumatva',
	suma_TVA_i decimal(15, 2) '@sumatva_i',  
	tip_TVA int '@tiptva',
	TVA_valuta decimal(15, 2) '@tvavaluta', 
	gestiune_pozitii char(9) '@gestiune', 
	gestiune_primitoare_pozitii varchar(40) '@gestprim', 
	lm_pozitii char(9) '@lm', 
	comanda_pozitii char(20) '@comanda', 
	indbug_pozitii char(20) '@indbug', 
	cont_de_stoc varchar(40) '@contstoc', 
	pret_de_stoc float '@pstoc', 
	valuta char(3) '@valuta', 
	curs float '@curs', 
	locatie char(30) '@locatie', 
	contract_pozitii char(20) '@contract', 
	lot char(20) '@lot', 
	data_expirarii datetime '@dataexpirarii',
	jurnal varchar(20) '@jurnal', 
	cont_factura_pozitii varchar(40) '@contfactura', 
	discount float '@discount', 
	punct_livrare_pozitii char(5) '@punctlivrare', 
	barcod char(30) '@barcod', 
	cont_corespondent_pozitii varchar(40) '@contcorespondent', 
	DVI char(25) '@dvi',
	categ_pozitii int '@categpret', 
	cont_intermediar varchar(40) '@contintermediar', 
	cont_venituri_pozitii varchar(40) '@contvenituri',
	tva_neexigibil_pozitii float '@tvaneexigibil',
	accizecump float '@accizecump', 
	ptupdate int '@update' ,
	adaos decimal(12,2) '@adaos',
		
	-- trimise din modulul contracte
	idJurnalContract int '@idjurnalcontract', 
	idPozContract int '@idpozcontract',
	subtip char(20) '@subtip',
	--alte
	cerecumulare int '@cerecumulare',
	idline int '@idlinie',
	idpozdoc int '@idpozdoc',
	colet varchar(500) '@colet',
	codgs1 varchar(1000) '@codgs1',
	idPozDocRezervare int '@idpozdocrezervare',
	idIntrare int '@idintrare'
	)

	update poz set 
		tip=(case when antet.tip='RC' then 'RM' else antet.tip end),
		numar=upper(antet.numar), 
		data=upper(isnull(antet.data,poz.data)),
		gestiune=COALESCE(gestiune,nullif(antet.gestiune_antet, ''),''),
		gestiune_primitoare=COALESCE(gestiune_primitoare,nullif(antet.gestiune_primitoare_antet, ''),''),
		tert=upper(isnull(antet.tert, '')),
		factura=COALESCE(factura,nullif(factura_antet, ''),''),
		data_facturii=isnull(poz.data_facturii, isnull(antet.datafact, isnull(antet.data, '01/01/1901'))),
		data_scadentei=antet.datascad,
		loc_de_munca=COALESCE(loc_de_munca,nullif(antet.lm_antet, ''),''),
		tip_tva=COALESCE(poz.tip_tva,nullif(antet.tip_TVA,0),0),
		zilescadenta =antet.zilescadenta,
		facturanesosita= isnull(antet.facturanesosita,0),--bifa de factura nesosita
		aviznefacturat= isnull(antet.aviznefacturat,0),
		comanda=COALESCE(comanda, NULLIF(antet.comanda_antet,''),''),
		valuta=COALESCE(valuta, nullif(valuta_antet,''),''),
		curs=COALESCE(curs, NULLIF(antet.curs_antet,0),0),
		numar_dvi=COALESCE(numar_dvi, NULLIF(antet.numar_dvi_antet,''),''),
		contract=COALESCE(contract, NULLIF(antet.contract_antet,''),''),
		punctlivrare=COALESCE(punctlivrare,NULLIF(antet.punct_livrare_antet,''),''),
		categ_pret=COALESCE(categ_pret, NULLIF(antet.categ_antet,0),0),
		cont_corespondent=COALESCE(cont_corespondent,nullif(case when antet.tip in ('AI','AE','AF') then antet.cont_corespondent_antet else '' end, ''),''),
		cont_factura=COALESCE(cont_factura, nullif(antet.cont_factura_antet,''),''),
		cont_venituri=isnull(cont_Venituri,''),
		tva_neexigibil=COALESCE(tva_neexigibil,NULLIF(antet.tva_neexigibil_antet,''),''),
		stare=isnull(nullif(antet.stare,0),3),
		jurnal=(case when antet.tip='RC' then 'RC' else coalesce(nullif(antet.jurnalantet,''),nullif(jurnal,''),@jurnalProprietate) end),
		detalii_antet=antet.detalii_antet,
		idplaja=antet.idplaja,
		asociereconf = antet.asociereconf
	from #documente poz
	JOIN OPENXML(@iDoc, @rootDocAntet)
	WITH 
	(
		pid int '@mp:id',
		detalii_antet XML 'detalii/row',

		tip char(2) '@tip', 
		numar char(20) '@numar',
		data datetime '@data',
		gestiune_antet char(9) '@gestiune',
		gestiune_primitoare_antet char(13) '@gestprim', 
		tert char(13) '@tert',
		factura_antet char(20) '@factura',
		datafact datetime '@datafacturii',
		datascad datetime '@datascadentei',
		lm_antet char(9) '@lm',
		lmprim_antet char(9) '@lmprim',
		comanda_antet char(20) '@comanda', 
		indbug_antet char(20) '@indbug', 
		cont_factura_antet varchar(40) '@contfactura', 
		cont_corespondent_antet varchar(40) '@contcorespondent', 
		cont_venituri_antet varchar(40) '@contvenituri', 
		explicatii_antet char(30) '@explicatii', 
		punct_livrare_antet char(5) '@punctlivrare',
		categ_antet char(5) '@categpret',
		tva_neexigibil_antet float '@tvaneexigibil',
		contract_antet char(20) '@contract', 
		nume_delegat char(30) '@numedelegat', 
		serie_buletin char(10) '@seriabuletin', 
		numar_buletin char(10) '@numarbuletin', 
		eliberat_buletin char(30) '@eliberat', 
		mijloc_transport char(30) '@mijloctp', 
		nr_mijloc_transport char(20) '@nrmijloctp', 
		data_expedierii datetime '@dataexpedierii', 
		ora_expedierii char(6) '@oraexpedierii', 
		observatii char(200) '@observatii', 
		punct_livrare_expeditie char(5) '@punctlivrareexped', 
		tip_TVA int '@tiptva',
		discount float '@discount',
		zilescadenta int '@zilescadenta',
		facturanesosita bit '@facturanesosita',
		aviznefacturat bit '@aviznefacturat',
		jurnalantet varchar(20) '@jurnal', 
		valuta_antet varchar(3) '@valuta' , 
		curs_antet float '@curs',
		numar_dvi_antet varchar(30) '@numardvi',
		numarpozitii int '@numarpozitii',		
		stare smallint '@stare',
		idplaja int '@idplaja',
		asociereconf varchar(20) '@asociereconf'			

		) antet on poz.idPtAntet=antet.pid

	exec sp_xml_removedocument @iDoc 

	/*
		Daca se lucreaza cu standardul GS1-128 procedura de mai jos actualizeaza #documente cu informatiile decodificate din codul GS1
	*/
	IF EXISTS (select 1 from #documente where NULLIF(codgs1,'') IS NOT NULL) and EXISTS (select 1 from sysobjects where name='wPrelucrareGS1') 
		exec wPrelucrareGS1 @sesiune=@sesiune, @parXML=@parXML
	/*
		identificare cod produs din cod de bare
	*/
	update d 
		set cod=rtrim(c.cod_produs)
	from #documente d
	inner join codbare c on c.Cod_de_bare=d.barcod 
	where isnull(cod,'')=''

	/*
		Daca se lucreaza cu unitati de masura secundare (vezi tabela UMProdus) anumite informatii dau efect aici
	*/
	update d set 
		cantitate = detalii.value('(/row/@cantitate_um)[1]','float')*u.coeficient, 
		pret_valuta=(case when detalii.value('(/row/@pret_um)[1]','float') IS NOT NULL then 
			round(convert(decimal(15,3),detalii.value('(/row/@pret_um)[1]','float') / (detalii.value('(/row/@cantitate_um)[1]','float')*u.coeficient)),2) else pret_valuta end)
	from #documente d
	JOIN UMProdus u on d.cod=u.cod and u.UM=detalii.value('(/row/@um_um)[1]','varchar(3)') and ISNULL(detalii.value('(/row/@cantitate_um)[1]','float'),0)>0.0
	

	/*
		Daca se lucreaza cu rezervari pe comenzi procedura de mai jos va actualiza #documente cu informatiile stocului din rezervari (=TE)
	*/
	IF @cuRezervari=1 and EXISTS (select 1 from sysobjects where name='wPrelucrareComenziRezervari') and EXISTS (select 1 from #documente where NULLIF(idPozDocRezervare,0)<>0)
		exec wPrelucrareComenziRezervari @sesiune=@sesiune, @parXML=@parXML

	create table #doc(idpozdoc int, idlinie int, numar_pozitie int)
	
	select d.tip,d.numar,d.pid,d.data,max(d.numar_pozitie) as maxpoz,sum(round(convert(decimal(12,3),d.tva_deductibil),2)) as sumatva
	into #maxPoz
	from #documente d 
	group by d.tip,d.numar,d.pid,d.data

	select p.tip,p.numar,p.data,max(p.numar_pozitie) as nrp
	into #mp
	from #documente d 
	inner join pozdoc p on p.subunitate=@subunitate and d.tip=p.tip and d.data=p.data and d.numar=p.numar
	group by p.tip,p.numar,p.data

	update #maxPoz set maxpoz=#mp.nrp
	from #mp 
	inner join #maxPoz on #mp.tip=#maxpoz.tip and #mp.numar=#maxpoz.numar and #mp.data=#maxpoz.data
	
	/*Aici se da gestiunea daca nu exista*/
	if @gestProprietate!='' and exists (select 1 from #documente where isnull(gestiune,'')='') 
	begin

		update #documente set gestiune=@gestProprietate where isnull(gestiune,'')=''

		if @parXML.value('(/row/@gestiune)[1]', 'varchar(20)') is not null                          
			set @parXML.modify('replace value of (/row/@gestiune)[1] with sql:variable("@gestProprietate")') 
		else
			set @parXML.modify ('insert attribute gestiune{sql:variable("@gestProprietate")} into (/row)[1]') 
	end

	/*Aici se da loc de munca daca nu exista*/
	if exists (select 1 from #documente where isnull(loc_de_munca,'')='')
	begin
		/*Luam locul de munca ca si lm atasat gestiunii*/
		update #documente set loc_de_munca=gestiuni.detalii.value('/row[1]/@lm[1]','varchar(20)')
		from #documente,gestiuni
		where #documente.gestiune=gestiuni.cod_gestiune and isnull(gestiuni.detalii.value('/row[1]/@lm[1]','varchar(20)'),'')!=''
			and isnull(#documente.loc_de_munca,'')=''

		/*Luam locul de munca ca si lm atasat gestiunii primitoare*/
		update #documente set loc_de_munca=gestiuni.detalii.value('/row[1]/@lm[1]','varchar(20)')
		from #documente,gestiuni
		where #documente.tip='TE' and #documente.gestiune_primitoare=gestiuni.cod_gestiune and isnull(gestiuni.detalii.value('/row[1]/@lm[1]','varchar(20)'),'')!=''
			 and isnull(#documente.loc_de_munca,'')=''

		/*Se ia locul de munca din comenzi*/
		update d
		set d.loc_de_munca= cm.loc_de_munca
		from #documente d
		inner join comenzi cm on d.comanda=cm.comanda
		where cm.Loc_de_munca<>''
			and isnull(d.loc_de_munca,'')=''

		update #documente set loc_de_munca=@lmproprietate 
			where isnull(loc_de_munca,'')='' and @lmProprietate!=''
	end

	/*Completam tipul de miscare si Cota_TVA
		I - Intrare
		E - Iesire
		V - Valoric
	*/
	update d set tip_miscare=
		(case when n.tip in ('F','R','S') then 'V'
			when d.tip in ('RM','AI','PP','AF','SI','FI') and isnull(g.tip_gestiune,'')!='V' then 'I'
			when d.tip in ('AP','AC','CM','TE','AE','DF','PF','CI') and isnull(g.tip_gestiune,'')!='V' then 'E'
			else 'V' end),
		cota_tva=isnull(d.cota_tva,n.Cota_TVA),
		tva_neexigibil=(case when g.tip_gestiune in ('A','V') and d.tip in ('RM','AI','PP') then isnull(nullif(d.tva_neexigibil,0),n.Cota_TVA) else 0 end)
	from #documente d
	inner join nomencl n on d.cod=n.cod 
	left outer join gestiuni g on g.Subunitate=@subunitate and d.gestiune=g.cod_gestiune

	--Modificare legislativa 01.01.2016 CotaTVA=20% dar la documente anterior acestei date va fi de 24%
	update #documente set cota_tva=24 where cota_tva=20 and data<'01/01/2016'

	update d set discount=round(-cota_tva*100.00/(100.00+cota_TVA),12,2)
		from #documente d
		where d.tip='RM' and d.jurnal='RC'

	/*
		Completam numarul facturii cu numarul documentului
		La documentele ce au completate tertul dar nu au completata factura.
	*/
	update d set data_scadentei=isnull(dateadd(day,coalesce(nullif(d.zilescadenta,0),nullif(it.zile_inc,0),ext.discount,0),data_facturii),convert(char(10),getdate(),101))
	from #documente d
	left outer join terti t on d.tert=t.tert
	left outer join infotert it on it.subunitate = @subunitate and d.tert=it.tert and it.identificator=substring(d.numar_dvi,14,5) and len(substring(d.numar_dvi,14,5))>0 
	left outer join infotert ext on ext.subunitate=@subunitate and d.tert=ext.tert and ext.identificator='' 
	where d.data_scadentei=d.data_facturii or d.data_scadentei is null or ptUpdate=1
	
	/* Iesirile cu minus se pun intrari, iar intrarile cu minus se pun iesiri. La scrierea in POZDOC se va folosi din nou algoritmul de mai sus
		dar pentru a trata corect intrarile si iesirile vom face aceste update-uri
	*/
	/*
	update #documente set tip_miscare='I' where tip_miscare='E' and cantitate<0
	update #documente set tip_miscare='E' where tip_miscare='I' and cantitate<0
	*/


	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuDocSPAnteSpargere')
		exec wScriuDocSPAnteSpargere @sesiune,@parXml output -- procedura care va modifica #documente
	

	/*-------------------------------------------La iesiri cu cantitate negativa stornam prima pozitie LIFO din stocuri - adica punem cod intrare - ultimul venit----*/
	if exists(select 1 from #documente where tip_miscare='E' and cantitate<0 and cod_intrare='' and @StocuriNoi=0 and not (tip='DF' and subtip='RO'))
	begin
			update d set cod_intrare=isnull(s.cod_intrare,'')
			from #documente d
			cross apply	(select top 1 cod_intrare from stocuri s where s.subunitate=@subunitate  and s.cod_gestiune=d.gestiune and s.cod=d.cod order by data desc) s
			where d.tip_miscare='E' and d.cantitate<0 and d.cod_intrare=''
	end

	/*-------------------------------------------La iesiri ce primesc cod de intrare trebuie sa redundam diverse date din stocuri----*/
	if exists(select 1 from #documente where (tip_miscare='E' or tip_miscare='I' and cantitate<0) and cod_intrare<>'') and @StocuriNoi=0
	begin
			update d set pret_de_stoc=s.pret,pret_amanunt_predator=s.Pret_cu_amanuntul,cont_de_stoc=s.Cont,locatie=(case when d.tip in ('TE','DF','PF') then d.locatie else s.Locatie end),idIntrare=s.idIntrare,idIntrareFirma=s.idIntrareFirma
			from #documente d
			inner join stocuri s on d.gestiune=s.cod_gestiune and d.cod=s.cod and d.cod_intrare=s.Cod_intrare 
	end

	if exists(select 1 from #documente where (tip_miscare='E' or tip_miscare='I' and cantitate<0) and isnull(idIntrare,0)>0) and @StocuriNoi=1
	begin
			update d set pret_de_stoc=s.pret_de_stoc,pret_amanunt_predator=s.Pret_cu_amanuntul,cont_de_stoc=s.Cont_de_stoc,locatie=(case when d.tip in ('TE','DF','PF') then d.locatie else s.Locatie end),idIntrareFirma=ISNULL(s.idIntrareFirma, s.idPozDoc), cod_intrare=s.Cod_intrare 
			from #documente d
			inner join pozdoc s on s.idPozdoc=d.idIntrare
	end

	/*-------------------------------------------Spargere iesiri pe cod de intrare---------------------*/
	if exists(select 1 from #documente where (tip_miscare='E' or tip_miscare='I' and cantitate<0) and cod_intrare='' and ptUpdate=0 and not (tip='DF' and subtip='RO')) 
	begin /*Spargere pentru iesiri*/
		
		declare @areTE int
		create table #pozd(Cantitate float,TVa_deductibil decimal(12,2),Tip varchar(2),Numar varchar(20),Cod varchar(20),Data datetime,Gestiune varchar(20),
			Pret_valuta decimal(12,5),Pret_de_stoc decimal(12,5),Pret_vanzare decimal(12,5),Pret_cu_amanuntul decimal(12,5),Cota_TVA decimal(12,2),
			Cod_intrare varchar(20),CodiPrim varchar(20),Cont_de_stoc varchar(40),Cont_corespondent varchar(40),TVA_neexigibil decimal(12,2),Pret_amanunt_predator decimal(12,5),
			Tip_miscare varchar(1),Locatie varchar(30),Data_expirarii datetime,Numar_pozitie int,Loc_de_munca varchar(20),Comanda varchar(20),
			Barcod varchar(20),Cont_intermediar varchar(40),Cont_venituri varchar(40),Discount decimal(12,5),Tert varchar(20),Factura varchar(20),
			Gestiune_primitoare varchar(40),Numar_DVI varchar(20),Categ_pret int,Stare int,Cont_factura varchar(40),Valuta varchar(3),Curs decimal(12,5),Data_facturii datetime,
			Data_scadentei datetime,Tip_tva int,Contract varchar(20),Jurnal varchar(20),
			cumulat float,nrordmin int,nrordmax int,tvaunit float,nrp int, nrpozmax int,idPozDoc int, idPozContract int, idJurnalContract int,detalii xml, idlinie int,idIntrareFirma int,idIntrare int,pid int, tva_deductibil_i decimal(12,2),
			detalii_antet xml, facturanesosita bit, aviznefacturat bit, punctlivrare varchar(50),lot varchar(20),colet varchar(500),idplaja int, subtip varchar(2), asociereconf varchar(20))

		delete d
		OUTPUT (case when deleted.tip_miscare='I' then -1 else 1 end)*DELETED.Cantitate,DELETED.TVa_deductibil,DELETED.Tip,DELETED.NUMAR,DELETED.Cod,DELETED.Data,DELETED.Gestiune,
			DELETED.Pret_valuta,DELETED.Pret_de_stoc,DELETED.Pret_vanzare,DELETED.Pret_cu_amanuntul,DELETED.Cota_TVA,
			DELETED.Cod_intrare,DELETED.codiprim,DELETED.Cont_de_stoc,DELETED.Cont_corespondent,
			DELETED.TVA_neexigibil,DELETED.Pret_amanunt_predator,DELETED.Tip_miscare,DELETED.Locatie,DELETED.Data_expirarii,DELETED.Numar_pozitie,
			DELETED.Loc_de_munca,DELETED.Comanda,DELETED.Barcod,DELETED.Cont_intermediar,DELETED.Cont_venituri,DELETED.Discount,DELETED.Tert,DELETED.Factura,
			DELETED.Gestiune_primitoare,DELETED.Numar_DVI,DELETED.Categ_pret,DELETED.Stare,DELETED.Cont_factura,DELETED.Valuta,DELETED.Curs,
			DELETED.Data_facturii,DELETED.Data_scadentei,DELETED.Tip_tva,
			DELETED.Contract,DELETED.Jurnal,CONVERT(FLOAT,0) as cumulat,0 as nrordmin,0 as nrordmax,deleted.tva_deductibil/(case when deleted.cantitate=0 then 1 else deleted.cantitate end) as tvaunit,0,0, 
			DELETED.nrp, DELETED.idPozContract, DELETED.idJurnalContract,DELETED.detalii, deleted.idlinie,deleted.idIntrareFirma,deleted.idIntrare,deleted.pid, deleted.tva_deductibil_i,
			DELETED.detalii_antet, deleted.facturanesosita, DELETED.aviznefacturat, deleted.punctlivrare,deleted.lot,deleted.colet,deleted.idplaja, deleted.subtip, deleted.asociereconf
		INTO #pozd
		from #documente d 
		where (tip_miscare='E' or tip_miscare='I' and cantitate<0) and d.cod_intrare='' and ptUpdate=0
		

		/*Creeam o tabela temporara pentru gestiuni de Transfer - utila mai ales la PV*/
		create table #gesttransfer(gestiune varchar(20),gestiune_transfer varchar(20),nrordine int)
		exec creeazaGestiuniTransfer
		
		update #pozd 
			set nrp=ranc
		from 
			(
				select 
					p2.tip,p2.pid,p2.data,p2.numar_pozitie,p2.idPozDoc,ROW_NUMBER() over (partition by p2.cod order by p2.cod,p2.data,p2.idPozDoc) as ranc
				from #pozd p2
			) p1 
		where p1.tip=#pozd.tip and p1.pid=#pozd.pid and p1.data=#pozd.data and p1.idPozDoc=#pozd.idPozDoc

		update #pozd
			set nrpozmax=maxpoz 
		from 
			(
				select 
					p2.tip,p2.numar,p2.data,MAX(p2.numar_pozitie) as maxpoz
				from pozdoc p2
				inner join #pozd p3 on p2.tip=p3.tip and p2.numar=p3.numar and p2.data=p3.data 
				group by p2.tip,p2.numar,p2.data
			) p1
		 where p1.tip=#pozd.tip and p1.numar=#pozd.numar and p1.data=#pozd.data 

		create table #stoctotal(nrord int,stoctotal float,Tip_gestiune varchar(1),Cod_gestiune varchar(20),Cod varchar(20),Data datetime,Cod_intrare varchar(13),Pret float,Stoc_initial float,Intrari float,Iesiri float,
			Data_ultimei_iesiri datetime,Stoc float,Cont varchar(40),Data_expirarii datetime,Stoc_ce_se_calculeaza float,Are_documente_in_perioada bit,TVA_neexigibil real,
			Pret_cu_amanuntul float,Locatie varchar(30),Pret_vanzare float,Loc_de_munca varchar(9),Comanda varchar(40),Contract varchar(20),Furnizor varchar(13),Lot varchar(20),
			Stoc_initial_UM2 float,Intrari_UM2 float,Iesiri_UM2 float,Stoc_UM2 float,Stoc2_ce_se_calculeaza float,Val1 float,Alfa1 varchar(30),Data1 datetime,gestiune_transfer varchar(20),idIntrareFirma int,idIntrare int,colet varchar(500))
		
		if @StocuriNoi=1
		begin
			insert into #stoctotal
			select 
				row_number() over (partition by pd.cod_gestiune,p.cod order by pd.nrordine,p.data) as nrord,convert(float,0.00) as stoctotal,
				'C' as tip_gestiune, p.gestiune as cod_gestiune, p.Cod, p.Data, p.Cod_intrare, p.Pret_de_stoc, p.cantitate, p.cantitate, 0, '01/01/1901', 
				(case when s.Stoc<0 then 0 else s.stoc end), 
				p.Cont_de_stoc, pi.Data_expirarii, 0, 0, p.TVA_neexigibil, p.Pret_cu_amanuntul, p.Locatie, 0, p.Loc_de_munca, 
				p.Comanda, p.Contract, pi.tert, coalesce(p.lot,pi.Lot,pd.lot), 0, 0, 0, 0, 0, 0, '', '01/01/1901' ,pd.gestiune_transfer,coalesce(p.idIntrareFirma,p.idIntrare,p.idPozDoc),coalesce(p.idIntrare,p.idPozDoc),
				coalesce(p.colet,pi.colet,pd.colet) as colet
			from stoc s
			left outer join pozdoc p on s.idintrare=p.idpozdoc
			left outer join pozdoc pi on p.idIntrareFirma=pi.idpozdoc
			inner join
				(select p.gestiune as cod_gestiune,gt.gestiune_transfer,p.cod,gt.nrordine,p.lot,p.colet,sum(p.cantitate) as cantitate
				from #pozd p 
				left outer join #gesttransfer gt on gt.gestiune=p.Gestiune
				group by p.gestiune,gt.gestiune_transfer,p.cod,p.lot,p.colet,gt.nrordine
				) pd on p.gestiune=isnull(pd.gestiune_transfer,pd.cod_Gestiune) and p.cod=pd.cod 
					and (nullif(pd.lot,'') is null or isnull(p.lot,pi.lot)=pd.lot)
					and (nullif(pd.colet,'') is null or isnull(p.colet,pi.colet)=pd.colet)
			where 
				s.panala is null
				and (pd.cantitate<0 or s.stoc>0.001)

		end
		else /*Cu vechea tabela de stocuri*/
		insert into #stoctotal
		select 
			row_number() over (partition by pd.cod_gestiune,s.cod order by pd.nrordine,s.data) as nrord,convert(float,0.00) as stoctotal,
			s.Tip_gestiune, pd.cod_gestiune as cod_gestiune, s.Cod, s.Data, s.Cod_intrare, s.Pret, s.Stoc_initial, s.Intrari, s.Iesiri, s.Data_ultimei_iesiri, 
			(case when s.Stoc<0 then 0 else s.stoc end), 
			s.Cont, s.Data_expirarii, s.Stoc_ce_se_calculeaza, s.Are_documente_in_perioada, s.TVA_neexigibil, s.Pret_cu_amanuntul, s.Locatie, s.Pret_vanzare, s.Loc_de_munca, s.Comanda, s.Contract, s.Furnizor, s.Lot, s.Stoc_initial_UM2, s.Intrari_UM2, s.Iesiri_UM2, s.Stoc_UM2, s.Stoc2_ce_se_calculeaza, s.Val1, s.Alfa1, s.Data1,pd.gestiune_transfer,s.idIntrareFirma,s.idIntrare,null as colet
		from stocuri s
		inner join
			(select p.gestiune as cod_gestiune,gt.gestiune_transfer,p.cod,gt.nrordine,sum(p.cantitate) as cantitate
			from #pozd p 
			left outer join #gesttransfer gt on gt.gestiune=p.Gestiune
			group by p.gestiune,gt.gestiune_transfer,p.cod,gt.nrordine
			) pd on s.cod_gestiune=isnull(pd.gestiune_transfer,pd.cod_Gestiune) and s.cod=pd.cod
		where 
			rtrim(s.Cod_intrare)!='' 
			and (pd.cantitate<0 or s.stoc>0.001)
		/* Mai punem o linie in stocuri cu cod intrare necompletat din stocuri daca cantitatea depaseste stocul curent*/ 

		declare @maxPozDoc int
		set @maxPozDoc=IDENT_CURRENT('pozdoc') 
		insert into #stoctotal
		select distinct 
			s1.nrord+1,0,s1.Tip_gestiune,s1.Cod_gestiune,s1.Cod,dateadd(day,1,s1.Data),'ST'+ltrim(str(@maxPozDoc+ROW_NUMBER() over (order by s1.cod_gestiune,s1.cod))) as cod_intrare,
			s1.Pret,100000000,100000000,0,s1.Data_ultimei_iesiri,100000000,s1.Cont,s1.Data_expirarii,s1.Stoc_ce_se_calculeaza,s1.Are_documente_in_perioada,
			s1.TVA_neexigibil,s1.Pret_cu_amanuntul,s1.Locatie,s1.Pret_vanzare,s1.Loc_de_munca,s1.Comanda,s1.Contract,s1.Furnizor,s1.Lot,s1.Stoc_initial_UM2,
			s1.Intrari_UM2,s1.Iesiri_UM2,s1.Stoc_UM2,s1.Stoc2_ce_se_calculeaza,s1.Val1,s1.Alfa1,s1.Data1,'',null as idIntrareFirma,null as idIntrare,null as colet
		from #stoctotal s1
		inner join 
			(
				select 
					s1.Cod_gestiune,s1.Cod,MAX(nrord) as nrord
				from #stoctotal s1
				group by s1.Cod_gestiune,s1.Cod
			) sm on s1.Cod_gestiune=sm.Cod_gestiune and s1.Cod=sm.Cod and s1.nrord=sm.nrord

		/* Mai punem o linie in stocuri cu cod intrare necompletat din pozdoc daca nu a avut nicio linie in tabela de stocuri*/
		insert into #stoctotal
		select 
			1,0,ISNULL(g.Tip_gestiune,'C'),p.gestiune,p.Cod,min(p.Data),'ST'+ltrim(str(@maxPozDoc+ROW_NUMBER() over (order by p.gestiune,p.cod)+1000)) as cod_intrare,
			max(p.Pret_de_stoc),100000000,100000000,0,min(p.Data),100000000,max(p.Cont_de_stoc),min(p.Data),0,0,max(p.TVA_neexigibil),max(p.Pret_cu_amanuntul),
			max(p.Locatie),max(p.Pret_vanzare),max(p.Loc_de_munca),max(p.Comanda),max(p.Contract),'','',0,0,0,0,0,0,'',min(p.Data),'',null as idIntrareFirma,null as idIntrare,null as colet
		from #pozd p
		left outer join gestiuni g on g.Subunitate=@subunitate and g.Cod_gestiune=p.gestiune
		left outer join #stoctotal s on s.cod_gestiune=p.gestiune and s.cod=p.cod
		where s.cod is null -- echivalent "not exists"
		group by ISNULL(g.Tip_gestiune,'C'),p.gestiune,p.Cod

		if EXISTS (select 1 from sysobjects where name='wScriuDocFiltruStocSpargereSP')
			exec wScriuDocFiltruStocSpargereSP @sesiune=@sesiune,@parXML=@parXML

		update #stoctotal 
			set stoctotal=st
		from 
			(	select 
					s1.Cod_gestiune,s1.Cod,s1.nrord,SUM(s2.stoc) as st from #stoctotal s1,#stoctotal s2
				where s1.Cod_gestiune=s2.Cod_gestiune and s1.Cod=s2.Cod and s2.nrord<=s1.nrord
				group by s1.Cod_gestiune,s1.Cod,s1.nrord
			) calcule 
		where 
			calcule.Cod_gestiune=#stoctotal.Cod_gestiune and
			calcule.Cod=#stoctotal.Cod and calcule.nrord=#stoctotal.nrord

		update #pozd 
			set cumulat=tot.cum
		from 
			(
				select
					 c1.tip,c1.pid,c1.cod,c1.comanda,c1.Loc_de_munca,c1.Data,c1.nrp,SUM(c2.cantitate) as cum from #pozd c1
				inner join #pozd c2 on c1.cod=c2.cod and c1.gestiune=c2.gestiune and c2.nrp<=c1.nrp
				group by c1.tip,c1.pid,c1.cod,c1.comanda,c1.Loc_de_munca,c1.Data,c1.nrp
			) tot
		where 
			#pozd.tip=tot.tip and #pozd.pid=tot.pid and #pozd.cod=tot.cod and #pozd.comanda=tot.comanda and #pozd.nrp=tot.nrp

		/* Punem min si max */
		update #pozd set nrordmin=st.nrord,nrordmax=st2.nrord
		from #pozd c
			cross apply
				(select top 1 smin.nrord from #stoctotal smin where smin.cod=c.cod and smin.Cod_gestiune=c.gestiune and c.cumulat-c.cantitate<smin.stoctotal order by smin.stoctotal) st 
			cross apply
				(select top 1 smax.nrord from #stoctotal smax where smax.cod=c.cod and smax.Cod_gestiune=c.gestiune and c.cumulat<=smax.stoctotal order by smax.stoctotal) st2
	
		/* Mica corectie pentru numere negative ce trebuie sa fie sparte*/	
		update #pozd set nrordmin=nrordmax where nrordmin>nrordmax

		/*Reinseram liniile in tabela #documente - doar ca de aceasta date sparte si cu cod_intrare,pret_de_Stoc, etc. completate*/
		insert into #documente(Cantitate,TVa_deductibil,Tip,Numar,Cod,Data,Gestiune,Pret_valuta,Pret_de_stoc,
			Pret_vanzare,Pret_cu_amanuntul,Cota_TVA,Cod_intrare,Cont_de_stoc,Cont_corespondent,TVA_neexigibil,Pret_amanunt_predator,
			Tip_miscare,Locatie,Data_expirarii,Numar_pozitie,Loc_de_munca,Comanda,Barcod,Cont_intermediar,Cont_venituri,Discount,Tert,Factura,
			Gestiune_primitoare,Numar_DVI,Categ_pret,Stare,codiprim,Cont_factura,Valuta,Curs,Data_facturii,Data_scadentei,Tip_tva,Contract,Jurnal, idPozContract, idJurnalContract,detalii, idlinie,idIntrareFirma,idIntrare,pid, tva_deductibil_i,
			detalii_antet, facturanesosita, aviznefacturat, punctlivrare,idplaja, subtip, lot, asociereconf,colet)
		select 
			--Pentru verificari s1.nrord,s1.stoctotal,pd.cantitate as c1,pd.cumulat,s1.stoc,pd.nrordmin,pd.nrordmax,
			(case when pd.tip_miscare='I' then -1 else 1 end)*
			(case 
				when pd.nrordmin=pd.nrordmax or pd.cantitate<0 
					then pd.cantitate
				when pd.nrordmin=s1.nrord --prima linie de pe stoc
					then pd.cantitate-(pd.cumulat-s1.stoctotal)
				when pd.nrordmax=s1.nrord --ultima linie de pe stoc
					then (pd.cumulat+s1.stoc-s1.stoctotal)
			  else s1.stoc
			end) as cantitate,
			(case when pd.tip_miscare='I' then -1 else 1 end)*
			(case 
				when pd.nrordmin=pd.nrordmax or pd.cantitate<0 
					then pd.cantitate
				when pd.nrordmin=s1.nrord --prima linie de pe stoc
					then pd.cantitate-(pd.cumulat-s1.stoctotal)
				when pd.nrordmax=s1.nrord --ultima linie de pe stoc
					then (pd.cumulat+s1.stoc-s1.stoctotal)
			  else s1.stoc
			end)*pd.tvaunit,
			pd.Tip,pd.Numar,pd.Cod,pd.Data,
			isnull(nullif(s1.Gestiune_transfer,''),pd.Gestiune) as Gestiune,
			pd.Pret_valuta,s1.Pret as pret_de_stoc,pd.Pret_vanzare,pd.Pret_cu_amanuntul,pd.Cota_TVA,
			s1.Cod_intrare,s1.Cont,pd.Cont_corespondent,s1.TVA_neexigibil,
			s1.Pret_cu_amanuntul,pd.Tip_miscare,pd.Locatie,pd.Data_expirarii,
			0 as numar_pozitie,--ROW_NUMBER() over (partition by pd.tip,pd.numar,pd.data order by pd.numar_pozitie),
			pd.Loc_de_munca,pd.Comanda,pd.Barcod,pd.Cont_intermediar,pd.Cont_venituri,pd.Discount,pd.Tert,pd.Factura,
			(case when ISNULL(s1.Gestiune_transfer,'')!='' and pd.tip='AC' then pd.Gestiune when ISNULL(pd.gestiune_primitoare,'')!='' then pd.gestiune_primitoare else '' end) as GestiunePrimitoare,
			pd.Numar_DVI,pd.Categ_pret,pd.Stare,
			(case when tip in ('TE','DF','PF') then
				(case when sprim.cod is not null then pd.codiprim 
				else 'cinou' --rtrim(s1.cod_intrare)+ltrim(str(row_number() over (partition by pd.cod order by pd.numar_pozitie)))
				end)
			else pd.codiprim end),
			pd.Cont_factura,pd.Valuta,pd.Curs,pd.Data_facturii,pd.Data_scadentei,pd.Tip_tva,pd.Contract,pd.Jurnal, pd.idPozContract, pd.idJurnalContract,pd.detalii, pd.idlinie,s1.idIntrareFirma,s1.idIntrare,pd.pid, pd.tva_deductibil_i,
			pd.detalii_antet, facturanesosita, aviznefacturat, pd.punctlivrare,pd.idplaja, pd.subtip, pd.lot,
			pd.asociereconf, pd.colet
			from #pozd pd
     		left outer join #stoctotal s1 on s1.cod_gestiune=pd.gestiune and s1.Cod=pd.cod and s1.nrord between pd.nrordmin and pd.nrordmax
			/*Pentru transferuri mai fac un join */
			left outer join stocuri sprim on pd.tip in ('TE','DF','PF') and sprim.Subunitate=@subunitate and 
				sprim.Cod_gestiune=pd.Gestiune_primitoare and sprim.cod=pd.cod and sprim.Cod_intrare=pd.codiprim and sprim.Cont=pd.Cont_corespondent and sprim.Pret=pd.Pret_de_stoc
				and sprim.pret_cu_amanuntul=pd.Pret_cu_amanuntul

	
		
		update #documente set tva_deductibil=tva_deductibil+(mp.sumatva-d.tvadeductibil)
		from #maxPoz mp
			inner join (select dd.tip,dd.pid,dd.data,sum(round(convert(Decimal(12,3),dd.tva_deductibil),2)) as tvadeductibil 
				from #documente dd group by dd.tip,dd.pid,dd.data) d 
				on d.tip=mp.tip and d.pid=mp.pid and d.data=mp.data
		where #documente.tip=mp.tip and #documente.pid=mp.pid and #documente.data=mp.data and #documente.numar_pozitie=1
		and abs(d.tvadeductibil-mp.sumatva)>0.001 and abs(mp.sumatva)>0.001

		delete #documente where abs(cantitate)<0.000001
	end

	/*	Daca nu a trecut prin bucla (avea cod intrare completat) totusi trebuie dat cod intrare primitor nou	*/
	update #documente set codiprim='cinou' where tip in ('TE','DF','PF') and codiprim=''

	 /*!!!!!!!!--------------------------Gata spargere iesiri pe cod intrare-------------------------------------*/
	/*Pun Cota TVA Neexigibil la TI - poate a venit un TVA_neexigibil din stocuri rau----------------------------*/
	update d set tva_neexigibil=n.Cota_TVA
		from #documente d
		inner join nomencl n on d.cod=n.cod 
		inner join gestiuni g on g.Subunitate=@subunitate and d.gestiune_primitoare=g.cod_gestiune
	where d.tip='TE' and g.tip_gestiune in ('A','V')

	/* Se iau pretul la intrari cu pret de stoc necompletat- NOUA METODA	*/
	declare @iauPretIntrari int
	set @iauPretIntrari = 0
	select top 1 @iauPretIntrari = 1 from #documente d where d.tip in ('RM','RS') and d.ptUpdate=0 and isnull(d.pret_valuta,0)=0

	IF @iauPretIntrari = 1 and EXISTS (select 1 from sysobjects where [type]='P' and [name]='wIaPreturiIntrare')
	BEGIN
		create table #preturiintrare(cod varchar(20),umprodus varchar(3),nestlevel int)
		
		insert into #preturiintrare
		select cod,max(detalii.value('(/row/@um_um)[1]','varchar(3)')),@@NESTLEVEL
		from #documente
		group by cod
			
		exec CreazaDiezPreturiIntrare

		declare @parXMLPreturiI xml
		select @parXMLPreturiI= @parXML

		exec wIaPreturiIntrare @sesiune=@sesiune, @parXML=@parXMLPreturiI
		
		update d
			set pret_valuta=ci.pret_stoc, valuta=ISNULL(ci.valuta,''), curs=ISNULL(ci.curs,0)
		from #documente d	
		JOIN #preturiintrare ci on d.cod=ci.cod		
		where isnull(d.pret_valuta,0)=0
	END

	/*Se ia pret valuta din nomenclator la Receptii - pentru cele care primesc pret de stoc egal cu zero*/
	update d
		set pret_valuta=isnull(nullif(d.pret_valuta,0),n.Pret_stoc)
		from #documente d
		inner join nomencl n on d.cod=n.cod 
		where isnull(d.pret_valuta,0)=0 and d.tip in ('RM','RS') and d.ptUpdate=0

	/*------------------------------Luare preturi pentru vanzare sau pentru pret cu amanuntul----------------------------------*/
	/*-------------------------------------------------------------------------------------------------------------------------*/
	declare @iauPretAmIntrari int,@iauPretAmIesiri int
	
	set @iauPretAmIntrari=0	
	set @iauPretAmIntrari=(select top 1 1
								from #documente d
								inner join gestiuni g on d.gestiune=g.cod_gestiune
								left outer join gestiuni gp on d.tip='TE' and d.gestiune_primitoare=gp.cod_gestiune
								where coalesce(gp.tip_gestiune,g.tip_gestiune,'C') in ('A','V') and pret_cu_amanuntul=0
								and d.tip in ('RM','RS','AI','TE')
			) 
	--La intrari pentru pret cu amanuntul pe gestiuni de tip A sau V
	set @iauPretAmIesiri=0
	set @iauPretAmIesiri=(select top 1 1
								from #documente d
								inner join gestiuni g on d.gestiune=g.cod_gestiune
								where pret_vanzare=0 and d.tip in ('AP','AC','AS')
			) 

	--La intrari pentru pret cu amanuntul pe gestiuni de tip A sau V
	if @iauPretAmIntrari=1 or @iauPretAmIesiri=1
	begin
		create table #preturi(cod varchar(20),umprodus varchar(3),nestlevel int)
		
		insert into #preturi
		select cod,max(detalii.value('(/row/@um_um)[1]','varchar(3)')),@@NESTLEVEL
		from #documente
		group by cod
			
		exec CreazaDiezPreturi

		/**
			La "intrari" vom alter putin @parXML asa incat sa nu trimitem "variabile" pentru determinarea pretului care tin de iesiri
				Ex: Tert, Punct liv., Contract, etc

			Vom crea o "copie" @parXML pentru ca modificarile din continul lui sa aiba efect doar in wIaPreturi nu si aici in procedura
		**/
		declare @parXMLPreturi xml
		select @parXMLPreturi= @parXML

		IF @iauPretAmIntrari=1
		BEGIN 
			set @parXMLPreturi.modify('delete (/row/@tert)[1]')
			set @parXMLPreturi.modify('delete (/row/@punctlivrare)[1]')
			set @parXMLPreturi.modify('delete (/row/@idContract)[1]')
			set @parXMLPreturi.modify('delete (/row/@comandalivrare)[1]')
		END

		exec wIaPreturi @sesiune=@sesiune, @parXML=@parXMLPreturi

		if @iauPretAmIntrari=1
			update d set pret_cu_amanuntul=p.pret_amanunt
				from #documente d
				inner join #preturi p on d.cod=p.cod
				inner join gestiuni g on d.gestiune=g.cod_gestiune
				left outer join gestiuni gp on d.tip='TE' and d.gestiune_primitoare=gp.cod_gestiune
				where coalesce(gp.tip_gestiune,g.tip_gestiune,'C') in ('A','V') and pret_cu_amanuntul=0
				and d.tip in ('RM','RS','AI','TE')			
		
		if @iauPretAmIesiri=1 
			update d set pret_valuta=isnull(p.pret_vanzare,0),
						 pret_cu_amanuntul=isnull(p.pret_amanunt,0),
						 discount=case when ISNULL(d.discount,0)=0 then ISNULL(p.discount,0) else d.discount end
				from #documente d
				inner join #preturi p on p.cod=d.cod
				inner join gestiuni g on d.gestiune=g.cod_gestiune
				where d.pret_valuta=0 and d.tip in ('AP','AC','AS')

	end

	update #documente set pret_vanzare=pret_valuta*(CASE WHEN isnull(valuta, '') <> '' THEN isnull(curs, 0) ELSE 1 END) * (1 - discount / 100)
	where pret_vanzare=0 and tip in ('AP','AC','AS')
	/*Gata formare preturi cu amanuntul sau pret de vanzare*/

	-- Pentru receptii terti externi cu DVI, cota TVA = 0.
	update d set cota_tva=0
	from #documente d
	inner join infotert ext on ext.subunitate=@subunitate and d.tert=ext.tert and ext.identificator='' 
	where d.tip='RM' and d.valuta<>'' and d.numar_dvi<>'' and ext.zile_inc=2

	-- Pentru receptii de la terti UE, in valuta, tip TVA = 1 Compensat.
	update d set tip_tva=1
	from #documente d
	inner join infotert ext on ext.subunitate=@subunitate and d.tert=ext.tert and ext.identificator='' 
	where d.tip='RM' and d.valuta<>'' and ext.zile_inc=1

	/* Daca se primeste tva_deductibil_i (introdus) acesta nu se va mai calcula dupa formule, etc ci se va scrie DIRECT*/
	/*Calculam Suma TVA doar pentru receptii*/
	update #documente
		set tva_deductibil=ISNULL(tva_deductibil_i,round(round((case when tip in ('AP','AS','AC') then pret_vanzare else round(isnull(pret_valuta,0)*(case when  valuta!='' then  curs else 1 end)
					*(case when (tip='RS' or isnull(numar_dvi,'')='') /*and jurnal<>'RC'*/ then 1+isnull(discount,0)/100 else 1 end),5) end)
					*isnull(cantitate,0),2)*Cota_TVA/100,2)) 
		where tva_deductibil=0 and cota_tva>0 and tert!='' or ptUpdate=1

	update #documente
		set tva_deductibil=0
		where tip in ('AP','AS','AC') and tip_tva='2' and tva_deductibil<>0 --Pentru tipul TVA 2 la vanzari = TVA NEINREGISTRAT se va lasa TVA-ul zero

	/*Calculam pretul de stoc - pentru cele care primesc pret de stoc egal cu zero, chiar si iesiri*/
	update d
	set pret_de_stoc=
		round(d.pret_valuta*(case when d.valuta!='' then d.curs else 1 end)
			*(case when d.discount<>0 and d.valuta='' and d.jurnal='RC' then 1/(1+d.cota_tva/100.00) else 1 end) -- TVA inversat la RC
			*(case when (d.tip='RS' or isnull(d.numar_dvi,'')='') and d.jurnal<>'RC' then 1+isnull(d.discount,0)/100 else 1 end) -- cota normala pe receptii
			+(case when d.tip in ('RM','RS') and d.tip_tva=3 then d.tva_deductibil/d.cantitate else 0 end),5) -- TVA nedeductibil in pret de stoc 
	from #documente d
	where d.tip in ('RM','RS') and (isnull(d.pret_de_stoc,0)=0 or d.ptUpdate=1)

	/*	
		Pare ca la RM si RS nu este necesar sa ia din nomenclator pret de stoc (mai sus un pic se ia pret_valuta=pret_stoc din nomencl, iar la update-ul anterior se ia pret_de_stoc functie de pret_valuta)
		Sub aceasta forma de update functioneaza corect si cazurile de la receptii cu cota de -100%.
	*/
	update d
		set pret_de_stoc=n.Pret_stoc
		from #documente d
		inner join nomencl n on d.cod=n.cod 
		left outer join stocuri s on d.gestiune=s.cod_gestiune and s.cod=d.cod and s.cod_intrare=d.cod_intrare
		where d.tip not in ('RM','RS') and isnull(d.pret_de_stoc,0)=0	
			and not (d.tip_miscare='E' and isnull(s.pret,1)=0 or d.tip_miscare='V' and n.tip='F')

	/*----------------------------------Formare cont de stoc---------------------------------*/
		/*Pasul 1 - Din gestiuni - cont contabil specific */
	update d set cont_de_stoc=g.Cont_contabil_specific
	from #documente d
	inner join gestiuni g on d.gestiune=g.cod_gestiune and g.Cont_contabil_specific!=''
	where nullif(d.cont_de_stoc,'') is null and (d.tip_miscare in ('I','E') or g.tip_gestiune='V')

	/*
		Acelasi algoritm il aplicam si la contul_corespondent in cazul transferului.
		Contul corespondent la transfer este in fapt un cont de intrare.
	
	*/
	update d set cont_corespondent=g.Cont_contabil_specific
	from #documente d
	inner join gestiuni g on d.gestiune_primitoare=g.cod_gestiune and g.Cont_contabil_specific!=''
	where d.tip='TE' and nullif(d.cont_corespondent,'') is null

	/*
		Acelasi algoritm il aplicam si la contul_intermediar in cazul AC-ului cu gestiune primitoare completata, validata in gestiuni si de tip A.
		Contul intermdiar la AC este in fapt un cont de intrare.
	*/
	update d set cont_intermediar=g.Cont_contabil_specific
	from #documente d
	inner join gestiuni g on d.gestiune_primitoare=g.cod_gestiune and g.Cont_contabil_specific!='' and g.Tip_gestiune='A'
	where d.tip='AC' and nullif(d.cont_intermediar,'') is null

		/*Pasul 2 - Din nomenclator combinat cu setari din parametrii*/
	if (select count(*) from #documente d where nullif(d.cont_de_stoc,'') is null)>0 or
		(select count(*) from #documente d where d.tip='TE' and nullif(d.cont_corespondent,'') is null)>0 or 
		(select count(*) from #documente d where d.tip='AC' and gestiune_primitoare<>'' and nullif(d.cont_intermediar,'') is null)>0
	begin
		/*Pentru valorice pot avea analitic loc de munca*/
		update d set cont_de_stoc=rtrim(n.Cont)+isnull((case when par.Val_logica=1 then '.'+left(d.loc_de_munca,(case when par.val_numerica>0 then par.Val_numerica else 13 end)) else '' end),'')
		from #documente d
		inner join nomencl n on d.cod=n.cod
		left outer join par on par.tip_parametru='GE' and par.parametru='CONTS'+(case when n.tip='R' then 'F' else 'P' end)
		where nullif(d.cont_de_stoc,'') is null and d.tip_miscare='V' /*Asta nu poate fi la transferuri de valorice*/

		/*Pentru cantitative*/
		select '30' as cont2,Val_logica as are_analitic,(case when Val_numerica>0 then Val_numerica else 9 end) as nrcar
		into #setcont
			from par where par.tip_parametru='GE' and par.parametru='CONTS'
		union all 
		select '34',Val_logica,(case when Val_numerica>0 then Val_numerica else 9 end)
			from par where par.tip_parametru='GE' and par.parametru='CONTPF'
		union all 
		select '37',Val_logica,(case when Val_numerica>0 then Val_numerica else 9 end)
			from par where par.tip_parametru='GE' and par.parametru='CONTM'
		/*union all 
		select '',Val_logica,(case when Val_numerica>0 then Val_numerica else 9 end)
			from par where par.tip_parametru='GE' and par.parametru='CONT3'*/

		update d set cont_de_stoc=rtrim(n.Cont)+isnull((case when sc.are_analitic=1 then '.'+left(d.gestiune,nrcar) else '' end),'')
		from #documente d
		inner join nomencl n on d.cod=n.cod
		left join #setcont sc on left(n.Cont,2)=sc.cont2
		where nullif(d.cont_de_stoc,'') is null

		/*	La Stornare avans, daca s-a completat factura de avans, caut in tabela facturi contul facturii de avans. Daca este, contul facturii de avans devine cont de stoc. 
			Tratat astfel pentru a nu se crea necorelatii de cont intre documente si facturi. */
		update d set cont_de_stoc=cont_de_tert
		from #documente d
		inner join nomencl n on d.cod=n.cod
		inner join facturi fa on fa.Subunitate=@subunitate and fa.Tip=(case when d.tip in ('RM','RS') then 0x54 else 0x46 end) and fa.Tert=d.Tert and fa.Factura=d.Cod_intrare and fa.cont_de_tert<>''
		inner join conturi c on c.Subunitate=@subunitate and c.cont=d.cont_de_stoc
		where (d.tip in ('RM','RS') and c.Sold_credit=1 and n.Tip='R' or d.tip in ('AP','AS') and c.Sold_credit=2 and n.Tip='S') and d.Cantitate<-0.001

		update d set cont_corespondent=rtrim(n.Cont)+isnull((case when sc.are_analitic=1 then '.'+left(d.gestiune_primitoare,nrcar) else '' end),'')
		from #documente d
		inner join nomencl n on d.cod=n.cod
		inner join #setcont sc on left(n.Cont,2)=sc.cont2
		where d.tip='TE' and nullif(d.cont_corespondent,'') is null

		update d set cont_intermediar=rtrim(n.Cont)+isnull((case when sc.are_analitic=1 then '.'+left(d.gestiune_primitoare,nrcar) else '' end),'')
		from #documente d
		inner join nomencl n on d.cod=n.cod
		inner join #setcont sc on left(n.Cont,2)=sc.cont2
		inner join gestiuni g on d.gestiune_primitoare=g.cod_gestiune and g.Cont_contabil_specific!='' and g.Tip_gestiune='A'
		where d.tip='AC' and nullif(d.cont_intermediar,'') is null

	end
	/*!!!!!!END---------------------Formare cont de stoc---------------------------------*/

	/*--------------------Formare cont intermediar--------------------------------------*/
	declare @cContCheltMarfuri varchar(40)
	select top 1 @cContCheltMarfuri=val_alfanumerica from par where tip_parametru='GE' and parametru='CCCMARFA'
	if @cContCheltMarfuri is null
		set @cContCheltMarfuri='601'

	update #documente set cont_intermediar='3'+substring(@cContCheltMarfuri,2,100)
	where tip='CM' and left(cont_de_stoc,3) in ('371','357') and tip_miscare='E'

	
	declare @cContIntermediarMateriale varchar(40)
	select top 1 @cContIntermediarMateriale =val_alfanumerica from par where tip_parametru='GE' and parametru='CINTMAT'
	if @cContIntermediarMateriale is null
		set @cContIntermediarMateriale ='371'

	update #documente set cont_intermediar=@cContIntermediarMateriale 
		where tip in ('AP','AC') and left(cont_de_stoc,2) not in ('33', '34', '35', '36', '37','80') and tip_miscare='E'

	/*!!!!!!END---------------------Formare cont intermediar---------------------------------*/
	
	/*--------------------Formare cont corespondent si cont venituri---------------------*/
	
	/*La predari*/
	update d set cont_corespondent=(case when left(d.cont_de_stoc,1)='8' then ''
				else isnull(p.val_alfanumerica,'711')+
					(case when p.Val_logica=1 then '.'+substring(d.cont_de_stoc,len(rtrim(c.cont_parinte)),13) else '' end)
				end)
	from #documente d
	left outer join par p on p.Tip_parametru='GE' and p.Parametru='CONTP'
	left join conturi c on d.cont_de_stoc=c.cont 
	where nullif(d.cont_corespondent,'') is null and (d.tip='PP' or d.tip='AI' and d.cont_de_stoc like '34%')
	
	/* 
	Pentru iesiri -	se va face o tabela de corespondente!!!
	*/
	declare @ct711 varchar(40)
	select @ct711=val_alfanumerica from par p where p.Tip_parametru='GE' and p.Parametru='CONTP'

	if exists(select 1 from sysobjects where name='formareContCorespondentDocSP')
		exec formareContCorespondentDocSP/*Aceasta procedura va pune valorile specifice pentru diverse conturi de stoc*/

	/*Primul pas corespondenta pe tip de document*/
	update #documente set cont_corespondent=dcc.cont_corespondent,
		cont_venituri=(case when #documente.tip in ('AP','AC') and isnull(#documente.cont_venituri,'')='' then dcc.cont_venituri else #documente.cont_venituri end)
	from 
		(select nrp,
			cc.cont_cheltuieli+
				(case when isnull(cc.analiticcs,0)=1 then substring(isnull(nullif(d.cont_intermediar,''),d.cont_de_stoc),len(cc.cont_de_stoc)+1,20)
						when isnull(cc.analiticg,0)=1 then '.'+ltrim(case when d.tip='AC' and d.gestiune_primitoare<>'' then d.gestiune_primitoare else d.gestiune end)
				else ''	end) as cont_corespondent,
			cc.cont_venituri+
				(case when isnull(cc.analiticcs,0)=1 then substring(isnull(nullif(d.cont_intermediar,''),d.cont_de_stoc),len(cc.cont_de_stoc)+1,20)
						when isnull(cc.analiticg,0)=1 then '.'+ltrim(case when d.tip='AC' and d.gestiune_primitoare<>'' then d.gestiune_primitoare else d.gestiune end) 
				else ''	end) as cont_venituri,
		row_number() over (partition by d.nrp order by cc.nrord) as ranc
		from #documente d
		left outer join ConfigurareContareIesiriDinGestiune cc on isnull(nullif(d.cont_intermediar,''),d.cont_de_stoc) like rtrim(cc.cont_de_stoc)+'%' and cc.tip=d.tip
		inner join nomencl n on n.cod=d.cod 
		where nullif(d.cont_corespondent,'') is null and (d.tip_miscare='E' or d.tip_miscare='V' and n.tip<>'S') and d.tip!='TE') dcc
	where #documente.nrp=dcc.nrp and dcc.ranc=1
		
	/*Al doilea pas corespondenta indiferenta de tip*/

	update #documente set cont_corespondent=dcc.cont_corespondent,
		cont_venituri=(case when #documente.tip in ('AP','AC') and isnull(#documente.cont_venituri,'')='' then dcc.cont_venituri else #documente.cont_venituri end)
	from 
		(select nrp,
			cc.cont_cheltuieli+
				(case when isnull(cc.analiticcs,0)=1 then substring(isnull(nullif(d.cont_intermediar,''),d.cont_de_stoc),len(cc.cont_de_stoc)+1,20)
						when isnull(cc.analiticg,0)=1 then '.'+ltrim(case when d.tip='AC' and d.gestiune_primitoare<>'' then d.gestiune_primitoare else d.gestiune end)
			else ''	end) as cont_corespondent,
			cc.cont_venituri+
				(case when isnull(cc.analiticcs,0)=1 then substring(isnull(nullif(d.cont_intermediar,''),d.cont_de_stoc),len(cc.cont_de_stoc)+1,20)
						when isnull(cc.analiticg,0)=1 then '.'+ltrim(case when d.tip='AC' and d.gestiune_primitoare<>'' then d.gestiune_primitoare else d.gestiune end) 
				else ''	end) as cont_venituri,
		row_number() over (partition by d.nrp order by cc.nrord) as ranc
		from #documente d
		left outer join ConfigurareContareIesiriDinGestiune cc on isnull(nullif(d.cont_intermediar,''),d.cont_de_stoc) like rtrim(cc.cont_de_stoc)+'%'
		inner join nomencl n on n.cod=d.cod 
		where nullif(d.cont_corespondent,'') is null and (d.tip_miscare='E' or d.tip_miscare='V' and n.tip<>'S') and d.tip!='TE') dcc
	where #documente.nrp=dcc.nrp and dcc.ranc=1


	if exists(select * from #documente where tip in ('DF','PF','CI','AF') and isnull(ptUpdate,0)=0) /* La Obiecte de inventar e altfel */
	begin
		declare @ct8039 varchar(40), @ctChelt varchar(40), @anCtChelt int, @ctUzura varchar(40), @anCtUzura varchar(40), @CtSalariati varchar(40), @cheltLaCasare int,	-- trecere ob. de inventar pe cheltuieli in momentul casarii
			@ObInvPeLocM int, @ObInvPeGestiuni int
		select top 1 @ct8039=rtrim(Val_alfanumerica) from par where tip_parametru='GE' and parametru='CONTLFO'
		select top 1 @ctChelt=rtrim(Val_alfanumerica), @anCtChelt=Val_numerica from par where tip_parametru='GE' and parametru='CONTCINV'
		select top 1 @ctUzura=rtrim(Val_alfanumerica), @anCtUzura=convert(int,Val_logica) from par where tip_parametru='GE' and parametru='CONTUZ'
		select top 1 @CtSalariati=rtrim(Val_alfanumerica) from par where tip_parametru='GE' and parametru='CONTDAS'
		select top 1 @cheltLaCasare=convert(int,Val_logica) from par where tip_parametru='GE' and parametru='TROICHCAS'
		select top 1 @ObInvPeLocM=convert(int,Val_logica) from par where tip_parametru='GE' and parametru='FOLLOCM'
		select top 1 @ObInvPeGestiuni=convert(int,Val_logica) from par where tip_parametru='GE' and parametru='FOLGEST'
		
		select @ct8039=isnull(nullif(@ct8039,''),'8039'), @ctChelt=isnull(nullif(@ctChelt,''),'603'), @ctUzura=isnull(nullif(@ctUzura,''),'603'), @CtSalariati=isnull(nullif(@CtSalariati,''),'4282')

		update #documente set 
		cont_de_stoc=@ct8039
		where tip='AF'

		update #documente set 
		cont_corespondent=(case when tip='DF' then @ct8039 
			when tip='AF' then (case when left(cont_de_stoc,1)='8' then '' else @ctUzura+(case when @anCtUzura=1 then substring(cont_de_stoc,4,17) else '' end) end)
			when tip='CI' then (case when left(cont_de_stoc,1)='8' then '' when @cheltLaCasare=1 then rtrim(@ctChelt)+(case when @anCtChelt=1 then substring(Cont_de_stoc,4,17) else '' end)
				 else @ctUzura+(case when @anCtUzura=1 then substring(cont_de_stoc,4,17) else '' end) end)  
			when tip='PF' then cont_de_stoc end) 
		where tip in ('DF','AF','PF','CI')

		update #documente set 
			cont_venituri=(case when left(cont_de_stoc,1)='8' then '' when left(cont_corespondent,1)<>'8' and @cheltLaCasare=1 then '' 
				else rtrim(@ctChelt)+(case when @anCtChelt=1 then substring(Cont_de_stoc,4,17) else '' end) end), 
			cont_intermediar=(case when left(cont_corespondent,1)<>'8' and @cheltLaCasare=1 then '' else @ctUzura+(case when @anCtUzura=1 then substring(cont_de_stoc,4,17) else '' end) end), 
			cont_factura=@CtSalariati
		where tip='DF'

		update #documente set codiPrim=isnull(nullif(codiPrim,''),'cinou')
		where tip in ('DF','PF')
		
		/*completare loc de munca cu cel al salariatului*/
		if @ObInvPeLocM=0 and @ObInvPeGestiuni=0
		begin
			update #documente set loc_de_munca=personal.loc_de_munca
			from #documente,personal
			where isnull(#documente.loc_de_munca,'')='' 
				and (tip='DF' and #documente.gestiune_primitoare=personal.marca or tip in ('AF','PF') and #documente.gestiune=personal.marca)
		end
	end
	/*!!!!!END-------------Gata Formare cont corespondent si cont venituri--------------------------------------*/
	/*----------------------------------------------------Formare cont factura---------------------------------*/

	declare @ContNesositReceptie varchar(40),@ContNesositAviz varchar(40)	--citit din parametrii
	select @ContNesositReceptie=isnull((case when parametru='CTFURECNE' then val_alfanumerica else @ContNesositReceptie end),'')
			,@ContNesositAviz=isnull((case when parametru='CTCLAVRT' then val_alfanumerica else @ContNesositAviz end),'')
	from par where tip_parametru='GE' and parametru in ('CTFURECNE','CTCLAVRT')
	if @ContNesositAviz='' set @ContNesositAviz='418' /*Nu vad unde se scrie in parametrii  - de discutat*/
	if @ContNesositReceptie='' set @ContNesositReceptie='408' /*Nu vad unde se scrie in parametrii - de discutat*/

	update #documente set cont_factura=
		(case when d.tip in ('AP','AS') then 
			(case when d.aviznefacturat=1 then @ContNesositAviz
				  when substring(d.numar_DVI, 14, 5)!='' then it.cont_in_banca3 
			else t.cont_ca_beneficiar end)
		else /*La intrari*/
			(case when d.facturanesosita=1 then @ContNesositReceptie
			else t.Cont_ca_furnizor end) end)
	from #documente d
	inner join terti t on d.tert=t.tert
	left outer join infotert it on d.tert=it.tert and it.identificator=substring(d.numar_DVI,14,5)
	where d.tip in ('AP','AS','RM','RS','RP','RZ') and cont_factura=''
	
	/*Completare cota TVA = 0, pentru documente fara factura in conditiile setarii [X]Ignorare inregistrare prin 4428 la receptii / avize fara factura.*/
	declare @ignor4428Document int, @CtDocFaraFact varchar(200)
	select @ignor4428Document=isnull((case when parametru='NEEXDOCFF' then val_logica else @ignor4428Document end),0),
		@CtDocFaraFact=isnull(nullif((case when parametru='NEEXDOCFF' then rtrim(val_alfanumerica) else @CtDocFaraFact end),''),'408,418')
	from par where Tip_parametru='GE' and Parametru in ('NEEXDOCFF')
	if @ignor4428Document=1
	begin
		if OBJECT_ID('tempdb..#ctdocfarafact') is not null 
			drop table #ctdocfarafact
		select c.cont into #ctdocfarafact
		from dbo.fSplit(@CtDocFaraFact,',') ff
		left outer join conturi c on c.subunitate=@subunitate and c.cont like rtrim(ff.string)+'%'

		update d set d.Cota_TVA=0, d.tva_deductibil=0
		from #documente d 
		left outer join #ctdocfarafact cdff on cdff.cont=d.cont_factura
		where isnull(ptUpdate,0)=0 and (tip in ('RM','RS') and facturanesosita=1 or tip in ('AP','AS') and aviznefacturat=1) and cdff.cont is not null
	end

	/*!!!!!END-------------Gata Formare cont factura----------------------------------------------------------*/
	
	update d set numar_pozitie=(case when d.numar_pozitie>0 then d.numar_pozitie else isnull(mp.maxpoz,0)+nrp end) /*NRP e pentru INTRARI numar_pozitie pentru IESIRI*/
	from #documente d
	left outer join  #maxPoz mp on d.tip=mp.tip and d.numar=mp.numar and d.data=mp.data

	update d set updatabile=1
	from #documente d
	inner join pozdoc p on p.subunitate=@subunitate and d.tip=p.tip and d.numar=p.numar and d.data=p.data and d.cod=p.cod and 
		(
			(d.tip_miscare='E' and d.cod_intrare=p.cod_intrare ) 
					or (d.tip_miscare='I' and d.cont_de_Stoc=p.cont_de_stoc and d.pret_de_stoc=p.pret_de_stoc and d.pret_cu_amanuntul=p.pret_cu_amanuntul)
		)
	where d.cerecumulare=1

	
	-- aici facem update direct pe pozdoc?
	update p set cantitate=p.cantitate+d.cantitate
	from #documente d
	inner join pozdoc p on p.subunitate=@subunitate and d.tip=p.tip and d.numar=p.numar and d.data=p.data and d.cod=p.cod and 
		(
			(d.tip_miscare='E' and d.cod_intrare=p.cod_intrare ) 
				or (d.tip_miscare='I' and d.cont_de_Stoc=p.cont_de_stoc and d.pret_de_stoc=p.pret_de_stoc and d.pret_cu_amanuntul=p.pret_cu_amanuntul)
		)
	where d.updatabile=1


	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuDocSP')
		exec wScriuDocSP @sesiune,@parXml output -- procedura care va modifica #documente

	/*---------------------------Formare cod intrare. Completam codul de intrare doar la intrari sau TI-------------------------*/
	declare @maxIdPozDoc int
	set @maxIdPozDoc=IDENT_CURRENT('pozdoc') - 1

	DBCC CHECKIDENT ("#documente", reseed, 1);
	
	update d set codiprim=d.tip+ltrim(str(@maxidPozDoc+d.nrp,9))
	from #documente d
	where d.tip in ('TE','DF','PF') and codiprim='cinou'

	update d set cod_intrare='AV'+replace(convert(char(8), data, 4) ,'.', '')
	from #documente d
	inner join nomencl n on d.cod=n.cod
	inner join conturi c on c.Cont=n.Cont
	where d.cod_intrare='' and (d.tip in ('RM', 'RS') and (c.Sold_credit=1) or (d.tip in ('AP', 'AS') and c.Sold_credit=2))

	update d set cod_intrare=d.tip+ltrim(str(@maxidPozDoc+d.nrp))
	from #documente d
	where d.cod_intrare='' and d.tip_miscare!='V'

	-- corectii finale
	update #documente set cont_factura='',cota_tva=0,tva_deductibil=0,tva_deductibil_i=0,cont_corespondent='',cont_intermediar=''
	where cont_de_stoc like '8%' and tip in ('RM','RS')

	update #documente set cont_corespondent=''
	where cont_corespondent is null and tip in ('RM','RS')

 -->Procesare diferente de curs la stornare avans in valuta. Conditionez diferente de curs de o mica verificare privind lucru cu valuta si miscari valorice cu cantititati negative.
 -->Conditia privind storno avansuri este cuprinsa in primul update care determina valoarea in valuta stornata (ca sa nu dublez conditia).
	if exists (select 1 from #documente d where d.valuta!='' and d.cantitate<0 and d.tip_miscare='V') 
	begin
		alter table #documente add val_valuta_storno float, cont_dif_av varchar(40), dif_curs_av float

		/*	Apelez procedura de calcul diferente de curs care apoi completeaza campul #documente.detalii. Aceeasi procedura este apelata si dinspre corectiiDocument pentru ASiSplus.*/
		exec pDifCursStornareAvans @sesiune=@sesiune, @parXML=@parXML
	end
		

	begin transaction wscriudoc
	/*Aici se aloca numar de document daca nu exista*/
	if exists (select 1 from #documente where isnull(numar,'')='')
	begin
		if (select count(distinct tip) from #documente where isnull(numar,'')='')>1
			raiserror('Nu se pot trimite mai multe tipuri cu numar de document necompletat!',16,1)
		
		declare 
			@fXML xml, @tipPentruNr varchar(2), @NrDocPrimit varchar(20),@lm varchar(20),@jurnal varchar(20),
			@NumarDocPrimit int,@idPlajaPrimit int,@nrdocumente int,@serieprimita varchar(20),@idplaja int,
			@asociereconfigurabila varchar(20)
		
		select top 1 
			@tipPentruNr=max(case when tip='RM' and jurnal='RC' then 'RC' else tip end),
			@lm=max(loc_de_munca),
			@jurnal=max(jurnal),
			@asociereconfigurabila =  max(asociereconf),
			@nrdocumente=max(pid)
		from #documente where isnull(numar,'')=''

		/*Daca se primeste un idPlaja explicit*/
		select top 1 
			@idplaja=max(idplaja), @data_document = max (data)
		from #documente

		set @fXML =  (select @tipPentruNr tip, @userASiS utilizator, @lm lm, @jurnal jurnal, @nrdocumente documente, @idplaja idplaja, @data_document data, @asociereconfigurabila asociereconf for xml raw)		

			
		exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocPrimit output,@Numar=@NumarDocPrimit output,@idPlaja=@idPlajaPrimit output,@serie=@serieprimita OUTPUT
			
		if @NrDocPrimit is null
			raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)
			
		if (select top 1 SerieInNumar from docfiscale where id=@idPlajaPrimit)=1
			update #documente set numar=@serieprimita+ltrim(str(@NumarDocPrimit+pid-1))
				where isnull(numar,'')=''
		else
			update #documente set numar=ltrim(str(convert(int,@NrDocPrimit)+pid-1))
				where isnull(numar,'')=''
		
		/* Indiferente de situatie: fie care s-a cerut dintr-o plaja, fie ca s-a dat automat determinand plaja, in #documente sa fie idplaja folosit 
			pt a salva mai jos rezervarea, in caz de eroare	*/
		update #documente set idplaja = @idPlajaPrimit		
	end

	update #documente set factura=numar where isnull(tert,'')!='' and isnull(factura,'')=''
	update #documente set lot='' where (tip_miscare='E' or tip_miscare='I' and cantitate<0) and lot<>''


	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuDocSP1')
		exec wScriuDocSP1 @sesiune,@parXml output -- procedura care poate modifica #documente imediat inainte de scriere (in tranzactie) 

	if isnull(@parXML.value('(/row/@numar)[1]', 'varchar(20)'),'')='' -- daca nu a venit completat
		if @parXML.value('(/row/@numar)[1]', 'varchar(20)') is not null                          
			set @parXML.modify('replace value of (/row/@numar)[1] with sql:variable("@NrDocPrimit")') 
		else
			set @parXML.modify ('insert attribute numar{sql:variable("@NrDocPrimit")} into (/row)[1]') 
	
	if (select count(*) from #documente where ptUpdate=1)>0 /*Se va modifica pozitia din tabela pozdoc*/
	begin
		if (select count(*) from #documente where idPozDoc is null)>0
			raiserror('Nu se poate face update fara idPozDoc',16,1)
		
		update pozdoc
		set utilizator=@userASiS,
		data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104), 
		ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')), 
		cod=isnull(#documente.Cod,pozdoc.cod),
		gestiune=isnull(#documente.gestiune,pozdoc.Gestiune),
		Cantitate=isnull(#documente.cantitate,pozdoc.Cantitate),
		Pret_valuta=isnull(#documente.Pret_valuta,pozdoc.Pret_valuta),
		Pret_de_stoc=isnull(#documente.pret_de_stoc,pozdoc.Pret_de_stoc),
		Pret_vanzare=isnull(#documente.Pret_vanzare,pozdoc.Pret_vanzare),
		Pret_cu_amanuntul=isnull(#documente.Pret_cu_amanuntul,pozdoc.Pret_cu_amanuntul),
		TVA_deductibil=isnull(#documente.TVA_deductibil,pozdoc.TVA_deductibil),
		Cota_TVA=isnull(#documente.Cota_TVA,pozdoc.Cota_TVA),
		Cod_intrare=isnull(#documente.Cod_intrare,pozdoc.Cod_intrare),
		Cont_de_stoc=isnull(#documente.Cont_de_stoc,pozdoc.Cont_de_stoc),
		Cont_corespondent=isnull(#documente.Cont_corespondent,pozdoc.Cont_corespondent),
		TVA_neexigibil=isnull(#documente.TVA_neexigibil,pozdoc.TVA_neexigibil),
		Pret_amanunt_predator=isnull(#documente.Pret_amanunt_predator,pozdoc.Pret_amanunt_predator),
		Locatie=isnull(#documente.Locatie,pozdoc.Locatie),
		Data_expirarii=isnull(#documente.Data_expirarii,pozdoc.Data_expirarii),
		Loc_de_munca=isnull(#documente.Loc_de_munca,pozdoc.Loc_de_munca),
		Comanda=isnull(#documente.Comanda,pozdoc.Comanda),
		Barcod=isnull(#documente.Barcod,pozdoc.Barcod),
		Cont_intermediar=isnull(#documente.Cont_intermediar,pozdoc.Cont_intermediar),
		Cont_venituri=isnull(#documente.Cont_venituri,pozdoc.Cont_venituri),
		Discount=isnull(#documente.Discount,pozdoc.Discount),
		Factura=isnull(#documente.Factura,pozdoc.Factura),
		Gestiune_primitoare =isnull(#documente.Gestiune_primitoare ,pozdoc.Gestiune_primitoare ),
		Numar_DVI=isnull(isnull((case when #documente.tip in ('AP','AS') then nullif(left(#documente.Numar_DVI,13),'') else #documente.Numar_DVI end),space(13))+(case when #documente.tip in ('AP','AS') then #documente.punctlivrare else '' end),pozdoc.Numar_DVI),
		--Grupa=isnull(#documente.Grupa,pozdoc.Grupa),
		Cont_factura=isnull(#documente.Cont_factura,pozdoc.Cont_factura),
		Valuta=isnull(#documente.Valuta,pozdoc.Valuta),
		Curs=isnull(#documente.curs,pozdoc.Curs),
		Data_facturii=isnull(#documente.Data_facturii,pozdoc.Data_facturii),
		Data_scadentei=isnull(#documente.Data_scadentei,pozdoc.Data_scadentei),
		Procent_vama=isnull(#documente.tip_tva,pozdoc.Procent_vama),
		Accize_cumparare=isnull(#documente.Categ_pret,pozdoc.Accize_cumparare),
		Jurnal=isnull(#documente.jurnal,pozdoc.Jurnal),
		detalii=isnull(#documente.detalii,pozdoc.detalii),
		lot=isnull(#documente.lot,pozdoc.lot),
		colet=isnull(#documente.colet,pozdoc.colet),
		idIntrare = isnull(#documente.idIntrare, pozdoc.idIntrare),
		idIntrareFirma = isnull(#documente.idIntrareFirma, pozdoc.idIntrareFirma)
		from #documente where pozdoc.idPozDoc=#documente.idpozdoc
	end
	else
		/*Restul pozitiilor se insereaza*/
		begin
		insert pozdoc
				(Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, 
				Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, 
				Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator, Tip_miscare, 
				Locatie, Data_expirarii, Numar_pozitie, Loc_de_munca, Comanda, Barcod, 
				Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
				Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, 
				Accize_cumparare, Accize_datorate, Contract, Jurnal,subtip,detalii,idIntrareFirma,idIntrare,lot,colet)
			OUTPUT inserted.idPozDoc, inserted.Numar_pozitie INTO #doc(idPozDoc, numar_pozitie)
			select
				@subunitate, d.Tip, d.Numar, Cod, d.Data, Gestiune, Cantitate, 
				Pret_valuta, 
				Pret_de_stoc, 
				0 as Adaos/*Nu se foloseste la nimic*/, 
				Pret_vanzare, 
				isnull(Pret_cu_amanuntul,0), --Poate fi null daca nu avem de unde da
				round(convert(decimal(15,3),TVA_deductibil),2), 
				ISNULL(Cota_TVA,0), 
				@userASiS, 
				convert(datetime, convert(char(10), getdate(), 104), 104), 
				RTrim(replace(convert(char(8), getdate(), 108), ':', '')), 
				Cod_intrare, Cont_de_stoc, Cont_corespondent, isnull(TVA_neexigibil,0), Pret_amanunt_predator, Tip_miscare, 
				Locatie, Data_expirarii, 
				d.numar_pozitie,
				Loc_de_munca, Comanda, Barcod, 
				Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, 
				isnull((case when d.tip in ('AP','AS') then nullif(left(d.Numar_DVI,13),'') else d.Numar_DVI end),space(13))+case when d.tip in ('AP','AS') then isnull(d.punctlivrare,'') else '' end as Numar_DVI, 
				Stare, 
				(case when d.tip in ('TE','DF','PF') then codiPrim else '' end) as Grupa,
				Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, tip_tva, 0, 
				isnull(d.Categ_pret,0), 0, Contract, Jurnal,subtip,detalii,idIntrareFirma,idIntrare,d.lot,d.colet
				from #documente d
				where isnull(d.updatabile,0)=0
				order by d.nrp

			update doc set 
				detalii=(case when d.detalii_antet IS NOT NULL then d.detalii_antet else doc.detalii end),
				idplaja=(case when @idPlajaPrimit IS NOT NULL then @idPlajaPrimit else isnull(doc.idplaja, d.idplaja) end)
			from #documente d
			inner join doc on d.tip=doc.Tip and d.numar=doc.Numar and d.data=doc.data

			/* Pentru bugetari se apeleaza procedura ce scrie in pozdoc.detalii, a indicatorului bugetar stabilit in mod unitar prin procedura indbugPozitieDocument. */
			if @bugetari='1' and exists (select 1 from #documente where isnull(ptUpdate,0)=0)
				and exists (select 1 from sysobjects where [type]='P' and [name]='indbugPozitieDocument')
			begin
				declare @parXMLIndbug xml
				IF OBJECT_ID('tempdb..#indbugPozitieDoc') is not null drop table #indbugPozitieDoc
				create table #indbugPozitieDoc (furn_benef char(1), tabela varchar(20), idPozitieDoc int, indbug varchar(20))
				insert into #indbugPozitieDoc (furn_benef, tabela, idPozitieDoc)
				select '', 'pozdoc', idpozdoc from #doc
				
				set @parXMLIndbug=(select 1 as scriere for xml raw)
				exec indbugPozitieDocument @sesiune=@sesiune, @parXML=@parXMLIndbug
			end

		end

		update #doc
			set idlinie=d.idlinie
		from #doc, #documente d
		where #doc.numar_pozitie=d.numar_pozitie

		IF EXISTS (select 1 from sysobjects where [type]='P' and [name]='wScriuDocSP2')
			exec wScriuDocSP2 @sesiune=@sesiune, @parXML=@parXML

		commit tran wscriudoc

		IF EXISTS (select 1 from sysobjects where [type]='P' and [name]='wScriuDocSP3')
			exec wScriuDocSP3 @sesiune=@sesiune, @parXML=@parXML


		/* Actualizam furnizori pe coduri (se "intretine" tabela PPRETURI)*/
		IF EXISTS (select 1 from #documente where tip='RM') and exists (select 1 from sysobjects where [type]='P' and [name]='wScriuFurnizoriArticol')
		begin
			declare @xml_furnizori xml

			set @xml_furnizori = (select DISTINCT tert, cod, pret_de_stoc pstoc, data datapret from #documente for xml raw, root('Date'))			
			exec wScriuFurnizoriArticol @sesiune=@sesiune, @parXML=@xml_furnizori
		end


		IF NOT EXISTS (select 1 from #documente where ptUpdate=1)
			SET @parXML = 
				(select top 1 @subunitate subunitate, tip, numar, data,
						(select d.idPozDoc, d.idlinie from #doc d for xml raw, root('docInserate'),type)
				from #documente
				for xml raw)				

END TRY

BEGIN CATCH
	declare @mesaj varchar(1000), @lenNumar int
	SET @mesaj = ERROR_MESSAGE()+' (wScriuDoc)'

	begin try
		IF EXISTS (select 1 from sysobjects where [type]='P' and [name]='wScriuDocSPEroare')
			exec wScriuDocSPEroare @sesiune=@sesiune, @parXML=@parXML
	end try
	begin catch
		set @mesaj=isnull(@mesaj, '')+' '+error_message()
	end catch

	begin try
		IF OBJECT_ID('tempdb.dbo.#documente') IS NOT NULL
			/* NU stricam numerele din plaja in caz de eroare	*/
			IF NOT EXISTS (select 1 from docfiscalerezervate dr JOIN #documente d on dr.idplaja=d.idplaja and dr.numar=d.numar and nullif(d.numar,'') is not null and isnumeric(d.numar)=1)
				INSERT INTO docfiscalerezervate (idplaja, numar, expirala)
				select d.idplaja, d.numar, getdate() from #documente d where nullif(d.idplaja,0) is not null and nullif(d.numar,'') is not null and isnumeric(d.numar)=1
					AND NOT EXISTS (select 1 from doc where Subunitate=@subunitate and tip=d.tip and numar=d.numar and Data=d.data)
	end try
	begin catch
		set @mesaj=isnull(@mesaj, '')+' '+error_message()
	end catch
		
	begin try	
		if error_number()=8152 --String or Binary data would be truncated
		BEGIN
			declare @mesaj2 varchar(2000)
			set @lenNumar=(SELECT min(clmns.max_length) FROM sys.tables AS tbl INNER JOIN sys.all_columns AS clmns ON clmns.object_id=tbl.object_id 
					where tbl.name='pozdoc' and clmns.name= 'numar') 

			IF OBJECT_ID('tempdb.dbo.#documente') IS NOT NULL
				if exists(select * from #documente where len(numar)>@lenNumar)
				BEGIN
					set @mesaj2='Numar de document mai mare de '+convert(varchar(3),@lenNumar)+' caractere!'
					raiserror(@mesaj2, 16,1)		
				END
		end
	end try
	begin catch
		set @mesaj=isnull(@mesaj, '')+' '+error_message()
	end catch

	begin try
		if @@trancount>0 and EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'wscriudoc')
			ROLLBACK TRAN wscriudoc
	end try
	
	begin catch
		set @mesaj=isnull(@mesaj, '')+' '+error_message()
	end catch

	RAISERROR (@mesaj, 16, 1)
END CATCH
