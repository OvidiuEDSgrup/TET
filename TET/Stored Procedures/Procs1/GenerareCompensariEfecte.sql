--***
create procedure GenerareCompensariEfecte @tipefecte varchar(1)='P', @stergerecomp int, @generarecomp int, 
	@datacomp datetime, @idcomp varchar(20)='CMPP', @jurnalcomp char(3)='', @ctcomp varchar(40)='581', 
	@tert varchar(6)='', @parXML XML='<row />'
as
begin try	
	if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
	begin
		raiserror('Accesul este restrictionat pe anumite locuri de munca! Nu este permisa operatia in aceste conditii!',16,1)
		return
	end

	declare @mesaj varchar(500), @sub varchar(9)
	declare @nrptnrdoc int, @nrpozitie int, @tabela_terti int, @tabela_efecte int, @userASiS char(10), @inversare_ordine_comp_efect int

	--daca se trimite 1 atunci compensarea efectelor se va face in ordine inversa a datei scadentei (folosit la cemacon)
	SET @inversare_ordine_comp_efect = isnull(@parXML.value('(/*/@inversare_ordine_comp_efect)[1]', 'int'),0)
			
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
		where subunitate=@sub and cont=@ctcomp and data=@datacomp 
			and plata_incasare=(case when @tipefecte='P' then 'PD' else 'ID' end) 
			and (@tert='' or Tert=@tert) 
			and exists (select 1 from conturi where conturi.subunitate=@sub and conturi.cont=pozplin.cont_corespondent and conturi.sold_credit=8) 
			and (explicatii like 'Compensare ef.'+'%' or explicatii like 'CMP'+rtrim(@tipefecte)+'%' or explicatii like rtrim(@idcomp)+'%')

		delete from plin where subunitate=@sub and cont=@ctcomp and data=@datacomp 
			and not exists (select 1 from pozplin where pozplin.subunitate=plin.subunitate and pozplin.cont=plin.cont and pozplin.data=plin.data and pozplin.jurnal=plin.jurnal)

		insert into #DocDeContat
		select distinct @sub, 'PI', numar, @datacomp
		from #doc_inserate
		exec fainregistraricontabile @dinTabela=2
	End

	if @generarecomp=1
	Begin
		IF OBJECT_ID('tempdb..#terti') IS NULL
		begin
			CREATE TABLE #terti (tert varchar(13), sold float)
			set @tabela_terti=0
		end
		else
			set @tabela_terti=1

		IF OBJECT_ID('tempdb..#efecte') IS NULL
		begin
			CREATE TABLE #efecte (tert varchar(13), efect varchar(20))
			set @tabela_efecte=0
		end
		else
			set @tabela_efecte=1

		IF OBJECT_ID('tempdb..#efectSoldNegativ') IS NOT NULL drop table #efectSoldNegativ
		IF OBJECT_ID('tempdb..#efectSoldPozitiv') IS NOT NULL drop table #efectSoldPozitiv
		IF OBJECT_ID('tempdb..#tmpcompensari') IS NOT NULL drop table #tmpcompensari
		IF OBJECT_ID('tempdb..#tmppozplin') IS NOT NULL drop table #tmppozplin

		/*	tabela cu efectele cu solduri negative */
		select ROW_NUMBER() over (partition by a.tert, a.cont, a.valuta order by a.tert, a.cont, a.valuta, a.data_scadentei, a.Nr_efect) as nrp, 0 as nrmin, 0 as nrmax,
			a.Nr_efect as efect, a.tert, a.Data, a.Cont, a.Valuta, a.Curs, isnull(t.Denumire,'') as dentert, a.Loc_de_munca, a.Comanda, abs(a.Sold) as sold, CONVERT(float,0.00) as cumulat,
			isnull(te.sold,0) as sold_de_compensat, 0 as se_compenseaza
		into #efectSoldNegativ
		from efecte a
			left outer join terti t on t.Tert=a.Tert
			left join #terti te on te.Tert=a.Tert
			left join #efecte ef on ef.Tert=a.Tert and ef.efect=a.Nr_efect
		where a.Subunitate=@sub 
			and a.Tip=@tipefecte
			and (@tert='' or a.Tert=@tert) 
			and round(convert(decimal(17,5), a.sold),2)<=-0.01 
			and a.Sold_valuta=0 
			--tratare prefiltrare tabele
			and (ef.efect is not null or @tabela_efecte=0)
			and (te.tert is not null or @tabela_terti=0)
		order by a.tert,a.cont,a.Valuta,a.data,a.Nr_efect

		/*	tabela cu efectele cu solduri pozitive */
		select ROW_NUMBER() over (partition by a.tert, a.cont, a.valuta order by a.tert, a.cont, a.valuta, (case when @inversare_ordine_comp_efect=1 then a.data_scadentei else '' end) desc
				,(case when @inversare_ordine_comp_efect=0 then a.data_scadentei else '' end) asc, a.Nr_efect) as nrp,
			a.Nr_efect as efect, a.tert, a.Data, a.Cont, a.Valuta, a.Curs, isnull(t.Denumire,'') as dentert, a.Loc_de_munca, a.Comanda, a.Sold as sold, CONVERT(float,0.00) as cumulat
		into #efectSoldPozitiv
		from efecte a
			left outer join terti t on t.Tert=a.Tert
			left join #terti te on te.Tert=a.Tert
			left join #efecte ef on ef.Tert=a.Tert and ef.efect=a.Nr_efect
		where a.Subunitate=@sub 
			and a.Tip=@tipefecte
			and (@tert='' or a.Tert=@tert) 
			and a.Nr_efect>='!' 
			and round(convert(decimal(17,5), a.Sold),2)>=0.01 
			and a.Sold_valuta=0 
			--tratare prefiltrare tabele
			and (ef.efect is not null or @tabela_efecte=0)
			and (te.Tert is not null or @tabela_terti=0)
		order by a.tert,a.cont,a.valuta
			,(case when @inversare_ordine_comp_efect=1 then a.data_scadentei else '' end) desc
			,(case when @inversare_ordine_comp_efect=0 then a.data_scadentei else '' end) asc
			,a.Nr_efect
		/*
		select * from #efectSoldNegativ
		select * from #efectSoldPozitiv
		*/

		/*	solduri cumulate efecte pozitive */
		update #efectSoldPozitiv set 
			cumulat=efectecalculate.cumulat
		from (select p2.tert, p2.cont, p2.valuta, p2.nrp, sum(p1.sold) as cumulat 
				from #efectSoldPozitiv p1, #efectSoldPozitiv p2 
				where p1.tert=p2.tert and p1.cont=p2.cont and p1.valuta=p2.valuta and p1.nrp<=p2.nrp 
				group by p2.tert, p2.cont, p2.valuta, p2.nrp) efectecalculate
		where efectecalculate.tert=#efectSoldPozitiv.tert
			and efectecalculate.cont=#efectSoldPozitiv.cont
			and efectecalculate.valuta=#efectSoldPozitiv.valuta 
			and efectecalculate.nrp=#efectSoldPozitiv.nrp

		/*	solduri cumulate efecte negative */
		update #efectSoldNegativ set 
			cumulat=avansuricalculate.cumulat
		from (select p2.tert, p2.cont, p2.valuta, p2.nrp, sum(p1.sold) as cumulat 
			from #efectSoldNegativ p1, #efectSoldNegativ p2 
			where p1.tert=p2.tert and p1.cont=p2.cont and p1.valuta=p2.valuta and p1.nrp<=p2.nrp 
			group by p2.tert, p2.cont, p2.valuta, p2.nrp) avansuricalculate
		where avansuricalculate.tert=#efectSoldNegativ.tert
			and avansuricalculate.cont=#efectSoldNegativ.cont
			and avansuricalculate.valuta=#efectSoldNegativ.valuta 
			and avansuricalculate.nrp=#efectSoldNegativ.nrp  

		/*	tratare sold de compensat primit prin tabela #terti
			toate efectele care intra in soldul de compensat, se compenseaza */
		update f set se_compenseaza=1
		from #efectSoldNegativ f
		where f.cumulat<=sold_de_compensat or isnull(sold_de_compensat,0)=0 

		--ultimul efect care intra in soldul de compensat, se compenseaza partial	
		update d set d.se_compenseaza=1, d.sold=d.sold_de_compensat-(d.cumulat-d.sold)
		from #efectSoldNegativ d
		where d.se_compenseaza=0

		/*	sterg efectele care nu se compenseaza */
		delete from #efectSoldNegativ 
		where se_compenseaza=0 or sold<0.00

		/*	calcul numar min */
		update #efectSoldNegativ 
 			set nrmin=st.nrp--,nrmax=dr.nrp
			from #efectSoldNegativ c
				cross apply
					(select top 1 smin.nrp from #efectSoldPozitiv smin where smin.tert=c.tert and smin.cont=c.cont and smin.valuta=c.valuta and c.cumulat-c.sold<smin.cumulat order by smin.cumulat) st 

		/*	calcul numar max */
 		update #efectSoldNegativ 
 			set nrmax=dr.nrp
			from #efectSoldNegativ c	
				cross apply
					(select Top 1 smax.nrp from #efectSoldPozitiv smax where smax.tert=c.tert and smax.cont=c.cont and smax.valuta=c.valuta and (smax.cumulat<=c.cumulat or smax.cumulat-smax.sold<c.cumulat) 
					order by smax.cumulat desc) dr

		/*	imperechere efecte */
		select row_number() over(order by pd.tert,pd.cont,pd.data,pd.efect) as nrord_poz ,dense_rank() over(order by pd.tert) as nrord_plin, pd.tert, pd.dentert,
			ec.efect as efect_sold_pozitiv, ec.sold as sold_pozitiv, ec.Cont as cont_efect_pozitiv, ec.valuta as valuta_pozitiv, ec.curs as curs_pozitiv, ec.loc_de_munca as lm_pozitiv, ec.Comanda as com_pozitiv,
			pd.efect as efect_sold_negativ, pd.sold as sold_negativ, pd.Cont as cont_efect_negativ, pd.valuta as valuta_negativ, pd.curs as curs_negativ, ec.loc_de_munca as lm_negativ, pd.Comanda as com_negativ,
			s.sumacompensata, pd.loc_de_munca, pd.Comanda
		into #tmpcompensari
		from #efectSoldNegativ pd
			inner/*left outer*/ join #efectSoldPozitiv ec on pd.tert=ec.tert and pd.cont=ec.cont and pd.valuta=ec.valuta and ec.nrp between pd.nrmin and pd.nrmax and pd.nrmin<>0
			cross apply (select round((case when pd.cumulat<=ec.cumulat then pd.cumulat else ec.cumulat end)
							-(case when  pd.cumulat-pd.sold>ec.cumulat-ec.sold then pd.cumulat-pd.sold else ec.cumulat-ec.sold end),2) as sumacompensata) s
		order by pd.tert, pd.cont, pd.valuta, pd.nrp, ec.nrp

	--insertul final
		SELECT @ctcomp as cont, @datacomp as data, efect_sold_negativ as numar, (case when @tipefecte='P' then 'PD' else 'ID' end) as plata_incasare, tert, cont_efect_negativ as cont_corespondent, 
			-sumacompensata as suma, left(rtrim(@idcomp)+' '+rtrim(efect_sold_negativ)+' '+rtrim(dentert),50) as explicatii, lm_negativ as loc_de_munca, com_negativ as comanda, efect_sold_negativ as efect
		into #tmppozplin
		FROM #tmpcompensari
		union all
		SELECT @ctcomp as cont, @datacomp as data, efect_sold_pozitiv as numar, (case when @tipefecte='P' then 'PD' else 'ID' end) as plata_incasare, tert, cont_efect_pozitiv as cont_corespondent, 
			sumacompensata as suma, left(rtrim(@idcomp)+' '+rtrim(efect_sold_pozitiv)+' '+rtrim(dentert),50) as explicatii, lm_pozitiv as loc_de_munca, com_pozitiv as comanda, efect_sold_pozitiv as efect
		FROM #tmpcompensari

		INSERT INTO POZPLIN 
			(Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, Cont_corespondent, Suma, Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, TVA11, TVA22, 
			Explicatii, Loc_de_munca, Comanda, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Cont_dif, Suma_dif, Achit_fact, Jurnal, detalii, tip_tva, marca, decont, efect)
		OUTPUT inserted.Cont
		into #doc_inserate(numar) 
			SELECT @sub, cont, data, numar, plata_incasare, tert, '', cont_corespondent, suma, '', 0, 0, 0, 0, 0,	explicatii, loc_de_munca, comanda, 
				@userASiS, convert(datetime, convert(char(10), getdate(), 104), 104), replace(convert(char(8), getdate(), 114),':',''), 
				row_number() over(partition by cont order by tert, efect), '', 0, 0, @jurnalcomp, null, 0, 
				'', null, efect
			FROM #tmppozplin

		delete from #DocDeContat
		insert into #DocDeContat
		select distinct @sub, 'PI', numar, @datacomp
		from #doc_inserate
		exec fainregistraricontabile @dinTabela=2
	End
end try
begin catch
	set @mesaj ='(GenerareCompensariEfecte): '+ ERROR_MESSAGE()
end catch


if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)	 

/*
select '11201893' as tert, 10000 as sold
into #terti
exec GenerareCompensariEfecte @tipefecte='P', @stergerecomp=1, @generarecomp=1, @datacomp='2014-04-30', @idcomp='CMPP', @jurnalcomp='', @ctcomp='581', @tert='', @parXML=''
drop table #terti
*/
