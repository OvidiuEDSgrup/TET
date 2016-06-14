declare @p2 xml
set @p2=convert(xml,N'<parametri gestiune="212.1" stergere="1" generare="1" o_gestiune="211.1" o_stergere="1" o_generare="1" update="1" datajos="07/06/2012" datasus="07/06/2012" tipMacheta="O" codMeniu="RF"/>')
exec wOPRefacACTE @sesiune='DF495FE3BBF52',@parXML=@p2