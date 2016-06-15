--***
/**	functie ScutiriSomaj	*/
Create function fScutiriSomaj 
	(@dataJos datetime, @dataSus datetime, @marcaJos char(6), @marcaSus char(6), @locmJos char(9), @locmSus char(9))
returns @Scutiri_somaj table
	(Data datetime, Marca char(6), Tip_deducere int, Scutire_art80 decimal(10,3), Scutire_art85 decimal(10,3))
As
Begin
	declare @userASiS char(20), @lista_lm int	--	pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @userASiS=dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@userASiS)
		
	declare @scutiritmp table (Data datetime, Marca char(6), Tip_deducere int, Scutire decimal(10,3))
	
	insert into @scutiritmp
	select n.Data, n.marca, p.coef_invalid, 
	(case when year(n.data)>=2006 and p.mod_angajare='N' and dbo.eom((case when isnull(c.data_inf,'01/01/1901')<>'01/01/1901' then c.data_inf 
		else dateadd(month,12,(case when isnull(d.data_inf,'01/01/1901')='01/01/1901' then p.data_angajarii_in_unitate else isnull(d.data_inf,'01/01/1901') end)) end))>=n.data 
			and year((case when isnull(d.data_inf,'01/01/1901')='01/01/1901' then p.data_angajarii_in_unitate else isnull(d.data_inf,'01/01/1901') end))>=2006 
	then n.somaj_5-(case when n.Asig_sanatate_din_cas<>0 and n.somaj_5<>0 then round((case when 1=1 then 0 else cm.ind_c_medical_unitate end)*dbo.iauParLN(n.data,'PS','3.5%SOMAJ')/100,2) else 0 end) 
	else 0 end)*
	(case when dbo.eom(isnull(d.data_inf,'01/01/1901'))<>n.data and dbo.eom(isnull(c.data_inf,'01/01/1901'))<>n.data or dbo.eom(isnull(d.data_inf,'01/01/1901'))=n.data 
		and isnull(d.data_inf,'01/01/1901')=p.Data_angajarii_in_unitate or dbo.eom(isnull(c.data_inf,'01/01/1901'))=n.data and isnull(c.data_inf,'01/01/1901')=p.Data_plec then 1 
	when dbo.eom(isnull(d.data_inf,'01/01/1901'))=n.data 
		then dbo.Zile_lucratoare(isnull(d.data_inf,'01/01/1901'),n.data)/convert(float,dbo.Zile_lucratoare((case when p.Data_angajarii_in_unitate<dbo.bom(n.data) then dbo.bom(n.data) else p.Data_angajarii_in_unitate end),n.data)) 
	when dbo.eom(isnull(c.data_inf,'01/01/1901'))=n.data 
		then dbo.Zile_lucratoare(dbo.bom(n.data),isnull(c.data_inf,'01/01/1901'))/convert(float,dbo.Zile_lucratoare(dbo.bom(n.data),(case when dbo.eom(p.Data_plec)=n.data then p.Data_plec else n.data end))) 
	else 1 end)
	from net n
		left outer join personal p on p.marca = n.marca 
		left outer join extinfop c on c.marca=n.marca and c.cod_inf='DEXPSOMAJ'
		left outer join extinfop d on d.marca=n.marca and d.cod_inf='DCONVSOMAJ'
		left outer join (select data, marca, sum(ind_c_medical_unitate) as ind_c_medical_unitate from 
			brut where data between @dataJos and @dataSus group by data, marca) cm on n.data=cm.data and n.marca=cm.marca
	where n.data between @dataJos and @dataSus and n.marca between @marcaJos and @marcaSus 
		and n.loc_de_munca between @locmJos and @locmSus and n.data=dbo.eom(n.data) 
--	in legea 250/2013 s-a scos conditia privind scutirea de la plata contributiei la somaj Angajator pentru someri peste 45 de ani. 
--	Legea intra in vigoare la 90 de zile de la data publicarii in MOF (24.07.2013+90 de zile)
		and (p.coef_invalid in ('1','2','3','4') and isnull(d.Data_inf,'01/01/1901')<'10/21/2013')
		and (@lista_lm=0 or exists (select 1 from lmfiltrare l where l.utilizator=@userASiS and l.cod=n.loc_de_munca))		

	insert into @Scutiri_somaj
	select Data, Marca, Tip_deducere, (case when tip_deducere in ('2','3','4') then Scutire else 0 end) as Scutire_art80,
	(case when tip_deducere in ('1') then Scutire else 0 end) as Scutire_art85
	from @scutiritmp
	return
End
