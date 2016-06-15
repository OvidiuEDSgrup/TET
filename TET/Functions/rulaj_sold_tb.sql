--***
create function rulaj_sold_tb (
	@conturi varchar(4000),		--> lista de conturi, separate prin virgule
	@lm varchar(4000),			--> lista de locuri de munca, separate prin virgule
	@tipint varchar(20),				--> tip interval - obligatoriu;
									--		1='luna'=luna
									--		2='decada'=decada
									--		3='saptamana'=saptamana
									--		4='zi'=zi
	@datajos datetime,			--> inceput interval; daca e necompletat (null) va incepe cu 1 ianuarie a anului de la @datasus
	@datasus datetime,			-->	sfarsit interval; daca e necompletat se foloseste configurarea par.(TB & LUNA.IND)
	@valuta varchar(3),			--> filtru pe o valuta
	@tip_sume varchar(20)='0')	--> parametru tip calcul - daca 1 sau "rulaj" sau "r" => rulaje 
								-->						 - daca 0 sau "sold" sau "s" => solduri
								-->						 - 2,3 sau "rd","rc" sau... => rulaje debit/credit
								-->						 - 4,5 sau "sd","sc" sau... => solduri debit/credit
								-->						 - 6,7 sau "rcd","rcc" sau... => rulaj cumulat debit/credit
