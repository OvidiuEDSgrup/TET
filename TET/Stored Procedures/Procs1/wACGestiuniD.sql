--***
create procedure [dbo].[wACGestiuniD] @sesiune varchar(50), @parXML XML    
as       
  
declare @subunitate varchar(9), @searchText varchar(80), @userASiS varchar(10), @lista_gestiuni bit, @gestprim char(13)   
        --,@aregest int 
--set @aregest=(case when exists (select 1 from fPropUtiliz() where cod_proprietate='GESTIUNE') then 1 else 0 end)
	select @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'    
	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')    
	set @searchText=REPLACE(@searchText, ' ', '%') 
	set @gestprim = ISNULL(@parXML.value('(/row/@gestprim)[1]', 'varchar(13)'), '')  
    
--if (@gestprim = '')
	select top 100 rtrim(Cod_gestiune) as cod, rtrim(Denumire_gestiune) as denumire,     
	rtrim(case when gestiuni.Cont_contabil_specific='' 
		then (case gestiuni.Tip_gestiune when 'M' then 'Materiale' when 'P' then 'Produse' when 'C' then 'Cantitativa' when 'A' then 'Amanuntul' when 'V' then 'Valorica' when 'O' then 'Obiecte' when 'F' 
			then 'Folosinta' when 'I' then 'Imobilizari' else gestiuni.Tip_gestiune end)    
		else 'Tip ' + gestiuni.Tip_gestiune + ' (Ct. ' + RTrim(gestiuni.Cont_contabil_specific) + ')' end) as info    
	from gestiuni 
	--left outer join fPropUtiliz() fp on cod_proprietate='GESTIUNE'  and Cod_gestiune=fp.valoare  
	where subunitate=@subunitate and    
	(cod_gestiune like @searchText + '%' or denumire_gestiune like '%' + @searchText + '%')    
	and gestiuni.tip_gestiune in ('C','P','M','A','I')
	--and (@aregest=0 or fp.valoare is not null)
	--order by trebuie sa ramana Cod_gestiune pentru ca functia CautaIndexat sa functioneze    
	order by Cod_gestiune    
	for xml raw 
