declare @p2 xml
set @p2=convert(xml,N'<parametri gestiune="211.1" stergere="1" generare="1" o_gestiune="211.1" o_stergere="1" o_generare="1" update="1" datajos="08/01/2012" datasus="08/31/2012" tipMacheta="O" codMeniu="RF"/>')
exec wOPRefacACTE @sesiune='B2E4BEECE5ED3',@parXML=@p2