--exec RefacereStocuri null,null,null,null,null,null
execute as login='tet\MAGAZIN.NT'
begin tran
set transaction isolation level read uncommitted
insert ASiSRIA..sesiuniRIA (BD,token,utilizator)
select 'TESTOV','727120292AC32','MAGAZIN_NT'
where '727120292AC32' not in (select token from asisria..sesiuniRIA)
insert ASiSRIA..utilizatoriRIA (BD,utilizator)
select 'TESTOV', s.utilizator from asisria..sesiuniRIA s left join asisria..utilizatoriRIA u on u.BD=s.BD and u.utilizator=s.utilizator
where s.token='727120292AC32' and u.utilizator is null
--SELECT * from pozcon p where p.Contract='9831177'
--select * from pozdoc p where p.Numar='9430747'
--select * from docfiscalerezervate
--select * from docfiscale

select TOP 1 * from plin p where p.Cont like '5311.NT%' order by p.Data desc
--exec wScriuPozplin 
--'727120292AC32'	
--,'<row data="07/11/2013" soldinitial="0" totalincasari="0" curs="0" totalplati="0" efect="" soldfinal="0" tip="RE">
--  <row tert="RO27410207" dentert="CRACIUN LUCIAN INTR.IND." factura="9411358" suma="0" subtip="IB" />
--</row>'
--select TOP 1 * from plin p where p.Cont like '5311.NT%' order by p.Data desc
--select TOP 2 * from pozplin p where p.Cont like '5311.NT%' order by p.Data desc
exec wScriuPozplin 
'727120292AC32'	
,'<row data="07/11/2013" soldinitial="0" totalincasari="0" curs="0" totalplati="0" efect="" soldfinal="0" tip="RE">
  <row tert="20278347" dentert="CAB.MED.DR. BURSUC AURORA" factura="9411360" suma="0" subtip="IB" />
</row>'
select TOP 1 * from plin p where p.Cont like '5311.NT%' order by p.Data desc
select TOP 20 * from pozplin p where p.Cont like '5311.NT%' order by p.Data desc
rollback tran