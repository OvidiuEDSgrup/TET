--***
Create procedure wStergMfix @sesiune varchar(50), @parXML xml
as
declare @nrinv varchar(13), @mesajeroare varchar(254)

Set @nrinv = @parXML.value('(/row/@nrinv)[1]','varchar(13)')
Set @mesajeroare=''

begin try
select @mesajeroare=(case when exists (select 1 from misMF where Numar_de_inventar=@nrinv) 
	or exists (select 1 from fisaMF where Numar_de_inventar=@nrinv) 
	or exists (select 1 from MFixini where Numar_de_inventar=@nrinv) 
	or exists (select 1 from pozdoc where /*subunitate=':1' and */cod_intrare=@nrinv and exists 
	(select 1 from nomencl where Tip='F' and nomencl.cod=pozdoc.Cod) and left(cont_de_stoc,2)<>'23' 
	and not (ISNULL((select val_logica from par where tip_parametru='GE' and parametru='IFN'),0)=1 
	and left(cont_de_stoc, 2)='43')) then 'Nr. de inventar ales este folosit in documente!' 
	when @nrinv is null then 'Nu a fost ales nr. de inventar pt. stergere!' else '' end)

if @mesajeroare=''	
	delete from mfix where Numar_de_inventar=@nrinv
else 
	raiserror(@mesajeroare, 11, 1)
END TRY

BEGIN CATCH
	set @mesajeroare=ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
END CATCH
