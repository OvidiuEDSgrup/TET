BEGIN TRAN
execute AS login='tet\magazin.cj'
declare @p2 xml
set @p2=convert(xml,N'
<parametri data="12/07/2015" valuta="" tert="1630303120708" dentert="1630303120708 - HODREA MARIAN ILIE" suma="2767.59" cont="5311.CJ" numar="" curs="0.00000" soldTert="2767.59" sumaFixa="2767.59" diferenta="0" tipOperatiune="IB" tipEd="RE" efect="" o_cont="5311.CJ" o_data="12/07/2015" o_numar="" o_tert="1630303120708" o_valuta="" o_curs="0.00000" o_soldTert="2767.59" o_suma="2767.59" o_diferenta="0" update="1" tip="RE" tipMacheta="D" codMeniu="PI" TipDetaliere="RE" subtip="PI">
  <o_DateGrid>
    <row nrcrt="1" numar="" tert="1630303120708" marca="" decont="" subtip="IB" factura="CJ941095" facturaInit="CJ941095" data_factura="11/27/2015" data_scadentei="11/27/2015" sold="2084.34" valoare="2084.34" suma="2084.34" curs="0.00000" valuta="" denvaluta="RON" selectat="1" factnoua="0" sumaFixaPoz="2767.59" lm="1VZ_CJ_03" lmfact="1VZ_CJ_03" cont="411.1" indicator="" jurnal="" denlm="CLUJ3">
      <detalii>
        <row />
      </detalii>
    </row>
    <row nrcrt="2" numar="" tert="1630303120708" marca="" decont="" subtip="IB" factura="CJ941098" facturaInit="CJ941098" data_factura="12/07/2015" data_scadentei="12/07/2015" sold="683.25" valoare="683.25" suma="683.25" curs="0.00000" valuta="" denvaluta="RON" selectat="1" factnoua="0" sumaFixaPoz="2767.59" lm="1VZ_CJ_02" lmfact="1VZ_CJ_02" cont="411.1" indicator="" jurnal="" denlm="CLUJ2">
      <detalii>
        <row />
      </detalii>
    </row>
  </o_DateGrid>
  <DateGrid>
    <row nrcrt="1" numar="" tert="1630303120708" marca="" decont="" subtip="IB" factura="CJ941095" facturaInit="CJ941095" data_factura="11/27/2015" data_scadentei="11/27/2015" sold="2084.34" valoare="2084.34" suma="2084.34" curs="0.00000" valuta="" denvaluta="RON" selectat="1" factnoua="0" sumaFixaPoz="2767.59" lm="1VZ_CJ_03" lmfact="1VZ_CJ_03" cont="411.1" indicator="" jurnal="" denlm="CLUJ3">
      <detalii>
        <row />
      </detalii>
    </row>
    <row nrcrt="2" numar="" tert="1630303120708" marca="" decont="" subtip="IB" factura="CJ941098" facturaInit="CJ941098" data_factura="12/07/2015" data_scadentei="12/07/2015" sold="683.25" valoare="683.25" suma="683.25" curs="0.00000" valuta="" denvaluta="RON" selectat="1" factnoua="0" sumaFixaPoz="2767.59" lm="1VZ_CJ_02" lmfact="1VZ_CJ_02" cont="411.1" indicator="" jurnal="" denlm="CLUJ2">
      <detalii>
        <row />
      </detalii>
    </row>
  </DateGrid>
</parametri>
')
--select @p2
exec wOPPISelectiva @sesiune='4ACC6CB5EC3F2',@parXML=@p2
revert
rollback tran