declare @Tert nvarchar(4000),@Factura nvarchar(4000),@data1 datetime,@data2 datetime
select @Tert='RO28002028',@Factura=N'',@data1='2011-01-01',@data2='2013-04-04'

select r.tert,r.Denumire,r.Factura,r.Data,r.Data_scadentei,r.ValoareFactura,
  ( case when r.cont!='413' then  r.Incasat else 0 end) as Incasat,r.valoareEfecte,r.Nr_efect,r.DataEfect,
  r.ScadentaEfect,r.IncasatEfect,r.soldEfect,r.Cont
  from 
  (select f.tert,
t.Denumire as Denumire,
f.Factura,f.DATA,f.Data_scadentei,isnull(fi.Valoare, f.Valoare)+ISNULL(fi.TVA_22, f.TVA_22) as ValoareFactura,
 isnull(p.Suma,0) as Incasat,
 isnull(e.Valoare,0) as valoareEfecte ,
 e.Nr_efect,
 e.Data as DataEfect,
 e.Data_scadentei as ScadentaEfect,
 e.Decontat as IncasatEfect,
 e.Sold as soldEfect,
 e.cont
from facturi f left join factimpl_copie1 fi on fi.Subunitate=f.Subunitate and fi.Tip=f.Tip and fi.Factura=f.Factura and fi.Tert=f.Tert
left  join pozplin p on  f.Factura=p.Factura and  p.Plata_incasare='IB' and f.Tert=p.Tert
 left join efecte e on  p.Numar=e.Nr_efect  and p.Tert=e.Tert and e.Data_scadentei between @data1 and @data2
left join terti t on t.tert=f.tert
 where t.Tert=f.Tert and
 (round(isnull(f.Sold,0),2)!=0 or round(isnull(e.Sold,0),2)>0)
and (f.Factura in (@Factura) or '' in (@Factura))
and (isnull(@Tert, '') = '' OR  f.Tert=ltrim(rtrim(@Tert)))
)r
union 
select e.tert, (select denumire from terti where tert=e.Tert) as Denumire,
 '' as Factura,'' as data,'' as data_scadentei,0 as valoareFactura,0 as incasat, 
(select Valoare from efecte where Nr_efect=e.Nr_efect),e.Nr_efect,e.Data,e.Data_scadentei,
(select Decontat from efecte where Nr_efect=e.Nr_efect),
(select sold from efecte where Nr_efect=e.Nr_efect),''  
  from efimpl e
  where 
(isnull(@Tert, '') = '' OR  e.Tert=ltrim(rtrim(@Tert)))
and e.Data_scadentei between @data1 and @data2