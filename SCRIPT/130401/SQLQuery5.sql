set transaction isolation level read uncommitted
--begin tran
declare @p2 xml
set @p2=convert(xml,N'<parametri tip="BC" numar="2" data="03/18/2013" dengestiune="CJ BON FISCAL CLUJ NAPOCA" gestiune="210.CJ" dentert="BURGA BOGDAN DANIEL" tert="1880125125830" valoare="4.00" tva="0.76" valtotala="4.00" numarpozitii="4" vanzator="MAGAZIN_CJ" casam="2" ora="14:51" idantetbon="2055" culoare="#000000" _nemodificabil="1" stergere="1" generare="1" o_tip="BC" o_numar="2" o_data="03/18/2013" o_dengestiune="CJ BON FISCAL CLUJ NAPOCA" o_gestiune="210.CJ" o_dentert="BURGA BOGDAN DANIEL" o_tert="1880125125830" o_valoare="4.00" o_tva="0.76" o_valtotala="4.00" o_numarpozitii="4" o_vanzator="MAGAZIN_CJ" o_casam="2" o_ora="14:51" o_idantetbon="2055" o_culoare="#000000" o__nemodificabil="1" o_stergere="1" o_generare="1" update="1" tipMacheta="D" codMeniu="BO" TipDetaliere="BC" subtip="RF"/>')
exec wOPRefacACTE @sesiune='BC487DB180C37',@parXML=@p2
--rollback tran