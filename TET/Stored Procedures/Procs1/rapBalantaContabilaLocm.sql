--***
create procedure rapBalantaContabilaLocm @ContJos varchar(40), @ContSus varchar(40), @pLuna int, @pAn int,
		@valuta varchar(20)='', @curs float=1, @cLM varchar(9)=null,
		@limba varchar(2) = null,	--> limba pentru care se genereaza planul de conturi alternative, definite in proprietati din macheta CG\Conturi\Conturi alternative /corespondente.
		@tipb varchar(20)=null,	-->	filtrare pe locurile de munca 
		@tipBalanta smallint=3, --> data nu e pe locuri de munca, 2=sintetica, 3=de raportare, 1=analitica, 4=conturi alternative (cu functia fConturiAlternative), in general pentru conturi din alte tari
		@peLocm bit=0,	--> parametru pentru stabilirea nivelului de centralizare (pentru a se folosi procedura in Balanta simpla si in Balanta pe locuri de munca)
		@denLocm varchar(200)='%',	-->	filtru pe denumire loc de munca
		@nivelLocm int=100,	--> filtru pe nivel loc de munca din strlm
		@direct bit=1,	--> daca e apelat direct (adica raportul foloseste procedura fara alte proceduri intermediare) se vor selecta datele la sfarsit
						--> daca nu e direct se calculeaza si rulajele conturilor extrabilantiere
		@conturiRecompuse int=0	--> 1= se recompun conturile (pt bugetari) dupa anumite reguli; 2= se recompun si se regrupeaza dupa tabela de reguli
		,@indicator varchar(100)=null
		,@peIndbug bit=0	--> parametru pentru gruparea pe indicatori bugetari (pentru a se folosi procedura in Balanta contabila pe locuri de munca daca se doreste detalierea pe indicatori)
as
/*
exec rapBalantaContabilaLocm @ContJos='', @ContSus='z', @pLuna=12, @pAn=2014,
		@tipBalanta=1
*/
begin
declare @eroare varchar(2000)
select @eroare=''

if object_id('tempdb..#rezbalanta') is null
begin
	create table #rezbalanta (subunitate varchar(20) default '1')
	exec rapBalantaContabilaLocm_tabela
end

CREATE TABLE #balanta(
		Subunitate char(9) NOT NULL,
		Cont varchar(100) NOT NULL,
		are_analitice int not null,
		Denumire_cont varchar(2000) NOT NULL,
		Sold_inc_an_debit float NOT NULL,
		Sold_inc_an_credit float NOT NULL,
		Rul_prec_debit float NOT NULL,
		Rul_prec_credit float NOT NULL,
		Sold_prec_debit float NOT NULL,
		Sold_prec_credit float NOT NULL,
		Total_sume_prec_debit float NOT NULL,
		Total_sume_prec_credit float NOT NULL,
		Rul_curent_debit float NOT NULL,
		Rul_curent_credit float NOT NULL,
		Rul_cum_debit float NOT NULL,
		Rul_cum_credit float NOT NULL,
		Total_sume_debit float NOT NULL,
		Total_sume_credit float NOT NULL,
		Sold_cur_debit float NOT NULL,
		Sold_cur_credit float NOT NULL,
		Cont_corespondent char(100) NOT NULL,
		locm char(20)
	)
