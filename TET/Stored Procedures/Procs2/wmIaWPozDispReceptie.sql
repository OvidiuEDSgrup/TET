/***--
Procedura stocata citeste antetul Pozitiilor si le afiseaza culoarea in functie de stare:
(case	when MAX(ps.cantitate) > sum(po.cantitate) then '0x0000FF'
							when MAX(ps.cantitate) = sum(po.cantitate) then '0x00FF00'
						else '0x620C0C' end) as culoare,
	'#00FF00'	-->	Pozitia contine numarul exact de articole aprobate
	'#620C0C'	--> Pozitia contine mai putine articole decat numarul articolelor aprobate
	'#0000FF'	--> Pozitia contine mai multe articole decat numarul articolelor aprobate

param:	@sesiune	Sesiune utilizatorului curent, din care se identifica utilizatorul
		@parXML		Parametru xml in care vin datele. Se citeste:
					@iddisp		->	Identificator unic al dispozitiei pe care se lucreaza
					@searchText ->	Textul din autoComplete dupa care se face scanarea/cautarea
--***/
CREATE PROCEDURE wmIaWPozDispReceptie @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wmIaWPozDispReceptieSP')
begin
	declare @returnValue int
	exec @returnValue = wmIaWPozDispReceptieSP @sesiune, @parXML output
	return @returnValue
end

declare @userASiS varchar(50), @mesaj varchar(100), @raspuns varchar(max),
		@searchText varchar(100), @idDisp int,@tert varchar(13),@detalii xml,
		@actiune varchar(100), @culoarePozNeatinsa varchar(50), @culoareFinalizata varchar(50),
		@culoareSupracantitate varchar(50), @culoareInLucru varchar(50), @culoareScanareOk varchar(50),
		@culoareScanareSparturi varchar(50),@dentert varchar(50)