returns @rez table (suma decimal(20,3), data DATETIME, LOCMUNCA VARCHAR(20))
as  
begin
	declare @utilizator varchar(50)
	select @utilizator=dbo.fIaUtilizator('')
	select @tipint=(case @tipint when 'luna' then '1'
								when 'decada' then '2'
								when 'saptamana' then '3'
								when 'zi' then '4'
						else @tipint
				end),
			@valuta=isnull(@valuta,'')
	select @tip_sume=(case @tip_sume when 'rulaj' then '1' when 'r' then '1'	-->	unificarea codificarilor  parametrului @tip_sume:
									 when 'sold' then '0' when 's' then '0'
									 when 'rd' then '2' when 'rulaj debit' then '2'
									 when 'rc' then '3' when 'rulaj credit' then '3'
									 when 'sd' then '4' when 'sold debit' then '4'
									 when 'sc' then '5' when 'sold credit' then '5'
									 when 'rcd' then '6' when 'rulaj cumulat debit' then '6'
									 when 'rcc' then '7' when 'rulaj cumulat credit' then '7'
									 else @tip_sume
					end)
	declare @rulaj_sold int, @debit_credit int, @cumulat int	--> cu acesti 2 parametri se detaliaza semnificatiile din par @tip_sume
	select	@rulaj_sold=(case when @tip_sume in ('0','4','5') then 0 else 1 end),
			@debit_credit=(case when @tip_sume in ('0','1') then -1 
								when @tip_sume in ('2','4','6') then 1 else 0 end),	-->	@debit_credit: 1=debit, 0=credit, -1=stil vechi
			@cumulat=(case when @tip_sume in ('6','7') then 1 else 0 end)
						
	if @datasus is null
	begin
		set @datasus=isnull((select val_alfanumerica from par where Tip_parametru='TB' and Parametru='LUNA.IND'),getdate())
		set @datasus	--=dbo.EOM(@datasus)
						=dateadd(d,-day(dateadd(M,1,@datasus)),dateadd(M,1,@datasus))		-->eom
	end
	if @datajos is null set @datajos=dateadd(m,1-month(@datasus),dateadd(d,1-DAY(@datasus),@datasus))	-->boy
	if (@tipint=1) set @datasus=dateadd(d,-day(dateadd(M,1,@datasus)),dateadd(M,1,@datasus))			-->eom
	declare @dataimpl datetime, @sc float,@sold_initial float,@subunitate varchar(20)  
	select @dataimpl=dateadd(m,1,dateadd(d,-1,convert(datetime,convert(varchar(4),p1.val_numerica)+'-'+convert(varchar(2),p2.val_numerica)+'-1')))
		from par p1, par p2 
		where p1.tip_parametru='GE' and p1.parametru like 'anulimpl' and p2.tip_parametru='GE' and p2.parametru like 'lunaimpl'  
	if (@datajos<@dataimpl) set @datajos=@dataimpl  
	select @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='subpro'  

	declare @iv int,@cont varchar(20), @tipCont varchar(1)
	declare @conturi2 table(cont varchar(20),tip varchar(1))  
	set @conturi=replace(isnull(@conturi,''),' ','')
	if @conturi='' set @conturi='%' 
	set @conturi=rtrim(@conturi)+','  
	while (isnull(@conturi,'')<>'')  
	begin  
		set @iv=charindex(',',@conturi)  
		set @cont=substring(@conturi,1,@iv-1)
		select @tipCont=c.Tip_cont from conturi c where c.cont=@cont
		insert into @conturi2 (cont, tip)
			select a.cont, @tipCont
			from arbconturi(@cont) a inner join conturi c on a.cont=c.cont and c.are_analitice=0
			where not exists (select 1 from @conturi2 co where co.cont=a.cont)  
		set @conturi=substring(@conturi,@iv+1,len(@conturi)-@iv)  
	end  -- m-am asigurat ca iau doar soldurile de analitice  
	--> am identificat conturile
	 
	set @sold_initial=0
	DECLARE @rulajelm int, @lminch varchar(50)	--> flag pt inchidere pe lm si locul de munca pt inchidere conturi pe unitate - care nu au lm atasat
	select @rulajelm=ISNULL((SELECT val_logica FROM par WHERE tip_parametru='GE' AND parametru='rulajelm'),0)
			,@lminch=''--isnull((select rtrim(val_alfanumerica) from par where Tip_parametru='GE' and parametru='LMINCH'),'')
			--	test	set @lminch='123'	--set @rulajelm=0
	
	declare @tlm table(lm varchar(20))		--> tabela pentru filtrare si "autofiltrare" pe locuri de munca
	declare @filtruLM int					-->	se trateaza filtrarile pe locuri de munca
	select @filtruLM=0, @lm=isnull(@lm,''), @lm=replace(isnull(@lm,''),' ','')
	if (@rulajelm=1)
	begin
		insert into @tlm (lm)			--> se adauga locul de munca default pt inchidere
			select @lminch --where @lminch<>''
		if (len(@lm)>0)			--> se trateaza filtrul explicit primit prin par functiei
		begin
			select @filtruLM=1
			select @lm=','+@lm+','
			insert into @tlm (lm)
			select SUBSTRING(@lm, t.n+1,charindex(',',@lm,n+1)-n-1)
			from Tally t
			where t.N<LEN(@lm) and substring(@lm,t.N,1)=',' and substring(@lm,t.N-1,1)<>','
				and SUBSTRING(@lm, t.n+1,charindex(',',@lm,n+1)-n-1)<>@lminch
			
			delete t from @tlm t where not exists (select 1 from proprietati p	--> raman doar acele locuri de munca cu LMINCHCONT
					where p.tip='LM' and p.Cod_proprietate='LMINCHCONT' and p.Valoare=1 and p.Cod=t.lm)
		end
		else
		insert into @tlm (lm)			-->	se iau doar acele locuri de munca pentru care exista setarea de inchidere conturi
				select rtrim(p.Cod) from proprietati p 
						where p.tip='LM' and p.Cod_proprietate='LMINCHCONT' and p.Valoare=1 and rtrim(p.Cod)<>@lminch
				
				/*	-- deocamdata nu se autofiltreaza pe locuri de munca utilizatori deoarece ar altera calculul
				delete t from @tlm t 
					where not exists (select 1 from proprietati p	--> autofiltrarea pe utilizator
							where p.Tip='UTILIZATOR' and p.Cod_proprietate='LOCMUNCA' and p.Cod=@utilizator 
									and t.lm like rtrim(p.Valoare)+'%' and rtrim(p.valoare)<>'')
									and exists (select 1 from proprietati p	--> autofiltrarea pe utilizator
							where p.Tip='UTILIZATOR' and p.Cod_proprietate='LOCMUNCA' and p.Cod=@utilizator 
									and rtrim(p.valoare)<>'')	--*/
	end	
	--> am identificat locurile de munca
	
	declare @r table (data datetime, dataInterval datetime)
	declare @tipIntervale int, @dataIntervalJos datetime, @dataan datetime
	select	@dataan=dateadd(M,1-month(@datajos),dateadd(d,1-day(@datajos), @datajos)),
			@tipIntervale=(case when @rulaj_sold=1 and @cumulat=0 then 1 else 0 end),
			@dataIntervalJos=(case when @cumulat=0 then @datajos else @dataan end)
				--> @tipIntervale:	rulajul cumulat trebuie generat oricand, ca si soldul, in timp ce rulajele se genereaza doar pt zilele cu rulaje
	insert into @r(data,dataInterval)
		SELECT i.data, i.dataInterval from dbo.generezIntervaleCuCorespondenta(@tipint, @dataIntervalJos, @datasus,@tipIntervale) i order by data
	--> am generat datele in care ne intereseaza sumele
	
	declare @startluna datetime, @zi2luna datetime
	select @startluna=dateadd(d,1-DAY(@datajos),@datajos),	-->bom
			@zi2luna=dateadd(d,2-DAY(@datajos),@datajos)	-->bom+1
	declare @pp table (suma float,data datetime, locmunca varchar(20), tipCont varchar(1), tipSuma int, cont varchar(20))	-->tipSuma:	1=sold, 2=rulaj debit, 3=rulaj credit

		insert into @pp(suma,data,locmunca, tipCont, tipSuma, cont)
			select (case when @debit_credit<>0 or @rulaj_sold=0 then
						sum(isnull(rulaj_debit,0)) else 0 end)
					-(case when @debit_credit<>1 or @rulaj_sold=0 then sum(isnull(rulaj_credit,0)) else 0 end)
					, r.data,
				isnull(left((case when isnull(r.Loc_de_munca,'')='' then @lminch else r.Loc_de_munca end),
						(select Max(len(t.lm)) from @tlm t where r.Loc_de_munca like t.lm+'%' or r.Loc_de_munca='' and lm=@lminch)),@lminch),
				c.tip,
				1 tipSuma, c.cont
			from --@r i, 
				rulaje r
				inner join @conturi2 c on RTRIM(r.Cont)=c.cont
			where
				(@valuta is null or isnull(valuta,'')=@valuta) and subunitate=@subunitate
				and r.data between @dataan and @datasus
				and (@filtruLM=0 or exists(select 1 from @tlm where r.Loc_de_munca like lm+'%' or r.Loc_de_munca='' and lm=@lminch))
				and (@cumulat=0 or not(day(data)=1 and month(data)=1))
			group by r.data, r.Loc_de_munca, c.tip, c.cont
		
			--> s-au luat soldurile din rulaje
	if (@tipint in ('2','3','4'))
		insert into @pp(suma,data,locmunca, tipCont, tipSuma, cont)
			select sum(isnull(suma,0)) as suma,data, --p.loc_de_munca
				isnull(left((case when p.Loc_de_munca='' then @lminch else p.Loc_de_munca end)
					,(select Max(len(t.lm)) from @tlm t where p.Loc_de_munca like t.lm+'%' or p.Loc_de_munca='' and lm=@lminch)),@lminch) AS locmunca,c.tip,
				2, c.cont
			from pozincon p, @conturi2 c  
			where (rtrim(cont_debitor)=c.cont) and
					(valuta=@valuta or @valuta is null) 
				and p.subunitate=@subunitate
					and data>=@dataan
					and (@filtruLM=0 or exists(select 1 from @tlm where p.Loc_de_munca like lm+'%' or p.Loc_de_munca='' and lm=@lminch))
					and @debit_credit in (-1,1)
			group by data, p.Loc_de_munca, c.tip, c.cont
		union all  
			select -sum(isnull(suma,0)) as suma,data, --p.Loc_de_munca 
				isnull(left((case when p.Loc_de_munca='' then @lminch else p.Loc_de_munca end)
					,(select Max(len(t.lm)) from @tlm t where p.Loc_de_munca like t.lm+'%' or p.Loc_de_munca='' and lm=@lminch)),@lminch) AS locmunca,c.tip,
				3, c.cont
			from pozincon p,@conturi2 c  
			where (rtrim(cont_creditor)=c.cont) and (valuta=@valuta or @valuta is null) and
					p.subunitate=@subunitate
					and data>=@dataan
					and (@filtruLM=0 or exists(select 1 from @tlm where p.Loc_de_munca like lm+'%' or p.Loc_de_munca='' and lm=@lminch))
					and @debit_credit in (-1,0)
			group by data, p.Loc_de_munca,c.tip, c.cont
			--> s-au completat soldurile initiale luate din rulaje cu sumele din pozincon*/

	insert into @pp(suma,data,locmunca, tipCont, tipSuma, cont)
	select 0, r.dataInterval, p.locmunca, p.tipCont, p.tipSuma, cont
		from @r r, (select distinct p.locmunca, p.tipCont, p.tipSuma, p.cont from @pp p) p
			
	declare @rezTipuri table (
		debit decimal(20,3), credit decimal(20,3),
		data DATETIME, LOCMUNCA VARCHAR(20), cont varchar(20), tipcont varchar(1))
