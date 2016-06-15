--***
create procedure inchidere121 (@data datetime, @locm varchar(20), @inlocm varchar(20),
	@stergTVA int, @inchidTVA int, @inchid4423 int,
	@sterg121 int, @inchid121 int, @inv711_121 int,
	@finala int=0, @com varchar(20)='')
as
if exists (select 1 from sys.objects o where o.name='inchidere121SP')
begin
	exec inchidere121SP @data,@locm, @inlocm,@stergTVA, @inchidTVA, @inchid4423,
		@sterg121, @inchid121, @inv711_121
	return
end
begin try
	if exists (select 1 from sys.objects o where o.name='inchidere121SP1')
	begin
		exec inchidere121SP1 @data, @locm, @inlocm, @stergTVA, @inchidTVA, @inchid4423, @sterg121, @inchid121, @inv711_121
	end
	if @inlocm=''
		set @inlocm=@locm 

	if @inchid121=0 set @inv711_121=0
	if @inchidTVA=0 set @inchid4423=0
	
	if (@data is null) raiserror ('Data necompletata!',16,1)
	select @data=DATEADD(D,-DAY(dateadd(M,1,@data)),dateadd(M,1,@data)),
			@locm=isnull(@locm,''),
			@inlocm=ISNULL(@inlocm,'')
			
	/*Scriu in tabela de parametri data ultimei inchideri 121
		Este foarte utila spre exemplu in Tablou de Bord - stiu ca de atunci 
	*/
	IF NOT EXISTS(SELECT * FROM par WHERE Tip_parametru='CG' AND Parametru='DATAI121')
		INSERT INTO par (Tip_parametru ,Parametru ,Denumire_parametru ,Val_logica ,Val_numerica ,Val_alfanumerica)
			VALUES('CG','DATAI121','Data ultimei inchideri 121',0,0,CONVERT(CHAR(10),@data,102))
	ELSE
		UPDATE par SET Val_alfanumerica=CONVERT(CHAR(10),@data,102) WHERE Tip_parametru='CG' AND Parametru='DATAI121'
		
	if @locm<>'' and not exists (select 1 from lm where lm.Cod=@locm)
		raiserror ('Loc de munca inexistent!',16,1)
	
	if @inlocm<>'' and not exists (select 1 from lm where lm.Cod=@inlocm)
		raiserror ('Loc de munca inexistent!',16,1)
		
	declare @modInchidere int, @cont_121 varchar(40), @lungimelm int,--	IF -> II:
			@ded_neded bit, @bugetari int, 
			@contTvaDed varchar(40), @contTvaColectat varchar(40),
			@contTvaIncasat varchar(40), @contTvaPlata varchar(40),
			@contAnalitic481INC varchar(40), @inchidlm int,
			@dataincan datetime,
			@nrDoc121 varchar(20), @nrDocTVA varchar(20), @pozMax int,
			@ut char(10), @dataop datetime, @oraop char(6),
			@A121PT691 varchar(40), @incinv679 int, @nu481inc int
				/** @A121PT691 este analitic 121 ales separat pentru inchiderea pe 691	(din CG/Configurari/Inchidere conturi)*/
				/**	@incinv679 este un parametru care determina daca se tine cont de tipul conturilor (A,P) la inchiderea pe 609 si 709	*/
				/** @nu481inc determina daca inchidere de TVA pe locuri de munca se face fara a folosi cont intermediar */
	set @inchidlm=(case when	/**cu @inchidlm aflu daca inchiderea (intreaga operatie) se efectueaza pe loc de munca sau pe unitate*/
			(isnull((select max(convert(int,Val_logica)) from par where Tip_parametru='GE' and Parametru='RULAJELM'),0)=0 or
			not exists(select 1 from proprietati p where p.tip='LM' and p.Cod_proprietate='LMINCHCONT' and p.Valoare=1 and p.Cod<>''))
			and @locm='' then 0 else 1 end)
	set @dataop=getdate()
	set @oraop=replace(CONVERT(varchar(8),@dataop,8),':','')
	set @ut=dbo.fIaUtilizator(null)
	set @dataincan=dateadd(M,1-month(@data),dateadd(D,1-day(@data),@data))

	set @lungimelm=LEN(@locm)
	set @modInchidere=isnull((select max(Val_numerica) from par where Tip_parametru='GE' and  Parametru='NOTEINCH'),1)
	set @ded_neded=isnull((select val_logica from par where tip_parametru='GE' and parametru like 'deduct'),0)
	select @cont_121=rtrim(Val_alfanumerica) from par where Tip_parametru='GE' and  Parametru='NOTEINCH'
	select @bugetari=rtrim(Val_logica) from par where Tip_parametru='GE' and  Parametru='BUGETARI'
	if @modInchidere<>2 or isnull(@cont_121,'')=''
		set @cont_121='121'
	select @contTvaDed=Val_alfanumerica from par where Tip_parametru='GE' and  Parametru='CDTVA'
	select @contTvaColectat=Val_alfanumerica from par where Tip_parametru='GE' and  Parametru='CCTVA'
	set @contAnalitic481INC=rtrim(isnull((select Val_alfanumerica from par where Tip_parametru='GE' and  Parametru='AN481INC'),'481'))
	if (@finala=1)	set @nu481inc=1
	else set @nu481inc =isnull((select max(convert(int, val_logica)) from par where tip_parametru='GE' and parametru = 'NU481INC'),0)
	if	(@inchidlm=0 or @nu481inc=1)	/**	daca se executa inchiderea simplu, nu pe locuri de munca, nu se va folosi analitic al lui 481:*/
	begin
		select @contTvaIncasat=Val_alfanumerica from par where Tip_parametru='GE' and  Parametru='CITVA'
		select @contTvaPlata=Val_alfanumerica from par where Tip_parametru='GE' and  Parametru='CPTVA'
	end
	else	/**	se va folosi un analitic al lui 481 ca intermediar*/
	if @inchidTVA=1 and @nu481inc=0
	begin
		if @contAnalitic481INC=''
		begin
			raiserror('Nu s-a ales contul intermediar pentru inchidere TVA (de exemplu 481 sau un analitic al acestuia); procedura de inchidere s-a apelat incorect - apelati procedura inchidere121lm!',16,1)
			return
		end
		if not exists (select 1 from conturi c where c.Cont=@contAnalitic481INC and c.Are_analitice=0)
		begin
			raiserror('Contul intermediar ales pentru inchidere TVA (tabela par, val_alfanumerica pentru parametru="AN481INC" de tip="GE") nu exista sau are analitice! Procedura de inchidere s-a apelat incorect - apelati procedura inchidere121lm!',16,1)
			return
		end
		select @contTvaIncasat=@contAnalitic481INC,@contTvaPlata=@contAnalitic481INC
	end
	select @A121PT691=rtrim(val_alfanumerica) from par where Tip_parametru='GE' and parametru='A121PT691' and val_logica=1
	
	set @incinv679=isnull((select Val_logica from par where Tip_parametru='GE' and parametru='incinv679'),0)
	--if  isnull((select c.Tip_cont from conturi c where c.Cont='609'),'P')='P' or
	--	isnull((select c.Tip_cont from conturi c where c.Cont='709'),'A')='A'
	--	set @incinv679=0	/** s-au verificat conditiile de inversare a conturilor 609 si 709*/

	declare @subunitate varchar(9)
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

	set @nrDoc121='IC'+(case when month(@data)<10 then '0' else '' end)+convert(varchar(2),month(@data),102)+convert(varchar(4),year(@data))
	set @nrDocTVA='IT'+(case when month(@data)<10 then '0' else '' end)+convert(varchar(2),month(@data),102)+convert(varchar(4),year(@data))
	set @pozMax=ISNULL((select max(p.Nr_pozitie) from pozncon p where subunitate=@subunitate and data=@data and tip='IC' and (Numar=@nrDoc121 or Numar=@nrDocTVA)),0)

