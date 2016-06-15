--***
/**	procedura virament carduri	*/
Create
procedure pVirament_carduri 
	@DataJ datetime, @DataS datetime, @Avans int, @RestDePlata int, @Corectii int, @CO int, 
	@Retineri int, @CoefMultipl float, @ProcVirament float, @lApareCorU int, @lApareCorO int, @lApareCorM int, @ScriuSumaNeta int, 
	@FaraCAS int, @FaraSomaj int, @FaraCASS int, @FaraImpozit int, @cTipCorectie char(2), @lSirCor int, @cSirCor char(200), 
	@GestSumePl int, @lTipCard int, @cTipCard char(25), @lBanca2 int, @pLm char(9), @Strict int, @lNrStat int, @nNrStat float, 
	@lStareCor int, @cStareCor char(1), @FiltruDataCorU int, @DataCorUJ datetime, @DataCorUS datetime, @FiltruDataCorO int, 
	@DataCorOJ datetime, @DataCorOS datetime, @DataCorMJ datetime, @DataCorMS datetime, @lSirMarci int, 
	@cSirMarci char(200), @SiMMzero int, @cSirCodben char(200), @FiltruDataOP int,  @DataOP decimal(10), 
	@DataRetJ datetime, @DataRetS datetime, @DataDoc datetime, @lSirLocm int, @cSirLocm char(200), 
	@lTipStat int, @cTipStat varchar(30), @lTipPers int, @cTipPers char(1), @DoarCOLunaCrt int=0
As
begin
	declare @Subtipcor int, @nCASind float, @nSomaj_ind float, @Tip_suma char(10), @Data datetime, @Marca char(6), @Nume char(50), @Loc_de_munca char(9), @Cont_banca char(25), @Tip_corectie char(2),@Suma_de_plata float,@Data200 datetime,@Moment_plata int
	Set @Subtipcor=dbo.iauParL('PS','SUBTIPCOR')
	Set @nCASind=dbo.iauParLN(@DataS,'PS','CASINDIV')
	Set @nSomaj_ind=dbo.iauParLN(@DataS,'PS','SOMAJIND')
	delete from carduri where data=@DataDoc

	Declare cursor_card Cursor For
	select a.Tip_suma, a.Data, a.Marca, a.Nume, a.Loc_de_munca, a.Cont_banca, a.Tip_corectie_venit, a.Suma 
	from dbo.fCarduri (@DataJ, @DataS, @Avans, @RestDePlata, @Corectii, @CO, @Retineri, 
	@lApareCorU, @lApareCorO, @lApareCorM, @ScriuSumaNeta, @FaraCAS, @FaraSomaj, @FaraCASS, @FaraImpozit, 
	@cTipCorectie, @lSirCor, @cSirCor, @GestSumePl, @lTipCard, @cTipCard, @lBanca2, @lNrStat, @nNrStat, 
	@lStareCor, @cStareCor, @FiltruDataCorU, @DataCorUJ, @DataCorUS, @FiltruDataCorO, @DataCorOJ, @DataCorOS, 
	@DataCorMJ, @DataCorMS, @SiMMzero, @cSirCodben, @FiltruDataOP,  @DataOP, @DataRetJ, @DataRetS, @DataDoc, 
	@lTipPers, @cTipPers, @DoarCOLunaCrt) a
		left outer join personal p on a.marca=p.marca
		left outer join infopers i on a.marca=i.marca
	where (@lSirMarci=0 or charindex (','+rtrim (a.Marca)+',',rtrim(@cSirMarci))<>0) 
		and (@pLm='' or a.Loc_de_munca like rtrim(@pLm)+(case when @Strict=1 then '' else '%' end)) 
		and (@lSirLocm=0 or charindex (','+rtrim (a.Loc_de_munca)+',',rtrim(@cSirLocm))<>0) and (@lTipStat=0 or i.Religia=@cTipStat)
	order by a.Marca

	open cursor_card
	fetch next from cursor_card into @Tip_suma,@Data,@Marca,@Nume,@Loc_de_munca,@Cont_banca,@Tip_corectie, @Suma_de_plata
	While @@fetch_status = 0 
	Begin
--		scriere corectii cu data=data corectiei + 200 de ani reprezentand corectia achitata
		if @Tip_suma='AL' and (@Tip_corectie='U-' or @Tip_corectie='O-') or @GestSumePl=1 and @Tip_suma='CS'
		Begin
			Set @Data200=Dateadd(year,200,@Data)
			Set @Moment_plata=(case when @Tip_suma='AL' and (@Tip_corectie='U-' or @Tip_corectie='O-') 
			then (case when @Avans=1 then 1 else 2 end) when @GestSumePl=1 and @Tip_suma='CS' then 3 else 0 end)
			exec scriuCorectii @Data200, @Marca, @Loc_de_munca, @Tip_corectie, @Suma_de_plata, @Moment_plata, 0
		End
--		completare tabela carduri
		if isnull((select count(1) from carduri where data=@DataDoc and marca=@Marca),0)=0
			insert into carduri select @DataDoc, @Marca, @Nume, @Cont_banca, @Suma_de_plata
		else
			update carduri set suma=suma+@Suma_de_plata where data=@DataDoc and marca=@Marca

		fetch next from cursor_card into @Tip_suma,@Data,@Marca,@Nume,@Loc_de_munca,@Cont_banca,@Tip_corectie, @Suma_de_plata
	End
	update carduri set Suma=round(convert(decimal(12,2),Suma*(1+@ProcVirament/100)*(case when @CoefMultipl=0 then 1 else @CoefMultipl end)),2) where data=@DataDoc
	close cursor_card
	Deallocate cursor_card
End
