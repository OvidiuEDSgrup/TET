--*/
CREATE PROCEDURE wScriuDocSPAnteSpargere @sesiune varchar(50), @parXML xml OUTPUT --am inlocuit cu ALTER va da eroare in cazul in care nu exista
AS
begin try
	declare @subunitate varchar(13),@userASiS varchar(20), @gestProprietate varchar(20), @clientProprietate varchar(13), @lmProprietate varchar(20), @jurnalProprietate varchar(3),
		@returneaza_inserate bit, @rootDoc varchar(20),@multiDoc int, @rootDocAntet varchar(20),@StocuriNoi int
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
	exec luare_date_par 'AR', 'NSTOC', @StocuriNoi output, 0, ''

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
	
	if OBJECT_ID('tempdb..#documente') is null
		create table #documente(tip varchar(2),numar varchar(20),data datetime,gestiune varchar(13),gestiune_primitoare varchar(20),tert varchar(13),factura varchar(20),
		data_facturii datetime,data_scadentei datetime,loc_de_munca varchar(13),numar_pozitie int,cod varchar(20),barcod varchar(20),codcodi varchar(50),cantitate float,pret_valuta float,pret_vanzare float,
		tip_tva int,zilescadenta int,facturanesosita int,aviznefacturat int,cod_intrare varchar(20),codiPrim varchar(20),pret_cu_amanuntul float,cota_tva int,tva_deductibil decimal(12,2),
		tva_valuta float,comanda varchar(20),indbug varchar(20),pret_de_stoc float,pret_amanunt_predator float,valuta varchar(3),curs float,locatie varchar(20),[contract] varchar(20),
		lot varchar(20),data_expirarii datetime,discount decimal(12,3),punctlivrare varchar(13),numar_dvi varchar(20),categ_pret int,
		cont_de_stoc varchar(20),cont_corespondent varchar(20),cont_intermediar varchar(20),cont_factura varchar(20),cont_venituri varchar(20),
		tva_neexigibil decimal(5,2),idJurnalContract int,idPozContract int,stare int,jurnal varchar(20),detalii xml,detalii_antet xml,subtip varchar(2),tip_miscare varchar(1),
		cumulat float,nrordmin int,nrordmax int,tvaunit float,nrpe int,nrpozmax int,updatabile int,cerecumulare int,idlinie int,idIntrareFirma int,idIntrare int,ptUpdate int,idpozdoc int,pid int,tva_deductibil_i decimal(12,2), idPtAntet int,colet varchar(500),
		codgs1 varchar(1000), idPozDocRezervare int,idplaja int,nrp int identity)
	
	if OBJECT_ID('tempdb..#maxPoz') is null
		select d.tip,d.numar,d.pid,d.data,max(d.numar_pozitie) as maxpoz,sum(round(convert(decimal(12,3),d.tva_deductibil),2)) as sumatva
		into #maxPoz
		from #documente d 
		group by d.tip,d.numar,d.pid,d.data

	if OBJECT_ID('tempdb..#mp') is null
		select p.tip,p.numar,p.data,max(p.numar_pozitie) as nrp
		into #mp
		from #documente d 
		inner join pozdoc p on p.subunitate=@subunitate and d.tip=p.tip and d.data=p.data and d.numar=p.numar
		group by p.tip,p.numar,p.data

	update #maxPoz set maxpoz=#mp.nrp
	from #mp 
	inner join #maxPoz on #mp.tip=#maxpoz.tip and #mp.numar=#maxpoz.numar and #mp.data=#maxpoz.data
	
	 /*Creeam o tabela temporara pentru gestiuni de Transfer - utila mai ales la PV*/
	if OBJECT_ID('tempdb..#gesttransfer') is null
	begin
		create table #gesttransfer(gestiune varchar(20),gestiune_transfer varchar(20),nrordine int)
		exec creeazaGestiuniTransfer
	end
	
	update p set Locatie=p.Comanda
	from #documente p
		left outer join gestiuni g on g.Subunitate=@subunitate and g.Cod_gestiune=p.gestiune
	where isnull(g.detalii.value('(/row/@custodie)[1]','int'),0)=1 
		and nullif(p.Locatie,'') is null and ISNULL(p.Comanda,'')<>''
		and (tip_miscare='E' and cantitate>0 or tip_miscare='I' and cantitate<0) and cod_intrare='' 
		
	update p set Locatie=p.Comanda
	from #documente p
		left outer join gestiuni g on g.Subunitate=@subunitate and g.Cod_gestiune=p.gestiune_primitoare
	where isnull(g.detalii.value('(/row/@custodie)[1]','int'),0)=1 
		and nullif(p.Locatie,'') is null and ISNULL(p.Comanda,'')<>''
		and (tip='TE' and cantitate>0) and cod_intrare='' 

	--begin transaction wScriuDocSPAnteSpargere	

	if exists (select top(1) 1 from #documente d join nomencl n on n.Cod=d.cod
		where d.tip in ('CM', 'TE', 'AP', 'AS', 'AC', 'AE', 'DF', 'PF', 'CI') and d.cod_intrare = ''
			and convert(decimal(18,5),d.cantitate-FLOOR(d.cantitate)) >= convert(decimal(18,5),0.00001) 
			and n.Tip not in ('S', 'R', 'F'))
			raiserror('Nu se pot opera documente de iesire din stoc ce au cantitati cu fractiuni dintr-un intreg (zecimale)! Va rugam sa corectati cantitatea!',11,1)

	update p
	set Gestiune_primitoare=gt.gestiune
	--select p.gestiune as cod_gestiune,gt.gestiune_transfer,p.cod,gt.nrordine,sum(p.cantitate) as cantitate
	from #documente p 
		left outer join #gesttransfer gt on gt.gestiune_transfer=replace(p.Gestiune,'700.','211.')
	where p.tip='AC' and nullif(p.Gestiune_primitoare,'') is null and ISNULL(gt.gestiune,'')<>''
	
	if exists(select 1 from #documente where (tip_miscare='E' or tip_miscare='I' and cantitate<0) and cod_intrare<>'') and @StocuriNoi=0
	begin
			update d set pret_de_stoc=s.pret,pret_amanunt_predator=s.Pret_cu_amanuntul,cont_de_stoc=s.Cont,lot=s.Lot,locatie=(case when d.tip='TE' then d.locatie else s.Locatie end),idIntrare=s.idIntrare,idIntrareFirma=s.idIntrareFirma
				,tva_neexigibil=s.TVA_neexigibil
			from #documente d join gestiuni g on g.Subunitate=@subunitate and g.Cod_gestiune=d.gestiune
			inner join stocuri s on s.Subunitate=@subunitate and s.Tip_gestiune=g.Tip_gestiune and d.gestiune=s.cod_gestiune and d.cod=s.cod and d.cod_intrare=s.Cod_intrare 
	end
	
	/*-------------------------------------------Spargere iesiri pe cod de intrare---------------------*/
	if exists(select 1 from #documente where (tip_miscare='E' /*SP or tip_miscare='I' SP*/ and cantitate<0) and cod_intrare='' ) 
	begin /*Spargere pentru iesiri*/
--select nrp,*
--from #documente d
		--where (tip_miscare='E' /*SP or tip_miscare='I' SP*/and cantitate<0) and d.cod_intrare=''
		
		declare @areTE int
		create table #pozdSP(Cantitate float,TVa_deductibil decimal(12,2),Tip varchar(2),Numar varchar(20),Cod varchar(20),Data datetime,Gestiune varchar(20),
			Pret_valuta decimal(12,5),Pret_de_stoc decimal(12,5),Pret_vanzare decimal(12,5),Pret_cu_amanuntul decimal(12,5),Cota_TVA decimal(12,2),
			Cod_intrare varchar(20),CodiPrim varchar(20),Cont_de_stoc varchar(20),Cont_corespondent varchar(20),TVA_neexigibil decimal(12,2),Pret_amanunt_predator decimal(12,5),
			Tip_miscare varchar(1),Locatie varchar(20),Data_expirarii datetime,Numar_pozitie int,Loc_de_munca varchar(20),Comanda varchar(20),
			Barcod varchar(20),Cont_intermediar varchar(20),Cont_venituri varchar(20),Discount decimal(12,5),Tert varchar(20),Factura varchar(20),
			Gestiune_primitoare varchar(20),Numar_DVI varchar(20),Categ_pret int,Stare int,Cont_factura varchar(20),Valuta varchar(3),Curs decimal(12,5),Data_facturii datetime,
			Data_scadentei datetime,Tip_tva int,Contract varchar(20),Jurnal varchar(20),
			cumulat float,nrordmin int,nrordmax int,tvaunit float,nrp int, nrpozmax int,idPozDoc int, idPozContract int, idJurnalContract int,detalii xml, idlinie int,idIntrareFirma int,idIntrare int,pid int, tva_deductibil_i decimal(12,2),
			detalii_antet xml, aviznefacturat bit, punctlivrare varchar(50),lot varchar(20),colet varchar(500),idplaja int, aretur nvarchar(max))

		delete d
		OUTPUT (case when deleted.tip='TE' then -1 else 1 end)*DELETED.Cantitate,DELETED.TVa_deductibil,DELETED.Tip,DELETED.NUMAR,DELETED.Cod,DELETED.Data,/*SP */(case DELETED.Tip when 'TE' then DELETED.gestiune_primitoare else DELETED.Gestiune end),/* SP*/
			DELETED.Pret_valuta,DELETED.Pret_de_stoc,DELETED.Pret_vanzare,DELETED.Pret_cu_amanuntul,DELETED.Cota_TVA,
/*SP */		(case DELETED.Tip when 'TE' then DELETED.codiPrim else DELETED.Cod_intrare end),(case DELETED.Tip when 'TE' then DELETED.Cod_intrare else DELETED.codiPrim end),/* SP*/DELETED.Cont_de_stoc,DELETED.Cont_corespondent,
			DELETED.TVA_neexigibil,DELETED.Pret_amanunt_predator,DELETED.Tip_miscare,DELETED.Locatie,DELETED.Data_expirarii,DELETED.Numar_pozitie,
			DELETED.Loc_de_munca,DELETED.Comanda,DELETED.Barcod,DELETED.Cont_intermediar,DELETED.Cont_venituri,DELETED.Discount,DELETED.Tert,DELETED.Factura,
/*SP */		(case DELETED.Tip when 'TE' then DELETED.Gestiune else DELETED.Gestiune_primitoare end),/* SP*/DELETED.Numar_DVI,DELETED.Categ_pret,DELETED.Stare,DELETED.Cont_factura,DELETED.Valuta,DELETED.Curs,
			DELETED.Data_facturii,DELETED.Data_scadentei,DELETED.Tip_tva,
			DELETED.Contract,DELETED.Jurnal,CONVERT(FLOAT,0) as cumulat,0 as nrordmin,0 as nrordmax,deleted.tva_deductibil/(case when deleted.cantitate=0 then 1 else deleted.cantitate end) as tvaunit,DELETED.nrp,0, 
			DELETED.nrp, DELETED.idPozContract, DELETED.idJurnalContract,DELETED.detalii, deleted.idlinie,deleted.idIntrareFirma,deleted.idIntrare,deleted.pid, deleted.tva_deductibil_i,
			DELETED.detalii_antet, DELETED.aviznefacturat, deleted.punctlivrare,deleted.lot,deleted.colet,deleted.idplaja,null
		INTO #pozdSP
		from #documente d
		where (tip_miscare='E' /*SP or tip_miscare='I' SP*/and cantitate<0) and d.cod_intrare=''
--/*SP
		update p set p.Locatie=p.Comanda
		from #pozdSP p
			left outer join gestiuni g on g.Subunitate=@subunitate and g.Cod_gestiune=p.gestiune
		where p.Tip='TE' and isnull(g.detalii.value('(/row/@custodie)[1]','int'),0)=1 
			and nullif(p.Locatie,'') is null and ISNULL(p.Comanda,'')<>''
--SP*/		
		update #pozdSP 
			set nrp=ranc
		from 
			(
				select 
					p2.tip,p2.pid,p2.data,p2.numar_pozitie,p2.idPozDoc,ROW_NUMBER() over (partition by p2.cod/*SP */,(case isnull(g.detalii.value('(/row/@custodie)[1]','int'),0) when 1 then p2.locatie end)/* SP*/  order by p2.cod,p2.data,p2.idPozDoc) as ranc
				from #pozdSP p2 /*SP */left outer join gestiuni g on g.Subunitate=@subunitate and g.Cod_gestiune=p2.gestiune/* SP*/
			) p1 
		where p1.tip=#pozdSP.tip and p1.pid=#pozdSP.pid and p1.data=#pozdSP.data and p1.idPozDoc=#pozdSP.idPozDoc

		update #pozdSP
			set nrpozmax=maxpoz 
		from 
			(
				select 
					p2.tip,p2.numar,p2.data,MAX(p2.numar_pozitie) as maxpoz
				from pozdoc p2
				inner join #pozdSP p3 on p2.tip=p3.tip and p2.numar=p3.numar and p2.data=p3.data
				group by p2.tip,p2.numar,p2.data
			) p1
		 where p1.tip=#pozdSP.tip and p1.numar=#pozdSP.numar and p1.data=#pozdSP.data 

		create table #stoctotal(nrord int,stoctotal float,Tip_gestiune varchar(1),Cod_gestiune varchar(20),Cod varchar(20),Data datetime,Cod_intrare varchar(13),Pret float,Stoc_initial float,Intrari float,Iesiri float,
			Data_ultimei_iesiri datetime,Stoc float,Cont varchar(20),Data_expirarii datetime,Stoc_ce_se_calculeaza float,Are_documente_in_perioada bit,TVA_neexigibil real,
			Pret_cu_amanuntul float,Locatie varchar(30),Pret_vanzare float,Loc_de_munca varchar(9),Comanda varchar(40),Contract varchar(20),Furnizor varchar(13),Lot varchar(20),
			Stoc_initial_UM2 float,Intrari_UM2 float,Iesiri_UM2 float,Stoc_UM2 float,Stoc2_ce_se_calculeaza float,Val1 float,Alfa1 varchar(30),Data1 datetime,gestiune_transfer varchar(20),idIntrareFirma int,idIntrare int,colet varchar(500))

		insert into #stoctotal
		select 
			row_number() over (partition by pd.cod_gestiune,s.cod/*SP */,(case isnull(g.detalii.value('(/row/@custodie)[1]','int'),0) when 1 then s.locatie end)/* SP*/order by pd.nrordine,s.data) as nrord,convert(float,0.00) as stoctotal,
			s.Tip_gestiune, pd.cod_gestiune as cod_gestiune, s.Cod, s.Data, s.Cod_intrare, s.Pret, s.Stoc_initial, s.Intrari, s.Iesiri, s.Data_ultimei_iesiri, 
			(case when s.Stoc<0 then 0 else s.stoc end), 
			s.Cont, s.Data_expirarii, s.Stoc_ce_se_calculeaza, s.Are_documente_in_perioada, s.TVA_neexigibil, s.Pret_cu_amanuntul, s.Locatie, s.Pret_vanzare, s.Loc_de_munca, s.Comanda, s.Contract, s.Furnizor, s.Lot, s.Stoc_initial_UM2, s.Intrari_UM2, s.Iesiri_UM2, s.Stoc_UM2, s.Stoc2_ce_se_calculeaza, s.Val1, s.Alfa1, s.Data1,pd.gestiune_transfer,s.idIntrareFirma,s.idIntrare,null as colet
		from stocuri s /*SP */left join gestiuni g on g.Subunitate=@subunitate and g.Cod_gestiune=s.cod_gestiune/* SP*/
		inner join
			(select p.gestiune as cod_gestiune,gt.gestiune_transfer,p.cod,gt.nrordine,sum(p.cantitate) as cantitate
			from #pozdSP p 
			left outer join #gesttransfer gt on gt.gestiune=p.Gestiune
			group by p.gestiune,gt.gestiune_transfer,p.cod,gt.nrordine
			) pd on s.cod_gestiune=isnull(pd.gestiune_transfer,pd.cod_Gestiune) and s.cod=pd.cod 
		where 
			rtrim(s.Cod_intrare)!='' /*SP
			and (pd.cantitate<0 or s.stoc>0.001) 
			--SP*/ and (pd.cantitate>0 and s.stoc>0.001) 

