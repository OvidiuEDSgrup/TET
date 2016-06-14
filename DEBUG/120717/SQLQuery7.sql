declare @p2 xml
set @p2=convert(xml,N'<parametri gestiune="212.1" stergere="1" generare="1" o_gestiune="212.1" o_stergere="1" o_generare="1" update="1" datajos="07/13/2012" datasus="07/13/2012" tipMacheta="O" codMeniu="RF"/>')
exec wOPRefacACTE @sesiune='17965C7E229B0',@parXML=@p2