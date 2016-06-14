select * from syssp p where left(p.Parametru,4) in  ('ANUL','LUNA')
order by p.Data_stergerii desc