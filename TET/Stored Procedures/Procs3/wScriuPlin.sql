--***
create procedure  [dbo].[wScriuPlin] @sesiune varchar(50), @parXML xml OUTPUT
as
  
declare @sub varchar(9),@utilizator varchar(50),@LMutilizator varchar(50),@jurnalUtilizator varchar(3),@contUtilizator varchar(40),
	@CtAvFurn varchar(40),@ctAvBen varchar(40),@Bugetari int,@SugerareEfectUnicPeTert int,@DecontPeContMarca int, @NrDecont_Numar int,
	@detalii_antet xml,@detalii_pozitii xml
  
  -- numerotare (RE) si explicatii
  
--begin try  
 /*   
  Se trateaza doar situatia registrelor de casa si banca.  
  Crearea efectelor si decontarea avansurilor va fi tratata ulterior. Deocamdata ramane pe stilul vechi (nu se automatizeaza chiar asa multe).  
  Lucian: Am tratat si efectele/deconturile.
 */  
  
-- exemplu de apel:  
--declare @px xml  
--set @px='  
--<Date>  
-- <row cont="5311" data="2012-11-22">     
  --<row numar="23" tert="1" suma="5000000" subtip="PF"/>  
  --<row numar="24" tert="100" suma="3500" subtip="IB"/>  
  --<row numar="25"  suma="400" subtip="PD" contcorespondent="604"/>  
  --<row numar="23" tert="1" factura="23421" suma="608.57" subtip="PF"/>  
-- </row>     
--</Date>'  
  
--exec wScriuPlin '', @px  
  
-- Observatii:  
-- 1. Factura 23421 este luata si la spargere, desi este ceruta explicit achitarea la valoarea totala - cred ca ar trebui scris prima data in pozplin ce nu e de spart si apoi sa se faca spargerea  
-- 2. Factura <spatiu> nu este descarcata la nivelul soldului, ci la nivelul soldului facturii testtt   
  
begin try  
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPlinSP')  
		exec wScriuPlinSP @sesiune, @parXML output  
  
	if app_name() not like '%unipaas%'
		EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT  
	else
		select top 1 @Utilizator=rtrim(utilizator) from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
	
	select @utilizator=isnull(@utilizator,'')
	set @LMutilizator=isnull((select top 1 cod from lmfiltrare l where l.utilizator=@utilizator order by cod),'')
	set @jurnalUtilizator=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='JURNAL'), '')
	set @contUtilizator=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='CONTPLIN'), '')
	
	exec luare_date_par 'GE','SUBPRO',0,0,@sub output  
  
	exec luare_date_par 'GE','CFURNAV',0,0,@CtAvFurn output  
	if @ctAvFurn='' 
		set @ctAvFurn='409'  
  
	exec luare_date_par 'GE','CBENEFAV',0,0,@CtAvBen output  

	exec luare_date_par 'GE','BUGETARI', @Bugetari output, 0, ''
	exec luare_date_par 'GE','SEFUNTERT', @SugerareEfectUnicPeTert output, 0, ''
	exec luare_date_par 'GE','DECMARCT', @DecontPeContMarca output, 0, ''
	exec luare_date_par 'GE','NRDECNR', @NrDecont_Numar output, 0, ''
	
	if @ctAvBen=''  
		set @ctAvBen='419'  
  
