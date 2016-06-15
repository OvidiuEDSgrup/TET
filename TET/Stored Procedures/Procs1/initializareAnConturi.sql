
create procedure initializareAnConturi(@sesiune varchar(50)=null, @an int, @doarStergere int=0)
as
BEGIN TRY
	declare 
		@eroare varchar(1000), @subunitate char(9), @dataSolduri datetime, @dataImplementarii datetime, @rulajelm int,
		@parXMLSP xml, @parXMLSold xml, @comandaSQL nvarchar(4000)



	if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
		raiserror('Accesul este restrictionat pe anumite locuri de munca! Nu este permisa operatia in aceste conditii!',16,1)
			
	SELECT
		@dataImplementarii=
			convert(varchar(20),isnull((select Val_numerica from par where tip_parametru='GE' and parametru='ANULIMPL'),1901))+'-'+
			convert(varchar(20),isnull((select Val_numerica from par where tip_parametru='GE' and parametru='LUNAIMPL'),1))+'-1'
	SELECT
		@rulajelm=isnull((select top 1 val_logica from par where Parametru='RULAJELM'),0)	
	SELECT
		@dataSolduri=convert(varchar(20),@an)+'-1-1'
	select 
		@subunitate=Val_alfanumerica from par where Tip_parametru='GE' and parametru='SUBPRO'
	
	if (@dataSolduri<=@dataImplementarii)
	begin
		set @eroare='Nu se poate face initializare la o data anterioara sau egala cu data implementarii ('+
				convert (varchar(20),@dataImplementarii,103)+')!'
		raiserror(@eroare,16,1)
	end
	
	/**	Se sterge eventuala initializare precedenta*/
	DELETE rulaje where subunitate=@subunitate and data=@dataSolduri 

	/**	Se completeaza in rulaje cu soldurile de inceput de an*/
	if @doarStergere=0
	begin
		/*	Varianta anterioara.
		INSERT INTO rulaje (subunitate, cont, loc_de_munca, valuta, data, rulaj_debit, rulaj_credit, indbug)
		select 
			r.subunitate, r.cont, isnull(p.cod,isnull(r.Loc_de_munca,'')) cod, r.valuta, convert(datetime,@dataSolduri), 
			round((case when c.Tip_cont='A' then 1 when c.Tip_cont='P' then 0 when sum(r.rulaj_debit)-sum(r.rulaj_credit)>0 then 1 else 0 end)*(sum(r.rulaj_debit)-sum(r.rulaj_credit)),2) as rulaj_debit,
			-round((case when c.Tip_cont='P' then 1 when c.Tip_cont='A' then 0 when sum(r.rulaj_debit)-sum(r.rulaj_credit)<0 then 1 else 0 end)*(sum(r.rulaj_debit)-sum(r.rulaj_credit)),2) as rulaj_credit, 
			r.indbug
		from rulaje r inner join conturi c on c.Cont=r.Cont
		left join proprietati p	on p.tip='LM' and p.cod_proprietate ='LMINCHCONT' 
				and p.valoare=1 and r.Loc_de_munca like rtrim(p.cod)+'%'
				and  not exists (select 1 from proprietati pp where pp.tip='LM' and pp.cod_proprietate ='LMINCHCONT' and pp.valoare=1 
				and r.Loc_de_munca like rtrim(pp.cod)+'%' and len(pp.cod)>len(p.cod))
				and @rulajelm=1
		where r.subunitate=@subunitate and r.data between convert(varchar(20),@an-1)+'-1-1' and dateadd(D,-1,@dataSolduri)	
		group by r.subunitate, r.cont, isnull(p.cod,isnull(r.Loc_de_munca,'')), r.valuta, c.Tip_cont, r.indbug
		*/
		set @parXMLSold=(select 1 as initancont for xml raw)
		if object_id('tempdb..#pRulajeConturi_t') is not null drop table #pRulajeConturi_t
		create table #pRulajeConturi_t (Subunitate varchar(10) default 1)
		exec pRulajeConturi_tabela
		/*	Apelez pRulajeConturi pentru rulajele in lei. Asa s-a discutat cu Ghita. */
		exec pRulajeConturi @nivelPlanContabil=1, @dataJos='01/01/1901', @dData=@dataSolduri, @cCont=null, @cValuta=null, @cJurnal=null, @cLM=null, @grlm=1, @grindbug=1, @parxml=@parXMLSold

		/*	Apelez pRulajeConturi pentru fiecare valuta atasata conturilor de valuta. Asa s-a discutat cu Ghita. */
		select distinct rtrim(p.valoare) as valuta
		into #valutecont
		from proprietati p 
		inner join conturi c on c.cont=p.cod and c.Subunitate=@subunitate
		where p.tip='CONT' and p.cod_proprietate='INVALUTA' and isnull(p.valoare,'')<>''
		
		select @comandaSQL=''
		select @comandaSQL=@comandaSQL+'exec pRulajeConturi @nivelPlanContabil=1, @dataJos='''+'01/01/1901'+''', @dData='''+convert(char(10),@dataSolduri,101)+''', @cvaluta='''+valuta+''', @grlm=1, @grindbug=1, @parxml='''
			+convert(varchar(max),@parXMLSold)+''''+char(13)
		from #valutecont
		exec sp_executesql @statement=@comandaSQL
		if @subunitate<>'1'
			update #pRulajeConturi_t set subunitate=@subunitate
		/*	Soldul pe nivel=1 nu trebuie luat in calcul. */
		delete from #pRulajeConturi_t where nivel=1

		INSERT INTO rulaje (subunitate, cont, loc_de_munca, valuta, data, rulaj_debit, rulaj_credit, indbug)
		select 
			r.subunitate, r.cont, isnull(p.cod,isnull(r.Loc_de_munca,'')) cod, r.valuta, convert(datetime,@dataSolduri), 
			/*	Pastrat regula de calcul a soldurilor. 
				Nu merge direct cu sum, intrucat pRulajeConturi returneaza solduri la nivel de locuri de munca de diferite nivele. Daca rulajelm=1 si lminchcont=1 atunci acestea trebuie centralizate.*/
			--sum(r.suma_debit) as rulaj_debit, sum(r.suma_credit) as rulaj_credit, 
			round((case when c.Tip_cont='A' then 1 when c.Tip_cont='P' then 0 when sum(r.suma_debit)-sum(r.suma_credit)>0 then 1 else 0 end)*(sum(r.suma_debit)-sum(r.suma_credit)),2) as rulaj_debit,
			-round((case when c.Tip_cont='P' then 1 when c.Tip_cont='A' then 0 when sum(r.suma_debit)-sum(r.suma_credit)<0 then 1 else 0 end)*(sum(r.suma_debit)-sum(r.suma_credit)),2) as rulaj_credit, 
			r.indbug
		from #pRulajeConturi_t r inner join conturi c on c.Cont=r.Cont
		left join proprietati p	on p.tip='LM' and p.cod_proprietate ='LMINCHCONT' 
				and p.valoare=1 and r.Loc_de_munca like rtrim(p.cod)+'%'
				and  not exists (select 1 from proprietati pp where pp.tip='LM' and pp.cod_proprietate ='LMINCHCONT' and pp.valoare=1 
				and r.Loc_de_munca like rtrim(pp.cod)+'%' and len(pp.cod)>len(p.cod))
				and @rulajelm=1
		group by r.subunitate, r.cont, isnull(p.cod,isnull(r.Loc_de_munca,'')), r.valuta, c.Tip_cont, r.indbug
	end

	/**	se elimina inregistarile cu sume nesemnificative sau cele care nu ar trebui preluate (conturile de tip 806. Bugetul nu se raporteaza de la un an la altul.)	*/
	DELETE rulaje where subunitate=@subunitate and data=@dataSolduri and (abs(rulaj_debit)<0.01 and abs(rulaj_credit)<0.01 or cont like '806%')

	/* Pregatire apel procedura specifica	*/
	if exists (select 1 from sysobjects where [type]='P' and [name]='initializareAnConturiSP')
	BEGIN	
		SET @parXMLSP = (select @dataSolduri datasolduri, @an an, @doarStergere doarstergere for xml raw) 
		exec initializareAnConturiSP @sesiune=@sesiune, @parXML=@parXMLSP
	END

END TRY
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH