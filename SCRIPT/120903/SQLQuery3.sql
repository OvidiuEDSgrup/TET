declare @p2 xml
set @p2=convert(xml,N'<parametri gestiune="213.1" stergere="1" generare="1" o_gestiune="212.1" o_stergere="1" o_generare="1" update="1" datajos="08/29/2012" datasus="08/29/2012" tipMacheta="O" codMeniu="RF"/>')
exec wOPRefacACTE @sesiune='3B77F75828887',@parXML=@p2