--/*SP
		declare @ErrorMessage nvarchar(max)

		update p set aretur=1
		from #pozdSP p join 
			(select p.gestiune as cod_gestiune,gt.gestiune_transfer,p.cod,p.Tert,p.Data,gt.nrordine,sum(p.cantitate) as cantitate
			from #pozdSP p 
			left outer join #gesttransfer gt on gt.gestiune=p.Gestiune
			group by p.gestiune,gt.gestiune_transfer,p.cod,p.Tert,p.Data,gt.nrordine
			) pd on pd.cod=p.cod and pd.cod_Gestiune=p.Gestiune and pd.Tert=p.Tert and pd.Data=p.Data
		inner join nomencl n on n.Cod=pd.Cod and n.Tip not in ('R','S')
		inner join gestiuni g on g.Subunitate='1' and g.Cod_gestiune=isnull(pd.gestiune_transfer,pd.cod_Gestiune)
		outer apply (select top (1) * from pozdoc t where t.Subunitate=@subunitate and t.Cod=pd.Cod and t.Tert=pd.Tert --and t.Pret_de_stoc<t.Pret_vanzare
				and t.gestiune=isnull(pd.gestiune_transfer,pd.cod_Gestiune) and t.Tip in ('AP','AC') and t.Cantitate>0 and t.Data<=pd.Data order by t.Data desc) s 
		where pd.cantitate<0 
			and nullif(s.Cod_intrare,'') is not null
			

		set @ErrorMessage=null
		select @ErrorMessage=isnull(@ErrorMessage,'Urmatoarele produse nu pot fi stornate pt. ca nu au fost vandute printr-un document din gestiunea si clientul completate:')
				+CHAR(13)+RTRIM(n.Denumire)+' ('+RTRIM(n.cod)+')'
		from #pozdSP pd 
		inner join nomencl n on n.Cod=pd.Cod and n.Tip not in ('R','S')
		where pd.cantitate<0 
			and isnull(pd.aretur,0)<>1

		if @ErrorMessage is not null
				raiserror(@errormessage,11,1)

		insert into #stoctotal
		select --'retururi',*,
			-1*row_number() over (partition by pd.cod_gestiune,s.cod order by pd.nrordine,s.data) as nrord,convert(float,0.00) as stoctotal,
			g.Tip_gestiune, pd.cod_gestiune as cod_gestiune, s.Cod, s.Data, s.Cod_intrare, s.Pret_de_stoc, Stoc_initial=0, Intrari=0, Iesiri=0, Data_ultimei_iesiri=s.Data, 
			Stoc=0, 
			Cont_de_stoc=null, s.Data_expirarii, Stoc_ce_se_calculeaza=0, Are_documente_in_perioada=0, s.TVA_neexigibil, s.Pret_cu_amanuntul, s.Locatie, s.Pret_vanzare, s.Loc_de_munca, s.Comanda, s.Contract, Furnizor='', s.Lot, Stoc_initial_UM2=0, Intrari_UM2=0, Iesiri_UM2=0, Stoc_UM2=0, Stoc2_ce_se_calculeaza=0, Val1=0, Alfa1='', Data1='',pd.gestiune_transfer,s.idIntrareFirma,s.idIntrare,null as colet
		from (select p.gestiune as cod_gestiune,gt.gestiune_transfer,p.cod,p.Tert,p.Data,gt.nrordine,sum(p.cantitate) as cantitate
			from #pozdSP p 
			left outer join #gesttransfer gt on gt.gestiune=p.Gestiune
			group by p.gestiune,gt.gestiune_transfer,p.cod,p.Tert,p.Data,gt.nrordine
			) pd 
		cross apply (select top (1) * from pozdoc t where t.Subunitate=@subunitate and t.Cod=pd.Cod and t.Tert=pd.Tert --and t.Pret_de_stoc<t.Pret_vanzare
				and t.gestiune=isnull(pd.gestiune_transfer,pd.cod_Gestiune) and t.Tip in ('AP','AC') and t.Cantitate>0 and t.Data<=pd.Data order by t.Data desc) s 
		inner join nomencl n on n.Cod=pd.Cod and n.Tip not in ('R','S')
		inner join gestiuni g on g.Subunitate=s.Subunitate and g.Cod_gestiune=isnull(pd.gestiune_transfer,pd.cod_Gestiune)
		where pd.cantitate<0
			and rtrim(s.Cod_intrare)!=''  
--SP*/			
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
			1,0,ISNULL(g.Tip_gestiune,'C'),p.gestiune,p.Cod,min(p.Data),'ST'+ltrim(str(@maxPozDoc+ROW_NUMBER() over (order by p.gestiune,p.cod)/*SP+1000 SP*/)) as cod_intrare,
			max(p.Pret_de_stoc),100000000,100000000,0,min(p.Data),100000000,max(p.Cont_de_stoc),min(p.Data),0,0,max(p.TVA_neexigibil),max(p.Pret_cu_amanuntul),
			max(p.Locatie),max(p.Pret_vanzare),max(p.Loc_de_munca),max(p.Comanda),max(p.Contract),'','',0,0,0,0,0,0,'',min(p.Data),'',null as idIntrareFirma,null as idIntrare,null as colet
		from #pozdSP p
		left outer join gestiuni g on g.Subunitate=@subunitate and g.Cod_gestiune=p.gestiune
		left outer join #stoctotal s on s.cod_gestiune=p.gestiune and s.cod=p.cod
		where s.cod is null -- echivalent "not exists" 
		group by ISNULL(g.Tip_gestiune,'C'),p.gestiune,p.Cod

