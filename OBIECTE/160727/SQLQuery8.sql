declare @p2 xml
set @p2=convert(xml,N'<parametri codMeniu="AD" subunitate="1" tip="FF" numar="1600268" data="07/01/2016" tert="BE0443598222" dentert="HENCO INDUSTRIES NV." factura="" tertbenef="4426         " dentertbenef="" valoare="-422.77" valoarecutva="-507.32" tva22="-84.55" valoarevaluta="-93.64" jurnal="" datascadentei="2016-08-31T00:00:00" lm="1LG_AP   " denlm="LG-APROVIZIONARE              " numarpozitii="1" stare="0" culoare="#000000" tipdocument="FF" nrdocument="1600268 " numarpozitie="587349" facturastinga="                    " facturadreapta="FCN-1600268         " valuta="EUR" curs="4.514800000000000e+000" sumavaluta="-9.364000000000000e+001" suma="-422.77" cotatva="20.00" sumatva="-84.55" contdeb="609" 
dencontdeb="609 - Cheltuieli cu disocuntui" contcred="401.1" dencontcred="401.1 - Furmizori marfa UE" diftva="-1.873000000000000e+001" achitfact="0.000000000000000e+000" contdifcurs=" " sumadifcurs="0.00" comanda="                    " dencomanda="                                                                                                                                                      " datafacturii="2016-07-01T00:00:00" explicatii="FF HENCO INDUSTRIES NV.                           " tiptva="1" idpozadoc="6162" o_numar="1600268" o_data="07/01/2016" o_dentert="HENCO INDUSTRIES NV." o_facturadreapta="FCN-1600268         " o_contdeb="609" o_contcred="401.1" o_suma="-422.77" update="1" cod="" dencod="SIGURANTA FUZIBILA BUSSMAN 10x38 2A" cantitate="2" pret="3" pret_valuta="0" tipMacheta="D" TipDetaliere="FF" subtip="DC" o_cod="" o_cantitate="2" o_pret="3" o_pret_valuta="0"><o_DateGrid><row nrpoz="1" cod_articol=" 581G1/21/4" den_articol="Reductie alama NTM 1/2&quot;x1/4&quot;" cantitate="1.00" pret="2.00" pret_valuta="0.0000" selectat="0"/></o_DateGrid><DateGrid><row nrpoz="1" cod_articol=" 581G1/21/4" den_articol="Reductie alama NTM 1/2&quot;x1/4&quot;" cantitate="1.00" pret="2.00" pret_valuta="0.0000" selectat="1"/></DateGrid></parametri>')
exec yso_wOPDetaliereCorectii @sesiune='9A6580A58A780',@parXML=@p2