declare @p2 xml
set @p2=convert(xml,N'<parametri tip="BC" numar="1" data="08/23/2012" dengestiune="MAGAZIN AMANUNT NT" gestiune="211.1" dentert="STAN CLEMENT" tert="2127312" factura="9410392" data_facturii="08/23/2012" valoare="5096.29" tva="986.38" valtotala="5096.29" numarpozitii="14" vanzator="MAGAZIN_NT" casam="1" ora="14:22" idantetbon="1109" culoare="#0000EE" _nemodificabil="1" o_tip="BC" o_numar="1" o_data="08/23/2012" o_dengestiune="MAGAZIN AMANUNT NT" o_gestiune="211.1" o_dentert="STAN CLEMENT" o_tert="2127312" o_factura="9410392" o_data_facturii="08/23/2012" o_valoare="5096.29" o_tva="986.38" o_valtotala="5096.29" o_numarpozitii="14" o_vanzator="MAGAZIN_NT" o_casam="1" o_ora="14:22" o_idantetbon="1109" o_culoare="#0000EE" o__nemodificabil="1" update="1" stergere="1" generare="1" tipMacheta="D" codMeniu="BO" TipDetaliere="BC" subtip="RF"/>')
exec wOPRefacACTE @sesiune='EACAC7EAEF843',@parXML=@p2