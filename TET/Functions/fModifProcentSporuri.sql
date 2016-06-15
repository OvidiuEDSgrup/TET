--***
/*	functie care returneaza salariatii din personal / istoric personal la care s-a modificat procentul de spor specific, spor vechime 
	salariatiCuModificari = 0	toti salariatii
	salariatiCuModificari = 1	Cei cu modificare procente in luna la care se genereaza raportul
	salariatiCuModificari = 2	Cei cu modificare procente fata de momentul generarii raportului
*/
Create 
function dbo.fModifProcentSporuri 
	(@dataJos datetime, @dataSus datetime, @marca char(6), @locm char(9), @tipspor char(2), @salariatiCuModificari int, @datarefmodif datetime, @ZilePanaLaPragVechime int)
returns @ModifSporuri table 
	(Data datetime, Marca char(6), Nume char(50), Cod_functie char(6), Denumire_functie char(30), Loc_de_munca char(9), Denumire_loc_de_munca char(30), 
	TipSpor char(20), SporLunaAnt float, SporLunaCrt float, Vechime char(8))
As
Begin
	declare @denSporSpec char(20), @dataJosPrev datetime, @dataSusPrev datetime, @dataJosNext datetime, @dataSusNext datetime, 
	@utilizator varchar(20), @nLunaInch int, @nAnulInch int, @dDataInch datetime, @AfisareSporCalculat int

	SET @utilizator = dbo.fIaUtilizator(null) --	citire utilizator pt. filtrare dupa proprietatea LOCMUNCA.

	set @denSporSpec=dbo.iauParA('PS','SSPEC')
	set @denSporSpec=(case when @denSporSpec='' then 'Spor specific' else @denSporSpec end)
	set @dataJosPrev=dbo.bom(DateAdd(month,-1,@dataSus))
	set @dataSusPrev=dbo.eom(DateAdd(month,-1,@dataSus))
	set @dataJosNext=dbo.bom(DateAdd(month,1,@dataSus))
	set @dataSusNext=dbo.eom(DateAdd(month,1,@dataSus))
	set @nLunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @nAnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	set @dDataInch=dbo.eom(convert(datetime,str(@nLunaInch,2)+'/01/'+str(@nAnulInch,4)))
	set @AfisareSporCalculat=(case when DateDiff(month,@dDataInch,@dataSus)>1 then 1 else 0 end)
	
--	creez tabela temporara in care determin vechimea in ani/procentele de vechime la luna generarii raportului
	declare @vechimi table (Marca char(6), Vechime_totala datetime, Vechime_la_intrare char(6),	dVechime_la_intrare datetime, Spor_vechime float, Spor_specific float, 
		VechimeAni int, VechimeUnitateAni int, VechimeGrilaNext int, VechimeUnitateGrilaNext int Unique (Marca))
	insert into @vechimi
	select p.Marca, c.Vechime_totala, c.Vechime_la_intrare, c.dVechime_la_intrare, c.Spor_vechime, c.Spor_specific, 
	(case when year(p.Vechime_totala)=1899 then 0 else convert(int,left(convert(char(10),c.Vechime_totala,11),2))+(case when MONTH(c.Vechime_totala)=12 then 1 else 0 end) end), 
	convert(int,left(c.Vechime_la_intrare,2))+(case when substring(c.Vechime_la_intrare,3,2)='12' then 1 else 0 end), 0, 0
	from personal p
		left outer join fCalculVechimeSporuri (@dataJos, @dataSus, @marca, 0, 0, '', '', 0) c on c.Marca=p.Marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and p.Loc_de_munca=lu.cod
	where (isnull(@marca,'')='' or p.marca=@marca) 
		and p.Data_angajarii_in_unitate<=@dataSus and (convert(int,p.Loc_ramas_vacant)=0 or p.Data_plec>@dataJos)
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
--	determin vechimea urmatoare din plaja (in ani) 
	update @vechimi set VechimeGrilaNext=isnull((select top 1 Limita from grspor a where a.Cod='Ve' and a.Limita>VechimeAni order by a.Nrcrt Asc),VechimeAni),
		VechimeUnitateGrilaNext=isnull((select top 1 Limita from grspor a where a.Cod='Sp' and a.Limita>VechimeUnitateAni order by a.Nrcrt Asc),VechimeUnitateAni) 

--	creez tabela temporara in care determin procentele de vechime la luna anterioara lunii de generare a raportului
--	am nevoie si de acea vechime/procente in cazul afisarii salariatilor cu modificare in luna.
	declare @vechimilant table (Marca char(6), Spor_vechime float, Spor_specific float Unique (Marca))
	insert into @vechimilant
	select p.Marca, c.Spor_vechime, c.Spor_specific
	from personal p
		left outer join fCalculVechimeSporuri (@dataJosPrev, @dataSusPrev, @marca, 0, 0, '', '', 0) c on c.Marca=p.Marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and p.Loc_de_munca=lu.cod
	where (isnull(@marca,'')='' or p.marca=@marca) 
		and p.Data_angajarii_in_unitate<=@dataSus and (convert(int,p.Loc_ramas_vacant)=0 or p.Data_plec>@dataJos)
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)

