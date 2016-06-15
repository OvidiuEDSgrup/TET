--***
Create
function [dbo].[fDeclaratia112Subventii] (@DataJ datetime, @DataS datetime)
returns @DateSubventii table (Data datetime, TipSubventie int, Recuperat decimal(10), Restituit decimal(10))
as
Begin
	declare @SomajAngajator decimal(10), @SubventiiArt80 decimal(10), @SubventiiArt85 decimal(10), @SubventiiArt172 decimal(10), 
	@ScutireArt80 decimal(10), @ScutireArt85 decimal(10),
	@SubvArt80Recup decimal(10), @SubvArt80Restit decimal(10), @ScutArt80Recup decimal(10), @ScutArt80Restit decimal(10), 
	@SubvArt85Recup decimal(10), @SubvArt85Restit decimal(10), @ScutArt85Recup decimal(10), @ScutArt85Restit decimal(10), 
	@SubvArt172Recup decimal(10), @SubvArt172Restit decimal(10), @ScutireOUG13 decimal(10)

	select @SomajAngajator=sum(somaj_5) from net where data=@DataS
	select @SubventiiArt80=sum((case when p.coef_invalid=2 or p.coef_invalid=3 or p.coef_invalid=4 then n.chelt_prof else 0 end)), 
		@SubventiiArt85=sum((case when p.coef_invalid=1 then n.chelt_prof else 0 end)), 
		@SubventiiArt172=sum((case when p.coef_invalid=7 then n.chelt_prof else 0 end)) 
	from net n
		left outer join personal p on p.Marca=n.Marca
	where data=@DataS
	select @ScutireArt80=sum(Scutire_art80), @ScutireArt85=sum(Scutire_art85) 
	from fScutiriSomaj (@DataJ, @DataS, '', 'ZZZ', '', 'ZZZ')
	select @ScutireOUG13=isnull(round(sum(somaj),0),0) from dbo.fPSScutiriOUG13 (@DataJ,@DataS, 0, '', '', 0)
	set @SubvArt80Recup=(case when @SubventiiArt80<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 
		then @SubventiiArt80 else (@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 end)
	set @SubvArt80Restit=(case when @SubventiiArt80<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 
		then 0 else @SubventiiArt80-(@SomajAngajator-@ScutireOUG13)+@ScutireArt80+@ScutireArt85 end)

	set @SubvArt85Recup=(case when @SubventiiArt85>0 then (case when @SubventiiArt80+@SubventiiArt85<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 
		then @SubventiiArt85 else (case when @SubventiiArt80<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 
		then (@SomajAngajator-@ScutireOUG13)-@SubventiiArt80-@ScutireArt80-@ScutireArt85 else 0 end) end) else 0 end)
	set @SubvArt85Restit=(case when @SubventiiArt85>0 then (case when @SubventiiArt80+@SubventiiArt85<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 then 0 
		else (case when @SubventiiArt80<(@SomajAngajator-@ScutireOUG13)-@ScutireArt80-@ScutireArt85 
		then @SubventiiArt80+@SubventiiArt85-(@SomajAngajator-@ScutireOUG13)+@ScutireArt80+@ScutireArt85 else @SubventiiArt85 end) end) else 0 end)
	set @SubvArt172Recup=(case when @SubventiiArt172>0 then (case when @SubventiiArt80+@SubventiiArt85+@SubventiiArt172<(@SomajAngajator-@ScutireOUG13) 
		then @SubventiiArt172 else (case when @SubventiiArt80+@SubventiiArt85<(@SomajAngajator-@ScutireOUG13) 
		then (@SomajAngajator-@ScutireOUG13)-(@SubventiiArt80+@SubventiiArt85) else 0 end) end) else 0 end)
	set @SubvArt172Restit=(case when @SubventiiArt172>0 then 
		(case when @SubventiiArt80+@SubventiiArt85+@SubventiiArt172<(@SomajAngajator-@ScutireOUG13) then 0 
		else (case when @SubventiiArt80+@SubventiiArt85<(@SomajAngajator-@ScutireOUG13) 
		then @SubventiiArt80+@SubventiiArt85+@SubventiiArt172-(@SomajAngajator-@ScutireOUG13) else @SubventiiArt172 end) end) else 0 end)

	insert into @DateSubventii
	select @DataS, 1, @SubvArt80Recup, @SubvArt80Restit where @SubvArt80Recup<>0 or @SubvArt80Restit<>0
	union all
	select @DataS, 2, @ScutireArt80, 0 where @ScutireArt80<>0
	union all 
	select @DataS, 3, @SubvArt85Recup, @SubvArt85Restit where @SubvArt85Recup<>0 or @SubvArt85Restit<>0
	union all 
	select @DataS, 4, @ScutireArt85, 0 where @ScutireArt85<>0
	union all
	select @DataS, 10, @SubvArt172Recup, @SubvArt172Restit where @SubvArt172Recup<>0 or @SubvArt172Restit<>0
	return
End

/*
	select * from fDeclaratia112Subventii ('01/01/2011', '01/31/2011')
*/
