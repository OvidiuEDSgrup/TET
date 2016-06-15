--***
Create procedure wIaCorectii @sesiune varchar(50), @parXML xml
as  
declare @AccesDataCor int, @subtipcor int, @CAS_J int, @userASiS varchar(10), @LunaInch int, @AnulInch int, @DataInch datetime, 
@LunaBloc int, @AnulBloc int, @DataBloc datetime, 
@tip varchar(20), @subtip varchar(20), @data datetime, @datajos datetime, @datasus datetime, 
@f_tipcor varchar(2), @f_dencor varchar(30), @tipcor varchar(2), @f_salariat varchar(50),
@CorectiiNete int

set @AccesDataCor=dbo.iauParL('PS','ACCESDCOR')
set @subtipcor=dbo.iauParL('PS','SUBTIPCOR')
set @CAS_J=dbo.iauParL('PS','CAS-J')
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
set @CorectiiNete=isnull((select count(1) from webConfigTipuri where meniu='SL' and tip='CN' and ISNULL(subtip,'')='' and vizibil=1),0)

set @LunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
set @AnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
set @DataInch=dbo.Eom(convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4)))

set @LunaBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNABLOC'), 1)
set @AnulBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANULBLOC'), 1901)
set @DataBloc=dbo.Eom(convert(datetime,str(@LunaBloc,2)+'/01/'+str(@AnulBloc,4)))

select @data=xA.row.value('@data', 'datetime'), @tip=xA.row.value('@tip', 'varchar(20)'), @subtip=xA.row.value('@subtip', 'varchar(20)'), 
@datajos=dbo.Bom(isnull(xA.row.value('@datajos','datetime'),isnull(xA.row.value('@data','datetime'),'01/01/1901'))), 
@datasus=dbo.Eom(isnull(xA.row.value('@datasus','datetime'),isnull(xA.row.value('@data','datetime'),'12/31/2999'))),
@f_dencor=xA.row.value('@f_dencor','varchar(50)'), @tipcor=xA.row.value('@tipcor','varchar(2)'),
@f_salariat=xA.row.value('@f_salariat','varchar(50)')
from @parXML.nodes('row') as xA(row) 

/*	Nu mai apelam aici procedura de scriere in istpers. Am apelat scrierea in istpers la adaugarea corectiilor pe marca. 
	Am tratat astfel pentru a nu modifica datele din istpers daca se deschid luni inchise.
exec wScriuIstPers @sesiune, @parXML
*/
-- selectez tipurile de corectii pe care exista date operate
select @tip as tip, (case when @tip='CT' then 'C2' when @tip='CN' then 'C4' when @tip='CL' then 'C5' end) as subtip, 
(case when @tip='CT' then 'Corectii' when @tip='CN' then 'Corectii nete' when @tip='CL' then 'Corectii pe locuri de munca' end) as densubtip, 
convert(char(10),dbo.EOM(c.Data),101) as data, 
c.tip_corectie_venit as tipcor, (case when @subtipcor=1 then max(isnull(s.denumire,'')) else max(isnull(t.denumire,'')) end) as dentipcor, 
rtrim(rtrim(max(f.LunaAlfa))+' '+convert(char(4),max(f.An))) as luna, 
isnull(count(distinct c.marca),0) as nrsal, 
isnull(count(distinct c.loc_de_munca),0) as nrlm, 
sum(convert(decimal(12,2),isnull((case when (@tip='CN' or @CorectiiNete=0) then c.Suma_neta else 0 end),0))) as sumaneta, 
sum(convert(decimal(12,2),isnull((case when @tip='CT' or @tip='CL' then c.Suma_corectie else 0 end),0))) as sumacorectie,
(case when dbo.EOM(c.Data)<=@DataInch then '#808080' else '#000000' end) as culoare,
(case when dbo.EOM(c.Data)<=@DataInch or dbo.EOM(c.Data)<=@DataBloc then 1 else 0 end) as _nemodificabil
from corectii c 
	left outer join subtipcor s on c.tip_corectie_venit=s.subtip
	left outer join tipcor t on c.tip_corectie_venit=t.tip_corectie_venit
	left outer join istpers i on i.Data=dbo.eom(c.Data) and i.Marca=c.Marca
	left outer join lm lm on lm.Cod=i.Loc_de_munca
	left outer join LMFiltrare lu on lu.utilizator=@userASiS --and c.Loc_de_munca=lu.cod
	and (@tip in ('CT','CN') and i.Loc_de_munca=lu.cod or @tip in ('CL') and c.Loc_de_munca=lu.cod)
	inner join fCalendar (@datajos, @datasus) f on f.Data=dbo.eom(c.Data)
where @tip in ('CT','CN','CL') and (@f_tipcor is null or c.tip_corectie_venit=@f_tipcor) 
	and c.data between @datajos and @datasus and (@data is null or c.data=@data)
	and (@f_dencor is null or (case when @subtipcor=1 then s.denumire else t.denumire end) like '%'+@f_dencor+'%') 
	and ((@tip='CT' and (c.suma_neta=0 or @CorectiiNete=0) or @tip='CN' and c.suma_neta<>0) and c.marca<>'' or @tip in ('CL') and c.Marca='')
	and (@tipcor is null or c.tip_corectie_venit=@tipcor)
	and (@f_salariat is null or i.Nume like '%'+@f_salariat+'%' or c.Marca like @f_salariat+'%')
	and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
group by dbo.EOM(c.Data), c.tip_corectie_venit 
-- selectez tipurile de corectii pe care nu exista date operate (prin diferenta)
union all
select @tip as tip, (case when @tip='CT' then 'C2' when @tip='CN' then 'C4' when @tip='CL' then 'C5' end) as subtip, 
(case when @tip='CT' then 'Corectii' when @tip='CN' then 'Corectii nete' when @tip='CL' then 'Corectii pe locuri de munca' end) as densubtip, 
convert(char(10),@datasus,101) as data, t.tip_corectie_venit as tipcor, max(t.denumire) as dentipcor, 
rtrim(rtrim(max(c.LunaAlfa))+' '+convert(char(4),max(c.An))) as luna, 
0 as nrsal, 0 as nrlm, 0 as sumaneta, 0 as sumacorectie,
(case when @datasus<=@DataInch then '#808080' else '#000000' end) as culoare,
(case when @datasus<=@DataInch or @datasus<=@DataBloc then 1 else 0 end) as _nemodificabil
from tipcor t 
	inner join fCalendar (@datasus, @datasus) c on c.Data=@datasus
where @tip in ('CT','CN','CL') and @subtipcor=0 and (@f_tipcor is null or t.tip_corectie_venit=@f_tipcor) 
	and (@tip='CT' or @tip='CN' and (tip_corectie_venit in ('D-','H-','K-','I-','J-','O-','F-','L-','X-','Y-','Z-','AI') or tip_corectie_venit='J-' and @CAS_J=1)
		or @tip='CL' and tip_corectie_venit not in ('R-','P-','N-','Q-'))
	and t.tip_corectie_venit not in (select c.tip_corectie_venit from corectii c 
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and c.Loc_de_munca=lu.cod
		where c.data between @datajos and @datasus and (@data is null or c.data=@data) 
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
		and ((@tip='CT' and (c.suma_neta=0 or @CorectiiNete=0) or @tip='CN' and c.suma_neta<>0) 
		and c.marca<>'' or @tip in ('CL') and c.Marca=''))
	and (@f_dencor is null or t.denumire like '%'+@f_dencor+'%')
	and (@tipcor is null or t.tip_corectie_venit=@tipcor)
group by t.tip_corectie_venit
order by Data, tipcor
for xml raw
