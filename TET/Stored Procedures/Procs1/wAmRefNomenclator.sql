--***
CREATE procedure wAmRefNomenclator @sesiune varchar(50),@cod varchar(20)    
as    
select    
(case when exists (select 1 from stocuri s where s.cod=@cod) then 'Articolul are stoc!'      
	when exists (select 1 from pozdoc p where p.cod=@cod) then 'Articolul este operat in documente!'      
	when exists (select 1 from istoricstocuri s where s.cod=@cod) then 'Articolul are istoric in stocuri!'      
 else '' end) as mesaj  
FOR XML RAW
