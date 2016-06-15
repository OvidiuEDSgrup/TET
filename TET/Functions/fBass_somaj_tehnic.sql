--***
/**	functie BASS somaj tehnic	*/
Create function fBass_somaj_tehnic (@Datajos datetime, @Datasus datetime, @plMarca int, @pcMarca char(6), 
	@plLocm int, @Lmjos char(9), @Lmsus char(9), @lSir_marci int, @cSir_marci char(200), @lTipBASS int, @cTipBASS char(200), 
	@Alfabetic int, @Tip_declaratie int, @Necompletare_regcom_somajt int)
returns @Bass_somaj_tehnic table
	(An int, Luna int, CF numeric, RJ char(3), RN int, RA int, Nume char(29), CNP char(13), CM int, CV int, PE int, SOM int, TT int, NN int, 
	DD int, SS int, PP int, TV float, TVN float, TVD float, TVS float, CASAT float, CASTOT float, BASS float, CNPA char(13), NORMA int, 
	TIPD char(1), TIPR char(1), NUMEANT char(29), CNPANT char(13), MARCA char(6), PPS int, PPD int, PPBASS int, PPFAAMBP float, FAAMBP float, PPCAS float, IND_CS int, NRZ_CFP int)
As
Begin
	Declare @nume char(50), @cod_fiscal char(13), @cod_fiscal_FR char(13), @RJ char(3), @RN int, @RA int, @Ore_luna float, @Salar_minim float, @TIPD char(1), @TIPR char(1)
	Set @TIPD=(case when @Tip_declaratie=1 then 'R' else '' end)
	Set @TIPR=(case when @Tip_declaratie=1 then 'M' else '' end)
	Set @nume=dbo.iauParA('GE','NUME')
	Set @cod_fiscal=dbo.iauParA('GE','CODFISC')
	Set @cod_fiscal_FR=(case when left(rtrim(ltrim(upper(@Cod_fiscal))),2)='RO' then substring(rtrim(ltrim(upper(@Cod_fiscal))),3,13) 
	when left(rtrim(ltrim(upper(@Cod_fiscal))),1)='R' then substring(rtrim(ltrim(upper(@Cod_fiscal))),3,13) else rtrim(ltrim(@Cod_fiscal)) end)
	if left(@cod_fiscal_FR,1)='.' or @cod_fiscal_FR=''
		set @cod_fiscal_FR='0'
	Set @RJ='*'+(case when upper(left(ltrim(dbo.iauParA('PS','REGCOM')),1))='J' then substring(ltrim(dbo.iauParA('PS','REGCOM')),2,2) else ltrim(rtrim(dbo.iauParA('PS','REGCOM'))) end)
	Set @RN=(case when @Necompletare_regcom_somajt=1 then 0 else dbo.iauParN('PS','REGCOM') end)
	Set @RA=(case when @Necompletare_regcom_somajt=1 then 0 else dbo.iauParN('PS','REGCOMAN') end)
	Set @Ore_luna=dbo.iauParLN(@Datasus,'PS','ORE_LUNA')
	Set @Salar_minim=dbo.iauParLN(@Datasus,'PS','S-MIN-BR')

	insert into @Bass_somaj_tehnic
	select year(max(a.data)), month(max(a.data)), @cod_fiscal_FR, @RJ, @RN, @RA, max(left(i.Nume,29)),b.Cod_numeric_personal,5,0 as CV, 
	0 as PE, 0 as SOM, sum(Ore/Regim_de_lucru), sum(Ore/Regim_de_lucru), 0 as DD, 0 as SS, 0 as PP, round((sum(Ore/Regim_de_lucru)/(@Ore_luna/8))*@Salar_minim,0),
	round((sum(Ore/Regim_de_lucru)/(@Ore_luna/8))*@Salar_minim,0), 0 as TVD, 0 as TVS, 0 as CASAT, 0 as CASTOT, 0 as BASS, 0 as CNPA, (case when max(i.Grupa_de_munca) in ('C','O','P') or max(a.regim_de_lucru)>8 or max(a.regim_de_lucru)=0 then 8 else max(a.regim_de_lucru) end) as Norma, '' as TIPD, '' as TIPR, '' as NUMEANT, 0 as CNPANT, max(a.marca) as MARCA, 0 as PPS, 0 as PPD, 0 as PPBASS, 0 as PPFAAMBP, 0 as FAAMBP, 0 as PPCAS, 0 as IND_CS, 0 as NRZ_CFP
	from pontaj a 
		left outer join personal b on a.marca=b.marca
		left outer join istPers i on i.Data=@Datasus and a.marca=i.marca
	where a.Data between @Datajos and @Datasus and (@plMarca=0 or a.Marca=@pcMarca) 
		and (@plLocm=0 or i.Loc_de_munca between @Lmjos and @Lmsus) 
		and (@lSir_marci=0 or charindex(','+rtrim(ltrim(a.marca))+',',@cSir_marci)>0) and a.Ore<>0
	Group by b.cod_numeric_personal
	order by (case when @Alfabetic=0 then max(a.marca) else max(b.Nume) end)
	return
End
