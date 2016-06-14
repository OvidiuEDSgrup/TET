declare @p2 xml
set @p2=convert(xml,N'<row tip="RN" numar="" data="03/04/2015" gestiune="" lm="" explicatii="STOC AG" denstare=""><row cod="570G1/2" dencod="Teu alama NTM 1/2&quot; FI" cantitate="30" pret="0" explicatii="" subtip="RN"/></row>')
exec wScriuPozContracte @sesiune='3BB8C17686706',@parXML=@p2
go
