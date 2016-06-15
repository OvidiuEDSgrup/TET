--***
create procedure GenerareCompensariStocuri @stergerecomp int, @generarecomp int, 
	@datastoc datetime, @datacomp datetime, @tipcomp varchar(2)='AI', @nrcomp varchar(20)='CORA', @ctcomp varchar(40)='7718', 
	@gestfiltru varchar(9)='', @codfiltru varchar(20)='', @ctstocfiltru varchar(40)='', @gestcuplus varchar(9)='', 
	@stocladata int=0, @lmcomp char(9)='', @parXML XML=''
as
/**
	Exemplu apel
	
	exec GenerareCompensariStocuri @datastoc='04/30/2014', @datacomp='04/30/2014', 
		@tipcomp='AI', @nrcomp='CORA', @ctcomp='768', @stergerecomp=1,
		@generarecomp=1, @gestfiltru=null/*'2'*/, @codfiltru=null/*'1000'*/, @ctstocfiltru='', 
		@gestcuplus='', @stocladata=0
**/

begin try
	if exists (select valoare, cod_proprietate from fPropUtiliz(null) where cod_proprietate='GESTIUNE' and valoare<>'')
	begin
		raiserror('Accesul este restrictionat pe anumite gestiuni! Nu este permisa operatia in aceste conditii!',16,1)
	end

	if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
	begin
		raiserror('Accesul este restrictionat pe anumite locuri de munca! Nu este permisa operatia in aceste conditii!',16,1)
		return
	end

	declare @mesaj varchar(500), @sub varchar(9), @serii int, @cotatva float, @cttvanx varchar(40), @angestcttvanx int,
		@ctadaos varchar(40),@angestctadaos int,@angrctadaos int
	declare @nrptnrdoc int, @nrmax_pozitie int, @tipgestfiltru char(1), @tabela_gestiuni int, @tabela_coduri int, @userASiS char(10), @inversare_ordine_comp_coduri int

	--daca se trimite 1 atunci compensarea codurilor de intrare se va face in ordine inversa a datei (preluat ideea de la compensare facturi. Poate aici nu este utila)
	SET @inversare_ordine_comp_coduri = isnull(@parXML.value('(/*/@inversare_ordine_comp_cod)[1]', 'int'),0)
			
	exec luare_date_par 'GE','SUBPRO',0,0,@sub output
	exec luare_date_par 'GE','SERII',@serii output,0,''
	exec luare_date_par 'GE','COTATVA',0,@cotatva output,''
	exec luare_date_par 'GE','CNTVA',@angestcttvanx output,0,@cttvanx output
	exec luare_date_par 'GE','CADAOS',@angestctadaos output,@angrctadaos output,@ctadaos output

	exec luare_date_par 'DO','NRCOMP',0,@nrptnrdoc output,''
	