if (@rulaj_sold=1)	--> rulaje:
	begin
		IF (@rulajelm=1)
			insert into @rezTipuri (data,
				debit, credit, LOCMUNCA, cont,tipcont)
			SELECT r.dataInterval,
					(case when p.tipCont='A' then sum(p.suma) when p.tipCont='P' then 0 when sum(p.suma)>0 then sum(p.suma) else 0 end) debit,
					(case when p.tipCont='A' then 0 when p.tipCont='P' then -sum(p.suma) when sum(p.suma)<0 then -sum(p.suma) else 0 end) credit,
					p.locmunca, p.cont, p.tipcont
					FROM @pp p inner join @r r on p.data=r.data 
					where p.tipSuma>1 and @tipint<>'1' or @tipint='1' and day(r.data)<>1
					GROUP BY r.dataInterval, p.locmunca, p.tipCont, p.cont
		else
			insert into @rezTipuri (data,debit, credit, LOCMUNCA, cont, tipcont)
			SELECT r.dataInterval,
					(case when p.tipCont='A' then sum(p.suma) when p.tipCont='P' then 0 when sum(p.suma)>0 then sum(p.suma) else 0 end) debit,
					(case when p.tipCont='A' then 0 when p.tipCont='P' then -sum(p.suma) when sum(p.suma)<0 then -sum(p.suma) else 0 end) credit,
				'' locmunca, p.cont, p.tipcont
				FROM @pp p inner join @r r on p.data=r.data
				where p.tipSuma>1 and @tipint<>'1' or @tipint='1' and day(r.data)<>1
				GROUP BY r.dataInterval, p.tipCont, p.cont

		if (@cumulat=1)	--> calcul rulaj cumulat
			update p set p.debit=ps.debit, p.credit=ps.credit
			from @rezTipuri p inner join (select sum(p.debit) debit, sum(p.credit) credit, ps.cont, ps.data, ps.locmunca
				from @rezTipuri p inner join @rezTipuri ps on p.locmunca=ps.locmunca and p.cont=ps.cont and p.data<=ps.data and year(p.data)=year(ps.data)
					and (day(p.data)>1 or month(p.data)>1) group by ps.cont, ps.data, ps.locmunca) ps 
						on p.locmunca=ps.locmunca and p.cont=ps.Cont and p.data=ps.data
	end
