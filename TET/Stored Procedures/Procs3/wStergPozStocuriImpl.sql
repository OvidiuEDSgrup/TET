--***
create procedure [wStergPozStocuriImpl] @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @eroare xml ,@serie varchar(20),@prop1 varchar(20),@prop2 varchar(20),@cod varchar(20),@tip varchar(2),@update bit,@subtip varchar(2),
		@subunitate varchar(9),@numar varchar(13),@data datetime,@numar_pozitie int	,@docXMLIaPozdoc xml,@stoc float,@gest varchar(9),@cod_intrare varchar(13),
		@userAsis varchar(13),@data_lunii datetime,@an_impl int,@luna_impl int,@mod_impl int		


begin try
begin transaction
if exists (select 1 from sysobjects where [type]='P' and [name]='wStergPozStocuriImplSP')
	exec wStergPozStocuriImplSP @sesiune, @parXML output

select
	 @subunitate=isnull(@parXML.value('(/row/@subunitate )[1]', 'varchar(9)'), ''),
	 @tip=isnull(@parXML.value('(/row/@tip )[1]', 'varchar(2)'), ''),	
	 @gest=isnull(@parXML.value('(/row/@cod_gestiune )[1]', 'varchar(13)'), ''),	 
	 @data=isnull(@parXML.value('(/row/@data )[1]', 'datetime'), '1901-01-01'),
	 @data_lunii=isnull(@parXML.value('(/row/@data_lunii )[1]', 'datetime'), '1901-01-01'),
	  
	 ---folosite exclusiv pentru lucrul pe serii
	 @cod_intrare=isnull(ISNULL(@parXML.value('(/row/row/@codintrare)[1]', 'varchar(13)'),
						 isnull(@parXML.value('(/row/row/row/@codintrareS )[1]', 'varchar(13)'), 
								@parXML.value('(/row/row/@codintrareS )[1]', 'varchar(13)'))),''),
	 @prop1=isnull(@parXML.value('(/row/row/@prop1 )[1]', 'varchar(20)'), ''),
	 @prop2=isnull(@parXML.value('(/row/row/@prop2 )[1]', 'varchar(20)'), ''),
	 @cod=isnull(@parXML.value('(/row/row/@cod )[1]', 'varchar(20)'), ''),
	 @subtip=isnull(@parXML.value('(/row/row/@subtip )[1]', 'varchar(2)'), ''),	
	 @serie=isnull(isnull(@parXML.value('(/row/row/row/@serie )[1]', 'varchar(20)'), @parXML.value('(/row/row/@serie )[1]', 'varchar(20)')),'')
		
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output	
	exec luare_date_par 'GE', 'ANULIMPL', 0, @an_impl output, ''
	exec luare_date_par 'GE', 'LUNAIMPL', 0, @luna_impl output, ''
	exec luare_date_par 'GE', 'IMPLEMENT', @mod_impl output, 0, ''
	
	/*if YEAR(@data)<>@an_impl and MONTH(@data)<>@luna_impl
		raiserror('Stergerea poate fi efectuata doar pentru stocurile cu data egala cu data implementarii!!',11,1)*/
		
	if @mod_impl=0
		raiserror('Stergerea poate fi efectuata doar daca sunteti in mod implementare!!',11,1)	
	
	if @serie=''
		set @serie=(case when @prop1<>'' and @prop2<>'' then rtrim(ltrim(@prop1))+','+RTRIM(ltrim(@prop2))when  @prop1<>'' and @prop2='' then @prop1 else''end)	
	
	if @subtip='SE' --suntem pe linie de serie
		begin
		delete from istoricserii where Subunitate=@subunitate and cod=@cod and Cod_intrare=@cod_intrare and Serie=@serie--stergere serie din istoricserii
							  
		set @stoc =(select SUM(stoc) from istoricserii where Gestiune=@Gest and cod=@Cod and Cod_intrare=@cod_intrare )--recalculam cantitatea din istoricserii pentru acesta pozitie din istoricstocuri
		
		if @stoc>0.001--daca stocul este mai mare de 0=> mai avem si alte serii pe aceasta pozitie din istoricserii, deci reglam stocul de pe ea
			update istoricstocuri set stoc=@stoc
			where subunitate=@subunitate and cod_gestiune=@gest and cod=@cod and Cod_intrare=@cod_intrare and Data_lunii=@data_lunii					  
		
		else -- nu mai sunt serii pe aceasta pozitie => stergem pozitia din istoricstocuri
			delete from istoricstocuri where Subunitate=@subunitate and cod_gestiune=@gest and cod=@cod and Cod_intrare=@cod_intrare and Data_lunii=@data_lunii
		end	
		 			  
	else --suntem pe linie cu pozitie de istoricstocuri 
	    begin
	    if (select UM_2  from nomencl where cod=@cod)='Y' and @serie<>''--daca avem serii pe acesta pozitie stergem toate seriile din istoricserii
			begin
			delete from istoricserii where Subunitate=@subunitate and cod=@cod  and Cod_intrare=@cod_intrare and Gestiune=@gest and Data_lunii=@data_lunii	
			end
		delete from istoricstocuri where Subunitate=@subunitate and cod_gestiune=@gest and cod=@cod and Cod_intrare=@cod_intrare and Data_lunii=@data_lunii					 
		end
		
	set @docXMLIaPozdoc = '<row cod_gestiune="'+rtrim(@gest)+'" data_lunii="'+convert(varchar(10),@data_lunii,101)+'"/>'
	exec wIaPozStocuriImpl @sesiune=@sesiune, @parXML=@docXMLIaPozdoc
			
commit transaction
end try
begin catch
   ROLLBACK TRAN
	
	declare @mesaj varchar(255)
		set @mesaj=ERROR_MESSAGE() 
		raiserror(@mesaj, 11, 1)
end catch
