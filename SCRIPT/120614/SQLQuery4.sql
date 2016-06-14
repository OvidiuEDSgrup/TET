select * from pozdoc p where p.Data_operarii='2012-06-14' and p.Ora_operarii>='130000'
and p.Tip='AP'
--not exists (select 1 from doc d where d.Subunitate=p.Subunitate and d.Tip=p.Tip and d.Numar=p.Numar and d.Data=p.Data)