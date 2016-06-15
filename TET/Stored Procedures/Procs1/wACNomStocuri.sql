create procedure wACNomStocuri @sesiune varchar(50), @parXML xml
as
declare @searchtext varchar(50), @categoriePret int, @gestutiliz varchar(20), @utilizator varchar(50), @gestiune varchar(20), @tip varchar(2)
select @searchtext=isnull(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),
       @gestiune=ISNULL(@parXML.value('(/row/@gestiune)[1]', 'varchar(20)'), ''),
       @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '')
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
set @searchtext=replace(@searchtext,' ','%')
set @gestutiliz=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and cod_proprietate='GESTIUNE' and cod=@utilizator),'')
select top 100
   rtrim(RTRIM(nomencl.Cod)+'|'+ltrim(stocuri.cod_intrare)) as cod, 
   RTRIM(nomencl.Denumire)+' ('+max(ltrim(rtrim(convert(char(18),convert(decimal(11,2),stocuri.Pret)))))+'lei ) ' as denumire,
   (case  when @tip in ('RM') and sum(stocuri.stoc)>0 then 'Ct:'+rtrim(max(stocuri.cont)) else 'Ct:'+rtrim(MAX(nomencl.cont))end)+' Cant:'+ltrim(CONVERT(varchar(20), sum(convert(decimal(15, 2), isnull(stocuri.stoc, 0)))))+ ' ' + rtrim(max(nomencl.um)) as info  
   from nomencl 
    inner join stocuri on stocuri.Cod=nomencl.Cod and stocuri.stoc>0 and  stocuri.Cod_gestiune=@gestiune 
    where   
         ((stocuri.cod_intrare like '%'+@searchtext+'%' ) or
		 (stocuri.cod like '%'+@searchtext+'%' ) or
		 (nomencl.Denumire like '%'+@searchtext+'%' ))
		 and (@tip not in ('CM') or nomencl.tip<>'O') 
	group by nomencl.cod,nomencl.Denumire, stocuri.Cod_intrare
   for xml raw

