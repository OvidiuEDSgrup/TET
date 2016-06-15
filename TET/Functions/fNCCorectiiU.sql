--***
/**	functie pentru generare NC aferenta sumelor operate pe corectia U */
Create function fNCCorectiiU 
	(@dataJos datetime, @dataSus datetime, @pMarca char(6)) 
returns @dateNCCorU table
	(Data datetime, Marca char(6), Loc_de_munca char(9), Comanda char(20), Valoare decimal(10,2))
as
begin
	declare @userASiS char(10), @Data datetime, @Marca char(6), @Lm char(9), @Valoare float, @ValoareCom float, @ValoareDif float, 
		@rMarca char(6), @rCantitate float, @rlm char(9), @rcomanda char(20), @rSuma float, @TOreRLM float, 
		@gComanda char(20), @gLm char(9), @NCCorUComenzi int

	set @userASiS=dbo.fIaUtilizator(null)
	set @NCCorUComenzi=dbo.iauParL('PS','N-C-CUCOM')

	declare cCorectiiU cursor for
	select max(a.data) as Data, max(a.marca), a.Loc_de_munca as Loc_de_munca, 
		round(round(sum(a.Suma_corectie),2),10,2) as Valoare, isnull(max(r1.Cantitate),0) as CantitateM
	from fSumeCorectie (@dataJos, @dataSus, 'U-', '', '', 1) a 
		left outer join (select Marca, Loc_de_munca, sum(Cantitate) as Cantitate from realcom r where data between @dataJos and @dataSus
			group by Marca, Loc_de_munca) r1 on r1.Marca=a.Marca and r1.Loc_de_munca=a.Loc_de_munca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=a.Loc_de_munca
	where (@pMarca='' or a.Marca=@pMarca) 
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	group by a.Loc_de_munca, (case when @NCCorUComenzi=1 then a.Marca else '' end)
	order by a.Loc_de_munca, (case when @NCCorUComenzi=1 then a.Marca else '' end)

	open cCorectiiU
	fetch next from cCorectiiU into @Data, @Marca, @Lm, @Valoare, @TOreRLM
	While @@fetch_status = 0 
	Begin
		if @TOreRLM<>0 and @NCCorUComenzi=1
		Begin
			Declare cursor_realcom cursor For
			select r.Marca, r.Loc_de_munca, r.Comanda, sum(Cantitate) from realcom r
			where r.Data between @dataJos and @dataSus and r.Marca=@Marca and r.Loc_de_munca=@Lm and r.Cantitate<>0 
			group by r.Loc_de_munca, r.Marca, r.Comanda
			order by r.Loc_de_munca, r.Marca, r.Comanda

			open cursor_realcom
			fetch next from cursor_realcom Into @rMarca, @rLm, @rComanda, @rCantitate
			set @gComanda=@rComanda
			set @gLm=@Lm
			set @ValoareDif=@Valoare
			while @rMarca=@Marca and @rLm=@Lm and @@fetch_status=0 
			Begin 
				set @gComanda=@rComanda
				set @gLm=@Lm
				set @ValoareCom=round(@Valoare*@rCantitate/@TOreRLM,2)
				set @ValoareDif=@ValoareDif-@ValoareCom
				insert @dateNCCorU
				select @Data, @Marca, @rLm, @rComanda, @ValoareCom
				Fetch next from cursor_realcom Into @rMarca, @rLm, @rComanda, @rCantitate
			End
			set @ValoareDif=round(@ValoareDif,2)
			if @ValoareDif<>0
			Begin
				update @dateNCCorU set Valoare=Valoare+@ValoareDif where Data=@Data and Marca=@Marca 
				and Loc_de_munca=@gLm and Comanda=@gComanda 
			End
			Close cursor_realcom
			Deallocate cursor_realcom
		End
		else
		Begin
			insert @dateNCCorU
			select @Data, @Marca, @Lm, '', @Valoare
		End
		fetch next from cCorectiiU into @Data, @Marca, @Lm, @Valoare, @TOreRLM
	End
	Close cCorectiiU
	Deallocate cCorectiiU
	return
end