begin try
	/*Validare utilizator */
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

	/*Citeste variabile din parametrii */
	select	@idDisp = @parXML.value('(/row/@iddisp)[1]', 'int') ,
			@searchText =	'%' + ISNULL(REPLACE(@parXML.value('(/row/@searchText)[1]', 'varchar(100)'),' ', '%') ,'') + '%',
			@tert = @parXML.value('(/row/@tert)[1]', 'varchar(13)')

	if not exists (select * from antdisp where iddisp=@idDisp)
		--daca nu exista dispozite cu idDisp primit
	begin
		set @idDisp= isnull((select top 1 iddisp
		from AntDisp
		where utilizator=@userASiS
			and stare in ('In lucru','De scanat')),0)

		if @idDisp=0
			--daca se doreste adaugare de dispozitie noua de pe terminal, se adauga antet de dispozitie
		begin

			if @tert is null
				--pentru alegerea tertului fortam trimiterea prin catalogul de terti
			begin
				set @parXML.modify ('insert attribute wmIaTerti.procdetalii {"wmIaWPozDispReceptie"} into (/row)[1]')
				exec wmIaTerti @sesiune=@sesiune, @parXML=@parXML
				select @tert = @parXML.value('(/row/@tert)[1]', 'varchar(13)')
				return 0
			end

			set @detalii=CONVERT(xml, '<row></row>')
			set @detalii.modify ('insert (attribute tert {sql:variable("@tert")}) into (/row)[1]')

			/* daca utilizatorul are setata gestiunea si locul de munca in proprietati, se trec si pe dispozitiea de receptie*/
			declare @gestiuneProprietate varchar(13),@lmProprietate varchar(13)
			SELECT	@gestiuneProprietate = (CASE WHEN cod_proprietate = 'GESTIUNE' THEN valoare ELSE isnull(@gestiuneProprietate, '') END),
					@lmProprietate = (CASE WHEN cod_proprietate = 'LOCMUNCA' THEN valoare ELSE isnull(@lmProprietate, '') END)
			FROM proprietati
			WHERE tip = 'UTILIZATOR' AND cod = @userASiS AND cod_proprietate IN ('GESTIUNE', 'LOCMUNCA') AND valoare <> ''

			if isnull(@gestiuneProprietate,'')<>''
				set @detalii.modify ('insert attribute gestiune {sql:variable("@gestiuneProprietate")} into (/row)[1]')
			if isnull(@lmProprietate,'')<>''
				set @detalii.modify ('insert attribute lm {sql:variable("@lmProprietate")} into (/row)[1]')

			IF OBJECT_ID('tempdb..#idDisp') IS NOT NULL
			DROP TABLE #idDisp

			CREATE TABLE #idDisp (idDisp INT)

			--raiserror('Dispozitia nu poate fi identificata. Verificati atributul @iddisp in XML',11,1)
			INSERT INTO AntDisp (tipDisp, stare, detalii, utilizator, descriere, dataUltimeiOperatii)
			OUTPUT inserted.idDisp INTO #idDisp(idDisp)
			SELECT 'FC', 'In lucru', @detalii, @userASiS, '', GETDATE()

			set @idDisp=(select top 1 idDisp from #idDisp)

			/*exec wmScriuAntetDispReceptie @sesiune=@sesiune, @parXML=@parXML output
			select @idDisp = @parXML.value('(/row/@iddisp)[1]', 'int') */

			select @idDisp as '@iddisp' for xml path('atribute'),root('Mesaje')
		end
		/*else
			--daca nu se indentifica o dispozitie, si nici nu se adauga una noua, returnam mesaj de eroare
		begin
			raiserror('Dispozitia nu poate fi identificata. Verificati atributul @iddisp in XML',11,1)
			return -1
		end*/

	end
	else
	if exists (select * from antdisp where iddisp = @iddisp and stare='De scanat')
		update antDisp
			set stare='In lucru'
		where iddisp=@iddisp

	/*Citire cod bare */
	-- verific daca s-a scanat in searchText un cod de bare
	declare @codcitit varchar(100), @codScanat varchar(100)
	select	@codcitit=rtrim(@parXML.value('(/row/@searchText)[1]','varchar(100)')),
			@codcitit=REPLACE(@codcitit,'CipherLab','')

	if len(isnull(@codcitit,''))>0
	begin
		--il cautam in tabela de coduri de bare
		select @codScanat=rtrim(cb.Cod_produs) from codbare cb where cb.Cod_de_bare=@codcitit

		if @codScanat is not null --inseamna ca am gasit cod scanat
		begin
			if not exists (select * from PozDispOp where idDisp=@idDisp and cod=@codScanat)
				raiserror('Codul scanat nu exista pe aceasta dispozitie.',11,1)

			set @actiune='autoSelect'
			set @searchText='%'
		end
	end

	select	@culoarePozNeatinsa = '0x000000',
			@culoareFinalizata = '0xC3C3C3',
			@culoareSupracantitate = '0x8A0808', --'0x660033',
			@culoareInLucru = '0xF9BB00',
			@culoareScanareOk = '0x66FF33',
			@culoareScanareSparturi = '0x61210B'

	/*Raspunsul de la server */
	set @raspuns ='<Date>' + char(13);
	/*Daca nu s-a scanat, arata si meniurile*/
	if (@codScanat is null)
		begin
			set @raspuns = @raspuns +
			isnull( (	select @idDisp as cod, 'Inchidere dispozitie' as denumire, '0xFFFFFF' as culoare, 'C' as tipdetalii,
							'assets/Imagini/Meniu/pregatire.png' as poza, 'wmInchideWDispozitie' as procdetalii, '@iddisp' as numeAtr
						for xml raw),'') + char(13)
		end

	set @raspuns=@raspuns+
		-- linie cod nou:
		(select @idDisp cod, '@iddisp' numeatr, 'Adauga cod' denumire,
		'0x0000ff' as culoare,
		'C' as tipdetalii, 'wmAlegCodDispReceptie' procdetalii,
		'assets/Imagini/Meniu/AdaugProdus32.png' as poza
		for xml raw)+CHAR(13)

	declare @pozitii table(cod varchar(20), denumire varchar(100), info varchar(200), culoare varchar(50), --poza varchar(500),
		stare int, iddisp int, idpoz int, idpozscan int, codbare varchar(50), [update] char(1), actiune varchar(100), form xml)

	-- inserez toate codurile de pe dispozitie, filtrate dupa @searchText
	insert into @pozitii(cod, denumire, info, culoare, stare, codbare, iddisp, idpoz, actiune)
		select
			po.cod as cod,
			rtrim(n.Denumire) as denumire,
			ltrim(isnull(str(ps.cantitate, 10, 2 ), '0')) +/* ' / ' + ltrim(isnull(str(po.cantitate, 10, 2),'0'))+*/' '+rtrim(n.UM)/*+' scanate'*/ as info,
			(case	when isnull(ps.cantitate,0) = 0 then @culoarePozNeatinsa
					when ps.cantitate = po.cantitate then @culoareFinalizata
					when ps.cantitate > po.cantitate then @culoareSupracantitate
					else @culoareInLucru
				end) as culoare,
			(case	when isnull(ps.cantitate,0) = 0 then 0 -- neatins
					when isnull(ps.cantitate,0) < po.cantitate then -1 -- in lucru
					when isnull(ps.cantitate,0) = po.cantitate then 9 -- finalizat
					when isnull(ps.cantitate,0) > po.cantitate then 3 -- supra-cantitate
					else 0 -- nu ar trebui sa ajunga aici
				end) as stare,
			@codcitit as codBare,
			@idDisp,
			po.idPoz,
			null--'back(0)' actiune
		from PozDispOp po
		inner join nomencl n on po.cod = n.Cod
		outer apply (select idpoz, sum(cantitate) cantitate from pozdispscan ps where ps.idPoz=po.idPoz group by idPoz) ps
		where	po.idDisp = @idDisp
				and (n.denumire like @searchText or po.cod like @searchText)
				and (@codScanat is null or po.cod = @codScanat)

	-- inserez linii cu pozitiile scanate pe terminalul mobil
	-- se insereaza doar liniile aferente pozitiilor filtrate mai sus
	insert into @pozitii(cod, denumire, info, culoare, stare, codbare, iddisp, idpoz, idpozscan, form)
		select po.cod as cod,
			convert(varchar(30),ps.cantitate) + ' ' + rtrim(n.um) + ' ' + (case tipPozitie when 'cantOk' then 'ok' when 'cantSp' then 'spart' else '' end) as denumire,
			null as info,
			(case	when po.culoare=@culoareFinalizata then @culoareFinalizata
					when tipPozitie='cantOk' then @culoareScanareOk
					when tipPozitie='cantSp' then @culoareScanareSparturi
					else @culoarePozNeatinsa end) as culoare,
			po.stare as stare,
			codbare as codBare,
			@idDisp,
			po.idPoz,
			ps.idPozScan,
			dbo.f_wmIaForm(case tipPozitie when 'cantOk' then 'WO' when 'cantSp' then 'WS' else null end) as form
		from PozDispScan ps
		inner join @pozitii po on ps.idPoz=po.idPoz
		inner join nomencl n on po.cod = n.Cod


	/*Pozitii din PozDispScan*/
	set @raspuns = @raspuns +
	isnull((select *, (case
				when stare=0  then 'assets/Imagini/Meniu/AdaugProdus32.png'
				when idpozscan is not null then null --'assets/Imagini/Meniu/Functii.png'
				when stare=9 then 'assets/Imagini/Meniu/Incasare.png'
				else 'assets/Imagini/Meniu/AdaugProdus32.png'
			end) as poza
			from @pozitii
			order by stare, idpoz, idpozscan
			for xml raw) , '') + char(13)

	/*Line pentru modificare/adaugare date dispozitie receptie*/
	set @raspuns= @raspuns+
		ISNULL
		(
			(
			SELECT '<Date dispozitie de receptie>' AS denumire,
				'Descriere: ' + descriere+ CHAR(13)+
				'Factura: '+detalii.value('(/row/@factura)[1]', 'varchar(13)')+', Data fact: '+ CONVERT(char(10),detalii.value('(/row/@data_facturii)[1]', 'datetime'),101)  AS info,
				'0xFFFFFF' AS culoare ,
				'D' AS _tipdetalii,
				'wmScriuAntetDispReceptie' AS _procdetalii,
				dbo.f_wmIaForm('DR') AS 'form',
				'http://www.veryicon.com/icon/48/Business/Or%20Application/clipboard.png' as poza,
				detalii.value('(/row/@factura)[1]', 'varchar(13)') as factura,
				@idDisp AS cod,
				@idDisp AS iddisp,
				descriere as descriere,
				CONVERT(char(10),detalii.value('(/row/@data_facturii)[1]', 'datetime'),101) as data_facturii,
				detalii.value('(/row/@gestiune)[1]', 'varchar(13)') as gestiune

			FROM AntDisp
			WHERE idDisp=@idDisp
			FOR XML RAW
			),''
		)
		+CHAR(13)

	/*Line pentru modificare tert*/
	set @raspuns= @raspuns+
		ISNULL
		(
			(
			SELECT '<Actualizare Tert>' AS denumire,
				a.detalii.value('(/row/@tert)[1]', 'varchar(13)')+'-'+RTRIM(t.denumire )  AS info,
				'0xFFFFFF'AS culoare , 'C' AS _tipdetalii
				,'wmAlegClientDispReceptie' AS _procdetalii,--dbo.f_wmIaForm('DR') AS 'form',
				'http://www.veryicon.com/icon/48/Business/Real%20Vista%20Project%20Management/tester.png' as poza,
				a.detalii.value('(/row/@factura)[1]', 'varchar(13)') as factura,@idDisp AS cod, @idDisp AS iddisp,
				a.descriere as descriere, CONVERT(char(10),a.detalii.value('(/row/@data)[1]', 'datetime'),101) as data,
				null as tert,RTRIM(t.denumire ) as dentert,'ModifTert' as msg
			FROM AntDisp a
				left join terti t on a.detalii.value('(/row/@tert)[1]', 'varchar(13)') =t.tert
			WHERE idDisp=@idDisp
			FOR XML RAW
			),''
		)
		+CHAR(13)

	/*Line pentru modificare gestiune*/
	set @raspuns= @raspuns+
		ISNULL
		(
			(
			SELECT '<Actualizare Gestiune>' AS denumire,
				a.detalii.value('(/row/@gestiune)[1]', 'varchar(13)')+'-'+RTRIM(g.Denumire_gestiune )  AS info,
				'0xFFFFFF'AS culoare , 'C' AS _tipdetalii
				,'wmAlegGestiuneDispReceptie' AS _procdetalii,--dbo.f_wmIaForm('DR') AS 'form',
				'http://www.veryicon.com/icon/48/Business/Super%20Vista%20Accounting/industry.png' as poza,
				a.detalii.value('(/row/@factura)[1]', 'varchar(13)') as factura,@idDisp AS cod, @idDisp AS iddisp,
				a.descriere as descriere, CONVERT(char(10),a.detalii.value('(/row/@data)[1]', 'datetime'),101) as data,
				null as gestiune,RTRIM(g.Denumire_gestiune ) as dengestiune,'ModifTert' as msg
			FROM AntDisp a
				left join gestiuni g on a.detalii.value('(/row/@gestiune)[1]', 'varchar(13)') =g.Cod_gestiune
			WHERE idDisp=@idDisp
			FOR XML RAW
			),''
		)
		+CHAR(13)

	set @raspuns= @raspuns+'</Date>';

	/*Converteste si trimite raspunsul catre client */
	select CONVERT(xml, @raspuns);
	/*Optiunile generale (mai slabe decat cele inline) trimise spre procesare*/
	select	'wmScriuWPozReceptii' as _detalii, 1 as _areSearch, 0 as _focusSearch, @actiune as _actiune, 'D' as _tipdetalii,
			(case when ISNULL(@codScanat, '') = '' then null else 1 end) as _clearSearch, 1 as _toateAtr, '1' as _upsideDown,
			dbo.f_wmIaForm('YR') as form
	for xml raw, root('Mesaje');
end try
begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wmIaWPozDispReceptie)'
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
--select * from AntDisp where stare='operat'
--select * from PozDispOp where iddisp='6'
--select * from pozdispscan
--select * from codbare where 12873
/*tipuri comenzi	bk - livrare
					bf - beneficiari
					fc - aprovizionare
					fa - furnizori*/