/****	Calculele pentru minunata inchidere TVA*/
	select @subunitate Subunitate, 'IC' Tip, 
		@nrDocTVA Numar,@data Data,x.cont, SUM(isnull(x.Suma,0)) suma,
		'' Valuta, 0 Curs, 0 Suma_valuta, 
		'Inchidere TVA' Explicatii, @ut Utilizator, 
		@dataop Data_operarii, replace(CONVERT(varchar(8),getdate(),8),':','') Ora_operarii, 
		ROW_NUMBER() over (order by x.cont) Nr_pozitie, 
		@locm Loc_munca, '' Comanda, '' Tert, 'IC' Jurnal,
		0 s4426MM4427
		--, x.indbug, (select rtrim(x.indbug) as indicator, (case when rtrim(x.indbug)='' then '1' end) as fara_indicator where @bugetari=1 for xml raw) as detalii
			into #TVAuri
			from
	(select
		c.cont,
		(case when c.cont=@contTvaDed then sum(r.rulaj_debit)-sum(r.rulaj_credit) else sum(r.rulaj_credit)-sum(r.rulaj_debit) end) as Suma
		--,r.indbug
	from rulaje r inner join conturi c on c.Cont=r.cont
	where	r.subunitate=@subunitate and valuta='' 
				and r.data between @dataincan and @data
			and c.subunitate=@subunitate and c.Are_analitice=0
			and c.cont in (@contTvaDed,@contTvaColectat)
			and r.Loc_de_munca like @locm+'%'
	group by c.cont,c.Tip_cont--,r.indbug
	union all select @contTvaDed, 0 as suma--, null as indbug
	union all select @contTvaColectat, 0 as suma--, null as indbug
	union all select @contTvaIncasat, 0 as suma--, null as indbug
	union all select @contTvaPlata, 0 as suma--, null as indbug
	)x group by cont--, indbug

	update #tvauri set suma=0 where abs(suma)<0.00009
	/**	scriu varianta de urmat in scriere #tva-uri :*/

	update t set s4426MM4427=s.varianta
	from #TVAuri t 
	inner join (select s4426.loc_munca, /*s4426.indbug,*/ (case when s4426.suma>s4427.suma then 1 else 0 end) as varianta 
		from #TVAuri s4426 
		left join #TVAuri s4427 on s4426.loc_munca=s4427.loc_munca /*and s4426.indbug=s4427.indbug*/ and s4427.cont=@contTvaColectat
		where s4426.cont=@contTvaDed
	) s on t.loc_munca=s.loc_munca --and t.indbug=s.indbug

