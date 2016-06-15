--***
Create procedure wScriuIstPers @sesiune varchar(50), @parXML xml
as  
Begin
declare @userASiS varchar(10), @datajos datetime, @datasus datetime, @LunaInch int, @AnulInch int, @DataInch datetime, 
@DataLJ datetime

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
set @LunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
set @AnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
set @DataInch=dbo.Eom(convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4)))

select @datajos=dbo.Bom(isnull(xA.row.value('@datajos','datetime'),isnull(xA.row.value('@data','datetime'),'01/01/1901'))), 
@datasus=dbo.Eom(isnull(xA.row.value('@datasus','datetime'),isnull(xA.row.value('@data','datetime'),'12/31/2999'))) 
from @parXML.nodes('row') as xA(row) 
set @DataLJ=dbo.Bom(@datasus)

if @datasus>@DataInch 
	and (isnull((select count(1) from istpers i
			left outer join personal p on p.Marca=i.Marca 
			left outer join LMfiltrare lu on lu.utilizator=@userASiS and lu.cod=p.Loc_de_munca
		where Data=@datasus and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)),0)
	<>
	isnull((select count(1) from personal p 
		left outer join infopers ip on ip.Marca=p.Marca 
		left outer join LMfiltrare lu on lu.utilizator=@userASiS and lu.cod=p.Loc_de_munca
		where (p.loc_ramas_vacant=0 or p.data_plec>=@DataLJ or left(isnull(ip.loc_munca_nou,''),7)='DETASAT') and p.Data_angajarii_in_unitate<=@datasus
			and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)),0)
	or isnull((select count(1) from personal p
		left outer join infopers ip on ip.Marca=p.Marca
		left outer join istpers i on i.Data=@datasus and i.Marca=p.Marca
		left outer join LMfiltrare lu on lu.utilizator=@userASiS and lu.cod=p.Loc_de_munca
	where (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
		and (p.loc_ramas_vacant=0 or p.data_plec>=@DataLJ or left(isnull(ip.loc_munca_nou,''),7)='DETASAT') and p.Data_angajarii_in_unitate<=@datasus and p.Loc_de_munca<>i.Loc_de_munca),0)<>0)
		exec scriuistPers @DataLJ, @datasus, '', '', 1, 1
End
