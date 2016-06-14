select * from stocuri s where s.Cod like 'PKKP600/1000%' 
select * from pozdoc p where p.Tip in ('RM','AP','TE') and p.Cod like 'PKKP600/1000' 
and '' in (Cod_intrare,grupa) 

select * from pozdoc p where p.Tip in ('AP') and p.Cod_intrare=''