
CREATE PROCEDURE wIaMeniuUtiliz @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @utilizator VARCHAR(50), @f_descriere VARCHAR(100), @f_sigrupe bit
	,@f_id varchar(100), @f_alocat varchar(100)

Select @utilizator = @parXML.value('(/row/@utilizator)[1]', 'varchar(50)')
	,@f_descriere = '%' + replace(isnull(@parXML.value('(/row/@f_descriere)[1]', 'varchar(100)'), ''),' ','%') + '%'
	,@f_id= @parXML.value('(/row/@f_id)[1]', 'varchar(100)')
	,@f_alocat= @parXML.value('(/row/@f_alocat)[1]', 'varchar(100)')
	,@f_sigrupe=1--(case when isnull(@parXML.value('(row/@f_sigrupe)[1]','varchar(100)'),'')='' then 0 else 1 end)

select @f_alocat=(case isnull(@f_alocat,'') when 'Da' then 1 when 'Nu' then 0 else @f_alocat end)

select @utilizator IdUtilizator, w.Meniu, 
		(case when max(charindex('S',w.Drepturi))>0 then 1 else 0 end) as sterg,
		(case when max(charindex('A',w.Drepturi))>0 then 1 else 0 end) as adaug,
		(case when max(charindex('M',w.Drepturi))>0 then 1 else 0 end) as modific,
		(case when max(charindex('F',w.Drepturi))>0 then 1 else 0 end) as formular,
		(case when max(charindex('O',w.Drepturi))>0 then 1 else 0 end) as operatii,
			--> in acest punct in et... se iau id-uri ale primelor grupe pt care exista drepturi:
		convert(varchar(200),max(case when charindex('S',w.Drepturi)>0 then f.grupa else '' end)) etSterg,
		convert(varchar(200),max(case when charindex('A',w.Drepturi)>0 then f.grupa else '' end)) etAdaug,
		convert(varchar(200),max(case when charindex('M',w.Drepturi)>0 then f.grupa else '' end)) etModific,
		convert(varchar(200),max(case when charindex('F',w.Drepturi)>0 then f.grupa else '' end)) etFormular,
		convert(varchar(200),max(case when charindex('O',w.Drepturi)>0 then f.grupa else '' end)) etOperatii,
			--> in urm 5 campuri se determina daca exista fiecare drept pentru utilizator daca am ignora grupele:
		max(case when charindex('S',w.Drepturi)>0 and f.grupa=@utilizator then 1 else 0 end) aveaS,
		max(case when charindex('A',w.Drepturi)>0 and f.grupa=@utilizator then 1 else 0 end) aveaA,
		max(case when charindex('M',w.Drepturi)>0 and f.grupa=@utilizator then 1 else 0 end) aveaM,
		max(case when charindex('F',w.Drepturi)>0 and f.grupa=@utilizator then 1 else 0 end) aveaF,
		max(case when charindex('O',w.Drepturi)>0 and f.grupa=@utilizator then 1 else 0 end) aveaO,
		convert(varchar(20),'') culoare,
	max(f.grupa) grupa
into #webConfigMeniuUtiliz from webConfigMeniuUtiliz w inner join fIaGrupeUtilizator(@utilizator) f on w.IdUtilizator=f.grupa
	where @f_sigrupe=1 or f.grupa=@utilizator
group by w.Meniu

update w set culoare=(CASE when @f_sigrupe=0 or (aveaS=1 or sterg=0) and (aveaA=1 or adaug=0) and (aveaM=1 or modific=0) and (aveaF=1 or formular=0) and (aveaO=1 or operatii=0) then '#008000' ELSE '#0000FF' END),
		etSterg=(case when sterg=1 then 'Da'+(case when aveaS=1 then '' else ' ('+etSterg+')' end) else 'Nu' end),
		etAdaug=(case when adaug=1 then 'Da'+(case when aveaA=1 then '' else ' ('+etAdaug+')' end) else 'Nu' end),
		etModific=(case when modific=1 then 'Da'+(case when aveaM=1 then '' else ' ('+etModific+')' end) else 'Nu' end),
		etFormular=(case when formular=1 then 'Da'+(case when aveaF=1 then '' else ' ('+etFormular+')' end) else 'Nu' end),
		etOperatii=(case when operatii=1 then 'Da'+(case when aveaO=1 then '' else ' ('+etOperatii+')' end) else 'Nu' end)
from #webConfigMeniuUtiliz w

--> filtrare; regula de aur: orice se incadreaza in filtrare va fi luat impreuna cu nivelurile sale superioare si inferioare
create table #meniurifiltrate(meniu varchar(1000), meniuparinte varchar(1000), filtrat bit)	--> filtrat=1 semnaleaza acele meniuri care respecta direct filtrele
	--> filtrarea:
