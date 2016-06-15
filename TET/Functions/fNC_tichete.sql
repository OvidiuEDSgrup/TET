--***
/**	functie NC tichete	*/
Create function fNC_tichete 
	(@dataJos datetime, @dataSus datetime, @pMarca char(6), @DeLaCalculLichidare int) 
returns @dateNCtichete table
	(Data datetime, Marca char(6), Loc_de_munca char(9), Comanda char(20), Tip_tichete char(1), Numar_tichete decimal(10,2), Valoare_tichete decimal(10,2), Ordonare char(50))
as
/*
	@DeLaCalculLichidare 
		-> 0 din alte locuri decat in afara de calcul lichidare (grupare pe locuri de munca).
		-> 1 de la calcul lichidare (grupare pe marca).
		-> 2 de la generare nota contabila tichete (grupare pe marca si loc de munca, sa se poata in procedura de generare sa se completeze contul debitor functie de activitate).
*/
begin
	declare @userASiS char(10), @lista_lm int, @multiFirma int, @Data datetime, @Marca char(6), @Lm char(9), @Comanda char(20), 
	@TipTichete char(1), @NumarTichete float, @ValoareTichete float, @NumarTicheteCom float, @ValoareTicheteCom float, @NumarTicheteDif float, @ValoareTicheteDif float, 
	@Ordonare char(50), @OrdonareLm char(50), @rmarca char(6), @rlm char(9),@rcomanda char(20), @TVenitR_LM float, @gcomanda char(20), @gLm char(9), @rSuma float, @ValoareTichet decimal(7,2), 
	@SalComenzi int, @TicheteMacheta int, @TichetePersonalizate int, @NCTichete int, @cTabela char(2), @TipDocument char(2), @NCTichComenzi int, @ParcurgTichete int, @Remarul int

	set @userASiS=dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@userASiS)
	set @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	set @ValoareTichet=dbo.iauParLN(@dataSus,'PS','VALTICHET')
	set @SalComenzi=dbo.iauParL('PS','SALCOM')
	set @TicheteMacheta=dbo.iauParL('PS','OPTICHINM')
	set @TichetePersonalizate=dbo.iauParL('PS','TICHPERS')
	set @NCTichete=dbo.iauParL('PS','NC-TICHM')
	set @cTabela=(case when len(rtrim(convert(char(2),dbo.iauParN('PS','NC-TICHM'))))>1 then right(rtrim(convert(char(2),dbo.iauParN('PS','NC-TICHM'))),1) else '1' end)
	set @TipDocument=(case when len(rtrim(convert(char(2),dbo.iauParN('PS','NC-TICHM'))))>1 then left(convert(char(2),dbo.iauParN('PS','NC-TICHM')),1) else '2' end) 
	set @NCTichComenzi=dbo.iauParL('PS','NC-TICCOM')
	set @ParcurgTichete=(case when @TicheteMacheta=1 and @cTabela='' or @cTabela='2' then 1 else 0 end)
	set @Remarul=dbo.iauParL('SP','REMARUL')

	declare ctichete cursor for
	select max(dbo.eom(a.data)) as data, max(a.marca), (case when @DeLaCalculLichidare in (0,2) then a.Loc_de_munca else '' end) as loc_de_munca, 
	(case when @SalComenzi=1 and @DeLaCalculLichidare in (0,2) then isnull(r.Comanda,'') else '' end) as comanda, 
	'C' as Tip_tichete, round(sum(a.ore__cond_6),(case when @DeLaCalculLichidare=1 then 0 else 2 end)) as numar_tichete, 
	round(round(sum(a.ore__cond_6),(case when @DeLaCalculLichidare=1 then 0 else 2 end))*@ValoareTichet,10,2) as valoare_tichete, 
	isnull(max(r1.Realizat),0) as Realizat, (case when @SalComenzi=1 or @NCTichComenzi=1 then max(a.marca) else '' end) as ordonare,  
	(case when @DeLaCalculLichidare in (0,2) then a.Loc_de_munca else '' end) as ordonare_lm 
	from pontaj a 
		left outer join infopers i on a.marca=i.marca
		left outer join realcom r on @SalComenzi=1 and r.data=a.data and r.marca=a.marca and substring(r.numar_document,3,10)=convert(char(10),numar_curent) 
		left outer join (select marca, loc_de_munca, sum(cantitate*tarif_unitar) as Realizat from realcom r where data between @dataJos and @dataSus
			group by marca, loc_de_munca) r1 on r1.marca=a.marca and r1.loc_de_munca=a.loc_de_munca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=a.Loc_de_munca
	where @ParcurgTichete=0 and a.data between @dataJos and @dataSus and (isnull(@pMarca,'')='' or a.Marca=@pMarca)
		and (dbo.f_areLMFiltru(@userASiS)=0 or @DeLaCalculLichidare=1 and @multiFirma=0 or lu.cod is not null)
	group by (case when @DeLaCalculLichidare in (0,2) then a.Loc_de_munca else '' end), 
		(case when @DeLaCalculLichidare in (1,2) or @SalComenzi=1 or @NCTichComenzi=1 then a.marca else '' end), 
		(case when @SalComenzi=1 and @DeLaCalculLichidare in (0,2) then isnull(r.Comanda,'') else '' end) 
	union all 
	select max(a.data_lunii) as data, max(a.marca), (case when @DeLaCalculLichidare in (0,2) then isnull(i.Loc_de_munca,p.Loc_de_munca) else '' end), 
	(case when @SalComenzi=1 then max(ip.centru_de_cost_exceptie) else '' end) as comanda, 
	(case when @DeLaCalculLichidare=1 then '' when a.Tip_operatie='S' then 'S' else 'C' end) as Tip_tichete,  
	sum((case when a.tip_operatie='R' then -1 else 1 end)*a.nr_tichete) as numar_tichete, 
	sum((case when a.tip_operatie='R' then -1 else 1 end)*a.nr_tichete*a.valoare_tichet) as valoare_tichete, 
	isnull(max(r.Realizat),0) as Realizat, 
	(case when @DeLaCalculLichidare in (1,2) or @SalComenzi=1 or @NCTichComenzi=1 then max(a.marca) else '' end) as ordonare,  
	(case when @DeLaCalculLichidare in (0,2) then isnull(i.Loc_de_munca,p.Loc_de_munca) else '' end) as ordonare_lm 
	from tichete a 
		left outer join personal p on a.marca=p.marca
		left outer join infopers ip on a.marca=ip.marca
		left outer join istpers i on a.marca=i.marca and a.data_lunii=i.data
		left outer join (select marca, sum(cantitate*tarif_unitar) as Realizat from realcom r where data between @dataJos and @dataSus group by marca) r on r.marca=a.marca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=isnull(i.Loc_de_munca,p.Loc_de_munca)
	where @ParcurgTichete=1 and a.data_lunii between @dataJos and @dataSus and (isnull(@pMarca,'')='' or a.Marca=@pMarca) 
		and (@TichetePersonalizate=1 and (tip_operatie in ('C','S','R') or @Remarul=0 and tip_operatie='P')
			or @TichetePersonalizate=0 and (tip_operatie in ('P','S') or @TicheteMacheta=1 and tip_operatie='C' or tip_operatie='R' and valoare_tichet<>0))
		and (dbo.f_areLMFiltru(@userASiS)=0 or @DeLaCalculLichidare=1 and @multiFirma=0 or lu.cod is not null)
	group by (case when @DeLaCalculLichidare in (0,2) then isnull(i.Loc_de_munca,p.Loc_de_munca) else '' end), 
		(case when @DeLaCalculLichidare in (1,2) or @SalComenzi=1 or @NCTichComenzi=1 then a.marca else '' end), 
		(case when @DeLaCalculLichidare=1 then '' when a.Tip_operatie='S' then 'S' else 'C' end) 
	order by ordonare_lm, ordonare

	open ctichete
	fetch next from ctichete into @Data, @Marca, @Lm, @Comanda, @TipTichete, @NumarTichete, @ValoareTichete, @TVenitR_LM, @Ordonare, @OrdonareLm
	While @@fetch_status = 0 
	Begin
		if @DeLaCalculLichidare=0
		Begin
			if @TVenitR_LM<>0 and @NCTichComenzi=1
			Begin
				Declare cursor_realcom cursor For
				select r.marca, r.loc_de_munca, r.comanda, sum((r.cantitate)*r.tarif_unitar) from realcom r
				where r.data between @dataJos and @dataSus and r.marca=@marca 
				and (@ParcurgTichete=1 or @ParcurgTichete=0 and r.Loc_de_munca=@Lm) and r.cantitate<>0 
				group by r.loc_de_munca, r.marca, r.comanda
				order by r.loc_de_munca, r.marca, r.comanda
				open cursor_realcom
				Fetch next from cursor_realcom Into @rmarca, @rlm, @rcomanda, @rSuma
				Set @gcomanda=@rcomanda
				Set @gLm=@Lm
				Set @NumarTicheteDif=@NumarTichete
				Set @ValoareTicheteDif=@ValoareTichete
				while @rmarca=@marca and (@ParcurgTichete=1 or @ParcurgTichete=0 and @rlm=@Lm) and @@fetch_status=0 
				Begin 
					Set @gcomanda=@rcomanda
					Set @gLm=@Lm
					Set @NumarTicheteCom=round(@NumarTichete*@rSuma/@TVenitR_LM,(case when @TipDocument='2' then 3 		else 2 end))
					Set @ValoareTicheteCom=round(@ValoareTichete*@rSuma/@TVenitR_LM,(case when @TipDocument='2' then 3 		else 2 end))
					Set @NumarTicheteDif=@NumarTicheteDif-@NumarTicheteCom
					Set @ValoareTicheteDif=@ValoareTicheteDif-@ValoareTicheteCom
					insert @dateNCtichete
					select @Data,@Marca,@rLm,@rComanda,@TipTichete,@NumarTicheteCom,@ValoareTicheteCom, @Ordonare
					Fetch next from cursor_realcom Into @rmarca, @rlm, @rcomanda, @rSuma
				End
				Set @NumarTicheteDif=round(@NumarTicheteDif,(case when @TipDocument='2' then 3 else 2 end))
				Set @ValoareTicheteDif=round(@ValoareTicheteDif,(case when @TipDocument='2' then 3 else 2 end))
				if @NumarTicheteDif<>0
				Begin
					update @dateNCtichete set Numar_tichete=Numar_Tichete+@NumarTicheteDif, 						Valoare_tichete=Valoare_Tichete+@ValoareTicheteDif where Data=@Data and Marca=@Marca 
					and Loc_de_munca=@gLm and Comanda=@gComanda and Tip_tichete=@TipTichete
				/*		insert @dateNCtichete select @Data,@Marca,@gLm,@gComanda,@TipTichete, @NumarTicheteDif, @ValoareTicheteDif,@Ordonare
*/
			End
			Close cursor_realcom
			Deallocate cursor_realcom
			End
			else
				insert @dateNCtichete
				select @Data,@Marca,@Lm,@Comanda,@TipTichete,@NumarTichete,@ValoareTichete, @Ordonare
		End
		else
			insert @dateNCtichete
			select @Data,@Marca,@Lm,@Comanda,@TipTichete,@NumarTichete,@ValoareTichete, @Ordonare
		fetch next from ctichete into @Data, @Marca, @Lm, @Comanda, @TipTichete, @NumarTichete, @ValoareTichete, @TVenitR_LM, @Ordonare, @OrdonareLm
	End
	close ctichete
	Deallocate ctichete
	return
end
