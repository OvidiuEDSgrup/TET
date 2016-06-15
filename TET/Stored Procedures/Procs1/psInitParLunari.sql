--***
/**	procedura initializare parametrii lunari cu parametrii legislativi sau cu parametrii din luna anterioara **/
Create procedure psInitParLunari
	@dataJos datetime, @dataSus datetime, @deLaInchidere int
As
Begin
	declare @utilizator varchar(20), @lm varchar(9), @multiFirma int, @GestionareTichete int, 
		@dataSusAnt datetime, @nLunaInch int, @nAnulInch int, @dDataInch datetime,
		@DataPar datetime, @Val_logica int, @Val_numerica float, @DataTicheteJ datetime, @DataTicheteS datetime
 
 	set @utilizator = dbo.fIaUtilizator(null)
	select @multiFirma=0, @lm=''
	if exists (select * from sysobjects where name ='par_lunari' and xtype='V')
		set @multiFirma=1

	set @GestionareTichete=dbo.iauParL('PS','TICHETE')
	set @dataSusAnt=dbo.eom(DateAdd(month,-1,@dataSus))
	set @nLunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @nAnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	if @nLunaInch not between 1 and 12 or @nAnulInch<=1901
		return
	set @dDataInch=dateadd(month,1,convert(datetime,str(@nLunaInch,2)+'/01/'+str(@nAnulInch,4)))

	if @dataSus>@dDataInch
	Begin
--	sterg pozitiile existente daca procedura se apeleaza de la inchiderea de luna
--	sau daca exista pe aceasta data pozitie cu parametru legislativ
		declare @par_lunari varchar(max), @par_lunari_st varchar(max), @par_legis varchar(max), @comandaSql nvarchar(max)
		set @par_lunari='SALMBRUT,CASGRUPA1,CASGRUPA2,CASGRUPA3,CASINDIV,SOMAJIND,CASSIND,SOMAJ-ISR,S-MIN-BR,0.5%ACCM,3.5%SOMAJ,CASSUNIT,COTACCI,FONDGAR,VALTICHET,STOUG28'
		set @par_lunari_st=(case when @multiFirma=1 then 'ORE_LUNA,NRMEDOL,NRTICHETE' else '' end)
		set @par_legis='SALMBRUT,CASGRUPA1,CASGRUPA2,CASGRUPA3,CASINDIV,SOMAJIND,CASSIND,SOMAJ-ISR,S-MIN-BR,3.5%SOMAJ,CASSUNIT,COTACCI,FONDGAR'+(case when @multiFirma=1 then '' else ',0.5%ACCM' end)
	
		if @multiFirma=1
			select @lm=isnull(min(Cod),'') from LMfiltrare where utilizator=@utilizator and cod in (select cod from lm where Nivel=1)

--	creez tabela temporara in care voi insera parametrii lunari de preluat/initializat
--	la final voi face scrierea in par_lunari/par_lunari_lm; sa nu fac la fiecare insert in parte
		if object_id('tempdb..#par_lunari') is not null drop table #par_lunari
		create table #par_lunari (Data datetime, Tip varchar(2), Parametru varchar(9), 
			Denumire_parametru varchar(30), Val_logica bit, Val_numerica float, Val_alfanumerica varchar(200), Val_data datetime)

		SET @comandaSql = N'
			delete p from '+(case when @multiFirma=1 then 'par_lunari_lm' else 'par_lunari' end)+' p 
			where '+(case when @multiFirma=1 then 'loc_de_munca=@lm and' else '' end)+' p.Data=@dataSus and p.tip=''PS'' 
				and (charindex(rtrim(p.Parametru),@par_lunari)<>0 or charindex(rtrim(p.Parametru),@par_lunari_st)<>0 or p.Parametru like ''%IMPZTIC%'')
				and (@deLaInchidere=1 or exists (select Data from par_lunari p1 where p1.Data=@dataSus and p1.tip=''PL'' and p1.Parametru=p.Parametru))'
		
		exec sp_executesql @statement=@comandaSql, @params=N'@dataSus datetime, @par_lunari varchar(max), @par_lunari_st varchar(max), @deLaInchidere int, @lm varchar(9)', 
			@dataSus=@dataSus, @par_lunari=@par_lunari, @par_lunari_st=@par_lunari_st, @deLaInchidere=@deLaInchidere, @lm=@lm
	
