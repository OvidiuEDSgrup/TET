
--select * from testov..rulaje o where not exists 
--(select 1 from tet..rulaje r where r.Subunitate=o.Subunitate and r.Cont=o.Cont and r.Data=o.Data
--and r.Valuta=o.Valuta and r.Loc_de_munca=o.Loc_de_munca and r.Indbug=o.indbug)
select SUM(1),sum(r.Rulaj_credit),SUM(r.Rulaj_debit) from rulaje r
declare @tabela varchar(30), @camp varchar(50), @cond varchar(500)
	,@comanda nvarchar(max), @camp1 varchar(50), @camp2 varchar(50)
	,@datajos datetime, @idindex int, @idobject int, @condjoinidxunic varchar(max)
	,@nrcrt int, @nrcrtmax int, @tipinl int, @nrcod int, @nrcodmax int
	,@setupdidxunic varchar(max), @selupdidxunic varchar(max)
--alter database tet set multi_user with rollback immediate
--select * from sys.databases d where d.database_id=7
--select * from sys.dm_tran_locks l where l.resource_database_id=7
--kill 64
set transaction isolation level read uncommiTted
begin try
--select * from rulaje r where '7588' in (r.cont) and r.data<'2015-01-01'
--select * from pozadoc p where '7588' in (p.Cont_deb,p.Cont_cred,p.Cont_dif)
--and p.data<'2015-01-01'
--select * from pozincon p where '7588' in (p.cont_debitor,p.cont_creditor) and p.data>='2015-01-01'
--select * from pozplin p where '7588' in (p.cont,p.cont_corespondent) 
	select @datajos='2015-01-01'