--/*SP 
		/* Mai punem o linie in stocuri cu cod intrare necompletat din pozdoc daca nu a avut nicio linie in tabela de stocuri - pt locatii*/
		insert into #stoctotal
		select 
			1,0,ISNULL(g.Tip_gestiune,'C'),p.gestiune,p.Cod,min(p.Data),'ST'+ltrim(str(@maxPozDoc+ROW_NUMBER() over (order by p.gestiune,p.cod)/*SP+1000 SP*/)) as cod_intrare,
			max(p.Pret_de_stoc),100000000,100000000,0,min(p.Data),100000000,max(p.Cont_de_stoc),min(p.Data),0,0,max(p.TVA_neexigibil),max(p.Pret_cu_amanuntul),
			max(p.Locatie),max(p.Pret_vanzare),max(p.Loc_de_munca),max(p.Comanda),max(p.Contract),'','',0,0,0,0,0,0,'',min(p.Data),'',null as idIntrareFirma,null as idIntrare,null as colet
		from #pozdSP p
		left outer join gestiuni g on g.Subunitate=@subunitate and g.Cod_gestiune=p.gestiune
		left outer join #stoctotal s on s.cod_gestiune=p.gestiune and s.cod=p.cod and (isnull(g.detalii.value('(/row/@custodie)[1]','int'),0)=0 or s.Locatie=p.Locatie)
		where s.cod is null -- echivalent "not exists" /*SP
			and p.Tip='TE'
		group by ISNULL(g.Tip_gestiune,'C'),p.gestiune,p.Cod		

--SP*/
		update #stoctotal 
			set stoctotal=st
		from 
			(	select 
					s1.Cod_gestiune,s1.Cod,s1.nrord,SUM(s2.stoc) as st from #stoctotal s1/*SP */ cross join #stoctotal s2 left join gestiuni g on g.Subunitate=@subunitate and g.Cod_gestiune=s1.cod_gestiune/* SP*/
				where s1.Cod_gestiune=s2.Cod_gestiune and s1.Cod=s2.Cod and s2.nrord<=s1.nrord/*SP */and (isnull(g.detalii.value('(/row/@custodie)[1]','int'),0)=0 or s2.Locatie=s1.Locatie)/* SP*/
				group by s1.Cod_gestiune,s1.Cod,s1.nrord
			) calcule 
		where 
			calcule.Cod_gestiune=#stoctotal.Cod_gestiune and
			calcule.Cod=#stoctotal.Cod and calcule.nrord=#stoctotal.nrord

		update #pozdSP 
			set cumulat=tot.cum
		from 
			(
				select
					 c1.tip,c1.pid,c1.cod,c1.comanda,c1.Loc_de_munca,c1.Data,c1.nrp,SUM(c2.cantitate) as cum from #pozdSP c1/*SP */left join gestiuni g on g.Subunitate=@subunitate and g.Cod_gestiune=c1.gestiune/* SP*/
				inner join #pozdSP c2 on c1.cod=c2.cod and c1.gestiune=c2.gestiune and c2.nrp<=c1.nrp/* SP*/and (isnull(g.detalii.value('(/row/@custodie)[1]','int'),0)=0 or c2.Locatie=c1.Locatie)/*SP */
				group by c1.tip,c1.pid,c1.cod,c1.comanda,c1.Loc_de_munca,c1.Data,c1.nrp
			) tot
		where 
			#pozdSP.tip=tot.tip and #pozdSP.pid=tot.pid and #pozdSP.cod=tot.cod and #pozdSP.comanda=tot.comanda and #pozdSP.nrp=tot.nrp

		/* Punem min si max */
		update #pozdSP set nrordmin=st.nrord,nrordmax=st2.nrord
		from #pozdSP c/*SP */left outer join gestiuni g on g.Subunitate=@subunitate and g.Cod_gestiune=c.gestiune/* SP*/
			cross apply
				(select top 1 smin.nrord from #stoctotal smin where smin.cod=c.cod and smin.Cod_gestiune=c.gestiune/*SP */and (isnull(g.detalii.value('(/row/@custodie)[1]','int'),0)=0 or c.Locatie=smin.Locatie)/* SP*/and c.cumulat-c.cantitate<smin.stoctotal order by smin.stoctotal) st 
			cross apply
				(select top 1 smax.nrord from #stoctotal smax where smax.cod=c.cod and smax.Cod_gestiune=c.gestiune/*SP */and (isnull(g.detalii.value('(/row/@custodie)[1]','int'),0)=0 or c.Locatie=smax.Locatie)/* SP*/and c.cumulat<=smax.stoctotal order by smax.stoctotal) st2
if @sesiune='' select '#stoctotal',* from #stoctotal s
		/* Mica corectie pentru numere negative ce trebuie sa fie sparte*/	
		update #pozdSP set nrordmin=nrordmax where nrordmin>nrordmax
if @sesiune='' select '#pozdSP',p.nrordmin,p.nrordmax,p.cumulat,* from #pozdSP p
--/*SP */	set identity_insert #documente on /* SP*/

		/*Reinseram liniile in tabela #documente - doar ca de aceasta date sparte si cu cod_intrare,pret_de_Stoc, etc. completate*/
		insert into #documente(Cantitate,TVa_deductibil,Tip,Numar,Cod,Data,Gestiune,Pret_valuta,Pret_de_stoc,
			Pret_vanzare,Pret_cu_amanuntul,Cota_TVA,Cod_intrare,Cont_de_stoc,Cont_corespondent,TVA_neexigibil,Pret_amanunt_predator,
			Tip_miscare,Locatie,Data_expirarii,Numar_pozitie,Loc_de_munca,Comanda,Barcod,Cont_intermediar,Cont_venituri,Discount,Tert,Factura,
			Gestiune_primitoare,Numar_DVI,Categ_pret,Stare,codiprim,Cont_factura,Valuta,Curs,Data_facturii,Data_scadentei,Tip_tva,Contract,Jurnal, idPozContract, idJurnalContract,detalii, idlinie,idIntrareFirma,idIntrare,pid, tva_deductibil_i,
			detalii_antet, aviznefacturat, punctlivrare, idplaja)--/*SP */, nrp/* SP*/)
		select 
			--Pentru verificari s1.nrord,s1.stoctotal,pd.cantitate as c1,pd.cumulat,s1.stoc,pd.nrordmin,pd.nrordmax,
			(case when /*SP */pd.tip='TE'/* SP*/ then -1 else 1 end)*
			(case 
				when pd.nrordmin=pd.nrordmax or pd.cantitate<0 
					then pd.cantitate
				when pd.nrordmin=s1.nrord --prima linie de pe stoc
					then pd.cantitate-(pd.cumulat-s1.stoctotal)
				when pd.nrordmax=s1.nrord --ultima linie de pe stoc
					then (pd.cumulat+s1.stoc-s1.stoctotal)
			  else s1.stoc
			end) as cantitate,
			(case when /*SP */pd.tip='TE'/* SP*/ then -1 else 1 end)*
			(case 
				when pd.nrordmin=pd.nrordmax or pd.cantitate<0 
					then pd.cantitate
				when pd.nrordmin=s1.nrord --prima linie de pe stoc
					then pd.cantitate-(pd.cumulat-s1.stoctotal)
				when pd.nrordmax=s1.nrord --ultima linie de pe stoc
					then (pd.cumulat+s1.stoc-s1.stoctotal)
			  else s1.stoc
			end)*pd.tvaunit,
			pd.Tip,pd.Numar,pd.Cod,pd.Data,/*SP */(case pd.Tip when 'TE' then (case when ISNULL(s1.Gestiune_transfer,'')!='' then pd.Gestiune when ISNULL(pd.gestiune_primitoare,'')!='' then pd.gestiune_primitoare else '' end) else
			isnull(nullif(s1.Gestiune_transfer,''),pd.Gestiune) end)/* SP*/,
			pd.Pret_valuta,s1.Pret as pret_de_stoc,pd.Pret_vanzare,pd.Pret_cu_amanuntul,pd.Cota_TVA,/*SP */(case pd.Tip when 'TE' then 
			(case when tip in ('TE','DF','PF') then
				(case when sprim.cod is not null then pd.codiprim 
				else 'cinou' --rtrim(s1.cod_intrare)+ltrim(str(row_number() over (partition by pd.cod order by pd.numar_pozitie)))
				end)
			else pd.codiprim end) else 
			s1.Cod_intrare end)/* SP*/,
			/*SP */(case pd.Tip when 'TE' then pd.Cont_corespondent else s1.Cont end),(case pd.Tip when 'TE' then s1.Cont else pd.Cont_corespondent end) /* SP*/,s1.TVA_neexigibil,
			s1.Pret_cu_amanuntul,pd.Tip_miscare,pd.Locatie,pd.Data_expirarii,
			0 as numar_pozitie,--ROW_NUMBER() over (partition by pd.tip,pd.numar,pd.data order by pd.numar_pozitie),
			pd.Loc_de_munca,pd.Comanda,pd.Barcod,pd.Cont_intermediar,pd.Cont_venituri,pd.Discount,pd.Tert,pd.Factura,/*SP */(case pd.Tip when 'TE' then isnull(nullif(s1.Gestiune_transfer,''),pd.Gestiune) else
			(case when ISNULL(s1.Gestiune_transfer,'')!='' then pd.Gestiune when ISNULL(pd.gestiune_primitoare,'')!='' then pd.gestiune_primitoare else '' end) end)/* SP*/,
			pd.Numar_DVI,pd.Categ_pret,pd.Stare,/*SP */(case pd.Tip when 'TE' then s1.Cod_intrare else
			(case when tip in ('TE','DF','PF') then
				(case when sprim.cod is not null then pd.codiprim 
				else 'cinou' --rtrim(s1.cod_intrare)+ltrim(str(row_number() over (partition by pd.cod order by pd.numar_pozitie)))
				end)
			else pd.codiprim end) end)/* SP*/,
			pd.Cont_factura,pd.Valuta,pd.Curs,pd.Data_facturii,pd.Data_scadentei,pd.Tip_tva,pd.Contract,pd.Jurnal, pd.idPozContract, pd.idJurnalContract,pd.detalii, pd.idlinie,s1.idIntrareFirma,s1.idIntrare,pd.pid, pd.tva_deductibil_i,
			pd.detalii_antet, aviznefacturat, pd.punctlivrare,pd.idplaja--/*SP */, pd.nrp /* SP*/
			from #pozdSP pd/*SP */left outer join gestiuni g on g.Subunitate=@subunitate and g.Cod_gestiune=pd.gestiune/* SP*/
     		left outer join #stoctotal s1 on s1.cod_gestiune=pd.gestiune and s1.Cod=pd.cod and s1.nrord between pd.nrordmin and pd.nrordmax/*SP */and (isnull(g.detalii.value('(/row/@custodie)[1]','int'),0)=0 or pd.Locatie=s1.Locatie or s1.stoc=100000000)/* SP*/
			/*Pentru transferuri mai fac un join */
			left outer join stocuri sprim on pd.tip in ('TE','DF','PF') and sprim.Subunitate=@subunitate and 
				sprim.Cod_gestiune=pd.Gestiune_primitoare and sprim.cod=pd.cod 
				and sprim.Cod_intrare=/*SP */(case pd.Tip when 'TE' then s1.Cod_intrare else pd.codiprim end) /* SP*/ 
				and sprim.Cont=/*SP */(case pd.Tip when 'TE' then s1.Cont else pd.Cont_corespondent end) /* SP*/
				and sprim.Pret=pd.Pret_de_stoc and sprim.pret_cu_amanuntul=pd.Pret_cu_amanuntul
