--***
create procedure wIaVerificareDocumente @sesiune varchar(50), @parXML XML    
as   
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wIaVerificareDocumenteSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wIaVerificareDocumenteSP @sesiune, @parXML output
	return @returnValue
end 
begin try
	declare @data_jos datetime,@data_sus datetime,@sub varchar(9),@contCheltTVANededuct varchar(40),@utilizator varchar(20),@mesajeroare varchar(500),
		@filtruNrDoc varchar(100),@filtruContDebit varchar(40),@filtruContCredit varchar(40),@tip varchar(3),
		@filtruCod varchar(20),@filtruGest varchar(9),@filtruTert varchar(50),@filtruFactura varchar(40),@dincgplus int,
		@datadoc_jos varchar(50), @datadoc_sus varchar(50), @locMunca varchar(100)

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	exec luare_date_par 'GE', 'CCTVANED', 0, 0, @contCheltTVANededuct output
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  	
	--citire date din xml
	select 
		@tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(3)'),''),
		@data_jos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1901-01-01'),
		@data_sus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2099-01-01'),
		@filtruNrDoc = isnull(@parXML.value('(/row/@filtruNrDoc)[1]','varchar(100)'),''),
		@filtruContDebit = isnull(@parXML.value('(/row/@filtruContDebit)[1]','varchar(40)'),''),
		@filtruContCredit = isnull(@parXML.value('(/row/@filtruContCredit)[1]','varchar(40)'),''),
		@filtruCod = isnull(@parXML.value('(/row/@filtruCod)[1]','varchar(100)'),''),
		@filtruGest = isnull(@parXML.value('(/row/@filtruGest)[1]','varchar(13)'),''),
		@filtruTert = isnull(@parXML.value('(/row/@filtruTert)[1]','varchar(13)'),''),
		@filtruFactura = isnull(@parXML.value('(/row/@filtruFactura)[1]','varchar(40)'),''),
		@dincgplus = isnull(@parXML.value('(/row/@dincgplus)[1]','int'),0),
		@datadoc_jos = @parXML.value('(/row/@filtruDataDocJos)[1]', 'varchar(50)'),
		@datadoc_sus = @parXML.value('(/row/@filtruDataDocSus)[1]', 'varchar(50)'),
		@locMunca = isnull(@parXML.value('(/row/@filtruLocMunca)[1]', 'varchar(100)'), '')
		
	declare @dDataIstoric datetime, @nAnInc int, @nLunaInc int, @dDImpl datetime, @nAnImpl int, @nLunaImpl int, @nAnInitFact int, @dDIniFac datetime
	set @nAnInc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULINC'), 1901)
	set @nLunaInc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAINC'), 1)
	set @dDataIstoric=dbo.eom(dateadd(year, @nAnInc-1901, dateadd(month, @nLunaInc-1, '01/01/1901')))
	set @nAnImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULIMPL'),0)
	set	@nLunaImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAIMPL'),0)
	set @dDImpl=dateadd(day,-1,dateadd(month,@nLunaImpl,dateadd(year,@nAnImpl-1901,'01/01/1901'))) 
	set @nAnInitFact=(select max(val_numerica) from par where tip_parametru='GE' and parametru='ULT_AN_IN')
	if isnull(@nAnInitFact,0)<1901
		set @nAnInitFact=@nAnImpl
	set @dDIniFac=dbo.eom(dateadd(year, @nAnInitFact-1901, '01/01/1901'))
		
	if @tip='CE'--conturi eronate
	begin
		--****inregistrari contabile
		--cont debit
		IF OBJECT_ID('tempdb..#conturiEronate') IS NOT NULL drop table #conturiEronate
		select	rtrim(pozincon.Subunitate) as subunitate, rtrim(case when tip_document='PI' then left(explicatii,2) else tip_document end) as tip_document, 
				rtrim(numar_document) as numar_document, convert(char(10),data,101)as data, cont_debitor, cont_creditor,
				(case when (cont_debitor='' ) then 'Cont debitor necompletat'
				when (isnull(c.cont,'')='' and Cont_debitor<>'') then 'Cont debit inexistent in planul de conturi' 
				when (isnull (c.cont,'')='' and isnull(c.Are_analitice,0)=0 and Cont_debitor<>'') then 'Cont debit are analitice'
				when (cont_debitor<>'' and left(cont_debitor,1)<>'8'and left(cont_creditor,1)='8') then 'Cont nepermis in coresp. cu cont clasa 8/9'
				when (cont_debitor<>'' and left(cont_debitor,1)<>'9'and left(cont_creditor,1)='9') then 'Cont nepermis in coresp. cu cont clasa 8/9'						   
				end ) as explicatii, 
				rtrim(convert(decimal(17,2),suma)) as suma  			 
		into #conturiEronate
		from (select * from pozincon where pozincon.Subunitate=@sub and data between @data_jos and @data_sus and convert(decimal(17,2),suma)<>0.00) pozincon
		left join conturi c on c.Subunitate=pozincon.Subunitate and  c.Cont=pozincon.Cont_debitor
		where   (cont_debitor='' and left(cont_creditor,1)<>'8' 
				or cont_debitor<>'' and left(cont_debitor,1)<>'8' and left(cont_creditor,1)='8' and left(cont_creditor,3) not in ('891','892') 
				or cont_debitor<>'' and left(cont_debitor,1)<>'9' and left(cont_creditor,1)='9'  
				or cont_debitor<>'' and c.Are_analitice=1)
		union all
		----cont credit
		select rtrim(pozincon.subunitate) as subunitate, (case when tip_document='PI' then left(explicatii,2) else tip_document end) as tip_document, 
				numar_document as numar_document, convert(char(10),data,101)as data, 
				cont_debitor as cont_debitor, Cont_creditor as cont_creditor,
			(case when cont_creditor=''  then 'Cont credit necompletat'
				when (isnull(c.cont,'')='' and Cont_creditor<>'') then 'Cont credit inexistent in planul de conturi' 
				when (isnull (c.cont,'')='' and isnull(c.are_analitice,0)=0 and Cont_creditor<>'') then 'Cont credit are analitice'
				when (cont_creditor<>''and left(cont_creditor,1)<>'8' and left(cont_debitor,1)='8') then 'Cont nepermis in coresp. cu cont clasa 8/9'
				when (cont_creditor<>''and left(cont_creditor,1)<>'9' and left(cont_debitor,1)='9') then 'Cont nepermis in coresp. cu cont clasa 8/9'						   
				end ) as explicatii, 
			rtrim(convert(decimal(15,2),suma)) as suma 			 
		from (select * from pozincon where pozincon.Subunitate=@sub and data between @data_jos and @data_sus ) pozincon
		left join conturi c on  c.Subunitate=pozincon.Subunitate and c.Cont=pozincon.Cont_creditor
		where 
			(cont_creditor='' and left(cont_debitor,1)<>'8' 
				or cont_creditor<>''and left(cont_creditor,1)<>'8' and left(cont_debitor,1)='8' and left(cont_debitor,3) not in ('891','892')  
				or cont_creditor<>''and left(cont_creditor,1)<>'9' and left(cont_debitor,1)='9' 
				or cont_creditor<>'' and ISNULL(are_analitice,0)=1)
				
		select	rtrim(subunitate) as subunitate, rtrim(tip_document) as tip_document, rtrim(numar_document) as numar_document, 
				rtrim(data) as data, rtrim(Cont_debitor) as cont_debitor, rtrim(Cont_creditor)as cont_creditor,  explicatii as explicatii,	rtrim(suma) as suma from #conturiEronate
		where explicatii<>'' and (Cont_debitor like @filtruContDebit+'%' or @filtruContDebit='')
			and (Cont_creditor like @filtruContCredit+'%' or @filtruContCredit='')
			and (Numar_document like @filtruNrDoc+'%' or @filtruNrDoc='')
		order by data desc
		for xml raw  
	end
	
	if @tip='PD'--necorelatii pret stoc<->pret intrare din documente
	begin		
	IF OBJECT_ID('tempdb..#pretIntrare') IS NOT NULL drop table #pretIntrare
	select rtrim(a.gestiune) as gestiune,b.tip_gestiune, a.tip as tip_doc, rtrim(a.numar) as numar, convert(char(10),a.data,101) as data, a.tip_miscare, a.cod, a.cod_intrare, 
			convert(decimal(12,5),a.pret_de_stoc) as pret_stoc_doc, 
			convert(decimal(15,5),b.pret) as pret_stoc_stoc,
			convert(char(10),@data_jos,101) as datajos,convert(char(10),@data_sus,101) as datasus,
			rtrim(a.loc_de_munca) as lm, rtrim(g.Denumire_gestiune) as dengestiune, convert(decimal(17,2),a.cantitate) as cantitate, 
			convert(decimal(17,2),a.cantitate*a.Pret_de_stoc) as valoare
		into #pretIntrare
		from (select * from pozdoc where subunitate=@sub and data between @data_jos and @data_sus and data>@dDataIstoric)a 
		inner join  stocuri b on a.subunitate=b.subunitate and a.gestiune=b.cod_gestiune and a.cod=b.cod and a.cod_intrare=b.cod_intrare
		left join gestiuni g on g.Cod_gestiune=a.gestiune
		where 
			a.tip in ('RM','PP','AI','CM','AP','AC','TE','AE','DF','PF','CI') 
			and b.tip_gestiune not in ('F', 'T')--,'A')
			and convert(decimal(15,5),a.pret_de_stoc)<>convert(decimal(15,5),b.pret)			
			--and convert(decimal(15,3),a.pret_de_stoc)<>convert(decimal(15,3),b.pret) 	
			
			and (a.gestiune like @filtruGest+'%' or @filtruGest='')
		union all 
		select a.gestiune_primitoare,b.tip_gestiune, (case when a.tip='TE' then 'TI' when a.tip='DF' then 'DI' else 'PI' end), a.numar, convert(char(10),a.data,101) as data, 'I', a.cod, 
			(case when a.grupa<>'' then a.grupa else a.cod_intrare end), 
			convert(decimal(12,5),(a.pret_de_stoc*(case when a.tip='DF' and a.procent_vama<>0 then (1-convert(decimal(15,2),a.procent_vama/100)) else 1 end))), 
			convert(decimal(15,3),b.pret) ,convert(char(10),@data_jos,101) as datajos,convert(char(10),@data_sus,101) as datasus,
			rtrim(a.loc_de_munca) as lm, rtrim(g.Denumire_gestiune) as dengestiune, convert(decimal(17,2),a.cantitate) as cantitate, 
			convert(decimal(17,2),a.cantitate*a.Pret_de_stoc) as valoare
		from pozdoc a
		inner join stocuri b on a.subunitate=b.subunitate and a.gestiune_primitoare=b.cod_gestiune and a.cod=b.cod and a.tip in ('TE','DF','PF') 
			and b.tip_gestiune not in ('F', 'T')
		left join gestiuni g on g.Cod_gestiune=a.gestiune
		where a.subunitate=@sub and a.data between @data_jos and @data_sus and a.data>@dDataIstoric
			and (case when a.grupa<>'' then a.grupa else a.cod_intrare end)=b.cod_intrare 
			and convert(decimal(15,5),a.pret_de_stoc*(case when a.tip='DF' and a.procent_vama<>0 then (1-convert(decimal(15,2),a.procent_vama/100)) else 1 end))<>convert(decimal(15,5),b.pret)
			and (a.Gestiune_primitoare like @filtruGest+'%' or @filtruGest='')

			select * from #pretIntrare
			where (numar like @filtruNrDoc+'%' or @filtruNrDoc='')
						and (cod like @filtruCod+'%' or @filtruCod='')		
		order by 5 desc
	
		for xml raw 
	end	
	
	if @tip='PA'--necorelatii pret stoc<->pret amanunt din documente
	begin		
		IF OBJECT_ID('tempdb..#pretAmanunt') IS NOT NULL drop table #pretAmanunt
		select	rtrim(a.gestiune) as gestiune,b.tip_gestiune, a.tip as tip_doc, 
				rtrim(a.numar) as numar, convert(char(10),a.data,101) as data, 
				a.tip_miscare, a.cod, a.cod_intrare, 
				(case when a.tip_miscare='I' then convert(decimal(15,5),a.pret_cu_amanuntul)else convert(decimal(15,5),a.pret_amanunt_predator) end) as pret_stoc_doc, 
				convert(decimal(15,5),b.Pret_cu_amanuntul) as pret_stoc_stoc,
				convert(char(10),@data_jos,101) as datajos,convert(char(10),@data_sus,101) as datasus
		into #pretAmanunt
		from (select * from pozdoc where subunitate=@sub and data between @data_jos and @data_sus and data>@dDataIstoric 
					and tip in ('RM','PP','AI','CM','AP','AC','TE','AE','DF','PF','CI') ) a
				inner join  stocuri b on a.subunitate=b.subunitate and a.gestiune=b.cod_gestiune and 
							a.cod=b.cod and a.cod_intrare=b.cod_intrare and b.tip_gestiune='A'			
		where 			
			(convert(decimal(15,2),(case when a.tip_miscare='I' then a.pret_cu_amanuntul else a.pret_amanunt_predator end))<>convert(decimal(15,2),b.pret_cu_amanuntul))
			and (a.gestiune like @filtruGest+'%' or @filtruGest='')			
		union all
		select a.gestiune_primitoare,b.tip_gestiune, (case when a.tip='TE' then 'TI' when a.tip='DF' then 'DI' else 'PI' end), a.numar, convert(char(10),a.data,101) as data, 'I', a.cod, 
			(case when a.grupa<>'' then a.grupa else a.cod_intrare end), 
			convert(decimal(15,3),a.pret_cu_amanuntul),
			convert(decimal(15,3),b.Pret_cu_amanuntul) ,convert(char(10),@data_jos,101) as datajos,convert(char(10),@data_sus,101) as datasus
		from pozdoc a, stocuri b 
		where a.subunitate=@sub and a.data between @data_jos and @data_sus and a.data>@dDataIstoric 
			and a.tip in ('TE','DF','PF') 
			and b.tip_gestiune ='A'
			and a.subunitate=b.subunitate 
			and a.gestiune_primitoare=b.cod_gestiune 
			and a.cod=b.cod 
			and (case when a.grupa<>'' then a.grupa else a.cod_intrare end)=b.cod_intrare 
			and convert(decimal(15,2),a.pret_cu_amanuntul)<>convert(decimal(15,2),b.pret_cu_amanuntul)			
			and convert(decimal(15,3),a.pret_cu_amanuntul)<>convert(decimal(15,3),b.pret_cu_amanuntul)			
			and (a.Gestiune_primitoare like @filtruGest+'%' or @filtruGest='')
			
			
		select * from #pretAmanunt	where (numar like @filtruNrDoc+'%' or @filtruNrDoc='') and (cod like @filtruCod+'%' or @filtruCod='')
		order by data desc
		for xml raw 
	end	
		
	if @tip='CD'--necorelatii conturi stoc<->conturi din documente
	begin

	IF OBJECT_ID('tempdb..#contStoc') IS NOT NULL drop table #contStoc
		
		select rtrim(a.gestiune) as gestiune,  rtrim(a.tip) as tip_doc, rtrim(a.numar) as numar, convert(char(10),a.data,101)as data, 
			rtrim(a.cod) as cod, rtrim(a.cod_intrare) as cod_intrare, rtrim(a.cont_de_stoc) as cont_stoc_doc, rtrim(b.cont ) as cont_stoc_stoc,
			convert(char(10),@data_jos,101) as datajos,convert(char(10),@data_sus,101) as datasus
			into #contStoc
		from (select * from pozdoc where subunitate=@sub and data between @data_jos and @data_sus and data>@dDataIstoric and
					tip in ('RM','PP','AI','CM','AP','AC','TE','AE','DF','PF') and (gestiune like @filtrugest+'%' or isnull(@filtrugest,'')='' ))a 
		inner join stocuri b on a.subunitate=b.subunitate and a.gestiune=b.cod_gestiune and a.cod=b.cod and a.cod_intrare=b.cod_intrare
		where (a.tip='PF' and b.tip_gestiune='F' or a.tip<>'PF' and b.tip_gestiune<>'F') 
			and a.cont_de_stoc<>b.cont
		union all 
		select  rtrim(a.Gestiune_primitoare), (case when a.tip='TE' then 'TI' when a.tip='DF' then 'DI' else 'PI' end),rtrim(a.numar) as numar, 
			convert(char(10),a.data,101)as data,rtrim(a.cod) as cod, (case when a.grupa<>'' then rtrim(a.grupa) else rtrim(a.cod_intrare) end), 
			rtrim(a.cont_corespondent) , rtrim(b.cont ),convert(char(10),@data_jos,101) as datajos,
			convert(char(10),@data_sus,101) as datasus
		from (select * from pozdoc where Subunitate=@sub and data between @data_jos and @data_sus and data>@dDataIstoric and tip in ('TE','DF','PF') )a  
		inner join stocuri b on a.subunitate=b.subunitate and a.Gestiune_primitoare=b.cod_gestiune and a.cod=b.cod and (case when a.grupa<>'' then a.grupa else a.cod_intrare end)=b.cod_intrare
		where (a.tip='TE' and b.tip_gestiune<>'F' or a.tip<>'TE' and b.tip_gestiune='F') 
			and a.cont_corespondent<>b.cont 
			and (a.gestiune_primitoare like @filtrugest+'%' or isnull(@filtrugest,'')='' )
	
		select * from #contStoc
			where (numar like @filtruNrDoc+'%' or @filtruNrDoc='')
				and (cod like @filtruCod+'%' or @filtruCod='')
		order by data desc
		for xml raw 
	end	
		declare @parXMLFact xml
		select @parXMLFact=(select @sesiune as sesiune for xml raw)
	if @tip='DF'--necorelatii cont documente <-> cont factura
	begin
		IF OBJECT_ID('tempdb..#contFactura') IS NOT NULL drop table #contFactura      
 		/* se preiau datele in tabela #pfacturi prin procedura pFacturi, in locul functiei fFacturi */
		if object_id('tempdb..#docfacturi') is not null drop table #docfacturi
		create table #docfacturi (furn_benef char(1))
		exec CreazaDiezFacturi @numeTabela='#docfacturi'
		set @parXMLFact=(select 'F' as furnbenef, @data_jos as datajos, @data_sus as datasus, 1 as strictperioada for xml raw)
		exec pFacturi @sesiune=@sesiune, @parXML=@parXMLFact

		--- pt Furnizor
		select rtrim(fF.tert) as tert, rtrim(fF.tert)+' - '+RTRIM(t.Denumire) as denTert, RTRIM(p.tip) as tip_document, RTRIM(p.numar) as numar, 
			RTRIM(CONVERT(varchar(20),p.data,101)) as data, rtrim(p.factura) as factura,
			p.Cont_de_tert as cont_tert_doc, rtrim(fF.Cont_de_tert) as cont_tert_fact,convert(char(10),@data_jos,101) as datajos,
				convert(char(10),@data_sus,101) as datasus, t.denumire 
		into #contFactura
			from #docfacturi p 
			--from dbo.fFacturi ('F', @data_jos, @data_sus, null, null, null, 0, 0, 1, null, @parXMLFact) p 
			inner join facturi fF on fF.tip=0x54 and p.Subunitate=fF.subunitate and p.Tert=fF.Tert and p.Factura=fF.Factura
			inner join terti t on t.Subunitate=p.Subunitate and t.Tert=p.Tert
			where p.Subunitate=@sub and p.cont_de_tert <> fF.Cont_de_tert
		--
		--- pt Beneficiar
		truncate table #docfacturi
		set @parXMLFact=(select 'B' as furnbenef, @data_jos as datajos, @data_sus as datasus, 1 as strictperioada for xml raw)
		exec pFacturi @sesiune=@sesiune, @parXML=@parXMLFact

		insert into #contFactura
		select rtrim(fB.tert) as tert, rtrim(fB.tert)+' - '+RTRIM(t.Denumire) as denTert, RTRIM(p.tip) as tip_document, RTRIM(p.numar) as numar, 
			RTRIM(CONVERT(varchar(20),p.data,101)) as data, rtrim(p.factura) as factura,
			p.Cont_de_tert as cont_tert_doc, rtrim(fB.Cont_de_tert) as cont_tert_fact,convert(char(10),@data_jos,101) as datajos,
				convert(char(10),@data_sus,101) as datasus, t.denumire 
			from #docfacturi p 
			--from dbo.fFacturi ('B', @data_jos, @data_sus, null, null, null, 0, 0, 1, null, @parXMLFact) p 
			inner join facturi fB on fB.tip=0x46 and p.Subunitate=fB.subunitate and p.Tert=fB.Tert and p.Factura=fB.Factura
			inner join terti t on t.Subunitate=p.Subunitate and t.Tert=p.Tert
			where p.Subunitate=@sub and p.cont_de_tert <> fB.Cont_de_tert
		---
		if @dincgplus=0
			select * from #contFactura 
			where
				(denumire like '%'+@filtruTert+'%' or Tert like @filtruTert+'%' or @filtruTert='')
					and (factura like @filtruFactura+'%' or @filtruFactura='')
					and (numar like @filtruNrDoc+'%' or @filtruNrDoc='')
			order by data desc
			for xml raw 
		else 
			select tert, denumire, tip_document, numar, data, factura, cont_tert_doc, cont_tert_fact from #contFactura 
			where
				(denumire like '%'+@filtruTert+'%' or Tert like @filtruTert+'%' or @filtruTert='')
					and (factura like @filtruFactura+'%' or @filtruFactura='')
					and (numar like @filtruNrDoc+'%' or @filtruNrDoc='')
	end

	if @tip='CT'--inregistrari eronate pentru cont credit 4426, debit 4427 sau conturi clasa 6 si 7.
	begin
		IF OBJECT_ID('tempdb..#contTVAsi67') IS NOT NULL drop table #contTVAsi67
 
		select p.subunitate, p.tip_document, rtrim(p.numar_document) as numar_document, convert(char(10),p.data,101) as data, 
			rtrim(p.cont_debitor) as cont_debitor, rtrim(p.cont_creditor) as cont_creditor, 
			'Inregistrare contabila eronata privind contul '
				+(case when p.cont_debitor='4427' or cd.tip_cont='P' and left(cont_debitor,1)='7' or cd.tip_cont='P' and left(cont_debitor,1)='6' then rtrim(p.cont_debitor) 
				when p.cont_creditor='4426' or cc.tip_cont='A' and left(cont_creditor,1)='7' or cc.tip_cont='A' and left(cont_creditor,1)='6' then rtrim(p.cont_creditor) end)+'!' as explicatii,
			rtrim(convert(decimal(17,2),suma)) as suma 
		into #contTVAsi67
		from pozincon p
			left outer join conturi cd on cd.subunitate=p.subunitate and cd.cont=p.cont_debitor
			left outer join conturi cc on cc.subunitate=p.subunitate and cc.cont=p.cont_creditor
		where p.subunitate=@sub and data between @data_jos and @data_sus
			and ((cont_debitor='4427' and cont_creditor<>'4426' and left(cont_creditor,4)<>'4423') 
				or (cont_creditor='4426' and cont_debitor<>'4427' and left(cont_debitor,4)<>'4424' and (@contCheltTVANededuct='' or cont_debitor<>@contCheltTVANededuct)
					and (p.tip_document<>'PI' 
						or not exists (select 1 from pozplin pp where pp.subunitate=p.subunitate and pp.Cont=p.Numar_document and pp.data=p.data and pp.tip_tva=3))
					and (p.tip_document not in ('RM','RS','RC') 
						or not exists (select 1 from pozdoc pd where pd.subunitate=p.subunitate and pd.Tip=p.Tip_document and pd.Numar=p.Numar_document and pd.data=p.data and pd.Procent_vama=3))
					and (p.tip_document not in ('FF') 
						or not exists (select 1 from pozadoc pa where pa.subunitate=p.subunitate and pa.Tip=p.Tip_document and pa.Numar_document=p.Numar_document and pa.data=p.data and pa.Stare=3))						) 
				or (cd.tip_cont='P' and left(cont_debitor,1)='7' and left(cont_debitor,3)<>'711' and left(cont_creditor,3)<>'121') 
				or (cc.tip_cont='A' and left(cont_creditor,1)='7' and left(cont_creditor,3)<>'711' and left(cont_debitor,3)<>'121') 
				or (cc.tip_cont='A' and left(cont_creditor,1)='6' and left(cont_debitor,3)<>'121')
				or (cd.tip_cont='P' and left(cont_debitor,1)='6' and left(cont_creditor,3)<>'121'))
	
		if @dincgplus=0
			select * from #contTVAsi67
			where (Numar_document like @filtruNrDoc+'%' or @filtruNrDoc='')
				and (Cont_debitor like @filtruContDebit+'%' or @filtruContDebit='')
				and (Cont_creditor like @filtruContCredit+'%' or @filtruContCredit='')
			order by data desc
			for xml raw 
		else 
			select subunitate, tip_document, numar_document, data, cont_debitor, cont_creditor, suma, explicatii
			from #contTVAsi67
	end

	if @tip = 'MD' -- modificari documente (dintr-o alta perioada) aferente perioadei date
	begin
		if object_id('tempdb..#docModificate') is not null
			drop table #docModificate

		select @datadoc_jos = (case when len(@datadoc_jos)>4 and ISDATE(dbo.fSchimbaZiLuna(@datadoc_jos))=1 then convert(datetime, dbo.fSchimbaZiLuna(@datadoc_jos)) end)
		select @datadoc_sus = (case when len(@datadoc_sus)>4 and ISDATE(dbo.fSchimbaZiLuna(@datadoc_sus))=1 then convert(datetime, dbo.fSchimbaZiLuna(@datadoc_sus)) end)

		select top 100
			rtrim(p.Subunitate) as subunitate, p.Tip_document as tip_doc, rtrim(p.Numar_document) as numar,
			convert(varchar(10), p.data, 101) as data, rtrim(p.Cont_debitor) as cont_debitor, rtrim(Cont_creditor) as cont_creditor,
			convert(decimal(17,2), p.suma) as suma, rtrim(p.Explicatii) as explicatii, rtrim(p.Utilizator) as utilizator,
			convert(varchar(10), p.Data_operarii, 101) as data_op, left(p.Ora_operarii, 2) + ':' + substring(p.Ora_operarii, 3, 2) as ora_op,
			rtrim(p.Loc_de_munca) as locMunca, rtrim(lm.Denumire) as denLocMunca
		into #docModificate
		from pozincon p
		left join lm on p.Loc_de_munca = lm.Cod
		where p.Data_operarii between @data_jos and @data_sus
			and (@locMunca = '' or p.Loc_de_munca like '%' + @locMunca + '%' or lm.Denumire like '%' + @locMunca + '%')
			and (@datadoc_jos is null or p.data >= @datadoc_jos)
			and (@datadoc_sus is null or p.data <= @datadoc_sus)
			and (p.Data_operarii > p.Data)

		select * from #docModificate
		where (@filtruContDebit = '' or cont_debitor like @filtruContDebit + '%')
			and (@filtruContCredit = '' or cont_creditor like @filtruContCredit + '%')
		order by data desc
		for xml raw

	end
end try
begin catch
	set @mesajeroare='(wIaVerificareDocumente)'+ERROR_MESSAGE()
end catch

if LEN(@mesajeroare)>0
	raiserror(@mesajeroare, 11, 1)