else				--> solduri:
	begin
		IF (@rulajelm=1)
			INSERT INTO @rezTipuri (data, debit, credit, LOCMUNCA, cont, tipcont)
			SELECT r.data,
					(case when p.tipCont='A' then sum(p.suma) when p.tipCont='P' then 0 when sum(p.suma)>0 then sum(p.suma) else 0 end) debit,
					(case when p.tipCont='A' then 0 when p.tipCont='P' then -sum(p.suma) when sum(p.suma)<0 then -sum(p.suma) else 0 end) credit,
				p.locmunca, p.cont, p.tipCont
				FROM @r r INNER JOIN @pp p ON p.data<=r.data and year(p.data)=year(r.data)
						and (p.tipSuma=1 and (@tipint='1' or p.data<>r.data or day(p.data)=1) or 
							month(r.data)=month(p.data) and p.tipSuma>1)
				GROUP BY r.data, p.locmunca, p.tipCont, p.cont
		else 
			INSERT INTO @rezTipuri (data,debit, credit,LOCMUNCA, cont, tipcont)
			SELECT r.data,
					(case when p.tipCont='A' then sum(p.suma) when p.tipCont='P' then 0 when sum(p.suma)>0 then sum(p.suma) else 0 end) debit,
					(case when p.tipCont='A' then 0 when p.tipCont='P' then -sum(p.suma) when sum(p.suma)<0 then -sum(p.suma) else 0 end) credit,
				'' locmunca, p.cont, p.tipcont
				FROM @r r INNER JOIN @pp p ON p.data<=r.data and year(p.data)=year(r.data)
						and (p.tipSuma=1 and (@tipint='1' or p.data<>r.data or day(p.data)=1) or 
						month(r.data)=month(p.data) and p.tipSuma>1)
				GROUP BY r.data, p.tipCont, p.cont
		
		declare @datamax datetime	--> data maxima la care se gasesc sume in datele brute
		set @datamax=(select max(data) from @rezTipuri)