/**	Inchiderea 121:	*/
	select	@subunitate Subunitate, 'IC' Tip, 
		@nrDoc121 Numar,
		@data Data,
		c.cont Cont_debitor,
		(case when left(c.cont,3) like '691' and @A121PT691 is not null then @A121PT691
			else
			@cont_121+
			(case when @modInchidere=4 then 
				(case when substring(c.cont,2,1)='6' or SUBSTRING(c.cont,1,3)='686' then '.02'
					  when substring(c.cont,2,1)='7' then '.03' else '.01' end)
				when @modInchidere=3 and charindex('.',c.cont)>0 then 
					(case when @ded_neded=0 then substring(c.cont,charindex('.',c.cont),10)
						when --left(c.Cont,charindex('.',c.cont))
								substring(substring(c.cont,charindex('.',c.cont)+1,2000),
								charindex('.',substring(c.cont,charindex('.',c.cont)+1,2000))+1,1) not in ('N','D')
							then substring(c.cont,charindex('.',c.cont),2)
							else substring(c.cont,charindex('.',c.cont),4)
						end)
				else '' end) end)
		 Cont_creditor, 
		sum(r.rulaj_credit)-sum(r.rulaj_debit) 
		as Suma,
		'' Valuta, 0 Curs, 0 Suma_valuta, 
	'U121'+SPACE(46) Explicatii, @ut Utilizator, 
		@dataop Data_operarii, @oraop Ora_operarii, 
		@locm Loc_munca, '' Comanda, '' Tert, 'IC' Jurnal, 
		(select rtrim(r.indbug) as indicator, (case when rtrim(r.indbug)='' then '1' end) as fara_indicator 
			where @bugetari=1 and r.indbug<>max(isnull(c.detalii.value('(/row/@indicator)[1]','varchar(20)'),'')) for xml raw) as detalii
	into #tmp
	from rulaje r inner join conturi c on c.Cont=r.cont
	where	r.subunitate=@subunitate and valuta='' 
				and r.data between @dataincan and @data
			and c.subunitate=@subunitate and c.Are_analitice=0
			and (c.cont like '7%'  and (c.Cont not like '709%' or @incinv679=1) or (c.Cont like '609%' and @incinv679=0 ))
			and r.Loc_de_munca like @locm+'%'
			and @inchid121=1
	group by c.cont,c.Tip_cont,r.indbug
	union all
	select	@subunitate Subunitate, 'IC' Tip, 
		@nrDoc121 Numar,
		@data Data,
		(case when left(c.cont,3) like '691' and @A121PT691 is not null then @A121PT691
			else
			@cont_121+
			(case when @modInchidere=4 then 
				(case when substring(c.cont,2,1)='6' or SUBSTRING(c.cont,1,3)='686' then '.02'
					  when substring(c.cont,2,1)='7' then '.03' else '.01' end)
				when @modInchidere=3 and charindex('.',c.cont)>0 
					then --substring(c.cont,charindex('.',c.cont),10)
					(case when @ded_neded=0 then substring(c.cont,charindex('.',c.cont),10)
						when --left(c.Cont,charindex('.',c.cont))
								substring(substring(c.cont,charindex('.',c.cont)+1,2000),
								charindex('.',substring(c.cont,charindex('.',c.cont)+1,2000))+1,1) not in ('N','D')
							then substring(c.cont,charindex('.',c.cont),2)
							else substring(c.cont,charindex('.',c.cont),4)
						end)
				else '' end) end) Cont_debitor, 
		c.cont Cont_creditor, 
		sum(r.rulaj_debit)-sum(r.rulaj_credit), 
		'' Valuta, 0 Curs, 0 Suma_valuta, 
	'U121' Explicatii, @ut, 
		@dataop, @oraop Ora_operarii, 
		@locm Loc_munca, '' Comanda, '' Tert, 'IC' Jurnal, 
		(select rtrim(r.indbug) as indicator, (case when rtrim(r.indbug)='' then '1' end) as fara_indicator 
			where @bugetari=1 and r.indbug<>max(isnull(c.detalii.value('(/row/@indicator)[1]','varchar(20)'),'')) for xml raw) as detalii
	from rulaje r inner join conturi c on c.Cont=r.cont
	where	r.subunitate=@subunitate and valuta='' 
				and r.data between @dataincan and @data
			and c.subunitate=@subunitate and c.Are_analitice=0
			and (c.cont like '6%' and (c.Cont not like '609%' or @incinv679=1) or (c.Cont like '709%' and @incinv679=0))
			and r.Loc_de_munca like @locm+'%'
			and @inchid121=1
	group by c.cont,c.Tip_cont,r.indbug
