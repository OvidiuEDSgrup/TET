declare @p2 xml
set @p2=convert(xml,N'<parametri numar="1" data="08/01/2013" gestiune="211.CJ" dentert="VARGA VASILE" tert="1760312120672" UID="CF820224-BF12-6234-D0E4-39659743F079" valoare="6773.50" tva="655.49" valtotala="6773.50" numarpozitii="50" vanzator="MAGAZIN_CJ" casam="2" ora="13:25" stergere="1" generare="1" o_numar="1" o_data="08/01/2013" o_gestiune="211.CJ" o_dentert="VARGA VASILE" o_tert="1760312120672" o_UID="CF820224-BF12-6234-D0E4-39659743F079" o_valoare="6773.50" o_tva="655.49" o_valtotala="6773.50" o_numarpozitii="50" o_vanzator="MAGAZIN_CJ" o_casam="2" o_ora="13:25" o_stergere="1" o_generare="1" update="1" tip="BN" tipMacheta="D" codMeniu="BO" TipDetaliere="BN" subtip="RF"/>')
exec wOPRefacACTE @sesiune='F1CABA0601945',@parXML=@p2
go