/* exec luare_date_par 'GE','REPSUMEF',0,@RepSumeF output,''  
 exec luare_date_par 'GE','EXCEP419',@ExcepAv output,0,''  
  if @ctAvFurn='' set @CtAvFurn='409'  
 if @CtAvBen='' set @CtAvBen='419'  
*/  
  
  
	create table #datecitite  
	 (  
		idPozPlin int,
		nrp int,  
		nrmin int,  
		nrmax int,  
		cumulat float,
		tip_antet varchar(20),
		subunitate varchar(9),
		jurnal varchar(3),
		cont varchar(40),
		data datetime,
		numar varchar(20),
		plata_incasare char(2),
		tert varchar(20),
		factura varchar(20),
		cont_corespondent varchar(40),
		suma decimal(12,2),
		valuta varchar(6),
		curs decimal(12,4),
		suma_valuta decimal(12,2),
		cota_tva decimal(12,2), --Campul tva_11 din pozplin  
		suma_tva decimal(12,2), --Campul tva_22 din pozplin  
		explicatii varchar(50),
		loc_de_munca varchar(20),
		comanda varchar(20),
		indbug varchar(20),
		nr_pozitie_primit int,
		cont_dif varchar(40),
		suma_dif decimal(12,2),  
		detalii xml,
		detalii_antet xml,
		tip_tva int,
		marca varchar(6),
		decont varchar(40),
		efect varchar(20),
		achitat decimal(12,2),  
		_de_spart int,  
		_update int,  
		suma_de_spart float,
		subtip varchar(2)
	)  
   
   
	declare @iDoc int,@rootDoc varchar(20),@multiDoc int  
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML  
	
	if @parXML.exist('(/Date)')=1 --Daca exista parametrul Date inseamna ca avem date multiple de introdus in tabela  
	begin  
		set @rootDoc='/Date/row/row'  
		set @multiDoc=1  
	end  
	else  
	begin  
		set @rootDoc='/row/row'  
		set @multiDoc=0  
	end  

	/*citire date din parametru xml primit*/
	insert into #datecitite(idPozPlin,tip_antet,subunitate,cont,data,numar,plata_incasare,tert,factura,cont_corespondent,suma,valuta,curs,suma_valuta,nr_pozitie_primit,  
		cota_tva,suma_tva,explicatii,loc_de_munca,comanda,indbug,cont_dif,suma_dif,achitat,_de_spart,_update,jurnal,detalii,detalii_antet,tip_tva,marca,decont,efect,suma_de_spart, subtip)  
	select  isnull(idPozPlin,0),tip_antet,@sub,isnull(nullif(cont_pozitii,''),isnull(nullif(cont_antet,''),'')) as cont,isnull(data_pozitii,data_antet),numar,subtip,
		isnull(tert_pozitii,tert_antet),factura,cont_corespondent,suma,isnull(nullif(valuta,''),isnull(valuta_antet,'')),isnull(nullif(curs,0),isnull(curs_antet,0)),suma_valuta,numar_pozitie_primit,  
		cota_tva,suma_tva,explicatii,lm,comanda,isnull(indbug,''),isnull(cont_dif,'') as cont_dif,0 as suma_dif,0 as achitat,  
		(case when subtip in ('PF','PV','IB','IV','PS','IS') and ISNULL(factura,'')='' then 1 else 0 end), _update,isnull(jurnal,''),detalii as detalii, detalii_antet as detalii_antet, 
		isnull(tiptva,0) as tip_tva,isnull(nullif(marca_pozitii,''),nullif(marca_antet,'')) as marca,isnull(nullif(decont_pozitii,''),nullif(decont_antet,'')) as decont,
		isnull(nullif(efect_pozitii,''),nullif(efect_antet,'')) as efect,(case when suma_valuta>0 and valuta!='' then suma_valuta else suma end) as suma_de_spart , subtip
	from OPENXML(@iDoc, @rootDoc)  
	WITH   
	(  
		detalii_antet xml '../detalii/row',
		detalii xml 'detalii/row',
		tip_antet char(2) '../@tip',
		cont_antet varchar(40) '../@cont',
		data_antet datetime '../@data',
		marca_antet char(6) '../@marca',
		decont_antet varchar(40) '../@decont',
		tert_antet char(13) '../@tert',
		efect_antet varchar(20) '../@efect',
		valuta_antet char(3) '../@valuta',   
		curs_antet float '../@curs',   

		idPozPlin int '@idPozPlin',
		cont_pozitii varchar(40) '@cont',
		data_pozitii datetime '@data',
		marca_pozitii char(6) '@marca',   
		decont_pozitii varchar(40) '@decont',   
		tert_pozitii char(13) '@tert',
		efect_pozitii varchar(20) '@efect',   
		subtip char(2) '@subtip',   
		numar char(10) '@numar',   
		factura char(20) '@factura',   
		cont_corespondent varchar(40) '@contcorespondent',   
		suma float '@suma',   
		valuta char(3) '@valuta',   
		curs float '@curs',   
		suma_valuta float '@sumavaluta',   
		cota_TVA float '@cotatva',   
		suma_TVA float '@sumatva',   
		explicatii char(50) '@explicatii',   
		lm char(9) '@lm',   
		comanda char(20) '@comanda',   
		indbug char(20) '@indbug',   
		numar_pozitie_primit int '@numarpozitie',   
		cont_dif varchar(40) '@contdif',
		jurnal char(3) '@jurnal',   
		tipTVA int '@tipTVA',   
		_update bit '@update',  		
		ext_datadocument datetime '@ext_datadocument'--data la care beneficiarul a facut plata(se ia in calcul la calculul penalitatilor). Se va lua din detalii.
	)  
	exec sp_xml_removedocument @iDoc   
	
	/*
		Validari deconturi
		1. Sa nu difere valuta din antet de valuta decontului
		2. Sa nu se opereze suma daca decontul este in valuta
		3. Sa nu se opereze suma_valuta daca decontul este in lei
	*/
	if exists(select 1 from #datecitite t 
			inner join conturi d on d.subunitate=t.subunitate and t.tip_antet not in ('DE','DR') and d.cont=t.cont and d.sold_credit=9)
		raiserror('Operati deconturi de pe tipul "Deconturi"!',16,1)

	if exists(select 1 from #datecitite t 
			inner join conturi c on c.subunitate=t.subunitate and c.cont=t.cont_corespondent and c.sold_credit=9 and t.subtip='IA' and isnull(t.decont,'')='')
		raiserror('Numar decont necompletat!',16,1)

	if exists(select 1 from #datecitite t 
			inner join deconturi d on d.subunitate=t.subunitate and t.tip_antet='DE' and t.marca=d.marca and t.decont=d.decont where isnull(t.valuta,'')!=isnull(d.valuta,''))
		raiserror('Valuta diferita de valuta decontului ales!',16,1)

	if exists(select 1 from #datecitite where tip_antet='DE' and isnull(valuta,'')!='' and suma != 0 and isnull(_update,0)=0)
		raiserror('Suma decontului trebuie sa fie in valuta!',16,1)

	if exists(select 1 from #datecitite where tip_antet='DE' and isnull(valuta,'')='' and suma_valuta != 0 and isnull(_update,0)=0)
		raiserror('Suma decontului trebuie sa fie in lei!',16,1)

	-- Recalculare suma in lei la update pentru deconturile in valuta
	if exists(select 1 from #datecitite where tip_antet='DE' and isnull(valuta,'')!='' and suma_valuta != 0 and isnull(_update,0)=1)
		update #datecitite
		set suma=suma_valuta*curs
		where tip_antet='DE' and isnull(valuta,'')!='' and suma_valuta != 0 and isnull(_update,0)=1

	/*
		Validari plata avans
		1. Sa nu se opereze suma daca valuta este completata in antet
		2. Sa nu se opereze suma_valuta daca valuta nu este completata in antet
	*/
	if exists(select 1 from #datecitite where tip_antet='RE' and plata_incasare='PX' and isnull(valuta,'')!='' and suma != 0  and isnull(_update,0)=0)
		raiserror('Suma trebuie sa fie in valuta!',16,1)

	if exists(select 1 from #datecitite where tip_antet='RE' and plata_incasare='PX' and isnull(valuta,'')='' and suma_valuta != 0  and isnull(_update,0)=0)
		raiserror('Suma trebuie sa fie in lei!',16,1)

-->	Formare detalii (din antet si pozitii) care se vor salva in pozplin.detalii (in special efecte).
	select @detalii_antet=convert(xml,convert(varchar(max),detalii_antet)), @detalii_pozitii=convert(xml,convert(varchar(max),detalii))
	from #datecitite
	where tip_antet='EF' and detalii_antet is not null --and detalii is not null
	if @detalii_antet is not null 
		exec adaugaAtributeXml @xmlSursa=@detalii_pozitii, @xmlDest=@detalii_antet output, @debug=0, @extrageDetalii=0

-->	am mutat aici urmatoarele 2 update-uri de mai jos intrucat contul este utilizat la stabilire numar maxim de pozitii
-->	Lucian: pentru cazul deconturilor, la decontarea lor (PF=Plata furnizor, PC=Plata TVA, PD Plata diverse), contul, locul de munca le luam din deconturi
	update d set d.Cont=isnull((case when isnull(d.Cont,'')='' then de.Cont else d.Cont end),'542'),
		loc_de_munca=isnull((case when isnull(d.loc_de_munca,'')='' then de.Loc_de_munca else d.Loc_de_munca end),p.loc_de_munca)
	from #datecitite d	
		left join deconturi de on de.Subunitate=d.Subunitate and de.Tip='T' and de.marca=d.marca and de.Decont=d.Decont 
		left join personal p on d.marca=p.marca
		--Cristy: Pus left join si cont implicit 542 daca nu este decontul respectiv
	where isnull(d.decont,'')<>'' and (isnull(d.Cont,'')='' or isnull(d.Loc_de_munca,'')='') and d.Plata_incasare like 'P%'-- in ('PF','PC','PD','PV')

-->	Lucian: pentru cazul efectelor (la introducerea lor), contul il completam (daca este necompletat) cu 403/413 functie de subtip.
	update d set d.Cont=(case when d.Plata_incasare='PF' then '403' else '413' end)
	from #datecitite d	
	where tip_antet='EF' and isnull(d.Efect,'')<>'' and isnull(d.Cont,'')='' and d.Plata_incasare in ('PF','IB') 

--	Lucian: inserez in cazul deconturilor/efectelor in @parXML contul completat mai sus (daca nu s-a completat nu functioneaza corect wIaPozplin)
--	Poate ar fi si varianta cu docInserate si in wScriuPozplin sa citim contul din docInserate. De discutat cu Cristy.
	if isnull(@parXML.value('(/row/@cont)[1]', 'varchar(40)'),'')='' 
		and exists (select 1 from #datecitite where tip_antet in ('EF','DE') and cont<>'') 
	begin
		declare @cont varchar(40)
		select @cont=max(cont) from #datecitite
		if @parXML.value('(/row/@cont)[1]', 'varchar(40)') is not null
			set @parXML.modify('replace value of (/row/@cont)[1] with sql:variable("@cont")') 
		else
			set @parXML.modify ('insert attribute cont {sql:variable("@cont")} into (/row)[1]') 		
	end

  /*In tabela temporara #nrpozitii fac join pe pozplin doar pentru documentele de adaugat (de regula unul) pentru a lua numarul maxim de pozitii*/  
	select p1.subunitate,p1.cont,p1.data,isnull(max(p2.numar_pozitie),0) as maxpoz  
	into #nrpozitii  
	from #datecitite p1  
		left outer join pozplin p2 on p1.Subunitate=p2.Subunitate and p1.cont=p2.cont and p1.Data=p2.Data 
	group by p1.subunitate,p1.cont,p1.data

 /* de aici incepe spargerea pe facturi */  
	update #datecitite set nrp=ranc  
	from   
		(select p2.subunitate,p2.plata_incasare,p2.cont,p2.numar,p2.data,  
		ROW_NUMBER() over (partition by p2.tert,left(p2.plata_incasare,1) order by p2.tert,p2.data) as ranc  
		from #datecitite p2) p1   
	where p1.subunitate=#datecitite.subunitate and p1.cont=#datecitite.cont and p1.numar=#datecitite.numar 
		and p1.data=#datecitite.data and left(p1.plata_incasare,1)=left(#datecitite.plata_incasare,1)  
		and _de_spart=1   
  
	select convert(float,0) as cumulat,ROW_NUMBER() OVER (PARTITION BY f.tert,F.TIP ORDER BY f.tert,F.TIP,F.DATA_SCADENTEI) as nrp,  
		(case when f.tip=0x46 then 'I' else 'P' end) as tipfact,f.tert,f.factura,(case when f.valuta!='' then f.sold_valuta else f.sold end) as sold,
		f.loc_de_munca,substring(f.comanda,1,20) as comanda,substring(f.comanda,21,20) as indbug,f.cont_de_tert,f.valuta,f.curs  
	into #facturi  
	from facturi f  
		inner join (select tert, valuta from #datecitite where _de_spart=1 group by tert,valuta) p 
			on f.tert=p.tert and f.Valuta=p.valuta 
	where f.sold>0  
		and not exists(select 1 from #datecitite d where d.factura=f.Factura and d.tert=f.Tert 
			and ((f.Tip=0x46 and left(d.plata_incasare,1)='I') or (f.Tip=0x54 and left(d.plata_incasare,1)='P')))
	order by f.tip,f.Data_scadentei  
   
	insert into #facturi  
	select 999999999 as cumulat,99999999 as nrord,'P' as tipfact,p.tert,'AVANS' as factura,999999999,
		'' as loc_de_munca,'' as comanda,'' as indbug,@ctAvFurn,valuta,max(curs)  
	from #datecitite p   
	where _de_spart=1  
	group by tert, valuta  
	union all 	
	select 999999999 as cumulat,99999999 as nrord,'I' as tipfact,p.tert,'AVANS' as factura,999999999,
		'' as loc_de_munca,'' as comanda,'' as indbug,@ctAvBen,valuta,max(curs)  
	from #datecitite p   
	where _de_spart=1  
	group by tert, valuta  
  
	update #facturi set   
		cumulat=facturicalculate.cumulat  
	from (select p2.tert,p2.tipfact,p2.nrp,p2.valuta,sum(p1.sold) as cumulat 
		from #facturi p1,#facturi p2 
		where p1.tert=p2.tert and p1.tipfact=p2.tipfact and p1.valuta=p2.valuta and p1.nrp<=p2.nrp   
		group by p2.tert,p2.tipfact,p2.valuta,p2.nrp) facturicalculate  
	where facturicalculate.tert=#facturi.tert and facturicalculate.tipfact=#facturi.tipfact 
		and facturicalculate.nrp=#facturi.nrp and facturicalculate.valuta=#facturi.valuta  
  
	update #datecitite set   
		cumulat=pozplincalculata.cumulat  
	from (select p2.tert,p2.plata_incasare,p2.nrp,p2.valuta,sum(p1.suma_de_spart) as cumulat 
		from #datecitite p1,#datecitite p2 
		where p1.tert=p2.tert and p1.plata_incasare=p2.plata_incasare and p1.valuta=p2.valuta and p1.nrp<=p2.nrp   
			and p1._de_spart=1 and p2._de_spart=1   
		group by p2.tert,p2.plata_incasare,p2.valuta,p2.nrp) pozplincalculata  
	where pozplincalculata.tert=#datecitite.tert and pozplincalculata.plata_incasare=#datecitite.plata_incasare 
		and pozplincalculata.valuta=#datecitite.valuta and pozplincalculata.nrp=#datecitite.nrp  
		and #datecitite._de_spart=1   
  
	update #datecitite set nrmin=st.nrp,nrmax=dr.nrp  
	from #datecitite c  
		cross apply (  
			select top 1 smin.nrp from #facturi smin 
			where smin.tert=c.tert and smin.valuta=c.valuta and smin.tipfact=left(c.plata_incasare,1) 
				and c.cumulat-c.suma_de_spart<smin.cumulat 
			order by smin.cumulat) st   
		cross apply (  
			select top 1 smax.nrp from #facturi smax 
			where smax.tert=c.tert and smax.valuta=c.valuta and smax.tipfact=left(c.plata_incasare,1) and c.cumulat<=smax.cumulat 
			order by smax.cumulat) dr  
	where c._de_spart=1   
  
	update #datecitite set nrmin=nrmax where nrmin>nrmax and _de_spart=1   
	/* pana aici a fost spargerea pe facturi */  
  
	CREATE TABLE [dbo].[#descris]( 
		[idpozPlin] [int],
		[Subunitate] [varchar](9) NOT NULL,
		[Cont] [varchar](20) NOT NULL,
		[Data] [datetime] NOT NULL,
		[Numar] [varchar](10) NULL,
		[Plata_incasare] [varchar](2) NOT NULL,
		[Tert] [varchar](13) NOT NULL,
		[Factura] [varchar](20) NOT NULL,
		[Cont_corespondent] [varchar](20) NOT NULL,
		[Suma] [float] NOT NULL,
		[Valuta] [varchar](3) NOT NULL,
		[Curs] [float] NOT NULL,
		[Suma_valuta] [float] NOT NULL,
		[Curs_la_valuta_facturii] [float] NOT NULL,
		[TVA11] [float] NOT NULL,
		[TVA22] [float] NOT NULL,
		[Explicatii] [varchar](50) NOT NULL,
		[Loc_de_munca] [varchar](9) NOT NULL,
		[Comanda] [char](20) NOT NULL,
		[Indbug] [char](20) NOT NULL,
		[Utilizator] [varchar](10) NOT NULL,
		[Data_operarii] [datetime] NOT NULL,
		[Ora_operarii] [varchar](6) NOT NULL,
		[Numar_pozitie] [int] NOT NULL,
		[Cont_dif] [varchar](20) NOT NULL,
		[Suma_dif] [float] NOT NULL,
		[Achit_fact] [float] NOT NULL,
		[Jurnal] [varchar](20) NOT NULL,
		[Detalii] [xml],
		[Tip_tva] [int] NOT NULL,
		[Marca] [varchar](6),
		[Decont] [varchar](20),
		[Efect] [varchar](20),
		tip_fact binary(1),
		[Cont_dif_dec] [varchar](20),
		[Dif_curs_dec] [float],
		_update int,
		subtip varchar(2)
	)  
    
 /*   
  Urmeaza scrierea in pozplin via #descris  
 */  
	insert into #descris(idpozPlin,Subunitate,Cont,Data,Numar,Plata_incasare,Tert,Factura,Cont_corespondent,Suma,  
		Valuta,Curs,Suma_valuta,Curs_la_valuta_facturii,TVA11,TVA22,Explicatii,Loc_de_munca,Comanda,Indbug,
		Utilizator,Data_operarii,Ora_operarii,  
		Numar_pozitie,Cont_dif,Suma_dif,Achit_fact,Jurnal,Detalii,Tip_tva,Marca,Decont,Efect, tip_fact,Cont_dif_dec,Dif_curs_dec,_update, subtip)
	select  pd.idPozPlin,@sub,pd.cont,pd.data,pd.numar,pd.plata_incasare,fc.tert,fc.factura,fc.cont_de_tert,  
		(case   
			when pd.nrmin=pd.nrmax or pd.suma_de_spart<0   
			then pd.suma_de_spart  
			when pd.nrmin=fc.nrp--prima linie de pe stoc  
			then pd.suma_de_spart-(pd.cumulat-fc.cumulat)  
			when pd.nrmax=fc.nrp--ultima linie de pe stoc  
			then (pd.cumulat+fc.sold-fc.cumulat)  
		else fc.sold  
		end) as sumadescris,  
		fc.valuta,isnull(pd.curs,0),  
		(case   
			when pd.nrmin=pd.nrmax or pd.suma_de_spart<0   
			then pd.suma_de_spart  
			when pd.nrmin=fc.nrp--prima linie de pe stoc  
			then pd.suma_de_spart-(pd.cumulat-fc.cumulat)  
			when pd.nrmax=fc.nrp--ultima linie de pe stoc  
			then (pd.cumulat+fc.sold-fc.cumulat)  
		else fc.sold  
		end),  
		isnull(fc.curs,pd.curs),isnull(pd.cota_tva,0),isnull(pd.suma_tva,0),isnull(nullif(pd.explicatii,''),pd.plata_incasare+' - '+isnull(t.denumire,'')),
		isnull(pd.loc_de_munca,isnull(fc.loc_de_munca,'')),isnull(pd.comanda,isnull(fc.comanda,'')),isnull(pd.indbug,isnull(fc.indbug,'')),  
		@utilizator,convert(datetime, convert(char(10), getdate(), 104), 104),RTrim(replace(convert(char(8), getdate(), 108), ':', '')),  
		ROW_NUMBER() OVER (partition by pd.cont,pd.data,pd.numar order by pd.nr_pozitie_primit) as numar_pozitie_calculat,pd.cont_dif,pd.suma_dif,0,pd.jurnal,
		(case when @detalii_antet is not null then @detalii_antet else pd.detalii end),isnull(pd.Tip_tva,0),pd.Marca,pd.Decont,pd.Efect,
		(case when pd.plata_incasare like 'I%' and pd.plata_incasare<>'IS' or pd.plata_incasare='PS' then 0x46 else 0x54 end),'',0,
		pd._update,
		pd.subtip
	from #datecitite pd  
		left outer join #facturi fc on pd.tert=fc.tert and pd.valuta=fc.valuta and left(pd.plata_incasare,1)=fc.tipfact and fc.nrp between pd.nrmin and pd.nrmax  
		left outer join terti t on pd.tert=t.tert and t.Subunitate=pd.subunitate
	where pd._de_spart=1  
	union all  
	select   
		idPozPlin,@sub,pd.cont,pd.data,pd.numar,pd.plata_incasare,isnull(pd.tert,''),isnull(pd.factura,''),isnull(nullif(pd.cont_corespondent,''),isnull(f.Cont_de_tert,'')),  
		isnull((case when isnull(pd.suma,0)=0 then f.Sold else pd.suma end),0),  
		isnull(pd.valuta,''),isnull(pd.curs,0),isnull((case when isnull(pd.valuta,'')<>'' and isnull(pd.suma_valuta,0)=0 then f.Sold_valuta else pd.suma_valuta end),0),
		0,isnull(pd.cota_tva,0),isnull(pd.suma_tva,0),
		isnull(nullif(pd.explicatii,''),pd.plata_incasare+' - '+isnull(rtrim(isnull(t.denumire,isnull(p.Nume,cc.Denumire_cont/*pd.cont_corespondent*/))),'')),	--	am pus denumire cont coresp.
		isnull(nullif(pd.loc_de_munca,''),isnull(f.loc_de_munca,'')),isnull(nullif(pd.comanda,''),isnull(substring(f.Comanda,1,20),'')),isnull(pd.indbug,isnull(substring(f.Comanda,21,20),'')),
		@utilizator,convert(datetime, convert(char(10), getdate(), 104), 104),RTrim(replace(convert(char(8), getdate(), 108), ':', '')),  
		ROW_NUMBER() OVER (partition by pd.cont,pd.data order by pd.nr_pozitie_primit),pd.cont_dif,pd.suma_dif,0,pd.jurnal,
		(case when @detalii_antet is not null then @detalii_antet else pd.detalii end),isnull(pd.Tip_tva,0),pd.Marca,pd.Decont,pd.Efect,
		(case when pd.plata_incasare like 'I%' and pd.plata_incasare<>'IS' or pd.plata_incasare='PS' then 0x46 else 0x54 end),'',0,pd._update,
		pd.subtip
	from #datecitite pd  
		left outer join facturi f on pd.tert=f.tert and pd.factura=f.factura and pd.subunitate=f.Subunitate 
			and f.tip=(case when pd.plata_incasare like 'I%' and pd.plata_incasare<>'IS' or pd.plata_incasare='PS' then 0x46 else 0x54 end)
		left outer join terti t on t.Tert=pd.tert and t.Subunitate=pd.subunitate 
		left outer join personal p on p.Marca=pd.marca
		left outer join conturi cc on cc.Subunitate=pd.Subunitate and cc.Cont=pd.Cont_corespondent
	where _de_spart=0  
   
-->Prelucrari pentru tabela de scris  
-->	Lucian: pentru cazul deconturilor, la decontarea lor (PF=Plata furnizor, PC=Plata TVA, PD Plata diverse), 
-->	Suma o luam din deconturi daca nu s-a completat (la PF se completeaza cu soldul facturi mai sus)
	update d set d.Suma=isnull((case when isnull(d.Suma,0)=0 then de.Sold else d.Suma end),0)
	from #datecitite d	
		inner join deconturi de on de.Subunitate=d.Subunitate and de.Tip='T' and de.marca=d.marca and de.Decont=d.Decont 
	where isnull(d.decont,'')<>'' and d.Plata_incasare in ('PF','PC','PD')

-->	Lucian: pentru cazul deconturilor (la PA=Plata decont, in cazul in care se face plata pe un decont existent sau IA=restituire decont), contul corespondent si locul de munca il luam din deconturi
	update d set d.Cont_corespondent=isnull((case when isnull(d.Cont_corespondent,'')='' then de.Cont else d.Cont_corespondent end),''), 
		d.loc_de_munca=isnull((case when isnull(d.loc_de_munca,'')='' then de.Loc_de_munca else d.Loc_de_munca end),'')
	from #descris d	
		inner join deconturi de on de.Subunitate=d.Subunitate and de.Tip='T' and de.marca=d.marca and de.Decont=d.Decont 
	where isnull(d.decont,'')<>'' and (isnull(d.Cont_corespondent,'')='' or isnull(d.Loc_de_munca,'')='') and d.Plata_incasare in ('PA','IA')

-->	Lucian: in caz implicit de plata avans, contul corespondent sa fie 542 (daca este necompletat)
	update d set Cont_corespondent='542'
	from #descris d	
	where isnull(d.Cont_corespondent,'')='' and d.Plata_incasare='PA' --and isnull(d.decont,'')<>''

-->	Lucian: pentru cazul efectelor (la decontarea acestora), contul corespondent il luam din efecte
	update d set d.Cont_corespondent=e.Cont, d.Suma=isnull((case when isnull(d.Suma,0)=0 then e.Sold else d.Suma end),0), 
		d.loc_de_munca=isnull((case when isnull(d.loc_de_munca,'')='' then e.Loc_de_munca else d.Loc_de_munca end),'')
	from #descris d	
		inner join efecte e on e.Subunitate=d.Subunitate and e.Tip=(case when d.Plata_incasare='IE' then 'I' else 'P' end) 
			and e.Tert=d.Tert and e.Nr_efect=d.Efect
	where isnull(d.Efect,'')<>'' and isnull(d.Cont_corespondent,'')='' and d.Plata_incasare in ('PE','IE','IY') 

-->	daca se efectueaza o plata avans catre o marca, atunci se ia locul de munca corespunzator marcii respective
	update d set d.Loc_de_munca=p.Loc_de_munca
	from #descris d	
		inner join personal p on p.marca=d.marca
	where isnull(d.Loc_de_munca,'')='' and d.Plata_incasare in ('PA','PD') --and isnull(d.decont,'')<>''	--	tratat sa aduca si pentru PD locul de munca al marcii daca este necompletat.

-->	daca se lucreaza cu proprietatea LOCMUNCA asociata utilizatorului, completam locul de munca pe doc. cu cel asociat utilizatorului
	update d set d.Loc_de_munca=@LMutilizator
	from #descris d	
	where isnull(d.Loc_de_munca,'')='' and isnull(@LMutilizator,'')<>''

-->	daca se lucreaza cu proprietatea CONTPLIN asociata utilizatorului, completam contul pe doc. cu cel asociat utilizatorului
	update d set d.Cont=@contUtilizator
	from #descris d	
	where isnull(d.Cont,'')='' and isnull(@contUtilizator,'')<>''

-->	daca se lucreaza cu proprietatea JURNAL asociata utilizatorului, completam jurnalul pe doc. cu cel asociat utilizatorului
	update d set d.Jurnal=@jurnalUtilizator
	from #descris d	
	where isnull(d.Jurnal,'')='' and isnull(@jurnalUtilizator,'')<>''

-->	pentru cazuri in care se fac plati/incasari reprezentand avansuri (daca suntem pe subtip de avans), contul corespondent se va lua din parametrii, iar factura se da automat (dupa regula din wScriuPozplin).
	update d set Cont_corespondent=(case when d.plata_incasare like 'I%' then @ctAvBen else @CtAvFurn end), factura=nf.nr_urm
	from #descris d	
		outer apply (select top 1 'AV'+convert(varchar(20),isnull(max(convert(int,convert(decimal(10),substring(rtrim(ltrim(factura)),3,len(rtrim(ltrim(factura)))-2)))),0)+1) as nr_urm
			from facturi f
			where f.subunitate=d.subunitate and f.tert=d.tert and f.factura like 'AV%' and isnumeric(substring(rtrim(ltrim(f.factura)),3,len(rtrim(ltrim(f.factura)))-2))>0) nf
	where isnull(d.factura,'')='' and isnull(d.Cont_corespondent,'')='' and d.Plata_incasare in ('IX','PX')

-->	pentru cazuri in care se fac plati/incasari reprezentand avansuri (daca suntem pe subtip de avans), TVA-ul se extrage din suma introdusa in macheta (model CGplus si wScriuPozplin).
	update d set TVA22=Suma*TVA11/(100+TVA11)
	from #descris d	
	where d.Plata_incasare in ('IX','PX') and TVA11<>0 and TVA22=0

 -->Tipul din subtip  
	update #descris set plata_incasare=(case when plata_incasare='PV' or plata_incasare='PX'/*PX->subtip de plata avans*/ then 'PF' 
											when plata_incasare='IV' or plata_incasare='IX'/*IX->subtip de incasare avans*/ then 'IB' 
											when plata_incasare in ('PA','PE','PG') then 'PD' 
											when plata_incasare in ('IA','IE','IY') then 'ID' 
											when plata_incasare = 'PT' then 'PC'
										else plata_incasare end)  

-->	Modificari bugetari: daca indicatorul nu a fost introdus de utilizator atunci il generam automat
-->	Scos formarea indicatorului bugetar. Indicatorul va fi completat doar in tabela conturi (detalii).
	if @Bugetari=1 and 1=0	
	begin 
		update d set d.Indbug=
			(case 
				when left(d.cont,1) in ('6','7') 
					then (case when isnull(c.Cont_strain,'')='' then '' else rtrim(isnull(substring(sp.Comanda,21,20),''))+substring(isnull(c.Cont_strain,''),LEN(rtrim(isnull(substring(sp.Comanda,21,20),'')))+1,20) end)
				when d.Plata_incasare not in ('PF','IB') 
					then (case when isnull(cc.Cont_strain,'')='' then '' else rtrim(isnull(substring(sp.Comanda,21,20),''))+substring(isnull(cc.Cont_strain,''),LEN(rtrim(isnull(substring(sp.Comanda,21,20),'')))+1,20) end) 
				when d.Plata_incasare in ('PF','IB') 
					then isnull(substring(f.comanda,21,20),'')
				else d.indbug
			end)
		from #descris d
			left outer join speciflm sp on d.Loc_de_munca=sp.loc_de_munca
			left outer join contcor c on d.Cont=c.ContCG
			left outer join contcor cc on d.Cont_corespondent=cc.ContCG
			left outer join facturi f on d.subunitate=f.Subunitate and d.tert=f.tert and d.factura=f.factura 
				and f.tip=(case when d.plata_incasare like 'I%' and d.plata_incasare<>'IS' or d.plata_incasare='PS' then 0x46 else 0x54 end)
		where isnull(indbug,'')=''
	end

 -->Procesare valuta  
	IF EXISTS(select 1 from #descris where valuta!='')  
	BEGIN  
		declare @ctCheltDifCF varchar(40),@CtVenDifcF varchar(40),@CtCheltDifcB varchar(40),@CtVenDifcB varchar(40)
		exec luare_date_par 'GE', 'DIFCH', 0, 0, @CtCheltDifcF output  
		exec luare_date_par 'GE', 'DIFVE', 0, 0, @CtVenDifcF output  
		exec luare_date_par 'GE', 'DIFCHB', 0, 0, @CtCheltDifcB output
		exec luare_date_par 'GE', 'DIFVEB', 0, 0, @CtVenDifcB output
  
-->	formatare sume aferente facturilor in valuta
		update #descris set curs=convert(decimal(11,4),curs), Curs_la_valuta_facturii=convert(decimal(11,4),Curs_la_valuta_facturii), Suma_valuta=convert(decimal(17,4),Suma_valuta)
-->	transpunere suma valuta in suma lei pornind de la curs.	
		update #descris set Suma=round(convert(decimal(18, 5), isnull(Suma_valuta,0)*isnull(Curs,0)), 2)
		where #descris.valuta!='' and abs(isnull(Suma,0))<0.01 and abs(isnull(Suma_valuta,0))>=0.01 and abs(isnull(Curs,0))>=0.0001

		update #descris set Achit_fact=Suma_valuta where plata_incasare in ('PF','IB','PS','IS') and valuta!=''  

		update #descris set  
			suma=round(convert(decimal(18, 5), #descris.suma_valuta*#descris.curs),2), Achit_fact=#descris.Suma_valuta
			,Suma_dif=convert(decimal(11,2),(case when f.valuta='' then 0 else #descris.suma_valuta*#descris.curs-#descris.suma_valuta*f.curs end))
		from facturi f 
		where #descris.Subunitate=f.Subunitate and #descris.tert=f.Tert and #descris.Factura=f.Factura and #descris.tip_fact=f.Tip
			and #descris.plata_incasare in ('PF','IB','PS','IS') and #descris.valuta!='' and #descris.tert!='' and #descris.Factura!=''  

		update #descris set  
			cont_dif=(case when cont_dif!='' then cont_dif
					when #descris.tip_fact=0x46 and /*#descris.curs<=f.curs*/ #descris.Suma_dif<=-0.01 then @CtCheltDifcB
					when #descris.tip_fact=0x46 and /*#descris.curs>f.curs*/ #descris.Suma_dif>=0.01 then @CtVenDifcB
					when #descris.tip_fact=0x54 and /*#descris.curs<=f.curs*/ #descris.Suma_dif<=-0.01 then @CtVenDifcF
					when #descris.tip_fact=0x54 and /*#descris.curs>f.curs*/ #descris.Suma_dif>=0.01 then @CtCheltDifcF else '' 
					end)
		from facturi f 
		where #descris.Subunitate=f.Subunitate and #descris.tert=f.Tert and #descris.Factura=f.Factura and #descris.tip_fact=f.Tip
			and #descris.plata_incasare in ('PF','IB','PS','IS') and #descris.valuta!='' and #descris.tert!='' and #descris.Factura!=''

-->	calcul diferente de curs la deconturi in valuta
		update #descris set  
			Dif_curs_dec=convert(decimal(11,2),(#descris.suma_valuta*#descris.curs-#descris.suma_valuta*d.curs))
		from deconturi d 
		where #descris.Subunitate=d.Subunitate and #descris.marca=d.Marca and #descris.Decont=d.Decont and #descris.valuta!=''  

		update #descris set  
			cont_dif_dec=rtrim((case when #descris.Dif_curs_dec<=0.01 then @CtCheltDifcB	--	diferenta nefavorabila
								when #descris.Dif_curs_dec>=0.01 then @CtVenDifcB end))		--	diferenta favorabila
		from deconturi d 
		where #descris.Subunitate=d.Subunitate and #descris.marca=d.Marca and #descris.Decont=d.Decont and #descris.valuta!=''  

-->	stocam diferenta de curs si contul in pozplin.detalii (pentru a nu se suprapune cu diferenta de curs/contul de diferente de curs de la facturi)
		update #descris set detalii='<row />'
		where detalii is null and Dif_curs_dec<>0

		update d set detalii.modify('replace value of (/row/@_difcursdec)[1] with sql:column("d.Dif_curs_dec")') 
		from #descris d
		where d.detalii.value('(/row/@_difcursdec)[1]','float') is not null and Dif_curs_dec<>0
		update d set detalii.modify('insert attribute _difcursdec {sql:column("d.Dif_curs_dec")} into (/row)[1]') 
		from #descris d
		where d.detalii.value('(/row/@_difcursdec)[1]','float') is null and Dif_curs_dec<>0

		update d set detalii.modify('replace value of (/row/@_contdifdec)[1] with sql:column("d.Cont_dif_dec")') 
		from #descris d
		where d.detalii.value('(/row/@_contdifdec)[1]','varchar(40)') is not null and Dif_curs_dec<>0
		update d set detalii.modify('insert attribute _contdifdec {sql:column("d.Cont_dif_dec")} into (/row)[1]') 
		from #descris d
		where d.detalii.value('(/row/@_contdifdec)[1]','varchar(40)') is null and Dif_curs_dec<>0
	end  
	-->Procesare TVA  
	update #descris set 
		TVA22=ROUND(convert(decimal(18, 5), isnull(Suma,0)*TVA11/(100.00+TVA11)), 2)  
	where substring(Plata_incasare, 2, 1)='C' and TVA11<>0 and ISNULL(TVA22, 0)=0	

	--pentru cazuri in care se fac plati/incasari pe facturi care nu sunt in ASIS(se genereaza acum),contul corespondent il luam din tert
	update d set Cont_corespondent=(case when d.plata_incasare like 'I%' then t.cont_ca_beneficiar else t.cont_ca_furnizor end)
	from #descris d	
		inner join terti t on t.tert=d.tert and isnull(d.factura,'')<>'' and isnull(d.Cont_corespondent,'')='' and d.Plata_incasare in ('IB','PF')

	/* Tratat tert generic la PC,IC*/
	declare @tertGeneric varchar(20)
	exec luare_date_par 'UC','TERTGEN',0,0,@tertGeneric OUTPUT
	if @tertGeneric!=''
	begin
		update #descris set tert=@tertGeneric where plata_incasare in ('PC','IC') and isnull(tert,'')=''
	end

	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPlinSP1')
		exec wScriuPlinSP1 @sesiune, @parXml output -- procedura care va modifica #descris


	/*start tranzactia de scriere in pozplin*/
	begin tran scriupozplin	
				/*Lucian: Aici se aloca numar de document daca nu exista*/
				if exists (select 1 from #descris where isnull(numar,'')='')
				begin
					if (select count(distinct Plata_incasare) from #descris where isnull(numar,'')='')>1
						raiserror('Nu se pot trimite mai multe tipuri cu numar de document necompletat!',16,1)

					declare @fXML xml, @tipPentruNr varchar(2), @subtip varchar(20),@NrDocPrimit varchar(20),@lm varchar(20),@jurnal varchar(20),
						@NumarDocPrimit int,@idPlajaPrimit int,@nrdocumente int,@serieprimita varchar(20)
			
					select top 1 @tipPentruNr=tip_antet,@lm=loc_de_munca,@jurnal=jurnal,@subtip=plata_incasare
					from #datecitite where isnull(numar,'')=''
		
					set @lm = (case when @lm is null then '' else @LM end)
					set @jurnal = (case when @jurnal is null then '' else @jurnal end)
					set @fXML = '<row/>'
					set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')
					set @fXML.modify ('insert attribute meniu {"PI"} into (/row)[1]')
					set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
					set @fXML.modify ('insert attribute subtip {sql:variable("@subtip")} into (/row)[1]')
					set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
					set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')
					set @fXML.modify ('insert attribute jurnal {sql:variable("@jurnal")} into (/row)[1]')

					exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocPrimit output, @Numar=@NumarDocPrimit output, @idPlaja=@idPlajaPrimit output, @serie=@serieprimita OUTPUT

					if @NrDocPrimit is null
						raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)
			
					if (select top 1 SerieInNumar from docfiscale where id=@idPlajaPrimit)=1
						update #descris set numar=@serieprimita+ltrim(str(@NumarDocPrimit))
						where isnull(numar,'')=''
					else
						update #descris set numar=ltrim(str(convert(int,@NrDocPrimit)))
						where isnull(numar,'')=''
				end
				/*Lucian: Aici se aloca numar de decont daca nu exista, pentru tip=RE si subtip=PA functie de setarile din ASiSplus*/
				update d set d.Decont=(case when @DecontPeContMarca=1 then (case when c.Sold_credit=9 then d.Cont else d.Cont_corespondent end) 
											when @NrDecont_Numar=1 then d.Numar else convert(varchar(10),nr.nr_urm) end)
				from #descris d
					left outer join conturi c on c.Subunitate=d.Subunitate and c.Cont=d.Cont
					left outer join conturi cc on cc.Subunitate=d.Subunitate and cc.Cont=d.Cont_corespondent
					outer apply (select isnull(max(convert(decimal(13,0), convert(float, decont))), 0) + 1 as nr_urm 
						from deconturi de
						where de.subunitate=d.subunitate and de.tip='T' and de.marca=d.Marca and isnumeric(decont)<>0) nr
				where isnull(d.decont,'')='' and marca<>'' and (d.Plata_incasare='PD' and cc.Sold_credit=9 or @DecontPeContMarca=1 and c.Sold_credit=9)
				
				/*Lucian: Aici se aloca numar de efect daca nu exista, pentru tip=EF si subtip=PF,IB. Momentan dupa modelul din ASiSplus*/
				update d set d.Efect='EF'+convert(varchar(10),nr.nr_urm)
				from #descris d
					left outer join conturi c on c.Subunitate=d.Subunitate and c.Cont=d.Cont
					outer apply 
						(select isnull(max(convert(int, substring(nr_efect,3,8))), 0) + 1 as nr_urm 
						from efecte e
						where e.subunitate=d.subunitate and e.tip=(case when left(d.Plata_incasare,1)='P' then 'P' else 'I' end) 
							and e.tert=d.tert and left(e.nr_efect,2) in ('BO','EF') and isnumeric(substring(nr_efect,3,8))<>0) nr
				where @SugerareEfectUnicPeTert=1 and isnull(d.Efect,'')='' and d.Plata_incasare in ('PF','IB') and c.Sold_credit=8
				
				if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPlinSP2')
					exec wScriuPlinSP2 @sesiune, @parXml output -- procedura care va modifica #descris
				
				IF OBJECT_ID('tempdb..#pozplinIns') is not null drop table #pozplinIns
				create table #pozplinIns (idpozplin int, numar_pozitie int)

				--stergem din pozplin pozitiile pentru care se face doar update. Am modificat sa facem update data _update=1 (similar wScriuDoc)
				if exists (select 1 from #descris where _update=1)
				begin
					update pozplin
					set utilizator=@utilizator,
					data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104), 
					ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')), 
					Cont=isnull(#descris.Cont,pozplin.Cont),
					Data=isnull(#descris.Data,pozplin.Data),
					Numar=isnull(#descris.Numar,pozplin.Numar),
					Plata_incasare=isnull(#descris.Plata_incasare,pozplin.Plata_incasare),
					Tert=isnull(#descris.Tert,pozplin.Tert),
					Factura=isnull(#descris.Factura,pozplin.Factura),
					Cont_corespondent=isnull(#descris.Cont_corespondent,pozplin.Cont_corespondent),
					Suma=isnull(#descris.Suma,pozplin.Suma),
					Valuta=isnull(#descris.Valuta,pozplin.Valuta),
					Curs=isnull(#descris.curs,pozplin.Curs),
					Suma_valuta=isnull(#descris.Suma_valuta,pozplin.Suma_valuta),
					Curs_la_valuta_facturii=isnull(#descris.Curs_la_valuta_facturii,pozplin.Curs_la_valuta_facturii),
					TVA11=isnull(#descris.TVA11,pozplin.TVA11),
					TVA22=isnull(#descris.TVA22,pozplin.TVA22),
					Explicatii=isnull(#descris.Explicatii,pozplin.Explicatii),
					Loc_de_munca=isnull(#descris.Loc_de_munca,pozplin.Loc_de_munca),
					Comanda=isnull(#descris.Comanda,pozplin.Comanda),
					Cont_dif=isnull(#descris.Cont_dif,pozplin.Cont_dif),
					Suma_dif=isnull(#descris.Suma_dif,pozplin.Suma_dif),
					Achit_fact=isnull(#descris.Achit_fact,pozplin.Achit_fact),
					Jurnal=isnull(#descris.jurnal,pozplin.Jurnal),
					detalii=isnull(#descris.detalii,pozplin.detalii),
					Tip_tva=isnull(#descris.Tip_tva,pozplin.Tip_tva),
					Marca=isnull(#descris.Marca,pozplin.Marca),
					Decont=isnull(#descris.Decont,pozplin.Decont),
					Efect=isnull(#descris.Efect,pozplin.Efect)
					from #descris where pozplin.idPozPlin=#descris.idPozPlin
					/*
					delete p 
					from pozplin p
						inner join #descris d on d._update=1 and d.idpozPlin!=0 and p.idPozPlin=d.idpozPlin  
					*/
				end
				else
					insert into pozplin(Subunitate,Cont,Data,Numar,Plata_incasare,Tert,Factura,Cont_corespondent,Suma,  
						Valuta,Curs,Suma_valuta,Curs_la_valuta_facturii,TVA11,TVA22,Explicatii,Loc_de_munca,Comanda,  
						Utilizator,Data_operarii,Ora_operarii,  
						Numar_pozitie,Cont_dif,Suma_dif,Achit_fact,Jurnal,Detalii,tip_tva,marca,decont,efect, subtip) 
					OUTPUT inserted.idPozplin, inserted.Numar_pozitie INTO #pozplinIns (idPozplin, numar_pozitie) 
					select pd.Subunitate,pd.Cont,pd.Data,pd.Numar,Plata_incasare,Tert,Factura,Cont_corespondent,convert(decimal(17,2),Suma),  
						Valuta,Curs,Suma_valuta,Curs_la_valuta_facturii,convert(decimal(11,2),TVA11),convert(decimal(11,2),TVA22),
						Explicatii,Loc_de_munca,convert(char(20),Comanda),Utilizator,Data_operarii,Ora_operarii,  
						(case when pd._update=1 then pd.numar_pozitie else p2.maxpoz+ ROW_NUMBER() OVER (partition by pd.cont,pd.data/*,pd.numar*/ order by pd.numar_pozitie) end),
						Cont_dif,Suma_dif,Achit_fact,Jurnal,
						pd.detalii,Tip_tva,Marca,Decont,Efect, subtip
					from #descris pd  
						left outer join #nrpozitii p2 on p2.subunitate=pd.subunitate and p2.cont=pd.cont and p2.data=pd.data 

				/* Pentru bugetari se apeleaza procedura ce scrie in pozplin.detalii, a indicatorului bugetar stabilit in mod unitar prin procedura indbugPozitieDocument. */
				if @bugetari=1 and exists (select 1 from #descris where isnull(_update,0)=0)
					and exists (select 1 from sysobjects where [type]='P' and [name]='indbugPozitieDocument')
				begin
					declare @parXMLIndbug xml
					IF OBJECT_ID('tempdb..#indbugPozitieDoc') is not null drop table #indbugPozitieDoc
					create table #indbugPozitieDoc (furn_benef char(1), tabela varchar(20), idPozitieDoc int, indbug varchar(20))
					insert into #indbugPozitieDoc (furn_benef, tabela, idPozitieDoc)
					select '', 'pozplin', idpozplin from #pozplinIns
					
					set @parXMLIndbug=(select 1 as scriere for xml raw)
					exec indbugPozitieDocument @sesiune=@sesiune, @parXML=@parXMLIndbug
				end
	commit tran scriupozplin
end try  
begin catch  
	if EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'scriupozplin')
		ROLLBACK TRAN scriupozplin

	declare @mesaj varchar(255)
	set @mesaj='wScriuPlin: '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1) 
end catch