begin try
	set transaction isolation level read uncommitted
	--=RTrim(iif(Parameters!ContGrup.Value<>"", Parameters!ContGrup.Value,"7"))+"zzzzzzzzzzzzz")
	declare @q_ContJos varchar(40),@q_ContSus varchar(40),@q_pLuna int,@q_pAn int,@q_lb_den varchar(2),@q_valuta varchar(20), @q_curs float, @q_tipb varchar(20)
			,@lungimeLM int, @fltLocm bit
	select @lungimeLM=100, @nivelLocm=isnull(@nivelLocm,100), @denLocm=isnull(@denLocm,'%')
	select @lungimelm=l.Lungime from strlm l where l.Nivel=@nivelLocm 
	select @q_ContJos=@ContJos, @q_ContSus=@ContSus, @q_pLuna=@pLuna, @q_pAn=@pAn, @q_lb_den=null, @q_valuta=@valuta, @q_tipb=@tipb
	, @q_curs=isnull((case when @curs=0 then 1 else @curs end),1)

	declare --@p_ContJos char(40), @p_ContSus char(40), 
			@p_pLuna int, @p_pAn int, @p_valuta varchar(20), @p_curs float, @p_cLM char(9),
			@eLmUtiliz int,
			@comanda_str varchar(max)	--> pentru sql dinamic, unde este cazul
	
	declare @utilizator varchar(20), @rulajelm bit
	select @utilizator=dbo.fIaUtilizator('')
	select cod valoare into #LmUtiliz from lmfiltrare l where l.utilizator=@utilizator
	select @p_cLM=@cLM, @eLmUtiliz=isnull((select max(1) from #LmUtiliz),0)
	select @rulajelm=isnull((select 1 from par where Tip_parametru='GE' and Parametru='rulajelm' and Val_logica=1),0)
	select @fltLocm=(case when @denLocm<>'%' or isnull(@p_cLM,'')<>'' or @q_tipb is not null or @nivelLocm<>100 then 1 else 0 end)
	select @denLocm='%'+@denLocm+'%'
	if @fltLocm=1 and @rulajelm=0 raiserror('Nu aveti setarea pentru Balanta pe locuri de munca!',16,1)
	if @rulajelm=0 select @eLmUtiliz=0

	declare @sector_cont_par varchar(2), @sursa_cont_par varchar(1)	-->	acesti 2 par se folosesc doar daca se merge pe specificul de conturi ultradetaliate
	select --@p_ContJos=@q_ContJos, @p_ContSus=@q_ContSus, 
		@p_pLuna=@q_pLuna, @p_pAn=@q_pAn, @p_valuta=@q_valuta, @p_curs=@q_curs
		
	/*	citire sector activitate si sursa de finantare din parametrii */
	select @sector_cont_par=(case when Parametru='SECTORACT' then val_alfanumerica else @sector_cont_par end)
		,@sursa_cont_par=(case when Parametru='SURSAF' then val_alfanumerica else @sursa_cont_par end)
	from par 
	where tip_parametru='GE' and parametru in ('SECTORACT','SURSAF')
	select @sector_cont_par=isnull(@sector_cont_par,'01'), @sursa_cont_par=isnull(@sursa_cont_par,'F'),
		@indicator=@indicator+'%'

	/*
	select @pLuna, @pAn, 0, 0, 0, 0, @valuta, @curs, @cLM
	if rtrim(@valuta)<>'' exec calcul_balanta @pLuna, @pAn, 0, 0, 1, 0, @valuta, @curs, @cLM
	else exec calcul_balanta @pLuna, @pAn, 0, 0, 0, 0, @valuta, @curs, @cLM
	*/

	-->	planul de conturi (alternativ sau obisnuit, depinde de parametrul @limba);
	-->	daca @conturiRecompuse=1 se foloseste pentru "recompunerea" conturilor:
	CREATE TABLE #conturi1(
		Subunitate varchar(9),
		Cont varchar(100),
		ContOriginal varchar(100),
		Denumire_cont varchar(300),
		Tip_cont varchar(1),
		Cont_parinte varchar(100),
		Are_analitice smallint,
		Apare_in_balanta_sintetica smallint,
		Sold_debit float,
		Sold_credit float,
		Nivel smallint,
		Articol_de_calculatie varchar(20),
		Logic smallint
	)
	
		/* Parametri generali */
	Declare @p_cSubunitate char(9), @p_IFN int, @p_dData_inc_an datetime, @p_dData_sf_luna datetime, @p_dData_lunii datetime, @p_cHostID char(8)
	exec luare_date_par 'GE','SUBPRO',0,0,@p_cSubunitate OUTPUT
	exec luare_date_par 'GE', 'IFN', @p_IFN output, 0, ''
	Set @p_dData_lunii = cast(@p_pAn as char(4))+'/'+rtrim(cast(@p_pLuna as char(2))) +'/01'
	Set @p_dData_inc_an = Dateadd(month,-(@p_pLuna-1),@p_dData_lunii)
	Set @p_dData_sf_luna = dateadd(day,-1,Dateadd(month,1,@p_dData_lunii))
	--exec fainregistraricontabile @dintabela=1,@datasus=@p_dData_sf_luna
	Set @p_cHostID =  isnull((select convert(char(8), abs(convert(int, host_id())))),'')
	set @p_cLM=isnull(@p_cLM,'')

	create table #datebaza(		--> tabela care contine toate sumele ce trebuie pe mai departe
		tip_suma varchar(10),	--> 'sold','rp'=rulaj precedent, 'rc'=rulaj curent - (doar 3x2 sume sunt relevante, restul de 5x2 sunt calculate pe baza acestora, mai tarziu)
		subunitate varchar(20), cont varchar(100), rulaj_debit decimal(18,4), rulaj_credit decimal(18,4),
		loc_de_munca varchar(20), data datetime, valuta varchar(20), indbug varchar(100)
	)
	
	--> rulajele de pe conturi recompuse vor trebui propagate in sus pe balanta; ma folosesc de aceasta tabela pt asta:
	
	create table #conturiRecompuseTerti(
			cont varchar(100),			--> contul de propagat
			contSuperior varchar(100))	--> contul care se va completa cu suma din "cont"

		insert into #conturi1 (Subunitate, Cont, ContOriginal, Denumire_cont, Tip_cont, Cont_parinte,
					Are_analitice, Apare_in_balanta_sintetica, Sold_debit, Sold_credit, Nivel,
					Articol_de_calculatie, Logic)
		select Subunitate, Cont, ContOriginal, Denumire_cont, Tip_cont, Cont_parinte,
					Are_analitice, Apare_in_balanta_sintetica, Sold_debit, Sold_credit, Nivel,
					Articol_de_calculatie, Logic from dbo.fConturiAlternative(null,@limba) f
			where (@limba is not null or @direct=0 or (left(cont,1) not in ('8','9') and @conturiRecompuse=0 or left(cont,1)<>'9' and @conturiRecompuse>0) or isnull(@q_ContJos,'')<>'')
				and f.cont between RTrim(@q_ContJos) and RTrim(@q_ContSus)

	CREATE NONCLUSTERED INDEX Principal ON #conturi1
	(
		Subunitate ASC,
		ContOriginal ASC
	)

	/*************************** calcul #balanta */
	declare --@pLuna int, @pAn int, @cLM char(9), @valuta char(3), @curs float
		@p_lCentralizata bit, @p_lContCor bit, @p_lInValuta bit, @p_lIn_val_ref bit
	select @p_lCentralizata=0, @p_lContCor=0, @p_lInValuta=(case when rtrim(@p_valuta)<>'' then 1 else 0 end), @p_lIn_val_ref=0

	CREATE CLUSTERED INDEX Sub_Cont ON #balanta 
	(
		Subunitate ASC,
		Cont ASC,
		locm asc
	)
		
	-- Se va face cursor pe subunitati pentru centralizata

	Declare @p_curSub char(9), @p_curBD char(13), @p_nFetch int
	Declare cur_sub cursor for
	Select subunitate,nume_baza_de_date from sub where @p_lCentralizata = 1
	Union all
	Select @p_cSubunitate,'' 
	Open cur_sub
	Fetch next from cur_sub into @p_curSub, @p_curBD
	Set @p_nFetch = @@fetch_status

	select * into #lm
	from lm where lm.denumire like @denLocm and (@p_cLM is null or @p_cLM like RTrim(@p_cLM)+'%' )
	
	While @p_nFetch = 0
	 Begin
	  
	  If (@p_lCentralizata = 0 or (@p_lCentralizata = 1 and @p_curSub <> @p_cSubunitate and @p_curBD <> '' ))
	  Begin
	   /* Insert si tot sume */
	   --> liniile din dreptul locurilor de munca
	   insert into #datebaza(tip_suma, subunitate, cont, rulaj_debit, rulaj_credit, loc_de_munca, data, valuta, indbug)
		select (case r.data when @p_dData_inc_an then 'sold' when @p_dData_sf_luna then 'rc' else 'rp' end) as tip_suma,
				max(r.subunitate),r.cont, sum(round(r.rulaj_debit,2)*isnull(curs.curs,1)) rulaj_debit,sum(round(r.rulaj_credit,2)*isnull(curs.curs,1)) rulaj_credit,
				left(r.Loc_de_munca, @lungimelm), r.Data, r.Valuta, r.indbug
			from rulaje r 
				left outer join curs on @p_IFN=1 and @p_lInValuta=1 and @p_curs=0 and curs.valuta=r.valuta and curs.data=(case when r.data=@p_dData_inc_an then r.data-1 else r.data end)
				left join #lm l on l.cod=r.loc_de_munca
			where	r.subunitate=@p_curSub and r.data<=@p_dData_sf_luna and r.data>=@p_dData_inc_an and r.loc_de_munca like RTrim(@p_cLM)+'%' 
					and ((@p_IFN=0 or @p_lInValuta=0) and r.valuta='' or @p_IFN=1 and @p_lInValuta=1 and r.valuta=@p_valuta)
					and (@eLmUtiliz=0 or exists (select 1 from #LmUtiliz u where u.valoare=r.Loc_de_munca))
					and (@fltLocm=0 or l.cod is not null or len(@p_cLM)=0)
					and (@indicator is null or r.indbug like @indicator)
					--/*
					and (--@peLocm=0 or 
							@q_tipb is null or exists(select 1 from proprietati p where p.Cod_proprietate='TIPBALANTA' and p.Tip='LM' and 
								valoare=@q_tipb and rtrim(r.Loc_de_munca) like rtrim(p.cod)+'%'))
				and r.cont between RTrim(@q_ContJos) and RTrim(@q_ContSus)
			group by r.data, r.cont, left(r.Loc_de_munca, @lungimelm), r.valuta, r.indbug
		
		--> recompunere => #rulajeindbug => #datebaza + prelucare #conturi1 (se sterg cele >7 car. si se pun cele recompuse)
		if @conturiRecompuse>0
		begin
			delete #conturi1 where len(cont)>7
			update #conturi1 set are_analitice=1 where len(cont)=7
			insert into #conturi1 (Subunitate, Cont, ContOriginal, Denumire_cont, Tip_cont, Cont_parinte,
						Are_analitice, Apare_in_balanta_sintetica, Sold_debit, Sold_credit, Nivel,
						Articol_de_calculatie, Logic)
			select '1', left(r.cont, 7)+@sector_cont_par+isnull(c.sursaf,@sursa_cont_par)+rtrim(r.indbug) as Cont,
					left(r.cont, 7)+@sector_cont_par+isnull(c.sursaf,@sursa_cont_par)+rtrim(r.indbug) as ContOriginal,
					max(rtrim(isnull(i.denumire,c.denumire))) denumire, max(c.tip_cont), left(r.cont, 7) cont_parinte, 0 are_analitice, 0 Apare_in_balanta_sintetica, max(Sold_debit), max(Sold_credit), max(Nivel),
					max(Articol_de_calculatie), 1
			from #datebaza r
				left join (select nullif(c.detalii.value('(row/@sursaf)[1]','varchar(20)'),'') sursaf, cont, denumire_cont denumire, tip_cont,
						Apare_in_balanta_sintetica, Sold_debit, Sold_credit, nivel, Articol_de_calculatie
					from conturi c) c on r.cont=c.cont
				left join indbug i on i.indbug=r.indbug
				where len(r.cont)=7
			group by left(r.cont, 7), isnull(c.sursaf,@sursa_cont_par), r.indbug
			--> se iau separat rulajele conturilor recompuse:
			select max(r.tip_suma) tip_suma, max(r.subunitate) subunitate,
				left(r.cont, 7)+max(@sector_cont_par+r.sursaf)+rtrim(r.indbug) cont,
				sum(r.rulaj_debit) rulaj_debit, sum(r.rulaj_credit) rulaj_credit, r.loc_de_munca, max(r.data) data, max(r.valuta) valuta, max(r.indbug) indbug
			into #rulajeindbug
			from	--> probabil ca existga o metoda mai frumoasa, dar prin urmatoarele group by-uri am rezolvat pb conturilor cu lungime > 7 care au analitice si a luarii indicatorilor pt conturi de lungime 7 sau mai mare
			(select max(tip_suma) tip_suma,  max(r.subunitate) subunitate, max(r.rulaj_debit) rulaj_debit, max(r.rulaj_credit) rulaj_credit
						,r.indbug, left(r.cont,7) cont, r.data, r.valuta, r.loc_de_munca
						,max(isnull(nullif(c.detalii.value('(row/@sursaf)[1]','varchar(20)'),''),@sursa_cont_par)) sursaf
				from
				(	select max(r.tip_suma) tip_suma, max(r.subunitate) subunitate, sum(r.rulaj_debit) rulaj_debit, sum(r.rulaj_credit) rulaj_credit
						,r.indbug, left(r.cont,7) cont, r.data, r.valuta, r.loc_de_munca
					from #datebaza r	--> se iau doar sumele conturilor care sunt de lungime > 7 si care nu au analitice
					where not exists(select 1 from conturi c where r.cont=c.cont_parinte)
					group by r.indbug, left(r.cont,7), r.data, r.loc_de_munca, r.valuta
				) r
						inner join conturi c on r.cont=c.cont --and len(c.cont_parinte)=7
					where (len(c.cont_parinte)=7 or len(r.cont)=7)
				group by r.indbug, left(r.cont,7), r.data, r.loc_de_munca, r.valuta
			) r --inner join conturi p on p.cont=r.cont_parinte and len(p.cont)=7
			group by left(r.cont, 7),rtrim(r.indbug), r.loc_de_munca, r.data

			delete #datebaza where len(cont)>7

			--> sufixare conturi recompuse care nu au indicatori:
			update c set cont=rtrim(cont)+'<fara ind>', contoriginal=rtrim(contoriginal)+'<fara ind>'
			from #conturi1 c where len(c.cont)=10

			--> creare conturi parinti pentru cele recompuse:
				--> inserare cont parinte pentru cele recompuse:
			insert into #conturi1 (Subunitate, Cont, ContOriginal, Denumire_cont, Tip_cont, Cont_parinte,
						Are_analitice, Apare_in_balanta_sintetica, Sold_debit, Sold_credit, Nivel,
						Articol_de_calculatie, Logic)
			select max(c.Subunitate), left(c.Cont,10) cont,
					left(c.Cont,10) ContOriginal, max(cn.Denumire_cont), max(c.Tip_cont),
					max(left(c.cont,7)) Cont_parinte, 1 Are_analitice, max(c.Apare_in_balanta_sintetica),
					max(c.Sold_debit), max(c.Sold_credit), max(c.Nivel),
					max(c.Articol_de_calculatie), max(c.Logic)
			from #conturi1 c
				left join conturi cn on left(c.cont,7)=cn.cont
			where len(c.cont)>10
			group by left(c.Cont,10)

				--> modificare parinte astfel incat sa fie noile conturi inserate:
			update c set c.cont_parinte=left(c.cont,10)
			from #conturi1 c where len(c.cont)>10
			
			update c set c.nivel=c.nivel+1
			from #conturi1 c where len(c.cont)>7
			
			update c set are_analitice=1
			from #conturi1 c
			where exists (select 1 from #conturi1 cf where cf.cont_parinte=c.cont)
			
			update c set are_analitice=0
			from #conturi1 c
			where not exists (select 1 from #conturi1 cf where cf.cont_parinte=c.cont)

			update r set  cont=rtrim(cont)+'<fara ind>'
				from #rulajeindbug r where len(r.cont)=10
			--/*
			insert into #rulajeindbug(tip_suma, subunitate, cont, rulaj_debit, rulaj_credit, loc_de_munca, data, valuta, indbug)
			select max(r.tip_suma), max(r.subunitate),
				left(r.cont, 10) cont,
				sum(r.rulaj_debit), sum(r.rulaj_credit), r.loc_de_munca, max(r.data), max(r.valuta), max(r.indbug)
			from #rulajeindbug r
			where len(cont)>=10
			group by left(r.cont, 10), r.loc_de_munca, r.data
	--/*		
			--> completare cu analitice bugetari pt conturile de 7 caractere care nu au analitice:
				--select * from #conturi1 c1 where c1.cont_parinte='5610300'
				
				
				select cont into #conturirecompusecurulaje from #rulajeindbug group by cont
				
				insert into #rulajeindbug(tip_suma, subunitate, cont, rulaj_debit, rulaj_credit, loc_de_munca, data, valuta, indbug)
				select max(r.tip_suma), max(r.subunitate),
					r.cont+max(@sector_cont_par+isnull(nullif(cc.detalii.value('(row/@sursaf)[1]','varchar(20)'),''),@sursa_cont_par)+rtrim(r.indbug)) cont,
					sum(r.rulaj_debit), sum(r.rulaj_credit), r.loc_de_munca, max(r.data), max(r.valuta), max(r.indbug)
				from #datebaza r inner join conturi cc on r.cont=cc.cont
				where len(r.cont)=7
					and not exists (select 1 from #conturirecompusecurulaje c1 where c1.cont like r.cont+'%')
				--	and r.cont like '5610300%'
				group by r.cont, r.loc_de_munca, r.data
	--*/

			insert into #datebaza(tip_suma, subunitate, cont, rulaj_debit, rulaj_credit, loc_de_munca, data, valuta, indbug)
			select tip_suma, subunitate, cont, rulaj_debit, rulaj_credit, loc_de_munca, data, valuta, indbug
			from #rulajeindbug

		--> propagarea sumelor pe conturile superioare pentru conturile recompuse; dinamic sa fie mai clara exceptia:
			select @comanda_str=''
			select @comanda_str='
			insert into #datebaza(tip_suma, subunitate, cont, rulaj_debit, rulaj_credit, loc_de_munca, data, valuta)
			select d.tip_suma, d.subunitate, c.contSuperior, d.rulaj_debit, d.rulaj_credit, d.loc_de_munca, d.data, d.valuta
			from #datebaza d inner join #conturiRecompuseTerti c on d.cont=c.cont'
			exec(@comanda_str)

			/* Daca se cere recompunere pt. balantele speciale bugetari se respecta regulile din dbo.wfReguliDezvoltareIndBug()*/
			IF @conturiRecompuse = 2
			BEGIN
				declare 
					@prioritate int, @max_prioritate int

				/** Pentru compatibilitate cu 2005, variabila locala trebuie intai declarata si abia apoi
					atribuit o valoare. */
				set @prioritate = 1

				SELECT * INTO #reguli from dbo.wfReguliDezvoltareIndBug()--RETURNEAZA CONT,CARACTERE,PRIORITATE
				SELECT @max_prioritate = MAX(prioritate) from #reguli
				ALTER TABLE #datebaza add marcat bit

				/* Marcam conturile care corespund conform regulilor, restul le stergem*/
				WHILE @prioritate<=@max_prioritate
				BEGIN							
					update db
						set marcat = 1
					from #datebaza db
					JOIN #reguli r on db.cont LIKE r.cont+'%' and LEN(db.cont)<=r.caractere and r.prioritate = @prioritate
					
					delete db
					from #datebaza db
					JOIN #reguli r on db.cont LIKE r.cont+'%' and isnull(db.marcat,0)=0 and r.prioritate = @prioritate 
					
					select @prioritate = @prioritate + 1
				END

				DELETE #datebaza where ISNULL(marcat,0)=0
				ALTER TABLE #datebaza drop column marcat

			END
		end
		--> stabilirea legaturilor de mai mare mai mic dintre toate conturile:
			select cont,Cont_parinte as prec,c.Apare_in_balanta_sintetica,c.Are_analitice,
					(case when c.Sold_debit=1 or c.Apare_in_balanta_sintetica=1 then 1 else 0 end) as raportare into #conturi from #conturi1 c --where cont between RTrim(@q_ContJos) and RTrim(@q_ContSus)
			declare @nr int
			set @nr=0
			while @nr<>(select COUNT(1) from #conturi)
			begin
				insert into #conturi(cont, prec, Apare_in_balanta_sintetica, Are_analitice,raportare)
				select c2.cont,c1.prec,c2.Apare_in_balanta_sintetica,c2.Are_analitice,
						c2.raportare
				from #conturi c1, #conturi c2 where c1.cont=c2.prec and c1.prec<>''
				set @nr=(select COUNT(1) from #conturi)
			end
			create index indconturi on #conturi (cont)
	
			--select * from #conturi1 c where c.cont like @contjos+'%'			order by cont
			--select * from #conturi c where c.cont like @contjos+'%'			order by cont
			
		--> liniile din dreptul conturilor (sumele se calculeaza mai jos ca total al valorilor de mai sus)
		insert into #datebaza(tip_suma, subunitate, cont, rulaj_debit, rulaj_credit, loc_de_munca, data, valuta)
			select 'rc', r.subunitate, r.cont, 
					0, 0, 
					--sum(rulaj_debit),sum(rulaj_credit),
				'Total LM', max(r.data), r.valuta
			from #datebaza r
			group by r.subunitate,r.cont, r.Valuta

		insert into #balanta (Subunitate, Cont, are_analitice, Denumire_cont, Sold_inc_an_debit, Sold_inc_an_credit, Rul_prec_debit, Rul_prec_credit, Sold_prec_debit, Sold_prec_credit, Total_sume_prec_debit,
			Total_sume_prec_credit, Rul_curent_debit, Rul_curent_credit, Rul_cum_debit, Rul_cum_credit, Total_sume_debit, Total_sume_credit, Sold_cur_debit, Sold_cur_credit, Cont_corespondent, locm)
		select r.subunitate,c.cont,c.are_analitice, max(c.denumire_cont),
			sum(round(convert(decimal(20,4), round((case when tip_suma='sold' then r.rulaj_debit else 0 end),2)), 2)) as sold_inc_an_debit, 
			sum(round(convert(decimal(20,4), round((case when tip_suma='sold' then r.rulaj_credit else 0 end),2)), 2)) as sold_inc_an_credit,
			sum(round(convert(decimal(20,4), round((case when tip_suma='rp' then r.rulaj_debit else 0 end),2)), 2)) as rul_prec_debit,
			sum(round(convert(decimal(20,4), round((case when tip_suma='rp' then r.rulaj_credit else 0 end),2)), 2)) as rul_prec_credit,
			0 as sold_prec_debit, 0 as sold_prec_credit,0 as total_sume_prec_debit,0 as total_sume_prec_credit,
			sum(round(convert(decimal(20,4), round((case when tip_suma='rc' then r.rulaj_debit else 0 end),2)), 2)) as rul_curent_debit,
			sum(round(convert(decimal(20,4), round((case when tip_suma='rc' then r.rulaj_credit else 0 end),2)), 2)) as rul_curent_credit,
			0 as rul_cum_debit,0 as rul_cum_credit, 0 as total_sume_debit, 0 as total_sume_credit,
			0 as sold_cur_debit,0 as sold_cur_credit, space(13) as cont_corespondent, 
			(case when @peIndbug=0 or r.Loc_de_munca='Total LM' then r.Loc_de_munca else r.indbug end) -- daca grupare pe indbug punem in locm, indicatorul
		from #datebaza r
			-- aici se mai modifica pentru centralizare din mai multe BD
			inner join #conturi1 c on rtrim(r.cont) =rtrim(c.contOriginal) and rtrim(r.subunitate)=rtrim(c.subunitate)
		where r.subunitate=@p_curSub and r.data<=@p_dData_sf_luna and r.data>=@p_dData_inc_an --and r.loc_de_munca like RTrim(@p_cLM)+'%'
			and ((@p_IFN=0 or @p_lInValuta=0) and r.valuta='' or @p_IFN=1 and @p_lInValuta=1 and r.valuta=@p_valuta)
			and (--r.cont is null or 
			c.cont between RTrim(@q_ContJos)  and RTrim(@q_ContSus)) --and c.are_analitice=0
		group by r.subunitate, c.cont, (case when @peIndbug=0 or r.Loc_de_munca='Total LM' then r.Loc_de_munca else r.indbug end), c.are_analitice
		
		--select distinct cont from #datebaza where cont like '4010100%'
		truncate table #datebaza
	  End
	  Fetch next from cur_sub into @p_curSub, @p_curBD
	  Set @p_nFetch = @@fetch_status
	 End

	Close cur_sub
	Deallocate cur_sub
--test	return
	/*
	if @conturiRecompuse=1 
	begin
		select * from #balanta where cont like '4040200%'
		select * from #conturi where cont like '4040200%'
		select * from #datebaza where cont like '4040200%'
	end	--*/
	if @rulajelm=1 and @peLocm=1
	begin
		if @conturiRecompuse=0
		select @eroare=@eroare+rtrim(b.cont)+char(10) from #balanta b
			where b.are_analitice=1 and not exists (select 1 from conturi c where c.cont_parinte=b.cont)
		group by b.cont
		order by b.cont
		
		if len(@eroare)>0
		begin
			select @eroare='Urmatoarele conturi sunt declarate cu analitice desi nu au (balanta nu poate aparea defalcata pe locuri de munca in aceasta situatie):'
					+char(10)+@eroare
			raiserror(@eroare,16,1)
		end
	end

	--/*	Calculez totaluri in dreptul conturilor
	update b set Sold_inc_an_credit=s.sold_inc_an_credit,Sold_inc_an_debit=s.Sold_inc_an_debit,
				 Rul_prec_credit=s.Rul_prec_credit, Rul_prec_debit=s.Rul_prec_debit,
				 Rul_curent_credit=s.Rul_curent_credit, Rul_curent_debit=s.Rul_curent_debit
	from #balanta b,
	(select b.Cont, sum(Rul_prec_debit) as Rul_prec_debit, sum(Rul_prec_credit) as Rul_prec_credit,
			sum(rul_curent_debit) rul_curent_debit, SUM(rul_curent_credit) as rul_curent_credit,
			SUM(sold_inc_an_debit) as sold_inc_an_debit,SUM(sold_inc_an_credit) as sold_inc_an_credit
			from #balanta b --where b.are_analitice=1 and b.locm<>'Total LM'
			group by b.Cont) s where s.Cont=b.Cont and b.locm='Total LM'
			--*/

	delete b from #balanta b where b.locm<>'Total LM' /**	sterg liniile cu locuri de munca din dreptul conturilor de nivel superior*/
		and  b.are_analitice=1

	/*------------------------------------------
	select *  from #balanta where cont like '451%'*/


	If @p_lInValuta = 1 and @p_IFN=0
	 Update #balanta set	Sold_inc_an_debit=Sold_inc_an_debit/@p_curs, Sold_inc_an_credit=Sold_inc_an_credit/@p_curs, 
							Rul_prec_debit=Rul_prec_debit/@p_curs, Rul_prec_credit=Rul_prec_credit/@p_curs, 
							Rul_curent_debit=Rul_curent_debit/@p_curs, Rul_curent_credit=Rul_curent_credit/@p_curs
							/*,Sold_prec_debit=Sold_prec_debit/@p_curs, Sold_prec_credit=Sold_prec_credit/@p_curs, 
							Total_sume_prec_debit=Total_sume_prec_debit/@p_curs, Total_sume_prec_credit=Total_sume_prec_credit/@p_curs, 
							Rul_cum_debit=Rul_cum_debit/@p_curs, Rul_cum_credit=Rul_cum_credit/@p_curs, 
							Total_sume_debit=Total_sume_debit/@p_curs, Total_sume_credit=Total_sume_credit/@p_curs, 
							Sold_cur_debit=Sold_cur_debit/@p_curs, Sold_cur_credit=Sold_cur_credit/@p_curs*/

	/***************************		Urmeaza calculul celorlalte 5 coloane */
		update b set Sold_inc_an_debit=(case isnull(c.tip_cont,'B') when 'A' then b.Sold_inc_an_debit-b.Sold_inc_an_credit when 'P' then 0 
					else (case when b.Sold_inc_an_debit>b.Sold_inc_an_credit then Sold_inc_an_debit-b.Sold_inc_an_credit else 0 end)
			 end),
				Sold_inc_an_credit=(case isnull(c.tip_cont,'B') when 'A' then 0 when 'P' then b.Sold_inc_an_credit-b.Sold_inc_an_debit 
					else (case when b.Sold_inc_an_credit>b.Sold_inc_an_debit then Sold_inc_an_credit-b.Sold_inc_an_debit else 0 end)
			 end)
		from #balanta b left join #conturi1 c on b.cont=c.cont
		
		
		update b set 
		Total_sume_prec_debit=b.Sold_inc_an_debit+b.Rul_prec_debit, Total_sume_prec_credit=b.Sold_inc_an_credit+b.Rul_prec_credit,
		Rul_cum_debit=Rul_prec_debit+Rul_curent_debit, Rul_cum_credit=Rul_prec_credit+Rul_curent_credit,
		Total_sume_debit=Rul_prec_debit+Rul_curent_debit+Sold_inc_an_debit,Total_sume_credit=Rul_prec_credit+Rul_curent_credit+Sold_inc_an_credit
		from #balanta b
		
		update b set 
				b.Sold_prec_debit=
			(case isnull(c.tip_cont,'B') when 'A' then b.total_sume_prec_debit-b.total_sume_prec_credit when 'P' then 0 
					else (case when b.total_sume_prec_debit>b.total_sume_prec_credit then total_sume_prec_debit-b.total_sume_prec_credit else 0 end)
			 end),
				 b.Sold_prec_credit=(case isnull(c.tip_cont,'B') when 'A' then 0 when 'P' then b.Total_sume_prec_credit-b.Total_sume_prec_debit 
					else (case when b.Total_sume_prec_credit>b.Total_sume_prec_debit then Total_sume_prec_credit-b.Total_sume_prec_debit else 0 end)
			 end),
				b.Sold_cur_debit=(case isnull(c.tip_cont,'B') when 'A' then b.Total_sume_debit-b.Total_sume_credit when 'P' then 0 
					else (case when b.Total_sume_debit>b.Total_sume_credit then Total_sume_debit-b.Total_sume_credit else 0 end)
			 end),
				 b.Sold_cur_credit=(case isnull(c.tip_cont,'B') when 'A' then 0 when 'P' then b.Total_sume_credit-b.Total_sume_debit
					else (case when b.Total_sume_credit>b.Total_sume_debit then Total_sume_credit-b.Total_sume_debit else 0 end)
			 end)
		from #balanta b left join #conturi1 c on b.cont=c.cont
	/***************************		Calcularea celor doua totaluri	*/
		insert into #balanta(Subunitate, Cont, are_analitice, Denumire_cont, Sold_inc_an_debit, Sold_inc_an_credit, Rul_prec_debit, Rul_prec_credit, 
							Sold_prec_debit, Sold_prec_credit, Total_sume_prec_debit, Total_sume_prec_credit, Rul_curent_debit, Rul_curent_credit, 
							Rul_cum_debit, Rul_cum_credit, Total_sume_debit, Total_sume_credit, Sold_cur_debit, Sold_cur_credit, Cont_corespondent, 
							locm)
		select '1' Subunitate, 'Total1' Cont, 1 are_analitice, 'Total *' Denumire_cont, 0, 0, 
								0, 0, 0, 0, 
								0, 0, 0, 0, 
								0, 0, 0, 0,
								0, 0, '' cont_corespondent,
								'Total LM' locm union all
		select '1' Subunitate, 'Total2' Cont, 1 are_analitice, 'Total' Denumire_cont, 0, 0, 
								0, 0, 0, 0, 
								0, 0, 0, 0, 
								0, 0, 0, 0,
								0, 0, '' cont_corespondent,
								'Total LM' locm 
		update b set Sold_inc_an_debit=isnull(c.Sold_inc_an_debit,0),Sold_inc_an_credit=isnull(c.Sold_inc_an_credit,0), 
						Rul_prec_debit=isnull(c.Rul_prec_debit,0),Rul_prec_credit=isnull(c.Rul_prec_credit,0),
						Sold_prec_debit=isnull(c.Sold_prec_debit,0), Sold_prec_credit=isnull(c.Sold_prec_credit,0),
						Total_sume_prec_debit=isnull(c.Total_sume_prec_debit,0), Total_sume_prec_credit=isnull(c.Total_sume_prec_credit,0),
						Rul_curent_debit=isnull(c.Rul_curent_debit,0),Rul_curent_credit=isnull(c.Rul_curent_credit,0),
						Rul_cum_debit=isnull(c.Rul_cum_debit,0),Rul_cum_credit=isnull(c.Rul_cum_credit,0), 
						Total_sume_debit=isnull(c.Total_sume_debit,0), Total_sume_credit=isnull(c.Total_sume_credit,0),
						Sold_cur_debit=isnull(c.Sold_cur_debit,0), Sold_cur_credit=isnull(c.Sold_cur_credit,0)
		from #balanta b,
		(select count(1) as nr, sum(Sold_inc_an_debit) Sold_inc_an_debit, sum(Sold_inc_an_credit)Sold_inc_an_credit, 
								sum(Rul_prec_debit) Rul_prec_debit, sum(Rul_prec_credit) Rul_prec_credit, SUM(Sold_prec_debit) Sold_prec_debit,
								sum(Sold_prec_credit) Sold_prec_credit,
								sum(Total_sume_prec_debit) Total_sume_prec_debit, sum(Total_sume_prec_credit) Total_sume_prec_credit, 
								sum(Rul_curent_debit) Rul_curent_debit, sum(Rul_curent_credit) Rul_curent_credit, 
								sum(Rul_cum_debit) Rul_cum_debit, sum(Rul_cum_credit) Rul_cum_credit, 
								sum(Total_sume_debit) Total_sume_debit, sum(Total_sume_credit) Total_sume_credit,
								sum(Sold_cur_debit) Sold_cur_debit, sum(Sold_cur_credit) Sold_cur_credit from #balanta
								where are_analitice=0 and locm='total lm'
								--and cont between RTrim(@q_ContJos) and RTrim(@q_ContSus)
								) c
		where b.Cont='Total1' and c.nr is not null

		update b set Sold_inc_an_debit=isnull(c.Sold_inc_an_debit,0),Sold_inc_an_credit=isnull(c.Sold_inc_an_credit,0), 
						Rul_prec_debit=isnull(c.Rul_prec_debit,0),Rul_prec_credit=isnull(c.Rul_prec_credit,0),
						Sold_prec_debit=isnull(c.Sold_prec_debit,0), Sold_prec_credit=isnull(c.Sold_prec_credit,0),
						Total_sume_prec_debit=isnull(c.Total_sume_prec_debit,0), Total_sume_prec_credit=isnull(c.Total_sume_prec_credit,0),
						Rul_curent_debit=isnull(c.Rul_curent_debit,0),Rul_curent_credit=isnull(c.Rul_curent_credit,0),
						Rul_cum_debit=isnull(c.Rul_cum_debit,0),Rul_cum_credit=isnull(c.Rul_cum_credit,0), 
						Total_sume_debit=isnull(c.Total_sume_debit,0), Total_sume_credit=isnull(c.Total_sume_credit,0),
						Sold_cur_debit=isnull(c.Sold_cur_debit,0), Sold_cur_credit=isnull(c.Sold_cur_credit,0)
			from #balanta b,
		(select count(1) as nr, sum(Sold_inc_an_debit) Sold_inc_an_debit, sum(Sold_inc_an_credit)Sold_inc_an_credit, 
								sum(Rul_prec_debit) Rul_prec_debit, sum(Rul_prec_credit) Rul_prec_credit, SUM(Sold_prec_debit) Sold_prec_debit,
								sum(Sold_prec_credit) Sold_prec_credit,
								sum(Total_sume_prec_debit) Total_sume_prec_debit, sum(Total_sume_prec_credit) Total_sume_prec_credit, 
								sum(Rul_curent_debit) Rul_curent_debit, sum(Rul_curent_credit) Rul_curent_credit, 
								sum(Rul_cum_debit) Rul_cum_debit, sum(Rul_cum_credit) Rul_cum_credit, 
								sum(Total_sume_debit) Total_sume_debit, sum(Total_sume_credit) Total_sume_credit,
								sum(Sold_cur_debit) Sold_cur_debit, sum(Sold_cur_credit) Sold_cur_credit from #balanta b
								where b.cont between RTrim(@q_ContJos)  and RTrim(@q_ContSus) and
									exists (select 1 from #conturi c where c.cont=b.Cont and c.prec='') 
									and b.locm='Total LM' and b.Cont<>'Total1') c
		where b.Cont='Total2' and c.nr is not null

	/***************************	Se elimina randurile care nu corespund tipului raportului	*/
	if (@peLocm=1)
	begin
			delete b from #balanta b where --b.locm<>'Total LM' --and b.locm is not null 
				exists (select 1 from #conturi c where c.cont=b.Cont and 
													(@tipBalanta=2 and c.Apare_in_balanta_sintetica=0
														or @tipBalanta=3 and c.raportare=0))

			delete c from #conturi c where (@tipBalanta=2 and c.Apare_in_balanta_sintetica=0
														or @tipBalanta=3 and c.raportare=0)
	end
	/**************************		Se elimina locurile de munca pentru balanta contabila simpla	*/

	if (@peLocm=0)
		delete from #balanta where locm<>'Total LM' or cont like 'Total%'
	insert into #rezbalanta(subunitate, cont, denumire_cont, tip_cont, are_analitice, cont_parinte, Apare_in_balanta_sintetica, apare_in_balanta_de_raportare, ContBal,
		DenContBal, Sold_inc_an_debit, Sold_inc_an_credit, Rul_prec_debit, Rul_prec_credit, Sold_prec_debit, Sold_prec_credit, Total_sume_prec_debit,
		Total_sume_prec_credit, Rul_curent_debit, Rul_curent_credit, Rul_cum_debit, Rul_cum_credit, Total_sume_debit, Total_sume_credit,
		Sold_cur_debit, Sold_cur_credit, Cont_corespondent, nivel, locm, nume_lm)
	select
		isnull(c.subunitate, 1) as subunitate, isnull(c.cont,b.cont) cont, rtrim(isnull(c.denumire_cont,b.Denumire_cont)) as denumire_cont,
		c.tip_cont, c.are_analitice, 
		(case when exists (select 1 from #conturi cc where cc.cont=c.Cont_parinte) then c.cont_parinte else '' end) as cont_parinte
		, c.Apare_in_balanta_sintetica, (case when c.Sold_debit=1 then 1 else 0 end) as apare_in_balanta_de_raportare,   
		isnull(b.Cont, '') as ContBal, isnull(b.Denumire_cont, '') as DenContBal,
		isnull(b.Sold_inc_an_debit, 0) as Sold_inc_an_debit, isnull(b.Sold_inc_an_credit, 0) as Sold_inc_an_credit, 
		isnull(b.Rul_prec_debit, 0) as Rul_prec_debit, isnull(b.Rul_prec_credit, 0) as Rul_prec_credit,
		isnull(b.Sold_prec_debit, 0) as Sold_prec_debit, isnull(b.Sold_prec_credit, 0) as Sold_prec_credit,
		isnull(b.Total_sume_prec_debit, 0) as Total_sume_prec_debit, isnull(b.Total_sume_prec_credit, 0) as Total_sume_prec_credit, 
		isnull(b.Rul_curent_debit, 0) as Rul_curent_debit, isnull(b.Rul_curent_credit, 0) as Rul_curent_credit,
		isnull(b.Rul_cum_debit, 0) as Rul_cum_debit, isnull(b.Rul_cum_credit, 0) as Rul_cum_credit,
		isnull(b.Total_sume_debit, 0) as Total_sume_debit, isnull(b.Total_sume_credit, 0) as Total_sume_credit,
		isnull(b.Sold_cur_debit, 0) as Sold_cur_debit, isnull(b.Sold_cur_credit, 0) as Sold_cur_credit,
		isnull(b.Cont_corespondent, '') as Cont_corespondent, 
		isnull(c.Nivel,1)+(case when c.nivel=2 then lm.nivel else 0 end) as nivel, 
		locm, (case when @peIndbug=0 then lm.Denumire else isnull(ib.Denumire,'') end) as nume_lm --,b.Cont as ordine	-- daca grupare pe indicatori punem in locm indicatorul
	from #balanta b
		left outer join (select c.subunitate, c.cont, max(c.denumire_cont) denumire_cont, max(c.tip_cont) tip_cont, max(c.are_analitice) are_analitice, max(c.cont_parinte) cont_parinte,
					max(c.sold_debit) sold_debit, max(c.apare_in_balanta_sintetica) apare_in_balanta_sintetica, max(c.nivel) nivel
				from #conturi1 c group by c.subunitate,c.cont)
			c on c.subunitate=b.subunitate and c.cont=b.cont
		left join lm on lm.Cod=b.locm
		left join indbug ib on ib.indbug=b.locm
		--left join proprietati pr on pr.tip='cont' and cod_proprietate='DEN_'+@limba and rtrim(pr.cod)=rtrim(c.cont) 
	where --c.cont between RTrim(@q_ContJos) and RTrim(@q_ContSus) --and (b.locm is null or b.locm='')	and 
		(isnull(b.Sold_inc_an_debit, 0) <>0 or isnull(b.Sold_inc_an_credit, 0) <>0 or 
		isnull(b.Rul_prec_debit, 0)<>0 or isnull(b.Rul_prec_credit, 0) <>0 or 
		isnull(b.Sold_prec_debit, 0)<>0 or isnull(b.Sold_prec_credit, 0)<>0 or
		isnull(b.Total_sume_prec_debit, 0)<>0 or isnull(b.Total_sume_prec_credit, 0)<>0 or
		isnull(b.Rul_curent_debit, 0)<>0 or isnull(b.Rul_curent_credit, 0)<>0 or
		isnull(b.Rul_cum_debit, 0)<>0 or isnull(b.Rul_cum_credit, 0)<>0 or
		isnull(b.Total_sume_debit, 0)<>0 or isnull(b.Total_sume_credit, 0)<>0 or
		isnull(b.Sold_cur_debit, 0)<>0 or isnull(b.Sold_cur_credit, 0)<>0)
		or left(b.Cont,5)='Total'
	order by c.cont, locm
--*/--*/--*/--*/--*/
end try
begin catch
	select @eroare=error_message()+'(rapBalantaContabilaLocm '+convert(varchar(20),error_line())+')'
end catch

begin try	--> ca sa nu ramana cursorul daca apare o problema
	Close crs
	Deallocate crs
end try
begin catch end catch

begin try	--> ca sa nu ramana cursorul daca apare o problema
	Close cur_sub
	Deallocate cur_sub
end try
begin catch end catch

if len(@eroare)>0
begin
/*	truncate table #balanta
	insert into #balanta(Subunitate, Cont, are_analitice, Denumire_cont, Sold_inc_an_debit, Sold_inc_an_credit, Rul_prec_debit, Rul_prec_credit, Sold_prec_debit, Sold_prec_credit, Total_sume_prec_debit,
			Total_sume_prec_credit, Rul_curent_debit, Rul_curent_credit, Rul_cum_debit, Rul_cum_credit, Total_sume_debit, Total_sume_credit, Sold_cur_debit, Sold_cur_credit, Cont_corespondent, locm)
	select '','EROARE',0,@eroare,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'',''
	select * from #balanta*/
	
	truncate table #rezbalanta
	insert into #rezbalanta(subunitate, cont, denumire_cont, tip_cont, are_analitice, cont_parinte, Apare_in_balanta_sintetica, apare_in_balanta_de_raportare, ContBal,
		DenContBal, Sold_inc_an_debit, Sold_inc_an_credit, Rul_prec_debit, Rul_prec_credit, Sold_prec_debit, Sold_prec_credit, Total_sume_prec_debit,
		Total_sume_prec_credit, Rul_curent_debit, Rul_curent_credit, Rul_cum_debit, Rul_cum_credit, Total_sume_debit, Total_sume_credit,
		Sold_cur_debit, Sold_cur_credit, Cont_corespondent, nivel, locm, nume_lm)
	select '', 'EROARE', @eroare, '' tip_cont, 0 are_analitice, '' cont_parinte, 0 Apare_in_balanta_sintetica, 0 apare_in_balanta_de_raportare, '' ContBal,
		'' DenContBal, 0 Sold_inc_an_debit, 0 Sold_inc_an_credit, 0 Rul_prec_debit, 0 Rul_prec_credit, 0 Sold_prec_debit, 0 Sold_prec_credit, 0 Total_sume_prec_debit,
		0 Total_sume_prec_credit, 0 Rul_curent_debit, 0 Rul_curent_credit, 0 Rul_cum_debit, 0 Rul_cum_credit, 0 Total_sume_debit, 0 Total_sume_credit,
		0 Sold_cur_debit, 0 Sold_cur_credit, '' Cont_corespondent, 0 nivel, '' locm, '' nume_lm
end
/*********************	Select-ul final, cu traduceri daca sunt */

if OBJECT_ID('rapBalantaContabilaLocmSP') is not null
begin
	declare @xml xml
	set @xml = (select @ContJos ContJos, @ContSus ContSus, @pLuna pLuna, @pAn pAn, @valuta valuta, @curs curs, @cLM cLM, @limba limba, @tipb tipb, 
						@tipBalanta tipBalanta, @peLocm peLocm, @denLocm denLocm, @nivelLocm nivelLocm, 
						@direct direct, @conturiRecompuse conturiRecompuse, @indicator indicator, @peIndbug peIndbug for xml raw)

	exec rapBalantaContabilaLocmSP @parXML=@xml 
end


if (@direct=1)
	select * from #rezbalanta
	order by cont, locm

if object_id('tempdb..#balanta') is not null drop table #balanta
if object_id('tempdb..#conturi1') is not null drop table #conturi1
if object_id('tempdb..#conturi') is not null drop table #conturi
if object_id('tempdb..#LmUtiliz') is not null drop table #LmUtiliz
if object_id('tempdb..#datebaza') is not null drop table #datebaza
if object_id('tempdb..#conturirecompusecurulaje') is not null drop table #conturirecompusecurulaje
end
