declare @p2 xml
set @p2=convert(xml,N'<row tip="RN" numar="" data="12/31/2014" gestiune="101" dengestiune="MARFURI SI PIESE DE SCHIMB" lm="1OF_SD" denlm="OF-OFFICE SEDIU" explicatii=""><row cod="PK4A42A1" dencod="Aeroterma de tavan(FT1)" cantitate="4" pret="100" termen="12/31/2014" subtip="RN"/></row>')
exec wScriuPozContracte @sesiune='9ADD7452A6E45',@parXML=@p2