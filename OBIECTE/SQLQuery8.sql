/****** Object:  StoredProcedure [dbo].[wACFacturi]    Script Date: 02/08/2012 08:40:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--***
ALTER procedure [dbo].[wACFacturiSP] @sesiune varchar(50), @parXML XML  
as  
declare @subunitate varchar(9), @searchText varchar(80), @tip varchar(2), @subtip varchar(2), @tert varchar(13), 
	@valuta varchar(3), @furnbenef varchar(1), @inValuta int, @cont varchar(13)
declare @raport varchar(100)
if exists (select 1 from sysobjects where [type]='P' and [name]='wACFacturiSP' and SCHEMA_NAME([uid])='yso')
	exec yso.wACFacturiSP @sesiune, @parXML 
else
begin
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''), 
	@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
	@subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), ''), 
	@tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(13)'),
		ISNULL(@parXML.value('(/row/@cTert)[1]', 'varchar(13)'), '')), 
	@valuta=ISNULL(@parXML.value('(/row/@valuta)[1]', 'varchar(3)'), ''),
	@raport=ISNULL(@parXML.value('(/row/@raport)[1]', 'varchar(100)'), ''),
	@furnbenef=isnull(@parXML.value('(/row/@furnbenef)[1]', 'varchar(1)'),
		ISNULL(@parXML.value('(/row/@cFurnBenef)[1]', 'varchar(1)'), '')),
	@cont=isnull(@parXML.value('(/row/@contbenef)[1]', 'varchar(1)'),'')
	

set @searchText=REPLACE(@searchText, ' ', '%')+'%'

if ISNULL(@furnbenef,'')=''
	set @furnbenef=(case when @tip in ('AP', 'AS','CB','IF') or @tip in ('RE', 'DE', 'EF') and (left(@subtip, 1)='I' and @subtip<>'IS' or @subtip='PS') then 'B' else 'F' end)

set @inValuta=(case when (@tip in ('RM', 'RS', 'AP', 'AS') or @tip in ('RE', 'DE', 'EF') and @subtip in ('PV', 'IV')) and @valuta<>'' then 1 else 0 end)

if (rtrim(@raport)<>'' or dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=0)	/**	Daca suntem pe rapoarte sau nu exista proprietatea 'LOCMUNCA' pentru utilizatorul curent se iau pur si simplu facturile*/
		select top 100 rtrim(f.Factura) as cod, 
		rtrim(f.Factura)+' din ' + CONVERT(varchar(10), f.data, 103) + ' Scad. ' + CONVERT(varchar(10), f.data_scadentei, 103)+' Ct. ' + RTRIM(f.Cont_de_tert) as denumire, 
		'Sold ' + CONVERT(varchar(20), convert(money, (case when @inValuta=1 then f.sold_valuta else f.sold end)), 1) + ' ' + (case when @inValuta=1 then @valuta else 'lei' end) as info, 
		f.Data
	from facturi f
	where f.Factura like @searchText
		and (@tert='' or f.Tert=@tert)
		and f.Tip=(case when @furnbenef='B' then 0x46 else 0x54 end)
		and (@cont='' or f.Cont_de_tert=@cont)
		and (@inValuta=0 or f.Valuta=@valuta)
		and (@tip not in ('RE', 'DE', 'EF') or ABS(case when @inValuta=1 then f.sold_valuta else f.sold end)>=0.01)
		and (@subtip<>'AA' or f.Factura like 'AV%')--daca este subtip de avans sa aduca numai facturile de avans
	order by 4
	for xml raw

else													/**	altfel se iau doar acele facturi pentru care exista date pe locul de munca filtrat*/

	select top 100 rtrim(f.Factura) as cod, 
		rtrim(f.Factura)+' din ' + CONVERT(varchar(10), max(isnull(fa.data,f.data)), 103) +
					' Scad. ' + CONVERT(varchar(10), max(isnull(fa.data_scadentei,f.data_scadentei)), 103)+' Ct. ' + RTRIM(max(f.Cont_de_tert)) as denumire, 
		'Sold ' + CONVERT(varchar(20), convert(money, sum(case when @inValuta=1 then f.total_valuta-f.achitat_valuta else f.valoare+f.tva-f.achitat end)), 1) +
					' ' + (case when @inValuta=1 then @valuta else 'lei' end) as info, 
		max(isnull(fa.data,f.data)) as data
	from --facturi f
	dbo.fTert (@furnbenef, '1901-1-1', '2500-1-1', @tert, @searchText, null, 0, 0, 0, null) f
		left join facturi fa on f.factura=fa.factura and f.tert=fa.tert and f.subunitate=fa.subunitate and fa.tip=(case when @furnbenef='B' then 0x46 else 0x54 end)
	where f.Factura like @searchText
		and (@tert<>'')
		and (@inValuta=0 or f.Valuta=@valuta)
	group by f.factura, f.tert
	having (@tip not in ('RE', 'DE', 'EF') or ABS(sum(case when @inValuta=1 then f.total_valuta-f.achitat_valuta else f.valoare+f.tva-f.achitat end))>=0.01)
		   and (@subtip<>'AA' or f.Factura like 'AV%')--daca este subtip de avans sa aduca numai facturile de avans
	order by 4
	for xml raw

end