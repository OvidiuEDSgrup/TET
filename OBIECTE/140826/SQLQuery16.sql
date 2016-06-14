select p.Tert,t.Denumire,* from pozdoc p join terti t on t.Tert=p.Tert
where p.Tip='AC' and p.Numar='CJ200001' and p.Data='2014-08-26'