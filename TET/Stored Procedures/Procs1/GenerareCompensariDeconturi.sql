--***
create procedure GenerareCompensariDeconturi @tipdecont varchar(1)='T', @stergerecomp int, @generarecomp int, 
	@datacomp datetime, @idcomp varchar(20)='CMP', @jurnalcomp char(3)='', @ctcomp varchar(40)='473', 
	@marca varchar(6)='', @lm varchar(9)='', @ctdecont varchar(40)='', @ctexceptie varchar(40)='', @parXML XML='<row />'
as
begin try	
	if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
	begin
		raiserror('Accesul este restrictionat pe anumite locuri de munca! Nu este permisa operatia in aceste conditii!',16,1)
		return
	end

	declare @mesaj varchar(500), @sub varchar(9)
	declare @nrptnrdoc int, @nrpozitie int, @tabela_personal int, @tabela_deconturi int, @userASiS char(10), @inversare_ordine_comp_decont int

	--daca se trimite 1 atunci compensarea deconturilor se va face in ordine inversa a datei scadentei (folosit la cemacon)
	SET @inversare_ordine_comp_decont = isnull(@parXML.value('(/*/@inversare_ordine_comp_decont)[1]', 'int'),0)
			
	exec luare_date_par 'GE','SUBPRO',0,0,@sub output
	exec luare_date_par 'GE','SUBPRO',0,0,@sub output
	exec luare_date_par 'DO','NRCOMP',0,@nrptnrdoc output,''
	exec luare_date_par 'DO','POZITIE',0,@nrpozitie output,''
	
	set @userASiS = isnull(dbo.fIaUtilizator(null),'')

	/*	creeaza tabela temporara #DocDeContat pentru a putea genera inreg. contabile doar pt. documentele afectate de procedura curenta	*/
	if object_id('tempdb..#DocDeContat') is not null
		drop table #DocDeContat
	else
		create table #DocDeContat (subunitate varchar(9), tip varchar(2), numar varchar(40), data datetime)
	if OBJECT_ID('tempdb..#doc_inserate') is not null drop TABLE #doc_inserate
	create table #doc_inserate(numar varchar(40))

	/*	stergere compensari generate anterior	*/
	if @stergerecomp=1
	Begin
		delete from pozplin 
		OUTPUT deleted.cont
		into #doc_inserate (numar) 
		where subunitate=@sub and numar like RTrim(@idcomp)+'%' and plata_incasare in ('PD','ID')
			and data=@datacomp and (@marca='' or marca=@marca) 
			and (@lm='' or loc_de_munca like RTrim(@lm)+'%') 
			and (@ctdecont='' or cont like RTrim(@ctdecont)+'%') and explicatii like 'COMP. DECONT%'

		delete from plin where subunitate=@sub and data=@datacomp and (@ctdecont='' or cont like RTrim(@ctdecont)+'%')
			and not exists (select 1 from pozplin where pozplin.subunitate=plin.subunitate and pozplin.cont=plin.cont and pozplin.data=plin.data and pozplin.jurnal=plin.jurnal)

		insert into #DocDeContat
		select distinct @sub, 'PI', numar, @datacomp
		from #doc_inserate
		exec fainregistraricontabile @dinTabela=2
	End

	if @generarecomp=1
	Begin
		IF OBJECT_ID('tempdb..#personal') IS NULL
		begin
			CREATE TABLE #personal (marca varchar(6), sold float)
			set @tabela_personal=0
		end
		else
			set @tabela_personal=1

		IF OBJECT_ID('tempdb..#deconturi') IS NULL
		begin
			CREATE TABLE #deconturi (marca varchar(6), decont varchar(40))
			set @tabela_deconturi=0
		end
		else
			set @tabela_deconturi=1

		IF OBJECT_ID('tempdb..#decontSoldNegativ') IS NOT NULL drop table #decontSoldNegativ
		IF OBJECT_ID('tempdb..#decontSoldPozitiv') IS NOT NULL drop table #decontSoldPozitiv
		IF OBJECT_ID('tempdb..#tmpcompensari') IS NOT NULL drop table #tmpcompensari
		IF OBJECT_ID('tempdb..#tmppozplin') IS NOT NULL drop table #tmppozplin

		/*	tabela cu deconturile cu solduri negative */
		select ROW_NUMBER() over (partition by a.marca, a.cont, a.valuta order by a.marca, a.cont, a.valuta, a.data_scadentei, a.decont) as nrp, 0 as nrmin, 0 as nrmax,
			a.Decont, a.Marca, a.Data, a.Cont, a.Valuta, a.Curs, isnull(p.Nume,'') as densalariat, a.Loc_de_munca, abs(a.Sold) as sold, CONVERT(float,0.00) as cumulat,
			isnull(pe.sold,0) as sold_de_compensat, 0 as se_compenseaza
		into #decontSoldNegativ
		from deconturi a
			left outer join personal p on p.Marca=a.Marca
			left join #personal pe on pe.marca=a.Marca
			left join #deconturi de on de.marca=a.Marca and de.decont=a.Decont
		where a.Subunitate=@sub 
			and a.Tip=@tipdecont
			and (@marca='' or a.marca=@marca) 
			and (@lm='' or a.Loc_de_munca like RTrim(@lm)+'%') 
			and round(convert(decimal(17,5), a.sold),2)<=-0.01 
			and a.Sold_valuta=0 
			and (@ctexceptie='' or a.Cont<>@ctexceptie) 
			and (@ctdecont='' or a.Cont like RTrim(@ctdecont)+'%') 
			--tratare prefiltrare tabele
			and (de.decont is not null or @tabela_deconturi=0)
			and (pe.marca is not null or @tabela_personal=0)
		order by a.marca,a.cont,a.Valuta,a.data,a.decont

		/*	tabela cu deconturile cu solduri pozitive */
		select ROW_NUMBER() over (partition by a.marca, a.cont, a.valuta order by a.marca, a.cont, a.valuta, (case when @inversare_ordine_comp_decont=1 then a.data_scadentei else '' end) desc
				,(case when @inversare_ordine_comp_decont=0 then a.data_scadentei else '' end) asc, a.decont) as nrp,
			a.Decont, a.Marca, a.Data, a.Cont, a.Valuta, a.Curs, isnull(p.Nume,'') as densalariat, a.Loc_de_munca, a.Sold as sold, CONVERT(float,0.00) as cumulat
		into #decontSoldPozitiv
		from deconturi a
			left outer join personal p on p.Marca=a.Marca
			left join #personal pe on pe.marca=a.marca
			left join #deconturi de on de.marca=a.marca and de.decont=a.Decont
		where a.Subunitate=@sub 
			and a.Tip=@tipdecont
			and (@marca='' or a.marca=@marca) 
			and a.Decont>='!' 
			and (@lm='' or a.Loc_de_munca like RTrim(@lm)+'%') 
			and round(convert(decimal(17,5), a.Sold),2)>=0.01 
			and a.Sold_valuta=0 
			and (@ctdecont='' or a.Cont like RTrim(@ctdecont)+'%')
			--tratare prefiltrare tabele
			and (de.decont is not null or @tabela_deconturi=0)
			and (pe.marca is not null or @tabela_personal=0)
		order by a.marca,a.cont,a.valuta
			,(case when @inversare_ordine_comp_decont=1 then a.data_scadentei else '' end) desc
			,(case when @inversare_ordine_comp_decont=0 then a.data_scadentei else '' end) asc
			,a.decont
		/*
		select * from #decontSoldNegativ
		select * from #decontSoldPozitiv
		*/

		/*	solduri cumulate deconturi pozitive */
		update #decontSoldPozitiv set 
			cumulat=deconturicalculate.cumulat
		from (select p2.marca, p2.cont, p2.valuta, p2.nrp, sum(p1.sold) as cumulat 
				from #decontSoldPozitiv p1, #decontSoldPozitiv p2 
				where p1.marca=p2.marca and p1.cont=p2.cont and p1.valuta=p2.valuta and p1.nrp<=p2.nrp 
				group by p2.marca, p2.cont, p2.valuta, p2.nrp) deconturicalculate
		where deconturicalculate.marca=#decontSoldPozitiv.marca
			and deconturicalculate.cont=#decontSoldPozitiv.cont
			and deconturicalculate.valuta=#decontSoldPozitiv.valuta 
			and deconturicalculate.nrp=#decontSoldPozitiv.nrp

		/*	solduri cumulate deconturi negative */
		update #decontSoldNegativ set 
			cumulat=avansuricalculate.cumulat
		from (select p2.marca, p2.cont, p2.valuta, p2.nrp, sum(p1.sold) as cumulat 
			from #decontSoldNegativ p1, #decontSoldNegativ p2 
			where p1.marca=p2.marca and p1.cont=p2.cont and p1.valuta=p2.valuta and p1.nrp<=p2.nrp 
			group by p2.marca, p2.cont, p2.valuta, p2.nrp) avansuricalculate
		where avansuricalculate.marca=#decontSoldNegativ.marca
			and avansuricalculate.cont=#decontSoldNegativ.cont
			and avansuricalculate.valuta=#decontSoldNegativ.valuta 
			and avansuricalculate.nrp=#decontSoldNegativ.nrp  

		/*	tratare sold de compensat primit prin tabela #personal
			toate deconturile care intra in soldul de compensat, se compenseaza */
		update f set se_compenseaza=1
		from #decontSoldNegativ f
		where f.cumulat<=sold_de_compensat or isnull(sold_de_compensat,0)=0 

		--ultimul decont care intra in soldul de compensat, se compenseaza partial	
		update d set d.se_compenseaza=1, d.sold=d.sold_de_compensat-(d.cumulat-d.sold)
		from #decontSoldNegativ d
		where d.se_compenseaza=0

		/*	sterg deconturile care nu se compenseaza */
		delete from #decontSoldNegativ 
		where se_compenseaza=0 or sold<0.00

		/*	calcul numar min */
		update #decontSoldNegativ 
 			set nrmin=st.nrp--,nrmax=dr.nrp
			from #decontSoldNegativ c
				cross apply
					(select top 1 smin.nrp from #decontSoldPozitiv smin where smin.marca=c.marca and smin.cont=c.cont and smin.valuta=c.valuta and c.cumulat-c.sold<smin.cumulat order by smin.cumulat) st 

		/*	calcul numar max */
 		update #decontSoldNegativ 
 			set nrmax=dr.nrp
			from #decontSoldNegativ c	
				cross apply
					(select Top 1 smax.nrp from #decontSoldPozitiv smax where smax.marca=c.marca and smax.cont=c.cont and smax.valuta=c.valuta and (smax.cumulat<=c.cumulat or smax.cumulat-smax.sold<c.cumulat) 
					order by smax.cumulat desc) dr
	
		/*	imperechere deconturi */
		select row_number() over(order by pd.marca,pd.cont,pd.data,pd.decont) as nrord_poz ,dense_rank() over(order by pd.marca) as nrord_plin, pd.marca, pd.densalariat,
			dc.decont as decont_sold_pozitiv, dc.sold as sold_pozitiv, dc.Cont as cont_decont_pozitiv, dc.valuta as valuta_pozitiv, dc.curs as curs_pozitiv, dc.loc_de_munca as lm_pozitiv,
			pd.decont as decont_sold_negativ, pd.sold as sold_negativ, pd.Cont as cont_decont_negativ, pd.valuta as valuta_negativ, pd.curs as curs_negativ, dc.loc_de_munca as lm_negativ,
			s.sumacompensata, pd.loc_de_munca, convert(varchar(8),'') as nr_plin, 0 as nr_poz
		into #tmpcompensari
		from #decontSoldNegativ pd
			inner/*left outer*/ join #decontSoldPozitiv dc on pd.marca=dc.marca and pd.cont=dc.cont and pd.valuta=dc.valuta and dc.nrp between pd.nrmin and pd.nrmax and pd.nrmin<>0
			cross apply (select round((case when pd.cumulat<=dc.cumulat then pd.cumulat else dc.cumulat end)
							-(case when  pd.cumulat-pd.sold>dc.cumulat-dc.sold then pd.cumulat-pd.sold else dc.cumulat-dc.sold end),2) as sumacompensata) s
		order by pd.marca, pd.cont, pd.valuta, pd.nrp, dc.nrp
	
		/*	setez numarul de document si numarul de pozitie */
		update #tmpcompensari
			set nr_plin=RTRIM(@idcomp)+rtrim(convert(char(4),@nrptnrdoc+nrord_plin)),
				nr_poz=@nrpozitie+nrord_poz

		--select * from #tmpcompensari

	--insertul final
		SELECT cont_decont_negativ as cont, @datacomp as data, nr_plin as numar, 'PD' as plata_incasare, @ctcomp as cont_corespondent, -sumacompensata as suma, 
			left('COMP. DECONT: '+' '+densalariat,50) as explicatii, (case when lm_negativ='' then lm_pozitiv else lm_negativ end) as loc_de_munca, marca, decont_sold_negativ as decont
		into #tmppozplin
		FROM #tmpcompensari
		union all
		SELECT cont_decont_pozitiv as cont, @datacomp as data, nr_plin as numar, 'PD' as plata_incasare, @ctcomp as cont_corespondent, sumacompensata as suma, 
			left('COMP. DECONT: '+' '+densalariat,50) as explicatii, (case when lm_pozitiv='' then lm_negativ else lm_pozitiv end) as loc_de_munca, marca, decont_sold_pozitiv
		FROM #tmpcompensari

		INSERT INTO POZPLIN 
			(Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, Cont_corespondent, Suma, Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, TVA11, TVA22, 
			Explicatii, Loc_de_munca, Comanda, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Cont_dif, Suma_dif, Achit_fact, Jurnal, detalii, tip_tva, marca, decont, efect)
		OUTPUT inserted.Cont
		into #doc_inserate(numar) 
			SELECT @sub, cont, data, numar, plata_incasare, '', '', cont_corespondent, suma, '', 0, 0, 0, 0, 0,	explicatii, loc_de_munca, '', 
				@userASiS, convert(datetime, convert(char(10), getdate(), 104), 104), replace(convert(char(8), getdate(), 114),':',''), 
				row_number() over(partition by cont order by marca, decont), '', 0, 0, @jurnalcomp, null, 0, 
				marca, decont, null
			FROM #tmppozplin

		delete from #DocDeContat
		insert into #DocDeContat
		select distinct @sub, 'PI', numar, @datacomp
		from #doc_inserate
		exec fainregistraricontabile @dinTabela=2

		set @nrptnrdoc=@nrptnrdoc + isnull((select max(nrord_plin) from #tmpcompensari),0)
		set @nrpozitie=@nrpozitie + isnull((select max(nrord_poz) from #tmpcompensari),0)
	
		exec setare_par 'DO','NRCOMP','Nr. pt. nr. doc.',0,@nrptnrdoc,''
		exec setare_par 'DO','POZITIE','Nr. pozitie doc.',0,@nrpozitie,''
	End
end try
begin catch
	set @mesaj ='(GenerareCompensariDeconturi): '+ ERROR_MESSAGE()
end catch


if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)	 

/*
select '13467557' as marca,10000 as sold
into #personal

exec GenerareCompensariDeconturi  @datacomp='2014-04-30', @idcomp='CMP', @jurnalcomp='', @stergerecomp=1, @generarecomp=1, @ctcomp='473', @ctexceptie='',
	@lm='', @marca='', @ctdecont='', @parXML=''

drop table #personal
*/
