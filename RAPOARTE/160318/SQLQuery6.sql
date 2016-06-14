execute as login='tet\magazin.gl'
declare @p2 xml
set @p2=convert(xml,N'<parametri tip="BY" numar="941416" data="03/16/2016" dengestiune="GL BON FISCAL GALATI" gestiune="210.GL" dentert="ARAMA PETRICA CATALIN" tert="1750630170319" factura="GL941416" data_facturii="03/16/2016" valoare="674.00" tva="134.80" valtotala="808.80" numarpozitii="2" vanzator="FILIALA_GL" casam="7" ora="10:43" idantetbon="13859" culoare="#2A8E82" _nemodificabil="1" contract="GL983726" nrdoc="GL941416" tipdoc="AP" datadoc="2016-03-16T00:00:00" update="1" stergere="1" generare="1" tipMacheta="D" codMeniu="BO_FILIALE" TipDetaliere="BY" subtip="RF"/>')
exec wOPRefacACTE @sesiune='15358ECF35DA6',@parXML=@p2
revert