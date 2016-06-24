CREATE procedure [dbo].[wCBConturi] @sesiune varchar(50), @parXML XML  
as  
if exists(select * from sysobjects where name='wACConturiSP' and type='P' and SCHEMA_NAME([uid])='yso')      
	exec yso.wACConturiSP @sesiune,@parXML      
else      
begin
declare @subunitate varchar(9), @searchText varchar(80), @tip varchar(2), @codMeniu varchar(2), @cdeb varchar(13), @subtip varchar(2),@facturanesosita bit,
	@CTCLAVRT bit,@ContAvizNefacturat varchar(20),@aviznefacturat bit,@tert varchar(13), @faraAnalitic int
select @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'  
  
select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''), 
	@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
	@facturanesosita=ISNULL(@parXML.value('(/row/@facturanesosita)[1]', 'bit'), 0),
	@aviznefacturat=ISNULL(@parXML.value('(/row/@aviznefacturat)[1]', 'bit'), 0),
	@subtip=ISNULL(@parXml.value('(/row/@subtip)[1]', 'varchar(2)'), ''), 
	@codMeniu=ISNULL(@parXML.value('(/row/@codMeniu)[1]', 'varchar(2)'), ''), 
	@cdeb=ISNULL(@parXML.value('(/row/@cdeb)[1]', 'varchar(13)'), ''),
	@tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), ''),
	@faraAnalitic=ISNULL(@parXML.value('(/row/@faraAnalitic)[1]', 'int'), 0)
		
set @searchText=REPLACE(@searchText, ' ', '%')

exec luare_date_par 'GE', 'CTCLAVRT ', @CTCLAVRT  output, 0, @ContAvizNefacturat output

select /*top 100*/ rtrim(Cont) as cod, rtrim(cont)+' - '+rtrim(left(Denumire_cont,30)) as denumire, 
	(case Sold_credit when 1 then '(Furnizori)' when 2 then '(Beneficiari)' when 3 then '(Stocuri)' 
					  when 4 then '(Valoare MF)' when 5 then '(Amortizare MF)' when 6 then '(TVA deductibil)' when 7 then '(TVA colectat)' 
					  when 8 then '(Efecte)' when 9 then '(Deconturi)' else '' end) as info,
	(case when @tip in('RM','RS','RC') and isnull(@subtip,'')='' and @tert<>'' and cont=(isnull((select max(cont_ca_furnizor) from terti where subunitate=@subunitate and tert=@Tert),'')) then 1
	      when @tip in('AP','AS')and isnull(@subtip,'')='' and @tert<>'' and cont=(isnull((select max(Cont_ca_beneficiar) from terti where subunitate=@subunitate and tert=@Tert),'')) then 1
	 else 0 end) as ordine--coloana pentru stabilirea ordinii conturilor, sa apara contul atast tertului, ca furnizor sau beneficiar(in functie de document),primul in lista
from conturi
where subunitate=@subunitate and  
(cont like @searchText + '%' or denumire_cont like '%' + @searchText + '%')  
and (@subtip<>'PN' or (@cdeb<>'' or Cont like '401%'))
and (@tip='' or conturi.Are_analitice=0)
and (@codMeniu<>'CO' or (@cdeb<>'' or Cont like '6%') and conturi.Are_analitice=0)
and ((@tip in ('RM','RS','RC') and cont like'408%' and ISNULL(@subtip,'')='') or @facturanesosita=0 )--pentru antetul receptiilor, dc este pusa bifa pentru facturi nesosite sa aduca doar contul 408
and ((@tip in ('AP','AS') and cont=@ContAvizNefacturat and ISNULL(@subtip,'')='') or @aviznefacturat=0 )--pentru antetul avizelor, dc este pusa bifa pentru aviz nefacturat sa aduca contul din parametrii(beneficiari aviz nefacturat)
and (@faraAnalitic=1 and conturi.Are_analitice=0 or @faraAnalitic=0)
/*and (@tip<>'DE' or conturi.Sold_credit=9)
and (@tip<>'EF' or conturi.Sold_credit=8)*/
order by 4 desc,rtrim(cont)  
for xml raw
end
