--***
/**	procedura generare concedii (CFS, nemotivate, invoiri, concedii de odihna) pornind de la datele preluate din fisierul excel de pontaj */
Create procedure GenerareConcediiDinPontajZilnic
	@dataJos datetime, @dataSus datetime, @pMarca char(6)=null, @pLocm char(9)=null, @stergere int=0, @generare int=1, @sesiune varchar(20)=null, @parXML xml=null  
As  
Begin try  
	declare @userASiS char(10), @Data_operarii datetime, @Ora_operarii char(6), @nData_op float, @legenda varchar(100), @lm varchar(9)  
   
	set @userASiS=dbo.fIaUtilizator(@sesiune)  
	set @lm=''  
	select @lm=isnull(min(Cod),'') from LMfiltrare where utilizator=@userASiS and cod in (select cod from lm where Nivel=1)  
  
	set @Data_operarii = convert(datetime, convert(char(10), getdate(), 104), 104)   
	set @Ora_operarii = replace(convert(char(8), getdate(), 114),':','')  
	Set @nData_op=datediff(day,convert(datetime,'01/01/1901'),@Data_operarii)+693961   
   
	set @legenda=',NE,'  --CO,FS,IN,LP, O=odihna,F=CFS,I=Invoit,N=Nemotivat,P-Liber platit. Pentru inceput tratam doar orele nemotivate.
  
	-- pun intr-o tabela temporara suspendarile in vigoare in luna de lucru  
	if object_id('tempdb..#concediiPontaj') is not null drop table #concediiPontaj
	if object_id('tempdb..#concediiPontaj1') is not null drop table #concediiPontaj1
	if object_id('tempdb..#prelco') is not null drop table #prelco
    
	create table #prelco (marca varchar(6), valoare varchar(10), ore int, camp varchar(10), ziua datetime, data_inceput datetime, data_sfarsit datetime)  
	insert into #prelco  
	select marca, tip_ore, ore, convert(varchar(10),'') as camp, data, '01/01/1901', '01/01/1901'  
	from #pontaj_zilnic
	where charindex(','+rtrim(upper(tip_ore))+',',@legenda)<>0

	update #prelco set camp='ziua'+convert(varchar(2),day(ziua))

	delete from #prelco where day(ziua)>DAY(@datasus)  
	update #prelco set valoare=REPLACE(valoare,'��','')  
  
	select (case when upper(p1.valoare) in ('CO') then 'concodih' else 'conalte' end) as tabela,   
	(case when upper(p1.valoare) in ('CO','FS') then '1' --when upper(p1.valoare)='P' then 'E'   
		when upper(p1.valoare) in ('NE') then '2' when upper(p1.valoare)='IN' then '3' else '' end) as tip_concediu,   
		p1.marca, p1.valoare, p1.camp, p1.ziua as Data_inceput, isnull(p4.ziua,99) as Data_sfarsit   
	into #concediiPontaj  
	from #prelco p1  
		left outer join #prelco p2 on p2.marca=p1.marca and p2.valoare=p1.valoare and p2.ziua=p1.ziua-1  
		outer apply (select top 1 p3.ziua from #prelco p3 where p3.marca=p1.marca and p3.valoare=p1.valoare and p3.ziua>=p1.ziua  
			and not exists (select 1 from #prelco p5 where p5.marca=p1.marca and p5.ziua between p1.ziua and p3.ziua and p5.valoare<>p1.valoare and p5.valoare<>'\')   
	order by p3.ziua desc) p4  
	where p2.ziua is null
  
	select tabela, tip_concediu, marca, valoare, MIN(camp) as camp, MIN(Data_inceput) as data_inceput, data_sfarsit  
	into #concediiPontaj1  
	from #concediiPontaj  
	group by tabela, tip_concediu, marca, valoare, data_sfarsit  
   
	delete from #concediiPontaj  
	insert into #concediiPontaj select * from #concediiPontaj1  
  
	-- citesc suspendarile pentru a nu prelua din #concediiPontaj acele pozitii pt. care exista deja suspendari  
	if object_id('tempdb..#suspendari') is not null drop table #suspendari  
	select s.Data, s.Marca,   
		(case when s.Data_inceput<@datajos then @dataJos else s.Data_inceput end) as Data_inceput,   
		(case when (case when s.Data_incetare<>'01/01/1901' then s.Data_incetare else s.Data_sfarsit end)>@datasus   
		then @dataSus else (case when s.Data_incetare<>'01/01/1901' then DateADD(day,-1,s.Data_incetare) else s.Data_sfarsit end) end) as Data_sfarsit, p.Data_plec,   
		'1' as Tip_concediu  
	into #suspendari  
	from fRevisalSuspendari (@dataJos, @dataSus, isnull(@pMarca,'')) s   
		left outer join personal p on p.Marca=s.Marca  
	where (isnull(@pLocm,'')='' or p.Loc_de_munca like rtrim(@pLocm)+'%') and s.Temei_legal='Art54'  
  
	update #suspendari set Data_sfarsit=(case when Data_plec>=Data_inceput and Data_plec<Data_sfarsit then DateADD(day,-1,Data_plec) else Data_sfarsit end)   
  
	--Tratat sa nu preia concediile fara salar (acestea se vor opera prin suspendari si vor iesi ca diferenta intre conalte si pontaj pe Validari).
	delete c  
	from #concediiPontaj c  
	where tabela='conalte' and c.tip_concediu='1'  
  
	-- sterg datele generate anterior  
	delete ca  
	from conalte ca  
		left outer join personal p on p.Marca=ca.Marca  
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=p.Loc_de_munca  
	where @stergere=1 and ca.Data=@dataSus and ca.Data=dbo.EOM(Data) and ca.Introd_manual=1 and not (ca.Data_sfarsit>@dataSus)  
		and ca.Tip_concediu in ('2','3')
		and (isnull(@pMarca,'')='' or ca.marca=@pMarca)   
		and (isnull(@pLocm,'')='' or ca.Marca in (select Marca from personal where Loc_de_munca like rtrim(@pLocm)+'%'))  
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)  
		--and ca.Marca in (select Marca from #concediiPontaj)  
  
	-- generez concedii\alte  
	insert into conalte (Data, Marca, Tip_concediu, Data_inceput, Data_sfarsit, Zile, Introd_manual, Indemnizatie, Utilizator, Data_operarii, Ora_operarii)  
	Select @dataSus, co.Marca, co.Tip_concediu, co.Data_inceput, co.Data_sfarsit, dbo.zile_lucratoare(co.Data_inceput, co.Data_sfarsit),   
	1, 0, @userASiS, @Data_operarii, @Ora_operarii  
	from #concediiPontaj co  
		left outer join personal p on co.marca=p.marca   
	where @generare=1  and tabela='conalte' and Tip_concediu in ('2','3')	
		and not exists (select 1 from conalte c where c.data=@dataSus and c.Marca=co.Marca and c.Data_inceput=co.Data_inceput and c.Tip_concediu=co.Tip_concediu)  
End try  
  
Begin catch  
	declare @eroare varchar(2000)  
	set @eroare='Procedura GenerareConcediiDinPontajZilnic (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())  
	raiserror(@eroare,16,1)  
End catch
