create procedure rapValidareTerti
as 
   
    
-- terti ai caror cod fiscal nu a fost gasit    
select t.Tert as cod_ASiS,t.Denumire as Denumire_ASiS,'' as denumire_MFin, ltrim(rtrim(replace(replace(rtrim(t.				cod_fiscal),'R',''),'O',''))) as CF_terti,'' as CF_MFin, i.grupa13 as TVA_terti, '' as TVA_MFin    
	from terti t      
	inner join infotert i  on t.tert = i.tert and t.subunitate = i.subunitate       
            and i.identificator = '' and zile_inc = '0'      
	where t.subunitate = '1' and t.cod_fiscal not in ('','-') and len(t.cod_fiscal)<11 and len(replace(t.cod_fiscal,		'.',''))>0      
		and ltrim(rtrim(replace(replace(rtrim(t.cod_fiscal),'R',''),'O',''))) not in (select cod_fiscal from				validareterti) 
union all   
--terti cu acelasi cod fiscal ,dar cu denumiri diferite  
select t.Tert,t.Denumire,v.denumire, t.Cod_fiscal,v.cod_fiscal, i.grupa13, v.tva  
	from terti t  
	inner join infotert i  on t.tert = i.tert and t.subunitate = i.subunitate   
             and i.identificator = '' and zile_inc = '0'  
	inner join validareterti v on ltrim(rtrim(replace(replace(rtrim(t.cod_fiscal),'R',''),'O',''))) = v.cod_fiscal		where t.cod_fiscal not in ('','-') and len(t.cod_fiscal)<11 and len(replace(t.cod_fiscal,'.',''))>0  
		and ltrim(rtrim(replace(replace(rtrim(t.cod_fiscal),'R',''),'O',''))) not in (select cod_fiscal from				validareterti)  
union all  
--cele care nu au "platitor de TVA" corect  
select t.Tert,t.Denumire,v.denumire, t.Cod_fiscal,v.cod_fiscal, i.grupa13, v.tva  
	from terti t  
	inner join infotert i  on t.tert = i.tert and t.subunitate = i.subunitate   
	inner join validareTerti v on ltrim(rtrim(replace(replace(rtrim(t.cod_fiscal),'R',''),'O',''))) = v.cod_fiscal  
	where i.grupa13 <> v.tva  
order by 1   

/*
--DE VAZUT: sau 2 si3 se inlocuieste cu asta:
 select t.Tert as cod_ASiS,t.Denumire as Denumire_ASiS,v.denumire as denumire_MFin, ltrim(rtrim(replace(replace(rtrim(t.cod_fiscal),'R',''),'O',''))) as CF_terti,v.cod_fiscal as CF_MFin, i.grupa13 as TVA_terti,
v.TVA as TVA_MFin
from terti t  
--merge numai cu tert.tert_extern = '0'  ????
inner join infotert i  on t.tert = i.tert and t.subunitate = i.subunitate   
            and i.identificator = '' and zile_inc = '0'  
inner join validareterti v on t.denumire = v.denumire or ltrim(rtrim(replace(replace(rtrim(t.cod_fiscal),'R',''),'O',''))) = v.cod_fiscal
 where t.cod_fiscal not in ('','-') and len(t.cod_fiscal)<11 and len(replace(t.cod_fiscal,'.',''))>0  
 and (ltrim(rtrim(replace(replace(rtrim(t.cod_fiscal),'R',''),'O',''))) <> v.cod_fiscal or
 i.grupa13 <> v.TVA)
 order by 3
 */