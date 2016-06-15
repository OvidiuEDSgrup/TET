
CREATE PROCEDURE wIaRapoarteUtiliz @sesiune VARCHAR(50), @parXML XML
AS
begin
declare @eroare varchar(2000)
begin try
	if object_id('tempdb..#cat') is not null drop table #cat
	if object_id('tempdb..#webConfigRapoarte') is not null drop table #webConfigRapoarte

	DECLARE @utilizator VARCHAR(50), @rap XML
	--select @utilizator='luci.maier'
	DECLARE @f_nume VARCHAR(425), @f_cale VARCHAR(100), @f_sigrupe bit

	SET @f_nume = '%' + isnull(@parXML.value('(/row/@f_nume)[1]', 'varchar(425)'), '') + '%'
	SET @f_cale = '%' + isnull(@parXML.value('(/row/@f_cale)[1]', 'varchar(425)'), '') + '%'
	SET @utilizator = @parXML.value('(/row/@utilizator)[1]', 'varchar(100)')
	set @f_sigrupe=1--=(case when isnull(@parXML.value('(row/@f_sigrupe)[1]','varchar(100)'),'')='' then 0 else 1 end)

	declare @subarb table(caleraport varchar(4000), nume varchar(500), itemid uniqueidentifier,
			type int, sub xml, alocat bit, denalocat varchar(100), culoare varchar(10), grupa varchar(50), nivel int, ParentId uniqueidentifier, ordine int)
	declare @nivel int
	select @nivel=1

	--> pregatire drepturi rapoarte pe utilizator si grupe incluse:
	select w.caleRaport, max(f.grupa) grupa,
			max(case when f.grupa=@utilizator then 1 else 0 end) as peUtilizator
		into #webConfigRapoarte
		from fIaGrupeUtilizator(@utilizator) f inner join webConfigRapoarte w on f.grupa=w.utilizator
		where @f_sigrupe=1 or 
			f.grupa=@utilizator
	group by w.caleRaport

	--> trebuie o mica prelucrare pentru a rezolva recursivitatea xml-ului dorit intr-un mod iterativ:
	select r.ItemID, r.ParentID, r.name, r.path, r.type, 0 as nivel into #cat
		from reportserver..catalog r
	order by path
	update r set nivel=1 from #cat r where r.ParentID is null

	--> prelucrarea: se desemneaza etajul fiecarui nod al arborelui (de la radacina=1 in jos) ca sa se asigure sincronizarea crearii subarborilor
		-->	(ca nu cumva un xml sa se creeze pe jumatate pentru ca intre timp vreun subarbore al lui nu a ajuns sa se finalizeze)
	while exists (select 1 from #cat r where r.nivel=0)
	begin
		update r
			set nivel=@nivel+1
		from #cat r inner join #cat p on r.ParentID=p.ItemID
		where p.nivel=@nivel
		
		set @nivel=@nivel+1
	end
		--> compunere structura xml; doar radacina va fi luata ca va contine rezultatul dorit; datele se parcurg invers fata de bucla anterioara
	while @nivel>0
	begin
		insert into @subarb(caleraport, nume, itemid, type, sub, alocat, denalocat, culoare, grupa, ParentId, nivel, ordine)
		select r.Path AS caleraport, r.NAME AS nume, r.ItemId AS id, r.type,
			(select @utilizator utilizator, s.caleraport, s.nume, s.itemid id, s.alocat, s.sub.query('.'), s.denalocat, s.culoare
				from @subarb s
				where r.ItemID=s.ParentId-- and s.nivel=@nivel
				order by s.caleraport
				FOR XML raw, TYPE),
			(CASE WHEN wcf.caleRaport IS NULL THEN 0 ELSE 1 END ) AS alocat,
			(CASE WHEN wcf.caleRaport IS NULL THEN 'Nu' ELSE 'Da' END)+(case when peUtilizator=0 then ' ('+wcf.grupa+')' else '' end) AS denalocat,
			(CASE WHEN wcf.caleRaport IS NULL THEN '#FF0000' when wcf.peUtilizator=0 then '#0000FF	' ELSE '#008000' END) AS culoare,'',--g.grupa
			r.ParentId, r.nivel, row_number() over (partition by r.parentid order by r.itemid)
			--*/
		FROM #cat r
			LEFT JOIN #webConfigRapoarte wcf ON
					r.Path = (convert(VARCHAR(500), wcf.caleRaport) collate SQL_Latin1_General_CP1_CI_AS)
			left join @subarb s1 on s1.ParentId=r.ItemID and s1.ordine=1
		where r.nivel=@nivel	-->	se asigura sincronizarea pentru care s-a facut prelucrarea
				AND (
						r.NAME LIKE @f_nume
						AND r.Path LIKE (convert(VARCHAR(500), @f_cale) collate SQL_Latin1_General_CP1_CI_AS)	--> filtre pe nodul curent
						OR r.Type <> 2		--> adica nodul curent nu e raport deci e director
						and s1.ordine IS NOT NULL	--> verificarea existentei subarborilor (daca exista filtrele de pe nodul curent nu trebuie sa mai aiba efect)
					)
		
		select @nivel=@nivel-1
	end

	select @rap=sub.query('.') from @subarb where nivel=1

	SET @rap = (
			SELECT @rap
			FOR XML path('Ierarhie')
			)

	IF @rap IS NOT NULL
		SET @rap.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')

	SELECT @rap
	FOR XML path('Date')
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (wIaRapoarteUtiliz '+convert(varchar(20),ERROR_LINE())+')'
end catch
if len(@eroare)>0 raiserror(@eroare, 16,1)

if object_id('tempdb..#cat') is not null drop table #cat
if object_id('tempdb..#webConfigRapoarte') is not null drop table #webConfigRapoarte
end
