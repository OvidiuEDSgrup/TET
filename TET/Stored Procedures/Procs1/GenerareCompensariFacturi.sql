--***
create procedure GenerareCompensariFacturi @tipfact char(2)='B', @datacomp datetime,
	@idcomp varchar(20)='CMPB', @jurnalcomp char(3)='', @stergerecomp int, @generarecomp int, @exfactavans int,
	@factavansfiltru char(20)='', @lmfiltru char(9)='', @tertfiltru char(13)='', @ctfactfiltru char(40)='',
	@parXML XML=''
as
begin try
	if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
	begin
		raiserror('Accesul este restrictionat pe anumite locuri de munca! Nu este permisa operatia in aceste conditii!',16,1)
		return
	end

	declare @mesaj varchar(500), @sub varchar(9)
	declare @ctavansfurn varchar(40), @ctavansben varchar(40), @nrptnrdoc int, @nrpozitie int, @IFN int, @faradifcursbenIFN int, @sifactinvalutaIFN int,
		@factneg char(20), @tert char(13), @ctfactneg varchar(40), @valutafactneg char(3), @tabela_terti int, @tabela_facturi int,
		@cursfactneg float, @solddecomp float, @dentert char(80), @locmn varchar(9), @locmp varchar(9), 
		@factpoz char(20), @ctfactpoz varchar(40), @valutafactpoz char(3),
		@cursfactpoz float, @soldfactpoz float,
		@suma float, @lungfactunif int, @car char(1),
		@ctexceptie varchar(40), @gtert char(13), @userASiS char(10), @inversare_ordine_comp_fact int

	--daca se trimite 1 atunci compensarea facturilor se va face in ordine inversa a datei scadentei(folosit la cemacon
	SET @inversare_ordine_comp_fact = isnull(@parXML.value('(/*/@inversare_ordine_comp_fact)[1]', 'int'),0)
			
	exec luare_date_par 'GE','SUBPRO',0,0,@sub output
	exec luare_date_par 'GE','SUBPRO',0,0,@sub output
	exec luare_date_par 'DO','NRCOMP',0,@nrptnrdoc output,''
	exec luare_date_par 'DO','POZITIE',0,@nrpozitie output,''
	exec luare_date_par 'GE','IFN',@IFN output,0,''
	exec luare_date_par 'GE','CFURNAV',0,0,@ctavansfurn output
	
	if @ctavansfurn='' set @ctavansfurn='409'
		exec luare_date_par 'GE','CBENEFAV',0,0,@ctavansben output
	if @ctavansben='' 
		set @ctavansben='419'
	
	set @faradifcursbenIFN=1
	set @sifactinvalutaIFN=(case when @tipfact<>'F' and @IFN=1 and @faradifcursbenIFN=1 then 1 
		else 0 end)
	set @ctexceptie=(case when @exfactavans=1 then (case when @tipfact='F' then @ctavansfurn 
		else @ctavansben end) else '' end)
	set @userASiS = isnull(dbo.fIaUtilizator(null),'')

	if @stergerecomp=1
	Begin
		delete from pozadoc where subunitate=@sub and tip='C'+@tipfact and numar_document like RTrim(@idcomp)+'%' 
			and data=@datacomp and (@tertfiltru='' or tert=@tertfiltru) 
			and (@factavansfiltru='' or @tipfact='B' and factura_stinga=@factavansfiltru or @tipfact='F' and factura_dreapta=@factavansfiltru)
			and (@lmfiltru='' or loc_munca like RTrim(@lmfiltru)+'%') 
			and (@ctfactfiltru='' or @tipfact='B' and cont_deb like RTrim(@ctfactfiltru)+'%' 
				or @tipfact='F' and cont_cred like RTrim(@ctfactfiltru)+'%')

		delete from adoc where subunitate=@sub and tip='C'+@tipfact and numar_document like RTrim(@idcomp)+'%' 
			and data=@datacomp and (@tertfiltru='' or tert=@tertfiltru) 
			and not exists (select 1 from pozadoc where pozadoc.subunitate=adoc.subunitate and pozadoc.tip=adoc.tip 
				and pozadoc.numar_document=adoc.numar_document and pozadoc.data=adoc.data)
	End

	if @generarecomp=1
	Begin

		IF OBJECT_ID('tempdb..#terti') IS NULL
		begin
			CREATE TABLE #terti (tert varchar(13),sold float)
			set @tabela_terti=0
		end
		else
			set @tabela_terti=1

		IF OBJECT_ID('tempdb..#facturi') IS NULL
		begin
			CREATE TABLE #facturi (tert varchar(13),factura varchar(20))
			set @tabela_facturi=0
		end
		else
			set @tabela_facturi=1

		--tabela cu facturile cu solduri negative
		select ROW_NUMBER() over (partition by a.tert, a.valuta order by a.tert,a.valuta,a.data_scadentei,a.factura) as nrp, 0 as nrmin, 0 as nrmax,
			a.Factura, a.Tert, a.Data, a.Cont_de_tert, a.Valuta, a.Curs, isnull(t.Denumire,'') as dentert, a.Loc_de_munca, a.Comanda, abs(a.Sold) as sold, CONVERT(float,0.00) as cumulat,
			isnull(te.sold,0) as sold_de_compensat, 0 as se_compenseaza
		into #factSoldNegativ
		from facturi a
			left outer join terti t on t.Subunitate=a.Subunitate and t.Tert=a.Tert
			left join #terti te on te.tert=a.tert
			left join #facturi fa on fa.tert=a.tert and fa.factura=a.factura
		where a.Subunitate=@sub 
			and a.Tip=(case when @tipfact='F' then 0x54 else 0x46 end) 
			and (@tertfiltru='' or a.tert=@tertfiltru) 
			and (@factavansfiltru='' or a.factura=@factavansfiltru) 
			and (@lmfiltru='' or a.Loc_de_munca like RTrim(@lmfiltru)+'%') 
			and round(convert(decimal(17,5), a.sold),2)<=-0.01 
			and (@sifactinvalutaIFN=1 or a.Sold_valuta=0) 
			and (@ctexceptie='' or a.Cont_de_tert<>@ctexceptie) 
			and (@ctfactfiltru='' or a.Cont_de_tert like RTrim(@ctfactfiltru)+'%') 
			--tratare prefiltrare tabele
			and(fa.factura is not null or @tabela_facturi=0)
			and(te.tert is not null or @tabela_terti=0)
		order by a.tert,a.Valuta,a.data,a.factura

		--tabela cu facturile cu solduri pozitive
		select ROW_NUMBER() over (partition by a.tert, a.valuta order by a.tert,a.valuta,case when @inversare_ordine_comp_fact=1 then a.data_scadentei else '' end desc
				,case when @inversare_ordine_comp_fact=0 then a.data_scadentei else '' end asc,a.factura) as nrp,
			a.Factura,a.tert, a.Data,a.Cont_de_tert, a.Valuta, a.Curs, isnull(t.Denumire,'') as dentert, a.Loc_de_munca, a.Comanda, a.Sold as sold, CONVERT(float,0.00) as cumulat
		into #factSoldPozitiv
		from facturi a
			left outer join terti t on t.Subunitate=a.Subunitate and t.Tert=a.Tert
			left join #terti te on te.tert=a.tert
			left join #facturi fa on fa.tert=a.tert and fa.factura=a.factura
		where a.Subunitate=@sub and a.Tip=(case when @tipfact='F' then 0x54 else 0x46 end) 
			and (@tertfiltru='' or a.tert=@tertfiltru) 
			and a.factura>='!' 
			and (@lmfiltru='' or a.Loc_de_munca like RTrim(@lmfiltru)+'%') 
			and round(convert(decimal(17,5), a.Sold),2)>=0.01 
			and Left (a.Cont_de_tert,3)<>'408' AND Left(a.Cont_de_tert,3)<>'418' 
			and (@sifactinvalutaIFN=1 or a.Sold_valuta=0) 
			and (@ctfactfiltru='' or a.Cont_de_tert like RTrim(@ctfactfiltru)+'%')
			--tratare prefiltrare tabele
			and(fa.factura is not null or @tabela_facturi=0)
			and(te.tert is not null or @tabela_terti=0)
		order by a.tert,a.valuta
			,case when @inversare_ordine_comp_fact=1 then a.data_scadentei else '' end desc
			,case when @inversare_ordine_comp_fact=0 then a.data_scadentei else '' end asc
			, a.factura

		--solduri cumulate  facturi pozitive
		update #factSoldPozitiv set 
			cumulat=facturicalculate.cumulat
		from (select p2.tert, p2.valuta, p2.nrp, sum(p1.sold) as cumulat 
				from #factSoldPozitiv p1, #factSoldPozitiv p2 
				where p1.tert=p2.tert and p1.valuta=p2.valuta and p1.nrp<=p2.nrp 
				group by p2.tert, p2.valuta, p2.nrp) facturicalculate
		where facturicalculate.tert=#factSoldPozitiv.tert
			and facturicalculate.valuta=#factSoldPozitiv.valuta 
			and facturicalculate.nrp=#factSoldPozitiv.nrp

		--solduri cumulate facturi negative
		update #factSoldNegativ set 
			cumulat=avansuricalculate.cumulat
		from (select p2.tert, p2.valuta, p2.nrp, sum(p1.sold) as cumulat 
			from #factSoldNegativ p1, #factSoldNegativ p2 
			where p1.tert=p2.tert and p1.valuta=p2.valuta and p1.nrp<=p2.nrp 
			group by p2.tert, p2.valuta, p2.nrp) avansuricalculate
		where avansuricalculate.tert=#factSoldNegativ.tert
			and avansuricalculate.valuta=#factSoldNegativ.valuta 
			and avansuricalculate.nrp=#factSoldNegativ.nrp  

		--tratare sold de compensat primit prin tabela #terti
		--toate facturile care intra in soldul de compensat, se compenseaza
		update f set se_compenseaza=1
		from #factSoldNegativ f
		where f.cumulat<=sold_de_compensat or isnull(sold_de_compensat,0)=0 

		--ultima factura care intra in soldul de compensat, se compenseaza partial	
		update f set f.se_compenseaza=1, f.sold=f.sold_de_compensat-(f.cumulat-f.sold)
		from #factSoldNegativ f
		where f.se_compenseaza=0

		--sterg facturile care nu se compenseaza
		delete from #factSoldNegativ 
		where se_compenseaza=0 or sold<0.00

		--calcul numar min
		update #factSoldNegativ 
 			set nrmin=st.nrp--,nrmax=dr.nrp
			from #factSoldNegativ c
				cross apply
					(select top 1 smin.nrp from #factSoldPozitiv smin where smin.tert=c.tert and smin.valuta=c.valuta and c.cumulat-c.sold<smin.cumulat order by smin.cumulat) st 

		--calcul numar max
 		update #factSoldNegativ 
 			set nrmax=dr.nrp
			from #factSoldNegativ c	
				cross apply
					(select Top 1 smax.nrp from #factSoldPozitiv smax where smax.tert=c.tert and smax.valuta=c.valuta and (smax.cumulat<=c.cumulat or smax.cumulat-smax.sold<c.cumulat) order by smax.cumulat desc) dr
	
		--imperechere facturi	
		select row_number() over(order by pd.tert,pd.data,pd.factura) as nrord_poz ,dense_rank() over(order by pd.tert) as nrord_adoc, pd.tert, pd.dentert,
			fc.factura as fact_sold_pozitiv, fc.sold as sold_pozitiv, fc.Cont_de_tert as cont_fact_pozitiv, fc.valuta as valuta_pozitiv, fc.curs as curs_pozitiv, fc.loc_de_munca as lm_pozitiv, fc.comanda as com_pozitiv,
			pd.factura as fact_sold_negativ, pd.sold as sold_negativ, pd.Cont_de_tert as cont_fact_negativ, pd.valuta as valuta_negativ, pd.curs as curs_negativ, pd.loc_de_munca as lm_negativ, pd.comanda as com_negativ,
			s.sumacompensata,pd.loc_de_munca, convert(varchar(8),'') as nr_adoc, 0 as nr_poz
		into #tmpcompensari
		from #factSoldNegativ pd
			inner/*left outer*/ join #factSoldPozitiv fc on pd.tert=fc.tert and pd.valuta=fc.valuta and fc.nrp between pd.nrmin and pd.nrmax and pd.nrmin<>0
			cross apply (select round((case when pd.cumulat<=fc.cumulat then pd.cumulat else fc.cumulat end)
							-(case when  pd.cumulat-pd.sold>fc.cumulat-fc.sold then pd.cumulat-pd.sold else fc.cumulat-fc.sold end),2) as sumacompensata) s
		order by pd.tert, pd.valuta, pd.nrp, fc.nrp
	
		--setez numarul de document si numarul de pozitie
		update #tmpcompensari
			set nr_adoc=RTRIM(@idcomp)+rtrim(convert(char(4),@nrptnrdoc+nrord_adoc)),
				nr_poz=@nrpozitie+nrord_poz

	--select * from #tmpcompensari

	--return
		INSERT INTO POZADOC (Subunitate,Numar_document,Data,
				Tert,Tip,
				Factura_stinga,Factura_dreapta,Cont_deb,Cont_cred,Suma,TVA11,TVA22,
				Utilizator, Data_operarii,Ora_operarii,Numar_pozitie,Tert_beneficiar,Explicatii,
				Valuta,Curs,Suma_valuta,
				Cont_dif,suma_dif,Loc_munca,Comanda,Data_fact,Data_scad,Stare,
				Achit_fact,Dif_TVA,Jurnal)
			SELECT @sub, nr_adoc,@datacomp,
				tert,'C'+@tipfact,
				(case when @tipfact='F' then fact_sold_pozitiv else fact_sold_negativ end),
				(case when @tipfact='F' then fact_sold_negativ else fact_sold_pozitiv end),
				(case when @tipfact='F' then cont_fact_pozitiv else cont_fact_negativ end),
				(case when @tipfact='F' then cont_fact_negativ else cont_fact_pozitiv end),sumacompensata,0,0,
				@userASiS,convert(datetime, convert(char(10), getdate(), 104), 104), replace(convert(char(8), getdate(), 114),':',''),nr_poz,'', left('C'+rtrim(@tipfact)+' '+dentert,50),			
				(case when @sifactinvalutaIFN=1 then (case when valuta_negativ<>'' then valuta_negativ else (case when 	valuta_pozitiv<>'' then valuta_pozitiv else '' end) end) else '' end),			
				(case when @sifactinvalutaIFN=1 then (case when valuta_negativ<>'' then curs_negativ else (case when valuta_pozitiv<>'' then curs_pozitiv else 0 end) end) else 0 end),			
				(case when @sifactinvalutaIFN=1 and valuta_negativ<>'' and curs_negativ<>0 then round(sumacompensata/curs_negativ,2) else 0 end),			
				'',0, (case when lm_pozitiv='' then lm_negativ else lm_pozitiv end),(case when com_pozitiv='' then com_negativ else com_pozitiv end),@datacomp,@datacomp,
				0,(case when @sifactinvalutaIFN=1 and valuta_pozitiv<>'' and curs_pozitiv<>0 then round(sumacompensata/curs_pozitiv,2) else 0 end),0, @jurnalcomp		
			FROM #tmpcompensari

			set @nrptnrdoc=@nrptnrdoc + isnull((select max(nrord_adoc) from #tmpcompensari),0)
			set @nrpozitie=@nrpozitie + isnull((select max(nrord_poz) from #tmpcompensari),0)

			exec setare_par 'DO','NRCOMP','Nr. pt. nr. doc.',0,@nrptnrdoc,''
			exec setare_par 'DO','POZITIE','Nr. pozitie doc.',0,@nrpozitie,''
	End
end try
begin catch
	set @mesaj ='(GenerareCompensariFacturi): '+ ERROR_MESSAGE()
end catch


if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)	 

/*
select '13467557' as tert,10000 as sold
into #terti   

exec GenCompFact  @tipfact='B', @datacomp='2014-04-30',
	@idcomp='CMPB',@jurnalcomp='',@stergerecomp=1, @generarecomp=1, @exfactavans=1,
	@factavansfiltru='', @lmfiltru='', @tertfiltru='11201900', @ctfactfiltru='', @parXML=''

drop table #terti

delete from adoc where numar_document like 'CMP%' and tip='CF' and data='2014-02-28 00:00:00.000'

*/
