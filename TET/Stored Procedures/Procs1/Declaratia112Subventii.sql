--***
Create procedure Declaratia112Subventii
	(@dataJos datetime, @dataSus datetime, @lm char(9)='')
as
Begin
--	articolul 80 si 85 fac parte din legea 76/2002
	declare @SomajAngajator decimal(10), @SubventiiArt80 decimal(10), @SubventiiArt85 decimal(10), @SubventiiLegea72 decimal(10), @SubventiiLegea116 decimal(10), 
	@ScutireArt80 decimal(10), @ScutireArt85 decimal(10),
	@SubvArt80Recup decimal(10), @SubvArt80Restit decimal(10), @ScutArt80Recup decimal(10), @ScutArt80Restit decimal(10), 
	@SubvArt85Recup decimal(10), @SubvArt85Restit decimal(10), @ScutArt85Recup decimal(10), @ScutArt85Restit decimal(10), 
	@SubvLegea72Recup decimal(10), @SubvLegea72Restit decimal(10), @ScutireOUG13 decimal(10), 
	@SubvLegea116Recup decimal(10), @SubvLegea116Restit decimal(10)

	select @SomajAngajator=sum(somaj_5) from #net where data=@dataSus
	select @SubventiiArt80=sum((case when p.coef_invalid=2 or p.coef_invalid=3 or p.coef_invalid=4 then n.chelt_prof else 0 end)), 
		@SubventiiArt85=sum((case when p.coef_invalid=1 or p.coef_invalid=9 then n.chelt_prof else 0 end)), 
		@SubventiiLegea72=sum((case when p.coef_invalid=7 then n.chelt_prof else 0 end)),
		@SubventiiLegea116=sum((case when p.coef_invalid=8 then n.chelt_prof else 0 end))
	from #net n
		left outer join personal p on p.Marca=n.Marca
		left outer join istpers i on i.data=n.data and i.marca=n.marca
	where n.data=@dataSus
		and (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')

	select @ScutireArt80=isnull(sum(Scutire_art80),0), @ScutireArt85=isnull(sum(Scutire_art85),0)
	from fScutiriSomaj (@dataJos, @dataSus, '', 'ZZZ', rtrim(@lm), rtrim(@lm)+'ZZZ')
	select @ScutireOUG13=isnull(round(sum(somaj),0),0) from dbo.fPSScutiriOUG13 (@dataJos,@dataSus, 0, '', '', 0)

--	subventii acordate in baza legii 76/2002 articolul 80
	set @SubvArt80Recup=(case when @SubventiiArt80<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 
		then @SubventiiArt80 else (@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 end)
	set @SubvArt80Restit=(case when @SubventiiArt80<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 
		then 0 else @SubventiiArt80-(@SomajAngajator-@ScutireOUG13)+@ScutireArt80+@ScutireArt85 end)
--	subventii acordate in baza legii 76/2002 articolul 85
	set @SubvArt85Recup=(case when @SubventiiArt85>0 
		then (case when @SubventiiArt80+@SubventiiArt85<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 
			then @SubventiiArt85 else (case when @SubventiiArt80<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 
				then (@SomajAngajator-@ScutireOUG13)-@SubventiiArt80-@ScutireArt80-@ScutireArt85 else 0 end) end) 
		else 0 end)
	set @SubvArt85Restit=(case when @SubventiiArt85>0 
		then (case when @SubventiiArt80+@SubventiiArt85<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 then 0 
			else (case when @SubventiiArt80<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 
				then @SubventiiArt80+@SubventiiArt85-(@SomajAngajator-@ScutireOUG13)+@ScutireArt80+@ScutireArt85 else @SubventiiArt85 end) end) 
		else 0 end)
--	subventii acordate in baza legii 116/2002 - tineri marginalizati din centre de plasament
	set @SubvLegea116Recup=(case when @SubventiiLegea116>0 
		then (case when @SubventiiArt80+@SubventiiArt85+@SubventiiLegea116<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 
			then @SubventiiLegea116 else (case when @SubventiiArt80+@SubventiiArt85<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 
			then (@SomajAngajator-@ScutireOUG13)-(@SubventiiArt80+@SubventiiArt85)-@ScutireArt80-@ScutireArt85 else 0 end) end) 
		else 0 end)
	set @SubvLegea116Restit=(case when @SubventiiLegea116>0 
		then (case when @SubventiiArt80+@SubventiiArt85+@SubventiiLegea116<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 then 0 
			else (case when @SubventiiArt80+@SubventiiArt85<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 
				then @SubventiiArt80+@SubventiiArt85+@SubventiiLegea116-(@SomajAngajator-@ScutireOUG13)+@ScutireArt80+@ScutireArt85 else @SubventiiLegea116 end) end) 
		else 0 end)
--	subventii acordate in baza legii 72/2007 articolul 1
	set @SubvLegea72Recup=(case when @SubventiiLegea72>0 
		then (case when @SubventiiArt80+@SubventiiArt85+@SubventiiLegea116+@SubventiiLegea72<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 
			then @SubventiiLegea72 
			else (case when @SubventiiArt80+@SubventiiArt85+@SubventiiLegea116<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 
				then (@SomajAngajator-@ScutireOUG13)-(@SubventiiArt80+@SubventiiArt85+@SubventiiLegea116)-@ScutireArt80-@ScutireArt85 else 0 end) end) 
		else 0 end)
	set @SubvLegea72Restit=(case when @SubventiiLegea72>0 
		then (case when @SubventiiArt80+@SubventiiArt85+@SubventiiLegea116+@SubventiiLegea72<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 then 0 
			else (case when @SubventiiArt80+@SubventiiArt85+@SubventiiLegea116<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 
				then @SubventiiArt80+@SubventiiArt85+@SubventiiLegea116+@SubventiiLegea72-(@SomajAngajator-@ScutireOUG13)+@ScutireArt80+@ScutireArt85 else @SubventiiLegea72 end) end) 
		else 0 end)

	select @dataSus as data, 1 as TipSubventie, @SubvArt80Recup as Recuperat, @SubvArt80Restit as Restituit where @SubvArt80Recup<>0 or @SubvArt80Restit<>0
	union all
	select @dataSus, 2, @ScutireArt80, 0 where @ScutireArt80<>0
	union all 
	select @dataSus, 3, @SubvArt85Recup, @SubvArt85Restit where @SubvArt85Recup<>0 or @SubvArt85Restit<>0
	union all 
	select @dataSus, 4, @ScutireArt85, 0 where @ScutireArt85<>0
	union all
	select @dataSus, 6, @SubvLegea116Recup, @SubvLegea116Restit where @SubvLegea116Recup<>0 or @SubvLegea116Restit<>0
	union all
	select @dataSus, 10, @SubvLegea72Recup, @SubvLegea72Restit where @SubvLegea72Recup<>0 or @SubvLegea72Restit<>0

	return
End

/*
	exec Declaratia112Subventii '11/01/2012', '11/30/2012'
*/	
