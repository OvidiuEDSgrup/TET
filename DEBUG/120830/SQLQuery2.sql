declare @p2 xml
set @p2=convert(xml,N'<parametri gestiune="211.1" stergere="1" generare="1" o_gestiune="213.1" o_stergere="1" o_generare="1" update="1" datajos="07/13/2012" datasus="07/13/2012" tipMacheta="O" codMeniu="RF"/>')
exec wOPRefacACTE @sesiune='7A4035C90AC37',@parXML=@p2