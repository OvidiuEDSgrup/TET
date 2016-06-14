--delete d from pozdoc d where d.Subunitate='1' and d.Tip='TE' and d.Numar='90001' and d.Data='2013-03-28'
SELECT * FROM pozdoc p where '9840110' in (p.Contract,p.Factura)