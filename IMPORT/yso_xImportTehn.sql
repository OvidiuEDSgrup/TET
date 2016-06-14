if exists (select * from sysobjects where name ='yso_xImportTehn')
drop procedure yso_xImportTehn
go
create procedure yso_xImportTehn as --@tabela varchar(255), @fisier nvarchar(4000) as
--begin try

	select isnull(Cod_tehn,'') as Cod_tehn, isnull(Denumire,'') as Denumire, isnull(Tip_tehn,'') as Tip_tehn
	,_linieimport
	into ##importXlsTmp
	from ##importXlsIniTmp
	order by _linieimport

	select distinct Cod_tehn, Denumire, Tip_tehn
	into ##importXlsDifTmp
	from ##importXlsTmp
	except
	select			Cod_tehn, Denumire, Tip_tehn
	from tehn

	alter table ##importXlsDifTmp add _nrdif int identity(1,1) not null
	create unique clustered index id on ##importXlsDifTmp (_nrdif)
	--create nonclustered index preturi on #preturiXlsDifTmp (cod, catpret, tippret, data_inferioara, pret_vanzare, pret_cu_amanuntul)

	declare @randuri int
	select @randuri=MAX(_nrdif) from #tehnXlsDifTmp

	if OBJECT_ID('tempdb..#mesajeASiSTmp') is not null
		drop table #mesajeASiSTmp
		
	select top 0 Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj 
	into #mesajeASiSTmp from mesajeASiS
	
	if OBJECT_ID('tempdb..#tehnXlsErrTmp') is not null
		drop table #tehnXlsErrTmp
		
	select top 0 _linieimport, convert(varchar(500),'') as _eroareimport into #tehnXlsErrTmp from #tehnXlsTmp t 
	
 	declare @eroareProc varchar(500),@txtSql nvarchar(max),@sursa varchar(max),@txtSelect varchar(max)
 		,@txtParam nvarchar(max),@eroareXL varchar(500), @contor int, @parxml xml 

-- select * from #tehnXlsErrTmp
	set @contor=1
	while @contor<=@randuri
	begin
		begin try
			update v
			set Cod_tehn=t.Cod_tehn, Denumire=t.Denumire, Tip_tehn=t.Tip_tehn
			from tehn v inner join #tehnXlsDifTmp t on v.Cod_tehn=t.Cod_tehn
			where t._nrdif=@contor
			if (@@ROWCOUNT=0)
				insert tehn
				(Cod_tehn, Denumire, Tip_tehn, Utilizator, Data_operarii, Ora_operarii, Data1, Data2, Alfa1, Alfa2, Alfa3, Alfa4, Alfa5, Val1, Val2, Val3, Val4, Val5)
				select
				Cod_tehn, Denumire, Tip_tehn, 'IMPORT', GETDATE(), '', '', '', '', '', '', '', '', '', '', '', '', ''
				from #tehnXlsDifTmp t
				where t._nrdif=@contor
 		end try
 		begin catch
			set @eroareProc = ERROR_MESSAGE()
			insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
			select '','','S',HOST_ID(),'Eroare import linie tehn',@eroareProc
			begin try
				insert #tehnXlsErrTmp
				select _linieimport, @eroareProc as _eroareimport from #tehnXlsTmp t inner join #tehnXlsDifTmp d
					on d.Cod_tehn=t.Cod_tehn and d.Denumire=t.Denumire and d.Tip_tehn=t.Tip_tehn
				where d._nrdif=@contor
			end try
			begin catch
				set @eroareXL = ERROR_MESSAGE()
				insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
				select '','','S',HOST_ID(),'Eroare raportare erori in tabel',@eroareXL
			end catch
 		end catch
 		--select @parxml
 		set @contor=@contor+1
	end
	begin try
		set @sursa='Excel 12.0;Database=@fisier;Extended Properties="Excel 12.0 Xml;IMEX=0;HDR=YES;";'
		set @sursa=REPLACE(@sursa,'@fisier',@fisier)
		set @txtSelect='Select * from [tehn$]'
		set @txtSql=
		'UPDATE x 
		SET _eroareimport = @eroareimport
		from OPENROWSET(''Microsoft.ACE.OLEDB.12.0''
		,@sursa
		, @txtSelect) x '
		set @txtSql=REPLACE(@txtSql,'@sursa',''''+@sursa+'''')
		set @txtSql=REPLACE(@txtSql,'@txtSelect',''''+@txtSelect+'''')
		set @txtParam='@eroareimport varchar(500)'
		exec sp_executesql @txtSql, @txtParam, ''
		set @txtSql=REPLACE(@txtSql,'@eroareimport','e._eroareimport')
		set @txtSql=@txtSql+' inner join #tehnXlsErrTmp e on e._linieimport=x._linieimport'
		exec sp_executesql @txtSql
	end try
	begin catch
		set @eroareXL = ERROR_MESSAGE()
		insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
		select '','','S',HOST_ID(),'Eroare raportare erori in excel',@eroareXL
	end catch
	
	delete mesajeASiS where Tip_destinatar='S' and Destinatar=HOST_ID()
	insert mesajeASiS (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj, Data, Ora, Stare)
	select t.*,GETDATE(),'','' from (select distinct * from #mesajeASiSTmp) t
	
--end try
--begin catch
--	declare @mesaj varchar(254)
--	set @mesaj = ERROR_MESSAGE() 
--	--set @mesaj = RTRIM(@mesaj)+': '+isnull(@cod,'')+','+isnull(@catpret,'')+','+isnull(@tippret,'')
--	--	+','+convert(varchar,isnull(@data,''))+','+CONVERT(varchar,isnull(@update,''))
--	raiserror(@mesaj, 11, 1)	
--	--select @mesaj as mesaj into testmesajasis
--end catch
GO

