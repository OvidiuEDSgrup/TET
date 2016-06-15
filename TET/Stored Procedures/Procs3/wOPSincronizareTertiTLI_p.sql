create  procedure wOPSincronizareTertiTLI_p @sesiune varchar(50), @parXML xml
as
begin try
	DECLARE 
		@rezultatRequest xml, @comanda_cmd nvarchar(4000), @caleServer varchar(max), @codfiscal varchar(100), @mesaj varchar(max), @docXML xml,
		@cale_form VARCHAR(200)

	select @codfiscal=RTRIM(ltrim((replace(val_alfanumerica,'RO',''))))
	from par where Tip_parametru='GE' and Parametru='CODFISC'

	if isnull(@codfiscal,'')=''
		raiserror('Codul fiscal al unitatii nu este completat! Va rugam completati parametrul "CODFISC" din configurari!',11, 1)
	
	select 
		@rezultatRequest=convert(xml,dbo.httpget('http://mfinante.asis.ro/handlere/SincronizareTerti.ashx?codfiscal='+@codfiscal))
	select top 1 
		@cale_form = rtrim(val_alfanumerica) from par where parametru='caleform'
	
	if @rezultatRequest.value('(/result/status)[1]','varchar(100)') <>'Success'
		raiserror('Nu s-a putut stabili legatura cu serverul Alfa Software pentru sincronizarea tertilor ',11,1)
	else
	begin
		begin try
			
			set @caleServer=@cale_form+'\terti.txt'

			IF OBJECT_ID('tempdb..##tertiPreluare') is not null
				drop table ##tertiPreluare
			create table ##tertiPreluare (string_raspuns varchar(max))

			INSERT into ##tertiPreluare(string_raspuns) 
			select rtrim(ltrim(@rezultatRequest.value('(/result/message)[1]','varchar(max)')))

			declare @nServer varchar(1000)
			select	@nServer=convert(varchar(1000),serverproperty('ServerName'))
			SET @comanda_cmd = 'bcp "select string_raspuns from ##tertiPreluare" queryout "'+@caleServer+'" -c -t, -r; -T -S'+@nServer
			EXEC master..XP_CMDSHELL @comanda_cmd 

			IF OBJECT_ID('tempdb..##tertiRepreluati') is not null
				drop table ##tertiRepreluati
			create table ##tertiRepreluati(codfiscal varchar(100), tiptva varchar(1), dela datetime, panala datetime)

			set @comanda_cmd='bulk insert ##tertiRepreluati	from  ''' +@caleServer+ '''  with (fieldterminator = '','', rowterminator = '';'' )'
			exec sp_executesql  @statement=@comanda_cmd
		end try
		begin catch
			/** Daca sunt erori sau ceva la preluare poate exista posiblitatea sa fie in TvaPeTertiASW ceva date care trebuie prelucrate chiar daca
				sesiunea curenta a avut erori...
			**/
			declare
				@errm varchar(200)
			select @errm = ERROR_MESSAGE()
			RAISERROR(@errm, 16, 1)

		end catch
		if exists (select 1 from sysobjects where name ='TvaPeTertiASW')
		BEGIN
			drop table TvaPeTertiASW
		END
			CREATE table TvaPeTertiASW (codfiscal varchar(100), tiptva varchar(1), dela datetime, panala datetime, tiptva_local varchar(1), tert varchar(20))

		delete from TvaPeTertiASW
		where codfiscal in (select codfiscal from ##tertiRepreluati )
		
		delete t from ##tertiRepreluati t LEFT JOIN Terti ti on rtrim(ltrim(replace(ti.Cod_fiscal,'RO','')))=t.codfiscal
		where ti.tert is null		
		
		insert into TvaPeTertiASW(codfiscal,tiptva,dela,panala, tiptva_local, tert)
		SELECT distinct t.codfiscal, ISNULL(t.tiptva,'P'), dela, panala, ISNULL(cl.tip_tva,'P'), tl.tert
		from ##tertiRepreluati t
		JOIN terti tl on rtrim(ltrim(replace(tl.Cod_fiscal,'RO','')))=t.codfiscal
		LEFT JOIN
		(
			select	
				tert, tip_tva, rank() over (partition by tert order by dela desc ) rn
			from TvaPeTerti where factura is null and tipf='F'
		) cl on tl.tert=cl.tert and cl.rn=1
		
		delete TvaPeTertiASW where tiptva=tiptva_local

		insert into TvaPeTertiASW(codfiscal, tiptva, dela, panala, tiptva_local, tert)
		select
			t.cod_fiscal, 'P', '1901-01-01', '1901-01-01', cl.tip_tva, t.tert
		from Terti t
		JOIN
		(
			select	
				tert, tip_tva, rank() over (partition by tert order by dela desc ) rn
			from TvaPeTerti where factura is null and tipf='F'
		) cl on t.tert=cl.tert and cl.rn=1
		LEFT JOIN ##tertiRepreluati tr on rtrim(ltrim(replace(t.Cod_fiscal,'RO','')))=tr.codfiscal
		where tr.codfiscal is null and cl.tip_tva = 'I'


		IF OBJECT_ID('tempdb.dbo.#date_p') IS NOT NULL
			DROP TABLE #date_p
		
		SELECT
			t.codfiscal codfiscal, rtrim(tl.denumire) dentert, 
			(case when t.tiptva='I' then convert(varchar(10), t.dela, 101) else convert(varchar(10), t.panala, 101) end) dela, 
			(case when t.tiptva='I' then 'Da' else 'Nu' end) tli, 1 actualizeaza, t.tert tert,
			t.tiptva
		INTO #date_p
		FROM TvaPeTertiASW t
		JOIN terti tl on tl.tert=t.tert	

		set @docXML= (select (select * from #date_p	order by (case when tiptva='I' then 'Da' else 'Nu' end) FOR XML raw, type) FOR XML path('DateGrid'), root('Mesaje'))
	
		IF @docXML.exist('/Mesaje/DateGrid/row')<>1
			select 
				'Nu exista actualizari pentru tertii din baza dvs. de date!' as textMesaj, 'Notificare' as titluMesaj,
				'1' as inchideFereastra
			for xml raw, root('Mesaje')
		else
			select @docXML
		
	end
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (wOPSincronizareTertiTLI_p)'
	select '1' as inchideFereastra
	for xml raw, root('Mesaje')

	raiserror (@mesaj, 11, 1)
end catch