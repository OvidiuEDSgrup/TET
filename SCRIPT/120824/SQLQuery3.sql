declare @p2 xml
set @p2=convert(xml,N'<parametri gestiune="212.1" stergere="1" generare="1" o_gestiune="212.1" o_stergere="1" o_generare="1" update="1" datajos="08/08/2012" datasus="08/08/2012" tipMacheta="O" codMeniu="RF"/>')
exec wOPRefacACTE @sesiune='3A48FC49EC916',@parXML=@p2