--/*		--> completare cu solduri pe zilele care nu au date
		insert into @rezTipuri(data,debit,credit,LOCMUNCA, cont,tipcont)
		select r.data, max(p.debit), max(p.credit), p.locmunca, p.cont,p.tipcont from @r r, @rezTipuri p where r.data>@datamax and p.data=@datamax
		group by r.data, p.locmunca, p.cont, p.tipcont
		
		/*	?	--> s-ar parea ca aici se completa daca nu existau date pe unele locuri de munca - costisitor; daca apar probleme ne mai gandim:
		insert into @rezTipuri(data,suma,LOCMUNCA, tipCont)
		select r.data, max(p.suma), p.locmunca, p.tipCont from @r r , @rezTipuri p where r.data>p.data and p.tipCont=p.tipCont
			and not exists (select 1 from @rezTipuri re where re.data=r.data and re.LOCMUNCA=p.LOCMUNCA and re.tipCont=p.tipCont)	--> verificare pt a nu insera daca exista deja linia aferenta datei
			and not exists (select 1 from @rezTipuri re where re.data<r.data and re.LOCMUNCA=p.LOCMUNCA and re.tipCont=p.tipCont and re.data>p.data)
		group by r.data, p.LOCMUNCA, p.tipCont--*/
		
	end
	
	insert into @rez(data,suma,LOCMUNCA)
		select data,
				convert(decimal(20,3),(case when @debit_credit=-1 or @rulaj_sold=1 then (case when @debit_credit in (1,-1) then 1 else -1 end)*isnull(sum(p.debit-p.credit),0)
						--when @debit_credit=1 then sum(debit) else sum(credit)
			--> s-a facut sa aduca rulaj debit si credit cu semn alternativ pentru conturi
			-->	bifunctionale ca sa functioneze ca si vechea metoda de calcul indicatori.
						when @debit_credit=1 and max(p.tipcont)<>'B' then sum(debit)
						when @debit_credit=0 and max(p.tipcont)<>'B' then sum(credit)
						else sum(debit-credit)
						end))
			,LOCMUNCA
		from @rezTipuri p where data between @datajos and @datasus
		group by data,LOCMUNCA
	return
end
