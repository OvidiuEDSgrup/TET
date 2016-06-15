--***
/**	functie pt. numarare salariati total/ocazionali/plecati/pe sex apelata din macheta salariati PSplus */
Create
function fNumarTotalSalariati()
returns @nrsalariati table (TotalSalariati int, SalariatiOcazionali int, SalariatiPlecati int, SalariatiBarbati int, SalariatiFemei int, SalariatiSuspendati int)
As
Begin
	declare @nLunaInch int, @nAnulInch int, @dDataInch datetime, @SalariatiSuspendatiIC2Ani int, @DataCurenta datetime
--	citesc luna/anul inchis pt. a studia in raport cu luna urmatoare acestei luni starea de suspendare a salariatilor 
--	pe viitor poate vom trata si alte suspendari
	set @nLunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @nAnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	set @dDataInch=dateadd(month,1,convert(datetime,str(@nLunaInch,2)+'/01/'+str(@nAnulInch,4)))
	select @DataCurenta=dbo.EOM(@dDataInch)

--	18.06.2012 - in urma discutiei cu cei de la Grup Sapte am modificat modul de calcul al celor suspendati
--	studiem in raport cu data curenta starea de suspendare a salariatilor
	select @DataCurenta=convert(datetime,getdate(),103)
		
	insert into @nrsalariati 
	Select count(1) as TotalSalariati, sum((case when Grupa_de_munca in ('O','P') and convert(int,Loc_ramas_vacant)=0 then 1 else 0  end)) as SalariatiOcazionali,
	sum((case when convert(int,Loc_ramas_vacant)=1 then 1 else 0  end)) as SalariatiPlecati,
	sum((case when convert(int,Loc_ramas_vacant)=0 and convert(int,Sex)=1 then 1 else 0  end)) as SalariatiBarbati,
	sum((case when convert(int,Loc_ramas_vacant)=0 and convert(int,Sex)=0 then 1 else 0  end)) as SalariatiFemei,
	0 as SalariatiSuspendati
	from personal 

	declare @tmpExtinfop table (Marca char(6) not null, Cod_inf char(13) not null, Val_inf char(80) not null, 
	Data_inf datetime not null, Procent float not null Unique (Marca, Cod_inf, Val_inf, Data_inf)) 
	insert into @tmpExtinfop (Marca, Cod_inf, Val_inf, Data_inf, Procent)
	select e.Marca, e.Cod_inf, e.Val_inf, e.Data_inf, e.Procent 
	from Extinfop e where e.Cod_inf in ('SCDATAINC','SCDATASF')
		and exists (select p.Marca from personal p where p.Marca=e.Marca)

	set @SalariatiSuspendatiIC2Ani=isnull((select COUNT(1) from @tmpExtinfop a
		left outer join @tmpExtinfop b on b.Marca=a.Marca and b.Cod_inf='SCDATASF' and b.Procent=a.Procent
	where a.Cod_inf='SCDATAINC' and a.Data_inf<@DataCurenta and b.Data_inf>@DataCurenta),0)
	
	update @nrsalariati set TotalSalariati=TotalSalariati-SalariatiOcazionali-SalariatiPlecati-@SalariatiSuspendatiIC2Ani,
	SalariatiSuspendati=@SalariatiSuspendatiIC2Ani
	
	return
End

/*
	select * from fNumarTotalSalariati()
*/
