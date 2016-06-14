begin tran
declare @p2 xml
set @p2=convert(xml,N'<row subunitate="1" tip="IF" numar="9630020" data="01/31/2014" tert="RO17244115" dentert="SIF ENERGY SERV SRL" factura="DJ940024" tertbenef="4427" dentertbenef="" valoare="570.65" valoarecutva="707.61" tva22="136.96" valoarevaluta="0.00" jurnal="" datascadentei="01/31/2014" numarpozitii="3" stare="0" culoare="#000000" tipdocument="IF" nrdocument="9630020 "><row facturastinga="" facturadreapta="DJ900004" contdeb="" contcred="" suma="0" cotatva="24.00" sumatva="0" lm="" explicatii="" subtip="IF"/></row>')
exec wScriuPozadoc @sesiune='F2C8941CD2B57',@parXML=@p2
rollback tran