--/*
	select @comanda=isnull(@comanda,'')+' alter	 table '+rtrim(o.name)+' disable trigger '+RTRIM(t.name)+CHAR(10)--+CHAR(13)
	from sys.triggers t inner join sys.objects o on o.object_id=t.parent_id
	where t.is_disabled=0

	exec (@comanda)
--*/
	if OBJECT_ID('tempdb..#coduri') is not null
	drop table #coduri
	
	select * 
	into #coduri
	from yso_codinl c
	order by c.Tip,c.Cod_nou,c.Cod_vechi
	--where c.Cod_vechi='1VNZ0103'
	
	select @nrcod=MIN(nrinl), @nrcodmax=MAX(nrinl) from #coduri
	
	begin tran
	
	while @nrcod<=@nrcodmax
	begin
		--select convert(xml,@comanda)

		--select * from DetTabInl d inner join TabInl t on t.Tip=d.Tip and d.Numar_tabela=t.Numar_tabela where t.Tip=1 and t.Inlocuiesc='Da'
		declare @codvechi nvarchar(50), @codnou nvarchar(50)
		select @codvechi=cod_vechi, @codnou=cod_nou, @tipinl=tip from #coduri 
		where NrInl=@nrcod
		print 'cod vechi '+@codvechi
		print 'cod nou '+@codnou
		
		if @codvechi=@codnou
			raiserror('Codul nou este acelasi cu codul vechi!',16,1)

		if OBJECT_ID('tempdb..#campuri') is not null
			drop table #campuri
			
		select nrcrt=IDENTITY(int,1,1)
			,tabela=rtrim(t.Denumire_SQL),camp=rtrim(d.Camp_SQL),cond=rtrim(d.Conditie_de_inlocuire ), camp1=rtrim(t.camp1), camp2=rtrim(t.camp2)
		INTO #campuri
		from yso_DetTabInl d inner join yso_TabInl t on t.Tip=d.Tip and d.Numar_tabela=t.Numar_tabela
		where t.Tip=@tipinl and t.Inlocuiesc='Da' 
			--and d.Camp_Magic like 'pozincon'
		order by t.Numar_tabela,d.Camp_SQL
		--and t.Denumire_SQL='corectii'

		select @nrcrt=MIN(nrcrt), @nrcrtmax=MAX(nrcrt) from #campuri
		
		while @nrcrt<=@nrcrtmax
		begin--/*
			select @idindex=null,@idobject=null, @condjoinidxunic=null, @setupdidxunic=null, @selupdidxunic=null
			select @tabela=tabela,@camp=camp,@cond=cond,@camp1=camp1,@camp2=camp2
			from #campuri c where c.nrcrt=@nrcrt
			
			
			select top 1 @idindex=i.index_id, @idobject=i.object_id
				from sys.index_columns ic 
					inner join sys.columns c on c.object_id=ic.object_id and c.column_id=ic.column_id
					inner join sys.indexes i on i.object_id=ic.object_id and i.index_id=ic.index_id 
					inner join sys.objects o on o.object_id=c.object_id
				where i.is_unique=1 and o.name=@tabela and c.name=@camp order by i.index_id 
			print 'tabela: '+rtrim(@tabela)+', index:'+rtrim(@idindex)+', idobject: '+rtrim(@idobject)
			if isnull(@idindex,0)<>0 --and 1=0
			begin 
				select @condjoinidxunic=ISNULL(@condjoinidxunic+' and ','')+' n.'+rtrim(c.name)+'=v.'+rtrim(c.name)
				from sys.index_columns ic 
					inner join sys.columns c on c.object_id=ic.object_id and c.column_id=ic.column_id
					inner join sys.indexes i on i.object_id=ic.object_id and i.index_id=ic.index_id 
					inner join sys.objects o on o.object_id=c.object_id
				where i.is_unique=1 and i.object_id=@idobject and i.index_id=@idindex and c.name<>@camp order by ic.key_ordinal
				print 'fac cond join:'+@condjoinidxunic

				select @setupdidxunic=case when c.collation_name is null 
							then case when c.name like 'curs%'
									then ISNULL(@setupdidxunic+char(10)+', ','')+rtrim(c.name)+'= (n.'+rtrim(c.name)+'+v.'+rtrim(c.name)+')/2' 
									else ISNULL(@setupdidxunic+char(10)+', ','')+rtrim(c.name)+'= n.'+rtrim(c.name)+'+v.'+rtrim(c.name) end
							else @setupdidxunic end
						,@selupdidxunic=case when c.collation_name is null 
							then ISNULL(@selupdidxunic+', v.','v.')+rtrim(c.name)								
							else @selupdidxunic end
				from sys.columns c 
					inner join sys.types t on t.system_type_id=c.system_type_id
					inner join sys.objects o on o.object_id=c.object_id
					left join sys.index_columns ic on c.object_id=ic.object_id and c.column_id=ic.column_id and ic.index_id=@idindex
				where o.object_id=@idobject and ic.index_id is null and t.name not like 'date%' and c.is_identity=0
					and t.name not like 'xml%' and c.name not like 'id%'
				order by c.column_id
				print 'fac set upd:'+@setupdidxunic
				
				set @comanda='if OBJECT_ID(''tempdb..#'+@tabela+''') is not null drop table #'+@tabela
				set @comanda+=CHAR(10)+'select top 0 *'/*+rtrim(@selupdidxunic)*/+' into #'+@tabela+' from '+@tabela+' v'
				
				set @comanda+=CHAR(10)+'delete v '
					+char(10)+'output deleted.*'/*+replace(rtrim(@selupdidxunic),'v.','deleted.')*/+' into #'+@tabela
					+char(10)+'from '+@tabela+' v cross apply (select '+@camp
					+char(10)+'from '+@tabela+' n where n.'+@camp+' = @codnou '+isnull(CHAR(10)+' and '+nullif(@condjoinidxunic,''),'')+') n ' 
					+char(10)+'where v.'+@camp+' = @codvechi'--' like N''%[a-z]%''' COLLATE Latin1_General_BIN'
					+isnull(CHAR(10)+' and '+nullif(@cond,''),'') 
					+isnull(CHAR(10)+' and v.'+nullif(ltrim(@camp1),'')+'=''1''','') 
					+isnull(CHAR(10)+' and v.'+nullif(ltrim(@camp2),'')+'>='''+convert(char(10),@datajos,120)+'''','') 
				
				set @comanda=@comanda+CHAR(10)
					+isnull('if @@ROWCOUNT>0 update n set'
					+char(10)+@setupdidxunic
					+char(10)+'from '+@tabela+' n cross apply (select '+@selupdidxunic
					+char(10)+'from '+'#'+@tabela+' v where v.'+@camp+' = @codvechi '+isnull(CHAR(10)+' and '+nullif(@condjoinidxunic,''),'')+') v ' 
					+char(10)+'where n.'+@camp+' = @codnou'--' like N''%[a-z]%''' COLLATE Latin1_General_BIN'
					+isnull(CHAR(10)+' and '+nullif(@cond,''),'') 
					+isnull(CHAR(10)+' and n.'+nullif(ltrim(@camp1),'')+'=''1''','') 
					+isnull(CHAR(10)+' and n.'+nullif(ltrim(@camp2),'')+'>='''+convert(char(10),@datajos,120)+'''','')
					,'')
				print isnull(@comanda,'com null')+char(10)
				exec sp_executesql @comanda, N'@codnou nvarchar(50), @codvechi nvarchar(50)', @codnou, @codvechi
				
				if @@ROWCOUNT>0
				begin
					print 'gasit index '+rtrim(@idindex)+',obiect '+rtrim(@idobject)+' la '+rtrim(@tabela)+'.'+rtrim(@camp) 
					print 'conditie delete '+@condjoinidxunic
					
				end
			end--*/
			
			set @comanda=null
			set @comanda='update '+@tabela+' set '+@camp+'=upper(@codnou)'
				--+case @tabela when 'proprietati' then +CHAR(10)+'output deleted.*' else '' end
				+CHAR(10)+' where '+@camp+' = @codvechi'--' like N''%[a-z]%''' COLLATE Latin1_General_BIN'
				+isnull(CHAR(10)+' and '+nullif(@cond,''),'') 
				+isnull(CHAR(10)+' and '+nullif(@camp1,'')+'=''1''','') 
				+isnull(CHAR(10)+' and '+nullif(@camp2,'')+'>='''+convert(char(10),@datajos,120)+'''','') 
			print @comanda
			print @codvechi+','+@codnou
			exec sp_executesql @comanda, N'@codnou nvarchar(50), @codvechi nvarchar(50)', @codnou, @codvechi
			set @nrcrt=@nrcrt+1
		end
		set @nrcod=@nrcod+1
	end
select SUM(1),sum(r.Rulaj_credit),SUM(r.Rulaj_debit) from rulaje r
	commit tran
	
	set @comanda=null
	select @comanda=isnull(@comanda,'')+' alter table '+rtrim(o.name)+' enable trigger '+RTRIM(t.name)+CHAR(10)--+CHAR(13)
	from sys.triggers t inner join sys.objects o on o.object_id=t.parent_id
	where t.is_disabled=1

	exec (@comanda)
end try
begin catch
	rollback tran
	declare @msjerr varchar(500)
	set @msjerr=ERROR_MESSAGE()
	raiserror(@msjerr,16,1)
end catch