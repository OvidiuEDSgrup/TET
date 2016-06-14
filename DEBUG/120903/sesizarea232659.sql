/*
acesta este apelul procedurii de refacere care da eroarea 
Msg 50000, Level 16, State 1, Procedure wOPRefacACTE, Line 223
wfValidarePozdoc: Gestiunea destinatara nu exista in lista de gestiuni! (wScriuPozdoc). (idAntetBon=1157) (wDescarcBon)(wOPRefacACTE)
fiindca in bt, pe bonul 2 din 29.08.2012 casa 3 facut pe comada de livrare/contractul 9830185
,pt pozitia de retur cu codul MA-FM12 si cantitate -1 incearca sa creeze un transfer cu contract/comanda de livrare atasata gresit:
parametrul este trimis cu atributul contract, care pentru transfer inseamna gestiune destinatara,si il cauta printre gestiuni unde nu-l gaseste.
*/

declare @p2 xml
set @p2=convert(xml,N'<parametri gestiune="213.1" stergere="1" generare="1" o_gestiune="213.1" o_stergere="1" o_generare="1" update="1" datajos="08/29/2012" datasus="08/29/2012" tipMacheta="O" codMeniu="RF"/>')
exec wOPRefacACTE @sesiune='007E15E5C5281',@parXML=@p2

