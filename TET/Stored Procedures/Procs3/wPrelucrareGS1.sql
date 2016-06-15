
CREATE PROCEDURE wPrelucrareGS1 @sesiune varchar(50), @parXML xml  
AS
BEGIN TRY
	IF OBJECT_ID('tempdb.dbo.#documente') IS NULL
		return

	declare
		@com_sql nvarchar(max), @id_sql int, @codgs1 varchar(1000)

	IF OBJECT_ID('tempdb.dbo.#updategs1') IS NOT NULL
		drop table #updategs1

	create table #updategs1 (id int identity,comanda_sql nvarchar(4000), codgs1 varchar(1000))

	/* Pentru liniile care au GS1 decodam continutul in tabelul (coloana, valoare)*/
	while EXISTS (select 1 from #documente d LEFT JOIN #updategs1 dg on d.codgs1=dg.codgs1 where dg.codgs1 is null)
	begin
		select @codgs1 = d.codgs1 from #documente d LEFT JOIN #updategs1 dg on d.codgs1=dg.codgs1 where dg.codgs1 is null

		insert into #updategs1(comanda_sql, codgs1 )
		select
			'update #documente set ' +
				coloana_asis +'= '+ ''''+valoare +''''+
			' where codgs1= ''' + @codgs1+'''', @codgs1
		from dbo.wfDecodareGS1(@codgs1) where coloana_asis is not null
	end

	/* Generam si executam intruct. SQL dinamice pt. actulizarea #documente */
	select @com_sql = ''
	select @com_sql = @com_sql + comanda_sql +char(13) from #updategs1
	exec sp_executesql @statement=@com_sql

	/* Daca citim un GS1 noi stim cod de bare => stim cod produs, pe care il completam in #documente*/
	update d
		set cod=cb.cod_produs
	from #documente d
	JOIN codbare cb on d.barcod=cb.cod_de_bare
	where ISNULL(d.cod,'')=''

END TRY
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch
