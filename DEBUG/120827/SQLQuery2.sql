declare @p2 xml
set @p2=convert(xml,N'<row tip="BC" numar="2" data="08/14/2012" dengestiune="MAGAZIN AMANUNT NT" gestiune="211.1" dentert="GONDOR DANIEL" tert="1700504274820" factura="9410358" data_facturii="08/14/2012" valoare="3643.32" tva="874.41" valtotala="4517.73" numarpozitii="12" vanzator="MAGAZIN_NT" casam="1" ora="13:03" idantetbon="1065" culoare="#0000EE" _nemodificabil="1" nrform="FACTBON"/>')
exec wTipFormular @sesiune='AF25664821D60',@parXML=@p2