--	preluare parametrii lunari fie din parametrii legislativi fie din parametrii lunari anteriori
		insert into #par_lunari (Data, Tip, Parametru, Denumire_parametru, Val_logica, Val_numerica, Val_alfanumerica, Val_data)
		select @dataSus, 'PS', p.Parametru, p.Denumire_parametru, p.Val_logica, p.Val_numerica, p.Val_alfanumerica, p.Val_data 
		from par_lunari p
		where Data=(case when exists (select Data from par_lunari pl1 where pl1.Data=@dataSus and pl1.tip='PL' and pl1.Parametru=p.Parametru) then @dataSus
				else isnull((select top 1 Data from par_lunari p1 where p1.Data<@dataSus and p1.tip='PS' and p1.Parametru=p.Parametru order by Data desc),
				isnull((select top 1 Data from par_lunari pl2 where pl2.Data<@dataSus and pl2.tip='PL' and pl2.Parametru=p.Parametru order by Data desc),@dataSusAnt)) end)
			and tip=(case when exists (select Data from par_lunari pl1 where pl1.Data=@dataSus and pl1.tip='PL' and pl1.Parametru=p.Parametru) 
					or exists (select Data from par_lunari p1 
						where p1.Data=isnull((select top 1 Data from par_lunari p2 where p2.Data<@dataSus and p2.tip='PS' and p2.Parametru=p.Parametru order by Data desc),
						isnull((select top 1 Data from par_lunari pl2 where pl2.Data<@dataSus and pl2.tip='PL' and pl2.Parametru=p.Parametru order by Data desc),@dataSusAnt)) 
						and p1.tip='PL' and p1.Parametru=p.Parametru) 
				then 'PL' else 'PS' end) 
			and charindex(rtrim(p.Parametru),@par_lunari)<>0
			and (@multiFirma=1 or not exists (select Data from par_lunari p1 where p1.Data=@dataSus and p1.tip='PS' and p1.Parametru=p.Parametru))

--	inserare parametru pt. ore lucratoare luna
		delete from par_lunari where @deLaInchidere=1 and Tip='PS' and Parametru='ORE_LUNA' and data=@dataSus
		insert into #par_lunari (Data, Tip, Parametru, Denumire_parametru, Val_logica, Val_numerica, Val_alfanumerica, Val_data)
		select @dataSus,'PS','ORE_LUNA','Ore lucratoare in luna',1,dbo.zile_lucratoare(@dataJos,@dataSus)*8,'Ore lucratoare in luna de lucru','01/01/1901'
		where (@multiFirma=1 or not exists (select Val_numerica from par_lunari where data=@dataSus and tip='PS' and parametru='ORE_LUNA'))

--	inserare parametru pt. numar tichete de masa 
--	daca numar tichete luna anterioara=zile lucratoare atunci numar tichete luna crt=zile lucratoare luna
--	altfel inserez numar tichete luna curenta=numar tichete luna anterioara
		if @GestionareTichete=1
		Begin
			select top 1 Data, Val_numerica into #nrtichete
			from par_lunari where Data<@dataSus and tip='PS' and Parametru='NRTICHETE' order by Data desc
			select @DataPar=Data, @Val_numerica=Val_numerica from #nrtichete
			insert into #par_lunari (Data, Tip, Parametru, Denumire_parametru, Val_logica, Val_numerica, Val_alfanumerica, Val_data)
			select @dataSus, 'PS', 'NRTICHETE', 'Nr. de tichete pe luna', 1, 
				(case when @Val_numerica is not null and @Val_numerica<>dbo.zile_lucratoare(dbo.bom(@DataPar),@DataPar) 
				then @Val_numerica else dbo.zile_lucratoare(@dataJos,@dataSus) end), '', '01/01/1901'
			where (@multiFirma=1 or not exists (select Data from par_lunari p1 where p1.Data=@dataSus and p1.tip='PS' and p1.Parametru='NRTICHETE'))

--	preiau perioada de impozitare a tichetelor
			select top 1 p.Data, p.Val_logica, p.Val_data as Val_DataJ, p1.Val_data as Val_dataS 
			into #datatichete
			from par_lunari p
				left outer join par_lunari p1 on p.Data=p1.Data and p.Tip=p1.Tip and p1.Parametru='DJIMPZTIC'
			where p.Data<@dataSus and p.tip='PS' and p.Parametru='DJIMPZTIC' order by p.Data desc
			select @DataPar=Data, @Val_logica=Val_logica, @DataTicheteJ=Val_DataJ, @DataTicheteS=Val_dataS from #datatichete

