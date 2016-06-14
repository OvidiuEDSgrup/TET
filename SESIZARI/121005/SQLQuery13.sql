select * from pozdoc p where p.Tip_miscare='E' and p.Cod_intrare='' order by p.Data desc
select * from pozdoc p where p.Data='2012-10-03' and p.Numar like 1*10000 +2 and p.Cod like 'TR0072              '

select * from stocuri s where s.Stoc<=-0.001 and (s.Data_ultimei_iesiri>='2012-10-01' or s.Data>='2012-10-01')
select * from stocuri s where s.Cod='95141               ' and s.Cod_gestiune='101'

select * from pozdoc p where p.Cod like 'P22/600/1400        ' and 'IMPL1B       ' in (p.Cod_intrare,p.Grupa)