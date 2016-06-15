--***
Create procedure wIaRetineri @sesiune varchar(50), @parXML xml
as  
set transaction isolation level READ UNCOMMITTED
declare @userASiS varchar(10), @LunaInch int, @AnulInch int, @DataInch datetime, @LunaBloc int, @AnulBloc int, @DataBloc datetime, 
@tip varchar(2), @subtip varchar(2), @codbenef varchar(13), @f_codbenef varchar(13), @f_denbenef varchar(50), @f_salariat varchar(50),
@data datetime, @datajos datetime, @datasus datetime

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
set @LunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
set @AnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
set @DataInch=dbo.Eom(convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4)))

set @LunaBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNABLOC'), 1)
set @AnulBloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANULBLOC'), 1901)
set @DataBloc=dbo.Eom(convert(datetime,str(@LunaBloc,2)+'/01/'+str(@AnulBloc,4)))

select @data=xA.row.value('@data', 'datetime'), @tip=xA.row.value('@tip', 'varchar(2)'), @subtip=xA.row.value('@subtip', 'varchar(2)'), 
@codbenef=xA.row.value('@codbenef','varchar(13)'), 
@f_codbenef=xA.row.value('@f_codbenef','varchar(13)'), @f_denbenef=xA.row.value('@f_denbenef','varchar(50)'), 
@datajos=dbo.Bom(isnull(xA.row.value('@datajos','datetime'),isnull(xA.row.value('@data','datetime'),'01/01/1901'))), 
@datasus=dbo.Eom(isnull(xA.row.value('@datasus','datetime'),isnull(xA.row.value('@data','datetime'),'12/31/2999'))),
@f_salariat=xA.row.value('@f_salariat','varchar(50)')
from @parXML.nodes('row') as xA(row) 

/*	Nu mai apelam aici procedura de scriere in istpers. Am apelat scrierea in istpers la adaugarea retinerilor pe marca. 
	Am tratat astfel pentru a nu modifica datele din istpers daca se deschid luni inchise.
exec wScriuIstPers @sesiune, @parXML
*/

select @tip as tip, 'R2' as subtip, '' as densubtip, convert(char(10),isnull(r.data,@datasus),101) as data, 
rtrim(rtrim(max(c.LunaAlfa))+' '+convert(char(4),max(c.An))) as luna, 
r.cod_beneficiar as codbenef, max(b.denumire_beneficiar) as denbenef, isnull(count(distinct r.marca),0) as nrsal, 
sum(convert(decimal(12,2),isnull(r.Retinere_progr_la_lichidare,0))) as progrlich, 
sum(convert(decimal(12,2),isnull(r.Retinut_la_lichidare,0))) as retinutlich,
(case when r.Data<=@DataInch then '#808080' else '#000000' end) as culoare,
(case when r.Data<=@DataInch or r.Data<=@DataBloc then 1 else 0 end) as _nemodificabil
from resal r 
	left outer join benret b on b.cod_beneficiar=r.cod_beneficiar
	left outer join istpers i on r.Data=i.Data and r.Marca=i.Marca
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and i.Loc_de_munca=lu.cod
	inner join fCalendar (@datajos, @datasus) c on c.Data=r.Data 
where @tip='RE' and (@f_codbenef is null or r.Cod_beneficiar=@f_codbenef)  
	and r.data between @datajos and @datasus and (@data is null or isnull(r.data,@datasus)=@data)
	and (@f_denbenef is null or b.denumire_beneficiar like '%'+@f_denbenef+'%')
	and (@codbenef is null or r.Cod_beneficiar=@codbenef)
	and (@f_salariat is null or i.Nume like '%'+@f_salariat+'%' or r.Marca like @f_salariat+'%')
	and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
group by r.data, r.cod_beneficiar 
union all
select @tip as tip, 'R2' as subtip, '' as densubtip, convert(char(10),@datasus,101) as data, 
rtrim(rtrim(max(c.LunaAlfa))+' '+convert(char(4),max(c.An))) as luna, 
b.cod_beneficiar as codbenef, max(b.denumire_beneficiar) as denbenef, 0 nrsal, 0 as progrlich, 0 as retinutlich,
(case when @datasus<=@DataInch then '#808080' else '#000000' end) as culoare,
(case when @datasus<=@DataInch or @datasus<=@DataBloc then 1 else 0 end) as _nemodificabil
from benret b 
	inner join fCalendar (@datasus, @datasus) c on c.Data=@datasus
where @tip='RE' and (@f_codbenef is null or b.Cod_beneficiar=@f_codbenef) 
	and (@f_denbenef is null or b.denumire_beneficiar like '%'+@f_denbenef+'%')
	and (@codbenef is null or b.Cod_beneficiar=@codbenef)
	and not exists 
	(select cod_beneficiar from resal r 
		left outer join personal p on r.Marca=p.Marca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and p.Loc_de_munca=lu.cod
	where r.data=@datasus and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null) and r.Cod_beneficiar=b.cod_beneficiar
		and (@data is null or r.data=@data)) 
group by b.cod_beneficiar
for xml raw
