--select * from webJurnalOperatii j where j.data>='2013-07-09' and j.utilizator='MAGAZIN_CJ'
--order by j.data desc 
--select * from asisria.dbo.sesiuniRIA s
execute as LOGIN='TET\magazin.CJ'
begin tran
insert asisria..utilizatoriRIA (BD,utilizator,utilizatorWindows,parola,detalii)
select 'TESTOV', 'MAGAZIN_CJ', 'TET\magazin.CJ', null,null
set transaction isolation level read uncommitted
exec wScriuPozplin 'B562137607A85',
'<row data="07/09/2013" soldinitial="0" cont="5311.CJ" totalincasari="0" curs="0" totalplati="0" efect="" soldfinal="0" tip="RE">
  <row tert="RO5773856" dentert="FAUSTA CONF SRL" factura="9420837" suma="0" subtip="IB" />
</row>'
rollback tran