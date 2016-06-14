if 0=1 and (select count(1) from sysobjects where name='anexadoc')>0 update anexadoc set punct_livrare='     ' where subunitate='1        ' and tip='AP' and numar='9430112 ' and data='08/13/2012'
if 1=1 and (select count(1) from sysobjects where name='anexadoc')>0 update anexadoc set numar='9430113', data='08/13/2012' where subunitate='1        ' and tip='AP' and numar='9430112 ' and data='08/13/2012'
if 0=1 and (select count(1) from sysobjects where name='anexafac')>0 update anexafac set numele_delegatului='                              ' where subunitate='1        ' and numar_factura='9430112             '
if 0=1 and (select count(1) from sysobjects where name='anexafac')>0 update anexafac set seria_buletin='' where subunitate='1        ' and numar_factura='9430112             '
if 0=1 and (select count(1) from sysobjects where name='anexafac')>0 update anexafac set numar_buletin='' where subunitate='1        ' and numar_factura='9430112             '
if 0=1 and (select count(1) from sysobjects where name='anexafac')>0 update anexafac set eliberat='                              ' where subunitate='1        ' and numar_factura='9430112             '
if 0=1 and (select count(1) from sysobjects where name='anexafac')>0 update anexafac set numarul_mijlocului='                    ' where subunitate='1        ' and numar_factura='9430112             '
if 1=1 and (select count(1) from sysobjects where name='anexafac')>0 if not exists (select 1 from anexafac where subunitate='1        ' and numar_factura='9430113             ') update anexafac set numar_factura='9430113             ' where subunitate='1        ' and numar_factura='9430112             '

