--***
/**	functie ce returneaza coduri de obligatii bugetare */
Create function fCodObligatiiBugetare (@parXML xml)
returns @codobligatii table 
	(cod_obligatie varchar(20), cod_declaratie varchar(20), cod_bugetar varchar(30), numar_evidenta varchar(50), denumire varchar(1000), notatie varchar(100))
begin
	declare @data datetime, @datajos datetime, @datasus datetime, 
		@pCASind char(10), @pCASunit char(10), @pFaambp char(10), @pCASSind char(10), 
		@pCASSunit char(10), @pCCI char(10), @pSomajInd char(10), @pSomajUnit char(10), @pFondGar char(10)
	
	select @data = @parXML.value('(/row/@data)[1]','datetime')
	select @datajos=dbo.BOM(@data), @datasus=dbo.EOM(@data)

	set @pCASind=ltrim(str(dbo.iauParLN(@dataSus,'PS','CASINDIV'),4,2))+'%'
	set @pCASunit=ltrim(str(dbo.iauParLN(@dataSus,'PS','CASGRUPA3')-dbo.iauParLN(@dataSus,'PS','CASINDIV'),4,1))+'%'
	set @pFaambp=ltrim(str(dbo.iauParLN(@dataSus,'PS','0.5%ACCM'),4,2))+'%'
	set @pCASSind=ltrim(str(dbo.iauParLN(@dataSus,'PS','CASSIND'),4,2))+'%'
	set @pCASSunit=ltrim(str(dbo.iauParLN(@dataSus,'PS','CASSUNIT'),4,2))+'%'
	set @pCCI=ltrim(str(dbo.iauParLN(@dataSus,'PS','COTACCI'),4,2))+'%'
	set @pSomajInd=ltrim(str(dbo.iauParLN(@dataSus,'PS','SOMAJIND'),4,2))+'%'
	set @pSomajUnit=ltrim(str(dbo.iauParLN(@dataSus,'PS','3.5%SOMAJ'),4,2))+'%'
	set @pFondGar=ltrim(str(dbo.iauParLN(@dataSus,'PS','FONDGAR'),4,2))+'%'

	insert into @codobligatii
	select '810', '', '20470101XX', '1081001', 'Varsam.de la PJ pt.pers.cu handicap neincadrate - angajator', 'CNPH'
	union all 
	select '412', '', '5502XXXXXX', '1041201', 'CAS - asigurati', 'CAS individual '+@pCASind
	union all 
	select '411', '', '5502XXXXXX', '1041101', 'CAS - angajator', 'CAS '+@pCASunit
--	acesta cod (419) s-a desfintat incepand cu luna iulie 2012, dar ramine de completat pt. declaratiile rectificative anterioare
	union all 
	select '419', '', '5502XXXXXX', '1041901', 'CAS individual - alti asigurati', 'CAS individual '+ @pCASind
	union all 
	select '416', '', '5502XXXXXX', '1041601', 'Contributie la fondul de acc. de munca si boli prof.- angajator', 'Acc. Munca '+@pFaambp
	union all 
	select '432', '', '5502XXXXXX', '1043201', 'CAS Sanatate - asigurati', 'Sanatate asigurati '+@pCASSind
	union all 
	select '431', '', '5502XXXXXX', '1043101', 'CAS Sanatate - angajator', 'Sanatate angajator '+@pCASSunit
	union all 
	select '438', '', '5502XXXXXX', '1043801', 'CAS Sanatate - angajator pt. Fambp', 'Sanatate angajator pt. Fambp '+@pCASSunit
	union all 
	select '448', '', '5502XXXXXX', '1044801', 'CAS Sanatate - din Fambp', 'Sanatate suportata de Fambp '+@pCASSunit
	union all 
	select '439', '', '5502XXXXXX', '1043901', 'Contrib.pt.concedii si indemnizatii - angajator','CCI '+@pCCI
	union all 
	select '422', '', '5502XXXXXX', '1042201', 'Contributie somaj individual - asigurati', 'Somaj '+@pSomajInd
	union all 
	select '421', '', '5502XXXXXX', '1042101', 'Contributie somaj - angajator', 'Somaj '+@pSomajUnit
--	acesta cod (424) s-a desfintat incepand cu luna iulie 2012, dar ramine de completat pt. declaratiile rectificative anterioare
	union all 
	select '424', '', '5502XXXXXX', '1042401', 'Contributie somaj individual - alti asigurati', 'Somaj '+@pSomajInd
	union all 
	select '423', '', '5502XXXXXX','1042301', 'Contributie la fondul de garantare - angajator', 'Fond garantare '+@pFondGar
	union all 
	select '602', '', '20470101XX', '1060201', 'Impozit pe venituri din salarii', 'Impozit 16%' 
	union all
	select '611', '', '20470101XX', '1061101', 'Impozit pe venituri din drepturi de autor', 'Impozit 16%'
	union all
	select '616', '', '20470101XX', '1061601', 'Impozit pe venituri din conventii civile', 'Impozit 16%'
--	contributiile de mai jos se declara incepand cu luna iulie 2012
	union all
	select '613', '', '20470101XX', '1061301', 'Impozit pe venituri din activitati agricole', 'Impozit 16%'
	where @dataJos>='07/01/2012'
	union all 
	select '451', '', '5502XXXXXX', '1045101', 'CAS individual - drepturi de proprietate intelectuala', 'CAS individual pt. drepturi de proprietate intelectuala '+ @pCASind
	where @dataJos>='07/01/2012'
	union all 
	select '461', '', '5502XXXXXX', '1046101', 'CAS Sanatate - drepturi de proprietate intelectuala', 'Sanatate pt. drepturi de proprietate intelectuala '+ @pCASSind
	where @dataJos>='07/01/2012'
	union all 
	select '452', '', '5502XXXXXX', '1045201', 'CAS individual - contracte/conventii civile', 'CAS individual pt. contracte/conventii civile '+ @pCASind
	where @dataJos>='07/01/2012'
	union all 
	select '462', '', '5502XXXXXX', '1046201', 'CAS Sanatate - contracte-conventii civile', 'Sanatate pt. contracte/conventii civile '+ @pCASSind
	where @dataJos>='07/01/2012'
	union all 
	select '466', '', '5502XXXXXX', '1046601', 'CAS Sanatate - activitati agricole', 'Sanatate pt. activitati agricole '+ @pCASSind
	where @dataJos>='07/01/2012'

	update @codobligatii set Cod_declaratie=(case when cod_obligatie in ('810') then '100' else '112' end)

	return
end

/*
	select * from fCodObligatiiBugetare ('<row data="04/30/2013" />')
*/
