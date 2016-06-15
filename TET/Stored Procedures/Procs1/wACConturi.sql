--***
create procedure wACConturi @sesiune varchar(50), @parXML XML  
as  
if exists(select * from sysobjects where name='wACConturiSP' and type='P')      
	exec wACConturiSP @sesiune,@parXML      
else      
begin
	declare 
		@subunitate varchar(9), @bugetari int, @searchText varchar(80), @tip varchar(2), @codMeniu varchar(2), @cdeb varchar(40), @subtip varchar(2),@facturanesosita bit,
		@CTCLAVRT bit,@ContAvizNefacturat varchar(40),@aviznefacturat bit,@tert varchar(13), @faraAnalitice int, @doarAnalitice int,
		@toateConturile bit	--> @toateConturile=0 => doar conturile fara analitice
	select @subunitate=(case when tip_parametru='GE' and parametru='SUBPRO' then val_alfanumerica else @subunitate end),
		@bugetari=(case when tip_parametru='GE' and parametru='BUGETARI' then Val_logica else @bugetari end)
	from par
  
	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''), 
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@facturanesosita=ISNULL(@parXML.value('(/row/@facturanesosita)[1]', 'bit'), 0),
		@aviznefacturat=ISNULL(@parXML.value('(/row/@aviznefacturat)[1]', 'bit'), 0),
		@subtip=ISNULL(@parXml.value('(/row/@subtip)[1]', 'varchar(2)'), ''), 
		@codMeniu=ISNULL(@parXML.value('(/row/@codMeniu)[1]', 'varchar(2)'), ''), 
		@cdeb=ISNULL(@parXML.value('(/row/@cdeb)[1]', 'varchar(40)'), ''),
		@tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), ''),
		@faraAnalitice=ISNULL(@parXML.value('(/row/@faraAnalitic)[1]', 'int'), 0),
		@doarAnalitice=ISNULL(@parXML.value('(/row/@doarAnalitice)[1]', 'int'), 0)
		

	select @toateConturile=(case when @parXML.value('(/row/@cale)[1]', 'varchar(2000)') is not null and @parXML.value('(/row/@raport)[1]', 'varchar(2000)') is not null or 
	@tip='' then 1 else 0 end)
	set @searchText=REPLACE(@searchText, ' ', '%')

	--exec luare_date_par 'GE', 'CTCLAVRT ', @CTCLAVRT  output, 0, @ContAvizNefacturat output

	select top 100 rtrim(Cont) as cod, rtrim(cont)+' - '+rtrim(left(Denumire_cont,80)) as denumire, 
		(case Sold_credit when 1 then '(Furnizori)' when 2 then '(Beneficiari)' when 3 then '(Stocuri)' 
						  when 4 then '(Valoare MF)' when 5 then '(Amortizare MF)' when 6 then '(TVA deductibil)' when 7 then '(TVA colectat)' 
						  when 8 then '(Efecte)' when 9 then '(Deconturi)' else '' end)
		+(case when @bugetari=1 then '-Indbug:'+isnull(detalii.value('(/row/@sursaf)[1]','varchar(1)'),'')+isnull('-'+detalii.value('(/row/@indicator)[1]','varchar(20)'),'') else '' end) as info,
		(case when @tip in ('RM','RS','RC') and isnull(@subtip,'')='' and @tert<>'' and cont=(isnull((select max(cont_ca_furnizor) from terti where subunitate=@subunitate and tert=@Tert),'')) then 1
			  when @tip in ('AP','AS')and isnull(@subtip,'')='' and @tert<>'' and cont=(isnull((select max(Cont_ca_beneficiar) from terti where subunitate=@subunitate and tert=@Tert),'')) then 1
		 else 0 end) as ordine--coloana pentru stabilirea ordinii conturilor, sa apara contul atast tertului, ca furnizor sau beneficiar(in functie de document),primul in lista
	from conturi
	where subunitate=@subunitate 
	and (cont like @searchText + '%' or denumire_cont like '%' + @searchText + '%'
		or @bugetari=1 --filtrare dupa sursa de finantare / indicator bugetar (bugetari)
			and	(isnull(detalii.value('(/row/@sursaf)[1]','varchar(1)'),'') like '%' + @searchText + '%' or isnull(detalii.value('(/row/@indicator)[1]','varchar(20)'),'') like '%' + @searchText + '%'))	
	and (@subtip<>'PN' or (@cdeb<>'' or Cont like '401%'))
	and (@toateConturile=1 or conturi.Are_analitice=0)
	and (@codMeniu<>'KC' or (@cdeb<>'' or Cont like '6%') and conturi.Are_analitice=0)
	--and ((@tip in ('RM','RS','RC') and cont like'408%' and ISNULL(@subtip,'')='') or @facturanesosita=0 )--pentru antetul receptiilor, dc este pusa bifa pentru facturi nesosite sa aduca doar contul 408
	--and ((@tip in ('AP','AS') and cont=@ContAvizNefacturat and ISNULL(@subtip,'')='') or @aviznefacturat=0 )--pentru antetul avizelor, dc este pusa bifa pentru aviz nefacturat sa aduca contul din parametrii(beneficiari aviz nefacturat)
	and (@faraAnalitice=1 and conturi.Are_analitice=0 or @faraAnalitice=0)
	and (@doarAnalitice=0 or conturi.Are_analitice=0)
	/*and (@tip<>'DE' or conturi.Sold_credit=9)
	and (@tip<>'EF' or conturi.Sold_credit=8)*/
	order by 4 desc,rtrim(cont)  
	for xml raw, root('Date')
end


