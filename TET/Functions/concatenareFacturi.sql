create function concatenareFacturi(@tert varchar(100), @utilizator varchar(100))   
returns varchar(500)  
as  
begin  
 declare @facturi varchar(500)
 select @facturi= isnull(@facturi+', ','')+rtrim(generareplati.factura)  
 from avnefac, generareplati
 where 
    avnefac.numar=generareplati.Numar_document and avnefac.data=generareplati.data and   
    avnefac.tip='GP' and rtrim(avnefac.Terminal)=@utilizator  and generareplati.tert=@tert
 GROUP BY generareplati.factura, generareplati.tert
return @facturi  
end