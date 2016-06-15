--***
/**	functie corectii Q	*/
Create
function fCorectiaQ  (@DataJ datetime, @DataS datetime, @pMarca char(6), @Lm char(9), @PeLm int) 
returns @CorectiaQ table
	(Data datetime, Marca char(6), Loc_de_munca char(9), Valoare decimal(10,2))
as
begin
	declare @SubtipCor int
	Set @SubtipCor=dbo.iauParL('PS','SUBTIPCOR')

	insert into @CorectiaQ
	select dbo.eom(c.data) as Data, c.marca, (case when @PeLm=1 then c.Loc_de_munca else '' end) as Loc_de_munca, 
		round(round(sum(c.Suma_corectie),2),10,2) as Valoare
	from corectii c 
		left outer join infopers i on c.marca=i.marca
	where c.data between @DataJ and @DataS and (@pMarca='' or c.Marca=@pMarca) 
		and (@Subtipcor=0 and c.tip_corectie_venit='Q-' or @Subtipcor=1 and c.Tip_corectie_venit in (select s.Subtip from Subtipcor s where s.tip_corectie_venit='Q-'))
	group by dbo.eom(c.data), c.Marca, (case when @PeLm=1 then c.Loc_de_munca else '' end)
	order by dbo.eom(c.data), c.Marca, (case when @PeLm=1 then c.Loc_de_munca else '' end)

	return
end
