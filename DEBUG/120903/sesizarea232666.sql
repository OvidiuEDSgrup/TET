-- aici am luat apelul procedurii de refacere pt gestiunea magazinului Neamt 211 pt lunile iulie si august

declare @parXML xml
set @parXML=convert(xml,N'<parametri gestiune="211" stergere="1" generare="1" o_gestiune="211" o_stergere="1" o_generare="1" update="1" datajos="07/01/2012" datasus="08/31/2012" tipMacheta="O" codMeniu="RF"/>')
--exec wOPRefacACTE @sesiune='007E15E5C5281',@parXML=@p2

DECLARE @datajos DATETIME, @datasus DATETIME, @listaGestiuni VARCHAR(max), @Subunitate VARCHAR(1), @Tip VARCHAR(2), @Numar VARCHAR(
		10), @Cod VARCHAR(10), @Data DATETIME, @Gestiune VARCHAR(10), @Cantitate FLOAT, @Pret_valuta FLOAT, @Pret_de_stoc FLOAT, 
	@utilizator VARCHAR(50), @stergere BIT, @generare BIT, @databon DATETIME, @casabon VARCHAR(10), @numarbon INT, @UID VARCHAR(50), 
	@userASiS VARCHAR(50), @msgEroare VARCHAR(max), @codMeniu VARCHAR(2), @vanzator VARCHAR(20), @casamarcat VARCHAR(20), 
	@DetBon INT, @NrDoc VARCHAR(20), @NuTEAC INT
	
/*-------- tratat pentru cele doua tipuri de codMeniu RF- Meniu; BC-Document*/
SET @datajos = isnull(@parXML.value('(/*/@datajos)[1]', 'datetime'), isnull(@data, '01/01/1901'))
SET @datasus = isnull(@parXML.value('(/*/@datasus)[1]', 'datetime'), isnull(@data, '01/01/1901'))
/*--------------------------*/
SET @gestiune = isnull(@parXML.value('(/*/@gestiune)[1]', 'varchar(10)'), '')
SET @codMeniu = @parXML.value('(/*/@codMeniu)[1]', 'varchar(10)')
SET @NrDoc = left(RTrim(CONVERT(VARCHAR(4), @casamarcat)) + right(replace(str(@numarbon), ' ', '0'), 4), 8)


--/* Aici se observa ca la stergere sunt aduse si transferuri care nu provin din bonuri.Cand nu era pusa conditia pe stare=5 erau si mai multe.
select *
--*/DELETE
FROM pozdoc
WHERE subunitate = '1'
	AND tip = 'TE'
	AND stare = 5 -- reactivare conditie de TE cu stare=5 (TE automat)
	AND data BETWEEN @datajos AND @datasus
	AND (Gestiune_primitoare = @gestiune or Gestiune=@gestiune )
	--and Gestiune in (select top 1 [dbo].[fStrToken](val_alfanumerica, 1, ';') from par where Tip_parametru='PG' and Parametru=@Gestiune )
	--AND charindex(';' + rtrim(gestiune) + ';', @listagestiuni) > 0
	AND (@codMeniu='RF' or Numar = @NrDoc)