-->	daca se lucreaza cu serii vom utiliza vechea procedura de compensare (care compensa si seriile). Discutat cu Ghita.	
-->	N-am mai tratat in procedura noua compensarea pt. serii, pentru ca este in dezbatere care este solutia ASiS pt. lucrul pe serii.
	if @serii=1 and exists (select * from sysobjects where name ='GenerareCompensariStocuriPtSerii')
	Begin
		exec GenerareCompensariStocuriPtSerii 
			@datastoc=@datastoc, @datacomp=@datacomp, @tipcomp=@tipcomp, @nrcomp=@nrcomp, @ctcomp=@ctcomp, 
			@stergerecomp=@stergerecomp, @generarecomp=@generarecomp, @gestfiltru=@gestfiltru, @codfiltru=@codfiltru, @ctstocfiltru=@ctstocfiltru, 
			@gestcuplus=@gestcuplus, @stocladata=@stocladata, @lmcomp=@lmcomp, @parXML=@parXML
		return 0
	End

	set @userASiS = isnull(dbo.fIaUtilizator(null),'')
	set @tipgestfiltru=ISNULL((select Tip_gestiune from gestiuni where Subunitate=@sub and Cod_gestiune=@gestfiltru),'')

	/*	creeaza tabela temporara #DocDeContat pentru a putea genera inreg. contabile doar pt. documentele afectate de procedura curenta	*/
	if object_id('tempdb..#DocDeContat') is not null
		drop table #DocDeContat
	else
		create table #DocDeContat (subunitate varchar(9), tip varchar(2), numar varchar(40), data datetime)
	if OBJECT_ID('tempdb..#doc_inserate') is not null drop TABLE #doc_inserate
	create table #doc_inserate(subunitate varchar(9), tip varchar(2), numar varchar(40), data datetime)

	IF OBJECT_ID('tempdb..#codStocNegativ') IS NOT NULL drop table #codStocNegativ
	IF OBJECT_ID('tempdb..#codStocPozitiv') IS NOT NULL drop table #codStocPozitiv
	IF OBJECT_ID('tempdb..#tmpcompensari') IS NOT NULL drop table #tmpcompensari
	IF OBJECT_ID('tempdb..#tmppozdoc') IS NOT NULL drop table #tmppozdoc

	if @stergerecomp=1
	Begin
		delete from pozdoc 
		OUTPUT deleted.subunitate, deleted.tip, deleted.numar, deleted.data 
		into #doc_inserate (subunitate, tip, numar, data) 
			where subunitate=@sub and tip=@tipcomp and numar=@nrcomp and data=@datacomp 
			and (isnull(@gestfiltru,'')='' or gestiune=@gestfiltru) 
			and (isnull(@codfiltru,'')='' or cod=@codfiltru) and (isnull(@ctstocfiltru,'')='' or cont_de_stoc like RTrim(@ctstocfiltru)+'%')

		delete from doc 
			where subunitate=@sub and tip=@tipcomp and numar=@nrcomp and data=@datacomp 
			and (isnull(@gestfiltru,'')='' or cod_gestiune=@gestfiltru)
			and not exists (select 1 from pozdoc where pozdoc.subunitate=doc.subunitate 
				and pozdoc.tip=doc.tip and pozdoc.numar=doc.numar and pozdoc.data=doc.data)

		insert into #DocDeContat
		select distinct subunitate, tip, numar, data
		from #doc_inserate
		exec fainregistraricontabile @dinTabela=2
	End

	if @generarecomp=1
	Begin
		IF OBJECT_ID('tempdb..#gestiuni_comp') IS NULL
		begin
			CREATE TABLE #gestiuni_comp (gestiune varchar(13),stoc float)
			set @tabela_gestiuni=0
		end
		else
			set @tabela_gestiuni=1

		IF OBJECT_ID('tempdb..#coduri') IS NULL
		begin
			CREATE TABLE #coduri (gestiune varchar(9),cod varchar(20))
			set @tabela_coduri=0
		end
		else
			set @tabela_coduri=1

		--tabela cu codurile cu stocuri negative
		select ROW_NUMBER() over (partition by a.cod_gestiune order by a.cod_gestiune,a.tip_gestiune,a.cod,a.cod_intrare,a.data) as nrp, 0 as nrmin, 0 as nrmax,
			a.Cod, a.Cod_gestiune as gestiune, a.tip_gestiune, a.cod_intrare, a.Data, a.Cont, isnull(g.Denumire_gestiune,'') as dengestiune, 
			a.Loc_de_munca, a.Comanda, a.Locatie, a.data_expirarii, a.TVA_neexigibil, n.grupa,
			a.pret, a.pret_cu_amanuntul, abs(a.Stoc) as stoc, CONVERT(float,0.000) as cumulat, isnull(ge.stoc,0) as stoc_de_compensat, 0 as se_compenseaza,
			a.idIntrareFirma
		into #codStocNegativ
		from stocuri a
			left outer join gestiuni g on g.Subunitate=a.Subunitate and g.Cod_gestiune=a.Cod_gestiune
			left outer join nomencl n on n.Cod=a.Cod
			left join #gestiuni_comp ge on ge.gestiune=a.cod_gestiune
			left join #coduri co on co.gestiune=a.cod_gestiune and co.cod=a.cod
		where a.Subunitate=@sub and a.Tip_gestiune not in ('F','T') 
			and (isnull(@gestfiltru,'')='' or a.tip_gestiune=@tipgestfiltru) 
			and (isnull(@gestfiltru,'')='' or a.Cod_gestiune=@gestfiltru) 
			and (isnull(@codfiltru,'')='' or a.Cod=@codfiltru) 
			and (isnull(@ctstocfiltru,'')='' or a.Cont like RTrim(@ctstocfiltru)+'%') 
			and round(convert(decimal(17,5), a.stoc),3)<=-0.001 
			--tratare prefiltrare tabele
			and(co.cod is not null or @tabela_coduri=0)
			and(ge.gestiune is not null or @tabela_gestiuni=0)
		order by a.tip_gestiune,a.cod_gestiune,a.cod,a.cod_intrare

		--tabela cu codurile cu stocuri pozitive
		select ROW_NUMBER() over (partition by a.cod_gestiune order by a.cod_gestiune,a.tip_gestiune,(case when @inversare_ordine_comp_coduri=1 then a.data else '' end) desc
				,(case when @inversare_ordine_comp_coduri=0 then a.data else '' end) asc,a.cod,a.cod_intrare) as nrp,
			a.cod, a.cod_gestiune as gestiune, a.tip_gestiune, a.cod_intrare, a.Data, a.Cont, isnull(g.Denumire_gestiune,'') as dengestiune, 
			a.Loc_de_munca, a.Comanda, a.Locatie, a.data_expirarii, a.TVA_neexigibil, n.grupa, 
			a.pret, a.pret_cu_amanuntul, isnull(a.stoc,0) as Stoc, CONVERT(float,0.000) as cumulat, a.idIntrareFirma
		into #codStocPozitiv
		from stocuri a
			left outer join gestiuni g on g.Subunitate=a.Subunitate and g.Cod_gestiune=a.Cod_gestiune
			left outer join nomencl n on n.Cod=a.Cod
			left join #gestiuni_comp ge on ge.gestiune=a.cod_gestiune
			left join #coduri co on co.gestiune=a.cod_gestiune and co.cod=a.cod
		where a.Subunitate=@sub and a.Tip_gestiune not in ('F','T') 
			and (isnull(@gestfiltru,'')='' or a.tip_gestiune=@tipgestfiltru) 
			and (isnull(@gestfiltru,'')='' or a.Cod_gestiune=@gestfiltru) 
			and (isnull(@gestcuplus,'')='' or a.Cod_gestiune=@gestcuplus)
			and (@ctstocfiltru='' or a.Cont like RTrim(@ctstocfiltru)+'%')
			--and a.cod_intrare>='!' 
			and round(convert(decimal(17,5), isnull(a.stoc,0)),3)>=0.001 
			--tratare prefiltrare tabele
			and(co.cod is not null or @tabela_coduri=0)
			and(ge.gestiune is not null or @tabela_gestiuni=0)
		order by a.tip_gestiune,a.cod_gestiune, a.cod 
			,(case when @inversare_ordine_comp_coduri=1 then a.data else '' end) desc
			,(case when @inversare_ordine_comp_coduri=0 then a.data else '' end) asc
			,a.cod_intrare

		--stocuri cumulate coduri pozitive
		update #codStocPozitiv set 
			cumulat=coduricalculate.cumulat
		from (select p2.gestiune, p2.cod, p2.nrp, sum(p1.stoc) as cumulat 
				from #codStocPozitiv p1, #codStocPozitiv p2 
				where p1.gestiune=p2.gestiune and p1.cod=p2.cod and p1.nrp<=p2.nrp 
				group by p2.gestiune, p2.cod, p2.nrp) coduricalculate
		where coduricalculate.gestiune=#codStocPozitiv.gestiune
			and coduricalculate.cod=#codStocPozitiv.cod
			and coduricalculate.nrp=#codStocPozitiv.nrp

		--stocuri cumulate coduri negative
		update #codStocNegativ set 
			cumulat=avansuricalculate.cumulat
		from (select p2.gestiune, p2.cod, p2.nrp, sum(p1.stoc) as cumulat 
			from #codStocNegativ p1, #codStocNegativ p2 
			where p1.gestiune=p2.gestiune and p1.cod=p2.cod and p1.nrp<=p2.nrp 
			group by p2.gestiune, p2.cod, p2.nrp) avansuricalculate
		where avansuricalculate.gestiune=#codStocNegativ.gestiune
			and avansuricalculate.cod=#codStocNegativ.cod
			and avansuricalculate.nrp=#codStocNegativ.nrp  

		--tratare stocurile de compensat primit prin tabela #gestiuni_comp
		--toate codurile care intra in stocurile de compensat, se compenseaza
		update f set se_compenseaza=1
		from #codStocNegativ f
		where f.cumulat<=stoc_de_compensat or isnull(stoc_de_compensat,0)=0 

		--ultima pozitie care intra in stocul de compensat, se compenseaza partial	
		update f set f.se_compenseaza=1, f.stoc=f.stoc_de_compensat-(f.cumulat-f.stoc)
		from #codStocNegativ f
		where f.se_compenseaza=0

		--sterg codurile de intrare care nu se compenseaza
		delete from #codStocNegativ 
		where se_compenseaza=0 or stoc<0.000

		--calcul numar min
		update #codStocNegativ 
 			set nrmin=st.nrp--,nrmax=dr.nrp
			from #codStocNegativ c
				cross apply
					(select top 1 smin.nrp from #codStocPozitiv smin where smin.gestiune=c.gestiune and smin.cod=c.cod and c.cumulat-c.stoc<smin.cumulat order by smin.cumulat) st 

		--calcul numar max
 		update #codStocNegativ 
 			set nrmax=dr.nrp
			from #codStocNegativ c	
				cross apply
					(select Top 1 smax.nrp from #codStocPozitiv smax where smax.gestiune=c.gestiune and smax.cod=c.cod and (smax.cumulat<=c.cumulat or smax.cumulat-smax.stoc<c.cumulat) order by smax.cumulat desc) dr

		--imperechere coduri/coduri de intrare	
		select row_number() over(order by pd.gestiune,pd.data,pd.cod) as nrord_poz ,dense_rank() over(order by pd.gestiune) as nrord_doc, pd.gestiune, pd.dengestiune, pd.tip_gestiune, pd.cod, pd.grupa, 
			fc.cod_intrare as codi_stoc_pozitiv, fc.stoc as stoc_pozitiv, fc.pret as pret_stoc_pozitiv, fc.pret_cu_amanuntul as pretam_stoc_pozitiv, fc.Cont as cont_stoc_pozitiv, 
				fc.loc_de_munca as lm_pozitiv, fc.comanda as com_pozitiv, fc.locatie as locatie_pozitiv, fc.data_expirarii as dataexp_pozitiv, fc.TVA_neexigibil as tvaneex_pozitiv, 
			pd.cod_intrare as codi_stoc_negativ, pd.stoc as stoc_negativ, pd.pret as pret_stoc_negativ, pd.pret_cu_amanuntul as pretam_stoc_negativ, pd.Cont as cont_stoc_negativ, 
				pd.loc_de_munca as lm_negativ, pd.comanda as com_negativ, pd.locatie as locatie_negativ, pd.data_expirarii as dataexp_negativ, pd.TVA_neexigibil as tvaneex_negativ, 
			s.stoccompensat, pd.loc_de_munca, convert(varchar(8),'') as nr_doc, 0 as nr_poz, pd.idIntrareFirma
		into #tmpcompensari
		from #codStocNegativ pd
			inner/*left outer*/ join #codStocPozitiv fc on pd.gestiune=fc.gestiune and pd.cod=fc.cod and fc.nrp between pd.nrmin and pd.nrmax and pd.nrmin<>0
			cross apply (select round((case when pd.cumulat<=fc.cumulat then pd.cumulat else fc.cumulat end)
							-(case when  pd.cumulat-pd.stoc>fc.cumulat-fc.stoc then pd.cumulat-pd.stoc else fc.cumulat-fc.stoc end),3) as stoccompensat) s
		order by pd.gestiune, pd.cod, pd.nrp, fc.nrp
	
		--setez numarul de document si numarul de pozitie
		/*update #tmpcompensari
			set nr_doc=RTRIM(@nrcomp)+rtrim(convert(char(4),@nrptnrdoc+nrord_doc))*/


		--formez tabela finala din care apoi se vor insera datele in pozdoc.
		SELECT	cod, (case when @gestcuplus<>'' then @gestcuplus else gestiune end) as gestiune, (case when @tipcomp='AE' then 1 else -1 end)*stoccompensat as cantitate, pret_stoc_pozitiv as pret_de_stoc, 
				(case when tip_gestiune='A' and @tipcomp='AI' then pretam_stoc_pozitiv else 0 end) as pret_cu_amanuntul,
				codi_stoc_pozitiv as cod_intrare, cont_stoc_pozitiv as cont_de_stoc, (case when tip_gestiune='A' then tvaneex_pozitiv else 0 end) as TVA_neexigibil, 
				(case when tip_gestiune='A' and @tipcomp='AE' then pretam_stoc_pozitiv else 0 end) as pret_amanunt_predator, 
				(case when @tipcomp='AI' then 'I' else 'E' end) as tip_miscare, locatie_pozitiv as locatie, dataexp_pozitiv as data_expirarii, 
				(case when tip_gestiune='A' and @tipcomp='AE' then RTRIM(@cttvanx)+(case when @angestcttvanx=1 then '.'+RTRIM(gestiune) else '' end) else '' end) as tert, 
				(case when tip_gestiune='A' then RTRIM(@ctadaos)+(case when @angestctadaos=1 then '.'+RTRIM(gestiune) else '' end)
					+(case when @angrctadaos=1 then '.'+RTRIM(grupa) else '' end) else '' end) as gestiune_primitoare, 
				(case when tip_gestiune='A' and @tipcomp='AI' then RTRIM(@cttvanx)
					+(case when @angestcttvanx=1 then '.'+RTRIM(gestiune) else '' end) else @ctcomp end) as cont_factura, idIntrareFirma
		into #tmppozdoc
		FROM #tmpcompensari
		union all
		SELECT	Cod, gestiune, (case when @tipcomp='AE' then 1 else -1 end)*(-1)*stoccompensat as cantitate, pret_stoc_negativ as pret_de_stoc, 
				(case when tip_gestiune='A' and @tipcomp='AI' then pretam_stoc_negativ else 0 end) as pret_cu_amanuntul, 
				codi_stoc_negativ as cod_itrare, cont_stoc_negativ as cont_de_stoc, (case when tip_gestiune='A' then tvaneex_negativ else 0 end) as TVA_neexigibil, 
				(case when tip_gestiune='A' and @tipcomp='AE' then pretam_stoc_negativ else 0 end) as pret_amanunt_predator, 
				(case when @tipcomp='AI' then 'I' else 'E' end) as tp_miscare, locatie_negativ as locatie, isnull(dataexp_negativ,'01/01/1901') as data_expirarii,
				(case when tip_gestiune='A' and @tipcomp='AE' then RTRIM(@cttvanx)+(case when @angestcttvanx=1 then '.'+RTRIM(gestiune) else '' end) else '' end) as tert, 
				(case when tip_gestiune='A' then RTRIM(@ctadaos)+(case when @angestctadaos=1 then '.'+RTRIM(gestiune) else '' end)
					+(case when @angrctadaos=1 then '.'+RTRIM(grupa) else '' end) else '' end) as gestiune_primitoare, 
				(case when tip_gestiune='A' and @tipcomp='AI' then RTRIM(@cttvanx)+(case when @angestcttvanx=1 then '.'+RTRIM(gestiune) else '' end) else @ctcomp end) as cont_factura,
				idIntrareFirma
		FROM #tmpcompensari

-->	Citesc numar maxim de pozitie de pe document (daca se da generare cu filtre) si sunt pozitii dupa stergere, pentru a da numar de pozitie incepand cu ultima pozitie existenta.
		select top 1 @nrmax_pozitie=numar_pozitie from pozdoc where subunitate=@sub and tip=@tipcomp and numar=@nrcomp and data=@datacomp order by Numar_pozitie desc
		select @nrmax_pozitie=isnull(@nrmax_pozitie,0)

		--scriere in pozdoc.
		INSERT INTO pozdoc (Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, 
				Pret_valuta, Pret_de_stoc, Adaos, Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, 
				Utilizator, Data_operarii, Ora_operarii, Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, 
				Pret_amanunt_predator, Tip_miscare, Locatie, Data_expirarii, Numar_pozitie, Loc_de_munca, Comanda, 
				Barcod, Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
				Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, 
				Accize_cumparare, Accize_datorate, Contract, Jurnal, idIntrareFirma) 
		OUTPUT inserted.subunitate, inserted.tip, inserted.numar, inserted.data 
		into #doc_inserate (subunitate, tip, numar, data) 
			SELECT @sub, @tipcomp, @nrcomp, Cod, @datacomp, gestiune, cantitate, 0, pret_de_stoc, 0, 0, 
				pret_cu_amanuntul, 0, 0, @userASiS, convert(datetime, convert(char(10), getdate(), 104), 104), RTrim(replace(convert(char(8), getdate(), 108), ':', '')), 
				cod_intrare, cont_de_stoc, (case when left(cont_de_stoc,1)='8' then '' else @ctcomp end), TVA_neexigibil, pret_amanunt_predator, 
				tip_miscare, locatie, data_expirarii, @nrmax_pozitie+row_number() over(order by gestiune, cod, cod_intrare), @lmcomp, '', '', 
				'', '', 0, tert, '', gestiune_primitoare, '', 3 as stare, '', cont_factura, 
				'', 0, '01/01/1901', '01/01/1901', 0, 0, 0, 0, '', '',idIntrareFirma
			FROM #tmppozdoc

		delete from #DocDeContat
		insert into #DocDeContat
		select distinct subunitate, tip, numar, data
		from #doc_inserate
		exec fainregistraricontabile @dinTabela=2

		set @nrptnrdoc=@nrptnrdoc + isnull((select max(nrord_doc) from #tmpcompensari),0)
		exec setare_par 'DO','NRCOMP','Nr. pt. nr. doc.',0,@nrptnrdoc,''
	End
end try
begin catch
	set @mesaj ='(GenerareCompensariStocuri): '+ ERROR_MESSAGE()
end catch


if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)	 