if @sesiune='' select * from #documente
/*SP */	set identity_insert #documente off /* SP*/

		update #documente set tva_deductibil=tva_deductibil+(mp.sumatva-d.tvadeductibil)
		from #maxPoz mp
			inner join (select dd.tip,dd.pid,dd.data,sum(round(convert(Decimal(12,3),dd.tva_deductibil),2)) as tvadeductibil 
				from #documente dd group by dd.tip,dd.pid,dd.data) d 
				on d.tip=mp.tip and d.pid=mp.pid and d.data=mp.data
		where #documente.tip=mp.tip and #documente.pid=mp.pid and #documente.data=mp.data and #documente.numar_pozitie=1
		and abs(d.tvadeductibil-mp.sumatva)>0.001 and abs(mp.sumatva)>0.001

		delete #documente where abs(cantitate)<0.000001
	end
	/*!!!!!!!!--------------------------Gata spargere iesiri pe cod intrare-------------------------------------*/
	 
	/*---------------------------Formare cod intrare. Completam codul de intrare doar la intrari-------------------------*/
	declare @maxIdPozDoc int
	set @maxIdPozDoc=IDENT_CURRENT('pozdoc')
	
	update d set cod_intrare=d.tip+ltrim(str(@maxidPozDoc+d.nrp,9))
	from #documente d
	where d.tip_miscare='E' and d.cantitate<0 and cod_intrare='cinou'

	--commit tran wScriuDocSPAnteSpargere
END TRY

BEGIN CATCH
	if @@trancount>0 and EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'wScriuDocSPAnteSpargere')
			ROLLBACK TRAN wScriuDocSPAnteSpargere
	
	declare @mesaj varchar(1000)
	SET @mesaj = ERROR_MESSAGE()+' (wScriuDocSPAnteSpargere)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
