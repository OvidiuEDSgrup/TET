create procedure wIaPozdoc @sesiune varchar(50), @parXML xml  
	as
	if OBJECT_ID('wIaPozdocSP') is not null
	begin
		exec wIaPozdocSP @sesiune,@parXML
		return
	end
	declare 
		@bugetari int, @zeccant varchar(20), @zeccantserv varchar(20), @subunitate char(9), @tip varchar(2), @numar varchar(20), 
		@data datetime, @cautare varchar(500),@doc xml, @areDetalii bit, @tip_doc varchar(2)
  
	exec luare_date_par 'GE','BUGETARI',@bugetari output,0,''
	exec luare_date_par 'GE','FCANT',0,0,@zeccant output
	set @zeccant=(case when isnumeric(substring(@zeccant,charindex('.',@zeccant)+1,1))=0 then '3' else substring(@zeccant,charindex('.',@zeccant)+1,1) end)
	exec luare_date_par 'GE','FCANTSERV',0,0,@zeccantserv output
	set @zeccantserv=(case when isnumeric(substring(@zeccantserv,charindex('.',@zeccantserv)+1,1))=0 then '3' else substring(@zeccantserv,charindex('.',@zeccantserv)+1,1) end)

	select 
		@subunitate=ISNULL(@parXML.value('(/row/@subunitate)[1]', 'varchar(9)'), ''),  
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),  
		@data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '01/01/1901'),  
		@numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),
		@cautare=ISNULL(@parXML.value('(/row/@_cautare)[1]', 'varchar(500)'), '')

	-- variabila folosita pt. filtrarea tipului de document in tabelele doc/pozdoc, pentru ca sa nu facem multe case-uri
	SELECT
		@tip_doc=(case when @tip in ('RC','RA','RF') then 'RM' when @tip in ('AA','AB') then 'AP' else @tip end)   
	if OBJECT_ID('tempdb..#wPozDoc') is not null
		drop table #wPozDoc

	select 
		(case when (select top 1 serie from pdserii where @Tip=Tip and @Data=Data and @Numar=Numar and @subunitate=Subunitate and Cod=p.Cod and Cod_intrare=p.Cod_intrare and Numar_pozitie=p.Numar_pozitie) is null then 1 
					 when p.tip='RP' then 3 --pozitiile cu prestari sa apara ultimele in lista
					 else 2 end)as ordonare,
		rtrim(p.subunitate) as subunitate,  
			/*rtrim(case when p.tip='RM' and p.jurnal='RC' then 'RC' else p.tip end)*/ @tip as tip,
		case when isnull(p.subtip, '')<>'' then p.subtip /* in anumite cazuri, subtip se scrie eronat '' in loc de null */
			else
				/*
				Daca exista SUBTIP completat este mai tare, altfel tot felul.
				Linia cu tot felul va fi eliminata complet in 6 luni printr-un update adica in data de 14 Septembrie 2013 - sper.
				*/		
				rtrim(case 
					when p.tip='RM' and p.jurnal='RC' then 'RC' --when p.tip='RM' and p.cantitate<0 then 'RN'
					when p.Tip='RM' then (case when n.UM_2='Y' then 'MR' else 'RM' end)
					when p.Tip='PP' then (case when n.UM_2='Y' then 'PM' else 'PP' end) 
					when p.Tip='CM' then (case when n.UM_2='Y' then 'MC' else 'CM' end)
					when p.Tip='AI' then (case when n.UM_2='Y' then 'AM' else 'AI' end)
					when p.Tip='AE' then (case when n.UM_2='Y' then 'AM' else 'AE' end)
					when p.Tip='AP' then (case when n.UM_2='Y' then 'AM' else 'AP' end)
					when p.Tip='TE' then (case when n.UM_2='Y' then 'TM' else 'TE' end)
					else p.tip 
				end) end as subtip,
			rtrim(p.numar) as numar, convert(char(10),p.data,101) as data,  p.numar_pozitie, 
		rtrim(p.cod) as cod, rtrim(p.cod) as codcodi, rtrim(p.gestiune) as gestiune, rtrim(p.gestiune_primitoare) as gestprim,   
		rtrim(p.tert) as tert, rtrim(p.loc_de_munca) as lm,       
	---despartire camp comanda in comanda(primele 20 caractere) si indicator bugetar(ultimele 20 caractere)
		rtrim(left(p.comanda,20)) as comanda, isnull(rtrim(com.descriere), '') as dencomanda,substring(p.comanda,21,20) as indbug,
		isnull(substring(indb.indbug,1,2),'  ')+'.'+isnull(substring(indb.indbug,3,2),'  ')+'.'+isnull(substring(indb.indbug,5,2),'  ')+'.'+isnull(substring(indb.indbug,7,2),'  ')+'.'
			+isnull(substring(indb.indbug,9,2),'  ')+'.'+isnull(substring(indb.indbug,11,2),'  ')+'.'+isnull(substring(indb.indbug,13,2),'  ')+' - '+rtrim(ltrim(indb.denumire)) as denbug,	
		rtrim(p.cod_intrare) as codintrare, 
		convert(decimal(12), p.Procent_vama) as tiptva,
		(case when @tip_doc in ('RM','RS') and p.Procent_vama=0 then '0-TVA Deductibil'
			when @tip_doc in ('RM','RS') and p.Procent_vama=1 then '1-TVA Compensat'
			when @tip_doc in ('RM','RS') and p.Procent_vama=2 then '2-TVA Nedeductibil'
			when @tip in ('AP', 'AS', 'AC') and p.Procent_vama=0 then '0-TVA Colectat' 
			when @tip in ('AP', 'AS', 'AC') and p.Procent_vama=1 then '1-TVA Compensat' 
			when @tip in ('AP', 'AS', 'AC') and p.Procent_vama=2 then '2-TVA Neinregistrat' else '' end ) as dentiptva,
		convert(decimal(17, 3),round(p.cantitate,(case when p.Tip in ('AS','RS') 
		and @zeccantserv<>'' then convert(int,@zeccantserv) else convert(int,@zeccant) end))) as cantitate, 
		convert(decimal(17, 5), p.pret_valuta) as pvaluta, 
		convert(decimal(17, 2), round(convert(decimal(18,5),p.cantitate*p.pret_valuta),2)) as valvaluta, 
		convert(decimal(17, 2), round(convert(decimal(18,5),p.cantitate*p.pret_de_stoc),2)) as valstoc, 
		convert(decimal(17, 5), p.pret_de_stoc) as pstoc, convert(decimal(17, 5), p.pret_vanzare) as pvanzare,   
		convert(decimal(17, 5), p.pret_cu_amanuntul) as pamanunt, convert(varchar(5),convert(decimal(5,2), p.cota_tva)) as cotatva,   
		convert(decimal(17, 2), p.TVA_deductibil) as sumatva,
		convert(decimal(17, 2), p.TVA_deductibil/(case when p.valuta='' or p.curs=0 then 1 else p.curs end)) as tvavaluta,   
		(case when p.Pret_de_stoc>0.0 then convert(decimal(17, 2), (p.pret_vanzare/p.Pret_de_stoc-1)*100.0) end ) as adaos, 
		p.numar_pozitie as numarpozitie,   
		rtrim(p.cont_de_stoc) as contstoc, rtrim(p.valuta) as valuta, convert(decimal(10, 4), p.curs) as curs,  
		rtrim(p.locatie) as locatie, rtrim(p.contract) as [contract], rtrim(p.factura) as factura,
		rtrim(case when p.tip in ('TE','DF') then p.grupa else '' end) as codiprimitor,  
		rtrim(isnull(nullif(p.lot,''),isnull(pozi.lot,''))) as lot,  
		convert (char(10),p.data_expirarii,101) as dataexpirarii,   
		rtrim(case when p.tip in ('AI', 'AE', 'DF') then left(p.factura, 8)+left(p.contract, 8) 
			when p.tip in ('RS') then p.Numar_DVI else '' end) as explicatii, 
		rtrim(p.jurnal) as jurnal, 
		rtrim(p.cont_factura) as contfactura, convert(decimal(5, 2), p.discount) as discount,   

		--> total cu tva in pozitii documente
		convert(decimal(17,2), round(convert(decimal(18,5), p.cantitate * p.pret_valuta), 2)
			+ convert(decimal(17,2), p.TVA_deductibil/(case when p.valuta = '' or p.curs = 0 then 1 else p.curs end))) as valcutva,

	---in campul numar_dvi se salveaza si punctul de livrare incepand cu caracterul 14--- 
		rtrim(left(p.numar_DVI,13)) as dvi,
		rtrim(case when p.tip in ('AP', 'AS', 'AC') then substring(p.numar_DVI, 14, 5) else '' end) as punctlivrare,  
		rtrim(case when p.tip in ('AP', 'AS', 'AC') then rtrim(it.Descriere) else '' end) as denpunctlivrare,  

		rtrim(p.barcod) as barcod, rtrim(p.cont_corespondent) as contcorespondent,   
		(case when p.tip in ('AP', 'AS', 'AC', 'TE') then convert(int, p.accize_cumparare) else 0 end) as categpret,   
		convert(decimal(17, 3), p.accize_cumparare) as accizecump,   
		rtrim(p.cont_venituri) as contvenituri,   
		rtrim(p.cont_intermediar) as contintermediar,   
		rtrim(p.cod_intrare) as dencodintrare,   
		rtrim(isnull(n.denumire, '')) as denumire, RTRIM(ISNULL(n.denumire,'')) as dencodcodi, rtrim(isnull(n.UM, '')) as um,   
		isnull(rtrim(left(gest.denumire_gestiune, 30)), '') as dengestiune, isnull(rtrim(gest.tip_gestiune), '') as tipgestiune,   
		isnull(rtrim(left(gestP.denumire_gestiune, 30)), '') as dengestprim, isnull(rtrim(gestP.tip_gestiune), '') as tipgestprim,   
		isnull(rtrim(lm.denumire), '') as denlm, isnull(rtrim(t.denumire), '') as dentert,  
		convert(decimal(5, 2), p.TVA_neexigibil) as tvaneexigibil,
		--rtrim(ltrim(tex.Alfa2)) as text_alfa2,
		(case when p.Tip_miscare<>'V' and p.Cod_intrare='' /*or p.tip not in ('RM', 'RS') and (ccor.Cont is null or isnull(ccor.Are_analitice, 0)=1)*/ then '#FF0000'
				when p.tip='RP' then '#4AA02C'--pozitie cu prestare pe receptie     
				else '#000000' end)as culoare,
		(case when p.tip='RP' then 'Prest. fact: '+rtrim(p.Factura)+', Tert: '+RTRIM(p.Tert)+'-'+RTRIM(t.Denumire) else rtrim(p.cod)+'-'+rtrim(n.denumire)end) as cod_de,	
		rtrim(p.utilizator) as utilizator, convert (char(10),p.data_operarii,103) as data_operarii, p.idpozdoc idpozdoc,
		p.colet colet,
		convert(xml, null) detalii, 
				
				---->>>>> start Cod specific lucrului pe serii- aduce seriile pt fiecare pozitie din pozdoc care are serii<<<<<--------
		(select RTRIM(pds.gestiune) as gestiune,   RTRIM(pds.cod) as cod,rtrim(pds.Cod)+'-'+rtrim(n.Denumire) as dencod,   RTRIM(pds.cod_intrare) as codintrareS,  rtrim(pds.Serie) as cod_de,   
				CONVERT(decimal(12,3),pds.cantitate) as cantitate,	RTRIM(pds.tip_miscare) as tip_miscare,  RTRIM(pds.numar_pozitie) as numarpozitie,  
				RTRIM(gestiune_primitoare) as gestiune_primitoare,rtrim(isnull(n.UM, '')) as um,'#08088A'as culoare  ,convert(decimal(14, 5), p.pret_de_stoc) as pstocS,
				(case when charindex(',',pds.Serie)<>0 then SUBSTRING(pds.serie,charindex(',',pds.Serie)+1,LEN(pds.Serie)-charindex(',',pds.serie)) else '' end) as prop2,
				(case when charindex(',',pds.Serie)<>0 then SUBSTRING(pds.Serie,1,charindex(',',pds.Serie)-1)else RTRIM(pds.Serie)end) as prop1 ,convert(decimal(14, 5), p.pret_valuta) as pvalutaS,
				(case when charindex(',',pds.Serie)<>0 then SUBSTRING(pds.serie,charindex(',',pds.Serie)+1,LEN(pds.Serie)-charindex(',',pds.serie)) else '' end) as denprop2,
				(case when charindex(',',pds.Serie)<>0 then SUBSTRING(pds.Serie,1,charindex(',',pds.Serie)-1)else RTRIM(pds.Serie)end) as denprop1 ,
				RTRIM(pds.Serie) as serie,'SE' as subtip,'da' as _expandat
			from pdserii pds
			left join nomencl n on n.Cod=pds.Cod
			where @Tip=pds.Tip and @Data=pds.Data and @Numar=pds.Numar and @subunitate=pds.Subunitate and pds.Cod=p.Cod and pds.Cod_intrare=p.Cod_intrare and pds.Numar_pozitie=p.Numar_pozitie
			order by pds.Serie
			for xml raw,type
			) serii	
				---->>>>> stop Cod specific lucrului pe serii- aduce seriile pt fiecare pozitie din pozdoc care are serii<<<<<--------	
		into #wPozDoc
		from pozdoc p  
			--left outer join textpozdoc tex on tex.Subunitate=p.Subunitate and tex.Tip=p.Tip and tex.Numar=p.Numar and tex.Data=p.Data and tex.Numar_pozitie=p.Numar_pozitie
			left outer join nomencl n on n.cod = p.cod    
			--inner join par sub on sub.tip_parametru='GE' and sub.parametru='SUBPRO'   
			left outer join terti t on t.subunitate = p.subunitate and t.tert = p.tert  
			/*left outer join stocuri s on s.subunitate = p.subunitate and s.Cod_gestiune = p.Gestiune and s.cod=p.cod and s.Cod_intrare=p.Cod_intrare  
				and (@tip not in ('DF','PF','CI') and s.Tip_gestiune<>'F' or @tip in ('DF','PF','CI') and s.Tip_gestiune='F')	Am comentat join-ul pe stocuri intrucat nu se folosesc campurile din stocuri.*/
			left join infotert it on t.tert=it.tert and t.Subunitate=it.Subunitate and it.Identificator<>'' and it.Identificator=substring(p.numar_DVI, 14, 5) 
			left outer join gestiuni gest on gest.cod_gestiune = p.gestiune  
			left outer join gestiuni gestP on gestP.cod_gestiune = p.gestiune_primitoare  
			left outer join lm on lm.cod = p.loc_de_munca  
			left outer join comenzi com on com.subunitate = p.subunitate and com.comanda = left(p.comanda,20)  
			left outer join indbug indb on indb.Indbug = substring(p.comanda,21,20)  
			left outer join conturi ccor on @tip_doc not in ('RM', 'RS') and ccor.Subunitate=p.Subunitate and ccor.Cont=p.Cont_corespondent  
			--left outer join proprietati prop on prop.Cod_proprietate='CATEGPRET' and prop.tip='GESTIUNE' and prop.cod=p.Gestiune_primitoare
			left outer join pozdoc pozi on pozi.idPozdoc=p.idIntrareFirma 
		where p.subunitate=@subunitate and (isnull(n.Denumire,'') like '%'+@cautare+'%' or p.cod like @cautare+'%' or p.cod_intrare like @cautare+'%')
			and p.tip=@tip_doc
			and (@tip='RC' and p.jurnal='RC' or @tip<>'RC' and (p.tip<>'RM' or p.jurnal<>'RC'))
			and p.numar=@numar and p.data=@data
		order by p.numar_pozitie desc  

	if @Bugetari=1 and exists (select * from sysobjects where name ='indbugPozitieDocument' and xtype='P')
	begin
		select '' as furn_benef, 'pozdoc' as tabela, idPozdoc as idPozitieDoc, indbug into #indbugPozitieDoc 
		from #wPozDoc
		exec indbugPozitieDocument @sesiune=@sesiune, @parXML=@parXML
		update p set p.indbug=ib.indbug
		from #wPozDoc p
			left outer join #indbugPozitieDoc ib on ib.idPozitieDoc=p.idPozdoc
	end
	
	IF EXISTS (SELECT 1 FROM syscolumns sc, sysobjects so WHERE so.id = sc.id AND so.NAME = 'pozdoc' AND sc.NAME = 'detalii')
	BEGIN
		SET @areDetalii = 1
		--ALTER TABLE #wPozDoc ADD detalii XML

		UPDATE #wPozDoc
		SET detalii = pd.detalii
		FROM pozdoc pd
		WHERE #wPozDoc.idpozdoc=pd.idPozdoc	/*	merge mai rapid pe idPozdoc */
	END
	ELSE
	begin
		SET @areDetalii = 0
	end

	if OBJECT_ID('wIaPozdocSP2') is not null
	begin
		exec wIaPozdocSP2 @sesiune,@parXML -- eventual o reordonare a pozitiilor 
	end

	SET @doc = (
			SELECT ordonare, subunitate, tip, subtip, numar, data, cod, codcodi, gestiune, gestprim, tert, lm, comanda, dencomanda, indbug, 
				codintrare, tiptva, dentiptva, cantitate, pvaluta, valvaluta, valcutva, valstoc, pstoc, pvanzare, pamanunt,
				cotatva, sumatva, tvavaluta, adaos, numarpozitie, contstoc, valuta, curs, locatie, contract, factura, codiprimitor, lot,
				dataexpirarii, explicatii, jurnal, contfactura, discount, dvi, punctlivrare, barcod, contcorespondent, categpret, accizecump, contvenituri, 
				contintermediar, dencodintrare, denumire, dencodcodi, um, dengestiune, tipgestiune, dengestprim, tipgestprim, denlm, 
				dentert, tvaneexigibil, culoare, cod_de, utilizator, data_operarii, detalii, idpozdoc, colet, serii.query('.')
			FROM #wPozDoc
			order by ordonare, numar_pozitie desc
			FOR XML raw, root('Ierarhie')
			)

	SELECT @doc	FOR XML path('Date')	

	select @areDetalii areDetaliiXml for xml raw, root('Mesaje')
