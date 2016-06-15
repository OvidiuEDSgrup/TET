--***
/**	functie contributie NPH	*/
Create function fCalcul_cnph
	(@dataJos datetime, @dataSus datetime, @functie char(6), @lmJos char(9), @lmSus char(9), @tipstat varchar(30), @judet varchar(30), @activitate varchar(20))
returns @sume_cnph table 
	(Numar_mediu_cnph float, Suma_cnph float, Numar_hand int, NrMediuFormula float)
As
Begin
	Declare @salar_minim float, @ore_pontaj float, @Numar_mediu float, @Numar_hand int, @Suma_cnph float, @NrMediuFormula float, @zile_cal float
	
	set @salar_minim=dbo.iauParLN(@dataSus,'PS','S-MIN-BR')
	set @ore_pontaj=0
	set @numar_mediu=0
	set @numar_hand=0
	set @Suma_cnph=0
	set @zile_cal = datediff(day,@dataJos,@dataSus)+1

--	calculez orele asimilate din pontaj 
	select @ore_pontaj=sum(ore) from fOreNumarMediuSalariati (@dataJos, @dataSus, @functie, @lmJos, @lmSus, @tipstat, @judet, @activitate)

--	calculez numar mediu
	Set @numar_mediu=round(@Ore_pontaj/convert(float,@zile_cal),2)

--	calculez numar persoane cu handicap
	Set @numar_hand=isnull((select dbo.fNumarare_salariati(@dataJos,@dataSus,'H',@functie, @lmJos, @tipstat, @activitate)),0)
	Set @NrMediuFormula=round(4/100.00*@Numar_mediu-@Numar_hand,2)

--	calculez contributia pentru neangajare persoane cu handicap
	Select @Suma_cnph=isnull(round(0.5*@Salar_minim*@NrMediuFormula,0),0) 
		where 4/100.00*@Numar_mediu-@Numar_hand>0

	insert into @sume_cnph Select @Numar_mediu, @Suma_cnph, @numar_hand, @NrMediuFormula
	return
End