insert into #meniurifiltrate(meniu, meniuparinte, filtrat)
	select m.meniu, m.meniuparinte,1 from webconfigmeniu m
		left join webconfigmeniuutiliz u on u.meniu=m.meniu and u.idutilizator=@utilizator
	where Nume LIKE @f_descriere and (@f_id is null or m.meniu like @f_id)
		and (@f_alocat is null or @f_alocat=1 and u.drepturi is not null or @f_alocat=0 and u.drepturi is null)
	--> selectarea nivelurilor inferioare:
insert into #meniurifiltrate(meniu, meniuparinte, filtrat)
	select meniu, meniuparinte,0 from webconfigmeniu m where exists (select 1 from #meniurifiltrate mf where mf.meniuparinte=m.meniu and mf.meniu<>'' and mf.filtrat=1)
		and m.meniuparinte=''
		and not exists (select 1 from #meniurifiltrate b where b.meniu=m.meniu)
	--> selectarea nivelurilor superioare:
insert into #meniurifiltrate(meniu, meniuparinte, filtrat)
	select meniu, meniuparinte,0 from webconfigmeniu m where exists (select 1 from #meniurifiltrate mp where mp.meniu=m.meniuparinte and mp.meniu<>'' and mp.meniuparinte='' and mp.filtrat=1)
		and not exists (select 1 from #meniurifiltrate b where b.meniu=m.meniu)

declare @_expandat varchar(100)
set @_expandat='nu'
if (select count(1) from #meniurifiltrate)<25
set @_expandat='da'


SELECT (
		SELECT @utilizator AS utilizator, wcm.Meniu AS id, wcm.nrordine as nrordine, RTRIM(wcm.Nume) AS descriere,
				isnull(wcmu.etSterg,'Nu') AS sterg, isnull(wcmu.etAdaug,'Nu') AS adaug, isnull(wcmu.etModific,'Nu') AS modific,
					isnull(wcmu.etOperatii,'Nu') AS operatii, isnull(wcmu.etFormular,'Nu') AS formulare,
				wcmu.sterg AS dsterg, wcmu.adaug AS dadaug, wcmu.modific AS dmodific, wcmu.operatii AS doperatii, wcmu.formular AS dformulare,
				(CASE WHEN wcmu.IdUtilizator IS NULL THEN 0 ELSE 1 END) AS alocat,
					--(CASE WHEN wcmu.IdUtilizator IS NULL THEN '#FF0000' ELSE '#008000' END
				(case WHEN IdUtilizator IS NULL THEN '#FF0000' else wcmu.culoare end) AS culoare,
				(
					SELECT @utilizator AS utilizator, wcm1.Meniu AS id, wcm1.nrordine AS nrordine, RTRIM(wcm1.Nume) AS descriere, 
					isnull(wcmu1.etSterg,'Nu') AS sterg, isnull(wcmu1.etAdaug,'Nu') AS adaug, isnull(wcmu1.etModific,'Nu') AS modific,
						isnull(wcmu1.etOperatii,'Nu') AS operatii, isnull(wcmu1.etFormular,'Nu') AS formulare,
					wcmu1.sterg AS dsterg, wcmu1.adaug AS dadaug, wcmu1.modific AS dmodific, wcmu1.operatii AS doperatii, wcmu1.formular AS dformulare,
					(CASE WHEN wcmu1.IdUtilizator IS NULL THEN 0 ELSE 1 END) AS alocat,
								(case WHEN IdUtilizator IS NULL THEN '#FF0000' else wcmu1.culoare end) AS culoare
					FROM webConfigMeniu wcm1 inner join #meniurifiltrate m on wcm1.meniu=m.meniu
					LEFT JOIN #webConfigMeniuUtiliz wcmu1 ON wcmu1.meniu = wcm1.meniu
					--	AND wcmu1.IdUtilizator = @utilizator
					WHERE/* wcm1.Nume LIKE @f_descriere
						AND*/ wcm1.meniuParinte = wcm.meniu
					order by nrordine
					FOR XML raw, type
				), @_expandat _expandat
		FROM webConfigMeniu wcm inner join #meniurifiltrate m on wcm.meniu=m.meniu
		LEFT JOIN #webConfigMeniuUtiliz wcmu ON wcmu.Meniu = wcm.meniu
			--AND wcmu.IdUtilizator = @utilizator
		WHERE /*wcm.Nume LIKE @f_descriere
			AND*/ wcm.meniuparinte=''
			and exists (select 1 from webConfigMeniu w where wcm.meniu=w.meniuparinte)
			and (wcm.meniu<>'')
		order by nrordine
		FOR XML raw, root('Ierarhie'), type
		)
FOR XML path('Date')

if object_id('tempdb..#webConfigMeniuUtiliz') is not null drop table #webConfigMeniuUtiliz
