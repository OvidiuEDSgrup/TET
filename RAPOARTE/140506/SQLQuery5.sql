--select * from facturi f where f.Factura like 'FCT%'
select t.Denumire,* from factimpl f join terti t on t.Tert=f.Tert
where f.Tert='RO6602668'--f.Factura like 'FCT%'
select p.Factura,p.Cont_factura,p.Cont_corespondent,p.Cont_de_stoc,p.Cont_intermediar,p.Cont_venituri,* from pozdoc p where p.Tert='RO6602668'
select * from istfact f where Tert='RO6602668'--f.Factura like 'FCT%'
--select * from rulaje r where r.Cont like '472' 
select * from pozincon p where '472' in (p.Cont_creditor,p.Cont_debitor) and p.Explicatii like '%magnetic%'

select * from POZADOC f where Tert='RO6602668'--f.Factura_dreapta like 'FCT%' OR f.Factura_stinga like 'FCT%'
select * from POZPLIN f where Tert='RO6602668'--f.Factura like 'FCT%'