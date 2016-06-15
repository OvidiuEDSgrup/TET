
create procedure wOPAliniereContinuaGestiuniDeTipA @sesiune varchar(50), @parXML xml                
as  
/**
	Exemple rulare
		exec wOPAliniereContinuaGestiuniDeTipA @sesiune='', @parXML='<row dataj="2015-03-01" datas="2015-03-31"/>'
		
**/

SET NOCOUNT ON

declare 
	@subunitate char(9),@gestiune varchar(20),@cod varchar(20),@pDataJ datetime,@pDataS datetime,@cugolire int,
	@amLegaturiContracte bit, @amLegaturiStornare bit

select
	@gestiune=ISNULL(@parXML.value('(/*/@gestiune)[1]', 'varchar(20)'), '') ,
	@pDataJ=ISNULL(@parXML.value('(/*/@dataj)[1]', 'datetime'), '') ,  
	@pDataS=ISNULL(@parXML.value('(/*/@datas)[1]', 'datetime'), '')


select top 1 @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'

select distinct gestiune,1 as CategPret
into #gestiuni
from pozdoc 
inner join gestiuni g on pozdoc.gestiune=g.cod_gestiune and g.tip_gestiune='A'
where pozdoc.subunitate=@subunitate and (isnull(@gestiune,'')='' or pozdoc.gestiune=@gestiune)
and pozdoc.data between @pDataJ and @pDataS

update #gestiuni set CategPret=valoare
FROM proprietati
WHERE tip = 'GESTIUNE'
AND Cod_proprietate = 'CATEGPRET'
AND cod = gestiune

update pd
set pret_cu_amanuntul=p.pret_cu_amanuntul,
tva_neexigibil=n.cota_tva
from pozdoc pd
inner join nomencl n on pd.cod=n.cod
inner join #gestiuni g on pd.gestiune=g.gestiune
outer apply 
	(select top 1 pret_cu_amanuntul from preturi pr where pr.um=g.CategPret and pr.cod_produs=pd.cod and pd.data>=pr.data_inferioara and pr.tip_pret='1' order by pr.data_inferioara desc) p
where pd.subunitate=@subunitate and (isnull(@gestiune,'')='' or pd.gestiune=@gestiune)
and pd.data between @pDataJ and @pDataS and pd.tip_miscare='I'
and pd.pret_cu_amanuntul!=p.pret_cu_amanuntul

update pd
set pret_amanunt_predator=p.pret_cu_amanuntul,tva_neexigibil=n.cota_tva
from pozdoc pd
inner join nomencl n on pd.cod=n.cod
inner join #gestiuni g on pd.gestiune=g.gestiune
outer apply 
	(select top 1 pret_cu_amanuntul from preturi pr where pr.um=g.CategPret and pr.cod_produs=pd.cod and pd.data>=pr.data_inferioara and pr.tip_pret='1' order by pr.data_inferioara desc) p
where pd.subunitate=@subunitate and (isnull(@gestiune,'')='' or pd.gestiune=@gestiune)
and pd.data between @pDataJ and @pDataS and pd.tip_miscare='E'
and pd.pret_cu_amanuntul!=p.pret_cu_amanuntul

