set transaction isolation level read uncommitted 
select rtrim(pozplin.Numar) as [DOC], rtrim(convert(char(10),max(pozplin.Data),103)) as [DATA], rtrim(ISNULL(max(personal.Nume),'')) as [NUME], rtrim(ISNULL(max(functii.denumire),'')) as [FUNCTIA], rtrim(SUM(pozplin.suma)) as [SUMA], rtrim('') as [SUMALITERE], rtrim(MAX(pozplin.Explicatii)) as [EXPLICATII], rtrim(ISNULL(max(LEFT(personal.copii,2)),'')) as [SERIA], rtrim(ISNULL(max(right(rtrim(personal.copii),6)),'')) as [NR]
 into ##raspASIS 
FROM pozplin cross join avnefac left join personal on pozplin.cont_dif = personal.Marca left join functii on personal.Cod_functie = functii.Cod_functie
WHERE WHERE pozplin.Numar = avnefac.Numar and pozplin.Data = avnefac.data and avnefac.Tip = 'LC'
and avnefac.terminal='ASIS' 
group by pozplin.Numar 
--set @maxrand = isnull((select count(*) from ##raspASIS),0)

select * from avnefac where Terminal='asis'