--***
/**	functie care returneaza salariatii din personal / istoric personal la care se modifica 
	zilele de concediu de odihna la un anumit an fata de cele anterioare */
Create function fPrevizionareZileCO 
	(@dataJos datetime, @dataSus datetime, @marca char(6), @locm char(9), @tippersonal char(1)=null, @salariatiCuModificari int, @grupare int, @alfabetic int)
returns @PrevZileCO table 
	(data datetime, marca char(6), nume char(50), cod_functie char(6), den_functie char(30), lm char(9), den_lm char(30), mod_angajare char(30), 
	vechime_ani int, zile_co_ant float, zile_co_calculate float)
As
Begin
	declare @ZileCOVechUnit int, @dataJosNext datetime, @dataSusNext datetime, @utilizator varchar(20), @nLunaInch int, @nAnulInch int, @dDataInch datetime, @AfisareSporCalculat int

	select @marca=isnull(@marca,''), @locm=isnull(@locm,'')
	Set @ZileCOVechUnit=dbo.iauParL('PS','ZICOVECHU')
	set @dataJosNext=dbo.bom(DateAdd(month,1,@dataSus))
	set @dataSusNext=dbo.eom(DateAdd(month,1,@dataSus))
	set @nLunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @nAnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	set @dDataInch=dbo.eom(convert(datetime,str(@nLunaInch,2)+'/01/'+str(@nAnulInch,4)))
	set @AfisareSporCalculat=(case when DateDiff(month,@dDataInch,@dataSus)>1 then 1 else 0 end)
	
--	citire utilizator pt. filtrare dupa proprietatea LOCMUNCA.
	SET @utilizator = dbo.fIaUtilizator(null)
	
	insert @PrevZileCO
	select i.Data, rtrim(isnull(i.Marca,p.Marca)) as marca, rtrim(isnull(i.Nume,p.Nume)) as nume, 
	rtrim(isnull(i.Cod_functie,p.Cod_functie)) as cod_functie, rtrim(isnull(f.Denumire,'')) as den_functie,
	rtrim(isnull(i.Loc_de_munca,p.Loc_de_munca)) as lm, rtrim(isnull(lm.Denumire,'')) as den_lm,
	(case when p.Mod_angajare='D' then 'Perioada determinata' else 'Perioada nedeterminata' end) as mod_angajare, 
	(case when @ZileCOVechUnit=0 then (case when right(convert(char(8),c.Vechime_totala,1),2)=99 then 0 
	else convert(int,right(convert(char(8),c.Vechime_totala,1),2))+(case when MONTH(c.Vechime_totala)=12 then 1 else 0 end) end)
	else convert(int,left(c.Vechime_la_intrare,2)) end) as vechime_ani,
	isnull(p.Zile_concediu_de_odihna_an,0) as zile_co_ant, c.Zile_CO_an as zile_co_calculate
	from personal p  
		left outer join istPers i on i.Data=@dataSus and i.marca=p.marca
		left outer join fCalculVechimeSporuri (@dataJos, @dataSus, @marca, 0, 0, '', '', 0) c on c.Marca=p.Marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and p.Loc_de_munca=lu.cod
		left outer join functii f on f.Cod_functie=isnull(i.Cod_functie,p.Cod_functie)
		left outer join lm on lm.Cod=isnull(i.Loc_de_munca,p.Loc_de_munca)
	where (@marca='' or p.marca=@marca) 
		and (@locm='' or isnull(i.Loc_de_munca,p.Loc_de_munca) like rtrim(@locm)+'%')
		and p.Data_angajarii_in_unitate<=@dataSus and (convert(int,p.Loc_ramas_vacant)=0 or p.Data_plec>@dataJos)
		and (@salariatiCuModificari=0 or c.Zile_CO_an<>p.Zile_concediu_de_odihna_an) 
		and (@tippersonal is null or (@tippersonal='T' and isnull(i.tip_salarizare,p.Tip_salarizare) in ('1','2')) or (@tipPersonal='M' and isnull(i.tip_salarizare,p.Tip_salarizare) in ('3','4','5','6','7')))		
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
	Order by (case when @grupare='2' then isnull(i.Loc_de_munca,p.Loc_de_munca) else '' end), 
		(case when @alfabetic=1 then isnull(i.Nume,p.Nume) else p.Marca end)

	return
End

/*
	select * from fPrevizionareZileCO('01/01/2012', '01/31/2012', '', '', 0)
*/
