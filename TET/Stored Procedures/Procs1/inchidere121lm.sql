--***

CREATE procedure inchidere121lm (@data datetime, @locm varchar(20), @inlocm varchar(20),
	@stergTVA int, @inchidTVA int, @inchid4423 int,
	@sterg121 int, @inchid121 int, @inv711_121 int, @com varchar(20)='')
as
/*
Exemplu de apel:
	exec inchidere121lm @data='2013-06-30', @locm='1', @inlocm=null,
		@stergTVA=1, @inchidTVA=1, @inchid4423=0,
		@sterg121=1, @inchid121=1, @inv711_121=0, @com=''
*/
begin
	
	exec fainregistraricontabile @dinTabela=1,@dataSus=@data
	/*Scriu in tabela de parametri data ultimei inchideri 121
		Este foarte utila spre exemplu in Tablou de Bord - stiu ca de atunci 
	*/
	IF NOT EXISTS(SELECT * FROM par WHERE Tip_parametru='CG' AND Parametru='DATAI121')
		INSERT INTO par ( Tip_parametru ,Parametru ,Denumire_parametru ,Val_logica ,Val_numerica ,Val_alfanumerica)
			VALUES('CG','DATAI121','Data ultimei inchideri 121',0,0,CONVERT(CHAR(10),@data,102))
	ELSE
		UPDATE par SET Val_alfanumerica=CONVERT(CHAR(10),@data,102) WHERE Tip_parametru='CG' AND Parametru='DATAI121'

	set @inlocm=isnull(@inlocm,'')
	declare @peToateLM int		/**	@peToateLM	determina daca se vor inchide conturile pe lm 'LMINCHCONT' sau doar pe @locm*/
	set @peToateLM=(case when 
		isnull((select max(convert(int,Val_logica)) from par where Tip_parametru='GE' and Parametru='RULAJELM'),0)=1 then 1
		else 0 end)
	/**	Daca vreau inchidere TVA pe locuri de munca trebuie sa am definit un analitic al lui 481 pt nota intermediara:*/
	declare @inchidlm int, @contAnalitic481INC varchar(40), @nu481inc int, @lminch varchar(20)
		/** @nu481inc determina daca inchidere de TVA pe locuri de munca se face fara a folosi cont intermediar */
		/**	lminch=locul de munca pe care se vor inchide inregistrarile care nu au inchiderea pe locuri de munca	*/
	set @contAnalitic481INC=rtrim(isnull((select Val_alfanumerica from par where Tip_parametru='GE' and  Parametru='AN481INC'),'481'))
	set @nu481inc =isnull((select max(convert(int, val_logica)) from par where tip_parametru='GE' and parametru = 'NU481INC'),0)
	if (@inlocm='')
		set @lminch=isnull((select rtrim(val_alfanumerica) from par where Tip_parametru='GE' and parametru='LMINCH'),'')
	else set @lminch=@inlocm
	set @inchidlm=(case when	/**cu @inchidlm aflu daca inchiderea (intreaga operatie) se efectueaza pe loc de munca sau pe unitate*/
			(isnull((select max(convert(int,Val_logica)) from par where Tip_parametru='GE' and Parametru='RULAJELM'),0)=0 or
			not exists(select 1 from proprietati p where p.tip='LM' and p.Cod_proprietate='LMINCHCONT' and p.Valoare=1 and p.Cod<>''))
			and @locm='' then 0 else 1 end)
	if	@inchidTVA=1 and @inchidlm=1 and @nu481inc=0
	begin
		if @contAnalitic481INC=''
		begin
			raiserror('Nu s-a ales contul intermediar pentru inchidere TVA (de exemplu 481 sau un analitic al acestuia) in tabela par, val_alfanumerica pentru parametru="AN481INC" de tip="GE"!',16,1)
			return
		end
		if not exists (select 1 from conturi c where c.Cont=@contAnalitic481INC and c.Are_analitice=0)
		begin
			raiserror('Contul intermediar ales pentru inchidere TVA (tabela par, val_alfanumerica pentru parametru="AN481INC" de tip="GE") nu exista sau are analitice!',16,1)
			return
		end
	end
	
	declare @inchidtot int	/**	cu @inchidtot se determina daca se vor inchide toate conturile	*/
	set @inchidtot=(case when @inchidTVA+@inchid121>0 and (@peToateLM=0 or rtrim(@locm)='') then 1 else 0 end)
	
	/**	verificare loc de munca pe care se face inchiderea pe unitate a notelor */
	if @inchidtot=1 and @inlocm='' 
		and not exists (select 1 from lm where lm.Cod=@lminch)
		and (@lminch<>'' or @lminch='' and exists(select 1 from par where parametru='CENTPROF' and val_numerica=1)) 
			/** se verifica doar daca este completat (daca nu e nevoie strict, se permite loc de munca necompletat) */
	begin
		raiserror('Locul de munca pentru inchiderea pe unitate nu exista (verificati in tabela par, val_alfanumerica pentru parametru="LMINCH" si tip_parametru="GE")',16,1)
		return
	end
		
	declare @subunitate varchar(9), @p_locm varchar(20), @p_inlocm varchar(20)
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
	
	/**************** pana aici se vor trata exceptii, de aici incepe modificarea datelor, daca totul e bine */
	declare @aminchis_lm int set @aminchis_lm=0		/**	cu @aminchis_lm aflu daca s-a inchis cel putin pe un loc de munca */
	declare @filtrareUser bit, @userASiS char(10) 
	set @userASiS=dbo.fIaUtilizator(null)
	select @filtrareUser=dbo.f_areLMFiltru(@userASiS)

	delete p from pozncon p 
		left join lmfiltrare pr on pr.cod=p.Loc_munca and pr.utilizator=@userASiS
		where p.subunitate=@subunitate and p.data=@data and p.Tip='IC' and (@sterg121=1 and p.Numar like 'IC%' or @stergTVA=1 and p.Numar like 'IT%') and p.Loc_munca like @locm+'%'
			and (@inchidlm=0 or @filtrareUser=0 or pr.utilizator=@userASiS)
	
	exec fainregistraricontabile @dinTabela=1,@dataSus=@data

	declare cr cursor for 
	select rtrim(lm.cod) cod,rtrim(lm.cod) inlocm 
		from lm 
		left join lmfiltrare pr on pr.cod=lm.cod and pr.utilizator=@userASiS
		where @peToateLM=1 and lm.cod like @locm+'%' and
			exists (select 1 from proprietati p where p.tip='LM' and p.Cod_proprietate='LMINCHCONT' and p.Valoare=1 and p.Cod=lm.Cod)
			and (@filtrareUser=0 or pr.utilizator=@userASiS)
		order by cod desc
	open cr
	fetch next from cr into @p_locm,@p_inlocm
	while (@@FETCH_STATUS=0)
	begin
		set @aminchis_lm=1
		exec inchidere121 @data,@p_locm,@p_inlocm,@stergTVA, @inchidTVA, @inchid4423,@sterg121, @inchid121, @inv711_121, @finala=0, @com=@com 
		fetch next from cr into @p_locm,@p_inlocm
	end
	close cr
	deallocate cr
	/**	citirea variabilelor pentru a inchide TVA pe unitate*/
	declare @nrDocTVA varchar(20)
	set @nrDocTVA='IT'+(case when month(@data)<10 then '0' else '' end)+convert(varchar(2),month(@data),102)+convert(varchar(4),year(@data))	
		
	declare @contTvaIncasat varchar(40), @contTvaPlata varchar(40), @contTvaDed varchar(40), @contTvaColectat varchar(40),
			@dataop datetime, @oraop char(6), @pozMax int, @nrdoc121 varchar(20)

	select @contTvaIncasat=Val_alfanumerica from par where Tip_parametru='GE' and  Parametru='CITVA'
	select @contTvaPlata=Val_alfanumerica from par where Tip_parametru='GE' and  Parametru='CPTVA'
	select @contTvaDed=Val_alfanumerica from par where Tip_parametru='GE' and  Parametru='CDTVA'
	select @contTvaColectat=Val_alfanumerica from par where Tip_parametru='GE' and  Parametru='CCTVA'

	set @dataop=getdate()
	set @oraop=replace(CONVERT(varchar(8),@dataop,8),':','')
	set @nrDoc121='IC'+(case when month(@data)<10 then '0' else '' end)+convert(varchar(2),month(@data),102)+convert(varchar(4),year(@data))
	/** se face diferenta de tva pe unitate*/
	if (@inchidlm=1 and @nu481inc=0) and @filtrareUser=0
	begin
		set @pozMax=ISNULL((select max(p.Nr_pozitie) from pozncon p where subunitate=@subunitate and data=@data and tip='IC' and (Numar=@nrDoc121 or Numar=@nrDocTVA)),0)
	
		insert into pozncon(Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, 
																Nr_pozitie, Loc_munca, Comanda, Tert, Jurnal)
		select @subunitate,'IC',@nrDocTVA,@data,p.Cont_debitor, p.Cont_creditor,-sum(p.Suma),
			'',0,0,'Inchidere '+rtrim(convert(varchar(40),p.Cont_creditor))+'='+rtrim(convert(varchar(40),p.Cont_debitor)),@userASiS,
			@dataop,@oraop,@pozMax+row_number() over (order by p.cont_creditor),@lminch,@com,'','IC'
			from pozncon p where rtrim(p.Loc_munca)<>rtrim(@inlocm)
					and rtrim(p.Numar)=rtrim(@nrDocTVA) and p.Cont_creditor=@contTvaDed
			group by p.Cont_creditor, p.Cont_debitor
		set @pozMax=ISNULL((select max(p.Nr_pozitie) from pozncon p where subunitate=@subunitate and data=@data and tip='IC' and (Numar=@nrDoc121 or Numar=@nrDocTVA)),0)
		insert into pozncon(Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, 
																Nr_pozitie, Loc_munca, Comanda, Tert, Jurnal)
		select @subunitate,'IC',@nrDocTVA,@data,p.Cont_debitor,p.Cont_creditor,-sum(p.Suma),
			'',0,0,'Inchidere '+rtrim(convert(varchar(40),p.Cont_creditor))+'='+rtrim(convert(varchar(40),p.Cont_debitor)),@userASiS,
			@dataop,@oraop,@pozMax+row_number() over (order by p.cont_creditor),@lminch,@com,'','IC'
			from pozncon p where rtrim(p.Loc_munca)<>rtrim(@inlocm)
					and rtrim(p.Numar)=rtrim(@nrDocTVA) and p.Cont_debitor=@contTvaColectat and p.Cont_creditor<>@contTvaDed
			group by p.Cont_creditor, p.Cont_debitor
		/*Mai fac odata inregistrari contabile dupa ce am generat notele de inchidere cu minus*/
		exec fainregistraricontabile @dinTabela=1,@dataSus=@data
	end
	/**	Se inchid notele pentru care nu s-a cerut inchidere pe locuri de munca (daca nu e filtrata inchiderea) */
	if @inchidTot=1 and (@inchidlm=0 or @filtrareUser=0)
		exec inchidere121 @data, @locm, @lminch,@stergTVA, @inchidTVA, @inchid4423,	@sterg121, @inchid121, @inv711_121, @finala=1, @com=@com
	/** se face nota 4424 la 4423*/
	if (@inchid4423=1 and @inchidlm=1) and @filtrareUser=0
	begin
		/*Mai fac odata inregistrari contabile dupa ce am generat notele de inchidere*/
		exec fainregistraricontabile @dinTabela=1,@dataSus=@data

		declare @dataincan datetime
		set @dataincan=dateadd(M,1-month(@data),dateadd(D,1-day(@data),@data))

		select cont, sum(isnull(x.suma,0)) suma into #tmp1
			from
		(select r.subunitate,r.Cont,
			(case when r.cont=@contTvaIncasat	then sum(isnull(r.rulaj_debit,0))-sum(isnull(r.rulaj_credit,0)) 
												else sum(isnull(r.rulaj_credit,0))-sum(isnull(r.rulaj_debit,0)) end) as suma
			from rulaje r
		where r.subunitate=@subunitate and valuta='' and r.data between @dataincan and @data
			and (r.cont=@contTvaPlata or r.cont=@contTvaIncasat)
			and (r.Loc_de_munca like @locm+'%' or @nu481inc=1)
			group by subunitate, Cont
			union all select @subunitate subunitate, @contTvaPlata cont,0 suma
			union all select @subunitate subunitate, @contTvaIncasat cont,0 suma
		) x 
		group by subunitate, Cont 

		set @pozMax=ISNULL((select max(p.Nr_pozitie) from pozncon p where subunitate=@subunitate and data=@data and tip='IC' and (Numar=@nrDoc121 or Numar=@nrDocTVA)),0)

		if isnull((select min(abs(r.suma)) from #tmp1 r),0)>0
		insert into pozncon(Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Valuta, 
							Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, 
																Nr_pozitie, Loc_munca, Comanda, Tert, Jurnal)
		select	@subunitate,'IC',@nrDocTVA,@data,@contTvaPlata,@contTvaIncasat,isnull((select min(r.suma) from #tmp1 r),0),
			'',0,0,'Inchidere '+rtrim(convert(varchar(40),@contTvaPlata))+'='+rtrim(convert(varchar(40),@contTvaIncasat)),@userASiS,
			@dataop,@oraop,@pozMax+1,@lminch,@com,'','IC'

	drop table #tmp1
	end
	-- aici am pus apel procedura de prelucrare a notelor de inchidere din pozncon
	if exists (select 1 from sys.objects o where o.name='inchidere121SP2')
	begin
		exec inchidere121SP2 @data,@locm, @inlocm,@stergTVA, @inchidTVA, @inchid4423,@sterg121, @inchid121, @inv711_121
	end
	
	/*Mai fac odata inregistrari contabile dupa ce am generat notele de inchidere*/
	exec fainregistraricontabile @dinTabela=1,@dataSus=@data

end
