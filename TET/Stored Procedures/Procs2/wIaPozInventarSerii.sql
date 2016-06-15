create procedure wIaPozInventarSerii @sesiune varchar(50), @parXML xml
as 
declare @gestiune varchar(20), @datainv datetime, @subtip varchar(2), @tip varchar(2), @Data datetime, @doc xml, @cautare varchar(20)


select @gestiune=ISNULL(@parXML.value('(/row/@gest)[1]', 'varchar(22)'), ''),
       @datainv=ISNULL(@parXML.value('(/row/@datainv)[1]', 'datetime'), ''),
       @subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), ''),
       @cautare=ISNULL(@parXML.value('(/row/@_cautare)[1]', 'varchar(20)'), '')
       
set @cautare='%'+replace(@cautare,' ','%')+'%'
set @doc=(select top 100 rtrim(iv.Cod_produs)+' - '+rtrim(n.Denumire)   as codserie,
       'IS' as subtip,
       rtrim(iv.Stoc_faptic) as faptic,
	   rtrim(isnull(n.UM, '')) as um,
	   (select convert(decimal(12,2),sum(st.Stoc_ce_se_calculeaza)) from stocuri st where st.subunitate=iv.subunitate and st.cod_Gestiune=@gestiune and st.cod=iv.cod_produs) as scriptic,
	   (select rtrim(iv.cod_produs) as cod,RTRIM(invsr.Serie) as codserie,'#08088A'as culoare,
			   convert(decimal(12,2),invsr.Stoc_faptic) as faptic,'SE' as subtip ,rtrim(isnull(n.UM, '')) as um
			   from invserii invsr 
				inner join inventar inv on inv.Subunitate=invsr.Subunitate and inv.Data_inventarului=invsr.Data_inventarului 
											and inv.Gestiunea=invsr.Gestiunea and invsr.Stoc_faptic>0 and inv.cod_produs=invsr.cod_produs 
											and inv.data_inventarului=@datainv and inv.gestiunea=@gestiune and invsr.cod_produs=iv.cod_produs
		order by invsr.Serie  for xml raw,type)
	    from inventar iv
	    inner join nomencl n on iv.Cod_produs=n.Cod and iv.Gestiunea=@gestiune and iv.Data_inventarului=@datainv 
	    where iv.cod_produs like @cautare or @cautare=''
for xml raw, root('Ierarhie')  
)
select @doc for xml path('Date')  
	   
