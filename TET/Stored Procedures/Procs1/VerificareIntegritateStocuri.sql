--***  

create procedure VerificareIntegritateStocuri   
@dataJ datetime, 
@dataS datetime, 
@cuModificare int=0, /*Daca este 1 se vor modifica documentele, modificand numarul facturii*/      
@necorelatiipret_intrare int,--se vor corecta necorelatiile de tipul pret intrare      
@necorelatiipret_amanunt int,--se vor corecta necorelatiile de tipul pret amanunt      
@necorelatiicont int,--se vor corecta necorelatii de tip cont de stoc      
@parXML xml      
as      
declare @eroare varchar(1000),@filtrucod varchar(20),@filtrugestiune varchar(13), @liniaCurenta int,     
		@codi varchar(13), @cod  varchar(20), @gestiune varchar(30), @numar varchar(20), @tipdoc varchar(2), @data datetime,    
		@new_codi varchar(13), @fstocuri int    
set @eroare=''      
begin  try      
  select @filtrucod = ISNULL(@parXML.value('(/row/@filtrucod)[1]', 'varchar(20)'), ''),      
		 @filtrugestiune = ISNULL(@parXML.value('(/row/@filtrugestiune)[1]', 'varchar(13)'), ''),    
		 @liniaCurenta  = ISNULL(@parXML.value('(/row/@liniaCurenta)[1]', 'int'), 0),    
		 @codi = ISNULL(@parXML.value('(/row/@codi)[1]', 'varchar(13)'), ''),    
		 @cod = ISNULL(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), ''),    
		 @gestiune = ISNULL(@parXML.value('(/row/@gestiune)[1]', 'varchar(20)'), ''),    
		 @numar = ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),    
		 @tipdoc = ISNULL(@parXML.value('(/row/@tipdoc)[1]', 'varchar(2)'), ''),    
		 @data = ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), ''),    
		 @new_codi = ISNULL(@parXML.value('(/row/@new_codi)[1]', 'varchar(13)'), '')

   /*Ar trebui facuta tabela deoarece se foloseste si in fFacturiCen alte triggere sau cine stie pe unde*/      
  CREATE TABLE #ordonaripetipuri(tip VARCHAR(2),ordine INT)      
  INSERT INTO #ordonaripetipuri VALUES('RM',1)      
  INSERT INTO #ordonaripetipuri VALUES('RS',2)      
  INSERT INTO #ordonaripetipuri VALUES('FF',3)      
      
  declare @areStocuriGresite int,@cSubunitate varchar(9)      
  set @cSubunitate=(select top 1 val_alfanumerica from par where Tip_parametru='GE' and Parametru='SUBPRO')      
  set @areStocuriGresite=0      
       
  create table #stocuri(gestiune varchar(20),cont varchar(40),cod varchar(20),cod_intrare varchar(20),pret_stoc_doc float,pret_stoc_stoc float,tip_miscare varchar(1),      
						tip_gestiune varchar(1),tip_document varchar(2),numar_document varchar(20),data datetime,numar_pozitie int, idpozdoc int, idIntrareFirma int)
  insert into #stocuri    
  select a.gestiune, a.Cont_de_stoc, b.Cod,b.Cod_intrare,   
		(case	when @necorelatiipret_intrare=1 then a.Pret_de_stoc 
				when @necorelatiipret_amanunt=1 then (case when a.tip_miscare='I' then a.pret_cu_amanuntul   
				else a.pret_amanunt_predator end)   
		end),   
		(case	when @necorelatiipret_intrare=1 then b.Pret  
				when @necorelatiipret_amanunt=1 then b.Pret_cu_amanuntul/*(case when b.tip_Gestiune='A' then a.Pret_amanunt_predator   
				when b.Tip_gestiune not in('F','T','A') then a.pret_de_Stoc end)*/  
		end),  
		rtrim(a.tip_miscare), rtrim(b.Tip_gestiune), rtrim(a.Tip), rtrim(a.Numar),rtrim(a.Data),rtrim(a.numar_pozitie), a.idpozdoc, b.idIntrareFirma
   from pozdoc a ,stocuri b  
   where a.tip in ('RM','PP','AI','CM','AP','AC','TE','AE','DF','PF','CI')   
		and a.subunitate=b.subunitate   
		and a.gestiune=b.cod_gestiune   
		and a.cod=b.cod   
		and a.cod_intrare=b.cod_intrare     
		and (b.cod=(case when @liniaCurenta!=1 then isnull(@filtrucod,'') else @cod end) or isnull(@filtrucod,'')='')
		and (b.Cod_gestiune=(case when @liniaCurenta!=1 then isnull(@filtrugestiune,'') else @gestiune end) or isnull(@filtrugestiune,'')='')  
		and (@liniaCurenta = 1 and a.Numar=@numar and a.Data=@data and a.Cod_intrare=@codi or @liniaCurenta!=1 and ''='')  
		AND ((@necorelatiipret_intrare = 1 and convert(decimal(15,2),a.pret_de_stoc)<>convert(decimal(15,2),b.pret)			
									and convert(decimal(15,3),a.pret_de_stoc)<>convert(decimal(15,3),b.pret)) 
		or (@necorelatiipret_amanunt = 1 and (convert(decimal(15,2),(case when a.tip_miscare='I' then a.pret_cu_amanuntul 
	                                                             else a.pret_amanunt_predator end))<>convert(decimal(15,2),b.pret_cu_amanuntul)))
		OR (@necorelatiicont = 1 and a.cont_de_stoc<>b.cont))   
		and a.subunitate=@cSubunitate   
		and a.data between @dataJ and @dataS  
  union all   
  select rtrim(a.gestiune_primitoare), rtrim(a.Cont_de_stoc), rtrim(a.Cod),(case when a.grupa<>'' then a.grupa else a.Cod_intrare end),   
		(case	when @necorelatiipret_intrare=1 then a.Pret_de_stoc   
				when @necorelatiipret_amanunt=1 then a.Pret_cu_amanuntul end),   
		(case	when @necorelatiipret_intrare=1 then b.pret   
				when @necorelatiipret_amanunt=1 then a.Pret_cu_amanuntul end),   
		rtrim(a.tip_miscare), rtrim(b.Tip_gestiune), (case when a.tip='TE' then 'TI' when a.tip='DF' then 'DI' else 'PI' end),   
		rtrim(a.Numar),rtrim(a.Data),rtrim(a.numar_pozitie), a.idpozdoc, b.idIntrareFirma
  from pozdoc a ,stocuri b  
  where a.tip in ('TE','DF','PF')  
	   and a.subunitate=b.subunitate   
	   and a.gestiune_primitoare=b.cod_gestiune   
	   and a.cod=b.cod   
	   and (case when a.grupa<>'' then a.grupa else a.cod_intrare end)=b.cod_intrare   
	   and (@necorelatiicont=1 and a.tip='TE' or @necorelatiicont=1 and b.tip_gestiune='F' or @necorelatiicont=0)
	   and (b.cod=(case when @liniaCurenta!=1 then isnull(@filtrucod,'') else @cod end) or isnull(@filtrucod,'')='')  
	   and (b.Cod_gestiune=(case when @liniaCurenta!=1 then isnull(@filtrugestiune,'') else @gestiune end) or isnull(@filtrugestiune,'')='')  
	   and (@liniaCurenta = 1 and a.Numar=@numar and a.Data=@data and (case when a.grupa<>'' then a.grupa else a.cod_intrare end)=@codi or @liniaCurenta!=1 and ''='')  
	   and a.subunitate=@cSubunitate   
	   and (@necorelatiipret_intrare = 1 and convert(decimal(15,2),a.pret_de_stoc*
										(case	when a.tip='DF' and a.procent_vama<>0 
												then (1-convert(decimal(15,2),a.procent_vama/100)) 
												else 1 
										 end))<>convert(decimal(15,2),b.pret)
		or @necorelatiipret_amanunt = 1 and convert(decimal(15,2),a.pret_cu_amanuntul)<>convert(decimal(15,2),b.pret_cu_amanuntul)			
										and convert(decimal(15,3),a.pret_cu_amanuntul)<>convert(decimal(15,3),b.pret_cu_amanuntul) 
		or @necorelatiicont = 1 and a.cont_corespondent<>b.cont
		)
	   and a.data between @dataJ and @dataS  

 select gestiune,cod,cod_intrare,min(idIntrareFirma) as idIntrareFirma
 into #stocurigresite      
 from #stocuri      
 where	tip_miscare<>'V'       
		--and tip_gestiune not in ('T','F')      
		and(tip_gestiune='A' or @necorelatiipret_amanunt=0)
 group by gestiune,cod,cod_intrare 
 
 if @@ROWCOUNT>0 /*Inseamna ca exista necorelatii de cont/pret intrare/ pret amanunt*/      
	set @areStocuriGresite=1      
 if @areStocuriGresite=1 and @cuModificare=0      
	raiserror('Exista necorelatii!',16,1)        
 if @areStocuriGresite=1 and @cuModificare=1      
	begin
	/*newcodi -- formez un nou codIntrare pentru update*/
	select s1.tip_document,s1.numar_document,s1.data,s1.cont,s1.pret_stoc_doc,s1.pret_stoc_stoc,s1.cod,s1.cod_intrare,s1.gestiune,      
		dense_RANK() over 
		(partition by s1.gestiune,s1.cod,s1.cod_intrare order by 
				case when @necorelatiipret_intrare=1 then convert(varchar(25),convert(decimal(17,5),s1.pret_stoc_doc))
					 when @necorelatiipret_amanunt=1 then convert(varchar(25),convert(decimal(17,5),s1.pret_stoc_stoc)) else s1.cont end) as nrpoz,
		/* Am inlocuit partea de mai jos pentru newcodi cu idPozdoc. Cu vechiul mod de formare codinou, pe acelasi cod si coduri de intrare diferite se genera acelasi cod intrare nou.
		'CR'+replace(replace(replace(replace(replace(replace(left(reverse(rtrim(s1.cod_intrare)),2)
			+upper(char(64+DENSE_RANK() over (partition by s1.cod/*, s1.cod_intrare, (case when @necorelatiicont=1 then s1.cont else '' end)*/ order by s1.cod, s1.cod_intrare, s1.cont, convert(decimal(17,5),s1.pret_stoc_stoc))))
			+upper(char(64+DENSE_RANK() over (partition by s1.cod/*, s1.cod_intrare, (case when @necorelatiicont=1 then s1.cont else '' end)*/ order by s1.cod, s1.cod_intrare desc, s1.cont, convert(decimal(17,5),s1.pret_stoc_stoc))))
			+RIGHT(reverse(rtrim(s1.cod_intrare)),3),'[','A1'),'\','B2'),']','C3'),'^','D4'),'_','E5'),'`','F6') as newcodi      
		*/
		'C'+REPLACE(STR(DENSE_RANK() over (partition by s1.gestiune,s1.cod,s1.cod_intrare order by s1.cod, s1.cod_intrare, s1.cont, convert(decimal(17,5),s1.pret_stoc_stoc)),4),' ','0')
			as newcodi,s1.idpozdoc, s1.idIntrareFirma
	into #docgresite
	from #stocuri s1
	inner join #stocurigresite s2 on s1.gestiune=s2.gestiune and s1.cod=s2.cod and s1.cod_intrare=s2.cod_intrare      
	left JOIN #ordonaripetipuri o1 on s1.tip_document=o1.tip

	if object_id ('tempdb..#newcodi') is not null drop table #newcodi
	select gestiune,cod,cod_intrare,newcodi,min(idpozdoc) as idpozdoc
	into #newcodi
	from #docgresite
	group by gestiune,cod,cod_intrare,newcodi
	
	update d
	set d.newcodi=rtrim(d.newcodi)+convert(char(8),n.idpozdoc)
	from #docgresite d,#newcodi n 
	where d.gestiune=n.gestiune
		and d.cod=n.cod
		and d.cod_intrare=n.cod_intrare
		and d.newcodi=n.newcodi
	
	--select * from #docgresite where gestiune='50012' and cod='1CBE29' and cod_intrare in ('14S2974002','14S9759002')
	--select * from #docgresite where gestiune='20002' and cod='34TCUL2' or gestiune='10001' and cod='1KMO11'
	--order by newcodi
	
	begin tran
		alter table pozdoc disable trigger all      
  
		if exists ( select * from dbo.sysobjects where name = 'docstocm' and OBJECTPROPERTY(id, 'IsTrigger') = 1)      
		begin
			alter table pozdoc enable trigger docstocm       
			alter table pozdoc enable trigger docstoc        
		end
		select * from #docgresite
		update pozdoc   
		set cod_intrare=(case	when @liniaCurenta!=1 then d.newcodi
								when @liniaCurenta=1  then @new_codi
							end),
			idIntrareFirma=d.idIntrareFirma
		from pozdoc,#docgresite d 
		where pozdoc.subunitate=@cSubunitate       
				and d.tip_document not in ('TI','DI','PI')
				and pozdoc.tip=d.tip_document  
				and pozdoc.numar=d.numar_document 
				and pozdoc.data=d.data
				and pozdoc.Cod=d.cod 
				and pozdoc.Cod_intrare=d.cod_intrare
				AND (
						(rtrim(pozdoc.Cont_de_stoc)=rtrim(d.cont) and @necorelatiicont=1)        
						or (pozdoc.Pret_de_stoc=d.pret_stoc_doc and @necorelatiipret_intrare=1)       
						or ((case when tip_miscare='I' then pozdoc.Pret_cu_amanuntul else pozdoc.Pret_amanunt_predator end)=d.pret_stoc_doc and @necorelatiipret_amanunt=1)
					)
	
		update pozdoc   
		set grupa=(case	when @liniaCurenta!=1 then d.newcodi
						when @liniaCurenta=1  then @new_codi
						end)
		from pozdoc,#docgresite d       
		where pozdoc.subunitate=@cSubunitate       
			and d.tip_document in ('TI','DI','PI')      
			and pozdoc.tip=(case d.tip_document when 'TI' then 'TE' when 'DI' then 'DF' else 'PF' end) and pozdoc.numar=d.numar_document   
			and pozdoc.data=d.data and pozdoc.Cod=d.cod 
			AND (
					(pozdoc.Cont_de_stoc=d.cont and @necorelatiicont=1)        
					or (pozdoc.Pret_de_stoc=d.pret_stoc_doc and @necorelatiipret_intrare=1)       
					--or ((case when tip_miscare='I'  then pozdoc.Pret_cu_amanuntul else pozdoc.Pret_amanunt_predator end)=d.pret_stoc_stoc
					or (pozdoc.Pret_cu_amanuntul =d.pret_stoc_stoc and @necorelatiipret_amanunt=1)
				)      
		alter table pozdoc enable trigger all      
	commit tran

	end      
      
end try      
begin catch      
	if @@TRANCOUNT>0
		rollback tran
	set @eroare=rtrim(ERROR_MESSAGE())+' ('+object_name(@@PROCID)+')'
end catch      
       
 IF OBJECT_ID('tempdb..#stocuri') IS NOT NULL drop table #stocuri      
 IF OBJECT_ID('tempdb..#stocurigresite') IS NOT NULL drop table #stocurigresite      
 IF OBJECT_ID('tempdb..#docgresite') IS NOT NULL drop table #docgresite      
 IF OBJECT_ID('tempdb..#ordonaripetipuri') IS NOT NULL drop table #ordonaripetipuri      
      
if @eroare<>'' 
	raiserror(@eroare,16,1)      
