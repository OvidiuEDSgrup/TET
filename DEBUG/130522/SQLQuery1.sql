select Subunitate,Tip,Contract,Tert,Punct_livrare,Data,Cod,Cantitate,Pret,Pret_promotional,Discount,Termen,Factura,Cant_disponibila,Cant_aprobata,Cant_realizata,Valuta,Cota_TVA,Suma_TVA,Mod_de_plata,UM,Zi_scadenta_din_luna,Explicatii,Numar_pozitie,Utilizator,Data_operarii,Ora_operarii
from sysspcon s where s.cod='9-3690-530-00-24-01'
and s.contract='9840265'
order by s.Data_stergerii desc
select Subunitate,Tip,Contract,Tert,Punct_livrare,Data,Cod,Cantitate,Pret,Pret_promotional,Discount,Termen,Factura,Cant_disponibila,Cant_aprobata,Cant_realizata,Valuta,Cota_TVA,Suma_TVA,Mod_de_plata,UM,Zi_scadenta_din_luna,Explicatii,Numar_pozitie,Utilizator,Data_operarii,Ora_operarii
from pozcon p where p.cod='9-3690-530-00-24-01'
and p.contract='9840265'
--order by s.Data_stergerii desc

select * from sysspv s where s.Cod_produs='9-3690-530-00-24-01' and s.UM=1
order by s.Data_stergerii desc

select * from pozdoc p where p.Contract='9840265'