/**	Inchiderea TVA:	*/
	union all
	select	Subunitate, Tip, Numar, Data, 
			@contTvaColectat Cont_debitor,
			@contTvaDed Cont_creditor,
			suma suma,
		Valuta, Curs, Suma_valuta, Explicatii, @ut, Data_operarii, Ora_operarii, Loc_munca, Comanda, Tert, Jurnal, null as detalii	-- t.detalii
	from #tvauri t where (s4426MM4427=1 and t.cont = @contTvaColectat or s4426MM4427=0  and t.cont=@contTvaDed)
		and @inchidTVA=1
	union all
	select	t.Subunitate, t.Tip, t.Numar, t.Data, 
			(case when t.s4426MM4427=1 then @contTvaIncasat else @contTvaColectat end) Cont_debitor,
			(case when t.s4426MM4427=1 then @contTvaDed else @contTvaPlata end) Cont_creditor,
			(case when t.s4426MM4427=1 then 1 else -1 end)*(t.suma-s.suma) suma,
		t.Valuta, t.Curs, t.Suma_valuta, t.Explicatii, @ut, t.Data_operarii, t.Ora_operarii, t.Loc_munca, t.Comanda, t.Tert, t.Jurnal, null as detalii	-- t.detalii
	from #tvauri t 
	inner join #tvauri s on t.loc_munca=s.loc_munca /*and t.indbug=s.indbug*/
	where t.cont=@contTvaDed and s.cont=@contTvaColectat and @inchidTVA=1