--	studiez modul de impozitare al tichetelor pe luna anterioara. Functie de regula gasita completez perioada de impozitare pe luna curenta.
			insert into #par_lunari (Data, Tip, Parametru, Denumire_parametru, Val_logica, Val_numerica, Val_alfanumerica, Val_data)
			select @dataSus, 'PS', 'DJIMPZTIC', 'Data jos impozit tichete', isnull(@Val_logica,0), 0, '', 
				(case when isnull(@DataTicheteJ,'01/01/1901')<>'01/01/1901' then DateAdd(MONTH,-DATEDIFF(month,@DataTicheteJ,dbo.bom(@DataPar)),@dataJos) else @dataJos end)
			where (@multiFirma=1 or not exists (select Data from par_lunari p1 where p1.Data=@dataSus and p1.tip='PS' and p1.Parametru='DJIMPZTIC'))

			insert into #par_lunari (Data, Tip, Parametru, Denumire_parametru, Val_logica, Val_numerica, Val_alfanumerica, Val_data)
			select @dataSus, 'PS', 'DSIMPZTIC', 'Data sus impozit tichete', 1, 0, '', 
				(case when isnull(@DataTicheteS,'01/01/1901')<>'01/01/1901' then DateAdd(MONTH,-DATEDIFF(month,@DataTicheteS,@DataPar),@dataSus) else @dataSus end)
			where (@multiFirma=1 or not exists (select Data from par_lunari p1 where p1.Data=@dataSus and p1.tip='PS' and p1.Parametru='DSIMPZTIC'))

		End

--	inserare parametru pt. numar mediu ore lucratoare luna
--	daca numar mediu ore luna anterioara=zile lucratoare atunci numar mediu ore luna crt=zile lucratoare luna curenta
--	altfel inserez numar mediu ore luna curenta=numar mediu ore luna anterioara
		select top 1 Data, Val_numerica into #nrmediu
		from par_lunari where Data<@dataSus and tip='PS' and Parametru='NRMEDOL' order by Data desc
		select @DataPar=Data, @Val_numerica=Val_numerica from #nrmediu
		insert into #par_lunari (Data, Tip, Parametru, Denumire_parametru, Val_logica, Val_numerica, Val_alfanumerica, Val_data)
		select @dataSus, 'PS', 'NRMEDOL', 'Numar mediu ore lucratoare', 1, 
		(case when @Val_numerica is not null and @Val_numerica<>dbo.zile_lucratoare(dbo.bom(@DataPar),@DataPar)*8 
		then @Val_numerica else dbo.zile_lucratoare(@dataJos,@dataSus)*8 end), '', '01/01/1901'
		where (@multiFirma=1 or not exists (select Data from par_lunari p1 where p1.Data=@dataSus and p1.tip='PS' and p1.Parametru='NRMEDOL'))

		SET @comandaSql = N'
			insert into '+(case when @multiFirma=1 then 'par_lunari_lm' else 'par_lunari' end)
				+' ('+(case when @multiFirma=1 then 'Loc_de_munca, ' else '' end)+'Data, Tip, Parametru, Denumire_parametru, Val_logica, Val_numerica, Val_alfanumerica, Val_data)
			select '+(case when @multiFirma=1 then '(case when charindex(p.parametru,@par_legis)<>0 then '''' else @lm end)'+', ' else '' end)
				+'Data, Tip, Parametru, Denumire_parametru, Val_logica, Val_numerica, Val_alfanumerica, Val_data 
			from #par_lunari p
			where not exists (select 1 from '+(case when @multiFirma=1 then 'par_lunari_lm' else 'par_lunari' end)+' p1 where '
				+(case when @multiFirma=1 then 'p1.loc_de_munca=(case when charindex(p.parametru,@par_legis)<>0 then '''' else @lm end) and ' else '' end)+
				' p1.Data=p.Data and p1.tip=p.tip and p1.Parametru=p.Parametru)'

		exec sp_executesql @statement=@comandaSql, @params=N'@lm varchar(9), @par_legis varchar(max)', @lm=@lm, @par_legis=@par_legis
	End
End

/*
	exec psInitParLunari '12/01/2013', '12/31/2013', 1
*/
