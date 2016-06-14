declare @p2 xml
set @p2=convert(xml,N'<parametri gestiune="212.1" stergere="1" generare="1" o_gestiune="213.1" o_stergere="1" o_generare="1" update="1" datajos="09/06/2012" datasus="09/06/2012" tipMacheta="O" codMeniu="RF"/>')
exec wOPRefacACTE @sesiune='5C94071C622D4',@parXML=@p2