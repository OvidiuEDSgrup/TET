drop procedure wACNomenclatorSP
go
--***
create procedure [dbo].[wACNomenclatorSP] @sesiune varchar(50),@parXML XML as      

	declare @FltStocPred int, @searchText varchar(80), @subunitate varchar(9), @tip varchar(2)
		, @gestiune varchar(20),@gestutiliz varchar(20), @categoriePret int, @codfarastoc bit
	declare @aplicatie varchar(100), @subtip varchar(2)
	declare @utilizator varchar(10)
	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT


	exec luare_date_par 'GE', 'FNOMPRED', @FltStocPred output, 0, ''
	--set @FltStocPred=1
	declare @lista_gestiuni int
	set @lista_gestiuni=(case when exists (select 1 from proprietati 
		where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='GESTIUNE' and Valoare<>'') then 1 else 0 end)

	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''), 
		@subunitate=ISNULL(@parXML.value('(/row/@subunitate)[1]', 'varchar(9)'), '1'), 
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
		@subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), ''), 
		@aplicatie=ISNULL(@parXML.value('(/row/@aplicatie)[1]', 'varchar(2)'), ''), 
		@gestiune=ISNULL(@parXML.value('(/row/@gestiune)[1]', 'varchar(20)'), ''),
		@codfarastoc=ISNULL(@parXML.value('(/row/@codfarastoc)[1]', 'bit'), 0),
		@categoriePret=@parXML.value('(/row/@categpret)[1]', 'int')
		
        
	if @aplicatie<>''
		set @tip=@aplicatie
	set @gestutiliz=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and cod_proprietate='GESTIUNE' and cod=@utilizator),'')
	set @categoriePret=COALESCE(@categoriePret
		,(select max(valoare) from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@gestutiliz)
		,(select max(valoare) from proprietati where tip='UTILIZATOR' and cod_proprietate='CATEGPRET' and cod=@utilizator)
		,'1')
		print @categoriePret
--select * from preturi pretGest where pretGest.Cod_produs='4000004010421' and pretGest.um=@categoriePret and pretGest.Tip_pret=1 and pretGest.Data_superioara='2999-01-01' 
	set @searchText=REPLACE(@searchText, ' ', '%')
		select top 100      
	rtrim(nomencl.cod) as cod, 
	(case 
		when @tip in ('RS') then rtrim(max(nomencl.cont)) 
		when @tip in ('AS') then 'Cont:'+rtrim(max(nomencl.cont)+'Pret: '+convert(varchar,convert(decimal(15, 2),max(nomencl.Pret_vanzare)))) 
		else (case when @tip IN ('PV','TE') then '('+ltrim(CONVERT(varchar(20), max(convert(decimal(15, 2), isnull(isnull(pretGest.Pret_cu_amanuntul,pretCat1.Pret_cu_amanuntul), nomencl.Pret_cu_amanuntul)))))+' lei) ' else '' end)
			+(case @tip when 'BK' then ' Stoc mag.= '+ltrim(CONVERT(varchar(20), convert(decimal(15, 2), isnull(sum(stocuri.stoc), 0))))
				+', Stoc dep.= '+ltrim(CONVERT(varchar(20), convert(decimal(15, 2), isnull(max(s.stoc), 0))))
					+ ' ' + rtrim(max(nomencl.um)) 
				else +ltrim(CONVERT(varchar(20), convert(decimal(15, 2), isnull(sum(stocuri.stoc), 0))))+ ' ' + rtrim(max(nomencl.um)) end)
			+(case when @tip in ('RM','PP') then ' (cont '+rtrim(max(nomencl.cont))+')' else '' end)
			end) as info,  
	rtrim(max(nomencl.denumire)) as denumire 
	from nomencl
	left join preturi pretGest on pretGest.Cod_produs=nomencl.Cod and pretGest.um=@categoriePret and pretGest.Tip_pret=1 and pretGest.Data_superioara='2999-01-01' 
	left join preturi pretCat1 on pretCat1.Cod_produs=nomencl.Cod and pretCat1.um=1 and pretCat1.Tip_pret=1 and pretCat1.Data_superioara='2999-01-01' 
	left join stocuri on stocuri.Subunitate=@subunitate 
		and (@tip in ('PF','CI') and stocuri.Tip_gestiune='F' or @tip not in ('PF','CI') and stocuri.Tip_gestiune not in ('F', 'T'))
			and stocuri.Cod=nomencl.cod and (@gestiune='' or stocuri.Cod_gestiune=@gestiune)
		and (@gestiune!='' or @lista_gestiuni=0 or exists (select 1 from proprietati gu where gu.valoare=stocuri.cod_gestiune and gu.tip='UTILIZATOR' and gu.cod=@utilizator and gu.cod_proprietate='GESTIUNE'))  --Se filtreaza pe gestiunile provenite din proprietati
	outer apply (select stoc=SUM(s.stoc) from stocuri s where s.Subunitate=@subunitate and s.Tip_gestiune not in ('F','T') and s.Cod=nomencl.Cod and s.Cod_gestiune='101') s
	where (nomencl.denumire like '%'+@searchText+'%' or nomencl.cod like @searchText+'%')
	and not (@tip in ('RM','AI') and nomencl.tip='S') 
	and not (@tip in ('AP','AE') and nomencl.tip='R') 
	and (@tip not in ('RS') or nomencl.tip='R') 
	and (@tip not in ('AS') or nomencl.tip='S') 
	and (@tip not in ('DF','PF','CI') or nomencl.tip='O') 
	and (@tip not in ('CM') or nomencl.tip<>'O') 
	and (@tip not in ('PV') or nomencl.Tip in ('A', 'M', 'P', 'S'))
	and ((nomencl.Cont in ('419','4092') and nomencl.Tip in ('S','R')) or @subtip not in ('AA'))--daca suntem pe subtip de avans sa aduca numai codurile de servicii pe cont 419
	--and (@gestiune='' --or @tip not in ('BK', 'AP', 'AC', 'CM', 'TE', 'DF', 'AE', 'PF', 'CI') 
	--	or nomencl.tip not in ('A','M','P') or stocuri.Cod_gestiune=@gestiune) --Se filtreaza pe gestiunea primita ca si parametru
	--and (@lista_gestiuni=0 or gu.valoare is not null 
		--or @tip not in ('BK', 'AP', 'AC', 'CM', 'TE', 'DF', 'AE', 'PF', 'CI') or @FltStocPred=0
		--or nomencl.tip not in ('A','M','P'))  --Se filtreaza pe gestiunile provenite din proprietati
	--and (@tip not in ('AP','PV','BK','TE') or @codfarastoc=1 or stocuri.Stoc>=0.001)
	group by nomencl.cod,nomencl.Denumire,nomencl.tip
	having (@FltStocPred=0 or nomencl.tip in ('R') or @tip not in ('AP', 'AC', 'CM', 'TE', 'DF', 'AE', 'PF', 'CI'/*SP */,'BK','PV') 
		or ISNULL(@parXML.value('(/row/@codfarastoc)[1]', 'bit'), 0)=1 /* SP*/ or sum(ISNULL(stocuri.stoc, 0))>=0.001)
	order by 3,patindex('%'+@searchText+'%',nomencl.denumire)
	for xml raw 

GO
