create procedure wACConturiReg @sesiune varchar(50), @parXML XML    
as    
begin  
declare @subunitate varchar(9), @searchText varchar(80),@utilizator varchar(20)  ,@valoare varchar(10)
select @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'    
select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')  

set @searchText=REPLACE(@searchText, ' ', '%')  

select top 100 rtrim(Cont) as cod, rtrim(cont)+' - '+rtrim(left(Denumire_cont,30)) as denumire,   
(case Sold_credit when 1 then '(Furnizori)' when 2 then '(Beneficiari)' when 3 then '(Stocuri)'   
when 4 then '(Valoare MF)' when 5 then '(Amortizare MF)' when 6 then '(TVA deductibil)' when 7 then '(TVA colectat)'   
when 8 then '(Efecte)' when 9 then '(Deconturi)' else '' end) as info   
from conturi  
where subunitate=@subunitate and    
(cont like @searchText + '%' or denumire_cont like '%' + @searchText + '%')    
and conturi.Are_analitice=0  
and conturi.Cont like '53%'  
order by rtrim(cont)    
for xml raw  
end

