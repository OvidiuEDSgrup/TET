create procedure yso_populezDateGenDoc @sesiune varchar(50), @parXML xml OUTPUT
as		
	declare @contract varchar(20),@mesaj varchar(500),@tip varchar(2), @subtip varchar(2),@tert varchar(13),@data datetime,@sub varchar(9),
		@gestiune varchar(20),@gestprim varchar(20),@categPret varchar(13),@numarDoc varchar(13), @dataDoc varchar(10),@tipDoc varchar(2),
		@utilizator varchar(20),@stare int, @dentert varchar(200)
		, @numedelegat varchar(200), @nrformular varchar(10), @denformular varchar(100), @iddelegat varchar(10), @prenumedelegat varchar(100)
		, @nrmijltransp varchar(13),@serieCI varchar(50), @numarCI varchar(50), @eliberatCI varchar(50), @observatii varchar(200)
		, @mijloctp varchar(50), @denmijloctp varchar(200), @modPlata varchar(50)

	select @tip=ISNULL(@parXML.value('(/*/@tip)[1]', 'varchar(2)'), ''),
		@contract=ISNULL(@parXML.value('(/*/@numar)[1]', 'varchar(20)'), ''),
		@tert=upper(ISNULL(@parXML.value('(/*/@tert)[1]', 'varchar(20)'), '')),
		@data=ISNULL(@parXML.value('(/*/@data)[1]', 'datetime'), ''),
		@stare=upper(ISNULL(@parXML.value('(/*/@stare)[1]', 'int'), 0)),
		@gestiune=ISNULL(@parXML.value('(/*/@gestiune)[1]', 'varchar(20)'), ''),
		@gestprim=ISNULL(@parXML.value('(/*/@gestprim)[1]', 'varchar(20)'), '')
		
	set @tipdoc=ISNULL((select top (1) tipdoc from #dateGenDoc), 'AP')

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output-->identificare utilizator pe baza sesiunii
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output --> citire subunitate din proprietati     
		
	select	@nrformular=(case when p.Cod_proprietate='UltFormGenBK'+@tipDoc then rtrim(p.Valoare) else isnull(@nrformular,'') end)
	from proprietati p
	where p.Tip='PROPUTILIZ' and p.Cod=@utilizator and p.Valoare_tupla=''
		and P.Cod_proprietate in ('UltFormGenAP'+@tipDoc)
	
	select @iddelegat=rtrim(p.Valoare) from proprietati p where p.tip='TERT' and p.cod=@Tert and p.cod_proprietate='UltDelegat' and p.Valoare<>''
	select @nrmijltransp=rtrim(p.Valoare) from proprietati p where p.tip='TERT' and p.cod=@tert and p.cod_proprietate='UltMasina' and p.Valoare<>''
	--select @modPlata=rtrim(p.Valoare) from proprietati p where p.tip='TERT' and p.cod=@tert and p.cod_proprietate='UltModPlataAPBK' and p.Valoare<>''
	
	select	@dentert=RTRIM(t.Denumire)
		, @numeDelegat = c.Pers_contact+SPACE(50)+c.Nume_delegat+convert(char(3),dbo.fStrToken(c.buletin, 1, ','))+convert(char(9),dbo.fStrToken(c.buletin, 2, ','))+c.eliberat--rtrim(isnull(c.Descriere,i.Nume_delegat))
		, @prenumedelegat = rtrim(c.Nume_delegat)
		, @serieCI = dbo.fStrToken(c.buletin, 1, ','), @numarCI = dbo.fStrToken(c.buletin, 2, ','), @eliberatCI = RTRIM(c.eliberat)
	from terti t 
		left join infotert i on i.Subunitate=t.Subunitate and i.Tert=t.Tert and i.Identificator=''
		left join infotert c on c.Subunitate='C'+t.Subunitate and c.Tert=t.Tert and c.Identificator=@idDelegat
	where t.Subunitate=@sub and t.tert=@tert 
	
	select @mijloctp=rtrim(m.Descriere) , @denmijloctp=convert(char(10),m.Numarul_mijlocului)+space(50)+convert(char(30),m.Descriere) 
	from masinexp m where m.Numarul_mijlocului=@nrmijltransp --and m.Furnizor=@tert
		
	select @denformular=RTRIM(f.Denumire_formular)
	FROM antform f
	WHERE f.Numar_formular=@nrformular
	
	select @numardoc=rtrim(c.Factura), @datadoc=convert(varchar,f.Data,101) 
	from con c 
		left join facturi f on f.Subunitate=c.Subunitate and f.Tip=0x46 and f.Tert=c.Tert and f.Factura=c.Factura and f.Factura<>''
	where c.Subunitate=@sub and c.Tip=@tip and c.Data=@data and c.Contract=@contract and c.Tert=@tert

	delete from #dateGenDoc
	insert into #dateGenDoc
	SELECT  @tipDoc AS tipdoc, @numardoc AS numardoc, @datadoc AS datadoc
		, rtrim(@tert) as tert, @tert+ ' - ' +rtrim(@dentert)  as dentert
		, iddelegat=isnull(@iddelegat,''), isnull(@numedelegat,@utilizator) numedelegat, isnull(@prenumedelegat,'') prenumedelegat
		, isnull(@nrmijltransp,rtrim(dbo.wfProprietateUtilizator('NrAuto',@utilizator))) nrmijltransp, @denmijloctp denmijloctp, @mijloctp mijloctp
		, isnull(@serieCI,dbo.wfProprietateUtilizator('SerieCI',@utilizator)) seriebuletin
		, isnull(@numarCI,rtrim(dbo.wfProprietateUtilizator('NumarCI',@utilizator))) numarbuletin
		, isnull(@eliberatCI,rtrim(dbo.wfProprietateUtilizator('EliberatCI',@utilizator))) eliberatbuletin	
		, observatii=@observatii
		, data_expedierii=convert(varchar,GETDATE(),101), ora_expedierii=left(convert(varchar,getdate(),114),8)
		, modPlata=@modPlata
		, nrformular=@nrformular, denformular=@denformular