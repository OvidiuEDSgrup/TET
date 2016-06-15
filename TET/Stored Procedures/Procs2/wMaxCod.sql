
create procedure wMaxCod (@cod varchar(30), @tabela varchar(100), @codmax varchar(30) output) 
as
begin try	
	if exists(select * from sysobjects where name='wMaxCodSP' and type='P')
	begin
		exec wMaxCodSP @cod,@tabela,@codmax output
		return
	end
	
	declare 
		@comanda nvarchar(1000), @ParmDefinition nvarchar(500)

	set @ParmDefinition=N'@scodmax nvarchar(30) OUTPUT'

	set @comanda=
		N'set @scodmax = ISNULL((select max(convert(decimal,'+rtrim(@cod)+')) from '+rtrim(@tabela)+'
		where isnumeric('+rtrim(@cod)+')<>0 and '+rtrim(@cod)+' not in (''.'','','') and charindex(''-'','+rtrim(@cod)+')=0 and '+rtrim(@cod)+' NOT like ''%[a-z]%'' and charindex('','','+rtrim(@cod)+')=0 and '+ rtrim(@cod) + ' not like''%[!@#$%^&*]%''),0)+1'
	
	execute sp_executesql @comanda, @ParmDefinition ,@scodmax=@codmax output
	
end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
