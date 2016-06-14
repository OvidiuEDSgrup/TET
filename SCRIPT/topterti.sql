select tip=case s.tip when 0x46 then 'Client' else 'Furnizor' end, nrcrt, s.tert,s.valoare 
,t.*,i.*, p.* from
(select f.Tip,f.Tert,valoare=sum(f.Valoare), nrcrt=ROW_NUMBER() over (partition by f.tip order by sum(f.valoare) desc)
from facturi f
group by f.Tip,f.Tert) s 
left join terti t on t.Tert=s.Tert 
left join infotert i on i.Subunitate=t.Subunitate and i.Tert=t.Tert and i.Identificator=''
left join infotert p on p.Subunitate='C'+t.Subunitate and p.Tert=t.Tert
where s.nrcrt<=30
order by s.Tip,s.nrcrt,p.Identificator