/*begin try
	begin transaction stoc

	select @amLegaturiContracte=1 from sysobjects where name='LegaturiContracte'
	select @amLegaturiStornare=1 from sysobjects where name='LegaturiStornare'

	select top 0 
		Cantitate,TVa_deductibil,Subunitate,Tip,Numar,Cod,Data,Gestiune,Pret_valuta,Pret_de_stoc,Adaos,Pret_vanzare,Pret_cu_amanuntul,Cota_TVA,Utilizator,
		Data_operarii,Ora_operarii,Cod_intrare,Cont_de_stoc,Cont_corespondent,TVA_neexigibil,Pret_amanunt_predator,Tip_miscare,Locatie,Data_expirarii,
		Numar_pozitie,Loc_de_munca,Comanda,Barcod,Cont_intermediar,Cont_venituri,Discount,Tert,Factura,Gestiune_primitoare,Numar_DVI,Stare,Grupa,Cont_factura,
		Valuta,Curs,Data_facturii,Data_scadentei,Procent_vama,Suprataxe_vama,Accize_cumparare,Accize_datorate,Contract,Jurnal,
		CONVERT(FLOAT,0) as cumulat,0 as nrordmin,0 as nrordmax,convert(float,0) as tvaunit,0 as nrp, 0 as nrpozmax,0 idPozDoc,convert(xml,'<row />') as detalii
	into #pozd from pozdoc

	/** Luam ID-urile din pozdoc care se vor sterge **/
	SELECT 
		idPozDoc
	INTO #idDeSters
	from pozdoc
	left outer join stocuri st on pozdoc.subunitate=st.subunitate and pozdoc.gestiune=st.cod_gestiune and pozdoc.cod=st.cod and pozdoc.cod_intrare=st.cod_intrare
	where pozdoc.subunitate=@subunitate 
	and pozdoc.data between @pDataJ and @pDataS
	and (@cod='' or pozdoc.cod=@cod)
	and (@gestiune='' or pozdoc.gestiune=@gestiune)
	and pozdoc.tip_miscare='E' and abs(pozdoc.cantitate)>=0.001
	--and not (pozdoc.tip='TE' and pozdoc.gestiune=pozdoc.gestiune_primitoare)
	--and not (tip='TE' and pozdoc.gestiune=pozdoc.Gestiune_primitoare) -- tentativa de execeptare modificari de pret
	and (@cugolire=1 or st.cod is null or st.stoc<=-0.001 or pozdoc.Cod_intrare='' or pozdoc.Pret_de_stoc!=st.Pret or pozdoc.Cont_de_stoc!=st.Cont or pozdoc.Pret_amanunt_predator!=st.Pret_cu_amanuntul)
	
	IF EXISTS (Select 1 from pozdoc d join #idDeSters id on d.idPozDoc=id.idPozDoc where d.tip='TE' and d.gestiune=d.Gestiune_primitoare)
		raiserror ('Exista transferuri in cadrul aceleasi gestiuni care nu sunt tratate!',16,1)

	if @amLegaturiContracte=1
	begin
		/** Daca se lucreaza si cu acest tabel se ia o imagine a tabelului pt. randurile afectate inainte de a se sterge **/
		IF OBJECT_ID('tempdb..#legaturiContracteSterse') IS NOT NULL
			DROP TABLE #legaturiContracteSterse	
		CREATE TABLE #legaturiContracteSterse (idJurnal int,idPozContract int,idPozDoc int, idPozContractCorespondent int)

		delete l 
		OUTPUT DELETED.idJurnal, DELETED.idPozContract, DELETED.idPozDoc, DELETED.idPozContractCorespondent
		INTO #legaturiContracteSterse(idJurnal,idPozContract,idPozDoc,idPozContractCorespondent)
		from LegaturiContracte l
		JOIN #idDeSters i on i.idPozDoc=l.idPozDoc
	END

	if @amLegaturiStornare=1
	begin
		/** Daca se lucreaza si cu acest tabel se ia o imagine a tabelului pt. randurile afectate inainte de a se sterge **/
		IF OBJECT_ID('tempdb..#legaturiStornareSterse') IS NOT NULL
			DROP TABLE #legaturiStornareSterse	
		CREATE TABLE #legaturiStornareSterse (idSursa int, idStorno int)

		delete l
		OUTPUT DELETED.idSursa, DELETED.idStorno
		INTO #legaturiStornareSterse(idSursa,idStorno)
		from LegaturiStornare l
		JOIN #idDeSters i on (i.idPozDoc=l.idsursa OR i.idPozDoc= l.idStorno)
	end

	/** Se sterg datele din PozDoc si se retin in #pozd **/
	delete pozdoc
	OUTPUT DELETED.Cantitate,DELETED.TVa_deductibil,DELETED.Subunitate,DELETED.Tip,DELETED.Numar,DELETED.Cod,DELETED.Data,DELETED.Gestiune,
		DELETED.Pret_valuta,DELETED.Pret_de_stoc,DELETED.Adaos,DELETED.Pret_vanzare,DELETED.Pret_cu_amanuntul,DELETED.Cota_TVA,
		DELETED.Utilizator,DELETED.Data_operarii,DELETED.Ora_operarii,DELETED.Cod_intrare,DELETED.Cont_de_stoc,DELETED.Cont_corespondent,
		DELETED.TVA_neexigibil,DELETED.Pret_amanunt_predator,DELETED.Tip_miscare,DELETED.Locatie,DELETED.Data_expirarii,DELETED.Numar_pozitie,
		DELETED.Loc_de_munca,DELETED.Comanda,DELETED.Barcod,DELETED.Cont_intermediar,DELETED.Cont_venituri,DELETED.Discount,DELETED.Tert,DELETED.Factura,
		DELETED.Gestiune_primitoare,DELETED.Numar_DVI,DELETED.Stare,DELETED.Grupa,DELETED.Cont_factura,DELETED.Valuta,DELETED.Curs,
		DELETED.Data_facturii,DELETED.Data_scadentei,DELETED.Procent_vama,DELETED.Suprataxe_vama,DELETED.Accize_cumparare,DELETED.Accize_datorate,
		DELETED.Contract,DELETED.Jurnal,CONVERT(FLOAT,0) as cumulat,0 as nrordmin,0 as nrordmax,deleted.tva_deductibil/deleted.cantitate as tvaunit,0,0, 
		DELETED.idPozDoc,deleted.detalii
	INTO #pozd
	from pozdoc 
	JOIN #idDeSters on #idDeSters.idPozDoc=pozdoc.idPozDoc	
	
	/*Se da refacere stocuri. Altfel data stocului este eronta*/
	--exec RefacereStocuri @cGestiune=@gestiune,@ccod=@cod,@cMarca=null,@dData=null,@pretmed=0,@inlocpret=0 --and @farainlocpretdoc=0'

	update #pozd 
		set nrp=ranc
	from 
		(
			select 
				p2.subunitate,p2.tip,p2.numar,p2.data,p2.numar_pozitie,	ROW_NUMBER() over (partition by p2.cod order by p2.cod,p2.data) as ranc
			from #pozd p2
		) p1 
	where p1.subunitate=#pozd.subunitate and p1.tip=#pozd.tip and p1.numar=#pozd.numar and p1.data=#pozd.data and p1.numar_pozitie=#pozd.Numar_pozitie

	update #pozd 
		set nrpozmax=maxpoz 
	from 
		(
			select 
				p2.subunitate,p2.tip,p2.numar,p2.data,MAX(p2.numar_pozitie) as maxpoz
			from pozdoc p2
			inner join #pozd p3 on p2.subunitate=p3.subunitate and p2.tip=p3.tip and p2.numar=p3.numar and p2.data=p3.data 
			group by p2.subunitate,p2.tip,p2.numar,p2.data
		) p1
	 where p1.subunitate=#pozd.subunitate and p1.tip=#pozd.tip and p1.numar=#pozd.numar and p1.data=#pozd.data 

	select 
		row_number() over (partition by tip_gestiune,cod_gestiune,cod order by data) as nrord,convert(float,0.00) as stoctotal,
		Subunitate, Tip_gestiune, Cod_gestiune, Cod, Data, Cod_intrare, Pret, Stoc_initial, Intrari, Iesiri, Data_ultimei_iesiri, Stoc, Cont, Data_expirarii, Stoc_ce_se_calculeaza, Are_documente_in_perioada, TVA_neexigibil, Pret_cu_amanuntul, Locatie, Pret_vanzare, Loc_de_munca, Comanda, Contract, Furnizor, Lot, Stoc_initial_UM2, Intrari_UM2, Iesiri_UM2, Stoc_UM2, Stoc2_ce_se_calculeaza, Val1, Alfa1, Data1,idIntrare,idIntrareFirma
	into #stoctotal
	from stocuri
	where 
		(@cod='' or cod=@cod)
		and (@gestiune='' or cod_gestiune=@gestiune)
		and cod in (select distinct cod from #pozd)
		and rtrim(Cod_intrare)!=''
		and stoc>=0.001

	/* Mai punem o linie in stocuri cu cod intrare necompletat din stocuri*/ 

	insert into #stoctotal
	select distinct 
		s1.nrord+1,0,s1.Subunitate,s1.Tip_gestiune,s1.Cod_gestiune,s1.Cod,dateadd(day,1,s1.Data),'' as cod_intrare,
		s1.Pret,10000000,10000000,0,s1.Data_ultimei_iesiri,10000000,s1.Cont,s1.Data_expirarii,s1.Stoc_ce_se_calculeaza,s1.Are_documente_in_perioada,
		s1.TVA_neexigibil,s1.Pret_cu_amanuntul,s1.Locatie,s1.Pret_vanzare,s1.Loc_de_munca,s1.Comanda,s1.Contract,s1.Furnizor,s1.Lot,s1.Stoc_initial_UM2,
		s1.Intrari_UM2,s1.Iesiri_UM2,s1.Stoc_UM2,s1.Stoc2_ce_se_calculeaza,s1.Val1,s1.Alfa1,s1.Data1,null as idIntrare,null as idIntrareFirma
	from #stoctotal s1
	inner join 
		(
			select 
				s1.Tip_gestiune,s1.Cod_gestiune,s1.Cod,MAX(nrord) as nrord
			from #stoctotal s1
			group by s1.Tip_gestiune,s1.Cod_gestiune,s1.Cod
		) sm on s1.Tip_gestiune=sm.Tip_gestiune and s1.Cod_gestiune=sm.Cod_gestiune and s1.Cod=sm.Cod and s1.nrord=sm.nrord

	/* Mai punem o linie in stocuri cu cod intrare necompletat din pozdoc */
	insert into #stoctotal
	select 
		1,0,p.Subunitate,ISNULL(g.Tip_gestiune,'C'),p.gestiune,p.Cod,min(p.Data),'' as cod_intrare,
		max(p.Pret_de_stoc),10000000,10000000,0,min(p.Data),10000000,max(p.Cont_de_stoc),min(p.Data),0,0,max(p.TVA_neexigibil),max(p.Pret_cu_amanuntul),
		max(p.Locatie),max(p.Pret_vanzare),max(p.Loc_de_munca),max(p.Comanda),max(p.Contract),'','',0,0,0,0,0,0,'',min(p.Data),null as idIntrare,null as idIntrareFirma
	from #pozd p
	left outer join gestiuni g on g.Subunitate=p.subunitate and g.Cod_gestiune=p.gestiune
	left outer join #stoctotal s on s.subunitate=p.subunitate and s.cod_gestiune=p.gestiune and s.cod=p.cod
	where s.cod is null -- echivalent "not exists"
	group by p.subunitate,ISNULL(g.Tip_gestiune,'C'),p.gestiune,p.Cod

	update #stoctotal 
		set stoctotal=st
	from 
		(	select 
				s1.Tip_gestiune,s1.Cod_gestiune,s1.Cod,s1.nrord,SUM(s2.stoc) as st from #stoctotal s1,#stoctotal s2
			where s1.Tip_gestiune=s2.Tip_gestiune and s1.Cod_gestiune=s2.Cod_gestiune and s1.Cod=s2.Cod and s2.nrord<=s1.nrord
			group by s1.Tip_gestiune,s1.Cod_gestiune,s1.Cod,s1.nrord
		) calcule 
	where 
		calcule.Tip_gestiune=#stoctotal.Tip_gestiune and calcule.Cod_gestiune=#stoctotal.Cod_gestiune and
		calcule.Cod=#stoctotal.Cod and calcule.nrord=#stoctotal.nrord

	update #pozd 
		set cumulat=tot.cum
	from 
		(
			select
				 c1.subunitate,c1.tip,c1.Numar,c1.cod,c1.comanda,c1.Loc_de_munca,c1.Data,c1.nrp,SUM(c2.cantitate) as cum from #pozd c1
			inner join #pozd c2 on c1.cod=c2.cod and c1.gestiune=c2.gestiune and c2.nrp<=c1.nrp
			group by c1.subunitate,c1.tip,c1.Numar,c1.cod,c1.comanda,c1.Loc_de_munca,c1.Data,c1.nrp
		) tot
	where 
		#pozd.subunitate=tot.subunitate and #pozd.tip=tot.tip and #pozd.Numar=tot.Numar and #pozd.cod=tot.cod and #pozd.comanda=tot.comanda and #pozd.nrp=tot.nrp

	/* Punem min si max */
	update #pozd set nrordmin=st.nrord,nrordmax=st2.nrord
	from #pozd c
		cross apply
			(select top 1 smin.nrord from #stoctotal smin where smin.cod=c.cod and smin.Cod_gestiune=c.gestiune and c.cumulat-c.cantitate<smin.stoctotal order by smin.stoctotal) st 
		cross apply
			(select top 1 smax.nrord from #stoctotal smax where smax.cod=c.cod and smax.Cod_gestiune=c.gestiune and c.cumulat<=smax.stoctotal order by smax.stoctotal) st2
	
	/* Mica corectie pentru numere negative ce trebuie sa fie sparte*/	
	update #pozd set nrordmin=nrordmax where nrordmin>nrordmax
  
	IF OBJECT_ID('tempdb..#inserate') is not null
		drop table #inserate
	CREATE table #inserate (idPozDoc int, idPozDocVechi int)

	MERGE pozdoc
	using 
	(select 
		/* Pentru verificari s1.nrord,s1.stoctotal,pd.cantitate as c1,pd.cumulat,s1.stoc,pd.nrordmin,pd.nrordmax */
		(case 
			when pd.nrordmin=pd.nrordmax or pd.cantitate<0 
				then pd.cantitate
			when pd.nrordmin=s1.nrord --prima linie de pe stoc
				then pd.cantitate-(pd.cumulat-s1.stoctotal)
			when pd.nrordmax=s1.nrord --ultima linie de pe stoc
				then (pd.cumulat+s1.stoc-s1.stoctotal)
		  else s1.stoc
		end) as cantitate,
		(case 
			when pd.nrordmin=pd.nrordmax or pd.cantitate<0 
				then pd.cantitate
			when pd.nrordmin=s1.nrord --prima linie de pe stoc
				then pd.cantitate-(pd.cumulat-s1.stoctotal)
			when pd.nrordmax=s1.nrord --ultima linie de pe stoc
				then (pd.cumulat+s1.stoc-s1.stoctotal)
		  else s1.stoc
		end)*pd.tvaunit TVa_deductibil,
		pd.Subunitate,pd.Tip,pd.Numar,pd.Cod,pd.Data,pd.Gestiune,pd.Pret_valuta,s1.Pret as pret_de_stoc,pd.Adaos,pd.Pret_vanzare,pd.Pret_cu_amanuntul,pd.Cota_TVA,pd.Utilizator,pd.Data_operarii,pd.Ora_operarii,
		s1.Cod_intrare,s1.Cont Cont_de_stoc ,pd.Cont_corespondent,pd.TVA_neexigibil,
		s1.Pret_cu_amanuntul Pret_amanunt_predator,pd.Tip_miscare,pd.Locatie,pd.Data_expirarii,
		pd.nrpozmax+ROW_NUMBER() over (order by pd.numar_pozitie) Numar_pozitie,
		pd.Loc_de_munca,pd.Comanda,pd.Barcod,pd.Cont_intermediar,pd.Cont_venituri,pd.Discount,pd.Tert,pd.Factura,pd.Gestiune_primitoare,pd.Numar_DVI,pd.Stare,
		(case when tip='TE' then ''
			/*(case when 1=0 and sprim.cod is not null then pd.Grupa 
			else LEFT(newid(),13) --rtrim(s1.cod_intrare)+ltrim(str(row_number() over (partition by pd.cod order by pd.numar_pozitie)))
			end)*/
		else pd.Grupa end) Grupa,
		pd.Cont_factura,pd.Valuta,pd.Curs,pd.Data_facturii,pd.Data_scadentei,pd.Procent_vama,pd.Suprataxe_vama,pd.Accize_cumparare,pd.Accize_datorate,pd.Contract,pd.Jurnal,
		pd.idPozDoc,s1.idIntrare,s1.idIntrareFirma,pd.detalii
		from #pozd pd
     	left outer join #stoctotal s1 on s1.cod_gestiune=pd.gestiune and s1.Cod=pd.cod and s1.nrord between pd.nrordmin and pd.nrordmax
		/*Pentru transferuri mai fac un join */
		--left outer join stocuri sprim on pd.tip='TE' and sprim.Subunitate=pd.Subunitate and 
		--	sprim.Cod_gestiune=pd.Gestiune_primitoare and sprim.cod=pd.cod and sprim.Cod_intrare=pd.Grupa and sprim.Cont=pd.Cont_corespondent and sprim.Pret=pd.Pret_de_stoc
		--	and sprim.pret_cu_amanuntul=pd.Pret_cu_amanuntul
	) pd
	on (1=0)
	when not MATCHED THEN
	insert (
		Cantitate,TVa_deductibil,Subunitate,Tip,Numar,Cod,Data,Gestiune,Pret_valuta,Pret_de_stoc,Adaos,Pret_vanzare,Pret_cu_amanuntul,Cota_TVA,Utilizator,
		Data_operarii,Ora_operarii,Cod_intrare,Cont_de_stoc,Cont_corespondent,TVA_neexigibil,Pret_amanunt_predator,Tip_miscare,Locatie,Data_expirarii,
		Numar_pozitie,Loc_de_munca,Comanda,Barcod,Cont_intermediar,Cont_venituri,Discount,Tert,Factura,Gestiune_primitoare,Numar_DVI,Stare,Grupa,Cont_factura,
		Valuta,Curs,Data_facturii,Data_scadentei,Procent_vama,Suprataxe_vama,Accize_cumparare,Accize_datorate,Contract,Jurnal,idIntrare,idIntrareFirma,detalii)
	VALUES(
		pd.Cantitate,pd.TVa_deductibil,pd.Subunitate,pd.Tip,pd.Numar,pd.Cod,pd.Data,pd.Gestiune,pd.Pret_valuta,pd.Pret_de_stoc,pd.Adaos,pd.Pret_vanzare,
		pd.Pret_cu_amanuntul,pd.Cota_TVA,pd.Utilizator,pd.Data_operarii,pd.Ora_operarii,pd.Cod_intrare,pd.Cont_de_stoc,pd.Cont_corespondent,pd.TVA_neexigibil,
		pd.Pret_amanunt_predator,pd.Tip_miscare,pd.Locatie,pd.Data_expirarii,pd.Numar_pozitie,pd.Loc_de_munca,pd.Comanda,pd.Barcod,pd.Cont_intermediar,
		pd.Cont_venituri,pd.Discount,pd.Tert,pd.Factura,pd.Gestiune_primitoare,pd.Numar_DVI,pd.Stare,pd.Grupa,pd.Cont_factura,pd.Valuta,pd.Curs,pd.Data_facturii,
		pd.Data_scadentei,pd.Procent_vama,pd.Suprataxe_vama,pd.Accize_cumparare,pd.Accize_datorate,pd.Contract,pd.Jurnal,pd.idIntrare,pd.idIntrareFirma,pd.detalii)
	OUTPUT INSERTED.idPozdoc, pd.idPozDoc
	into #inserate(idPozDoc, idPozDocVechi);
		
	if @amLegaturiContracte=1
	/** Re-inseram legaturile in LegaturiContracte -- daca exista**/
		insert into LegaturiContracte(idJurnal,idPozContract,idPozDoc,idPozContractCorespondent)
		select 
			ls.idJurnal, ls.idPozContract, i.idPozDoc, ls.idPozContractCorespondent
		from #legaturiContracteSterse ls
		JOIN #inserate i on i.idPozDocVechi=ls.idPozDoc

	if @amLegaturiStornare=1
	/** Re-inseram legaturile in LegaturiStornare-- daca exista**/
		insert into LegaturiStornare(idSursa,idStorno)
		SELECT
			isr.idPozDoc, ist.idPozDoc
		from #legaturiStornareSterse l
		JOIN #inserate isr ON isr.idPozDocVechi=l.idSursa
		JOIN #inserate ist ON ist.idPozDocVechi=l.idStorno
	
	commit transaction stoc
end try        
begin catch 
	rollback transaction stoc
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()+ ' (wOPReincadrareIesiri)'
	raiserror(@eroare, 16, 1) 
end catch
*/