update #tmp set explicatii=	'Gen. note '+rtrim(convert(varchar(40),cont_debitor))+'='+rtrim(convert(varchar(40),cont_creditor))
		where explicatii='U121'

if @inv711_121=1
	update #tmp set cont_creditor=Cont_debitor, Cont_debitor=cont_creditor, suma=-suma 
		where Cont_debitor like '711%' and cont_creditor like @cont_121+'%' and suma<0 
		
delete from #tmp  where abs(suma)<0.00009

insert into pozncon(
Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, 
															Nr_pozitie, Loc_munca, Comanda, Tert, Jurnal, detalii)
select 
Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, @ut, Data_operarii, Ora_operarii, 
	@pozMax+row_number() over (order by cont_debitor,cont_creditor) Nr_pozitie, 
	@inlocm Loc_munca, @com Comanda, Tert, Jurnal, detalii
 from #tmp

drop table #tmp drop table #tvauri

/**	Inchiderea 4423=4424*/
if (@inchid4423=1 and @inchidlm=0)
begin
	exec fainregistraricontabile @dinTabela=1,@dataSus=@data

	select @contTvaIncasat=Val_alfanumerica from par where Tip_parametru='GE' and  Parametru='CITVA'
	select @contTvaPlata=Val_alfanumerica from par where Tip_parametru='GE' and  Parametru='CPTVA'
	select cont, sum(isnull(x.suma,0)) suma into #tmp1
		from
	(select r.subunitate,r.Cont,
		(case when r.cont=@contTvaIncasat	then sum(isnull(r.rulaj_debit,0))-sum(isnull(r.rulaj_credit,0)) 
											else sum(isnull(r.rulaj_credit,0))-sum(isnull(r.rulaj_debit,0)) end) as suma
		from rulaje r
	where r.subunitate=@subunitate and valuta='' and r.data between @dataincan and @data
		and (r.cont=@contTvaPlata or r.cont=@contTvaIncasat)
		and r.Loc_de_munca like @locm+'%'
		group by subunitate, Cont
		union all select @subunitate subunitate, @contTvaPlata cont,0 suma
		union all select @subunitate subunitate, @contTvaIncasat cont,0 suma
	) x 
	group by subunitate, Cont 

	set @pozMax=ISNULL((select max(p.Nr_pozitie) from pozncon p where subunitate=@subunitate and data=@data and tip='IC' and (Numar=@nrDoc121 or Numar=@nrDocTVA)),0)

	if isnull((select min(r.suma) from #tmp1 r),0)>0
	insert into pozncon(Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, 
															Nr_pozitie, Loc_munca, Comanda, Tert, Jurnal)
	select	@subunitate,'IC',@nrDocTVA,@data,@contTvaPlata,@contTvaIncasat,isnull((select min(r.suma) from #tmp1 r),0),
		'',0,0,'Inchidere '+rtrim(convert(varchar(40),@contTvaPlata))+'='+rtrim(convert(varchar(40),@contTvaIncasat)),@ut,
		@dataop,@oraop,@pozMax+1,@inlocm,@com,'','IC'
	drop table #tmp1
	
end
exec fainregistraricontabile @dinTabela=1,@dataSus=@data

end try
begin catch
	declare @eroare varchar(200)
	set @eroare='inchidere121 (linia '+convert(varchar(20),ERROR_LINE())+'):'+CHAR(10)+
			ERROR_MESSAGE()
	raiserror(@eroare,16,1)
end catch