--	pun in tabela temporara ultima pozitie din istpers pe marca cu data < @datasus
	declare @istpers table (Data datetime, Marca char(6), Spor_vechime float, Spor_specific float)
	insert into @istpers
	select Data, Marca, Spor_vechime, Spor_specific from (select Data, Marca, Spor_vechime, Spor_specific, RANK() over (partition by Marca order by Data Desc) as ordine
	from istPers where (@datarefmodif is null and Data<@DataSus or Data=dbo.eom(@datarefmodif)) and (isnull(@marca,'')='' or Marca=@marca) and (isnull(@locm,'')='' or Loc_de_munca like rtrim(@locm)+'%')) a
	where Ordine=1
		
	insert @ModifSporuri
	select a.Data, isnull(a.Marca,p.Marca), isnull(a.Nume,p.Nume), isnull(a.Cod_functie,p.Cod_functie), rtrim(isnull(f.Denumire,'')) as Denumire_functie,
	isnull(a.Loc_de_munca,p.Loc_de_munca), rtrim(isnull(lm.Denumire,'')) as Denumire_loc_de_munca,
	(case when @tipspor='SP' then @denSporSpec when @tipspor='SV' then 'Vechime munca' end) as TipSpor,	
	(case when @tipspor='SP' then isnull(b.Spor_specific,0) when @tipspor='SV' then isnull(b.Spor_vechime,0) else 0 end) as SporLunaAnt, 
	(case when @tipspor='SP' then isnull((case when @AfisareSporCalculat=1 then vc.Spor_specific else a.Spor_specific end),p.Spor_specific) 
		when @tipspor='SV' then isnull((case when @AfisareSporCalculat=1 then vc.Spor_vechime else a.Spor_vechime end),p.Spor_vechime) else 0 end) as SporLunaCrt, 
	(case when @tipspor='SP' then (case when vc.VechimeUnitateAni<10 then '0' else '' end)+rtrim(convert(char(2),vc.VechimeUnitateAni))+'/'+ 
		(case when substring(vc.Vechime_la_intrare,3,2)='12' then '00' else substring(vc.Vechime_la_intrare,3,2) end)+'/'+substring(vc.Vechime_la_intrare,5,2)
		else (case when vc.VechimeAni<10 then '0' else '' end)+rtrim(convert(char(2),vc.VechimeAni))+'/'+
		(case when MONTH(vc.Vechime_totala)=12 then '00' else convert(char(2),substring(convert(char(10),vc.Vechime_totala,11),4,2)) end)+'/'+
		(case when day(vc.Vechime_totala)<10 then '0' else '' end)+rtrim(convert(char(2),day(vc.Vechime_totala))) end) as Vechime
	from personal p  
		left outer join @vechimi vc on vc.Marca=p.Marca
		left outer join @vechimilant va on va.Marca=p.Marca
		left outer join istPers a on a.Data=@dataSus and a.marca=p.marca
--		left outer join istPers b on (@AfisareSporCalculat=0 and b.Data=dbo.eom(DateAdd(month,-1,a.Data)) or @AfisareSporCalculat=1 and b.Data=@dDataInch) and b.marca=p.marca
		left outer join @istpers b on b.marca=p.marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and p.Loc_de_munca=lu.cod
		left outer join functii f on f.Cod_functie=isnull(a.Cod_functie,p.Cod_functie)
		left outer join lm on lm.Cod=isnull(a.Loc_de_munca,p.Loc_de_munca)
	where (isnull(@marca,'')='' or p.marca=@marca) and (isnull(@locm,'')='' or isnull(a.Loc_de_munca,p.Loc_de_munca) like rtrim(@locm)+'%')
		and p.Data_angajarii_in_unitate<=@dataSus and (convert(int,p.Loc_ramas_vacant)=0 or p.Data_plec>@dataJos)
--	filtrez aici salariatii carora li se modifica procentul de spor vechime (in munca/in unitate)
		and (@salariatiCuModificari=0 
			or @salariatiCuModificari=1 and 
				(@tipspor='SP' and isnull((case when @AfisareSporCalculat=1 then vc.Spor_specific else a.Spor_specific end),p.Spor_specific)<>
					(case when @AfisareSporCalculat=1 then isnull(va.Spor_specific,0) else isnull(b.Spor_specific,0) end)
				or @tipspor='SV' and isnull((case when @AfisareSporCalculat=1 then vc.Spor_vechime else a.Spor_vechime end),p.Spor_vechime)<>
					(case when @AfisareSporCalculat=1 then isnull(va.Spor_vechime,0) else isnull(b.Spor_vechime,0) end))
			or @salariatiCuModificari=2 and 
				(@tipspor='SP' and isnull((case when @AfisareSporCalculat=1 then vc.Spor_specific else a.Spor_specific end),p.Spor_specific)<>isnull(b.Spor_specific,0) 
				or @tipspor='SV' and isnull((case when @AfisareSporCalculat=1 then vc.Spor_vechime else a.Spor_vechime end),p.Spor_vechime)<>isnull(b.Spor_vechime,0))
			)
--	filtrez aici salariatii care mai au X zile pana la atingerea urmatorului prag de vechime din grila
		and (isnull(@ZilePanaLaPragVechime,0)=0 
			or @tipspor='SP' and DATEDIFF(DAY,vc.dVechime_la_intrare,DateAdd(month,-1,DateAdd(year,vc.VechimeUnitateGrilaNext,'01/01/1900'))) between 1 and @ZilePanaLaPragVechime
			or @tipspor='SV' and DATEDIFF(DAY,p.Vechime_totala,DATEADD(year,vc.VechimeGrilaNext,'01/01/1900'))-31 between 1 and @ZilePanaLaPragVechime)
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
	Order by a.Marca

	return
End

/*
	select * from fModifProcentSporuri('10/01/2011', '10/31/2011', Null, Null, 'SP', 0, 3)
	select Data, Marca, Nume, Cod_functie, Loc_de_munca, TipSpor, SporLunaAnt, SporLunaCrt from fModifProcentSporuri ('10/01/2011', '10/31/2011', '', '', 'SP', 1)
*/
